// Request handling for retest-products (split from index.ts so tests can
// import handlers without triggering Deno.serve).
//
// Body: { action: 'scan' | 'list' | 'apply' | 'discard' | 'latest', ... }
//   scan:    { runId?: string, cursor?: string, limit?: number,
//              barcodes?: string[], nameQuery?: string,
//              analyzedBefore?: string, analyzedAfter?: string }
//   list:    { runId: string, offset?: number, limit?: number }
//   apply:   { runId: string, barcodes?: string[] }   // omit barcodes to apply all
//   discard: { runId: string }
//   latest:  {}   // finds the most recent run still worth resuming/reviewing
//
// Scan progress (cursor + running totals) is persisted per run in
// `product_retest_runs` so a scan can resume across page reloads instead of
// re-scanning the whole catalog from the start, and so `latest` can restore
// an in-progress/reviewable run in the UI after a refresh. `scan` filters
// (barcodes / nameQuery / analyzedBefore / analyzedAfter) are only read from
// the request when *starting* a new run — once a run exists, its persisted
// filter is authoritative, so resuming never silently switches from a
// scoped scan to scanning the whole catalog.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { computeStoredReanalysis } from '../lookup-product/reanalysis.ts'
import { loadCustomKeywords, type HalalScanProduct } from '../lookup-product/productQueries.ts'
import { upsertAnalysis, upsertProduct, type AnalysisRow, type ProductRow } from '../lookup-product/persistence.ts'
import { snapshotFromComputed, snapshotFromStoredRow, snapshotsEqual } from './retestDiff.ts'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const DEFAULT_SCAN_LIMIT = 100
const DEFAULT_LIST_LIMIT = 50

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

interface ApplyPayload {
  product: ProductRow
  analysis: AnalysisRow
}

/** Optional scan scope — omit all fields to scan the whole catalog. */
export interface ScanFilter {
  barcodes?: string[]
  nameQuery?: string
  /** ISO timestamp — only products last analyzed before this. */
  analyzedBefore?: string
  /** ISO timestamp — only products last analyzed after this. */
  analyzedAfter?: string
}

interface RunRow {
  run_id: string
  cursor: string | null
  done: boolean
  scanned: number
  changed: number
  filter_barcodes: string[] | null
  filter_name_query: string | null
  filter_analyzed_before: string | null
  filter_analyzed_after: string | null
}

function isFilterEmpty(filter: ScanFilter): boolean {
  return !filter.barcodes?.length && !filter.nameQuery && !filter.analyzedBefore && !filter.analyzedAfter
}

function filterFromRunRow(run: RunRow): ScanFilter {
  return {
    barcodes: run.filter_barcodes ?? undefined,
    nameQuery: run.filter_name_query ?? undefined,
    analyzedBefore: run.filter_analyzed_before ?? undefined,
    analyzedAfter: run.filter_analyzed_after ?? undefined,
  }
}

async function getRunRow(adminClient: SupabaseClient, runId: string): Promise<RunRow | null> {
  const { data } = await adminClient
    .from('product_retest_runs')
    .select(
      'run_id, cursor, done, scanned, changed, filter_barcodes, filter_name_query, filter_analyzed_before, filter_analyzed_after',
    )
    .eq('run_id', runId)
    .maybeSingle()
  return (data as RunRow | null) ?? null
}

async function saveRunProgress(
  adminClient: SupabaseClient,
  runId: string,
  existing: RunRow | null,
  cursor: string | null,
  done: boolean,
  scannedDelta: number,
  changedDelta: number,
  filter: ScanFilter,
): Promise<void> {
  const { error } = await adminClient.from('product_retest_runs').upsert({
    run_id: runId,
    cursor,
    done,
    scanned: (existing?.scanned ?? 0) + scannedDelta,
    changed: (existing?.changed ?? 0) + changedDelta,
    filter_barcodes: filter.barcodes?.length ? filter.barcodes : null,
    filter_name_query: filter.nameQuery || null,
    filter_analyzed_before: filter.analyzedBefore || null,
    filter_analyzed_after: filter.analyzedAfter || null,
    updated_at: new Date().toISOString(),
  })
  if (error) console.error(`[retest-products] run progress upsert failed for ${runId}`, error)
}

