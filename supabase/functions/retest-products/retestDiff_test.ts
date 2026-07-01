// Run with: deno test --allow-env supabase/functions/retest-products/retestDiff_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { snapshotFromComputed, snapshotFromStoredRow, snapshotsEqual } from './retestDiff.ts'
import type { AnalysisRow, ProductRow } from '../lookup-product/persistence.ts'

function analysisRow(overrides: Partial<AnalysisRow> = {}): AnalysisRow {
  return {
    barcode: '1234567890',
    isHalal: true,
    isUnknown: false,
    isNonFood: false,
    haramIngredients: [],
    suspiciousIngredients: [],
    ingredientWarnings: {},
    haramLabels: [],
    suspiciousLabels: [],
    labelWarnings: {},
    haramAdditives: [],
    suspiciousAdditives: [],
    additiveWarnings: {},
    explanation: '',
    analyzedByAI: false,
    ...overrides,
  }
}

function productRow(overrides: Partial<ProductRow> = {}): ProductRow {
  return {
    barcode: '1234567890',
    name: 'Test Product',
    ingredients: ['water'],
    ingredientSource: 'off',
    isNonFood: false,
    labels: [],
    imageUrl: undefined,
    imageFrontUrl: undefined,
    imageIngredientsUrl: undefined,
    imageNutritionUrl: undefined,
    requiresHalalCert: false,
    fetchedAt: '2026-06-01T00:00:00Z',
    ...overrides,
  }
}

Deno.test('snapshotFromStoredRow — maps snake_case fields, defaults missing arrays to []', () => {
  const snap = snapshotFromStoredRow({
    is_halal: false,
    is_unknown: false,
    haram_ingredients: ['pork'],
    explanation: 'contains pork',
  })
  assertEquals(snap.isHalal, false)
  assertEquals(snap.haramIngredients, ['pork'])
  assertEquals(snap.suspiciousIngredients, [])
  assertEquals(snap.haramLabels, [])
  assertEquals(snap.requiresHalalCert, false)
  assertEquals(snap.explanation, 'contains pork')
})

Deno.test('snapshotFromComputed — pulls requiresHalalCert from productRow, rest from analysisRow', () => {
  const snap = snapshotFromComputed(
    productRow({ requiresHalalCert: true }),
    analysisRow({ isHalal: false, haramIngredients: ['gelatin'], explanation: 'not halal' }),
  )
  assertEquals(snap.isHalal, false)
  assertEquals(snap.haramIngredients, ['gelatin'])
  assertEquals(snap.requiresHalalCert, true)
  assertEquals(snap.explanation, 'not halal')
})

Deno.test('snapshotsEqual — true for identical snapshots, list order does not matter', () => {
  const a = snapshotFromStoredRow({ is_halal: false, haram_ingredients: ['pork', 'gelatin'] })
  const b = snapshotFromStoredRow({ is_halal: false, haram_ingredients: ['gelatin', 'pork'] })
  assertEquals(snapshotsEqual(a, b), true)
})

Deno.test('snapshotsEqual — false when a new keyword flips the verdict', () => {
  const old = snapshotFromStoredRow({ is_halal: true, is_unknown: false, haram_ingredients: [] })
  const updated = snapshotFromComputed(
    productRow(),
    analysisRow({ isHalal: false, haramIngredients: ['e120'], explanation: 'contains E120 (carmine)' }),
  )
  assertEquals(snapshotsEqual(old, updated), false)
})

Deno.test('snapshotsEqual — false when only explanation text changes', () => {
  const a = snapshotFromStoredRow({ is_halal: true, explanation: 'stale explanation' })
  const b = snapshotFromStoredRow({ is_halal: true, explanation: 'fresh explanation' })
  assertEquals(snapshotsEqual(a, b), false)
})
