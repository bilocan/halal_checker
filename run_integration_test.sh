#!/usr/bin/env bash
# Runs integration tests with the same --dart-define credentials as the app.
#
# Usage:
#   ./run_integration_test.sh
#   ./run_integration_test.sh test/integration/supabase_services_integration_test.dart
#   ./run_integration_test.sh test/integration/barcode_lookup_test.dart 180

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFINES_FILE="${ROOT}/dart_defines.json"
TEST_FILE="${1:-test/integration/barcode_lookup_test.dart}"
TIMEOUT="${2:-120}"

if [[ ! -f "$DEFINES_FILE" ]]; then
  echo "dart_defines.json not found at $DEFINES_FILE" >&2
  exit 1
fi

DART_DEFINES=()
while IFS= read -r key; do
  value="$(python3 -c "import json; print(json.load(open('$DEFINES_FILE')).get('$key', ''))")"
  DART_DEFINES+=("--dart-define=${key}=${value}")
done < <(python3 -c "import json; print('\n'.join(json.load(open('$DEFINES_FILE')).keys()))")

echo "Running: flutter test $TEST_FILE --concurrency 1 --timeout ${TIMEOUT}s ${DART_DEFINES[*]}"
flutter test "$TEST_FILE" --concurrency 1 --timeout "${TIMEOUT}s" "${DART_DEFINES[@]}"
