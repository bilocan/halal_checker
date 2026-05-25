import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

/** Whether Gemini web ingredient lookup should run for this request. */
export function shouldRunGeminiIngredientLookup(opts: {
  fetchAiIngredients: boolean
  hasApprovedRequest: boolean
  offIngredientCount: number
  productName: string
}): boolean {
  return (
    opts.fetchAiIngredients &&
    opts.hasApprovedRequest &&
    opts.offIngredientCount === 0 &&
    opts.productName !== 'Unknown Product'
  )
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
