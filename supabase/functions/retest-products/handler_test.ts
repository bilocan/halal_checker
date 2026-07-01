// Run with: deno test --allow-env supabase/functions/retest-products/handler_test.ts

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleApply, handleDiscard, handleLatestRun, handleList, handleScan } from './handler.ts'

/** Chainable stub: every method call returns itself; awaiting it resolves to `result`. */
function chainable(result: unknown): unknown {
  const handler: ProxyHandler<() => void> = {
    get(_target, prop) {
      if (prop === 'then') {
        return (resolve: (v: unknown) => void) => resolve(result)
      }
      return () => proxy
    },
  }
  const proxy = new Proxy(() => undefined, handler)
  return proxy
}

interface MockOpts {
  productsFullRows?: Record<string, unknown>[]
  keywordRows?: Record<string, unknown>[]
  diffRows?: Record<string, unknown>[]
  diffListResult?: { data: unknown[]; error: null; count: number }
  discardCount?: number
  /** Existing product_retest_runs row — used by handleScan's resume lookup
   *  and handleLatestRun's "most recent run" query. */
  runRow?: Record<string, unknown> | null
}

function mockRetestSupabase(opts: MockOpts = {}): SupabaseClient {
  const from = (table: string) => {
    switch (table) {
      case 'products_full':
        return chainable({ data: opts.productsFullRows ?? [], error: null })
      case 'keywords':
        return chainable({ data: opts.keywordRows ?? [], error: null })
      case 'ingredient_contributions':
        return chainable({ data: null, error: null })
      case 'product_retest_diffs':
        return chainable(
          opts.diffListResult ?? { data: opts.diffRows ?? [], error: null, count: opts.discardCount ?? 0 },
        )
      case 'product_retest_runs':
        return chainable({ data: opts.runRow ?? null, error: null })
      case 'products':
      case 'product_analysis':
        return chainable({ error: null })
      default:
        throw new Error(`mockRetestSupabase: unexpected table ${table}`)
    }
  }
  return { from } as unknown as SupabaseClient
}

function storedRow(overrides: Record<string, unknown> = {}) {
  return {
    barcode: '1111111111',
    name: 'Test Product',
    ingredients: ['water', 'salt'],
    ingredient_source: 'off',
    is_halal: true,
    is_unknown: false,
    is_non_food: false,
    haram_ingredients: [],
    suspicious_ingredients: [],
    ingredient_warnings: {},
    labels: [],
    explanation: 'stale',
    analyzed_by_ai: false,
    requires_halal_cert: false,
    is_managed: false,
    fetched_at: '2026-05-01T00:00:00Z',
    ...overrides,
  }
}

Deno.test('handleScan — no changed products, run reports done with changed=0', async () => {
  const supabase = mockRetestSupabase({
    productsFullRows: [storedRow({
      explanation: 'No haram or suspicious ingredients detected. Assessed by keyword matching.',
    })],
  })
  const res = await handleScan(supabase, undefined, undefined, 10)
  const body = await res.json()
  assertEquals(body.scanned, 1)
  assertEquals(body.changed, 0)
  assertEquals(body.done, true)
})

Deno.test('handleScan — new haram keyword flips a stored halal product, diff recorded as changed', async () => {
  const supabase = mockRetestSupabase({
    productsFullRows: [storedRow({
      barcode: '2222222222',
      ingredients: ['gelatin'],
      is_halal: true,
      is_unknown: false,
    })],
    keywordRows: [{ canonical: 'gelatin', category: 'haram', reason: 'often pork-derived', variants: ['gelatin'] }],
  })
  const res = await handleScan(supabase, undefined, undefined, 10)
  const body = await res.json()
  assertEquals(body.scanned, 1)
  assertEquals(body.changed, 1)
})

Deno.test('handleScan — managed products are skipped', async () => {
  const supabase = mockRetestSupabase({
    productsFullRows: [storedRow({ is_managed: true, ingredients: ['gelatin'], is_halal: true })],
    keywordRows: [{ canonical: 'gelatin', category: 'haram', reason: 'often pork-derived', variants: ['gelatin'] }],
  })
  const res = await handleScan(supabase, undefined, undefined, 10)
  const body = await res.json()
  assertEquals(body.changed, 0)
})

Deno.test('handleScan — reuses provided runId and paginates via nextCursor', async () => {
  const supabase = mockRetestSupabase({ productsFullRows: [storedRow({ barcode: '3333333333' })] })
  const res = await handleScan(supabase, 'fixed-run-id', undefined, 1)
  const body = await res.json()
  assertEquals(body.runId, 'fixed-run-id')
  assertEquals(body.nextCursor, '3333333333')
  assertEquals(body.done, false)
})

