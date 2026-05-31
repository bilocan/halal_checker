# Run definition-of-done checks (format, analyze, tests) and print a summary.
#
# Usage:
#   .\scripts\windows\task_done.ps1
$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
Set-Location $Root

$pass = 0
$fail = 0

function Test-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host ("  {0,-22}" -f $Name) -NoNewline
    & $Action
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASS"
        $script:pass++
    } else {
        Write-Host "FAIL"
        $script:fail++
    }
}

Write-Host ""
Write-Host "Definition of done - automated checks"
Write-Host "======================================"

Test-Step "format" { & .\scripts\windows\format_dart.ps1 -Check }
Test-Step "analyze" { flutter analyze --no-fatal-infos }
Test-Step "unit tests" {
    flutter test test/services/ test/constants/ test/models/ test/config_test.dart
}

Write-Host ""
Write-Host "Manual reminders (if applicable this task):"
Write-Host '  - User-visible? -> add_release_note at task done: en, de, tr, ar'
Write-Host "  - UI/nav/scan?  -> e2e_coverage.json + run_ui_e2e_test.sh"
Write-Host "  - Edge/verdict? -> VERDICT_PIPELINE.md"
Write-Host ""
Write-Host "Result: $pass passed, $fail failed"
Write-Host 'Full checklist (edit only this file): DEFINITION_OF_DONE.md'
Write-Host ""

if ($fail -gt 0) { exit 1 }
