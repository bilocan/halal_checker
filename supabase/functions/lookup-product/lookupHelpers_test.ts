// Run with: deno test supabase/functions/lookup-product/lookupHelpers_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { classifyOffCategories, normalizeStoredLabels } from './lookupHelpers.ts'

Deno.test('normalizeStoredLabels — trims, lowercases, drops empties', () => {
  assertEquals(
    normalizeStoredLabels([' Halal ', '', '  ', 'Organic']),
    ['halal', 'organic'],
  )
  assertEquals(normalizeStoredLabels(null), [])
  assertEquals(normalizeStoredLabels('not-array'), [])
})

Deno.test('classifyOffCategories — detects non-food from OFF tags', () => {
  const r = classifyOffCategories(['en:cosmetics'], false)
  assertEquals(r.isNonFood, true)
  assertEquals(r.haramCategory, null)
  assertEquals(r.isHalalByCategory, false)
})

Deno.test('classifyOffCategories — haram category when not non-food', () => {
  const r = classifyOffCategories(['en:beers', 'en:other'], false)
  assertEquals(r.isNonFood, false)
  assertEquals(r.haramCategory, 'en:beers')
  assertEquals(r.isHalalByCategory, false)
})

Deno.test('classifyOffCategories — halal-by-category when water and no haram', () => {
  const r = classifyOffCategories(['en:waters'], false)
  assertEquals(r.isNonFood, false)
  assertEquals(r.haramCategory, null)
  assertEquals(r.isHalalByCategory, true)
})

Deno.test('classifyOffCategories — preserves isNonFood when already true', () => {
  const r = classifyOffCategories([], true)
  assertEquals(r.isNonFood, true)
  assertEquals(r.haramCategory, null)
})
