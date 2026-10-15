# rxlink-catalog-db

PostgreSQL migrations for the RxLink **shared catalog** database (`C001`…), separate from the partner stream in `rxlink-db` (`V001`…). Architecture: `rxlink-sv/docs/shared-catalog-and-platform-plan.md` (§5); progress: `rxlink-sv/docs/phase-2-implementation-tracker.md` (Phase 4).

## Rules

- Reference data only — **no patient data, no partner operational data** (I1, I5).
- Deactivate, never delete (plan §5.2). Codes (`…Code` UUID) are stable forever and copied verbatim from the partner DB when seeding.
- Only `rxlink-catalog-api` writes to this database; partners connect read-only.
- Requires PostgreSQL 18+ (`uuidv7()`).
- Non-production databases are built from migrations only, with synthetic data — never branch/clone production.

## Seeding from a partner DB (Phase 4.3)

`scripts/seed-from-partner.sh <source> <target>` copies the ten catalog tables from a partner DB into an empty catalog DB with **identical ids and `…Code` UUIDs** (drops `Specialty` prices and `Medication.DeletedBy`; `Sex.IsActive` = true; `CoveragePercentage` → `DefaultCoveragePercentage`). It only reads the source and refuses to run on a non-empty target. `scripts/verify-against-partner.sh` compares row counts and an md5 of every `(id, code)` pair per table. Both accept `PSQL="podman exec -i pgtest psql -U postgres"` when no local psql exists (then the arguments are database names). The initial load writes `AuditLog` rows with no actor (the audit triggers fire on the seed inserts) — expected.

## Registering a partner (Phase 4.4)

`scripts/register-partner.sh <catalog> <logo.png|webp>` (identity and reader password via env vars, see the script header) creates, in one transaction, the `catalog_reader_<slug>` login role (member of `catalog_reader`), the `Partner` row (`Status = Active`, `CatalogRoleName` set) and its `PartnerLogo` (PNG/WebP, ≤256 KB, sha256 computed). It fails atomically if the slug, tax id, display name or role already exists. Pass `PARTNER_CODE` equal to the partner DB's `PartnerConfig.PartnerCode` so the Phase 7.3 startup check matches. No API key is issued (heartbeat, Phase 8).
