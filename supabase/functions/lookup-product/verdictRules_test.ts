// Run with: deno test --allow-env supabase/functions/lookup-product/verdictRules_test.ts

import { assertEquals, assertFalse, assertMatch } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { resolveOffIngredientAnalysis } from './ingredientResolution.ts'
import { keywordAnalysis } from './keyword.ts'
import {
  aiVerdictJson,
  claudeTextContent,
  geminiGenerateText,
  restoreTestEnv,
  saveTestEnv,
  setAiEnvEnabled,
  withMockedFetch,
} from './lookup_test_helpers.ts'
import {
  applyPostAnalysisRules,
  computeVerdict,
  type VerdictContext,
  type VerdictSnapshot,
} from './verdictRules.ts'

function baseCtx(overrides: Partial<VerdictContext> = {}): VerdictContext {
  return {
    barcode: 'test-bc',
    ingredients: ['water', 'sugar'],
    name: 'Test Product',
    labels: [],
    rawCategories: [],
    isNonFood: false,
    ingredientSource: 'off',
    haramCategory: null,
    isHalalByCategory: false,
    additivesTags: [],
    customHaramEntries: [],
    customSuspiciousEntries: [],
    imageIngredientsUrl: '',
    ...overrides,
  }
}

function aiSaysHalalSnapshot(overrides: Partial<VerdictSnapshot> = {}): VerdictSnapshot {
  return {
    isHalal: true,
    isUnknown: false,
    haramIngredients: [],
    suspiciousIngredients: [],
    ingredientWarnings: {},
    haramLabels: [],
    suspiciousLabels: [],
    labelWarnings: {},
    haramAdditives: [],
    suspiciousAdditives: [],
    additiveWarnings: {},
    explanation: 'AI incorrectly marked this as halal.',
    ...overrides,
  }
}

// ── computeVerdict (no API keys → AI skipped) ────────────────────────────────

Deno.test('computeVerdict — skipAi skips tiered AI when set', async () => {
  const result = await computeVerdict(baseCtx({
    ingredients: ['water', 'sugar'],
    skipAi: true,
  }))
  assertEquals(result.analyzedByAI, false)
  assertEquals(result.isHalal, true)
})

Deno.test('computeVerdict — clean ingredients → halal, keyword-only', async () => {
  const result = await computeVerdict(baseCtx())
  assertEquals(result.isHalal, true)
  assertEquals(result.isUnknown, false)
  assertEquals(result.analyzedByAI, false)
  assertEquals(result.requiresHalalCert, false)
})

Deno.test('computeVerdict — pork in ingredients → not halal', async () => {
  const result = await computeVerdict(baseCtx({ ingredients: ['pork', 'salt'] }))
  assertEquals(result.isHalal, false)
  assertEquals(result.haramIngredients.length > 0, true)
  assertEquals(result.analyzedByAI, false)
})

Deno.test('computeVerdict — non-food → not halal, fixed explanation', async () => {
  const result = await computeVerdict(baseCtx({ isNonFood: true }))
  assertEquals(result.isHalal, false)
  assertEquals(result.isUnknown, false)
  assertMatch(result.explanation, /non-food/i)
})

Deno.test('computeVerdict — halal category with no ingredients → halal', async () => {
  const result = await computeVerdict(baseCtx({
    isHalalByCategory: true,
    ingredients: [],
  }))
  assertEquals(result.isHalal, true)
  assertEquals(result.isUnknown, false)
  assertMatch(result.explanation, /inherently halal category/i)
})

Deno.test('computeVerdict — empty ingredients → unknown', async () => {
  const result = await computeVerdict(baseCtx({ ingredients: [] }))
  assertEquals(result.isUnknown, true)
  assertEquals(result.analyzedByAI, false)
})

