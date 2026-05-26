# HalalScan

A Flutter app that scans food product barcodes and determines whether they are **halal**, **haram**, or **require verification** according to Islamic dietary law.

## What it does

Point the camera at any food product barcode (or enter it manually). The app fetches the ingredient list, runs a multi-layer halal analysis, and gives you:

- A clear **Halal / Not Halal** verdict with a colour-coded result screen
- A per-ingredient breakdown showing exactly which ingredients were flagged and why
- A transparency panel showing what was checked, what matched, and a link to the full keyword/rule catalog
- **Deep Analysis** — on-demand per-ingredient AI analysis with Islamic scholarly basis, confidence levels, and alternative names
- **Community discussions** — threaded conversations about a product's ingredients with upvoting
- **Ingredient challenges** — formally dispute the verdict on a specific ingredient and track resolution
- Community feedback on each product
- A scan history so you can revisit previous lookups

Supported languages: **English**, **Turkish**, **German** — [help improve a translation](docs/TRANSLATING.md)

---

## How halal status is determined

The analysis runs through several layers in order. The result of the highest-confidence layer wins, but the deterministic rules engine always has the final say for safety-critical ingredient matches.

### Layer 1 — AI analysis (Claude)

Ingredient text is sent to Claude Haiku running as a Supabase Edge Function. Claude has been instructed on Islamic dietary law and returns a structured JSON verdict:

```
isHalal | haramIngredients[] | suspiciousIngredients[] | ingredientWarnings{} | explanation
```

This runs server-side — the API key never touches the app.

### Layer 2 — Rules engine / keyword matching (fallback)

If the Edge Function is unavailable or Claude fails, the app falls back to `HalalRulesEngine`, a deterministic rules engine in `lib/services/halal_rules_engine.dart`. It checks ingredient text against two built-in rule lists in `lib/constants/ingredient_keywords.dart`:

**Haram keywords** make a product not halal:

| Category | Keywords |
|---|---|
| Alcohol | alcohol, ethanol, wine, beer, spirits, liqueurs |
| Pork | pork, lard, bacon, ham, pepperoni, salami, chorizo, prosciutto |
| Animal-derived | gelatin, carmine, cochineal |
| E-numbers | E120, E441, E542, E904 |

**Verdict rules** (highest priority first): **haram** if any haram ingredient matches; **suspicious** if any suspicious ingredient matches (product is not halal until source is verified); **needs cert** for animal-derived foods without halal certification; **halal** only when none of the above apply.

**Suspicious keywords** flag ingredients that need source verification (product is not marked halal):

| Keyword | Reason |
|---|---|
| whey | Dairy by-product; halal if no pork-derived rennet |
| rennet | May be animal-derived |
| E471, E472, E473 | Mono/diglycerides; may be animal fat |
| E322 | Lecithin; may be animal-derived |
| E920, L-cysteine | May be animal-derived |
| natural flavour, flavouring | Source unspecified |
| enzymes | May be extracted from animal sources |
| glycerol, E422 | May be animal-derived |

Each canonical keyword has variants in `IngredientKeywords.haramVariants` or `IngredientKeywords.suspiciousVariants`. Variants cover multiple languages used by the app and product databases, and matching uses word-boundary regex to avoid false positives (for example, `porcelain` does not match `pork`).

**Special cases:**
- **Fatty alcohols** — cetyl alcohol, stearyl alcohol, behenyl alcohol, and similar food emulsifiers are explicitly excluded from the alcohol haram check
- **Alcohol-free labels** — ingredients marked `alcohol-free` are not flagged

### Layer 3 — Keyword safety override

After AI analysis completes, keyword matching always runs a second time as a safety net. If keywords detect a haram ingredient that the AI missed, **the product is overridden to not halal**. This prevents AI false negatives from slipping through.

### Custom keywords

Approved community keyword suggestions (stored in Supabase) are applied on top of the built-in lists, following the same matching logic. Each approved rule has a **canonical** id (e.g. `pork`), a **variants** array for multilingual matching, and optional **translations** (`de`, `tr`, …) for result-screen labels. Users can submit extra spellings when suggesting a keyword; admins merge duplicates into one rule instead of creating parallel entries.

**Admin moderation:** see [docs/ADMIN_KEYWORDS.md](docs/ADMIN_KEYWORDS.md) for the full workflow (approve, merge, variants, translations, SQL).