export async function handleScan(
  adminClient: SupabaseClient,
  runId: string | undefined,
  cursor: string | undefined,
  limit: number,
  requestedFilter: ScanFilter = {},
): Promise<Response> {
  const effectiveRunId = runId ?? crypto.randomUUID()

  // Resume from the persisted cursor when the caller doesn't supply one
  // (e.g. the page was reloaded mid-scan) instead of rescanning from the start.
  // Once a run exists, its persisted filter is authoritative — a filter in
  // the request only takes effect when *creating* a new run.
  let existingRun: RunRow | null = null
  let effectiveCursor = cursor
  let effectiveFilter = requestedFilter
  if (runId) {
    existingRun = await getRunRow(adminClient, runId)
    if (existingRun?.done) {
      return json({
        runId: effectiveRunId,
        scanned: 0,
        changed: 0,
        nextCursor: null,
        done: true,
        filtered: !isFilterEmpty(filterFromRunRow(existingRun)),
      })
    }
    if (effectiveCursor === undefined) effectiveCursor = existingRun?.cursor ?? undefined
    if (existingRun) effectiveFilter = filterFromRunRow(existingRun)
  }

  const { haram, suspicious } = await loadCustomKeywords(adminClient)

  let query = adminClient
    .from('products_full')
    .select('*')
    .order('barcode', { ascending: true })
    .limit(limit)
  if (effectiveCursor) query = query.gt('barcode', effectiveCursor)
  if (effectiveFilter.barcodes?.length) query = query.in('barcode', effectiveFilter.barcodes)
  if (effectiveFilter.nameQuery) query = query.ilike('name', `%${effectiveFilter.nameQuery}%`)
  if (effectiveFilter.analyzedBefore) query = query.lt('last_analysed_at', effectiveFilter.analyzedBefore)
  if (effectiveFilter.analyzedAfter) query = query.gt('last_analysed_at', effectiveFilter.analyzedAfter)

  const { data: rows, error } = await query
  if (error) return json({ error: 'Failed to fetch products' }, 500)
  if (!rows?.length) {
    await saveRunProgress(adminClient, effectiveRunId, existingRun, effectiveCursor ?? null, true, 0, 0, effectiveFilter)
    return json({
      runId: effectiveRunId,
      scanned: 0,
      changed: 0,
      nextCursor: null,
      done: true,
      filtered: !isFilterEmpty(effectiveFilter),
    })
  }

  let changed = 0
  for (const row of rows as HalalScanProduct[]) {
    if (row.is_managed) continue
    const barcode = row.barcode
    const { productRow, analysisRow } = await computeStoredReanalysis(
      adminClient, row, barcode, haram, suspicious,
    )
    const oldSnapshot = snapshotFromStoredRow(row)
    const newSnapshot = snapshotFromComputed(productRow, analysisRow)
    if (snapshotsEqual(oldSnapshot, newSnapshot)) continue

    changed++
    const payload: ApplyPayload = { product: productRow, analysis: analysisRow }
    const { error: upsertErr } = await adminClient.from('product_retest_diffs').upsert({
      run_id: effectiveRunId,
      barcode,
      old_snapshot: oldSnapshot,
      new_snapshot: newSnapshot,
      apply_payload: payload,
      applied: false,
      applied_at: null,
    }, { onConflict: 'run_id,barcode' })
    if (upsertErr) console.error(`[retest-products] diff upsert failed for ${barcode}`, upsertErr)
  }

  const lastBarcode = (rows[rows.length - 1] as Record<string, unknown>).barcode as string
  const done = rows.length < limit
  const nextCursor = done ? null : lastBarcode
  await saveRunProgress(adminClient, effectiveRunId, existingRun, nextCursor, done, rows.length, changed, effectiveFilter)

  return json({
    runId: effectiveRunId,
    scanned: rows.length,
    changed,
    nextCursor,
    done,
    filtered: !isFilterEmpty(effectiveFilter),
  })
}

export async function handleList(
  adminClient: SupabaseClient,
  runId: string,
  offset: number,
  limit: number,
): Promise<Response> {
  const { data, error, count } = await adminClient
    .from('product_retest_diffs')
    .select('barcode, old_snapshot, new_snapshot', { count: 'exact' })
    .eq('run_id', runId)
    .eq('applied', false)
    .order('barcode', { ascending: true })
    .range(offset, offset + limit - 1)
  if (error) return json({ error: 'Failed to list diffs' }, 500)
  const total = count ?? 0
  return json({ diffs: data ?? [], total, hasMore: offset + limit < total })
}

