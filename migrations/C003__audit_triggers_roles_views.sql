-- =============================================================================
-- Catalog audit triggers, DB roles and partner self-views (plan §5.4, §5.5, §12.6)
--
-- Roles are NOLOGIN groups. Login roles are created per environment (Neon console/API)
-- and granted membership; per-partner readers (catalog_reader_<partner>) are created at
-- provisioning time (Phase 4.4 / 8.10) as members of catalog_reader.
-- The migration owner is whoever runs these migrations and owns every object.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Audit trigger: actor is a PlatformUser (app.user_code = PlatformUserCode)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION audit_row_change() RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_old       JSONB;
    v_new       JSONB;
    v_row       JSONB;
    v_changed   TEXT[];
    v_excluded  TEXT[] := COALESCE(TG_ARGV, ARRAY[]::TEXT[]);
    v_user_id   INTEGER;
    v_user_code UUID;
    v_ip        INET;
    v_id_text   TEXT;
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN v_old := to_jsonb(OLD) - v_excluded; END IF;
    IF TG_OP IN ('INSERT', 'UPDATE') THEN v_new := to_jsonb(NEW) - v_excluded; END IF;

    IF TG_OP = 'UPDATE' THEN
        SELECT COALESCE(array_agg(n.key ORDER BY n.key), ARRAY[]::TEXT[])
          INTO v_changed
          FROM jsonb_each(v_new) n
         WHERE v_old -> n.key IS DISTINCT FROM n.value;
        IF cardinality(v_changed) = 0 THEN
            RETURN NULL;   -- no-op, or only excluded columns changed
        END IF;
    END IF;

    v_row := CASE WHEN TG_OP = 'DELETE' THEN v_old ELSE v_new END;

    BEGIN
        v_user_code := NULLIF(current_setting('app.user_code', true), '')::UUID;
    EXCEPTION WHEN invalid_text_representation THEN
        v_user_code := NULL;
    END;
    IF v_user_code IS NOT NULL THEN
        SELECT "PlatformUserId" INTO v_user_id FROM "PlatformUser" WHERE "PlatformUserCode" = v_user_code;
    END IF;

    BEGIN
        v_ip := NULLIF(current_setting('app.ip', true), '')::INET;
    EXCEPTION WHEN invalid_text_representation THEN
        v_ip := NULL;
    END;

    -- PartnerLogo is keyed by PartnerId, every other table by <Table>Id
    v_id_text := COALESCE(v_row ->> (TG_TABLE_NAME || 'Id'), v_row ->> 'PartnerId');

    INSERT INTO "AuditLog" (
        "TableName", "RecordId", "RecordKey", "Action",
        "OldValues", "NewValues", "ChangedColumns",
        "UserId", "IpAddress", "RequestId"
    )
    VALUES (
        TG_TABLE_NAME,
        v_id_text::INTEGER,
        COALESCE(v_row ->> (TG_TABLE_NAME || 'Code'), v_id_text),
        TG_OP, v_old, v_new, v_changed,
        v_user_id, v_ip,
        NULLIF(current_setting('app.request_id', true), '')
    );
    RETURN NULL;
END;
$$;

-- Append-only: row-level guard (a future retention purge must disable this trigger)
CREATE FUNCTION audit_log_immutable() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'AuditLog is append-only (% not allowed)', TG_OP;
END;
$$;
CREATE TRIGGER trg_audit_log_immutable
    BEFORE UPDATE OR DELETE ON "AuditLog"
    FOR EACH ROW EXECUTE FUNCTION audit_log_immutable();

DO $$
DECLARE
    t RECORD;
BEGIN
    FOR t IN
        SELECT * FROM (VALUES
            ('DocumentType', ''), ('Sex', ''), ('Specialty', ''), ('PharmaceuticalForm', ''),
            ('AdministrationRoute', ''), ('Frequency', ''), ('Allergy', ''), ('AllergySeverity', ''),
            ('Medication', ''), ('Insurance', ''),
            ('PlatformUser', 'PasswordHash,LastAccess'),
            ('Partner', 'ApiKeyHash,LastHeartbeatAt,ApiVersion,DbSchemaVersion,SupportedCatalogSchemas,CatalogSchemaVersionSeen,CatalogVersionSeen'),
            ('PartnerLogo', 'Data')
        ) AS v(tbl, excluded)
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON %I '
            'FOR EACH ROW EXECUTE FUNCTION audit_row_change(%s)',
            t.tbl,
            CASE WHEN t.excluded = '' THEN ''
                 ELSE (SELECT string_agg(quote_literal(c), ',') FROM unnest(string_to_array(t.excluded, ',')) c) END
        );
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------------------
-- Roles
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'catalog_admin')  THEN CREATE ROLE catalog_admin  NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'catalog_reader') THEN CREATE ROLE catalog_reader NOLOGIN; END IF;
END;
$$;

REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;

-- catalog_admin: write path of rxlink-catalog-api. No DELETE anywhere (deactivate, never delete).
GRANT USAGE ON SCHEMA public TO catalog_admin, catalog_reader;
GRANT SELECT, INSERT, UPDATE ON
    "DocumentType", "Sex", "Specialty", "PharmaceuticalForm", "AdministrationRoute", "Frequency",
    "Allergy", "AllergySeverity", "Medication", "Insurance",
    "PlatformUser", "PlatformRefreshToken", "Partner", "PartnerLogo"
    TO catalog_admin;
GRANT SELECT, UPDATE ON "CatalogVersion" TO catalog_admin;
GRANT SELECT ON "AuditLog" TO catalog_admin;   -- inserts happen through the SECURITY DEFINER trigger
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO catalog_admin;

-- catalog_reader: group of the per-partner reader roles. Catalog tables + CatalogVersion only.
GRANT SELECT ON
    "DocumentType", "Sex", "Specialty", "PharmaceuticalForm", "AdministrationRoute", "Frequency",
    "Allergy", "AllergySeverity", "Medication", "Insurance", "CatalogVersion"
    TO catalog_reader;

-- ---------------------------------------------------------------------------
-- Self-only views for partner readers (§5.5)
-- Views run with the owner's rights, so readers need no access to the base tables.
-- session_user (not current_user, which inside a definer-rights view is the owner)
-- identifies the connecting partner role.
-- ---------------------------------------------------------------------------

CREATE VIEW partner_self AS
SELECT "PartnerCode", "Slug", "DisplayName", "LegalName", "Status", "Country", "Timezone",
       "Currency", "Locale", "ApiBaseUrl", "BrandPrimaryColor", "BrandAccentColor"
  FROM "Partner"
 WHERE "CatalogRoleName" = session_user;

CREATE VIEW partner_logo_self AS
SELECT l."ContentType", l."Data", l."Sha256", l."UpdatedAt"
  FROM "PartnerLogo" l
  JOIN "Partner" p ON p."PartnerId" = l."PartnerId"
 WHERE p."CatalogRoleName" = session_user;

GRANT SELECT ON partner_self, partner_logo_self TO catalog_reader;
