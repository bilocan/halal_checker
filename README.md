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

Supported languages: **English**, **Turkish**, **German**

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

**Suspicious keywords** require source verification:

| Keyword | Reason |
|---|---|
| whey | Dairy by-product; halal if no pork-derived rennet |
| rennet | May be animal-derived |
| E471, E472, E473 | Mono/diglycerides; may be animal fat |
| E322 | Lecithin; may be animal-derived |
| E920, L-cysteine | May be animal-derived |
| natural flavour, flavouring | Source unspecified |
| enzymes | May be extracted from animal sources |
| glycerol | May be animal-derived |

Each canonical keyword has variants in `IngredientKeywords.haramVariants` or `IngredientKeywords.suspiciousVariants`. Variants cover multiple languages used by the app and product databases, and matching uses word-boundary regex to avoid false positives (for example, `porcelain` does not match `pork`).

**Special cases:**
- **Fatty alcohols** — cetyl alcohol, stearyl alcohol, behenyl alcohol, and similar food emulsifiers are explicitly excluded from the alcohol haram check
- **Alcohol-free labels** — ingredients marked `alcohol-free` are not flagged

### Layer 3 — Keyword safety override

After AI analysis completes, keyword matching always runs a second time as a safety net. If keywords detect a haram ingredient that the AI missed, **the product is overridden to not halal**. This prevents AI false negatives from slipping through.

### Custom keywords

Approved community keyword suggestions (stored in Supabase) are applied on top of the built-in lists, following the same matching logic.

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
variants text[] not null default '{}'
```

Example:

```sql
insert into keywords (canonical, category, reason, variants)
values (
  'example additive',
  'suspicious',
  'Source may be animal-derived and requires verification',
  array['example additive', 'e-999', 'e999']
);
```

User suggestions flow into `keyword_suggestions`. When a suggestion is approved, the migration trigger copies it into `keywords`. The app’s keyword screen lets users submit suggestions, but approval should stay a moderated/admin action.

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
├── products                Shared product cache
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
- An [Anthropic](https://console.anthropic.com) API key set as a Supabase secret
- Google OAuth configured in the Supabase dashboard (Authentication → Providers → Google)

### Supabase secrets

```bash
supabase secrets set CLAUDE_API_KEY=sk-ant-...
```

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

### Running tests

```bash
flutter test test/services/
```

Tests cover the rules engine, keyword matching, product verdict logic, caching, community services, and UI smoke paths. CI runs them automatically on every push and pull request via GitHub Actions.

### Test fixtures

`test_data/seed_products.json` contains pre-classified products (halal, haram, suspicious) loaded into a separate `halal_test.db` on debug builds. These barcodes are intercepted before any network call, making them available offline.

To add a real product as a fixture, append its barcode to `test_data/seed_barcodes.txt`. The app fetches real product data on the next debug launch and freezes it in the test DB.

### Parallel install (debug + release)

Debug builds use the app ID `app.halalscan.dev`, so they coexist with a release install as two separate apps on the same device.

---

## Data sources

- **[Open Food Facts](https://world.openfoodfacts.org)** — product data, ingredient lists, images (CC BY-SA)
- **[Anthropic Claude](https://anthropic.com)** — AI ingredient analysis (server-side only)
- **[Supabase](https://supabase.com)** — shared product cache, custom keywords, community suggestions