---

## Managing the Rules Engine

The rules engine is deliberately simple and auditable. Most changes should be made either as approved custom keywords in Supabase or as built-in keyword changes in code.

### Where rules live

| Purpose | File / place |
|---|---|
| Built-in haram and suspicious keyword reasons | `lib/constants/ingredient_keywords.dart` |
| Multilingual variants and E-number variants | `lib/constants/ingredient_keywords.dart` |
| Alcohol exceptions such as fatty alcohols and alcohol-free labels | `lib/constants/ingredient_keywords.dart` and `lib/services/halal_rules_engine.dart` |
| Localized display names in the result UI | `lib/constants/ingredient_display_names.dart` |
| Engine logic and structured result model | `lib/services/halal_rules_engine.dart` |
| Product lookup integration and custom keyword merge | `lib/services/product_service.dart` |
| User-visible keyword catalog and suggestion flow | `lib/screens/keywords_screen.dart` |
| Approved remote rules | Supabase `keywords` table |
| Pending user suggestions | Supabase `keyword_suggestions` table |
| Admin guide (community keywords & translations) | [docs/ADMIN_KEYWORDS.md](docs/ADMIN_KEYWORDS.md) |

### Built-in rule vs custom keyword

Use a **custom keyword** when:

- you want to add a keyword without shipping a new app version;
- it is a narrow addition with clear wording and reason;
- the same matching logic is enough;
- it came from community feedback and still needs operational moderation.

Change the **built-in rules** when:

- the rule is safety-critical and should work offline;
- a false positive or false negative is caused by matching logic;
- the keyword needs multilingual variants;
- the exception needs code support, such as a new alcohol-related exception;
- the app UI needs localized display names for the keyword.

### Adding a built-in haram or suspicious keyword

1. Edit `lib/constants/ingredient_keywords.dart`.
2. Add the canonical keyword to exactly one map: `IngredientKeywords.haram` or `IngredientKeywords.suspicious`.
3. Add the same canonical key to the matching variants map: `IngredientKeywords.haramVariants` or `IngredientKeywords.suspiciousVariants`.
4. Include common spellings, E-number formats, and language variants. For E-numbers, include both forms, for example `e471` and `e-471`.
5. If the ingredient appears in the UI and a localized label helps, add it to `lib/constants/ingredient_display_names.dart`.
6. Add or update tests in `test/constants/ingredient_keywords_test.dart`, `test/services/keyword_analysis_test.dart`, and, when verdict behavior changes, `test/services/product_service_test.dart`.
7. Run the focused checks:

```bash
dart analyze lib/services/halal_rules_engine.dart lib/services/product_service.dart lib/constants/ingredient_keywords.dart
flutter test test/constants/ingredient_keywords_test.dart test/services/halal_rules_engine_test.dart test/services/keyword_analysis_test.dart test/services/product_service_test.dart
```

### Adding a custom keyword in Supabase

Custom keywords are read by `KeywordService.fetchCustomKeywords()` from the `keywords` table and merged into `ProductService` before product analysis.

The table shape is:

```sql
canonical text not null unique,
category text not null check (category in ('haram', 'suspicious')),
reason text not null,
variants text[] not null default '{}',
translations jsonb not null default '{}'  -- e.g. {"de":"schwein","tr":"domuz"}
```

Example:

```sql
insert into keywords (canonical, category, reason, variants, translations)
values (
  'pork',
  'haram',
  'Contains pork or pork-derived ingredient',
  array['pork', 'schwein', 'domuz', 'porc'],
  '{"de":"schwein","tr":"domuz","fr":"porc"}'::jsonb
);
```

**Translations vs variants:** `variants` is a flat list of every spelling that should match ingredient text. `translations` maps locale codes to terms for UI labels; those terms are also merged into the effective variant list at runtime. Prefer one canonical row per concept and merge aliases (see [docs/ADMIN_KEYWORDS.md](docs/ADMIN_KEYWORDS.md)).

User suggestions flow into `keyword_suggestions` (with optional `variants`). Admins approve from **Admin panel → Rules → Suggestions**; the app can merge into an existing rule when an alias already exists. The keyword screen lets signed-in users submit suggestions; approval stays a moderated action.

### Fixing false positives

