#!/usr/bin/env bash
# Runs pipeline integration tests against a dedicated test Supabase project.
# Uses dart_defines.integration.json — NOT dart_defines.json (app/prod).
#
# Setup:
#   cp dart_defines.integration.example.json dart_defines.integration.json
#
# Usage:
#   ./run_integration_test.sh
#   ./run_integration_test.sh test/integration/supabase_services_integration_test.dart
#   ./run_integration_test.sh test/integration/barcode_lookup_test.dart 300
#   ./run_all_integration_tests.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFINES_FILE="${DEFINES_FILE:-${ROOT}/dart_defines.integration.json}"
TEST_FILE="${1:-test/integration/barcode_lookup_test.dart}"
TIMEOUT="${2:-120}"

if [[ ! -f "$DEFINES_FILE" ]]; then
  echo "dart_defines.integration.json not found." >&2
  echo "Copy dart_defines.integration.example.json → dart_defines.integration.json" >&2
  echo "See TESTING.md → Pipeline integration." >&2
  exit 1
fi

echo "Defines: $DEFINES_FILE"
echo "Running: flutter test $TEST_FILE --concurrency 1 --timeout ${TIMEOUT}s --dart-define-from-file=$DEFINES_FILE"
flutter test "$TEST_FILE" --concurrency 1 --timeout "${TIMEOUT}s" \
  --dart-define-from-file="$DEFINES_FILE"
