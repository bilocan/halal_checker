#!/usr/bin/env bash
# Expire TestFlight builds for comma-separated marketing versions (preReleaseVersion).
#
# Usage:
#   JWT=... APP_ID=... ./scripts/ci/expire_testflight_versions.sh 1.3.15,1.3.14
#
# Marks each version's latest VALID build as expired (removed from TestFlight).
# Same logic as cancel-beta-review.yml action=expire.
set -euo pipefail

VERSIONS="${1:?comma-separated versions required (e.g. 1.3.15,1.3.14)}"
JWT="${JWT:?JWT required}"
APP_ID="${APP_ID:?APP_ID required}"

IFS=',' read -ra VER_LIST <<< "$VERSIONS"

for VERSION in "${VER_LIST[@]}"; do
  VERSION="${VERSION// /}"
  [ -n "$VERSION" ] || continue

  echo "=== Expire TestFlight build for v$VERSION ==="

  BUILD_ID=$(curl -gsS \
    -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/builds?filter[app]=$APP_ID&filter[preReleaseVersion.version]=$VERSION&filter[processingState]=VALID&sort=-uploadedDate&limit=1" \
    | jq -r '.data[0].id // empty')

  if [ -z "$BUILD_ID" ]; then
    echo "No valid build found for v$VERSION — skipping."
    continue
  fi
  echo "Build ID: $BUILD_ID"

  HTTP=$(curl -sS -o /dev/null -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    -d "{\"data\":{\"type\":\"builds\",\"id\":\"$BUILD_ID\",\"attributes\":{\"expired\":true}}}" \
    "https://api.appstoreconnect.apple.com/v1/builds/$BUILD_ID")
  if [ "$HTTP" -ge 200 ] && [ "$HTTP" -lt 300 ]; then
    echo "Build expired — removed from TestFlight."
  else
    echo "::warning::Could not expire build for v$VERSION (HTTP $HTTP)."
  fi
done
