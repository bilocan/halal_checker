# Runs UI E2E on a connected device/emulator (integration_test/ui_barcode_flow_test.dart).
# Uses dart_defines.e2e.json (local Supabase) — NOT dart_defines.json.
#
# Setup: see TESTING.md → "Local Supabase for E2E"
#
# Usage:
#   .\run_ui_e2e_test.ps1
#   .\run_ui_e2e_test.ps1 -DefinesFile dart_defines.e2e.android-emulator.json
#   .\run_ui_e2e_test.ps1 -LiveLookup
#   .\run_ui_e2e_test.ps1 -BarcodesFile test/barcodes.txt -Timeout 300

param(
    [string]$TestFile = "integration_test/ui_barcode_flow_test.dart",
    [string]$BarcodesFile = "test/barcodes_e2e.txt",
    [string]$DefinesFile = "dart_defines.e2e.json",
    [int]$Timeout = 180,
    [switch]$LiveLookup
)

$definesPath = Join-Path $PSScriptRoot $DefinesFile
if (-not (Test-Path $definesPath)) {
    Write-Error @"
$DefinesFile not found.
Copy dart_defines.e2e.example.json to dart_defines.e2e.json (or use -DefinesFile).
See TESTING.md → Local Supabase for E2E.
"@
    exit 1
}

$defines = Get-Content $definesPath -Raw | ConvertFrom-Json

$dartDefineArgs = @()
foreach ($prop in $defines.PSObject.Properties) {
    $dartDefineArgs += "--dart-define=$($prop.Name)=$($prop.Value)"
}
$dartDefineArgs += "--dart-define=E2E_BARCODES_FILE=$BarcodesFile"
$dartDefineArgs += "--dart-define=E2E_SKIP_CAMERA=true"
if ($LiveLookup) {
    $dartDefineArgs += "--dart-define=E2E_LIVE_LOOKUP=true"
}

$flutterArgs = @(
    "test",
    $TestFile,
    "--concurrency", "1",
    "--timeout", "${Timeout}s"
) + $dartDefineArgs

Write-Host "Defines: $DefinesFile" -ForegroundColor DarkGray
Write-Host "Requires a connected device or emulator + local Supabase (see scripts/start_e2e_supabase.ps1)." -ForegroundColor Yellow
Write-Host "Running: flutter $($flutterArgs -join ' ')" -ForegroundColor Cyan
& flutter @flutterArgs
