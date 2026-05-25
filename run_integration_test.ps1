# Runs pipeline integration tests against a dedicated test Supabase project.
# Uses dart_defines.integration.json — NOT dart_defines.json (app/prod).
#
# Setup:
#   cp dart_defines.integration.example.json dart_defines.integration.json
#
# Usage:
#   .\run_integration_test.ps1
#   .\run_integration_test.ps1 -TestFile test/integration/supabase_services_integration_test.dart
#   .\run_integration_test.ps1 -Timeout 300
#   .\run_all_integration_tests.ps1

param(
    [string]$TestFile = "test/integration/barcode_lookup_test.dart",
    [string]$DefinesFile = "dart_defines.integration.json",
    [int]$Timeout = 120
)

$definesPath = Join-Path $PSScriptRoot $DefinesFile
if (-not (Test-Path $definesPath)) {
    Write-Error @"
$DefinesFile not found.
Copy dart_defines.integration.example.json to dart_defines.integration.json
and point SUPABASE_URL at your test Supabase project (not production).
See TESTING.md → Pipeline integration.
"@
    exit 1
}

$flutterArgs = @(
    "test", $TestFile,
    "--concurrency", "1",
    "--timeout", "${Timeout}s",
    "--dart-define-from-file=$definesPath"
)

Write-Host "Defines: $DefinesFile" -ForegroundColor DarkGray
Write-Host "Running: flutter $($flutterArgs -join ' ')" -ForegroundColor Cyan
& flutter @flutterArgs
