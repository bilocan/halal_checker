#!/usr/bin/env bash
# Ensure an iOS App Store version row exists for Gate 1 (submit-review).
#
# Apple allows only one in-flight App Store version per app+platform. A row stuck
# in an editable state (e.g. DEVELOPER_REJECTED) blocks POST with HTTP 409 even
# when the versionString differs — reuse by PATCHing versionString when needed.
#
# Usage:
#   VERSION=1.3.17 APP_ID=... JWT=... ./scripts/ci/ensure_app_store_version.sh
#
# Also: expire/delete stale PREPARE_FOR_SUBMISSION drafts != target before create.
# Writes version_id to GITHUB_OUTPUT when set.
set -euo pipefail

VERSION="${VERSION:?VERSION required (e.g. 1.3.17)}"
JWT="${JWT:?JWT required}"
APP_ID="${APP_ID:?APP_ID required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EDITABLE_STATES='PREPARE_FOR_SUBMISSION|DEVELOPER_REJECTED|DEVELOPER_ACTION_NEEDED|METADATA_REJECTED|INVALID_BINARY|REJECTED'
LOCKED_STATES='WAITING_FOR_REVIEW|IN_REVIEW|PENDING_DEVELOPER_RELEASE|PENDING_APPLE_RELEASE|PROCESSING_FOR_APP_STORE|READY_FOR_SALE|REPLACED_WITH_NEW_VERSION|WAITING_FOR_EXPORT_COMPLIANCE|PENDING_CONTRACT'

list_versions() {
  curl -gsS -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/appStoreVersions?filter[platform]=IOS&limit=50" \
    | jq '.data[] | {id: .id, version: .attributes.versionString, state: .attributes.appStoreState}'
}

fetch_target_version_id() {
  curl -gsS --fail-with-body \
    -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/appStoreVersions?filter[platform]=IOS&filter[versionString]=$VERSION&limit=1" \
    | jq -r '.data[0].id // empty'
}

fetch_versions_json() {
  curl -gsS --fail-with-body \
    -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/appStoreVersions?filter[platform]=IOS&limit=50"
}

find_editable_inflight() {
  # stdout: id|versionString|state  (first editable row, any version)
  fetch_versions_json \
    | jq -r --arg re "$EDITABLE_STATES" \
      '.data[] | select(.attributes.appStoreState | test($re)) | [.id, .attributes.versionString, .attributes.appStoreState] | @tsv' \
    | head -1
}

find_blocking_non_target() {
  # Any non-shipped iOS version row that is not the target (occupies Apple's single slot).
  fetch_versions_json \
    | jq -r --arg target "$VERSION" \
      '.data[] |
        select(.attributes.versionString != $target) |
        select(.attributes.appStoreState != "READY_FOR_SALE") |
        select(.attributes.appStoreState != "REPLACED_WITH_NEW_VERSION") |
        select(.attributes.appStoreState != "REMOVED_FROM_SALE") |
        [.id, .attributes.versionString, .attributes.appStoreState] | @tsv' \
    | head -1
}

is_locked_state() {
  local state="$1"
  [[ " $LOCKED_STATES " == *" $state "* ]]
}

repurpose_version_row() {
  local version_id="$1"
  local existing_version="$2"
  local existing_state="$3"

  if is_locked_state "$existing_state"; then
    echo "::error::App Store version $existing_version is in $existing_state — already with Apple." >&2
    echo "::error::Wait for review to finish or cancel in App Store Connect, then re-run." >&2
    list_versions >&2
    exit 1
  fi

  if [ "$existing_version" = "$VERSION" ]; then
    echo "Using existing $existing_state version $VERSION (ID: $version_id)." >&2
    printf '%s' "$version_id"
    return 0
  fi

  echo "Repurposing $existing_state row $version_id: $existing_version -> $VERSION" >&2
  JWT="$JWT" APP_ID="$APP_ID" bash "$SCRIPT_DIR/expire_testflight_versions.sh" "$existing_version" || true

  PATCH_HTTP=$(curl -sS -o /tmp/asc_patch_body.json -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    -d "{\"data\":{\"type\":\"appStoreVersions\",\"id\":\"$version_id\",\"attributes\":{\"versionString\":\"$VERSION\"}}}" \
    "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$version_id")
  if [ "$PATCH_HTTP" -lt 200 ] || [ "$PATCH_HTTP" -ge 300 ]; then
    echo "::error::Could not repurpose version row $version_id (HTTP $PATCH_HTTP):" >&2
    jq '.' /tmp/asc_patch_body.json 2>/dev/null || cat /tmp/asc_patch_body.json >&2
    list_versions >&2
    exit 1
  fi
  echo "Repurposed App Store version row to $VERSION." >&2
  printf '%s' "$version_id"
}

