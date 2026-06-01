import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { toProduct } from './db.ts'
import { getApprovedContribution } from './community.ts'
import { computeVerdict } from './verdictRules.ts'
import type { KeywordEntry } from './keyword.ts'
import { classifyOffCategories, normalizeStoredLabels } from './lookupHelpers.ts'
import type { HalalScanProduct } from './productQueries.ts'
import {
  jsonResponse,
  persistLookupAndRespond,
  type AnalysisRow,
  type ProductRow,
} from './persistence.ts'

/**
 * Re-run keyword + post rules on stored product data (no OFF refetch, no AI).
 * Used when source data is stale or caller requested force refresh.
 */
export async function runStoredProductReanalysis(
  supabase: SupabaseClient,
  existing: HalalScanProduct,
  barcode: string,
  customHaramEntries: KeywordEntry[],
  customSuspiciousEntries: KeywordEntry[],
  corsHeaders: Record<string, string>,
): Promise<Response> {
  const communityIngredients = await getApprovedContribution(supabase, barcode)
  const storedIngredients: string[] = communityIngredients
    ?? (Array.isArray(existing.ingredients) ? existing.ingredients as string[] : [])
  const ingredientSource: 'off' | 'ai' | 'community' = communityIngredients
    ? 'community'
    : ((existing.ingredient_source === 'ai' || existing.ingredient_source === 'community')
        ? existing.ingredient_source as 'ai' | 'community'
        : 'off')

  const name = typeof existing.name === 'string' && existing.name.trim().length > 0
    ? existing.name.trim()
    : 'Unknown Product'
  const labels = normalizeStoredLabels(existing.labels)
  const isNonFood = !!(existing.is_non_food ?? false)
  const imageIngredientsUrl = typeof existing.image_ingredients_url === 'string'
    ? existing.image_ingredients_url.trim()
    : ''

  const displayLang = typeof existing.display_lang === 'string'
    ? existing.display_lang
    : ''
  const analyzeLang = typeof existing.analyze_lang === 'string'
    ? existing.analyze_lang
    : null
  const analyzeSources = storedIngredients.length > 0
    ? [{ key: 'primary' as const, ingredients: storedIngredients }]
    : []

  const rawCategories: string[] = Array.isArray(existing.categories_tags)
    ? existing.categories_tags as string[]
    : []
  const { haramCategory, isHalalByCategory } = classifyOffCategories(rawCategories, isNonFood)

  const verdict = await computeVerdict({
    barcode,
    ingredients: storedIngredients,
    analyzeSources,
    displayLang,
    analyzeLang,
    name,
    labels,
    additivesTags: Array.isArray(existing.additives_tags) ? existing.additives_tags as string[] : [],
    rawCategories,
    isNonFood,
    ingredientSource,
    haramCategory,
    isHalalByCategory,
    customHaramEntries,
    customSuspiciousEntries,
    imageIngredientsUrl,
    skipAi: true,
  })

  const {
    isHalal, isUnknown, haramIngredients, suspiciousIngredients,
    ingredientWarnings, haramLabels, suspiciousLabels, labelWarnings,
    haramAdditives, suspiciousAdditives, additiveWarnings,
    explanation, requiresHalalCert,
  } = verdict

  const productRow: ProductRow = {
    barcode,
    name,
    ingredients: verdict.ingredients,
    ingredientSource,
    isNonFood,
    labels,
    imageUrl: existing.image_url as string | undefined,
    imageFrontUrl: existing.image_front_url as string | undefined,
    imageIngredientsUrl: existing.image_ingredients_url as string | undefined,
    imageNutritionUrl: existing.image_nutrition_url as string | undefined,
    requiresHalalCert,
    isManaged: existing.is_managed as boolean | undefined,
    fetchedAt: (existing.fetched_at as string) ?? new Date().toISOString(),
    geminiAt: existing.gemini_web_ingredient_lookup_at as string | undefined,
    geminiNameKey: existing.gemini_web_ingredient_lookup_name_key as string | undefined,
    brand:          typeof existing.brand === 'string' ? existing.brand : '',
    quantity:       typeof existing.quantity === 'string' ? existing.quantity : '',
    categoriesTags: rawCategories,
    additivesTags:  Array.isArray(existing.additives_tags) ? existing.additives_tags as string[] : [],
    allergensTags:  Array.isArray(existing.allergens_tags) ? existing.allergens_tags as string[] : [],
    tracesTags:     Array.isArray(existing.traces_tags) ? existing.traces_tags as string[] : [],
  }

  const analysisRow: AnalysisRow = {
    barcode,
    isHalal,
    isUnknown,
    isNonFood,
    haramIngredients,
    suspiciousIngredients,
    ingredientWarnings,
    haramLabels,
    suspiciousLabels,
    labelWarnings,
    haramAdditives,
    suspiciousAdditives,
    additiveWarnings,
    explanation,
    analyzedByAI: false,
    keywordMatchSource: verdict.keywordMatchSource,
    keywordMatchOrigins: verdict.keywordMatchOrigins,
    analyzeLang: verdict.analyzeLang,
  }

  const responseRow = {
    barcode,
    name,
    ingredients: verdict.ingredients,
    ingredient_source: ingredientSource,
    is_halal: isHalal,
    is_unknown: isUnknown,
    is_non_food: isNonFood,
    haram_ingredients: haramIngredients,
    suspicious_ingredients: suspiciousIngredients,
    ingredient_warnings: ingredientWarnings,
    haram_labels: haramLabels,
    suspicious_labels: suspiciousLabels,
    label_warnings: labelWarnings,
    haram_additives: haramAdditives,
    suspicious_additives: suspiciousAdditives,
    additive_warnings: additiveWarnings,
    labels,
    image_url: existing.image_url,
    image_front_url: existing.image_front_url,
    image_ingredients_url: existing.image_ingredients_url,
    image_nutrition_url: existing.image_nutrition_url,
    explanation,
    analyzed_by_ai: false,
    requires_halal_cert: requiresHalalCert,
    keyword_match_source: verdict.keywordMatchSource ?? null,
    keyword_match_origins: verdict.keywordMatchOrigins ?? {},
    analyze_lang: verdict.analyzeLang ?? null,
    display_lang: verdict.displayLang ?? null,
    is_managed: existing.is_managed,
    last_analysed_at: new Date().toISOString(),
    fetched_at: productRow.fetchedAt,
    gemini_web_ingredient_lookup_at: productRow.geminiAt ?? null,
    gemini_web_ingredient_lookup_name_key: productRow.geminiNameKey ?? null,
  }

  return persistLookupAndRespond(supabase, corsHeaders, productRow, analysisRow, responseRow)
}

/** Managed rows are returned unchanged. */
export function jsonManagedProduct(
  existing: HalalScanProduct,
  corsHeaders: Record<string, string>,
): Response {
  return jsonResponse({ product: toProduct(existing) }, 200, corsHeaders)
}
