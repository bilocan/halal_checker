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
