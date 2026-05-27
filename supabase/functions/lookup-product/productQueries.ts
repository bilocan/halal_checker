import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import type { KeywordEntry } from './keyword.ts';

export interface HalalScanProduct extends Record<string, unknown> {
  barcode: string;
  is_managed?: boolean;
  is_unknown?: boolean;
  ingredients?: unknown;
  ingredient_source?: string;
  name?: string;
  labels?: unknown;
  image_url?: string;
  image_front_url?: string;
  image_ingredients_url?: string;
  image_nutrition_url?: string;
  requires_halal_cert?: boolean;
  last_analysed_at?: string;
  fetched_at?: string;
  gemini_web_ingredient_lookup_at?: string;
  gemini_web_ingredient_lookup_name_key?: string;
}

/**
 * Fetch product from products_full table.
 */
export async function getHalalScanProduct(
  supabase: SupabaseClient,
  barcode: string
): Promise<HalalScanProduct | null> {
  const { data } = await supabase
    .from('products_full')
    .select('*')
    .eq('barcode', barcode)
    .maybeSingle();
  return data ?? null;
}

/**
 * Load custom haram/suspicious keywords from the keywords table.
 */
export async function loadCustomKeywords(
  supabase: SupabaseClient
): Promise<{ haram: KeywordEntry[]; suspicious: KeywordEntry[] }> {
  const { data: kwRows } = await supabase
    .from('keywords')
    .select('canonical, category, reason, variants');

  const haram: KeywordEntry[] = [];
  const suspicious: KeywordEntry[] = [];

  if (kwRows) {
    for (const kw of kwRows) {
      const variants: string[] = Array.isArray(kw.variants) && kw.variants.length > 0
        ? kw.variants as string[]
        : [kw.canonical as string];
      const entry: KeywordEntry = [kw.canonical as string, kw.reason as string, ...variants];
      if (kw.category === 'haram') {
        haram.push(entry);
      } else {
        suspicious.push(entry);
      }
    }
  }

  return { haram, suspicious };
}