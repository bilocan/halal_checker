// Run with: deno test supabase/functions/_shared/gemini_ingredient_lookup_test.ts
// No GEMINI_API_KEY required — asserts request shape only (zero token cost).

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  GEMINI_LOOKUP_MAX_OUTPUT_TOKENS,
  GEMINI_LOOKUP_MODEL,
  GEMINI_LOOKUP_TEMPERATURE,
  GEMINI_LOOKUP_TOP_P,
  INGREDIENT_LOOKUP_SYSTEM,
  buildGeminiIngredientLookupRequest,
  buildIngredientLookupPrompt,
  geminiIngredientLookupUrl,
  parseIngredientList,
} from './gemini_ingredient_lookup.ts'

const BARCODE = '5449000000990'
const NAME = 'Cola Zero'
const BRAND = 'Coca-Cola'

/** Stable snapshot of the Gemini request contract (Flutter + web admin share this). */
const REQUEST_SNAPSHOT = {
  contents: [{
    parts: [{
      text: buildIngredientLookupPrompt(NAME, BARCODE, BRAND),
    }],
  }],
  systemInstruction: { parts: [{ text: INGREDIENT_LOOKUP_SYSTEM }] },
  tools: [{ google_search: {} }],
  generationConfig: {
    maxOutputTokens: GEMINI_LOOKUP_MAX_OUTPUT_TOKENS,
    temperature: GEMINI_LOOKUP_TEMPERATURE,
    topP: GEMINI_LOOKUP_TOP_P,
    thinkingConfig: { thinkingBudget: 0 },
  },
}

Deno.test('buildGeminiIngredientLookupRequest — matches snapshot (no API call)', () => {
  const body = buildGeminiIngredientLookupRequest(NAME, BARCODE, BRAND)
  assertEquals(body, REQUEST_SNAPSHOT)
})

Deno.test('buildGeminiIngredientLookupRequest — omits brand when empty', () => {
  const body = buildGeminiIngredientLookupRequest(NAME, BARCODE, '')
  assertEquals(
    body.contents[0].parts[0].text,
    buildIngredientLookupPrompt(NAME, BARCODE, ''),
  )
  assertEquals(body.tools, [{ google_search: {} }])
  assertEquals(body.generationConfig.maxOutputTokens, 2048)
})

Deno.test('geminiIngredientLookupUrl — uses lookup model', () => {
  const url = geminiIngredientLookupUrl('test-key')
  assertEquals(url.includes(`/${GEMINI_LOOKUP_MODEL}:generateContent`), true)
  assertEquals(url.endsWith('?key=test-key'), true)
})

Deno.test('parseIngredientList — comma list and UNKNOWN', () => {
  assertEquals(parseIngredientList('water, sugar, citric acid'), [
    'water',
    'sugar',
    'citric acid',
  ])
  assertEquals(parseIngredientList('UNKNOWN'), [])
})
