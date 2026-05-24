#!/usr/bin/env bash
# Validates test/e2e_coverage.json against e2e keys and barcodes_e2e.txt (no device).
set -euo pipefail
cd "$(dirname "$0")/.."
flutter test test/constants/e2e_coverage_test.dart
