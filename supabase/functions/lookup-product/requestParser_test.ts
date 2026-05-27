// Run with: deno test supabase/functions/lookup-product/requestParser_test.ts

import { assertEquals, assertThrows } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { parseRequest } from './requestParser.ts'

Deno.test('parseRequest — valid barcode and flags', () => {
  assertEquals(parseRequest({ barcode: '8690766143732', force: true }), {
    barcode: '8690766143732',
    force: true,
    fetchAiIngredients: false,
  })
  assertEquals(
    parseRequest({ barcode: '1', fetchAiIngredients: 1 }),
    { barcode: '1', force: false, fetchAiIngredients: true },
  )
})

Deno.test('parseRequest — rejects invalid body', () => {
  assertThrows(() => parseRequest(null), Error, 'Invalid JSON body')
  assertThrows(() => parseRequest('x'), Error, 'Invalid JSON body')
})

Deno.test('parseRequest — rejects missing or empty barcode', () => {
  assertThrows(() => parseRequest({}), Error, 'barcode is required')
  assertThrows(() => parseRequest({ barcode: '' }), Error, 'barcode is required')
  assertThrows(() => parseRequest({ barcode: 123 }), Error, 'barcode is required')
})