clear_stale_prepare_versions() {
  local stale_versions stale_ids stale_id stale_ver
  stale_versions=$(fetch_versions_json \
    | jq -r --arg target "$VERSION" \
      '[.data[] | select(.attributes.appStoreState == "PREPARE_FOR_SUBMISSION" and .attributes.versionString != $target) | .attributes.versionString] | join(",")')
  if [ -z "$stale_versions" ]; then
    return 0
  fi
  echo "Clearing stale Prepare for Submission versions: $stale_versions"
  JWT="$JWT" APP_ID="$APP_ID" bash "$SCRIPT_DIR/expire_testflight_versions.sh" "$stale_versions"

  stale_ids=$(fetch_versions_json \
    | jq -r --arg target "$VERSION" \
      '.data[] | select(.attributes.appStoreState == "PREPARE_FOR_SUBMISSION" and .attributes.versionString != $target) | .id')
  while IFS= read -r stale_id; do
    [ -n "$stale_id" ] || continue
    stale_ver=$(curl -gsS --fail-with-body \
      -H "Authorization: Bearer $JWT" \
      "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$stale_id" \
      | jq -r '.data.attributes.versionString // empty')
    echo "Deleting App Store version $stale_ver (ID: $stale_id)..."
    DELETE_HTTP=$(curl -sS -o /dev/null -w "%{http_code}" -X DELETE \
      -H "Authorization: Bearer $JWT" \
      "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$stale_id")
    if [ "$DELETE_HTTP" = "204" ] || [ "$DELETE_HTTP" = "200" ]; then
      echo "Deleted App Store version $stale_ver."
    else
      echo "::warning::Could not delete App Store version $stale_ver (HTTP $DELETE_HTTP)."
    fi
  done <<< "$stale_ids"
}

create_app_store_version() {
  echo "Creating App Store version $VERSION..."
  local create_resp create_http create_body
  create_resp=$(curl -gsS -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    -d "{\"data\":{\"type\":\"appStoreVersions\",\"attributes\":{\"platform\":\"IOS\",\"versionString\":\"$VERSION\",\"releaseType\":\"MANUAL\"},\"relationships\":{\"app\":{\"data\":{\"type\":\"apps\",\"id\":\"$APP_ID\"}}}}}" \
    "https://api.appstoreconnect.apple.com/v1/appStoreVersions")
  create_http=$(echo "$create_resp" | tail -1)
  create_body=$(echo "$create_resp" | sed '$d')
  printf '%s\n' "$create_http"
  printf '%s\n' "$create_body"
}

resolve_after_create_failure() {
  local http_code="$1"
  local body="$2"
  local version_id row existing_id existing_ver existing_state

  version_id=$(fetch_target_version_id)
  if [ -n "$version_id" ]; then
    echo "Target version $VERSION already exists (ID: $version_id) after HTTP $http_code."
    printf '%s' "$version_id"
    return 0
  fi

  row=$(find_editable_inflight || true)
  if [ -z "$row" ]; then
    row=$(find_blocking_non_target || true)
  fi
  if [ -n "$row" ]; then
    existing_id=$(echo "$row" | cut -f1)
    existing_ver=$(echo "$row" | cut -f2)
    existing_state=$(echo "$row" | cut -f3)
    repurpose_version_row "$existing_id" "$existing_ver" "$existing_state"
    return 0
  fi

  # Version string may already exist in a shipped/released state.
  if echo "$body" | jq -e '.errors[] | select(.code == "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE")' >/dev/null 2>&1; then
    echo "::error::Version $VERSION was already used on App Store Connect — bump pubspec marketing version." >&2
  fi

  echo "::error::Could not create App Store version $VERSION (HTTP $http_code):" >&2
  echo "$body" | jq '.errors[] | {code, detail, title}' 2>/dev/null || echo "$body" >&2
  echo "Current iOS App Store versions:" >&2
  list_versions >&2
  exit 1
}

write_output() {
  local version_id="$1"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "version_id=$version_id" >> "$GITHUB_OUTPUT"
  fi
}

main() {
  local version_id row existing_id existing_ver existing_state
  local create_result create_http create_body

  version_id=$(fetch_target_version_id)
  if [ -n "$version_id" ]; then
    local version_state
    version_state=$(curl -gsS --fail-with-body \
      -H "Authorization: Bearer $JWT" \
      "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$version_id" \
      | jq -r '.data.attributes.appStoreState // empty')
    echo "Version $VERSION already exists in state: $version_state (ID: $version_id)"
    write_output "$version_id"
    return 0
  fi

  row=$(find_editable_inflight || true)
  if [ -z "$row" ]; then
    row=$(find_blocking_non_target || true)
  fi
  if [ -n "$row" ]; then
    existing_id=$(echo "$row" | cut -f1)
    existing_ver=$(echo "$row" | cut -f2)
    existing_state=$(echo "$row" | cut -f3)
    version_id=$(repurpose_version_row "$existing_id" "$existing_ver" "$existing_state")
    write_output "$version_id"
    return 0
  fi

  clear_stale_prepare_versions

  create_result=$(create_app_store_version)
  create_http=$(echo "$create_result" | head -1)
  create_body=$(echo "$create_result" | tail -n +2)

  if [ "$create_http" -ge 400 ]; then
    echo "Create failed (HTTP $create_http) — resolving..."
    echo "$create_body" | jq '.errors[] | {code, detail, title}' 2>/dev/null || echo "$create_body"
    clear_stale_prepare_versions
    sleep 2
    version_id=$(resolve_after_create_failure "$create_http" "$create_body")
    write_output "$version_id"
    return 0
  fi

  version_id=$(echo "$create_body" | jq -r '.data.id // empty')
  echo "Created App Store version $VERSION (ID: $version_id)."

  if [ -z "$version_id" ]; then
    for i in $(seq 1 12); do
      version_id=$(fetch_target_version_id)
      if [ -n "$version_id" ]; then
        echo "Resolved version ID after create (attempt $i)."
        break
      fi
      echo "Waiting for version $VERSION to appear... (attempt $i/12)"
      sleep 5
    done
  fi

  if [ -z "$version_id" ]; then
    echo "::error::App Store version $VERSION not found after ensure step." >&2
    list_versions >&2
    exit 1
  fi

  write_output "$version_id"
}

main "$@"
