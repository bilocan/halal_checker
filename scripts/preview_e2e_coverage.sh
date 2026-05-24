#!/usr/bin/env bash
# Human-readable report of test/e2e_coverage.json (no device, no tests).
set -euo pipefail
cd "$(dirname "$0")/.."
dart run tool/e2e_coverage_report.dart