False positives usually mean the matching rule is too broad.

- Add a failing test first in `test/services/keyword_analysis_test.dart`.
- Prefer adding a specific exception rather than weakening the whole keyword.
- For single-word keywords, preserve word-boundary matching.
- For alcohol-related false positives, check `IngredientKeywords.alcoholFamily` and `fattyAlcoholPrefix`.
- For phrases, be careful: phrase variants currently use substring matching, so overly generic phrases can match too much.

Examples already handled:

- `cetyl alcohol` is treated as fatty alcohol, not drinking alcohol.
- `alcohol-free` and `alcohol free` are not flagged as haram alcohol.
- `porcelain` does not match `pork`.

### Fixing false negatives

False negatives usually mean the canonical keyword is missing a variant or the product database uses a normalized ingredient ID we do not cover yet.

- Add the ingredient text that failed to a test.
- Add the missing variant to the relevant variants map.
- Include normalized forms from Open Food Facts IDs, where useful. The app already analyzes structured ingredient IDs after replacing language prefixes and hyphens.
- If the term can be haram in one context and harmless in another, consider classifying it as `suspicious` rather than `haram`.

### What the engine returns

`HalalRulesEngine.analyzeIngredients()` returns a `HalalRulesResult`:

| Field | Meaning |
|---|---|
| `verdict` | `halal` or `haram` for deterministic keyword analysis |
| `checkedValues` | Ingredient strings that were checked |
| `checkedRuleCount` | Number of active built-in/custom keyword rules in that engine |
| `matches` | Structured matches with value, canonical keyword, reason, verdict, and category |
| `warnings` | Map used by the result UI for per-ingredient explanations |
| `translations` | Canonical keyword hints used for localized ingredient labels |
| `explanation` | Plain-language summary shown to users |

In the result screen, users see a compact transparency summary for the current product and can open **Keywords** to inspect the full rule catalog.

### Release checklist for rule changes

- Rule reason text is clear and user-facing.
- Haram vs suspicious classification is conservative and defensible.
- Variants include common spellings and E-number formats.
- Tests cover both the match and at least one non-match.
- `flutter test` passes.
- If the change affects legal/religious interpretation, mark it suspicious or route it through Deep Analysis/community review rather than making a hard haram rule too quickly.

---

## Deep Analysis & Community

### Deep Analysis

The standard scan gives a quick verdict. Deep Analysis goes further — it runs a separate AI pass using **Claude Sonnet** and returns a detailed breakdown for *every* ingredient, not just the flagged ones.

**How to trigger it:**

1. Scan a product and open the result screen.
2. Tap the **Deep Analysis** card (purple, with a science icon).
3. If no analysis exists yet, tap **Analyse** — this calls the `deep-analyze-product` Edge Function and may take 10–30 seconds.
4. The screen moves through pipeline stages as the analysis progresses.

> Sign-in is required to trigger analysis. The result is cached in Supabase and shared with all users — so the first person who analyses a product pays the wait; everyone else gets it instantly.

**What each ingredient card shows:**

| Field | Description |
|---|---|
| Verdict | `halal` / `haram` / `suspicious` / `unknown` — colour-coded |
| Confidence | `high` (universally agreed) / `medium` (mainstream) / `low` (contested across madhabs) |
| Reason | Plain-language explanation of the verdict |
| Islamic basis | Quranic verse, hadith, scholarly consensus, or fatwa body reference |
| Also known as | Alternative names and E-numbers the ingredient may appear under |

**Analysis pipeline stages:**

```
pending          → queued, waiting for the AI run
ai_analyzing     → Claude Sonnet is processing (do not retry)
ai_done          → AI complete, results visible
community_review → opened for community discussion by admin
consulting       → escalated to a scholar
resolved         → final verdict set by scholar or admin
```

Admins can trigger a batch run on all pending products via the `batch-analyze` Edge Function (admin role required).

---

### Ingredient Challenges

If you believe the AI got a specific ingredient wrong, you can file a formal challenge.

1. On the Deep Analysis screen, expand any ingredient card and tap **Challenge verdict**.
2. Select what the verdict *should* be and write your reasoning (cite sources if possible — Quran, hadith, fatwa body).
3. The challenge appears in the **Community → Challenges** tab, visible to all users.
4. An admin or scholar can resolve or dismiss it, optionally adding a resolution note.

