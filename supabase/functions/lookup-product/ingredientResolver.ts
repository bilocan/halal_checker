import { geminiIngredientLookup } from './ai.ts'
import {
  isGeminiWebIngredientLookupDoneForProductName,
  normalizeProductNameForGeminiKey,
  shouldRunGeminiIngredientLookup,
} from './ingredient_lookup_gate.ts'
import type { HalalScanProduct } from './productQueries.ts'

export type IngredientSource = 'off' | 'ai' | 'community'

export interface ResolveGeminiIngredientsInput {
  barcode: string
  name: string
  brand: string
  ingredients: string[]
  ingredientSource: IngredientSource
  existing: HalalScanProduct | null
  geminiAutoEmptyOff: boolean
  fetchAiIngredients: boolean
  hasApprovedAiRequest: boolean
}

export interface ResolveGeminiIngredientsResult {
  ingredients: string[]
  ingredientSource: IngredientSource
  geminiAt?: string
  geminiNameKey?: string
}

/**
 * When OFF (or DB stub) has no ingredients, optionally run Gemini web ingredient lookup.
 * Records lookup timestamp + normalized name key when a lookup is attempted.
 */
export async function resolveGeminiIngredients(
  input: ResolveGeminiIngredientsInput,
): Promise<ResolveGeminiIngredientsResult> {
  const {
    barcode, name, brand, existing, geminiAutoEmptyOff, fetchAiIngredients, hasApprovedAiRequest,
  } = input
  let { ingredients, ingredientSource } = input
  let geminiAt = existing?.gemini_web_ingredient_lookup_at as string | undefined
  let geminiNameKey = existing?.gemini_web_ingredient_lookup_name_key as string | undefined

  if (!shouldRunGeminiIngredientLookup({
    autoLookupEmptyOff: geminiAutoEmptyOff,
    fetchAiIngredients,
    hasApprovedRequest: hasApprovedAiRequest,
    offIngredientCount: ingredients.length,
    productName: name,
  })) {
    if (ingredients.length === 0 && name !== 'Unknown Product') {
      const skipReason = geminiAutoEmptyOff
        ? 'preconditions not met'
        : !fetchAiIngredients
        ? 'requires fetchAiIngredients after admin approval, or enable gemini_lookup_empty_off (superadmin / env)'
        : !hasApprovedAiRequest
        ? 'no approved ai_ingredient_requests row'
        : 'preconditions not met'
      console.log(`[${barcode}] Gemini ingredient lookup: skipped — ${skipReason}`)
    }
    return { ingredients, ingredientSource, geminiAt, geminiNameKey }
  }

  if (isGeminiWebIngredientLookupDoneForProductName(existing, name)) {
    console.log(
      `[${barcode}] Gemini web ingredient lookup: skipped — already attempted for this product name`,
    )
    return { ingredients, ingredientSource, geminiAt, geminiNameKey }
  }

  const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
  const geminiKey = Deno.env.get('GEMINI_API_KEY')
  if (!geminiEnabled) {
    console.log(`[${barcode}] Gemini ingredient lookup: skipped — disabled by GEMINI_ENABLED=false`)
    return { ingredients, ingredientSource, geminiAt, geminiNameKey }
  }
  if (!geminiKey) {
    console.log(`[${barcode}] Gemini ingredient lookup: skipped — GEMINI_API_KEY not set`)
    return { ingredients, ingredientSource, geminiAt, geminiNameKey }
  }

  try {
    const found = await geminiIngredientLookup(name, barcode, geminiKey, brand)
    if (found.length > 0) {
      ingredients = found
      ingredientSource = 'ai'
    }
  } finally {
    geminiAt = new Date().toISOString()
    geminiNameKey = normalizeProductNameForGeminiKey(name)
  }

  return { ingredients, ingredientSource, geminiAt, geminiNameKey }
}
