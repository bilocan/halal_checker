import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export const GEMINI_LOOKUP_EMPTY_OFF_CONFIG_KEY = 'gemini_lookup_empty_off'

/**
 * Local/dev override via `GEMINI_LOOKUP_EMPTY_OFF=true` (Supabase secret or .env.local).
 * Production toggle is `app_config.gemini_lookup_empty_off` (superadmin in app).
 */
export function isGeminiLookupEmptyOffEnvEnabled(envValue?: string): boolean {
  const v = envValue ?? Deno.env.get('GEMINI_LOOKUP_EMPTY_OFF')
  return v === 'true'
}

export function isGeminiLookupEmptyOffDbEnabled(dbValue: string | null | undefined): boolean {
  return dbValue === 'true'
}

/** Env OR app_config (read with service role in lookup-product). */
export async function resolveGeminiLookupEmptyOffEnabled(
  supabase: SupabaseClient,
  opts?: { envValue?: string },
): Promise<boolean> {
  if (isGeminiLookupEmptyOffEnvEnabled(opts?.envValue)) return true
  const { data, error } = await supabase
    .from('app_config')
    .select('value')
    .eq('key', GEMINI_LOOKUP_EMPTY_OFF_CONFIG_KEY)
    .maybeSingle()
  if (error) {
    console.error(
      `[app_config] read ${GEMINI_LOOKUP_EMPTY_OFF_CONFIG_KEY} failed:`,
      error.message,
    )
    return false
  }
  return isGeminiLookupEmptyOffDbEnabled(data?.value as string | undefined)
}

/** Whether Gemini web ingredient lookup should run for this request. */
export function shouldRunGeminiIngredientLookup(opts: {
  autoLookupEmptyOff: boolean
  fetchAiIngredients: boolean
  hasApprovedRequest: boolean
  offIngredientCount: number
  productName: string
}): boolean {
  if (opts.offIngredientCount !== 0 || opts.productName === 'Unknown Product') {
    return false
  }
  if (opts.autoLookupEmptyOff) return true
  return opts.fetchAiIngredients && opts.hasApprovedRequest
}

/** Re-fetch OFF + Gemini when a cached row still has no ingredients from OFF. */
export function shouldBypassCacheForGeminiAutoLookup(
  cached: { ingredients?: unknown; ingredient_source?: string | null } | null,
  opts: { autoLookupEmptyOff: boolean; fetchAiIngredients: boolean; force: boolean },
): boolean {
  if (opts.fetchAiIngredients || opts.force || !opts.autoLookupEmptyOff || !cached) {
    return false
  }
  const ing = Array.isArray(cached.ingredients) ? cached.ingredients : []
  if (ing.length > 0) return false
  const source = cached.ingredient_source ?? 'off'
  return source === 'off'
}

export async function hasApprovedAiIngredientRequest(
  supabase: SupabaseClient,
  barcode: string,
): Promise<boolean> {
  const { data } = await supabase
    .from('ai_ingredient_requests')
    .select('id')
    .eq('barcode', barcode)
    .eq('status', 'approved')
    .limit(1)
    .maybeSingle()
  return data != null
}
