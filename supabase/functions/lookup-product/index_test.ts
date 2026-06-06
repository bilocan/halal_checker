// Deno unit tests for lookup-product gates, community, and keyword regressions.
// Run with: deno test supabase/functions/lookup-product/index_test.ts

import { assertEquals, assertMatch } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { withCommunitySource } from './community.ts'
import { toProduct } from './db.ts'
import {
  isGeminiLookupEmptyOffDbEnabled,
  isGeminiLookupEmptyOffEnvEnabled,
  shouldBypassCacheForGeminiAutoLookup,
  shouldRunGeminiIngredientLookup,
  normalizeProductNameForGeminiKey,
  isGeminiWebIngredientLookupDoneForProductName,
} from './ingredient_lookup_gate.ts'
import { keywordAnalysis } from './keyword.ts'

// deno-lint-ignore no-explicit-any
function makeRow(overrides: Record<string, any> = {}) {
  return {
    barcode: '1234567890',
    name: 'Test Product',
    ingredients: ['water', 'salt'],
    is_halal: true,
    is_unknown: false,
    is_non_food: false,
    haram_ingredients: [],
    suspicious_ingredients: [],
    ingredient_warnings: {},
    labels: [],
    image_url: null,
    image_front_url: null,
    image_ingredients_url: null,
    image_nutrition_url: null,
    explanation: 'No haram detected.',
    analyzed_by_ai: false,
    ...overrides,
  }
}

// ── tests: toProduct / analysisMethod ────────────────────────────────────────

Deno.test('toProduct — analyzed_by_ai:false → analysisMethod:keyword', () => {
  const p = toProduct(makeRow({ analyzed_by_ai: false }))
  assertEquals(p.analysisMethod, 'keyword')
  assertEquals(p.analyzedByAI, false)
})

Deno.test('toProduct — analyzed_by_ai:true → analysisMethod:ai', () => {
  const p = toProduct(makeRow({ analyzed_by_ai: true }))
  assertEquals(p.analysisMethod, 'ai')
  assertEquals(p.analyzedByAI, true)
})

Deno.test('toProduct — analysisMethod is always ai or keyword (never undefined)', () => {
  const p = toProduct(makeRow())
  assertEquals(typeof p.analysisMethod, 'string')
  assertEquals(['ai', 'keyword'].includes(p.analysisMethod), true)
})

Deno.test('toProduct — geminiWebIngredientLookupAttemptedForName when name matches key', () => {
  const p = toProduct(makeRow({
    gemini_web_ingredient_lookup_at: '2026-01-01T00:00:00Z',
    gemini_web_ingredient_lookup_name_key: 'test product',
    name: 'Test Product',
  }))
  assertEquals(p.geminiWebIngredientLookupAttemptedForName, true)
})

// ── tests: server-side error logging ─────────────────────────────────────────

Deno.test('console.error is called when AI JSON parse fails', () => {
  const logged: string[] = []
  const original = console.error
  console.error = (...args: unknown[]) => { logged.push(args.map(String).join(' ')) }

  try {
    try {
      JSON.parse('not-valid-json')
    } catch (e) {
      console.error('[lookup-product] Gemini JSON parse failed:', e)
    }
    assertEquals(logged.length, 1)
    assertMatch(logged[0], /Gemini JSON parse failed/)
  } finally {
    console.error = original
  }
})

Deno.test('console.error is called when Claude JSON parse fails', () => {
  const logged: string[] = []
  const original = console.error
  console.error = (...args: unknown[]) => { logged.push(args.map(String).join(' ')) }

  try {
    try {
      JSON.parse('{bad json}')
    } catch (e) {
      console.error('[lookup-product] Claude JSON parse failed:', e)
    }
    assertEquals(logged.length, 1)
    assertMatch(logged[0], /Claude JSON parse failed/)
  } finally {
    console.error = original
  }
})

// ── tests: keywordAnalysis (production keyword.ts) ───────────────────────────

Deno.test('keywordAnalysis — clean ingredients → isHalal true', () => {
  const r = keywordAnalysis(['water', 'salt', 'sugar'])
  assertEquals(r.isHalal, true)
  assertEquals(r.haram.length, 0)
})

Deno.test('keywordAnalysis — pork → isHalal false', () => {
  const r = keywordAnalysis(['pork', 'salt'])
  assertEquals(r.isHalal, false)
  assertEquals(r.haram, ['pork'])
})

Deno.test('keywordAnalysis — e471 → isHalal false, suspicious populated', () => {
  const r = keywordAnalysis(['flour', 'e471', 'salt'])
  assertEquals(r.isHalal, false)
  assertEquals(r.suspicious.length, 1)
  assertEquals(r.haram.length, 0)
})

Deno.test('keywordAnalysis — empty list → isUnknown true', () => {
  const r = keywordAnalysis([])
  assertEquals(r.isUnknown, true)
  assertEquals(r.isHalal, false)
})

