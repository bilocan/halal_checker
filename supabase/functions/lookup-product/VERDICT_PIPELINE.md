# Lookup-product: request & verdict pipelines

**Keep this file in sync with the code.** When you add, remove, or reorder a step, update the matching section here and run:

```bash
deno test --allow-env supabase/functions/lookup-product/verdictRules_test.ts
deno test --allow-env supabase/functions/lookup-product/
```

| If you change… | Update in code | Update in this doc |
|----------------|----------------|-------------------|
| HTTP / cache / OFF / Gemini ingredients | `handler.ts`, `index.ts`, helpers below | [Request orchestration](#request-orchestration-handlerts) |
| Halal verdict steps (AI, keywords, overrides) | `verdictRules.ts` | [Verdict pipeline](#verdict-pipeline-verdictrulests) |
| Stale DB re-analysis only | `reanalysis.ts` | [Stored re-analysis](#stored-re-analysis) |
| Empty-OFF Gemini ingredient fetch | `ingredientResolver.ts` | [Ingredient resolution](#ingredient-resolution-before-verdict) |
| Keyword lists | `keyword.ts` (+ app `product_service.dart`) | [Keyword source](#keyword-source) |
| Post-rule order / cert / name fallback | `POST_ANALYSIS_RULES` in `verdictRules.ts` | [Post-analysis rules](#post-analysis-rules-fixed-order) |

App-side mirror: `lib/services/product_service.dart` + `lib/services/keyword_service.dart` (keyword safety override must stay equivalent).

---

## Request orchestration (`handler.ts`)

High-level flow for each `lookup-product` POST:

```mermaid
flowchart TD
  A[parseRequest] --> B[getHalalScanProduct]
  B --> C{is_managed?}
  C -->|yes| D[Return DB row]
  C -->|no| E{stale or force refresh?}
  E -->|yes| F[runStoredProductReanalysis]
  E -->|no| G{cache hit?}
  G -->|yes, no vision needed| H[Return cached row]
  G -->|no / vision stub| I{OFF fetch}
  I -->|miss| J[analyzeFromDbStub]
  I -->|hit| K[OFF path + computeVerdict]
  F --> L[persistLookupAndRespond]
  J --> L
  K --> L
```

| Step | Module | What it does |
|------|--------|----------------|
| Parse body | `requestParser.ts` | `barcode`, `force`, `fetchAiIngredients` |
| Load cache | `productQueries.ts` | `getHalalScanProduct` from `products_full` |
| Gemini empty-OFF gate | `ingredient_lookup_gate.ts` | `refetchForGeminiAuto`, bypass cache when enabled |
| Managed | `reanalysis.ts` | Return row unchanged |
| Stale / force | `reanalysis.ts` | `computeVerdict({ skipAi: true })` on stored data |
| Cache return | `index.ts` | Skip if empty ingredients + `image_ingredients_url` (vision path) |
| OFF fetch | `fetch.ts` | `fetchOpenFactsProduct` (OFF → OBF → OPF) |
| OFF miss | `index.ts` | `analyzeFromDbStub` — DB stub + optional Gemini ingredients |
| Full analysis | `index.ts` | Community override → `computeVerdict` → `persistLookupAndRespond` |
| Persist | `persistence.ts` | `upsertProduct` + `upsertAnalysis` + `products_full` read |

Supporting modules: `community.ts`, `lookupHelpers.ts` (labels/categories), `db.ts` (`toProduct`, `isStale`).

---

## Ingredient resolution (before verdict)

Runs in `index.ts` (OFF path and DB-stub path), **not** inside `computeVerdict`.

| Priority | Source | Module |
|----------|--------|--------|
| 1 | Open Food Facts text | `fetch.ts` → `ingredientResolution.ts` → display + analyze sources |
| 2 | Gemini web lookup (empty OFF) | `ingredientResolver.ts` |
| 3 | Community approved list | `community.ts` (wins over OFF/Gemini) |

Gemini ingredient lookup conditions: `ingredient_lookup_gate.ts` (`shouldRunGeminiIngredientLookup`).  
Halal **verdict** on the resulting list: `computeVerdict` below.

---

## Verdict pipeline (`verdictRules.ts`)

Entry point: **`computeVerdict(ctx: VerdictContext)`**.

Implementation pattern: ordered **async steps** on `VerdictState`, then **post-analysis rules** on `VerdictSnapshot`.  
Do not use a state machine — each step reads the snapshot left by the previous step.

### Phase 0 — Bootstrap (sync)

| Step | Function | Notes |
|------|----------|--------|
| 0a | `createInitialState` | `keywordAnalysis(ingredients)` → `kwFirst`; `keywordAnalysis(labels)` → `kwLabels` |
| 0b | Initial snapshot | Non-food / halal-by-category-empty-ingredients shortcuts; else `kwFirst` verdict; `haramLabels`/`suspiciousLabels` seeded from `kwLabels` |

`kwFirst` and `kwLabels` are both frozen for the whole run — post-rules use them for **keyword safety override** even after AI changes the snapshot.

### Phase 1 — Async pipeline (`VERDICT_PIPELINE`)

| Order | Step | Function | Skipped when |
|-------|------|----------|--------------|
| 1 | Text AI | `stepTieredTextAi` | See [Text AI skip](#text-ai-skip) |
| 1a | → Gemini Flash | `analyzeWithGemini` | No key / `GEMINI_ENABLED=false` / prior skip |
| 1b | → Claude Haiku | `analyzeWithClaude` | Only if Gemini did not analyze |
| 2 | Vision + AI | `stepVisionWithOptionalAi` | See [Vision skip](#vision-skip) |
| 2a | → OCR | `analyzeWithClaudeVision` | Reads `imageIngredientsUrl` |
| 2b | → Keywords on OCR list | `keywordAnalysis` | If haram found, skip AI on vision list |
| 2c | → Gemini / Claude | Same as tier 1 | On vision-derived ingredients |
| 3 | Post-analysis | `stepPostAnalysis` | `applyPostAnalysisRules` (always runs) |

#### Text AI skip

`shouldSkipTextAi` is true when any of:

- `ctx.skipAi` (stored re-analysis)
- `isNonFood`
- `isHalalByCategory`
- `kwFirst.haram.length > 0`
- `kwLabels.haram.length > 0` ← haram label keyword found
- `haramCategory !== null`
- `ingredients.length === 0`
- `ingredientSource === 'ai'`

#### Vision skip

`shouldRunVision` is false when:

- `ctx.skipAi`
- Text AI already produced a verdict (`analyzedByAI`)
- Ingredients non-empty after bootstrap
- Non-food, halal-by-category, or haram category set
- No `imageIngredientsUrl` / Claude disabled / no API key

### Post-analysis rules (fixed order)

Applied in `applyPostAnalysisRules` — **must not reorder** without updating tests and this doc.

| Order | Rule | Effect |
|-------|------|--------|
| 1 | `applyKeywordHaramOverride` | If `kwFirst` has haram and snapshot still `isHalal` → force not halal, merge lists |
| 2 | `applyKeywordSuspiciousOverride` | Same for suspicious |
| 3 | `applyHaramCategoryOverride` | `ctx.haramCategory` wins over AI |
| 4 | `applyNameFallback` | If `isUnknown`, keyword-scan product name |
| 5 | `applyLabelHaramOverride` | If `kwLabels` has haram → force not halal, populate `haramLabels`/`labelWarnings` |
| 6 | `applyLabelSuspiciousOverride` | If `kwLabels` has suspicious and snapshot still `isHalal` → force not halal, populate `suspiciousLabels` |
| 7 | `applyHalalCertRequirement` | Animal product without halal label → `requiresHalalCert`, not halal; skipped if `haramLabels` non-empty |
| 8 | `applySuspiciousNotHalal` | Suspicious only (no haram ingredients or labels) → `isHalal = false` |

Categories for cert: `categories.ts` (`ANIMAL_PRODUCT_CATEGORIES`, `HALAL_CERT_LABELS`, `ANIMAL_PRODUCT_NAME_TERMS`).

### Stored re-analysis

`reanalysis.ts` → `computeVerdict({ …, skipAi: true, rawCategories: [], haramCategory: null, isHalalByCategory: false })`.

- No OFF refetch, no text AI, no vision.
- Full post-analysis rules **do** run (cert, suspicious-only, keyword safety).

---

## Keyword source

When the displayed ingredient label is not keyword-analyzable (e.g. Cyrillic), the pipeline:

1. Keeps **display** ingredients from `ingredients_text` (original language).
2. Adds **analyze** sources from `ingredients_text_{en,de,fr,…}` when present.
3. Adds **OFF taxonomy** IDs (`en:*` from structured `ingredients` array).
4. If primary script is unsupported, no translated OFF text exists, and no keyword matches (including from taxonomy) → `isUnknown`, `keywordMatchSource=unanalyzable`.

Transparency fields: `keyword_match_source`, `keyword_match_origins`, `analyze_lang`, `display_lang`.

| Layer | Location |
|-------|----------|
| Built-in haram/suspicious | `keyword.ts` (`HARAM_ENTRIES`, `SUSPICIOUS_ENTRIES`) |
| DB custom keywords | `productQueries.ts` → `loadCustomKeywords` |
| App constants | `lib/services/product_service.dart` — keep aligned when changing builtins |

---

## Environment & defaults

| Secret / flag | Effect |
|---------------|--------|
| `CLAUDE_ENABLED=false` (default in repo) | Skip Claude text + vision |
| `CLAUDE_API_KEY` | Required for Claude paths when enabled |
| `GEMINI_ENABLED` / `GEMINI_API_KEY` | Gemini text AI + ingredient web lookup |
| `GEMINI_LOOKUP_EMPTY_OFF` | Auto Gemini ingredients when OFF empty (see `ingredient_lookup_gate.ts`) |

**Gemini ingredient web lookup (shared):** `_shared/gemini_ingredient_lookup.ts` — model, system prompt, and `generateContent` body used by `lookup-product` (Flutter) and `admin-gemini-ingredient-lookup` (web admin probe). Request contract: `_shared/gemini_ingredient_lookup_test.ts` (no API calls in CI).

Production default: **Open Food Facts + keywords + post-rules**; AI tiers optional.

---

## Tests

| File | Covers |
|------|--------|
| `verdictRules_test.ts` | `computeVerdict`, `applyPostAnalysisRules`, `skipAi` |
| `index_test.ts` | `keyword.ts`, gates, `toProduct` (via `db.ts`) |
| `db_test.ts` | `isStale`, `toProduct` field mapping |
| `lookupHelpers_test.ts` | `normalizeStoredLabels`, `classifyOffCategories` |
| `fetch_test.ts` | OFF parsers + `fetchOpenFactsProduct` (mocked HTTP) |
| `requestParser_test.ts` | `parseRequest` validation |
| `ingredientResolver_test.ts` | `resolveGeminiIngredients` (mocked Gemini HTTP) |
| `reanalysis_test.ts` | `runStoredProductReanalysis`, `jsonManagedProduct` |
| `ai_test.ts` | `parseIngredientList` |
| `ai_api_test.ts` | `analyzeWithGemini/Claude/Vision`, `geminiIngredientLookup` (mocked HTTP + shared request body) |
| `_shared/gemini_ingredient_lookup_test.ts` | `buildGeminiIngredientLookupRequest` snapshot (zero token cost) |
| `persistence_test.ts` | `persistLookupAndRespond` (`products_full` vs fallback) |
| `handler_test.ts` | `handleLookup` / `handleLookupRequest` (mocked Supabase + OFF) |

Flutter: `test/services/product_service_test.dart`, `needs_reanalysis_test.dart` (keyword override after edge function).

---

## File map

```
lookup-product/
  index.ts              Deno.serve entry
  handler.ts            Request orchestration (injectable deps for tests)
  verdictRules.ts       computeVerdict + post-rules  ← pipeline source of truth
  reanalysis.ts         Stale / force stored re-analysis
  ingredientResolver.ts Gemini ingredients (empty OFF)
  keyword.ts            Keyword engine
  ai.ts                 Gemini / Claude / vision
  fetch.ts              Open*Facts fetch + parse
  persistence.ts        DB upsert + JSON response
  productQueries.ts     products_full + custom keywords
  requestParser.ts      Request body
  community.ts          Approved community ingredients
  lookupHelpers.ts      Labels + OFF category classification
  ingredient_lookup_gate.ts  Gemini empty-OFF policy
  categories.ts         Haram / halal / animal / cert sets
  VERDICT_PIPELINE.md   This document
```
