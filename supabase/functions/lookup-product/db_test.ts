// Run with: deno test supabase/functions/lookup-product/db_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { isStale, toProduct } from './db.ts'

Deno.test('isStale — false when no updated_at', () => {
  assertEquals(isStale({ last_analysed_at: null }), false)
})

Deno.test('isStale — true when last_analysed_at missing but updated_at set', () => {
  assertEquals(isStale({ updated_at: '2026-05-01T00:00:00Z' }), true)
})

Deno.test('isStale — true when updated_at is newer than last_analysed_at', () => {
  assertEquals(isStale({
    updated_at: '2026-05-02T00:00:00Z',
    last_analysed_at: '2026-05-01T00:00:00Z',
  }), true)
})

Deno.test('isStale — false when analysis is at or after product update', () => {
  assertEquals(isStale({
    updated_at: '2026-05-01T00:00:00Z',
    last_analysed_at: '2026-05-02T00:00:00Z',
  }), false)
  assertEquals(isStale({
    updated_at: '2026-05-01T00:00:00Z',
    last_analysed_at: '2026-05-01T00:00:00Z',
  }), false)
})

Deno.test('toProduct — maps ingredientSource and requiresHalalCert defaults', () => {
  const p = toProduct({
    barcode: '1',
    name: 'X',
    ingredients: [],
    is_halal: false,
    haram_ingredients: [],
    suspicious_ingredients: [],
    ingredient_warnings: {},
    labels: [],
    explanation: '',
    analyzed_by_ai: false,
    ingredient_source: 'community',
    requires_halal_cert: true,
  })
  assertEquals(p.ingredientSource, 'community')
  assertEquals(p.requiresHalalCert, true)
  assertEquals(p.isManaged, false)
})

Deno.test('toProduct — maps haramLabels, suspiciousLabels, labelWarnings from DB row', () => {
  const p = toProduct({
    barcode: '1',
    name: 'X',
    ingredients: ['water'],
    is_halal: false,
    haram_ingredients: [],
    suspicious_ingredients: [],
    ingredient_warnings: {},
    haram_labels: ['pork'],
    suspicious_labels: ['gelatin'],
    label_warnings: { pork: 'Found on label: Contains pork', gelatin: 'Found on label: Gelatin source unclear' },
    labels: ['en:pork'],
    explanation: '',
    analyzed_by_ai: false,
  })
  assertEquals(p.haramLabels, ['pork'])
  assertEquals(p.suspiciousLabels, ['gelatin'])
  assertEquals(p.labelWarnings['pork'], 'Found on label: Contains pork')
  assertEquals(p.labelWarnings['gelatin'], 'Found on label: Gelatin source unclear')
})

Deno.test('toProduct — defaults haramLabels, suspiciousLabels, labelWarnings when absent', () => {
  const p = toProduct({
    barcode: '1',
    name: 'X',
    ingredients: [],
    is_halal: true,
    haram_ingredients: [],
    suspicious_ingredients: [],
    ingredient_warnings: {},
    labels: [],
    explanation: '',
    analyzed_by_ai: false,
  })
  assertEquals(p.haramLabels, [])
  assertEquals(p.suspiciousLabels, [])
  assertEquals(p.labelWarnings, {})
})