Deno.test('handleList — returns diffs with total/hasMore from count', async () => {
  const supabase = mockRetestSupabase({
    diffListResult: {
      data: [{ barcode: '4444444444', old_snapshot: {}, new_snapshot: {} }],
      error: null,
      count: 5,
    },
  })
  const res = await handleList(supabase, 'run-1', 0, 1)
  const body = await res.json()
  assertEquals(body.total, 5)
  assertEquals(body.hasMore, true)
  assertEquals(body.diffs.length, 1)
})

Deno.test('handleApply — applies each diff payload and reports count', async () => {
  const supabase = mockRetestSupabase({
    diffRows: [
      {
        id: 'diff-1',
        barcode: '5555555555',
        apply_payload: {
          product: {
            barcode: '5555555555', name: 'X', ingredients: [], ingredientSource: 'off',
            isNonFood: false, labels: [], imageUrl: undefined, imageFrontUrl: undefined,
            imageIngredientsUrl: undefined, imageNutritionUrl: undefined,
            requiresHalalCert: false, fetchedAt: '2026-06-01T00:00:00Z',
          },
          analysis: {
            barcode: '5555555555', isHalal: false, isUnknown: false, isNonFood: false,
            haramIngredients: ['gelatin'], suspiciousIngredients: [], ingredientWarnings: {},
            haramLabels: [], suspiciousLabels: [], labelWarnings: {},
            haramAdditives: [], suspiciousAdditives: [], additiveWarnings: {},
            explanation: 'contains gelatin', analyzedByAI: false,
          },
        },
      },
    ],
  })
  const res = await handleApply(supabase, 'run-1', undefined)
  const body = await res.json()
  assertEquals(body.applied, 1)
  assertEquals(body.errors, [])
})

Deno.test('handleApply — no unapplied diffs returns applied=0', async () => {
  const supabase = mockRetestSupabase({ diffRows: [] })
  const res = await handleApply(supabase, 'run-1', undefined)
  const body = await res.json()
  assertEquals(body.applied, 0)
})

Deno.test('handleDiscard — deletes unapplied diffs and reports count', async () => {
  const supabase = mockRetestSupabase({ discardCount: 3 })
  const res = await handleDiscard(supabase, 'run-1')
  const body = await res.json()
  assertEquals(body.deleted, 3)
})

Deno.test('handleScan — resuming a run already marked done short-circuits without rescanning', async () => {
  const supabase = mockRetestSupabase({
    productsFullRows: [storedRow({ barcode: '9999999999' })],
    runRow: { run_id: 'run-1', cursor: null, done: true, scanned: 42, changed: 3 },
  })
  const res = await handleScan(supabase, 'run-1', undefined, 10)
  const body = await res.json()
  assertEquals(body.scanned, 0)
  assertEquals(body.changed, 0)
  assertEquals(body.done, true)
})

Deno.test('handleLatestRun — no runs at all returns runId=null', async () => {
  const supabase = mockRetestSupabase({ runRow: null })
  const res = await handleLatestRun(supabase)
  const body = await res.json()
  assertEquals(body.runId, null)
})

Deno.test('handleLatestRun — unfinished run is restorable', async () => {
  const supabase = mockRetestSupabase({
    runRow: { run_id: 'run-1', done: false, scanned: 10, changed: 2 },
    discardCount: 2, // reused as the "pending diffs" count for this run
  })
  const res = await handleLatestRun(supabase)
  const body = await res.json()
  assertEquals(body.runId, 'run-1')
  assertEquals(body.done, false)
  assertEquals(body.pending, 2)
})

Deno.test('handleLatestRun — finished run with nothing pending is not restorable', async () => {
  const supabase = mockRetestSupabase({
    runRow: { run_id: 'run-1', done: true, scanned: 10, changed: 2 },
    discardCount: 0,
  })
  const res = await handleLatestRun(supabase)
  const body = await res.json()
  assertEquals(body.runId, null)
})

Deno.test('handleLatestRun — finished run with unapplied diffs left is still restorable', async () => {
  const supabase = mockRetestSupabase({
    runRow: { run_id: 'run-1', done: true, scanned: 10, changed: 2 },
    discardCount: 2,
  })
  const res = await handleLatestRun(supabase)
  const body = await res.json()
  assertEquals(body.runId, 'run-1')
  assertEquals(body.pending, 2)
})
