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
}

export interface AnalysisRow {
  barcode: string
  isHalal: boolean
  isUnknown: boolean
  isNonFood: boolean
  haramIngredients: string[]
  suspiciousIngredients: string[]
  ingredientWarnings: Record<string, string>
  explanation: string
  analyzedByAI: boolean
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
    ...(row.isManaged !== undefined ? { is_managed: row.isManaged } : {}),
    ...(row.geminiNameKey ? {
      gemini_web_ingredient_lookup_at:       row.geminiAt,
      gemini_web_ingredient_lookup_name_key: row.geminiNameKey,
    } : {}),
  })
  if (error) console.error(`[${row.barcode}] products upsert error`, error)
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
    explanation:            row.explanation,
    analyzed_by_ai:         row.analyzedByAI,
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
