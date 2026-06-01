import { isGeminiWebIngredientLookupDoneForProductName } from './ingredient_lookup_gate.ts'

// deno-lint-ignore no-explicit-any
export function toProduct(row: Record<string, any>) {
  return {
    barcode:               row.barcode,
    name:                  row.name,
    ingredients:           row.ingredients,
    isHalal:               row.is_halal,
    isUnknown:             row.is_unknown ?? false,
    isNonFood:             row.is_non_food ?? false,
    haramIngredients:      row.haram_ingredients,
    suspiciousIngredients: row.suspicious_ingredients,
    ingredientWarnings:    row.ingredient_warnings,
    haramLabels:           row.haram_labels ?? [],
    suspiciousLabels:      row.suspicious_labels ?? [],
    labelWarnings:         row.label_warnings ?? {},
    haramAdditives:        row.haram_additives ?? [],
    suspiciousAdditives:   row.suspicious_additives ?? [],
    additiveWarnings:      row.additive_warnings ?? {},
    labels:                row.labels,
    imageUrl:              row.image_url,
    imageFrontUrl:         row.image_front_url,
    imageIngredientsUrl:   row.image_ingredients_url,
    imageNutritionUrl:     row.image_nutrition_url,
    explanation:           row.explanation,
    analyzedByAI:          row.analyzed_by_ai,
    analysisMethod:        row.analyzed_by_ai ? 'ai' : 'keyword',
    ingredientSource:      row.ingredient_source ?? 'off',
    requiresHalalCert:     row.requires_halal_cert ?? false,
    isManaged:             row.is_managed ?? false,
    updatedAt:             row.updated_at ?? null,
    lastAnalysedAt:        row.last_analysed_at ?? null,
    geminiWebIngredientLookupAttemptedForName: isGeminiWebIngredientLookupDoneForProductName(
      row,
      String(row.name ?? ''),
    ),
    keywordMatchSource:    row.keyword_match_source ?? null,
    keywordMatchOrigins:   row.keyword_match_origins ?? {},
    analyzeLang:           row.analyze_lang ?? null,
    displayLang:           row.display_lang ?? null,
    brand:                 row.brand ?? '',
    quantity:              row.quantity ?? '',
    categoriesTags:        row.categories_tags ?? [],
    additivesTags:         row.additives_tags ?? [],
    allergensTags:         row.allergens_tags ?? [],
    tracesTags:            row.traces_tags ?? [],
    tagsPopulated:         (row.tags_version ?? 0) > 0,
  }
}

// deno-lint-ignore no-explicit-any
export function isStale(row: Record<string, any>): boolean {
  if (!row.updated_at) return false
  if (!row.last_analysed_at) return true
  return new Date(row.last_analysed_at) < new Date(row.updated_at)
}
