-- =============================================================================
-- Catalog supporting tables (plan §5.1, §5.5)
--   PlatformUser, PlatformRefreshToken, CatalogVersion, AuditLog, Partner, PartnerLogo
-- Also closes the Medication.DeletedBy FK left open in C001.
-- No PHI lives here (I5): organisations and deployments only.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS unaccent;

-- unaccent() is only STABLE; an index expression needs an IMMUTABLE wrapper.
CREATE FUNCTION immutable_unaccent(TEXT) RETURNS TEXT
LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT
AS $$ SELECT public.unaccent('public.unaccent'::regdictionary, $1) $$;

-- ---------------------------------------------------------------------------
-- Platform identity (separate from any partner's "User")
-- ---------------------------------------------------------------------------

CREATE TABLE "PlatformUser" (
    "PlatformUserId"   SERIAL       PRIMARY KEY,
    "PlatformUserCode" UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Username"         VARCHAR(50)  NOT NULL,
    "Email"            VARCHAR(255) NOT NULL,
    "PasswordHash"     TEXT         NOT NULL,
    "IsActive"         BOOLEAN      NOT NULL DEFAULT TRUE,
    "LastAccess"       TIMESTAMPTZ,
    "CreatedAt"        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "UpdatedAt"        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX uq_platform_user_username ON "PlatformUser" (lower("Username"));
CREATE UNIQUE INDEX uq_platform_user_email    ON "PlatformUser" (lower("Email"));

CREATE TABLE "PlatformRefreshToken" (
    "PlatformRefreshTokenId" SERIAL      PRIMARY KEY,
    "PlatformUserId"         INTEGER     NOT NULL REFERENCES "PlatformUser" ("PlatformUserId"),
    "TokenHash"              TEXT        NOT NULL,
    "ExpiresAt"              TIMESTAMPTZ NOT NULL,
    "CreatedAt"              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "SessionStartedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "IpAddress"              INET,
    "UserAgent"              TEXT,
    "RevokedAt"              TIMESTAMPTZ,
    "RevokedBy"              INTEGER REFERENCES "PlatformUser" ("PlatformUserId"),
    CONSTRAINT chk_platform_refresh_token_revocation
        CHECK ("RevokedAt" IS NULL OR "RevokedAt" >= "CreatedAt")
);
CREATE INDEX idx_platform_refresh_token_user ON "PlatformRefreshToken" ("PlatformUserId");
CREATE UNIQUE INDEX uq_platform_refresh_token_hash ON "PlatformRefreshToken" ("TokenHash");

ALTER TABLE "Medication"
    ADD CONSTRAINT fk_medication_deleted_by
    FOREIGN KEY ("DeletedBy") REFERENCES "PlatformUser" ("PlatformUserId");

-- ---------------------------------------------------------------------------
-- CatalogVersion: single row, bumped in the same transaction as every catalog write
-- ---------------------------------------------------------------------------

CREATE TABLE "CatalogVersion" (
    "CatalogVersionId" SMALLINT    PRIMARY KEY CHECK ("CatalogVersionId" = 1),
    "Version"          BIGINT      NOT NULL DEFAULT 1 CHECK ("Version" >= 1),
    "SchemaVersion"    INTEGER     NOT NULL DEFAULT 1 CHECK ("SchemaVersion" >= 1),
    "UpdatedAt"        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO "CatalogVersion" ("CatalogVersionId") VALUES (1);

-- ---------------------------------------------------------------------------
-- AuditLog (same shape as the partner table after V018; actor is a PlatformUser)
-- ---------------------------------------------------------------------------

CREATE TABLE "AuditLog" (
    "AuditLogId"     BIGSERIAL    PRIMARY KEY,
    "TableName"      VARCHAR(100) NOT NULL,
    "RecordId"       INTEGER,
    "RecordKey"      TEXT,
    "Action"         VARCHAR(10)  NOT NULL CHECK ("Action" IN ('INSERT', 'UPDATE', 'DELETE')),
    "OldValues"      JSONB,
    "NewValues"      JSONB,
    "ChangedColumns" TEXT[],
    "UserId"         INTEGER REFERENCES "PlatformUser" ("PlatformUserId"),  -- NULL = missed context
    "OccurredAt"     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "IpAddress"      INET,
    "RequestId"      TEXT
);
CREATE INDEX idx_audit_log_table_record_key ON "AuditLog" ("TableName", "RecordKey");
CREATE INDEX idx_audit_log_user_time        ON "AuditLog" ("UserId", "OccurredAt");
CREATE INDEX idx_audit_log_occurred_at      ON "AuditLog" ("OccurredAt");

-- ---------------------------------------------------------------------------
-- Partner registry (§5.5)
-- ---------------------------------------------------------------------------

CREATE TABLE "Partner" (
    "PartnerId"       SERIAL       PRIMARY KEY,
    "PartnerCode"     UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Slug"            VARCHAR(40)  NOT NULL UNIQUE CHECK ("Slug" ~ '^[a-z0-9-]{3,40}$'),
    "DisplayName"     VARCHAR(100) NOT NULL,
    "LegalName"       VARCHAR(200) NOT NULL,
    "TaxId"           CHAR(11)     NOT NULL UNIQUE CHECK ("TaxId" ~ '^[0-9]{11}$'),
    "Status"          VARCHAR(20)  NOT NULL DEFAULT 'Provisioning'
                          CHECK ("Status" IN ('Provisioning', 'Active', 'Suspended', 'Terminated')),
    "StatusReason"    TEXT,
    "StatusChangedAt" TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "DirectoryVisible" BOOLEAN     NOT NULL DEFAULT FALSE,
    "IsTest"          BOOLEAN      NOT NULL DEFAULT FALSE,
    "Country"         CHAR(2)      NOT NULL DEFAULT 'PE',
    "Timezone"        VARCHAR(64)  NOT NULL DEFAULT 'America/Lima',
    "Currency"        CHAR(3)      NOT NULL DEFAULT 'PEN',
    "Locale"          VARCHAR(10)  NOT NULL DEFAULT 'es-PE',
    "ApiBaseUrl"      VARCHAR(300) UNIQUE CHECK ("ApiBaseUrl" ~ '^https://'),
    "BrandPrimaryColor" CHAR(7)    CHECK ("BrandPrimaryColor" ~ '^#[0-9A-Fa-f]{6}$'),
    "BrandAccentColor"  CHAR(7)    CHECK ("BrandAccentColor"  ~ '^#[0-9A-Fa-f]{6}$'),
    "ContactName"     VARCHAR(150),
    "ContactEmail"    VARCHAR(255),
    "ContactPhone"    VARCHAR(30),
    "CatalogRoleName" VARCHAR(63)  UNIQUE,
    "ApiKeyHash"      TEXT,
    -- Heartbeat telemetry
    "ApiVersion"                VARCHAR(30),
    "DbSchemaVersion"           VARCHAR(30),
    "SupportedCatalogSchemas"   INT4RANGE,
    "CatalogSchemaVersionSeen"  INTEGER,
    "CatalogVersionSeen"        BIGINT,
    "LastHeartbeatAt"           TIMESTAMPTZ,
    "CreatedAt"       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "ActivatedAt"     TIMESTAMPTZ,
    "UpdatedAt"       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "UpdatedBy"       INTEGER REFERENCES "PlatformUser" ("PlatformUserId"),
    -- Only Active partners can be listed; test deployments never are
    CONSTRAINT chk_partner_directory
        CHECK (NOT "DirectoryVisible" OR ("Status" = 'Active' AND NOT "IsTest")),
    CONSTRAINT chk_partner_activated
        CHECK ("Status" <> 'Active' OR "ActivatedAt" IS NOT NULL)
);
CREATE UNIQUE INDEX uq_partner_display_name
    ON "Partner" (lower(immutable_unaccent("DisplayName")));

CREATE TABLE "PartnerLogo" (
    "PartnerId"   INTEGER     PRIMARY KEY REFERENCES "Partner" ("PartnerId"),
    "ContentType" VARCHAR(20) NOT NULL CHECK ("ContentType" IN ('image/png', 'image/webp')),
    "Data"        BYTEA       NOT NULL CHECK (octet_length("Data") <= 262144),
    "Sha256"      CHAR(64)    NOT NULL,
    "UpdatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
