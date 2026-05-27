// Run with: deno test --allow-env supabase/functions/lookup-product/handler_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { createLookupDeps, handleLookup, handleLookupRequest } from './handler.ts'
import { mockHandlerSupabase } from './lookup_test_helpers.ts'

function cachedProduct(overrides: Record<string, unknown> = {}) {
  return {
    barcode: '1234567890',
    name: 'Cached Mineral Water',
    ingredients: ['water'],
    ingredient_source: 'off',
    is_halal: true,
    is_unknown: false,
    is_non_food: false,
    haram_ingredients: [],
    suspicious_ingredients: [],
    ingredient_warnings: {},
    labels: [],
    explanation: 'Cached.',
    analyzed_by_ai: false,
    requires_halal_cert: false,
    is_managed: false,
    updated_at: '2026-05-01T00:00:00Z',
    last_analysed_at: '2026-05-02T00:00:00Z',
    fetched_at: '2026-05-01T00:00:00Z',
    ...overrides,
  }
}

Deno.test('handleLookupRequest — invalid body returns 400', async () => {
  const supabase = mockHandlerSupabase()
  const res = await handleLookupRequest(
    new Request('http://local', { method: 'POST', body: JSON.stringify({}) }),
    createLookupDeps(supabase),
  )
  assertEquals(res.status, 400)
  const body = await res.json()
  assertEquals(typeof body.error, 'string')
})

Deno.test('handleLookup — managed product returns row unchanged', async () => {
  const row = cachedProduct({ is_managed: true, name: 'Admin Curated' })
  const supabase = mockHandlerSupabase({ cacheProduct: row })
  const res = await handleLookup(
    { barcode: '1234567890', force: false, fetchAiIngredients: false },
    createLookupDeps(supabase),
  )
  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.product.name, 'Admin Curated')
  assertEquals(body.product.isManaged, true)
})

Deno.test('handleLookup — fresh cache hit without OFF refetch', async () => {
  const row = cachedProduct()
  const supabase = mockHandlerSupabase({ cacheProduct: row })
  const deps = createLookupDeps(supabase)
  deps.fetchOpenFactsProduct = () => {
    throw new Error('fetchOpenFactsProduct should not run on cache hit')
  }

  const res = await handleLookup(
    { barcode: '1234567890', force: false, fetchAiIngredients: false },
    deps,
  )
  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.product.name, 'Cached Mineral Water')
  assertEquals(body.product.analysisMethod, 'keyword')
})

Deno.test('handleLookup — force refresh runs reanalysis (skipAi)', async () => {
  const row = cachedProduct({
    is_unknown: false,
    updated_at: '2026-05-01T00:00:00Z',
    last_analysed_at: '2026-05-02T00:00:00Z',
  })
  const supabase = mockHandlerSupabase({ cacheProduct: row, savedProduct: null })
  const res = await handleLookup(
    { barcode: '1234567890', force: true, fetchAiIngredients: false },
    createLookupDeps(supabase),
  )
  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.product.analyzedByAI, false)
  assertEquals(body.product.analysisMethod, 'keyword')
})

Deno.test('handleLookup — unknown barcode and OFF miss returns null product', async () => {
  const supabase = mockHandlerSupabase({ cacheProduct: null })
  const deps = createLookupDeps(supabase)
  deps.fetchOpenFactsProduct = async () => null

  const res = await handleLookup(
    { barcode: '0000000000000', force: false, fetchAiIngredients: false },
    deps,
  )
  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.product, null)
})

Deno.test('handleLookup — force refetches OFF when cached row is unknown', async () => {
  const row = cachedProduct({
    is_unknown: true,
    is_halal: false,
    ingredients: [],
    explanation: 'stale unknown',
  })
  const supabase = mockHandlerSupabase({
    cacheProduct: row,
    savedProduct: {
      ...row,
      name: 'Mineral Water',
      is_halal: true,
      is_unknown: false,
      explanation: 'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.',
    },
  })
  const deps = createLookupDeps(supabase)
  deps.fetchOpenFactsProduct = async () => ({
    pd: {
      product_name: 'Mineral Water',
      ingredients_text: '',
      categories_tags: ['en:waters', 'en:mineral-waters'],
    },
    isNonFood: false,
  })

  const res = await handleLookup(
    { barcode: '1234567890', force: true, fetchAiIngredients: false },
    deps,
  )
  const body = await res.json()
  assertEquals(body.product.isHalal, true)
  assertEquals(body.product.isUnknown, false)
})

Deno.test('handleLookup — stale row triggers reanalysis', async () => {
  const row = cachedProduct({
    updated_at: '2026-05-03T00:00:00Z',
    last_analysed_at: '2026-05-01T00:00:00Z',
  })
  const supabase = mockHandlerSupabase({ cacheProduct: row })
  const res = await handleLookup(
    { barcode: '1234567890', force: false, fetchAiIngredients: false },
    createLookupDeps(supabase),
  )
  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.product.barcode, '1234567890')
  assertEquals(body.product.analyzedByAI, false)
})
