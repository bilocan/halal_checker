import { assertEquals, assertMatch } from 'https://deno.land/std@0.208.0/assert/mod.ts'
import {
  adjustFlavouringForVegan,
  buildSuspiciousExplanation,
  hasVeganLabelEvidence,
} from './flavouringVerdict.ts'

Deno.test('hasVeganLabelEvidence — en:vegan label', () => {
  assertEquals(hasVeganLabelEvidence(['en:vegan'], 'Cookies'), true)
})

Deno.test('hasVeganLabelEvidence — vegetarian alone is false', () => {
  assertEquals(hasVeganLabelEvidence(['en:vegetarian'], 'Cookies'), false)
})

Deno.test('buildSuspiciousExplanation — flavouring mentions alcohol extraction', () => {
  const msg = buildSuspiciousExplanation(
    ['Aroma'],
    { Aroma: 'flavouring' },
    [],
    '',
  )
  assertMatch(msg, /animal-derived or extracted with alcohol/i)
})

Deno.test('buildSuspiciousExplanation — vegan flavouring drops animal conclusion', () => {
  const msg = buildSuspiciousExplanation(
    ['Aroma'],
    { Aroma: 'flavouring' },
    ['en:vegan'],
    'Chocolate Chip Cookies',
  )
  assertMatch(msg, /vegan-certified/i)
  assertMatch(msg, /non-animal per certification/i)
  assertMatch(msg, /alcohol content cannot be ruled out/i)
})

Deno.test('adjustFlavouringForVegan — rewrites per-ingredient warning', () => {
  const result = adjustFlavouringForVegan({
    suspicious: ['Aroma'],
    warnings: { Aroma: 'old warning' },
    canonicals: { Aroma: 'flavouring' },
    labels: ['en:vegan'],
    productName: 'Cookies',
  })
  assertMatch(result.warnings.Aroma, /Vegan-certified/i)
  assertMatch(result.warnings.Aroma, /alcohol used in extraction/i)
})

Deno.test('buildSuspiciousExplanation — vegetarian label keeps animal-derived for Aroma', () => {
  const msg = buildSuspiciousExplanation(
    ['Aroma'],
    { Aroma: 'flavouring' },
    ['en:vegetarian'],
    'Cookies',
  )
  assertMatch(msg, /animal-derived or extracted with alcohol/i)
  assertEquals(msg.includes('vegan-certified'), false)
})

Deno.test('buildSuspiciousExplanation — vegan + glycerol splits flavouring from other', () => {
  const msg = buildSuspiciousExplanation(
    ['Aroma', 'glycerol'],
    { Aroma: 'flavouring', glycerol: 'glycerol' },
    ['en:vegan'],
    'Cookies',
  )
  assertMatch(msg, /non-animal per certification/i)
  assertMatch(msg, /alcohol content cannot be ruled out/i)
  assertMatch(msg, /may still be animal-derived: glycerol/i)
})
