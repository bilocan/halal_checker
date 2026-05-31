#!/usr/bin/env bash
# Runs all pipeline integration tests (barcode lookup + Supabase services).
# Uses dart_defines.integration.json — see TESTING.md.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMEOUT="${1:-300}"
export DEFINES_FILE="${DEFINES_FILE:-${ROOT}/dart_defines.integration.json}"

"${ROOT}/run_integration_test.sh" test/integration/barcode_lookup_test.dart "$TIMEOUT"
"${ROOT}/run_integration_test.sh" test/integration/supabase_services_integration_test.dart "$TIMEOUT"
"${ROOT}/run_integration_test.sh" test/integration/barcode_20013066_stored_analysis_test.dart "$TIMEOUT"
