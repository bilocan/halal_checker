# HalalScan

A Flutter app that scans food product barcodes and determines whether they are **halal**, **haram**, or **require verification** according to Islamic dietary law.

## What it does

Point the camera at any food product barcode (or enter it manually). The app fetches the ingredient list, runs a multi-layer halal analysis, and gives you:

- A clear **Halal / Not Halal** verdict with a colour-coded result screen
- A per-ingredient breakdown showing exactly which ingredients were flagged and why
- A full transparency panel listing every keyword that was checked
- Community feedback on each product
- A scan history so you can revisit previous lookups

Supported languages: **English**, **Turkish**, **German**

---

## How halal status is determined

The analysis runs through three layers in order. The result of the highest-confidence layer wins, but the keyword safety override always has the final say.

### Layer 1 — AI analysis (Claude)

Ingredient text is sent to Claude Haiku running as a Supabase Edge Function. Claude has been instructed on Islamic dietary law and returns a structured JSON verdict:

```
isHalal | haramIngredients[] | suspiciousIngredients[] | ingredientWarnings{} | explanation
```

This runs server-side — the API key never touches the app.

### Layer 2 — Keyword matching (fallback)

If the Edge Function is unavailable or Claude fails, the app falls back to deterministic keyword matching against two built-in lists:

**Haram keywords** (19 entries) — these make a product not halal:

| Category | Keywords |
|---|---|
| Alcohol | alcohol, ethanol, wine, beer |
| Pork | pork, lard, bacon, ham, pepperoni, salami, chorizo, prosciutto |
| Animal-derived | gelatin, carmine, cochineal |
| E-numbers | E120, E441, E542, E904 |

**Suspicious keywords** (13 entries) — these require source verification:

| Keyword | Reason |
|---|---|
| whey | Dairy by-product; halal if no pork-derived rennet |
| rennet | May be animal-derived |
| E471, E472, E473 | Mono/diglycerides; may be animal fat |
| E322 | Lecithin; may be animal-derived |
| E920, L-cysteine | May be derived from feathers or hair |
| natural flavour, flavouring | Source unspecified |
| enzymes | May be extracted from animal sources |
| glycerol | May be animal-derived |

Each keyword is matched across **7 languages** (EN, DE, TR, FR, IT, ES, NL) using word-boundary regex to avoid false positives (e.g. `porcelain` does not match `pork`).

**Special cases:**
- **Fatty alcohols** — cetyl alcohol, stearyl alcohol, behenyl alcohol, and similar food emulsifiers are explicitly excluded from the alcohol haram check
- **Alcohol-free labels** — ingredients marked `alcohol-free` are not flagged

### Layer 3 — Keyword safety override

After AI analysis completes, keyword matching always runs a second time as a safety net. If keywords detect a haram ingredient that the AI missed, **the product is overridden to not halal**. This prevents AI false negatives from slipping through.

### Custom keywords

Approved community keyword suggestions (stored in Supabase) are applied on top of the built-in lists, following the same matching logic.

---

## Architecture

```
Flutter App
│
├── HomeScreen          Barcode scanner (mobile_scanner)
├── ResultScreen        Verdict + per-ingredient breakdown
├── StartScreen         Scan history (last 50 scans)
└── KeywordsScreen      View / suggest custom keywords

Services
├── ProductService      Orchestrates the full lookup pipeline
├── CacheService        30-day local cache (SharedPreferences)
├── DatabaseService     Scan history (SQLite — halal_scan.db)
├── KeywordService      Fetches approved custom keywords from Supabase
└── FeedbackService     Local community feedback storage

Backend (Supabase)
├── lookup-product      Edge Function: OpenFoodFacts → Claude → keyword fallback → cache
├── products            Shared product cache (7-day TTL)
├── keywords            Approved custom halal keywords
└── keyword_suggestions Community keyword submissions (pending moderation)
```

**Lookup pipeline** (in order, first hit wins):

```
1. Test DB (debug builds only)      instant, offline fixtures
2. Local SharedPreferences cache    30-day TTL, instant
3. Supabase Edge Function           shared cache + Claude AI
4. OpenFoodFacts + keyword analysis direct fallback, no AI
```

---

## Setup

### Prerequisites

- Flutter SDK (stable channel)
- A [Supabase](https://supabase.com) project with the `lookup-product` Edge Function deployed
- An [Anthropic](https://console.anthropic.com) API key set as a Supabase secret

### Supabase secrets

```bash
supabase secrets set CLAUDE_API_KEY=sk-ant-...
```

### Local configuration

Create `dart_defines.json` in the project root (already in `.gitignore`):

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

### Run

```bash
# Debug (uses .dev app ID — installs alongside release)
flutter run --dart-define-from-file=dart_defines.json

# Release APK
flutter build apk --release --dart-define-from-file=dart_defines.json

# Release APK split by ABI (preferred for distribution)
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json
```

---

## Development

### Running tests

```bash
flutter test test/services/
```

Tests cover the keyword matching engine and halal verdict logic. CI runs them automatically on every push and pull request via GitHub Actions.

### Test fixtures

`test_data/seed_products.json` contains pre-classified products (halal, haram, suspicious) loaded into a separate `halal_test.db` on debug builds. These barcodes are intercepted before any network call, making them available offline.

To add a real product as a fixture, append its barcode to `test_data/seed_barcodes.txt`. The app fetches real product data on the next debug launch and freezes it in the test DB.

### Parallel install (debug + release)

Debug builds use the app ID `com.example.halal_checker.dev`, so they coexist with a release install as two separate apps on the same device.

---

## Data sources

- **[Open Food Facts](https://world.openfoodfacts.org)** — product data, ingredient lists, images (CC BY-SA)
- **[Anthropic Claude](https://anthropic.com)** — AI ingredient analysis (server-side only)
- **[Supabase](https://supabase.com)** — shared product cache, custom keywords, community suggestions
