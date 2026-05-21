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
  }
}

// deno-lint-ignore no-explicit-any
export function isStale(row: Record<string, any>): boolean {
  if (!row.updated_at) return false
  if (!row.last_analysed_at) return true
  return new Date(row.last_analysed_at) < new Date(row.updated_at)
}
