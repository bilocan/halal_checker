// Run with: deno test supabase/functions/lookup-product/fetch_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  extractIngredientsText,
  optImg,
  parseOffBrand,
  parseOffIngredientList,
  parseOffLabels,
  parseOffProductName,
} from './fetch.ts'

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
