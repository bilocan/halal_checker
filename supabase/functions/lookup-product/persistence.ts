import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { toProduct } from './db.ts'

export interface ProductRow {
  barcode: string
  name: string
  ingredients: string[]
  ingredientSource: 'off' | 'ai' | 'community'
  isNonFood: boolean
  labels: string[]
  imageUrl: string | null | undefined
  imageFrontUrl: string | null | undefined
  imageIngredientsUrl: string | null | undefined
  imageNutritionUrl: string | null | undefined
  requiresHalalCert: boolean
  isManaged?: boolean
  fetchedAt: string
  geminiAt?: string
  geminiNameKey?: string
  displayLang?: string
  brand?: string
  quantity?: string
  categoriesTags?: string[]
  additivesTags?: string[]
  allergensTags?: string[]
  tracesTags?: string[]
}

export interface AnalysisRow {
  barcode: string
  isHalal: boolean
  isUnknown: boolean
  isNonFood: boolean
  haramIngredients: string[]
  suspiciousIngredients: string[]
  ingredientWarnings: Record<string, string>
  haramLabels: string[]
  suspiciousLabels: string[]
  labelWarnings: Record<string, string>
  haramAdditives: string[]
  suspiciousAdditives: string[]
  additiveWarnings: Record<string, string>
  explanation: string
  analyzedByAI: boolean
  keywordMatchSource?: string
  keywordMatchOrigins?: Record<string, string>
  keywordMatchLanguages?: Record<string, string>
  halalCertMatchTerm?: string
  halalCertMatchLang?: string | null
  analyzeLang?: string | null
}

export async function upsertProduct(supabase: SupabaseClient, row: ProductRow): Promise<void> {
  const { error } = await supabase.from('products').upsert({
    barcode:               row.barcode,
    name:                  row.name,
    ingredients:           row.ingredients,
    ingredient_source:     row.ingredientSource,
    is_non_food:           row.isNonFood,
    labels:                row.labels,
    image_url:             row.imageUrl ?? null,
    image_front_url:       row.imageFrontUrl ?? null,
    image_ingredients_url: row.imageIngredientsUrl ?? null,
    image_nutrition_url:   row.imageNutritionUrl ?? null,
    requires_halal_cert:   row.requiresHalalCert,
    last_analysed_at:      new Date().toISOString(),
    fetched_at:            row.fetchedAt,
    display_lang:          row.displayLang || null,
    brand:                 row.brand ?? '',
    quantity:              row.quantity ?? '',
    categories_tags:       row.categoriesTags ?? [],
    additives_tags:        row.additivesTags ?? [],
    allergens_tags:        row.allergensTags ?? [],
    traces_tags:           row.tracesTags ?? [],
    tags_version:          1,
    ...(row.isManaged !== undefined ? { is_managed: row.isManaged } : {}),
    ...(row.geminiNameKey ? {
      gemini_web_ingredient_lookup_at:       row.geminiAt,
      gemini_web_ingredient_lookup_name_key: row.geminiNameKey,
    } : {}),
  })
  if (error) console.error(`[${row.barcode}] products upsert error`, error)
}

/** Update only tag columns + tags_version. Never touches ingredients or analysis. */
export async function patchProductTags(
  supabase: SupabaseClient,
  barcode: string,
  tags: { brand: string; quantity: string; categoriesTags: string[]; additivesTags: string[]; allergensTags: string[]; tracesTags: string[] },
): Promise<void> {
  const { error } = await supabase.from('products').update({
    brand:           tags.brand,
    quantity:        tags.quantity,
    categories_tags: tags.categoriesTags,
    additives_tags:  tags.additivesTags,
    allergens_tags:  tags.allergensTags,
    traces_tags:     tags.tracesTags,
    tags_version:    1,
  }).eq('barcode', barcode)
  if (error) console.error(`[${barcode}] patchProductTags error`, error)
}

export async function upsertAnalysis(supabase: SupabaseClient, row: AnalysisRow): Promise<void> {
  const { error } = await supabase.from('product_analysis').upsert({
    barcode:                row.barcode,
    is_halal:               row.isHalal,
    is_unknown:             row.isUnknown,
    is_non_food:            row.isNonFood,
    haram_ingredients:      row.haramIngredients,
    suspicious_ingredients: row.suspiciousIngredients,
    ingredient_warnings:    row.ingredientWarnings,
    haram_labels:           row.haramLabels,
    suspicious_labels:      row.suspiciousLabels,
    label_warnings:         row.labelWarnings,
    haram_additives:        row.haramAdditives,
    suspicious_additives:   row.suspiciousAdditives,
    additive_warnings:      row.additiveWarnings,
    explanation:            row.explanation,
    analyzed_by_ai:         row.analyzedByAI,
    keyword_match_source:    row.keywordMatchSource ?? null,
    keyword_match_origins:   row.keywordMatchOrigins ?? {},
    keyword_match_languages: row.keywordMatchLanguages ?? {},
    halal_cert_match_term:   row.halalCertMatchTerm ?? null,
    halal_cert_match_lang:   row.halalCertMatchLang ?? null,
    analyze_lang:            row.analyzeLang ?? null,
    analyzed_at:            new Date().toISOString(),
  })
  if (error) console.error(`[${row.barcode}] product_analysis upsert error`, error)
}

export function jsonResponse(
  body: unknown,
  status: number,
  corsHeaders: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

/** Upsert product + analysis, re-read view, return JSON lookup response. */
export async function persistLookupAndRespond(
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>,
  product: ProductRow,
  analysis: AnalysisRow,
  // deno-lint-ignore no-explicit-any
  fallbackRow: Record<string, any>,
): Promise<Response> {
  await upsertProduct(supabase, product)
  await upsertAnalysis(supabase, analysis)
  const { data: saved } = await supabase
    .from('products_full')
    .select('*')
    .eq('barcode', product.barcode)
    .maybeSingle()
  return jsonResponse({ product: toProduct(saved ?? fallbackRow) }, 200, corsHeaders)
}
