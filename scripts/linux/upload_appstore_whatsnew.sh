#!/usr/bin/env bash
# Upload App Store "What's New" from release_notes/<version>/ via App Store Connect API.
#
# Usage:
#   ./scripts/linux/upload_appstore_whatsnew.sh <version> [--dry-run]
#
# Requires: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID,
#           APP_STORE_CONNECT_KEY_BASE64
#
# Always exits 0 (non-breaking). Warns and skips when notes or ASC version missing.
#
# --dry-run: write build/appstore-whatsnew/<locale>.txt only; no API calls.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_release_note_text.sh
source "$SCRIPT_DIR/_release_note_text.sh"

VERSION="${1:?version required (e.g. 1.3.7)}"
DRY_RUN=false
if [ "${2:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

NOTES_ROOT="${RELEASE_NOTES_ROOT:-release_notes}"
SOURCE="$NOTES_ROOT/$VERSION"
OUT="${APPSTORE_WHATSNEW_DIR:-build/appstore-whatsnew}"
MAX="${APPSTORE_WHATSNEW_MAX:-4000}"

# release_notes locale file -> App Store Connect locale id
declare -A APPSTORE_LOCALES=(
  [en]=en-US
  [de]=de-DE
  [tr]=tr
  [ar]=ar-SA
)

asc_jwt() {
  pip install cryptography --quiet 2>/dev/null || pip install cryptography --quiet
  local key_file
  key_file="$(mktemp /tmp/authkey.XXXXXX.p8)"
  echo "$APP_STORE_CONNECT_KEY_BASE64" | base64 --decode > "$key_file"
  KEY_FILE="$key_file" python3 - <<'PYEOF'
import json, time, base64, os
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
key_id = os.environ['APP_STORE_CONNECT_KEY_ID']
issuer_id = os.environ['APP_STORE_CONNECT_ISSUER_ID']
with open(os.environ['KEY_FILE'], 'rb') as f:
    pk = serialization.load_pem_private_key(f.read(), password=None)
now = int(time.time())
def b64u(d): return base64.urlsafe_b64encode(d if isinstance(d, bytes) else d.encode()).rstrip(b'=').decode()
h = b64u(json.dumps({'alg':'ES256','kid':key_id,'typ':'JWT'}, separators=(',',':')))
p = b64u(json.dumps({'iss':issuer_id,'iat':now,'exp':now+1200,'aud':'appstoreconnect-v1'}, separators=(',',':')))
msg = f'{h}.{p}'
r, s = decode_dss_signature(pk.sign(msg.encode(), ec.ECDSA(hashes.SHA256())))
print(f'{msg}.{b64u(r.to_bytes(32,"big")+s.to_bytes(32,"big"))}')
PYEOF
  rm -f "$key_file"
}

collect_notes() {
  local locale src asc_locale text
  NOTES_LOCALES=()
  NOTES_TEXTS=()

  if [ ! -d "$SOURCE" ]; then
    echo "Warning: no release notes at $SOURCE - App Store What's New skipped." >&2
    return 1
  fi

  rm -rf "$OUT"
  mkdir -p "$OUT"

  for locale in en de tr ar; do
    src="$SOURCE/$locale.md"
    asc_locale="${APPSTORE_LOCALES[$locale]}"
    if ! release_note_file_has_bullets "$src"; then
      continue
    fi
    text="$(release_note_extract_text "$src" "$MAX" "$src")" || continue
    [ -z "$text" ] && continue

    printf '%s' "$text" > "$OUT/$asc_locale.txt"
    echo "Prepared App Store $asc_locale from $locale.md ($(release_note_char_count "$text") chars)"
    NOTES_LOCALES+=("$asc_locale")
    NOTES_TEXTS+=("$text")
  done

  if [ "${#NOTES_LOCALES[@]}" -eq 0 ]; then
    rm -rf "$OUT"
    echo "Warning: no App Store What's New bullets for v$VERSION - skipped." >&2
    return 1
  fi

  return 0
}

upload_to_asc() {
  local jwt app_id version_id loc_json loc_id asc_locale text i payload http_code body

  for secret in APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_KEY_BASE64; do
    if [ -z "${!secret:-}" ]; then
      echo "Warning: missing $secret - App Store What's New skipped." >&2
      return 0
    fi
  done

  jwt="$(asc_jwt)"

  app_id="$(curl -gsS --fail-with-body \
    -H "Authorization: Bearer $jwt" \
    "https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=app.halalscan" \
    | jq -r '.data[0].id')"
  echo "App ID: $app_id"

  version_id="$(curl -gsS --fail-with-body \
    -H "Authorization: Bearer $jwt" \
    "https://api.appstoreconnect.apple.com/v1/apps/$app_id/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION&filter[versionString]=$VERSION" \
    | jq -r '.data[0].id')"

  if [ -z "$version_id" ] || [ "$version_id" = "null" ]; then
    echo "Warning: no iOS version $VERSION in PREPARE_FOR_SUBMISSION - What's New not uploaded." >&2
    echo "Create the version in App Store Connect before Gate 1 (submit-review)." >&2
    curl -gsS -H "Authorization: Bearer $jwt" \
      "https://api.appstoreconnect.apple.com/v1/apps/$app_id/appStoreVersions?filter[platform]=IOS" \
      | jq '.data[] | {id: .id, version: .attributes.versionString, state: .attributes.appStoreState}' || true
    return 0
  fi

  echo "Version ID: $version_id"

  loc_json="$(curl -gsS --fail-with-body \
    -H "Authorization: Bearer $jwt" \
    "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$version_id/appStoreVersionLocalizations?limit=200")"

  for i in "${!NOTES_LOCALES[@]}"; do
    asc_locale="${NOTES_LOCALES[$i]}"
    text="${NOTES_TEXTS[$i]}"

    loc_id="$(echo "$loc_json" | jq -r --arg loc "$asc_locale" \
      '.data[] | select(.attributes.locale == $loc) | .id' | head -1)"

    if [ -z "$loc_id" ] || [ "$loc_id" = "null" ]; then
      echo "Warning: no App Store localization for $asc_locale on version $VERSION - skipped." >&2
      continue
    fi

    payload="$(jq -n --arg id "$loc_id" --arg text "$text" \
      '{data:{type:"appStoreVersionLocalizations",id:$id,attributes:{whatsNew:$text}}}')"

    response="$(curl -gsS -w "\n%{http_code}" \
      -X PATCH \
      -H "Authorization: Bearer $jwt" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$loc_id")"
    http_code="$(echo "$response" | tail -1)"
    body="$(echo "$response" | sed '$d')"

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
      echo "Uploaded What's New for $asc_locale."
    else
      echo "Warning: failed to upload What's New for $asc_locale (HTTP $http_code):" >&2
      echo "$body" | jq '.errors[0].detail' 2>/dev/null || echo "$body" >&2
    fi
  done
}

if ! collect_notes; then
  exit 0
fi

if $DRY_RUN; then
  echo "$OUT"
  exit 0
fi

upload_to_asc || true
exit 0
