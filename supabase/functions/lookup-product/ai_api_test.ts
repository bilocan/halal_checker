// Run with: deno test --allow-env supabase/functions/lookup-product/ai_api_test.ts

import { assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  analyzeWithClaude,
  analyzeWithClaudeVision,
  analyzeWithGemini,
  geminiIngredientLookup,
} from './ai.ts'
import {
  aiVerdictJson,
  claudeTextContent,
  geminiGenerateText,
  restoreTestEnv,
  saveTestEnv,
  withMockedFetch,
} from './lookup_test_helpers.ts'

const BARCODE = 'test-bc-ai'

Deno.test('geminiIngredientLookup — parses comma list from mocked API', async () => {
  const list = await withMockedFetch(
    (req) => {
      assertEquals(req.url.includes('generativelanguage.googleapis.com'), true)
      return geminiGenerateText('water, sugar, citric acid')
    },
    () => geminiIngredientLookup('Cola', BARCODE, 'fake-key', 'Brand'),
  )
  assertEquals(list, ['water', 'sugar', 'citric acid'])
})

Deno.test('geminiIngredientLookup — UNKNOWN yields empty list', async () => {
  const list = await withMockedFetch(
    () => geminiGenerateText('UNKNOWN'),
    () => geminiIngredientLookup('Cola', BARCODE, 'fake-key'),
  )
  assertEquals(list, [])
})

Deno.test('analyzeWithGemini — returns verdict from mocked JSON', async () => {
  const verdict = await withMockedFetch(
    (req) => {
      assertEquals(req.url.includes('gemini-2.5-flash'), true)
      return geminiGenerateText(aiVerdictJson({ isHalal: true, explanation: 'OK' }))
    },
    () => analyzeWithGemini(['water', 'salt'], BARCODE, 'fake-key'),
  )
  assertExists(verdict)
  assertEquals(verdict!.isHalal, true)
  assertEquals(verdict!.explanation, 'OK')
})

Deno.test('analyzeWithClaude — returns verdict from mocked JSON', async () => {
  const verdict = await withMockedFetch(
    (req) => {
      assertEquals(req.url.includes('api.anthropic.com'), true)
      return claudeTextContent(aiVerdictJson({
        isHalal: false,
        haramIngredients: ['pork'],
        explanation: 'Contains pork.',
      }))
    },
    () => analyzeWithClaude(['pork', 'salt'], BARCODE, 'fake-key'),
  )
  assertExists(verdict)
  assertEquals(verdict!.isHalal, false)
  assertEquals(verdict!.haramIngredients, ['pork'])
})

Deno.test('analyzeWithClaudeVision — extracts ingredients from mocked OCR text', async () => {
  const list = await withMockedFetch(
    (req) => {
      const body = req.json() as Promise<{ messages: unknown[] }>
      return body.then((b) => {
        assertEquals(typeof b.messages, 'object')
        return claudeTextContent('water, salt, flour')
      })
    },
    () => analyzeWithClaudeVision('https://example.com/ingredients.jpg', BARCODE, 'fake-key'),
  )
  assertEquals(list, ['water', 'salt', 'flour'])
})

Deno.test('analyzeWithGemini — HTTP error returns null', async () => {
  const verdict = await withMockedFetch(
    () => new Response('error', { status: 500 }),
    () => analyzeWithGemini(['water'], BARCODE, 'fake-key'),
  )
  assertEquals(verdict, null)
})
