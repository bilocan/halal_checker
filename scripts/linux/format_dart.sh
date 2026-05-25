#!/usr/bin/env bash
# Format Dart sources under lib/ and test/ (avoids broken build/ paths on Windows).
#
# Usage (from repo root):
#   ./scripts/linux/format_dart.sh           # apply formatting
#   ./scripts/linux/format_dart.sh --check   # CI mode: exit 1 if not formatted

set -euo pipefail
cd "$(dirname "$0")/../.."

if [[ "${1:-}" == "--check" ]]; then
  dart format --output=none --set-exit-if-changed lib test
else
  dart format lib test
fi
