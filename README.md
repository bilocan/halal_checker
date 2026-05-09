# HalalScan

A Flutter app that scans food product barcodes and determines whether they are **halal**, **haram**, or **require verification** according to Islamic dietary law.

## What it does

Point the camera at any food product barcode (or enter it manually). The app fetches the ingredient list, runs a multi-layer halal analysis, and gives you:

- A clear **Halal / Not Halal** verdict with a colour-coded result screen
- A per-ingredient breakdown showing exactly which ingredients were flagged and why
- A full transparency panel listing every keyword that was checked
- **Deep Analysis** — on-demand per-ingredient AI analysis with Islamic scholarly basis, confidence levels, and alternative names
- **Community discussions** — threaded conversations about a product's ingredients with upvoting
- **Ingredient challenges** — formally dispute the verdict on a specific ingredient and track resolution
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

Tests cover the keyword matching engine and halal verdict logic. CI runs them automatically on every push and pull request via GitHub Actions.

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
