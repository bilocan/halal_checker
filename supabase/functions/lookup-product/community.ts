import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export function parseIngredientText(text: string): string[] {
  return text
    .split(/[,;]/)
    .map((s: string) => s.trim())
    .filter((s: string) => s.length > 0)
}

/** Latest approved community ingredient list for a barcode, if any. */
export async function getApprovedContribution(
  supabase: SupabaseClient,
  barcode: string,
): Promise<string[] | null> {
  const { data } = await supabase
    .from('ingredient_contributions')
    .select('ingredient_text')
    .eq('barcode', barcode)
    .eq('status', 'approved')
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()

  if (!data?.ingredient_text) return null
  const parsed = parseIngredientText(data.ingredient_text as string)
  return parsed.length > 0 ? parsed : null
}

// deno-lint-ignore no-explicit-any
export function withCommunitySource(
  row: Record<string, any>,
  communityIngredients: string[] | null,
): Record<string, any> {
  if (!communityIngredients?.length) return row
  return {
    ...row,
    ingredients: communityIngredients,
    ingredient_source: 'community',
  }
}
