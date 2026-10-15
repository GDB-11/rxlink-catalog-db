# rxlink-catalog-db

PostgreSQL migrations for the RxLink **shared catalog** database (`C001`…), separate from the partner stream in `rxlink-db` (`V001`…). Architecture: `rxlink-sv/docs/shared-catalog-and-platform-plan.md` (§5); progress: `rxlink-sv/docs/phase-2-implementation-tracker.md` (Phase 4).

## Rules

- Reference data only — **no patient data, no partner operational data** (I1, I5).
- Deactivate, never delete (plan §5.2). Codes (`…Code` UUID) are stable forever; the reference seed (C006) uses fixed codes.
- Only `rxlink-catalog-api` writes to this database; partners connect read-only.
- Requires PostgreSQL 18+ (`uuidv7()`).
- Non-production databases are built from migrations only, with synthetic data — never branch/clone production.

## Reference seed (Phase 9.2)

`C006__reference_seed.sql` loads every catalog table with **fixed codes** of the form `c0deTTTT-0000-4000-8000-<old integer id, 12 digits>` (`TTTT`: 0001 Sex, 0002 DocumentType, 0003 Specialty, 0004 PharmaceuticalForm, 0005 AdministrationRoute, 0006 Frequency, 0007 Allergy, 0008 AllergySeverity, 0009 Medication, 0010 Insurance, 0011 MedicationClass), so partner seeds, tests and the devstack can refer to rows by literal. It also seeds a small set of medication classes, allergy links and interaction rules from C005. The medication list and rules are **synthetic development content**; production content is curated through `rxlink-platform` and needs clinical review. The seed runs as the migration owner with no `app.user_code`, so the audit triggers write rows with a NULL actor (expected).

`scripts/verify-seed.sh <catalog-db>` checks row counts, NULL/duplicate codes and orphan rule rows (accepts `PSQL="podman exec -i pgtest psql -U postgres"` when no local psql exists; then the argument is the database name).

## Registering a partner (Phase 4.4)

`scripts/register-partner.sh <catalog> <logo.png|webp>` (identity and reader password via env vars, see the script header) creates, in one transaction, the `catalog_reader_<slug>` login role (member of `catalog_reader`), the `Partner` row (`Status = Active`, `CatalogRoleName` set) and its `PartnerLogo` (PNG/WebP, ≤256 KB, sha256 computed). It fails atomically if the slug, tax id, display name or role already exists. Pass `PARTNER_CODE` equal to the partner DB's `PartnerConfig.PartnerCode` so the Phase 7.3 startup check matches. No API key is issued (heartbeat, Phase 8).
