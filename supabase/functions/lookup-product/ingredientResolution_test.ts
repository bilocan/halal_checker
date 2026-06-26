// Run with: deno test --allow-env supabase/functions/lookup-product/ingredientResolution_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  isAnalyzableScript,
  resolveOffIngredientAnalysis,
  splitIngredientText,
} from './ingredientResolution.ts'

Deno.test('isAnalyzableScript — Latin text is analyzable', () => {
  assertEquals(isAnalyzableScript('water, pork, salt'), true)
})

Deno.test('isAnalyzableScript — Cyrillic without Latin is not analyzable', () => {
  assertEquals(isAnalyzableScript('частично финомляно свинско месо'), false)
})

Deno.test('isAnalyzableScript — E-numbers make text analyzable', () => {
  assertEquals(isAnalyzableScript('состав: e471, вода'), true)
})

Deno.test('splitIngredientText — splits on commas', () => {
  assertEquals(splitIngredientText('water, salt, sugar'), ['water', 'salt', 'sugar'])
})

Deno.test('splitIngredientText — filters UNKNOWN placeholder', () => {
  assertEquals(splitIngredientText('unknown'), [])
  assertEquals(splitIngredientText('UNKNOWN.'), [])
  assertEquals(splitIngredientText('unknown!'), [])
})

Deno.test('splitIngredientText — keeps UNKNOWN mixed with real ingredients', () => {
  assertEquals(splitIngredientText('water, unknown., sugar'), ['water', 'sugar'])
})

Deno.test('resolveOffIngredientAnalysis — Bulgarian primary + English fallback', () => {
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

  assertEquals(resolved.display.length > 0, true)
  assertEquals(resolved.displayLang, 'bg')
  assertEquals(resolved.analyzeLang, 'en')
  assertEquals(
    resolved.sources.some(s => s.key === 'off_en' && s.ingredients.some(i => i.includes('pork'))),
    true,
  )
  assertEquals(resolved.sources.some(s => s.key === 'off_taxonomy'), true)
  assertEquals(
    resolved.sources.some(
      s => s.key === 'off_taxonomy' && s.ingredients.some(i => i.includes('свинско')),
    ),
    true,
  )
})
