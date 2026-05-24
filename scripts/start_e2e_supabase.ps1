# Start local Supabase (Docker) for UI E2E and apply migrations.
#
# Usage (from repo root):
#   .\scripts\start_e2e_supabase.ps1
#
# Then in a second terminal:
#   supabase functions serve lookup-product --no-verify-jwt --env-file supabase/.env.local

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Error "Supabase CLI not found. Install: https://supabase.com/docs/guides/cli"
}

Write-Host "Starting local Supabase (Docker)..." -ForegroundColor Cyan
supabase start

Write-Host "`nApplying migrations (db reset)..." -ForegroundColor Cyan
supabase db reset

Write-Host "`nLocal stack ready. API URL (host machine):" -ForegroundColor Green
supabase status

Write-Host @"

Next steps:
  1. Copy dart_defines.e2e.example.json -> dart_defines.e2e.json
     (use dart_defines.e2e.android-emulator.example.json on Android emulator)
  2. Optional: copy supabase/.env.e2e.example -> supabase/.env.local and add AI keys
  3. In another terminal:
       supabase functions serve lookup-product --no-verify-jwt --env-file supabase/.env.local
  4. Run UI E2E:
       .\run_ui_e2e_test.ps1

"@ -ForegroundColor Yellow
