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
| Bulk retest of stored products | `../retest-products/` | [Bulk retest tool](#bulk-retest-tool-retest-products) |
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
  C -->|no| E{stale or force\nor unknown-OFF+stored-tags?}
  E -->|yes| F[runStoredProductReanalysis]
  E -->|no| G{cache hit?}
  G -->|yes, no vision/tag-backfill needed| H[Return cached row]
  G -->|no DB row / vision stub / unknown-OFF (no tags yet)| I{OFF fetch - new products only}
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
| Stale / force / unknown+tags | `reanalysis.ts` | `computeVerdict({ skipAi: true })` on stored data — routes when stale, force=true, or unknown+OFF with `tags_version>0`; reads stored `categories_tags` for halal-by-category; OFF is **never** re-fetched for existing rows |
| Cache return | `index.ts` | Skip if `!unknown && !needsTagFetch && !needsVisionIngredients`; unknown+OFF rows without stored tags still fall through to the tag-backfill path |
| OFF fetch | `fetch.ts` | `fetchOpenFactsProduct` (OFF → OBF → OPF) — called **only when no DB row exists** (`!existing`); existing products always use stored data |
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
| 0a | `createInitialState` | Strips placeholder tokens (`/^unknown[.!?,;:]*$/i`) from `ctx.ingredients`; `keywordAnalysis(ingredients)` → `kwFirst`; `deduplicateLabels(labels)` then `keywordAnalysis` → `kwLabels` |
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
| 5 | `applyLabelHaramOverride` | If `kwLabels` has haram → force not halal, populate `haramLabels`/`labelWarnings`; explanation = label text when no ingredient haram, else ingredient explanation + label note appended |
| 6 | `applyLabelSuspiciousOverride` | Always merges `suspiciousLabels`/`labelWarnings` from `kwLabels`; if snapshot still `isHalal` → force not halal, set label-based explanation (defers when ingredient flags present); if already not halal → appends suspicious-label note to existing explanation |
| 7 | `applyAdditivesHaramOverride` | Merges haram additive keyword matches into snapshot |
| 8 | `applyAdditivesSuspiciousOverride` | Merges suspicious additive keyword matches into snapshot |
| 9 | `applyVeganFlavouringAdjustment` | When vegan label evidence (`en:vegan`, etc.): rewrites `flavouring` / `natural flavour` warnings and suspicious-only explanation — non-animal per certification, alcohol extraction still unclear. Does not change `isHalal`. Vegetarian labels do not qualify. |
| 10 | `applyHalalCertRequirement` | Animal product without halal label → `requiresHalalCert`, not halal; skipped if `haramLabels` non-empty; overwrites `explanation` with the matched category/name/ingredient reason |
| 11 | `applySuspiciousNotHalal` | Suspicious only (no haram ingredients or labels) → `isHalal = false` |

Categories for cert: `categories.ts` (`ANIMAL_PRODUCT_CATEGORIES`, `HALAL_CERT_LABELS`, `ANIMAL_PRODUCT_NAME_TERMS`, `ANIMAL_INGREDIENT_TERMS`). Name/ingredient term matching uses `matchesAnimalTerm` (word-boundary regex, mirrors `keyword.ts`'s `wPre`/`wPost`) — plain substring matching would false-positive on short terms like `ente` (German "duck") inside unrelated words (e.g. Spanish "preferentemente").

### Match-language transparency

Every keyword/term match carries its source language, purely for debugging cross-language false positives (e.g. barcode 20289119: `ente` matched inside Spanish `preferentemente`) — never used in matching logic itself.

- **`ANIMAL_PRODUCT_NAME_TERMS` / `ANIMAL_INGREDIENT_TERMS`** (`categories.ts`) are `Map<term, lang>`, not `Set<term>`. `applyHalalCertRequirement` looks up the matched term's language, compares it against `ctx.analyzeLang ?? ctx.displayLang` (the language the ingredient text was actually analyzed in), and appends a mismatch note to `explanation` when they differ. Category matches (`en:`/`de:`/`tr:` prefix) aren't compared — OFF category tags are frequently in a different language than the ingredient list, so a mismatch there is expected, not suspicious. Result fields: `halalCertMatchTerm`, `halalCertMatchLang`.
- **`HARAM_ENTRIES` / `SUSPICIOUS_ENTRIES`** (`keyword.ts`) — each variant string is tagged in `VARIANT_LANGUAGE`. E-number variants (`e441`, `e-441`, …) are language-neutral and omitted (detected via `E_NUMBER_VARIANT`, not looked up). Exposed per-match via `KeywordResult.keywordMatchLanguages` (ingredient/label/additive token → lang), merged from `kwFirst` + `kwLabels` + `kwAdditives` once in `createInitialState` and carried through the post-rule pipeline unchanged (`VerdictSnapshot.keywordMatchLanguages`).
- Persisted on `product_analysis` (`keyword_match_languages jsonb`, `halal_cert_match_term text`, `halal_cert_match_lang text`), exposed via `products_full`. Surfaced in the Flutter result screen's transparency card (`result_transparency_card.dart`) and the admin retest tool (`halal-checker-web/app/admin/retest/RetestProductsClient.tsx`) plus the public product page.

### Stored re-analysis

`reanalysis.ts` → `computeStoredReanalysis` reads `existing.categories_tags` → `computeVerdict({ …, skipAi: true, rawCategories: <stored>, haramCategory: <derived>, isHalalByCategory: <derived> })`.

- No OFF refetch, no text AI, no vision.
- Full post-analysis rules **do** run (cert, suspicious-only, keyword safety).
- `runStoredProductReanalysis` (live lookup path) calls `computeStoredReanalysis` then persists via `persistLookupAndRespond`. It only runs for one barcode at a time, lazily, when that product is next looked up (stale/force) — adding a keyword does **not** retroactively touch rows already sitting in Supabase.
- **Bulk retest tool** (`../retest-products/`): reuses the same `computeStoredReanalysis` across every stored product to preview keyword/rule changes before writing them back. See below.

---

## Bulk retest tool (`retest-products/`)

Admin-only tool (web admin → **Retest** tab) for previewing keyword/custom-rule changes against products already sitting in Supabase, since they're otherwise only re-analysed lazily per-barcode. Sibling function, reuses `computeStoredReanalysis` from `reanalysis.ts` — never duplicates verdict logic.

| Action | What it does |
|--------|--------------|
| `scan` | Batches through `products_full` (ordered by barcode, cursor-paginated), recomputes each non-managed product's verdict, and — only when it differs from the stored one — upserts a row into `product_retest_diffs` (`old_snapshot`, `new_snapshot`, `apply_payload`). Call repeatedly with the returned `nextCursor`/`runId` until `done`. Progress (`cursor`, `done`, running `scanned`/`changed` totals) is persisted per `run_id` in `product_retest_runs`; if the caller passes a `runId` without a `cursor` (e.g. after a page reload), it resumes from the persisted cursor instead of rescanning the catalog from the start. Optionally scoped via `ScanFilter` (`barcodes`, `nameQuery` → `ilike` on `name`, `analyzedBefore`/`analyzedAfter` → range on `last_analysed_at`) — a filter only takes effect when *starting* a new run; once a run exists, its filter is persisted in `product_retest_runs` (`filter_*` columns) and is authoritative on every subsequent call, so resuming never silently widens a scoped scan to the whole catalog. |
| `list` | Paginated diffs for a `runId`, for the review UI. |
| `apply` | Persists `apply_payload` (`{ product, analysis }`, the exact `ProductRow`/`AnalysisRow` from `computeStoredReanalysis`) via `upsertProduct`/`upsertAnalysis` for selected barcodes (or all pending), marks them `applied`. |
| `discard` | Deletes unapplied diff rows for a run, and drops its `product_retest_runs` progress row — a discarded run is not resumable or restorable. |
| `latest` | Finds the most recently updated run in `product_retest_runs` that's still worth surfacing — not fully scanned yet, or fully scanned but with diffs the admin hasn't applied/discarded — so the web UI can restore an in-progress/reviewable run (including its scan filter, so the UI can show/re-populate the scope) after a refresh instead of starting from a blank page. Returns `{ runId: null }` when there's nothing to restore. |

`old_snapshot`/`new_snapshot` are compact `RetestSnapshot`s (`retestDiff.ts`) — `isHalal`, `isUnknown`, haram/suspicious ingredient+label+additive lists, `requiresHalalCert`, `explanation` — compared order-insensitively (`snapshotsEqual`) so only real verdict changes are staged.

Auth: `profiles.role` = `superadmin` only (web admin panel gates the same way, matching the Gemini probe tool). Tables `product_retest_diffs` / `product_retest_runs` have RLS enabled with no client policies — only the service-role edge function touches them.

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
| `AI_VERDICT_ENABLED=true` | Enable Gemini + Claude text verdict (`stepTieredTextAi`); **unset = disabled** |
| `CLAUDE_ENABLED=false` (default in repo) | Skip Claude text + vision |
| `CLAUDE_API_KEY` | Required for Claude paths when enabled |
| `GEMINI_ENABLED` / `GEMINI_API_KEY` | Gemini ingredient web lookup; also gates Gemini text verdict when `AI_VERDICT_ENABLED=true` |
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
| `reanalysis_test.ts` | `computeStoredReanalysis`, `runStoredProductReanalysis`, `jsonManagedProduct` |
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
