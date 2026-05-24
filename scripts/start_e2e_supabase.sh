#!/usr/bin/env bash
# Start local Supabase (Docker) for UI E2E and apply migrations.
#
# Usage (from repo root):
#   ./scripts/start_e2e_supabase.sh
#
# Then in a second terminal:
#   supabase functions serve lookup-product --no-verify-jwt --env-file supabase/.env.local

set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI not found. Install: https://supabase.com/docs/guides/cli" >&2
  exit 1
fi

echo "Starting local Supabase (Docker)..."
supabase start

echo ""
echo "Applying migrations (db reset)..."
supabase db reset

echo ""
echo "Local stack ready. API URL (host machine):"
supabase status

cat <<'EOF'

Next steps:
  1. cp dart_defines.e2e.example.json dart_defines.e2e.json
     (use dart_defines.e2e.android-emulator.example.json on Android emulator)
  2. Optional: cp supabase/.env.e2e.example supabase/.env.local and add AI keys
  3. In another terminal:
       supabase functions serve lookup-product --no-verify-jwt --env-file supabase/.env.local
  4. Run UI E2E:
       ./run_ui_e2e_test.sh

EOF
