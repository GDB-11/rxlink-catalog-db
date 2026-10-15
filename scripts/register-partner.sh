#!/usr/bin/env bash
# Registers a partner in the catalog registry by direct SQL (plan §5.5 provisioning flow,
# Phase 4.4; the admin UI only exists from Phase 8): creates the Partner row, uploads its
# logo, creates the catalog_reader_<slug> role and sets CatalogRoleName. Idempotent-safe:
# refuses if the slug, tax id or role already exists. Reads nothing from any partner DB.
#
# usage: register-partner.sh <catalog-conninfo> <logo.png|logo.webp>
# Required env:
#   PARTNER_SLUG          a-z0-9-, 3–40 chars (immutable once Active)
#   PARTNER_DISPLAY_NAME  shown in login/headers/directory (≤100)
#   PARTNER_LEGAL_NAME
#   PARTNER_TAX_ID        RUC, 11 digits
#   PARTNER_API_BASE_URL  https://… base URL of the partner API
#   READER_PASSWORD       password of the new catalog_reader_<slug> login role (never stored by the script)
# Optional env:
#   PARTNER_CODE          UUID to use as PartnerCode. Pass the value already in the partner DB's
#                         PartnerConfig so both sides match (otherwise one is generated and the
#                         partner DB must be updated to it later — Phase 7.3 startup check).
#   PARTNER_IS_TEST       true|false (default false)
#   DIRECTORY_VISIBLE     true|false (default false)
#   BRAND_PRIMARY_COLOR / BRAND_ACCENT_COLOR   #RRGGBB
#   CONTACT_NAME / CONTACT_EMAIL / CONTACT_PHONE
#   PSQL                  e.g. "podman exec -i pgtest psql -U postgres" (conninfo is then a db name)
# The partner ends up Status='Active'. No API key is issued here (heartbeat auth is Phase 8.5/8.6).
set -euo pipefail
DB=${1:?catalog conninfo}; LOGO=${2:?logo file}
PSQL=${PSQL:-psql}
: "${PARTNER_SLUG:?}" "${PARTNER_DISPLAY_NAME:?}" "${PARTNER_LEGAL_NAME:?}" "${PARTNER_TAX_ID:?}" \
  "${PARTNER_API_BASE_URL:?}" "${READER_PASSWORD:?}"

[[ "$PARTNER_SLUG" =~ ^[a-z0-9-]{3,40}$ ]] || { echo "invalid PARTNER_SLUG" >&2; exit 1; }
ROLE="catalog_reader_${PARTNER_SLUG//-/_}"   # hyphens are awkward in role names
[[ ${#ROLE} -le 63 ]] || { echo "role name too long" >&2; exit 1; }

[[ -f "$LOGO" ]] || { echo "logo not found: $LOGO" >&2; exit 1; }
SIZE=$(stat -c %s "$LOGO")
(( SIZE > 0 && SIZE <= 262144 )) || { echo "logo must be 1 byte–256 KB (is $SIZE)" >&2; exit 1; }
MAGIC=$(head -c 12 "$LOGO" | od -An -tx1 | tr -d ' \n')
if [[ "$MAGIC" == 89504e470d0a1a0a* ]]; then CT=image/png
elif [[ "${MAGIC:0:8}" == 52494646 && "${MAGIC:16:8}" == 57454250 ]]; then CT=image/webp
else echo "logo must be PNG or WebP" >&2; exit 1; fi
HEX=$(od -An -v -tx1 "$LOGO" | tr -d ' \n')
SHA=$(sha256sum "$LOGO" | cut -d' ' -f1)

$PSQL -X -q -v ON_ERROR_STOP=1 "$DB" \
  -v slug="$PARTNER_SLUG" -v dname="$PARTNER_DISPLAY_NAME" -v lname="$PARTNER_LEGAL_NAME" \
  -v taxid="$PARTNER_TAX_ID" -v apiurl="$PARTNER_API_BASE_URL" -v role="$ROLE" \
  -v rpass="$READER_PASSWORD" -v pcode="${PARTNER_CODE:-}" \
  -v istest="${PARTNER_IS_TEST:-false}" -v dirvis="${DIRECTORY_VISIBLE:-false}" \
  -v c1="${BRAND_PRIMARY_COLOR:-}" -v c2="${BRAND_ACCENT_COLOR:-}" \
  -v cname="${CONTACT_NAME:-}" -v cmail="${CONTACT_EMAIL:-}" -v cphone="${CONTACT_PHONE:-}" \
  -v ct="$CT" -v sha="$SHA" -v hex="$HEX" <<'SQL'
BEGIN;

-- Role first: if it already exists the whole thing aborts before any registry row is written.
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L IN ROLE catalog_reader', :'role', :'rpass') \gexec

WITH p AS (
  INSERT INTO "Partner" ("PartnerCode", "Slug", "DisplayName", "LegalName", "TaxId", "Status",
                         "IsTest", "DirectoryVisible", "ApiBaseUrl", "BrandPrimaryColor",
                         "BrandAccentColor", "ContactName", "ContactEmail", "ContactPhone",
                         "CatalogRoleName", "ActivatedAt")
  VALUES (COALESCE(NULLIF(:'pcode', '')::uuid, uuidv7()), :'slug', :'dname', :'lname', :'taxid',
          'Active', :'istest'::boolean, :'dirvis'::boolean, :'apiurl',
          NULLIF(:'c1', ''), NULLIF(:'c2', ''), NULLIF(:'cname', ''), NULLIF(:'cmail', ''),
          NULLIF(:'cphone', ''), :'role', NOW())
  RETURNING "PartnerId"
)
INSERT INTO "PartnerLogo" ("PartnerId", "ContentType", "Data", "Sha256")
SELECT "PartnerId", :'ct', decode(:'hex', 'hex'), :'sha' FROM p;

COMMIT;

SELECT "PartnerCode", "Slug", "DisplayName", "Status", "CatalogRoleName" FROM "Partner" WHERE "Slug" = :'slug';
SQL
echo "registered partner '$PARTNER_SLUG' with reader role '$ROLE'"
