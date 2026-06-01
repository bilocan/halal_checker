// Run with: deno test --allow-env supabase/functions/lookup-product/persistence_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { persistLookupAndRespond, type AnalysisRow, type ProductRow } from './persistence.ts'
import { mockSupabase } from './lookup_test_helpers.ts'

const cors = { 'Access-Control-Allow-Origin': '*' }

const productRow: ProductRow = {
  barcode: '999888777',
  name: 'Fallback Name',
  ingredients: ['salt'],
  ingredientSource: 'off',
  isNonFood: false,
  labels: [],
  imageUrl: null,
  imageFrontUrl: null,
  imageIngredientsUrl: null,
  imageNutritionUrl: null,
  requiresHalalCert: false,
  fetchedAt: '2026-05-01T00:00:00Z',
}

const analysisRow: AnalysisRow = {
  barcode: '999888777',
  isHalal: false,
  isUnknown: true,
  isNonFood: false,
  haramIngredients: [],
  suspiciousIngredients: [],
  ingredientWarnings: {},
  haramLabels: [],
  suspiciousLabels: [],
  labelWarnings: {},
  haramAdditives: [],
  suspiciousAdditives: [],
  additiveWarnings: {},
  explanation: 'Fallback explanation.',
  analyzedByAI: false,
}

const fallbackRow = {
  barcode: '999888777',
  name: 'Fallback Name',
  ingredients: ['salt'],
  ingredient_source: 'off',
  is_halal: false,
  is_unknown: true,
  is_non_food: false,
  haram_ingredients: [],
  suspicious_ingredients: [],
  ingredient_warnings: {},
  labels: [],
  explanation: 'Fallback explanation.',
  analyzed_by_ai: false,
  requires_halal_cert: false,
}

Deno.test('persistLookupAndRespond — prefers products_full row over fallback', async () => {
  const savedFromView = {
    ...fallbackRow,
    name: 'Saved From View',
    is_halal: true,
    is_unknown: false,
    analyzed_by_ai: true,
    explanation: 'From products_full.',
    gemini_web_ingredient_lookup_at: '2026-06-01T00:00:00Z',
    gemini_web_ingredient_lookup_name_key: 'saved from view',
  }

  const supabase = mockSupabase({ productsFullRow: savedFromView })
  const res = await persistLookupAndRespond(
    supabase,
    cors,
    productRow,
    analysisRow,
    fallbackRow,
  )

  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.product.name, 'Saved From View')
  assertEquals(body.product.isHalal, true)
  assertEquals(body.product.analysisMethod, 'ai')
  assertEquals(body.product.geminiWebIngredientLookupAttemptedForName, true)
})

Deno.test('persistLookupAndRespond — uses fallback when products_full returns null', async () => {
  const supabase = mockSupabase({ productsFullRow: null })
  const res = await persistLookupAndRespond(
    supabase,
    cors,
    productRow,
    analysisRow,
    fallbackRow,
  )

  const body = await res.json()
  assertEquals(body.product.name, 'Fallback Name')
  assertEquals(body.product.analysisMethod, 'keyword')
  assertEquals(body.product.isUnknown, true)
})