export async function handleApply(
  adminClient: SupabaseClient,
  runId: string,
  barcodes: string[] | undefined,
): Promise<Response> {
  let query = adminClient
    .from('product_retest_diffs')
    .select('id, barcode, apply_payload')
    .eq('run_id', runId)
    .eq('applied', false)
  if (barcodes?.length) query = query.in('barcode', barcodes)

  const { data: diffs, error } = await query
  if (error) return json({ error: 'Failed to load diffs' }, 500)
  if (!diffs?.length) return json({ applied: 0, errors: [] })

  let applied = 0
  const errors: { barcode: string; reason: string }[] = []
  for (const diff of diffs) {
    try {
      const payload = diff.apply_payload as ApplyPayload
      await upsertProduct(adminClient, payload.product)
      await upsertAnalysis(adminClient, payload.analysis)
      await adminClient
        .from('product_retest_diffs')
        .update({ applied: true, applied_at: new Date().toISOString() })
        .eq('id', diff.id)
      applied++
    } catch (e) {
      errors.push({ barcode: diff.barcode as string, reason: String(e) })
    }
  }
  return json({ applied, errors })
}

export async function handleDiscard(adminClient: SupabaseClient, runId: string): Promise<Response> {
  const { error, count } = await adminClient
    .from('product_retest_diffs')
    .delete({ count: 'exact' })
    .eq('run_id', runId)
    .eq('applied', false)
  if (error) return json({ error: 'Failed to discard run' }, 500)

  // Drop the scan progress too — a discarded run should not be resumable or
  // restorable by `latest`; the next scan starts a fresh run from barcode zero.
  await adminClient.from('product_retest_runs').delete().eq('run_id', runId)

  return json({ deleted: count ?? 0 })
}

/** Most recent run still worth restoring in the UI: not fully scanned yet, or
 * fully scanned but still has diffs the admin hasn't applied/discarded. */
export async function handleLatestRun(adminClient: SupabaseClient): Promise<Response> {
  const { data } = await adminClient
    .from('product_retest_runs')
    .select(
      'run_id, done, scanned, changed, filter_barcodes, filter_name_query, filter_analyzed_before, filter_analyzed_after',
    )
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  const run = data as RunRow | null

  if (!run) return json({ runId: null })

  const { count } = await adminClient
    .from('product_retest_diffs')
    .select('id', { count: 'exact', head: true })
    .eq('run_id', run.run_id)
    .eq('applied', false)

  const pending = count ?? 0
  if (run.done && pending === 0) return json({ runId: null })

  return json({
    runId: run.run_id,
    done: run.done,
    scanned: run.scanned,
    changed: run.changed,
    pending,
    filter: filterFromRunRow(run),
  })
}

/** Core action dispatch (auth already verified by the caller). */
export async function handleRetestRequest(req: Request, adminClient: SupabaseClient): Promise<Response> {
  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }
  const action = body.action

  if (action === 'scan') {
    const limit = typeof body.limit === 'number' ? Math.min(Math.max(1, body.limit), 500) : DEFAULT_SCAN_LIMIT
    const filter: ScanFilter = {
      barcodes: Array.isArray(body.barcodes) && body.barcodes.length > 0
        ? body.barcodes.map(String)
        : undefined,
      nameQuery: typeof body.nameQuery === 'string' && body.nameQuery.trim() ? body.nameQuery.trim() : undefined,
      analyzedBefore: typeof body.analyzedBefore === 'string' ? body.analyzedBefore : undefined,
      analyzedAfter: typeof body.analyzedAfter === 'string' ? body.analyzedAfter : undefined,
    }
    return handleScan(
      adminClient,
      typeof body.runId === 'string' ? body.runId : undefined,
      typeof body.cursor === 'string' ? body.cursor : undefined,
      limit,
      filter,
    )
  }

  if (action === 'list') {
    if (typeof body.runId !== 'string') return json({ error: 'runId is required' }, 400)
    const offset = typeof body.offset === 'number' ? Math.max(0, body.offset) : 0
    const limit = typeof body.limit === 'number' ? Math.min(Math.max(1, body.limit), 200) : DEFAULT_LIST_LIMIT
    return handleList(adminClient, body.runId, offset, limit)
  }

  if (action === 'apply') {
    if (typeof body.runId !== 'string') return json({ error: 'runId is required' }, 400)
    const barcodes = Array.isArray(body.barcodes) ? body.barcodes.map(String) : undefined
    return handleApply(adminClient, body.runId, barcodes)
  }

  if (action === 'discard') {
    if (typeof body.runId !== 'string') return json({ error: 'runId is required' }, 400)
    return handleDiscard(adminClient, body.runId)
  }

  if (action === 'latest') {
    return handleLatestRun(adminClient)
  }

  return json({ error: `Unknown action: ${String(action)}` }, 400)
}
