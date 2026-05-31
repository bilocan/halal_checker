#!/usr/bin/env bash
# Run definition-of-done checks (format, analyze, tests) and print a summary.
#
# Usage:
#   ./scripts/linux/task_done.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

pass=0
fail=0
skip=0

check() {
  local name="$1"
  shift
  printf '  %-22s ' "$name"
  if "$@"; then
    echo "PASS"
    pass=$((pass + 1))
  else
    echo "FAIL"
    fail=$((fail + 1))
  fi
}

echo ""
echo "Definition of done — automated checks"
echo "======================================"

check "format" bash ./scripts/linux/format_dart.sh --check
check "analyze" flutter analyze --no-fatal-infos
check "unit tests" flutter test test/services/ test/constants/ test/models/ test/config_test.dart

echo ""
echo "Manual reminders (if applicable this task):"
echo "  - User-visible? → add_release_note at task done (en, de, tr, ar)"
echo "  - UI/nav/scan?  → e2e_coverage.json + run_ui_e2e_test.sh"
echo "  - Edge/verdict? → VERDICT_PIPELINE.md"
echo ""
echo "Result: $pass passed, $fail failed"
echo "Full checklist (edit only this file): DEFINITION_OF_DONE.md"
echo ""

if [ "$fail" -gt 0 ]; then
  exit 1
fi
