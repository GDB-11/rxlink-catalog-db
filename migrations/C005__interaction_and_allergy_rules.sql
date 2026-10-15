-- =============================================================================
-- C005: allergen <-> medication-class mapping and class-class interaction rules
--       (Phase 11.1; plan §13 "Allergy and drug-interaction checks")
--
-- Rules are expressed over MEDICATION CLASSES, not individual medications, so one rule
-- covers every product in the class:
--   MedicationClass         a therapeutic/chemical group (e.g. penicillins, NSAIDs)
--   MedicationClassMember   which medications belong to a class (many-to-many)
--   AllergyMedicationClass  an allergy implies avoiding every medication of the class
--   MedicationInteraction   two classes that should not be combined, with a severity
-- A single-product allergy is modelled as a class with one member.
--
-- Additive change: CatalogVersion.SchemaVersion stays at 1 (older partner builds ignore
-- the new tables). Rows are deactivated, never deleted. Join tables carry a serial
-- <Table>Id because the generic audit trigger keys rows by it.
-- =============================================================================

CREATE TABLE "MedicationClass" (
    "MedicationClassId"   SERIAL       PRIMARY KEY,
    "MedicationClassCode" UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"                VARCHAR(150) NOT NULL,
    "Description"         TEXT,
    "IsActive"            BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE UNIQUE INDEX uq_medication_class_name ON "MedicationClass" (LOWER("Name"));

CREATE TABLE "MedicationClassMember" (
    "MedicationClassMemberId" SERIAL  PRIMARY KEY,
    "MedicationClassId"       INTEGER NOT NULL REFERENCES "MedicationClass" ("MedicationClassId"),
    "MedicationId"            INTEGER NOT NULL REFERENCES "Medication" ("MedicationId"),
    "IsActive"                BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE ("MedicationClassId", "MedicationId")
);

CREATE INDEX idx_medication_class_member_medication_id ON "MedicationClassMember" ("MedicationId");

CREATE TABLE "AllergyMedicationClass" (
    "AllergyMedicationClassId" SERIAL  PRIMARY KEY,
    "AllergyId"                INTEGER NOT NULL REFERENCES "Allergy" ("AllergyId"),
    "MedicationClassId"        INTEGER NOT NULL REFERENCES "MedicationClass" ("MedicationClassId"),
    "IsActive"                 BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE ("AllergyId", "MedicationClassId")
);

CREATE INDEX idx_allergy_medication_class_class_id ON "AllergyMedicationClass" ("MedicationClassId");

CREATE TABLE "MedicationInteraction" (
    "MedicationInteractionId"   SERIAL      PRIMARY KEY,
    "MedicationInteractionCode" UUID        NOT NULL DEFAULT uuidv7() UNIQUE,
    "MedicationClassAId"        INTEGER     NOT NULL REFERENCES "MedicationClass" ("MedicationClassId"),
    "MedicationClassBId"        INTEGER     NOT NULL REFERENCES "MedicationClass" ("MedicationClassId"),
    "Severity"                  VARCHAR(20) NOT NULL
                                CHECK ("Severity" IN ('Minor', 'Moderate', 'Major', 'Contraindicated')),
    "Description"               TEXT        NOT NULL,
    "IsActive"                  BOOLEAN     NOT NULL DEFAULT TRUE,
    -- unordered pair stored once (A < B); same-class pairs (e.g. two NSAIDs) are allowed via A = B
    CHECK ("MedicationClassAId" <= "MedicationClassBId"),
    UNIQUE ("MedicationClassAId", "MedicationClassBId")
);

CREATE INDEX idx_medication_interaction_class_b_id ON "MedicationInteraction" ("MedicationClassBId");

-- Audit triggers, same function and conventions as C003
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['MedicationClass', 'MedicationClassMember', 'AllergyMedicationClass', 'MedicationInteraction']
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON %I '
            'FOR EACH ROW EXECUTE FUNCTION audit_row_change()', t);
    END LOOP;
END;
$$;

-- Grants, same model as C003: catalog_admin writes (no DELETE), partner readers read
GRANT SELECT, INSERT, UPDATE ON
    "MedicationClass", "MedicationClassMember", "AllergyMedicationClass", "MedicationInteraction"
    TO catalog_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO catalog_admin;
GRANT SELECT ON
    "MedicationClass", "MedicationClassMember", "AllergyMedicationClass", "MedicationInteraction"
    TO catalog_reader;

-- Tables only; rules are curated through rxlink-catalog-api / rxlink-platform and need
-- clinical review before use, so nothing is seeded here.
UPDATE "CatalogVersion" SET "Version" = "Version" + 1, "UpdatedAt" = NOW() WHERE "CatalogVersionId" = 1;
