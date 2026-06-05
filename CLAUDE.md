# HalalScan — Claude Code Guide

Agent checklist: [AGENTS.md](AGENTS.md). **Definition of done (Cursor + Claude Code):** [DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md) — edit only that file when changing done steps. Cursor rules in `.cursor/rules/` point there.

## Vault — always log bugs and decisions

The team's second brain is the **HalalScan Obsidian vault** — configured as an additional working directory in Claude Code, so it is always accessible alongside this repo.

**When a bug is reported or fixed:**
1. Create a note in `02 - Dev/Bugs/` using this template
2. Add a row to the vault **[[Bug Tracker]]** (`02 - Dev/Bugs/Bug Tracker.md`) under the matching status section
3. Update summary counts on the tracker and [[Dashboard]] when status changes

```
# Bug: <short title>

**Captured:** YYYY-MM-DD
**Status:** Open | Fix implemented | Resolved
**File:** <affected file or workflow>
**Priority:** High / Medium / Low

## Symptoms
## Root cause
## Fix — implemented / pending
## Related
```

Move to `02 - Dev/Bugs/Resolved/` only after the user confirms it works in production; then set **Status:** Resolved and move the tracker row to **Resolved**.

**When a product decision is made:** capture it in `01 - Product/Decisions/`.

**On `debrief`:** follow the vault `CLAUDE.md` debrief flow — end with **copy-paste commit message(s) only** (vault `docs: …` and/or `halal_checker` when code changed); **no `git` commands** in the reply; do not commit unless asked.

## Task done (Claude Code + Cursor)

When the user says **task done** / **done** / **finish**: follow **[DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md)** in full. For user-visible work you **must** write release notes — run `add_release_note` or edit `release_notes/unreleased/{en,de,tr,ar}.md`. Consolidating docs into one file does **not** remove that step.

## Current deployment defaults

**Claude product AI (edge function) is off** in this project unless you re-enable it: `CLAUDE_ENABLED=false` on edge functions; no `CLAUDE_API_KEY` required for normal development ([CONTRIBUTING.md](CONTRIBUTING.md)). This is **not** about Claude Code writing release notes or using this repo as an agent. Production lookups rely on **Open Food Facts + keyword analysis**; optional AI layers remain in code for local use.

**Gemini** is optional (`GEMINI_*`, admin approval, or `GEMINI_LOOKUP_EMPTY_OFF`).

When Claude is disabled, tier-1 “AI” steps in the edge function are skipped; keywords and the safety override remain authoritative.

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
3. Supabase Edge Function — shared product cache + optional AI (Claude/Gemini when enabled)
4. OpenFoodFacts + keyword analysis — direct fallback, no AI

**Key services:**
- [lib/services/product_service.dart](lib/services/product_service.dart) — orchestrates the full lookup pipeline
- [lib/services/keyword_service.dart](lib/services/keyword_service.dart) — keyword matching engine (haram/suspicious lists, 7 languages)
- [lib/services/cache_service.dart](lib/services/cache_service.dart) — SharedPreferences cache
- [lib/services/database_service.dart](lib/services/database_service.dart) — SQLite scan history

**Backend:**
- Supabase Edge Function at `supabase/functions/lookup-product/` handles OpenFoodFacts fetching, optional AI analysis, and shared caching
- Claude API key (`CLAUDE_API_KEY`) and `CLAUDE_ENABLED` are Supabase secrets — never in the app; **off by default** in this repo
- Gemini (`GEMINI_API_KEY`, optional `GEMINI_ENABLED`) powers web-grounded ingredient lookup when OFF has no ingredients — after admin approval + `fetchAiIngredients: true`, when superadmin enables **Admin → Settings** (`app_config.gemini_lookup_empty_off`), or via env `GEMINI_LOOKUP_EMPTY_OFF=true`; tier-1 halal analysis still runs on existing ingredient lists. Gemini web lookup is **recorded per barcode + normalized name** (`products.gemini_web_ingredient_lookup_*`) and is not repeated for the same pairing; the result screen reflects that with `geminiWebIngredientLookupAttemptedForName`.
- **OFF-missing pack photos**: when admins approve submissions in `product_image_submissions`, the DB ensures a stub row in `products` (+ `product_analysis`) so lookups can resolve. The Edge Function skips the cached “frozen unknown” shortcut when text ingredients are empty but `image_ingredients_url` exists, then OFF still misses—and runs Tier-3 vision (`analyzeWithClaudeVision`) plus the usual keyword/AI analysis; apply migration `20260527000000_upsert_product_on_pack_photo_approval.sql` and redeploy `lookup-product`.

## Halal analysis layers

Edge function detail (step order, skip conditions, post-rules): **[supabase/functions/lookup-product/VERDICT_PIPELINE.md](supabase/functions/lookup-product/VERDICT_PIPELINE.md)** — update it when changing `verdictRules.ts` or lookup flow.

Summary (server `computeVerdict`):

1. **Keyword bootstrap** — `keywordAnalysis` on ingredient list (+ custom DB keywords)
2. **AI (optional)** — Gemini Flash → Claude Haiku; then vision OCR + AI when no text ingredients; skipped when `CLAUDE_ENABLED=false` / no keys / `skipAi` (stale re-analysis)
3. **Post-rules (fixed order)** — keyword safety override → category → name fallback → halal cert → suspicious-only

Keyword safety override uses the **initial** keyword pass (`kwFirst`) after AI, so haram/suspicious keywords AI missed still force not halal.

App mirror: [lib/services/product_service.dart](lib/services/product_service.dart), [lib/services/keyword_service.dart](lib/services/keyword_service.dart). Built-in lists: edge `keyword.ts` + app constants (keep aligned).

## Adding test fixtures

Append a barcode to `test_data/seed_barcodes.txt`. On the next debug launch, the app fetches real product data and freezes it in `halal_test.db`.

## Config

All runtime secrets are injected via `--dart-define-from-file=dart_defines.json`. The app reads them with `String.fromEnvironment()` in [lib/config.dart](lib/config.dart). Never hardcode keys.

## Code style

- `./scripts/linux/format_dart.sh` (or `.\scripts\windows\format_dart.ps1` on Windows) and `flutter analyze` must pass — CI enforces both
- Post-write dart formatting is configured in `.claude/settings.json`
