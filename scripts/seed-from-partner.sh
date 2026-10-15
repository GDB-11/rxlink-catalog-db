#!/usr/bin/env bash
# Copies the ten catalog tables from a partner DB (rxlink-db) into an empty catalog DB
# (rxlink-catalog-db, C001–C003 applied), keeping every id and every …Code UUID verbatim
# (plan §14 step 1). Partner-only columns are dropped: Specialty prices, Medication.DeletedBy.
#
# usage: seed-from-partner.sh <source-psql-conninfo> <target-psql-conninfo>
#   e.g. seed-from-partner.sh "postgresql://postgres:x@localhost:55432/partner" "postgresql://postgres:x@localhost:55432/catalog"
# Read-only on the source. Refuses to run if any target catalog table already has rows.
# Needs a psql client on PATH, or set PSQL="podman exec -i pgtest psql -U postgres" (conninfo is then a db name).
set -euo pipefail
SRC=${1:?source conninfo}; DST=${2:?target conninfo}
PSQL=${PSQL:-psql}
run() { local target=$1; shift; $PSQL -X -q -v ON_ERROR_STOP=1 "$target" "$@"; }

# table | target columns | source select (same order) | identity sequence column
# Parent tables first (Medication references PharmaceuticalForm / AdministrationRoute).
TABLES=(
 'DocumentType|"DocumentTypeId","DocumentTypeCode","Name","IsActive"|"DocumentTypeId","DocumentTypeCode","Name","IsActive"|DocumentTypeId'
 'Sex|"SexId","SexCode","Name","IsActive"|"SexId","SexCode","Name",TRUE|SexId'
 'Specialty|"SpecialtyId","SpecialtyCode","Name","IsActive"|"SpecialtyId","SpecialtyCode","Name","IsActive"|SpecialtyId'
 'PharmaceuticalForm|"PharmaceuticalFormId","PharmaceuticalFormCode","Name","IsActive"|"PharmaceuticalFormId","PharmaceuticalFormCode","Name","IsActive"|PharmaceuticalFormId'
 'AdministrationRoute|"AdministrationRouteId","AdministrationRouteCode","Name","IsActive"|"AdministrationRouteId","AdministrationRouteCode","Name","IsActive"|AdministrationRouteId'
 'Frequency|"FrequencyId","FrequencyCode","Description","IntervalHours","IsActive"|"FrequencyId","FrequencyCode","Description","IntervalHours","IsActive"|FrequencyId'
 'Allergy|"AllergyId","AllergyCode","Name","Description","IsActive"|"AllergyId","AllergyCode","Name","Description","IsActive"|AllergyId'
 'AllergySeverity|"SeverityId","SeverityCode","Name","SortOrder","IsActive"|"SeverityId","SeverityCode","Name","SortOrder","IsActive"|SeverityId'
 'Medication|"MedicationId","MedicationCode","PharmaceuticalFormId","AdministrationRouteId","GenericName","CommercialName","Concentration","IsActive","DeletedAt","DeletedBy"|"MedicationId","MedicationCode","PharmaceuticalFormId","AdministrationRouteId","GenericName","CommercialName","Concentration","IsActive","DeletedAt",NULL::integer|MedicationId'
 'Insurance|"InsuranceId","InsuranceCode","Name","DefaultCoveragePercentage","IsActive"|"InsuranceId","InsuranceCode","Name","CoveragePercentage","IsActive"|InsuranceId'
)

for spec in "${TABLES[@]}"; do
  IFS='|' read -r t _ _ _ <<<"$spec"
  n=$(run "$DST" -tA -c "SELECT count(*) FROM \"$t\"")
  [[ "$n" == 0 ]] || { echo "target \"$t\" already has $n rows; refusing to seed" >&2; exit 1; }
done

for spec in "${TABLES[@]}"; do
  IFS='|' read -r t tcols scols seq <<<"$spec"
  run "$SRC" -c "\\copy (SELECT $scols FROM \"$t\" ORDER BY 1) TO STDOUT WITH (FORMAT csv)" \
    | run "$DST" -c "\\copy \"$t\" ($tcols) FROM STDIN WITH (FORMAT csv)"
  run "$DST" -qtA -c "SELECT setval(pg_get_serial_sequence('\"$t\"','$seq'), GREATEST(COALESCE((SELECT max(\"$seq\") FROM \"$t\"),0),1), (SELECT count(*) > 0 FROM \"$t\"))" >/dev/null
  echo "seeded $t"
done
