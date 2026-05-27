// Run with: deno test --allow-env supabase/functions/lookup-product/ingredientResolver_test.ts

import { assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { resolveGeminiIngredients } from './ingredientResolver.ts'
import {
  geminiGenerateText,
  restoreTestEnv,
  saveTestEnv,
  setAiEnvEnabled,
  withMockedFetch,
} from './lookup_test_helpers.ts'

const baseInput = {
  barcode: '8690000000001',
  name: 'Cola Zero',
  brand: 'Test Brand',
  ingredients: [] as string[],
  ingredientSource: 'off' as const,
  existing: null,
  geminiAutoEmptyOff: true,
  fetchAiIngredients: false,
  hasApprovedAiRequest: false,
}

Deno.test('resolveGeminiIngredients — skips when gate closed', async () => {
  const env = saveTestEnv()
  let fetchCalls = 0
  try {
    const result = await withMockedFetch(() => {
      fetchCalls++
      return new Response('unexpected')
    }, async () =>
      resolveGeminiIngredients({
        ...baseInput,
        geminiAutoEmptyOff: false,
        fetchAiIngredients: false,
        hasApprovedAiRequest: false,
      }))
    assertEquals(result.ingredients, [])
    assertEquals(result.ingredientSource, 'off')
    assertEquals(fetchCalls, 0)
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('resolveGeminiIngredients — skips when already attempted for name', async () => {
  const env = saveTestEnv()
  setAiEnvEnabled()
  let fetchCalls = 0
  try {
    const result = await withMockedFetch(() => {
      fetchCalls++
      return new Response('unexpected')
    }, async () =>
      resolveGeminiIngredients({
        ...baseInput,
        existing: {
          barcode: baseInput.barcode,
          gemini_web_ingredient_lookup_at: '2026-01-01T00:00:00Z',
          gemini_web_ingredient_lookup_name_key: 'cola zero',
        },
      }))
    assertEquals(result.ingredients, [])
    assertEquals(fetchCalls, 0)
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('resolveGeminiIngredients — skips when GEMINI_API_KEY unset', async () => {
  const env = saveTestEnv()
  Deno.env.delete('GEMINI_API_KEY')
  Deno.env.set('GEMINI_ENABLED', 'true')
  let fetchCalls = 0
  try {
    const result = await withMockedFetch(() => {
      fetchCalls++
      return new Response('unexpected')
    }, async () => resolveGeminiIngredients(baseInput))
    assertEquals(result.ingredients, [])
    assertEquals(fetchCalls, 0)
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('resolveGeminiIngredients — applies AI list and records lookup metadata', async () => {
  const env = saveTestEnv()
  setAiEnvEnabled()
  try {
    const result = await withMockedFetch((req) => {
      assertEquals(req.url.includes('generativelanguage.googleapis.com'), true)
      return geminiGenerateText('water, sugar, citric acid')
    }, async () => resolveGeminiIngredients(baseInput))

    assertEquals(result.ingredients, ['water', 'sugar', 'citric acid'])
    assertEquals(result.ingredientSource, 'ai')
    assertExists(result.geminiAt)
    assertEquals(result.geminiNameKey, 'cola zero')
  } finally {
    restoreTestEnv(env)
  }
})

Deno.test('resolveGeminiIngredients — records attempt even when lookup returns empty', async () => {
  const env = saveTestEnv()
  setAiEnvEnabled()
  try {
    const result = await withMockedFetch(() => geminiGenerateText('UNKNOWN'), async () =>
      resolveGeminiIngredients(baseInput))

    assertEquals(result.ingredients, [])
    assertEquals(result.ingredientSource, 'off')
    assertExists(result.geminiAt)
    assertEquals(result.geminiNameKey, 'cola zero')
  } finally {
    restoreTestEnv(env)
  }
})
