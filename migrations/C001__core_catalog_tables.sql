-- =============================================================================
-- Shared catalog — the ten core catalog tables (plan §5.1)
-- Requires PostgreSQL 18+ (uuidv7)
--
-- Structure mirrors the partner tables so the move is mechanical, except:
--   * Sex gets IsActive
--   * Specialty has no price columns (partner-local, see PartnerSpecialty)
--   * Insurance stores DefaultCoveragePercentage (D23); partners may override it
--   * Medication.DeletedBy references PlatformUser (added in C002); the FK is
--     created there because PlatformUser does not exist yet
-- Rows are deactivated, never deleted (plan §5.2). Codes are stable forever.
-- =============================================================================

CREATE TABLE "DocumentType" (
    "DocumentTypeId"   SERIAL      PRIMARY KEY,
    "DocumentTypeCode" UUID        NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"             VARCHAR(20) NOT NULL,
    "IsActive"         BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE "Sex" (
    "SexId"    SERIAL      PRIMARY KEY,
    "SexCode"  UUID        NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"     VARCHAR(50) NOT NULL,
    "IsActive" BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE "Specialty" (
    "SpecialtyId"   SERIAL       PRIMARY KEY,
    "SpecialtyCode" UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"          VARCHAR(100) NOT NULL,
    "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE "PharmaceuticalForm" (
    "PharmaceuticalFormId"   SERIAL       PRIMARY KEY,
    "PharmaceuticalFormCode" UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"                   VARCHAR(100) NOT NULL,
    "IsActive"               BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE "AdministrationRoute" (
    "AdministrationRouteId"   SERIAL       PRIMARY KEY,
    "AdministrationRouteCode" UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"                    VARCHAR(100) NOT NULL,
    "IsActive"                BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE "Frequency" (
    "FrequencyId"   SERIAL       PRIMARY KEY,
    "FrequencyCode" UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Description"   VARCHAR(200) NOT NULL,
    "IntervalHours" INTEGER      NOT NULL CHECK ("IntervalHours" > 0),
    "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE "Allergy" (
    "AllergyId"   SERIAL       PRIMARY KEY,
    "AllergyCode" UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"        VARCHAR(150) NOT NULL,
    "Description" TEXT,
    "IsActive"    BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE "AllergySeverity" (
    "SeverityId"   SERIAL      PRIMARY KEY,
    "SeverityCode" UUID        NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"         VARCHAR(50) NOT NULL,
    "SortOrder"    SMALLINT    NOT NULL DEFAULT 0,
    "IsActive"     BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE "Medication" (
    "MedicationId"          SERIAL       PRIMARY KEY,
    "MedicationCode"        UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "PharmaceuticalFormId"  INTEGER      NOT NULL REFERENCES "PharmaceuticalForm" ("PharmaceuticalFormId"),
    "AdministrationRouteId" INTEGER      NOT NULL REFERENCES "AdministrationRoute" ("AdministrationRouteId"),
    "GenericName"           VARCHAR(200) NOT NULL,
    "CommercialName"        VARCHAR(200),
    "Concentration"         VARCHAR(50)  NOT NULL,
    "IsActive"              BOOLEAN      NOT NULL DEFAULT TRUE,
    "DeletedAt"             TIMESTAMPTZ,
    "DeletedBy"             INTEGER
);

CREATE INDEX idx_medication_pharmaceutical_form_id  ON "Medication" ("PharmaceuticalFormId");
CREATE INDEX idx_medication_administration_route_id ON "Medication" ("AdministrationRouteId");

CREATE TABLE "Insurance" (
    "InsuranceId"               SERIAL       PRIMARY KEY,
    "InsuranceCode"             UUID         NOT NULL DEFAULT uuidv7() UNIQUE,
    "Name"                      VARCHAR(100) NOT NULL,
    "DefaultCoveragePercentage" NUMERIC(5,2) NOT NULL CHECK ("DefaultCoveragePercentage" BETWEEN 0 AND 100),
    "IsActive"                  BOOLEAN      NOT NULL DEFAULT TRUE
);