Deno.test('keywordAnalysis — cetyl alcohol not flagged as haram', () => {
  const r = keywordAnalysis(['cetyl alcohol'])
  assertEquals(r.haram.length, 0)
})

Deno.test('keywordAnalysis — alcohol-free not flagged as haram', () => {
  const r = keywordAnalysis(['malt (alcohol-free)'])
  assertEquals(r.haram.length, 0)
})

Deno.test('keywordAnalysis — 0% alcohol declaration not flagged as haram', () => {
  const r = keywordAnalysis(['sugar', '0% alcohol'])
  assertEquals(r.haram.length, 0)
  assertEquals(r.isHalal, true)
})

Deno.test('negation — DE keine: enthält keine zutaten vom schwein → halal', () => {
  const r = keywordAnalysis(['enthält keine zutaten vom schwein'])
  assertEquals(r.isHalal, true)
  assertEquals(r.haram.length, 0)
})

Deno.test('negation — EN no: contains no pork → halal', () => {
  const r = keywordAnalysis(['contains no pork'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — EN free of: pork free of → halal', () => {
  const r = keywordAnalysis(['free of pork'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — FR sans: sans porc → halal', () => {
  const r = keywordAnalysis(['sans porc'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — IT senza: senza gelatina → halal', () => {
  const r = keywordAnalysis(['senza gelatina'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — ES sin: sin alcohol → halal', () => {
  const r = keywordAnalysis(['sin alcohol'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — TR içermez: içermez pork → halal', () => {
  const r = keywordAnalysis(['içermez pork'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — TR yoktur: domuz yağı ve katkıları yoktur → halal', () => {
  const r = keywordAnalysis(['domuz yağı ve katkıları yoktur'])
  assertEquals(r.isHalal, true)
  assertEquals(r.haram.length, 0)
})

Deno.test('negation — TR ASCII icermez: domuz icermez → halal', () => {
  const r = keywordAnalysis(['domuz icermez'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — EN trailing free: pork free → halal', () => {
  const r = keywordAnalysis(['pork free'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — DE compound frei: schweinefrei → halal', () => {
  const r = keywordAnalysis(['schweinefrei'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — HU nem: nem tartalmaz schwein → halal', () => {
  const r = keywordAnalysis(['nem tartalmaz schwein'])
  assertEquals(r.isHalal, true)
})

Deno.test('negation — actual pork still flagged', () => {
  const r = keywordAnalysis(['pork fat', 'salt'])
  assertEquals(r.isHalal, false)
  assertEquals(r.haram, ['pork fat'])
})

// Shared negation fixture — keep in sync with test/fixtures/negation_cases.json
const negationCasesPath = new URL('../../../test/fixtures/negation_cases.json', import.meta.url)
const negationCases: Array<{
  description: string
  ingredients: string[]
  verdict: string
  matched_canonicals?: string[]
}> = JSON.parse(await Deno.readTextFile(negationCasesPath))

function verdictFromKeywordResult(r: ReturnType<typeof keywordAnalysis>): string {
  if (r.haram.length > 0) return 'haram'
  if (r.suspicious.length > 0) return 'suspicious'
  return 'halal'
}

for (const c of negationCases) {
  Deno.test(`negation fixture — ${c.description}`, () => {
    const r = keywordAnalysis(c.ingredients)
    assertEquals(verdictFromKeywordResult(r), c.verdict)
    if (c.verdict === 'halal') {
      assertEquals(r.isHalal, true)
      assertEquals(r.haram.length, 0)
      assertEquals(r.suspicious.length, 0)
    }
  })
}

Deno.test('unicode boundary — lactosérum does not false-positive on "rum"', () => {
  const r = keywordAnalysis(['poudre de lactosérum (lait)'])
  assertEquals(r.haram.length, 0)
})

Deno.test('unicode boundary — standalone rum is still haram', () => {
  const r = keywordAnalysis(['rum', 'sugar'])
  assertEquals(r.isHalal, false)
})

Deno.test('keywordAnalysis — mikrobielles Lab not suspicious (rennet safelist)', () => {
  const r = keywordAnalysis(['Milch', 'mikrobielles Lab', 'Salz'])
  assertEquals(r.isHalal, true)
  assertEquals(r.suspicious.length, 0)
})

Deno.test('keywordAnalysis — bare Lab stays suspicious', () => {
  const r = keywordAnalysis(['Milch', 'Lab', 'Salz'])
  assertEquals(r.isHalal, false)
  assertEquals(r.suspicious.includes('Lab'), true)
})

// ── community ingredient source ───────────────────────────────────────────────

Deno.test('withCommunitySource — overrides OFF source when approved list exists', () => {
  const row = {
    barcode: '8690766143732',
    ingredient_source: 'off',
    ingredients: ['off ingredient a', 'off ingredient b'],
  }
  const enriched = withCommunitySource(row, ['community sugar', 'community cocoa'])
  assertEquals(enriched.ingredient_source, 'community')
  assertEquals(enriched.ingredients, ['community sugar', 'community cocoa'])
})

Deno.test('withCommunitySource — leaves row unchanged when no approved list', () => {
  const row = { barcode: '123', ingredient_source: 'off', ingredients: ['water'] }
  assertEquals(withCommunitySource(row, null), row)
})

// ── Gemini ingredient lookup gate ───────────────────────────────────────────

Deno.test('shouldRunGeminiIngredientLookup — runs when approved + fetchAiIngredients', () => {
  assertEquals(
    shouldRunGeminiIngredientLookup({
      autoLookupEmptyOff: false,
      fetchAiIngredients: true,
      hasApprovedRequest: true,
      offIngredientCount: 0,
      productName: 'Cola Zero',
    }),
    true,
  )
  assertEquals(
    shouldRunGeminiIngredientLookup({
      autoLookupEmptyOff: false,
      fetchAiIngredients: false,
      hasApprovedRequest: true,
      offIngredientCount: 0,
      productName: 'Cola Zero',
    }),
    false,
  )
  assertEquals(
    shouldRunGeminiIngredientLookup({
      autoLookupEmptyOff: false,
      fetchAiIngredients: true,
      hasApprovedRequest: false,
      offIngredientCount: 0,
      productName: 'Cola Zero',
    }),
    false,
  )
})

Deno.test('shouldRunGeminiIngredientLookup — runs when GEMINI_LOOKUP_EMPTY_OFF (no app flag)', () => {
  assertEquals(
    shouldRunGeminiIngredientLookup({
      autoLookupEmptyOff: true,
      fetchAiIngredients: false,
      hasApprovedRequest: false,
      offIngredientCount: 0,
      productName: 'Cola Zero',
    }),
    true,
  )
  assertEquals(isGeminiLookupEmptyOffEnvEnabled('true'), true)
  assertEquals(isGeminiLookupEmptyOffEnvEnabled('false'), false)
  assertEquals(isGeminiLookupEmptyOffDbEnabled('true'), true)
  assertEquals(isGeminiLookupEmptyOffDbEnabled('false'), false)
})

Deno.test('shouldBypassCacheForGeminiAutoLookup — refetch when cached OFF row is empty', () => {
  assertEquals(
    shouldBypassCacheForGeminiAutoLookup(
      { ingredients: [], ingredient_source: 'off' },
      { autoLookupEmptyOff: true, fetchAiIngredients: false, force: false },
    ),
    true,
  )
  assertEquals(
    shouldBypassCacheForGeminiAutoLookup(
      { ingredients: [], ingredient_source: 'ai' },
      { autoLookupEmptyOff: true, fetchAiIngredients: false, force: false },
    ),
    false,
  )
})

Deno.test('shouldRunGeminiIngredientLookup — skips when OFF already has ingredients', () => {
  assertEquals(
    shouldRunGeminiIngredientLookup({
      autoLookupEmptyOff: true,
      fetchAiIngredients: true,
      hasApprovedRequest: true,
      offIngredientCount: 2,
      productName: 'Cola Zero',
    }),
    false,
  )
})

Deno.test('shouldRunGeminiIngredientLookup — skips unknown product name', () => {
  assertEquals(
    shouldRunGeminiIngredientLookup({
      autoLookupEmptyOff: true,
      fetchAiIngredients: true,
      hasApprovedRequest: true,
      offIngredientCount: 0,
      productName: 'Unknown Product',
    }),
    false,
  )
})

Deno.test('normalizeProductNameForGeminiKey — trims and collapses whitespace', () => {
  assertEquals(normalizeProductNameForGeminiKey('  Foo   Bar  '), 'foo bar')
  assertEquals(normalizeProductNameForGeminiKey('CAFÉ'), 'café')
})

Deno.test('isGeminiWebIngredientLookupDoneForProductName — matches normalized name', () => {
  assertEquals(
    isGeminiWebIngredientLookupDoneForProductName(
      {
        gemini_web_ingredient_lookup_at: '2026-01-01T00:00:00Z',
        gemini_web_ingredient_lookup_name_key: 'cola zero',
      },
      '  Cola   Zero  ',
    ),
    true,
  )
  assertEquals(
    isGeminiWebIngredientLookupDoneForProductName(
      {
        gemini_web_ingredient_lookup_at: '2026-01-01T00:00:00Z',
        gemini_web_ingredient_lookup_name_key: 'cola zero',
      },
      'Cola Light',
    ),
    false,
  )
  assertEquals(
    isGeminiWebIngredientLookupDoneForProductName(null, 'Cola Zero'),
    false,
  )
})
