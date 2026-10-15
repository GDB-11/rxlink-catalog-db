#!/usr/bin/env bash
# Plan §14.1, first item: per catalog table, row count and the set of (id, code) pairs must be
# identical between the partner DB and the catalog DB. Exits non-zero on any difference.
# usage: verify-against-partner.sh <source-psql-conninfo> <target-psql-conninfo>   (same PSQL override as the seed script)
set -euo pipefail
SRC=${1:?source conninfo}; DST=${2:?target conninfo}
PSQL=${PSQL:-psql}
q() { $PSQL -X -qtA -v ON_ERROR_STOP=1 "$1" -c "$2"; }
rc=0
for spec in DocumentType:DocumentTypeId:DocumentTypeCode Sex:SexId:SexCode Specialty:SpecialtyId:SpecialtyCode \
            PharmaceuticalForm:PharmaceuticalFormId:PharmaceuticalFormCode AdministrationRoute:AdministrationRouteId:AdministrationRouteCode \
            Frequency:FrequencyId:FrequencyCode Allergy:AllergyId:AllergyCode AllergySeverity:SeverityId:SeverityCode \
            Medication:MedicationId:MedicationCode Insurance:InsuranceId:InsuranceCode; do
  IFS=: read -r t id code <<<"$spec"
  sql="SELECT count(*), md5(string_agg(\"$id\"::text||':'||\"$code\"::text, ',' ORDER BY \"$id\")) FROM \"$t\""
  a=$(q "$SRC" "$sql"); b=$(q "$DST" "$sql")
  if [[ "$a" == "$b" ]]; then echo "OK   $t (${a%%|*} rows)"; else echo "DIFF $t partner=[$a] catalog=[$b]"; rc=1; fi
done
exit $rc
