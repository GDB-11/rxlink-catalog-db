-- =============================================================================
-- C004: PlatformUser MFA + account lockout (Phase 8.7)
--
-- PlatformUserMfa: TOTP second factor, same shape as the partner "UserMfa" (V022).
--   A row with ConfirmedAt NULL is a pending enrollment and does not affect login.
--   SecretEncrypted is encrypted by rxlink-catalog-api; LastUsedStep is the last
--   accepted 30 s step (replay protection).
-- PlatformUserLockout: consecutive failed credential attempts (password AND MFA code),
--   reset on a completed login. Separate table so the churn is not audited row by row.
-- =============================================================================

CREATE TABLE "PlatformUserMfa" (
    "PlatformUserMfaId" SERIAL      PRIMARY KEY,
    "PlatformUserId"    INTEGER     NOT NULL UNIQUE REFERENCES "PlatformUser" ("PlatformUserId"),
    "SecretEncrypted"   TEXT        NOT NULL,
    "ConfirmedAt"       TIMESTAMPTZ,
    "LastUsedStep"      BIGINT,
    "CreatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit enrollment/confirmation/reset, but never the secret; LastUsedStep churns on every login.
CREATE TRIGGER trg_audit AFTER INSERT OR UPDATE OR DELETE ON "PlatformUserMfa"
    FOR EACH ROW EXECUTE FUNCTION audit_row_change('SecretEncrypted', 'LastUsedStep');

CREATE TABLE "PlatformUserLockout" (
    "PlatformUserId" INTEGER     PRIMARY KEY REFERENCES "PlatformUser" ("PlatformUserId"),
    "FailedCount"    INTEGER     NOT NULL DEFAULT 0,
    "LockedUntil"    TIMESTAMPTZ,
    "LastFailedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- catalog_admin has no DELETE anywhere else; MFA reset (lost device) is the one exception.
GRANT SELECT, INSERT, UPDATE, DELETE ON "PlatformUserMfa"      TO catalog_admin;
GRANT SELECT, INSERT, UPDATE         ON "PlatformUserLockout"  TO catalog_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO catalog_admin;