Challenges are tracked separately from discussions so they can be acted on systematically.

---

### Community Discussions

Every product has a discussion space, accessible from the result screen or the Deep Analysis screen.

- **Discussions tab** — browse or start threads about the product. Threads can be titled (e.g. "Is the gelatin bovine or porcine?") or left untitled.
- **Challenges tab** — see all open ingredient challenges and their resolution status.
- Inside a thread, post top-level comments or reply to a specific comment. Upvote/downvote with the thumb icons.
- Locked threads (set by admin) remain readable but accept no new comments.

Sign-in via Google is required to post or vote.

---

```
Flutter App
│
├── HomeScreen              Barcode scanner (mobile_scanner)
├── ResultScreen            Verdict + per-ingredient breakdown + analysis/community cards
├── DeepAnalysisScreen      Per-ingredient AI analysis with Islamic basis + challenge sheet
├── DiscussionScreen        Community threads (Discussions tab + Challenges tab)
├── StartScreen             Scan history (last 50 scans)
└── KeywordsScreen          View / suggest custom keywords

Services
├── ProductService          Orchestrates the full lookup pipeline
├── HalalRulesEngine        Deterministic rule matching + transparent result model
├── AnalysisService         Request / fetch deep analysis; admin batch trigger
├── CommunityService        Challenges, discussions, comments, votes (Supabase direct)
├── CacheService            30-day local cache (SharedPreferences)
├── DatabaseService         Scan history (SQLite — halal_scan.db)
├── KeywordService          Fetches approved custom keywords from Supabase
└── FeedbackService         Local community feedback storage

Backend (Supabase)
├── lookup-product          Edge Function: OpenFoodFacts → Claude/Gemini → keyword fallback → cache
├── deep-analyze-product    Edge Function: per-ingredient Claude Sonnet analysis (auth required)
├── batch-analyze           Edge Function: process all pending analyses (admin only)
├── report-issue            Edge Function: submit wrong-result reports
├── products                Shared product source data (ingredients, images, labels)
├── product_analysis        Barcode scan verdict per product (see Development → Supabase)
├── product_analyses        Deep analysis pipeline records (status + AI result JSON)
├── ingredient_challenges   Community ingredient verdict challenges
├── discussions             Per-product discussion threads
├── comments                Threaded comments with soft-delete
├── comment_votes           Upvote/downvote per user per comment
├── profiles                User profiles (auto-created on first Google sign-in)
├── keywords                Approved custom halal keywords
└── keyword_suggestions     Community keyword submissions (pending moderation)
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
- A [Supabase](https://supabase.com) project with Edge Functions deployed
- Google OAuth configured in the Supabase dashboard (Authentication → Providers → Google)

Claude / Anthropic is **optional** — scans work via Open Food Facts + keywords. Claude is **off** in this project for now (`CLAUDE_ENABLED=false`; no API key required).

### Supabase secrets

```bash
# Claude disabled by default (omit CLAUDE_API_KEY unless re-enabling)
supabase secrets set CLAUDE_ENABLED=false
# supabase secrets set CLAUDE_API_KEY=sk-ant-...

supabase secrets set GEMINI_API_KEY=your_google_ai_studio_key
# Optional — omit or set to false to disable Gemini (ingredient lookup + halal tier-1)
supabase secrets set GEMINI_ENABLED=true
# Optional dev override — same as superadmin toggle below (prefer Admin → Settings in app)
# supabase secrets set GEMINI_LOOKUP_EMPTY_OFF=true
```

Gemini ingredient lookup uses **Grounding with Google Search** (billable on the Gemini API). By default it runs only when a user requests AI ingredients on the result screen, an admin approves that request, and the app calls `lookup-product` with `fetchAiIngredients: true`. **Superadmins** can enable automatic lookup for empty Open Food Facts rows in **Admin panel → Settings** (`app_config.gemini_lookup_empty_off`). Alternatively set **`GEMINI_LOOKUP_EMPTY_OFF=true`** in edge-function env for local dev. Still requires `GEMINI_ENABLED` and `GEMINI_API_KEY`. Use the same Google AI Studio project/key you test with in chat, with billing enabled if searches return no `groundingMetadata` in Edge Function logs. After a successful API attempt for a given barcode plus normalized product name, the edge function **does not call Gemini again** until the name changes (migration `20260527130100_gemini_web_ingredient_lookup_attempt.sql`); the app hides the request button and shows a short confirmation.


### Database migrations

```bash
supabase db push
```

This applies all migrations including the community tables (`profiles`, `product_analyses`, `ingredient_challenges`, `discussions`, `comments`, `comment_votes`).

### Deploy Edge Functions

```bash
supabase functions deploy lookup-product
supabase functions deploy deep-analyze-product
supabase functions deploy batch-analyze
supabase functions deploy report-issue
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

