# Runs all pipeline integration tests (barcode lookup + Supabase services).
# Uses dart_defines.integration.json — see TESTING.md.

param(
    [string]$DefinesFile = "dart_defines.integration.json",
    [int]$Timeout = 300
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

& "$root\run_integration_test.ps1" `
    -TestFile "test/integration/barcode_lookup_test.dart" `
    -DefinesFile $DefinesFile `
    -Timeout $Timeout
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$root\run_integration_test.ps1" `
    -TestFile "test/integration/supabase_services_integration_test.dart" `
    -DefinesFile $DefinesFile `
    -Timeout $Timeout
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$root\run_integration_test.ps1" `
    -TestFile "test/integration/barcode_20013066_stored_analysis_test.dart" `
    -DefinesFile $DefinesFile `
    -Timeout $Timeout
exit $LASTEXITCODE
