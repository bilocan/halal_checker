// Run with: deno test --allow-net supabase/functions/lookup-product/fetch_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  extractIngredientsText,
  fetchOpenFactsProduct,
  OFF_BASE,
  OBF_BASE,
  optImg,
  parseOffBrand,
  parseOffIngredientList,
  parseOffLabels,
  parseOffProductName,
} from './fetch.ts'
import { offApiProduct, withMockedFetch } from './lookup_test_helpers.ts'

Deno.test('extractIngredientsText — prefers ingredients_text', () => {
  const text = extractIngredientsText({ ingredients_text: 'Water, Salt' })
  assertEquals(text, 'water, salt')
})

Deno.test('extractIngredientsText — falls back to localized field', () => {
  const text = extractIngredientsText({ ingredients_text_de: 'Wasser, Salz' })
  assertEquals(text, 'wasser, salz')
})

Deno.test('extractIngredientsText — structured ingredients array', () => {
  const text = extractIngredientsText({
    ingredients: [{ text: 'Sugar' }, { text: 'Cocoa' }],
  })
  assertEquals(text, 'sugar, cocoa')
})

Deno.test('parseOffIngredientList — splits comma list', () => {
  assertEquals(
    parseOffIngredientList({ ingredients_text: 'water, salt, sugar' }),
    ['water', 'salt', 'sugar'],
  )
})

Deno.test('parseOffProductName — falls back to Unknown Product', () => {
  assertEquals(parseOffProductName({}), 'Unknown Product')
  assertEquals(parseOffProductName({ product_name_en: '  Cola  ' }), 'Cola')
})

Deno.test('parseOffBrand — first brand from comma list', () => {
  assertEquals(parseOffBrand({ brands: 'Acme, Other' }), 'Acme')
  assertEquals(parseOffBrand({}), '')
})

Deno.test('parseOffLabels — merges and normalizes label fields', () => {
  const labels = parseOffLabels({
    labels: 'Halal, Organic',
    labels_tags: ['en:vegan'],
  })
  assertEquals(labels.includes('halal'), true)
  assertEquals(labels.includes('organic'), true)
  assertEquals(labels.includes('en:vegan'), true)
})

Deno.test('optImg — upgrades thumbnail resolution', () => {
  assertEquals(
    optImg('https://images.openfoodfacts.org/images/products/1/2/3/front_en.100.jpg'),
    'https://images.openfoodfacts.org/images/products/1/2/3/front_en.400.jpg',
  )
  assertEquals(optImg(undefined), null)
})

// ── fetchOpenFactsProduct (mocked HTTP) ───────────────────────────────────────

Deno.test('fetchOpenFactsProduct — OFF hit with ingredients', async () => {
  await withMockedFetch((req) => {
    if (req.url.startsWith(OFF_BASE)) {
      return offApiProduct({ ingredients_text: 'water, salt' })
    }
    return offApiProduct(null)
  }, async () => {
    const result = await fetchOpenFactsProduct('1234567890')
    assertEquals(result !== null, true)
    assertEquals(result!.isNonFood, false)
    assertEquals(extractIngredientsText(result!.pd), 'water, salt')
  })
})

Deno.test('fetchOpenFactsProduct — falls back to OBF when OFF misses', async () => {
  await withMockedFetch((req) => {
    if (req.url.startsWith(OFF_BASE)) return offApiProduct(null)
    if (req.url.startsWith(OBF_BASE)) {
      return offApiProduct({ ingredients_text: 'aqua, glycerin' })
    }
    return offApiProduct(null)
  }, async () => {
    const result = await fetchOpenFactsProduct('1234567890')
    assertEquals(result !== null, true)
    assertEquals(result!.isNonFood, true)
    assertEquals(parseOffIngredientList(result!.pd), ['aqua', 'glycerin'])
  })
})

Deno.test('fetchOpenFactsProduct — OFF stub without text refetches OBF', async () => {
  await withMockedFetch((req) => {
    if (req.url.startsWith(OFF_BASE)) {
      return offApiProduct({ product_name: 'Mystery Food' })
    }
    if (req.url.startsWith(OBF_BASE)) {
      return offApiProduct({ ingredients_text: 'water, glycerin' })
    }
    return offApiProduct(null)
  }, async () => {
    const result = await fetchOpenFactsProduct('1234567890')
    assertEquals(result !== null, true)
    assertEquals(result!.isNonFood, true)
    assertEquals(extractIngredientsText(result!.pd), 'water, glycerin')
  })
})
