# Format Dart sources under lib/ and test/ (avoids broken build/ paths on Windows).
#
# Usage (from repo root):
#   .\scripts\windows\format_dart.ps1           # apply formatting
#   .\scripts\windows\format_dart.ps1 -Check    # CI mode: exit 1 if not formatted

param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "../..")

if ($Check) {
    dart format --output=none --set-exit-if-changed lib test
} else {
    dart format lib test
}
