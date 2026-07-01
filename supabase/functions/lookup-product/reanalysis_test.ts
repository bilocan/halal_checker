// Run with: deno test --allow-env supabase/functions/lookup-product/reanalysis_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { jsonManagedProduct, runStoredProductReanalysis } from './reanalysis.ts'
import { mockSupabase } from './lookup_test_helpers.ts'

const cors = { 'Access-Control-Allow-Origin': '*' }

function storedRow(overrides: Record<string, unknown> = {}) {
  return {
    barcode: '1234567890',
    name: 'Test Product',
    ingredients: ['water', 'salt'],
    ingredient_source: 'off',
    is_halal: true,
    is_unknown: false,
    is_non_food: false,
    haram_ingredients: [],
    suspicious_ingredients: [],
    ingredient_warnings: {},
    labels: [],
    explanation: 'stale',
    analyzed_by_ai: false,
    requires_halal_cert: false,
    is_managed: false,
    fetched_at: '2026-05-01T00:00:00Z',
    ...overrides,
  }
}

Deno.test('jsonManagedProduct — returns cached row unchanged', async () => {
  const row = storedRow({ is_managed: true, is_halal: true })
  const res = jsonManagedProduct(row, cors)
  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.product.isHalal, true)
  assertEquals(body.product.isManaged, true)
  assertEquals(body.product.barcode, '1234567890')
})

Deno.test('runStoredProductReanalysis — skipAi keyword path (no OFF categories on re-run)', async () => {
  const row = storedRow()
  const supabase = mockSupabase({ productsFullRow: null })

  const res = await runStoredProductReanalysis(
    supabase,
    row,
    row.barcode as string,
    [],
    [],
    cors,
  )
  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.product.isHalal, true)
  assertEquals(body.product.analyzedByAI, false)
  assertEquals(body.product.analysisMethod, 'keyword')
  assertEquals(body.product.requiresHalalCert, false)
})

Deno.test('runStoredProductReanalysis — preserves existing explanation when the verdict is unchanged', async () => {
  const row = storedRow({
    ingredients: ['gurken'],
    is_halal: true,
    haram_ingredients: [],
    suspicious_ingredients: [],
    explanation: "The ingredient 'gurken' (cucumbers) is a vegetable and is considered halal. "
      + 'There are no haram or suspicious ingredients present.',
  })
  const supabase = mockSupabase({ productsFullRow: null })

  const res = await runStoredProductReanalysis(supabase, row, row.barcode as string, [], [], cors)
  const body = await res.json()
  assertEquals(body.product.isHalal, true)
  assertEquals(
    body.product.explanation,
    "The ingredient 'gurken' (cucumbers) is a vegetable and is considered halal. "
      + 'There are no haram or suspicious ingredients present.',
  )
})

Deno.test('runStoredProductReanalysis — replaces stale explanation when the verdict actually changes', async () => {
  const row = storedRow({
    ingredients: ['gelatin'],
    is_halal: true,
    haram_ingredients: [],
    suspicious_ingredients: [],
    explanation: 'stale explanation from before gelatin was flagged',
  })
  const supabase = mockSupabase({ productsFullRow: null })

  const res = await runStoredProductReanalysis(supabase, row, row.barcode as string, [], [], cors)
  const body = await res.json()
  assertEquals(body.product.isHalal, false)
  assertEquals(body.product.suspiciousIngredients.includes('gelatin'), true)
  assertEquals(
    body.product.explanation.includes('stale explanation from before gelatin was flagged'),
    false,
  )
})

Deno.test('runStoredProductReanalysis — community ingredients override stored OFF list', async () => {
  const row = storedRow({ ingredients: ['pork'], is_halal: false })
  const fallback = {
    ...row,
    ingredients: ['water', 'salt'],
    ingredient_source: 'community',
    is_halal: true,
    requires_halal_cert: false,
  }
  const supabase = mockSupabase({
    approvedIngredients: ['water', 'salt'],
    productsFullRow: fallback,
  })

  const res = await runStoredProductReanalysis(
    supabase,
    row,
    row.barcode as string,
    [],
    [],
    cors,
  )
  const body = await res.json()
  assertEquals(body.product.ingredients, ['water', 'salt'])
  assertEquals(body.product.isHalal, true)
  assertEquals(body.product.ingredientSource, 'community')
})

Deno.test('runStoredProductReanalysis — pork in stored list stays not halal', async () => {
  const row = storedRow({ ingredients: ['pork', 'salt'], name: 'Pork Snack' })
  const fallback = { ...row, is_halal: false, haram_ingredients: ['pork'] }
  const supabase = mockSupabase({ productsFullRow: fallback })

  const res = await runStoredProductReanalysis(
    supabase,
    row,
    row.barcode as string,
    [],
    [],
    cors,
  )
  const body = await res.json()
  assertEquals(body.product.isHalal, false)
  assertEquals(body.product.haramIngredients.includes('pork'), true)
  assertEquals(body.product.analyzedByAI, false)
})

Deno.test('runStoredProductReanalysis — pork in stored labels → haramLabels populated, not halal', async () => {
  const row = storedRow({
    ingredients: ['water', 'salt'],
    is_halal: true,
    labels: ['en:pork', 'en:no-gluten'],
  })
  const fallback = { ...row, is_halal: false, haram_labels: ['pork'] }
  const supabase = mockSupabase({ productsFullRow: fallback })

  const res = await runStoredProductReanalysis(
    supabase,
    row,
    row.barcode as string,
    [],
    [],
    cors,
  )
  const body = await res.json()
  assertEquals(body.product.isHalal, false)
  assertEquals(body.product.haramLabels.includes('pork'), true)
  assertEquals(body.product.haramIngredients.length, 0)
  assertEquals(body.product.analyzedByAI, false)
})

Deno.test('runStoredProductReanalysis — halal-by-category preserved for mineral water (no ingredients)', async () => {
  const row = storedRow({
    name: 'Mineralwasser prickelnd',
    ingredients: [],
    is_halal: true,
    is_unknown: false,
    categories_tags: ['en:beverages', 'en:waters', 'en:mineral-waters'],
  })
  const fallback = { ...row }
  const supabase = mockSupabase({ productsFullRow: fallback })

  const res = await runStoredProductReanalysis(
    supabase,
    row,
    row.barcode as string,
    [],
    [],
    cors,
  )
  const body = await res.json()
  assertEquals(body.product.isHalal, true)
  assertEquals(body.product.isUnknown, false)
  assertEquals(body.product.analyzedByAI, false)
})

Deno.test('runStoredProductReanalysis — clean labels → haramLabels empty', async () => {
  const row = storedRow({
    ingredients: ['water', 'salt'],
    labels: ['en:vegan', 'en:organic'],
  })
  const supabase = mockSupabase({ productsFullRow: null })

  const res = await runStoredProductReanalysis(
    supabase,
    row,
    row.barcode as string,
    [],
    [],
    cors,
  )
  const body = await res.json()
  assertEquals(body.product.isHalal, true)
  assertEquals(body.product.haramLabels.length, 0)
  assertEquals(body.product.suspiciousLabels.length, 0)
})
