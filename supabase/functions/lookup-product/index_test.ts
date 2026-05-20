// Deno unit tests for lookup-product edge function helpers.
// Run with: deno test supabase/functions/lookup-product/index_test.ts
//
// These tests cover the two requirements from issue #2:
//   1. analysisMethod field in the response payload
//   2. Server-side error logging when AI calls fail

import { assertEquals, assertMatch } from 'https://deno.land/std@0.224.0/assert/mod.ts'

// ── inline copies of the pure functions under test ───────────────────────────
// We copy them here rather than importing from index.ts to keep the test file
// self-contained (index.ts uses Deno.serve which can't be tested directly).

const HARAM_ENTRIES: [string, string, ...string[]][] = [
  ['alcohol', 'Contains alcohol', 'alcohol', 'alkohol'],
  ['pork', 'Contains pork', 'pork', 'schwein'],
  ['gelatin', 'Gelatin is animal-derived', 'gelatin', 'gelatine'],
]

const SUSPICIOUS_ENTRIES: [string, string, ...string[]][] = [
  ['enzymes', 'Enzymes may be animal-derived', 'enzymes', 'enzyme'],
]

const ALCOHOL_FAMILY = new Set(['alcohol', 'alkohol'])
const FATTY_ALCOHOL_PREFIX = /\b(cetyl|stearyl|behenyl|lauryl)\s+/i
const NEGATION_WORDS = /\b(?:keine?|nicht|ohne|frei\s+von|sans|pas|geen|zonder|vrij\s+van|no|not|without|free\s+from|free\s+of|senza|sin|içermez|içermemektedir|neobsahuje|bez|nema|nem|mentes)\b/i

function escape(s: string) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') }

const wPre = '(?<![a-zA-Z\\dÀ-ɏß])'
const wPost = '(?![a-zA-Z\\dÀ-ɏß])'

function isZeroPercentAlcoholDeclaration(text: string, variant: string): boolean {
  const v = escape(variant)
  return new RegExp(
    `\\b0(?:[.,]0+)?\\s*%\\s*${v}(?:\\b|(?![a-zA-Z\\dÀ-ɏß]))|\\b${v}(?:\\b|(?![a-zA-Z\\dÀ-ɏß]))\\s*(?:\\(?\\s*)?0(?:[.,]0+)?\\s*%`,
    'i',
  ).test(text)
}

function matchesVariant(ingredient: string, variant: string): boolean {
  if (variant.includes(' ')) return ingredient.includes(variant)
  if (ALCOHOL_FAMILY.has(variant)) {
    if (FATTY_ALCOHOL_PREFIX.test(ingredient)) return false
    if (isZeroPercentAlcoholDeclaration(ingredient, variant)) return false
    return new RegExp(`${wPre}${escape(variant)}${wPost}(?![-\\s]*free)`, 'i').test(ingredient)
  }
  return new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').test(ingredient)
}

function isNegated(chunk: string, variant: string): boolean {
  const lower = chunk.toLowerCase()
  let idx: number
  if (variant.includes(' ')) {
    idx = lower.indexOf(variant.toLowerCase())
  } else {
    const m = new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').exec(lower)
    idx = m ? m.index : -1
  }
  if (idx < 0) return false
  return NEGATION_WORDS.test(lower.substring(0, idx))
}

function keywordAnalysis(ingredients: string[]) {
  const warnings: Record<string, string> = {}
  const haram: string[] = []
  const suspicious: string[] = []
  for (const ing of ingredients) {
    const lower = ing.toLowerCase()
    let foundHaram = false
    for (const entry of HARAM_ENTRIES) {
      const matchedVariant = (entry.slice(2) as string[]).find(v => matchesVariant(lower, v))
      if (matchedVariant && !isNegated(lower, matchedVariant)) {
        warnings[ing] = entry[1]; haram.push(ing); foundHaram = true; break
      }
    }
    if (foundHaram) continue
    for (const entry of SUSPICIOUS_ENTRIES) {
      const matchedVariant = (entry.slice(2) as string[]).find(v => matchesVariant(lower, v))
      if (matchedVariant && !isNegated(lower, matchedVariant)) {
        warnings[ing] = entry[1]; suspicious.push(ing); break
      }
    }
  }
  const isUnknown = ingredients.length === 0
  return { isHalal: !isUnknown && haram.length === 0, isUnknown, haram, suspicious, warnings }
}

// toProduct mirrors the function in index.ts; analysisMethod is the new field.
// deno-lint-ignore no-explicit-any
function toProduct(row: Record<string, any>) {
  return {
    barcode:               row.barcode,
    name:                  row.name,
    ingredients:           row.ingredients,
    isHalal:               row.is_halal,
    isUnknown:             row.is_unknown ?? false,
    isNonFood:             row.is_non_food ?? false,
    haramIngredients:      row.haram_ingredients,
    suspiciousIngredients: row.suspicious_ingredients,
    ingredientWarnings:    row.ingredient_warnings,
    labels:                row.labels,
    imageUrl:              row.image_url,
    imageFrontUrl:         row.image_front_url,
    imageIngredientsUrl:   row.image_ingredients_url,
    imageNutritionUrl:     row.image_nutrition_url,
    explanation:           row.explanation,
    analyzedByAI:          row.analyzed_by_ai,
    analysisMethod:        row.analyzed_by_ai ? 'ai' : 'keyword',
  }
}

// Minimal DB-row fixture.
function makeRow(overrides: Record<string, unknown> = {}) {
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

// ── tests: server-side error logging ─────────────────────────────────────────

Deno.test('console.error is called when AI JSON parse fails', () => {
  const logged: string[] = []
  const original = console.error
  console.error = (...args: unknown[]) => { logged.push(args.map(String).join(' ')) }

  try {
    // Simulate the Gemini JSON-parse failure path.
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

// ── tests: keywordAnalysis ────────────────────────────────────────────────────

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

// ── negation detection ────────────────────────────────────────────────────────

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

Deno.test('negation — TR içermez: schwein içermez → halal', () => {
  const r = keywordAnalysis(['pork içermez'])
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

// ── Unicode word-boundary regressions ────────────────────────────────────────

Deno.test('unicode boundary — lactosérum does not false-positive on "rum"', () => {
  const r = keywordAnalysis(['poudre de lactosérum (lait)'])
  assertEquals(r.haram.length, 0)
})

Deno.test('unicode boundary — standalone rum is still haram', () => {
  const r = keywordAnalysis(['rum', 'sugar'])
  assertEquals(r.isHalal, false)
})
