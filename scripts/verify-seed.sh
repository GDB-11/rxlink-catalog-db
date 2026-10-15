#!/usr/bin/env bash
# Verifies the C006 reference seed in a catalog database: expected row counts per table, no NULL or
# duplicated codes, no orphan rule rows. Exits non-zero on any mismatch.
# Usage: scripts/verify-seed.sh <catalog-db>     (PSQL="podman exec -i pgtest psql -U postgres" when no local psql)
set -euo pipefail
DB="${1:?usage: verify-seed.sh <catalog-db>}"
PSQL="${PSQL:-psql}"
fail=0
q() { $PSQL -d "$DB" -Atqc "$1"; }

# table:codecolumn:minimum row count after C006 (later platform edits only add rows, so compare with >=)
for spec in Sex:SexCode:2 DocumentType:DocumentTypeCode:3 Specialty:SpecialtyCode:30 PharmaceuticalForm:PharmaceuticalFormCode:10 \
            AdministrationRoute:AdministrationRouteCode:8 Frequency:FrequencyCode:8 Allergy:AllergyCode:26 \
            AllergySeverity:SeverityCode:4 Medication:MedicationCode:87 Insurance:InsuranceCode:7 \
            MedicationClass:MedicationClassCode:11 MedicationInteraction:MedicationInteractionCode:6; do
  IFS=: read -r t c n <<<"$spec"
  total=$(q "SELECT count(*) FROM \"$t\"")
  nulls=$(q "SELECT count(*) FROM \"$t\" WHERE \"$c\" IS NULL")
  dups=$(q "SELECT count(*) - count(DISTINCT \"$c\") FROM \"$t\"")
  status=ok
  if [ "$total" -lt "$n" ] || [ "$nulls" -ne 0 ] || [ "$dups" -ne 0 ]; then status=FAIL; fail=1; fi
  printf '%-22s rows=%-4s expected>=%-4s null_codes=%s duplicate_codes=%s %s\n' "$t" "$total" "$n" "$nulls" "$dups" "$status"
done
orph=$(q 'SELECT (SELECT count(*) FROM "MedicationClassMember" m LEFT JOIN "Medication" x USING ("MedicationId") WHERE x."MedicationId" IS NULL)
              + (SELECT count(*) FROM "AllergyMedicationClass" a LEFT JOIN "Allergy" x USING ("AllergyId") WHERE x."AllergyId" IS NULL)')
echo "orphan rule rows: $orph"; [ "$orph" -eq 0 ] || fail=1
exit $fail
