#!/usr/bin/env bash
# Runs UI E2E on a connected device/emulator.
# Uses dart_defines.e2e.json (local Supabase) — NOT dart_defines.json.
#
# Setup: see TESTING.md → "Local Supabase for E2E"
#
# Usage:
#   ./run_ui_e2e_test.sh
#   DEFINES_FILE=dart_defines.e2e.android-emulator.json ./run_ui_e2e_test.sh
#   LIVE_LOOKUP=1 ./run_ui_e2e_test.sh test/barcodes.txt 300

set -euo pipefail
cd "$(dirname "$0")"

TEST_FILE="${TEST_FILE:-integration_test/ui_barcode_flow_test.dart}"
BARCODES_FILE="${1:-test/barcodes_e2e.txt}"
TIMEOUT="${2:-300}"
DEFINES_FILE="${DEFINES_FILE:-dart_defines.e2e.json}"
LIVE_LOOKUP="${LIVE_LOOKUP:-}"

if [[ ! -f "$DEFINES_FILE" ]]; then
  echo "$DEFINES_FILE not found." >&2
  echo "Copy dart_defines.e2e.example.json to dart_defines.e2e.json (see TESTING.md)." >&2
  exit 1
fi

LIVE_ARGS=()
if [[ "${LIVE_LOOKUP}" == "1" || "${3:-}" == "--live-lookup" ]]; then
  LIVE_ARGS=(--dart-define=E2E_LIVE_LOOKUP=true)
fi

echo "Defines: ${DEFINES_FILE}"
echo "Requires a connected device or emulator + local Supabase (see scripts/start_e2e_supabase.sh)."

# Debug APK id (see android/app/build.gradle.kts). E2E skips the camera, but grant
# anyway for OCR/manual flows on a fresh emulator.
if command -v adb >/dev/null 2>&1; then
  for pkg in app.halalscan.dev app.halalscan; do
    if adb shell pm grant "${pkg}" android.permission.CAMERA 2>/dev/null; then
      echo "Granted CAMERA to ${pkg}"
    fi
  done
fi

flutter test "$TEST_FILE" \
  --concurrency 1 \
  --timeout "${TIMEOUT}s" \
  --dart-define-from-file="${DEFINES_FILE}" \
  --dart-define=E2E_BARCODES_FILE="${BARCODES_FILE}" \
  --dart-define=E2E_SKIP_CAMERA=true \
  "${LIVE_ARGS[@]}"
