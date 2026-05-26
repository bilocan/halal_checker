# HalalScan — Claude Code Guide

## Running the app

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Requires `dart_defines.json` in the project root (copy from `dart_defines.example.json`).

## Running tests

Full guide: [TESTING.md](TESTING.md) (CI, integration, UI E2E, OCR).

```bash
flutter test test/services/ test/constants/ test/models/ test/config_test.dart
```

## Architecture

**Lookup pipeline** (first hit wins):
1. Test DB — debug builds only, offline fixtures from `test_data/`
2. Local cache — SharedPreferences, 30-day TTL
3. Supabase Edge Function — shared product cache + Claude AI analysis
4. OpenFoodFacts + keyword analysis — direct fallback, no AI

**Key services:**
- [lib/services/product_service.dart](lib/services/product_service.dart) — orchestrates the full lookup pipeline
- [lib/services/keyword_service.dart](lib/services/keyword_service.dart) — keyword matching engine (haram/suspicious lists, 7 languages)
- [lib/services/cache_service.dart](lib/services/cache_service.dart) — SharedPreferences cache
- [lib/services/database_service.dart](lib/services/database_service.dart) — SQLite scan history

**Backend:**
- Supabase Edge Function at `supabase/functions/lookup-product/` handles OpenFoodFacts fetching, Claude AI analysis, and shared caching
- Claude API key lives as a Supabase secret (`CLAUDE_API_KEY`) — never in the app
- Gemini (`GEMINI_API_KEY`, optional `GEMINI_ENABLED`) powers web-grounded ingredient lookup when OFF has no ingredients — after admin approval + `fetchAiIngredients: true`, when superadmin enables **Admin → Settings** (`app_config.gemini_lookup_empty_off`), or via env `GEMINI_LOOKUP_EMPTY_OFF=true`; tier-1 halal analysis still runs on existing ingredient lists. Gemini web lookup is **recorded per barcode + normalized name** (`products.gemini_web_ingredient_lookup_*`) and is not repeated for the same pairing; the result screen reflects that with `geminiWebIngredientLookupAttemptedForName`.
- **OFF-missing pack photos**: when admins approve submissions in `product_image_submissions`, the DB ensures a stub row in `products` (+ `product_analysis`) so lookups can resolve. The Edge Function skips the cached “frozen unknown” shortcut when text ingredients are empty but `image_ingredients_url` exists, then OFF still misses—and runs Tier-3 vision (`analyzeWithClaudeVision`) plus the usual keyword/AI analysis; apply migration `20260527000000_upsert_product_on_pack_photo_approval.sql` and redeploy `lookup-product`.

## Halal analysis layers

Three layers run in order; highest-confidence result wins, but keyword safety override always has final say:

1. **AI (Claude Haiku)** — server-side, returns structured JSON verdict
2. **Keyword matching** — deterministic fallback, 19 haram + 13 suspicious keywords across 7 languages
3. **Safety override** — keyword matching reruns after AI; if it detects haram that AI missed, product is overridden to not halal

Keyword lists live in [lib/services/product_service.dart](lib/services/product_service.dart) as constants.

## Adding test fixtures

Append a barcode to `test_data/seed_barcodes.txt`. On the next debug launch, the app fetches real product data and freezes it in `halal_test.db`.

## Config

All runtime secrets are injected via `--dart-define-from-file=dart_defines.json`. The app reads them with `String.fromEnvironment()` in [lib/config.dart](lib/config.dart). Never hardcode keys.

## Code style

- `./scripts/linux/format_dart.sh` (or `.\scripts\windows\format_dart.ps1` on Windows) and `flutter analyze` must pass — CI enforces both
- Post-write dart formatting is configured in `.claude/settings.json`
