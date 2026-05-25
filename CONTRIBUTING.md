# Contributing to HalalScan

Thank you for helping make halal food verification more accessible.

## Before you start

- For bug reports and feature requests, open a GitHub issue first
- For small fixes (typos, minor bugs), a PR is fine without a prior issue
- For larger changes, discuss in an issue first to avoid wasted effort

## Setting up the development environment

### Prerequisites

- Flutter SDK (stable channel)
- A [Supabase](https://supabase.com) project with the `lookup-product` Edge Function deployed
- **Claude / Anthropic is optional** — lookup works via Open Food Facts + keyword analysis without it. This project keeps Claude **off** for now (`CLAUDE_ENABLED=false` on edge functions; no `CLAUDE_API_KEY` required). To re-enable later, set the secret and `CLAUDE_ENABLED=true` (or unset `CLAUDE_ENABLED`).

### Environments (local / test / production)

HalalScan does not use a single runtime “environment” flag. Separation is by **which dart-defines file you pass** and **which Supabase stack** that file points at. Pick the right file for what you are doing — there is no automatic guard when you `flutter run`.

| Environment | Config file | Supabase backend | Typical use |
|-------------|-------------|------------------|-------------|
| **Production / dev app** | `dart_defines.json` | Your real hosted project | `flutter run`, release builds, day-to-day development |
| **Pipeline integration** | `dart_defines.integration.json` | A **second** hosted project (test only) | `test/integration/*`, `run_integration_test.*` |
| **UI E2E (local)** | `dart_defines.e2e.json` | Local Docker via Supabase CLI (`127.0.0.1:54321` or `10.0.2.2` on Android emulator) | `run_ui_e2e_test.*` |

All three files are **gitignored**; copy from the matching `*.example.json` in the repo root. Secrets are read at compile time via [`lib/config.dart`](lib/config.dart) (`String.fromEnvironment`) — never hardcode keys in source.

**What is enforced**

- Integration tests call `assertIntegrationProjectOnly()` ([`test/integration/helpers/supabase_integration_helper.dart`](test/integration/helpers/supabase_integration_helper.dart)): `INTEGRATION_PROJECT_REF` must be set and must match the host in `SUPABASE_URL`, so accidentally using `dart_defines.json` fails fast.
- Unit tests (`flutter test test/services/ …`) do not use Supabase; they use mocks and offline fixtures.

**What is manual**

- You must use a **different** Supabase project for `dart_defines.json` (prod) and `dart_defines.integration.json` (test). The guard only checks ref ↔ URL consistency, not that prod and test refs differ.
- UI E2E must use `dart_defines.e2e.json`, not `dart_defines.json`.

**Backend / CI (high level)**

| Layer | Production | Test (hosted) | Local |
|-------|------------|---------------|-------|
| App deploy & release builds | `SUPABASE_*` GitHub secrets | — | — |
| Optional integration workflow | — | `INTEGRATION_*` secrets → writes `dart_defines.integration.json` in CI | — |
| Edge function deploy & migrations | `.github/workflows/deploy-supabase.yml` → `SUPABASE_PROJECT_REF` | Apply same migrations to the test project | `supabase start` + [`scripts/start_e2e_supabase.ps1`](scripts/start_e2e_supabase.ps1) / `.sh` |
| Edge function secrets (optional AI) | `CLAUDE_ENABLED=false` by default; optional `GEMINI_*` for admin-approved ingredient lookup | Same if needed on test project | `supabase/.env.local` (gitignored) for `supabase functions serve` during E2E — see [`supabase/.env.e2e.example`](supabase/.env.e2e.example) |

**Debug-only offline fixtures** (`halal_test.db`, `test_data/`) are used in debug builds when not running E2E with `E2E_LIVE_LOOKUP=true`. They do not touch production data.

Full testing setup (E2E Docker stack, barcodes, CI secrets): [TESTING.md](TESTING.md).

### Local configuration

**App (production Supabase project):**

```bash
cp dart_defines.example.json dart_defines.json
```

Edit `dart_defines.json` with your Supabase URL, anon key, and Google OAuth client ID. Never commit this file.

**Pipeline integration** (separate **test** Supabase project — not production):

```bash
cp dart_defines.integration.example.json dart_defines.integration.json
```

Set `INTEGRATION_PROJECT_REF` to the test project ref from the dashboard URL; `SUPABASE_URL` must be `https://<that-ref>.supabase.co`. Add test Auth users and `SUPABASE_SERVICE_ROLE_KEY` only for admin/cleanup tests (never ship the service role in the app).

```bash
./run_all_integration_tests.sh    # Linux/macOS/Git Bash
# .\run_all_integration_tests.ps1   # Windows
```

**UI E2E** (local Docker Supabase):

```bash
.\scripts\start_e2e_supabase.ps1   # Windows — or scripts/start_e2e_supabase.sh
cp dart_defines.e2e.example.json dart_defines.e2e.json
# Android emulator: use dart_defines.e2e.android-emulator.example.json instead
.\run_ui_e2e_test.ps1
```

See [TESTING.md → Local Supabase for E2E](TESTING.md#local-supabase-for-e2e) and [TESTING.md → Pipeline integration](TESTING.md#pipeline-integration--live-api-no-ui).

### Run

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## Making changes

### Tests

Run the test suite before submitting a PR:

```bash
flutter test test/services/
```

Tests cover the keyword matching engine and halal verdict logic. All PRs must pass CI (format check, lint, tests).

### Code style

- Follow standard Dart formatting: `./scripts/linux/format_dart.sh` or `.\scripts\windows\format_dart.ps1` (`lib/` + `test/` only; avoids `dart format .` failing on Windows when `build/` is stale)
- Follow Flutter lint rules: `flutter analyze`
- CI enforces both — PRs with formatting or lint failures will not be merged

### Translation contributions

To fix a translation or add a new language, see **[docs/TRANSLATING.md](docs/TRANSLATING.md)** for a step-by-step guide. No Dart knowledge required — translations are plain JSON files in `lib/l10n/`.

### Keyword contributions

To add or correct halal/haram keywords, open an issue with:
- The keyword
- Why it should be flagged (haram) or cleared (false positive)
- Sources (scholarly references or food science citations preferred)

Do not add keywords directly to the codebase without discussion — incorrect keyword additions affect every user.

## Pull request checklist

- [ ] `./scripts/linux/format_dart.sh --check` passes (or `.\scripts\windows\format_dart.ps1 -Check` on Windows)
- [ ] `flutter analyze` passes with no warnings
- [ ] `flutter test test/services/` passes
- [ ] PR description explains *why* the change is needed, not just what it does

## License

By contributing, you agree that your contributions will be licensed under the [GNU General Public License v3.0](LICENSE).