Deno.test('computeVerdict — ai-sourced ingredients skip verdict AI (keyword-only)', async () => {
  const env = saveTestEnv()
  setAiEnvEnabled()
  let geminiVerdictCalls = 0
  try {
    const result = await withMockedFetch((req) => {
      if (req.url.includes('generativelanguage.googleapis.com')) {
        geminiVerdictCalls++
        return geminiGenerateText(aiVerdictJson())
      }
      return new Response('not found', { status: 404 })
    }, async () =>
      computeVerdict(baseCtx({
        ingredients: ['water', 'sugar', 'citric acid'],
        ingredientSource: 'ai',
      })))

    assertEquals(result.analyzedByAI, false)
    assertEquals(geminiVerdictCalls, 0)
    assertEquals(result.isHalal, true)
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('computeVerdict — animal product without halal label → requiresHalalCert', async () => {
  const result = await computeVerdict(baseCtx({
    name: 'Chicken Breast Fillets',
    rawCategories: ['en:chicken'],
    ingredients: ['chicken', 'salt'],
  }))
  assertEquals(result.requiresHalalCert, true)
  assertEquals(result.isHalal, false)
  assertEquals(result.isUnknown, false)
})

Deno.test('computeVerdict — animal product with halal label → no cert flag', async () => {
  const result = await computeVerdict(baseCtx({
    name: 'Halal Chicken',
    rawCategories: ['en:chicken'],
    ingredients: ['chicken', 'salt'],
    labels: ['Halal certified'],
  }))
  assertEquals(result.requiresHalalCert, false)
})

// Regression: barcode 9002600768916 — chicken product with no matching OFF category or name term
// was passing as halal because neither the category nor name path triggered requiresHalalCert.
// The ingredient-level detection in applyHalalCertRequirement now catches this.
Deno.test('computeVerdict — chicken in ingredients, generic category, plain name → requiresHalalCert', async () => {
  const result = await computeVerdict(baseCtx({
    barcode: '9002600768916',
    name: 'Classic Soup',
    rawCategories: ['en:soups', 'en:canned-foods'],
    ingredients: ['water', 'chicken', 'salt', 'vegetables'],
  }))
  assertEquals(result.requiresHalalCert, true)
  assertEquals(result.isHalal, false)
  assertEquals(result.isUnknown, false)
})

Deno.test('computeVerdict — chicken in ingredients, generic category, halal cert → no cert flag', async () => {
  const result = await computeVerdict(baseCtx({
    barcode: '9002600768916',
    name: 'Classic Soup',
    rawCategories: ['en:soups'],
    ingredients: ['water', 'chicken', 'salt'],
    labels: ['halal certified'],
  }))
  assertEquals(result.requiresHalalCert, false)
})

Deno.test('computeVerdict — haram category blocks cert and forces not halal', async () => {
  const result = await computeVerdict(baseCtx({
    haramCategory: 'alcoholic beverages',
    name: 'Chicken Beer Bites',
    rawCategories: ['en:chicken'],
    ingredients: ['chicken'],
  }))
  assertEquals(result.isHalal, false)
  assertEquals(result.requiresHalalCert, false)
  assertMatch(result.explanation, /not permissible/i)
})

// ── applyPostAnalysisRules (keyword safety + post rules) ───────────────────

Deno.test('postRules — keyword haram override wins over AI halal snapshot', () => {
  const ctx = baseCtx({ ingredients: ['pork', 'salt'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst)

  assertEquals(snapshot.isHalal, false)
  assertEquals(snapshot.isUnknown, false)
  assertEquals(snapshot.haramIngredients.includes('pork'), true)
  assertMatch(snapshot.explanation, /pork/i)
})

Deno.test('postRules — keyword suspicious override wins over AI halal snapshot', () => {
  const ctx = baseCtx({ ingredients: ['mono- and diglycerides of fatty acids (e471)'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst)

  assertFalse(snapshot.isHalal)
  assertEquals(snapshot.isUnknown, false)
  assertEquals(snapshot.suspiciousIngredients.length > 0, true)
})

Deno.test('postRules — haram category override wins over AI halal snapshot', () => {
  const ctx = baseCtx({ haramCategory: 'beer', ingredients: ['water'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst)

  assertEquals(snapshot.isHalal, false)
  assertMatch(snapshot.explanation, /not permissible: beer/)
})

Deno.test('postRules — Cyrillic label pork skips empty name fallback', () => {
  const ctx = baseCtx({
    ingredients: ['80% частично финомляно свинско месо', 'вода', 'сол'],
    name: 'Свински кюфтета',
    displayLang: 'bg',
  })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  assertEquals(kwFirst.isUnknown, false)
  assertEquals(kwFirst.haram.length > 0, true)

  const { snapshot } = applyPostAnalysisRules({
    isHalal: kwFirst.isHalal,
    isUnknown: kwFirst.isUnknown,
    haramIngredients: kwFirst.haram,
    suspiciousIngredients: kwFirst.suspicious,
    ingredientWarnings: kwFirst.warnings,
    haramLabels: [],
    suspiciousLabels: [],
    labelWarnings: {},
    haramAdditives: [],
    suspiciousAdditives: [],
    additiveWarnings: {},
    explanation: kwFirst.explanation,
  }, ctx, kwFirst)

  assertEquals(snapshot.isUnknown, false)
  assertEquals(snapshot.haramIngredients.length > 0, true)
  assertMatch(snapshot.explanation, /keyword matching/i)
  assertFalse(snapshot.explanation.includes('product name contains a haram indicator'))
  assertFalse(snapshot.explanation.includes('language we cannot analyze'))
})

Deno.test('postRules — name fallback when unknown and name contains haram term', () => {
  const ctx = baseCtx({ ingredients: [], name: 'Premium Pork Crackling' })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules({
    isHalal: false,
    isUnknown: true,
    haramIngredients: [],
    suspiciousIngredients: [],
    ingredientWarnings: {},
    haramLabels: [],
    suspiciousLabels: [],
    labelWarnings: {},
    haramAdditives: [],
    suspiciousAdditives: [],
    additiveWarnings: {},
    explanation: 'No ingredients listed.',
  }, ctx, kwFirst)

  assertEquals(snapshot.isHalal, false)
  assertEquals(snapshot.isUnknown, false)
  assertMatch(snapshot.explanation, /product name contains a haram indicator/i)
  assertEquals(snapshot.haramIngredients.length > 0, true)
})

Deno.test('postRules — suspicious-only AI list forces not halal after cert step', () => {
  const ctx = baseCtx({ ingredients: ['water'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot({
    suspiciousIngredients: ['gelatin'],
    ingredientWarnings: { gelatin: 'source unspecified' },
  }), ctx, kwFirst)

  assertEquals(snapshot.isHalal, false)
})

Deno.test('postRules — halal cert applied before suspicious-only rule', () => {
  const ctx = baseCtx({
    name: 'Beef Mince',
    rawCategories: ['en:beef'],
    ingredients: ['beef'],
  })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot, requiresHalalCert } = applyPostAnalysisRules(aiSaysHalalSnapshot({
    suspiciousIngredients: ['natural flavors'],
  }), ctx, kwFirst)

  assertEquals(requiresHalalCert, true)
  assertEquals(snapshot.isHalal, false)
  assertEquals(snapshot.isUnknown, false)
})

Deno.test('postRules — no override when AI halal matches clean keyword pass', () => {
  const ctx = baseCtx({ ingredients: ['water', 'salt'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst)

  assertEquals(snapshot.isHalal, true)
  assertEquals(snapshot.haramIngredients.length, 0)
})

// ── computeVerdict — vision + mocked AI tiers ─────────────────────────────────

Deno.test('computeVerdict — vision OCR then Gemini text AI on pack photo path', async () => {
  const env = saveTestEnv()
  setAiEnvEnabled()
  try {
    const result = await withMockedFetch((req) => {
      const url = req.url
      if (url.includes('api.anthropic.com')) {
        return claudeTextContent('water, salt')
      }
      if (url.includes('generativelanguage.googleapis.com')) {
        return geminiGenerateText(aiVerdictJson({ isHalal: true, explanation: 'Vision+AI halal.' }))
      }
      return new Response('not found', { status: 404 })
    }, async () =>
      computeVerdict(baseCtx({
        ingredients: [],
        imageIngredientsUrl: 'https://example.com/pack-ingredients.jpg',
      })))

    assertEquals(result.ingredients, ['water', 'salt'])
    assertEquals(result.analyzedByAI, true)
    assertEquals(result.isHalal, true)
    assertEquals(result.isUnknown, false)
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('computeVerdict — vision finds pork, skips Gemini (keyword-haram)', async () => {
  const env = saveTestEnv()
  setAiEnvEnabled()
  let geminiCalls = 0
  try {
    const result = await withMockedFetch((req) => {
      if (req.url.includes('api.anthropic.com')) {
        return claudeTextContent('pork, salt')
      }
      if (req.url.includes('generativelanguage.googleapis.com')) {
        geminiCalls++
        return geminiGenerateText(aiVerdictJson())
      }
      return new Response('not found', { status: 404 })
    }, async () =>
      computeVerdict(baseCtx({
        ingredients: [],
        imageIngredientsUrl: 'https://example.com/pack.jpg',
      })))

    assertEquals(result.isHalal, false)
    assertEquals(result.analyzedByAI, false)
    assertEquals(result.haramIngredients.includes('pork'), true)
    assertEquals(geminiCalls, 0)
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('computeVerdict — 20013066 Cyrillic label + OFF en → label keyword match explanation', async () => {
  const resolved = resolveOffIngredientAnalysis({
    ingredients_lc: 'bg',
    ingredients_text:
      '80% частично финомляно свинско месо, вода, сол',
    ingredients_text_en:
      '80% pork meat is partially minced, water, salt',
    ingredients: [
      { id: 'bg:свинско-месо', text: 'частично финомляно свинско месо' },
      { id: 'en:water', text: 'вода' },
    ],
  })

  const result = await computeVerdict(baseCtx({
    barcode: '20013066',
    name: 'Свински кюфтета',
    ingredients: resolved.display,
    analyzeSources: resolved.sources,
    displayLang: resolved.displayLang,
    analyzeLang: resolved.analyzeLang,
  }))

  assertEquals(result.isHalal, false)
  assertEquals(result.isUnknown, false)
  assertEquals(result.keywordMatchSource?.includes('off_en'), true)
  assertEquals(result.haramIngredients.length > 0, true)
  assertMatch(result.explanation, /keyword matching/i)
  assertMatch(result.explanation, /pork|свинско|not permissible/i)
  assertFalse(result.explanation.includes('product name contains a haram indicator'))
  assertFalse(result.explanation.includes('language we cannot analyze'))
})

// ── label analysis ──────────────────────────────────────────────────────────

Deno.test('computeVerdict — pork in label → haramLabels set, not halal, haramIngredients empty', async () => {
  const result = await computeVerdict(baseCtx({
    ingredients: ['water', 'salt'],
    labels: ['en:pork', 'en:no-artificial-colours'],
  }))
  assertEquals(result.isHalal, false)
  assertEquals(result.isUnknown, false)
  // keywordAnalysis returns the full matched input text, not just the keyword
  assertEquals(result.haramLabels.includes('en:pork'), true)
  assertEquals(result.haramIngredients.length, 0)
})

Deno.test('computeVerdict — alcohol in label, clean ingredients → haramLabels set, haramIngredients empty', async () => {
  const result = await computeVerdict(baseCtx({
    ingredients: ['water', 'sugar', 'citric acid'],
    labels: ['en:contains-alcohol', 'en:vegan'],
  }))
  assertEquals(result.isHalal, false)
  assertEquals(result.haramLabels.length > 0, true)
  assertEquals(result.haramIngredients.length, 0)
})

Deno.test('computeVerdict — label warning prefixed with "Found on label:"', async () => {
  const result = await computeVerdict(baseCtx({
    ingredients: ['water'],
    labels: ['pork'],
  }))
  const warnValue = Object.values(result.labelWarnings)[0] ?? ''
  assertMatch(warnValue, /^Found on label:/i)
  assertMatch(warnValue, /pork/i)
})

Deno.test('computeVerdict — suspicious keyword in label → suspiciousLabels populated', async () => {
  // rennet is in SUSPICIOUS_ENTRIES (not HARAM_ENTRIES), so it goes to suspiciousLabels
  const result = await computeVerdict(baseCtx({
    ingredients: ['water', 'sugar'],
    labels: ['contains rennet'],
  }))
  assertEquals(result.isHalal, false)
  assertEquals(result.suspiciousLabels.includes('contains rennet'), true)
  assertEquals(result.haramLabels.length, 0)
})

Deno.test('computeVerdict — haram label + animal product → requiresHalalCert false (label exempts cert)', async () => {
  // Clean ingredients (chicken, salt — no keyword haram) but pork label.
  // Without the label, this would trigger requiresHalalCert. The haram label should exempt it.
  const result = await computeVerdict(baseCtx({
    name: 'Mixed Meat',
    rawCategories: ['en:chicken'],
    ingredients: ['chicken', 'salt'],
    labels: ['en:pork'],
  }))
  assertEquals(result.requiresHalalCert, false)
  assertEquals(result.isHalal, false)
  assertEquals(result.haramLabels.includes('en:pork'), true)
  assertEquals(result.haramIngredients.length, 0)
})

Deno.test('computeVerdict — haram label skips AI (pork label short-circuits AI)', async () => {
  const env = saveTestEnv()
  setAiEnvEnabled()
  let geminiCalls = 0
  try {
    const result = await withMockedFetch((req) => {
      if (req.url.includes('generativelanguage.googleapis.com')) {
        geminiCalls++
        return geminiGenerateText(aiVerdictJson({ isHalal: true }))
      }
      return new Response('not found', { status: 404 })
    }, async () =>
      computeVerdict(baseCtx({
        ingredients: ['water', 'sugar'],
        labels: ['en:pork'],
      })))

    assertEquals(result.isHalal, false)
    assertEquals(result.analyzedByAI, false)
    assertEquals(result.haramLabels.includes('en:pork'), true)
    assertEquals(geminiCalls, 0)
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('computeVerdict — suspicious label preserved through AI step', async () => {
  const env = saveTestEnv()
  setAiEnvEnabled()
  try {
    // rennet is suspicious (not haram) — so shouldSkipTextAi does not fire,
    // AI runs and says halal, but the suspicious label must survive the snapshot swap.
    const result = await withMockedFetch((req) => {
      if (req.url.includes('generativelanguage.googleapis.com')) {
        return geminiGenerateText(aiVerdictJson({ isHalal: true }))
      }
      return new Response('not found', { status: 404 })
    }, async () =>
      computeVerdict(baseCtx({
        ingredients: ['water', 'sugar'],
        labels: ['contains rennet'],
      })))

    assertEquals(result.suspiciousLabels.includes('contains rennet'), true)
    assertEquals(result.isHalal, false)
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('computeVerdict — clean labels → haramLabels and suspiciousLabels empty', async () => {
  const result = await computeVerdict(baseCtx({
    ingredients: ['water', 'salt'],
    labels: ['en:vegan', 'en:no-artificial-colours', 'en:organic'],
  }))
  assertEquals(result.haramLabels.length, 0)
  assertEquals(result.suspiciousLabels.length, 0)
})

Deno.test('computeVerdict — Aroma + en:vegan → not halal, vegan explanation, alcohol unclear', async () => {
  const result = await computeVerdict(baseCtx({
    barcode: '9100000976259',
    name: 'Chocolate Chip Cookies',
    ingredients: ['Weizenmehl', 'Zucker', 'Aroma'],
    labels: ['en:vegan'],
  }))
  assertEquals(result.isHalal, false)
  assertEquals(result.suspiciousIngredients, ['Aroma'])
  assertEquals(result.haramIngredients.length, 0)
  assertMatch(result.explanation, /vegan-certified/i)
  assertMatch(result.explanation, /non-animal per certification/i)
  assertMatch(result.explanation, /alcohol content cannot be ruled out/i)
  assertMatch(result.ingredientWarnings['Aroma'] ?? '', /Vegan-certified/i)
  assertMatch(result.ingredientWarnings['Aroma'] ?? '', /alcohol used in extraction/i)
})

Deno.test('computeVerdict — Aroma + vegetarian only → still animal-derived wording', async () => {
  const result = await computeVerdict(baseCtx({
    ingredients: ['flour', 'Aroma'],
    labels: ['en:vegetarian'],
  }))
  assertEquals(result.isHalal, false)
  assertMatch(result.explanation, /animal-derived or extracted with alcohol/i)
  assertEquals(result.explanation.includes('vegan-certified'), false)
})

Deno.test('computeVerdict — vegan + Aroma + glycerol → split flavouring vs other suspicious', async () => {
  const result = await computeVerdict(baseCtx({
    ingredients: ['sugar', 'Aroma', 'glycerol'],
    labels: ['en:vegan'],
  }))
  assertEquals(result.isHalal, false)
  assertEquals(result.suspiciousIngredients.includes('Aroma'), true)
  assertEquals(result.suspiciousIngredients.includes('glycerol'), true)
  assertMatch(result.explanation, /non-animal per certification/i)
  assertMatch(result.explanation, /alcohol content cannot be ruled out/i)
  assertMatch(result.explanation, /may still be animal-derived: glycerol/i)
})

// ── postRules — label analysis ───────────────────────────────────────────────

Deno.test('postRules — label haram override wins over AI halal snapshot', () => {
  const ctx = baseCtx({ ingredients: ['water'], labels: ['en:pork'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst, kwLabels)

  assertEquals(snapshot.isHalal, false)
  assertEquals(snapshot.isUnknown, false)
  assertEquals(snapshot.haramLabels.includes('en:pork'), true)
})

Deno.test('postRules — label haram explanation used when no ingredient haram', () => {
  const ctx = baseCtx({ ingredients: ['water'], labels: ['pork'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst, kwLabels)

  assertMatch(snapshot.explanation, /label/i)
  assertMatch(snapshot.explanation, /pork/i)
})

Deno.test('postRules — label haram appends label note to ingredient explanation when both haram', () => {
  const ctx = baseCtx({ ingredients: ['pork', 'salt'], labels: ['en:pork'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst, kwLabels)

  assertEquals(snapshot.isHalal, false)
  assertEquals(snapshot.haramIngredients.includes('pork'), true)
  assertEquals(snapshot.haramLabels.includes('en:pork'), true)
  // Starts with ingredient explanation, then appends label note
  assertMatch(snapshot.explanation, /keyword matching|not permissible/i)
  assertMatch(snapshot.explanation, /label also indicates/i)
  assertMatch(snapshot.explanation, /en:pork/i)
})

Deno.test('postRules — label suspicious override forces not halal when snapshot isHalal', () => {
  // rennet is in SUSPICIOUS_ENTRIES; 'contains rennet' label matches via substring
  const ctx = baseCtx({ ingredients: ['water'], labels: ['contains rennet'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst, kwLabels)

  assertEquals(snapshot.isHalal, false)
  assertEquals(snapshot.suspiciousLabels.includes('contains rennet'), true)
  assertEquals(snapshot.haramLabels.length, 0)
})

Deno.test('postRules — label suspicious + haram both captured when labels contain both types', () => {
  const ctx = baseCtx({ ingredients: ['water'], labels: ['pork', 'contains rennet'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst, kwLabels)

  // haram override fires first → sets explanation to label-haram text
  // suspicious override appends its own note to that explanation
  assertEquals(snapshot.haramLabels.includes('pork'), true)
  assertEquals(snapshot.suspiciousLabels.includes('contains rennet'), true)
  assertMatch(snapshot.explanation, /pork/i)
  assertMatch(snapshot.explanation, /rennet/i)
})

Deno.test('postRules — label suspicious sets explanation when no ingredient flags', () => {
  const ctx = baseCtx({ ingredients: ['water'], labels: ['contains rennet'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst, kwLabels)

  assertMatch(snapshot.explanation, /label/i)
  assertMatch(snapshot.explanation, /rennet/i)
})

Deno.test('postRules — label suspicious defers to existing explanation when AI set suspicious ingredients', () => {
  // ingredients have no keyword hits, but AI already flagged gelatin as suspicious
  const ctx = baseCtx({ ingredients: ['water'], labels: ['contains rennet'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const snapshotWithAiIngredients = aiSaysHalalSnapshot({
    suspiciousIngredients: ['gelatin'],
    ingredientWarnings: { gelatin: 'May be animal-derived' },
    explanation: 'Gelatin found.',
  })
  const { snapshot } = applyPostAnalysisRules(snapshotWithAiIngredients, ctx, kwFirst, kwLabels)

  // isHalal stays true after kwFirst (no hits) so label override fires,
  // but defers to the existing ingredient-based explanation
  assertMatch(snapshot.explanation, /Gelatin/i)
})

Deno.test('postRules — label suspicious merges labels even when snapshot already not halal', () => {
  const ctx = baseCtx({ ingredients: ['pork'], labels: ['contains rennet'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const notHalalSnapshot = aiSaysHalalSnapshot({ isHalal: false, isUnknown: false, explanation: 'Pork found.' })
  const { snapshot } = applyPostAnalysisRules(notHalalSnapshot, ctx, kwFirst, kwLabels)

  // suspicious labels are captured and a note is appended to the existing explanation
  assertEquals(snapshot.suspiciousLabels.includes('contains rennet'), true)
  assertEquals(snapshot.isHalal, false)
  assertMatch(snapshot.explanation, /Pork/i)
  assertMatch(snapshot.explanation, /animal-derived.*rennet/i)
})

Deno.test('postRules — haramLabels exempts requiresHalalCert (animal product + haram label)', () => {
  const ctx = baseCtx({
    name: 'Chicken Pork Mix',
    rawCategories: ['en:chicken'],
    ingredients: ['chicken'],
    labels: ['en:pork'],
  })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const { snapshot, requiresHalalCert } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst, kwLabels)

  assertEquals(requiresHalalCert, false)
  assertEquals(snapshot.isHalal, false)
  assertEquals(snapshot.haramLabels.includes('en:pork'), true)
})

Deno.test('postRules — label warnings carry "Found on label:" prefix', () => {
  const ctx = baseCtx({ ingredients: ['water'], labels: ['pork'] })
  const kwFirst = keywordAnalysis(ctx.ingredients, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  // Simulate the prefix added in createInitialState
  const kwLabelsWithPrefix = {
    ...kwLabels,
    warnings: Object.fromEntries(
      Object.entries(kwLabels.warnings).map(([k, v]) => [k, `Found on label: ${v}`]),
    ),
  }
  const { snapshot } = applyPostAnalysisRules(aiSaysHalalSnapshot(), ctx, kwFirst, kwLabelsWithPrefix)

  const warnValue = snapshot.labelWarnings['pork'] ?? ''
  assertMatch(warnValue, /^Found on label:/i)
})
