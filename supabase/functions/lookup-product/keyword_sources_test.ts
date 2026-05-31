// Run with: deno test --allow-env supabase/functions/lookup-product/keyword_sources_test.ts

import { assertEquals, assertMatch } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { keywordAnalysisFromSources } from './keyword.ts'

Deno.test('keywordAnalysisFromSources — English fallback catches pork in Cyrillic product', () => {
  const result = keywordAnalysisFromSources(
    [
      { key: 'primary', ingredients: ['частично финомляно свинско месо', 'вода'] },
      { key: 'off_en', ingredients: ['80% pork meat is partially minced', 'water'] },
    ],
    ['частично финомляно свинско месо', 'вода'],
    'en',
  )

  assertEquals(result.isHalal, false)
  assertEquals(result.isUnknown, false)
  assertEquals(result.haram.some(h => h.includes('pork')), true)
  assertEquals(result.keywordMatchSource?.includes('off_en'), true)
  assertEquals(result.haram.some(h => h.includes('pork')), true)
})

Deno.test('keywordAnalysisFromSources — Cyrillic label matches Bulgarian pork terms', () => {
  const result = keywordAnalysisFromSources(
    [{ key: 'primary', ingredients: ['частично финомляно свинско месо'] }],
    ['частично финомляно свинско месо'],
    null,
  )

  assertEquals(result.isUnknown, false)
  assertEquals(result.isHalal, false)
  assertEquals(result.keywordMatchSource, 'primary')
  assertEquals(result.haram.some(h => h.includes('свинско')), true)
  assertMatch(result.explanation, /keyword matching/i)
})

Deno.test('keywordAnalysisFromSources — partial taxonomy without pork stays unanalyzable', () => {
  const result = keywordAnalysisFromSources(
    [
      { key: 'primary', ingredients: ['вода'] },
      { key: 'off_taxonomy', ingredients: ['water', 'salt'] },
    ],
    ['вода'],
    null,
  )

  assertEquals(result.isUnknown, true)
  assertEquals(result.keywordMatchSource, 'unanalyzable')
  assertEquals(result.haram.length, 0)
})

Deno.test('keywordAnalysisFromSources — bg taxonomy id matches pork on label', () => {
  const result = keywordAnalysisFromSources(
    [
      { key: 'primary', ingredients: ['свинско месо'] },
      { key: 'off_taxonomy', ingredients: ['свинско месо'] },
    ],
    ['свинско месо'],
    null,
  )

  assertEquals(result.isHalal, false)
  assertEquals(result.isUnknown, false)
  assertEquals(result.keywordMatchSource, 'off_taxonomy+primary')
})

Deno.test('keywordAnalysisFromSources — taxonomy id catches pork', () => {
  const result = keywordAnalysisFromSources(
    [
      { key: 'primary', ingredients: ['свинско месо'] },
      { key: 'off_taxonomy', ingredients: ['pork'] },
    ],
    ['свинско месо'],
    null,
  )

  assertEquals(result.isHalal, false)
  assertEquals(result.haram.some(h => h.includes('pork') || h.includes('свинско')), true)
  assertEquals(result.keywordMatchSource?.includes('off_taxonomy'), true)
})