### Supabase shared product cache

Barcode lookup verdicts are stored in **`product_analysis`**. Source data (name, ingredient list, images, labels) lives in **`products`**. Reads use the **`products_full`** view (`products` LEFT JOIN `product_analysis`).

**Written by:** `lookup-product` Edge Function (normal scan + stale re-analysis), and approved community ingredient contributions (keyword re-run → upsert).

There is **no** separate `verdict = 'suspicious'` column. The app infers **suspicious** from `suspicious_ingredients` being non-empty while `haram_ingredients` is empty and `is_halal` is false.

| Column | Type | Role |
|--------|------|------|
| `barcode` | `TEXT` PK | FK → `products.barcode` |
| `is_halal` | `BOOLEAN` | `true` only when no haram, no suspicious, and not blocked by cert/unknown rules; `false` for haram, suspicious-only, or needs-cert |
| `is_unknown` | `BOOLEAN` | No usable ingredient data to analyse |
| `is_non_food` | `BOOLEAN` | Non-food product (dietary rules N/A) |
| `haram_ingredients` | `JSONB` | Array of matched ingredient strings (definitively not permissible) |
| `suspicious_ingredients` | `JSONB` | Array of matched ingredient strings (source must be verified, e.g. E471, whey) |
| `ingredient_warnings` | `JSONB` | Object: ingredient text → reason string (shown on result screen) |
| `explanation` | `TEXT` | Plain-language summary of the verdict |
| `analyzed_by_ai` | `BOOLEAN` | `true` if Claude/Gemini set the lists; `false` if keyword-only |
| `analyzed_at` | `TIMESTAMPTZ` | When this row was last written |

**`products`** (not in `product_analysis`): `ingredients`, `ingredient_source` (`off` / `ai` / `community`), `requires_halal_cert`, images, `labels`, `is_managed`, `fetched_at`, `last_analysed_at`, `updated_at`.

**Keyword safety override (edge function):** after AI, built-in keywords always win. If keywords find **haram** or **suspicious** that AI missed, lists are merged and **`is_halal` is forced to `false`**.

**App-side only (not in Supabase):** `ingredientCanonicals` and `ingredientTranslations` on the `Product` model — stored in SharedPreferences cache, rebuilt from keywords when needed.

**Local scan history** (`halal_scan.db` → `scans` table): stores `is_halal` and optional `verdict` (`halal`, `haram`, `suspicious`, `nocert`, …) for the recent-scans list; it does **not** store the full `suspicious_ingredients` array.

**Related, separate table:** `product_analyses` (plural) holds **Deep Analysis** pipeline state and per-ingredient AI JSON — not the same as barcode scan cache above.

Migration: `supabase/migrations/20260519000000_create_product_analysis.sql`.

### Testing

See **[TESTING.md](TESTING.md)** for the full guide: CI unit tests, live API integration, **UI E2E** (full app, no widget mocks), OCR on device, fixtures, and when to use each layer.

Quick start:

```bash
# CI (every change)
flutter test test/services/ test/constants/ test/models/ test/config_test.dart

# UI E2E on emulator (local Supabase — see TESTING.md)
.\scripts\start_e2e_supabase.ps1
.\run_ui_e2e_test.ps1          # uses dart_defines.e2e.json
```

### Parallel install (debug + release)

Debug builds use the app ID `app.halalscan.dev`, so they coexist with a release install as two separate apps on the same device.

---

## Data sources

- **[Open Food Facts](https://world.openfoodfacts.org)** — product data, ingredient lists, images (CC BY-SA)
- **[Anthropic Claude](https://anthropic.com)** — AI ingredient analysis (server-side only)
- **[Supabase](https://supabase.com)** — shared product cache, custom keywords, community suggestions
