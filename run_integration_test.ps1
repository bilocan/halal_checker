# Runs the barcode lookup integration test with the same --dart-define
# credentials used by the app (read from dart_defines.json).
#
# Usage:
#   .\run_integration_test.ps1
#   .\run_integration_test.ps1 -TestFile test/integration/barcode_lookup_test.dart
#   .\run_integration_test.ps1 -Timeout 180

param(
    [string]$TestFile = "test/integration/barcode_lookup_test.dart",
    [int]$Timeout = 120
)

$definesFile = Join-Path $PSScriptRoot "dart_defines.json"
if (-not (Test-Path $definesFile)) {
    Write-Error "dart_defines.json not found at $definesFile"
    exit 1
}

$defines = Get-Content $definesFile -Raw | ConvertFrom-Json

$dartDefineArgs = @()
foreach ($prop in $defines.PSObject.Properties) {
    $dartDefineArgs += "--dart-define=$($prop.Name)=$($prop.Value)"
}

$flutterArgs = @("test", $TestFile, "--timeout", "${Timeout}s") + $dartDefineArgs

Write-Host "Running: flutter $($flutterArgs -join ' ')" -ForegroundColor Cyan
& flutter @flutterArgs
