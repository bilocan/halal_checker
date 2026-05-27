// Request orchestration for barcode lookup. Verdict steps: VERDICT_PIPELINE.md + verdictRules.ts
import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { toProduct, isStale } from './db.ts'
import {
  fetchOpenFactsProduct,
  parseOffBrand,
  parseOffIngredientList,
  parseOffLabels,
  parseOffProductName,
  resolveImg,
} from './fetch.ts'
import { getApprovedContribution, withCommunitySource } from './community.ts'
import {
  hasApprovedAiIngredientRequest,
  resolveGeminiLookupEmptyOffEnabled,
  shouldBypassCacheForGeminiAutoLookup,
} from './ingredient_lookup_gate.ts'
import { resolveGeminiIngredients } from './ingredientResolver.ts'
import { classifyOffCategories, normalizeStoredLabels } from './lookupHelpers.ts'
import { computeVerdict } from './verdictRules.ts'
import {
  jsonResponse,
  persistLookupAndRespond,
  type AnalysisRow,
  type ProductRow,
} from './persistence.ts'
import { parseRequest } from './requestParser.ts'
import type { LookupRequest } from './requestParser.ts'
import { getHalalScanProduct, loadCustomKeywords } from './productQueries.ts'
import type { HalalScanProduct } from './productQueries.ts'
import { jsonManagedProduct, runStoredProductReanalysis } from './reanalysis.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// deno-lint-ignore no-explicit-any
function productImagesFromExisting(existing: HalalScanProduct | null, pd?: any) {
  return {
    imageUrl: (existing?.image_url ?? (pd ? resolveImg(pd, 'image_url', 'front') : null)) as string | undefined,
    imageFrontUrl: (existing?.image_front_url ?? (pd ? resolveImg(pd, 'image_front_url', 'front') : null)) as string | undefined,
    imageIngredientsUrl: (existing?.image_ingredients_url ?? (pd ? resolveImg(pd, 'image_ingredients_url', 'ingredients') : null)) as string | undefined,
    imageNutritionUrl: (existing?.image_nutrition_url ?? (pd ? resolveImg(pd, 'image_nutrition_url', 'nutrition') : null)) as string | undefined,
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  let parsedRequest: LookupRequest
  try {
    parsedRequest = parseRequest(await req.json())
  } catch (err) {
    return jsonResponse(
      { error: err instanceof Error ? err.message : String(err) },
      400,
      corsHeaders,
    )
  }
  const { barcode, force = false, fetchAiIngredients = false } = parsedRequest

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const existing = await getHalalScanProduct(supabase, barcode)

    const geminiAutoEmptyOff = await resolveGeminiLookupEmptyOffEnabled(supabase)
    const refetchForGeminiAuto = shouldBypassCacheForGeminiAutoLookup(existing, {
      autoLookupEmptyOff: geminiAutoEmptyOff,
      fetchAiIngredients,
      force,
    })
    console.log(
      `[${barcode}] request: force=${force} fetchAiIngredients=${fetchAiIngredients} ` +
      `geminiAutoEmptyOff=${geminiAutoEmptyOff} refetchForGeminiAuto=${refetchForGeminiAuto}`,
    )

    console.log(`[${barcode}] db: ${existing ? `found (is_managed=${existing.is_managed} is_unknown=${existing.is_unknown} ingredient_source=${existing.ingredient_source} ingredients=${Array.isArray(existing.ingredients) ? existing.ingredients.length : 0})` : 'not found'}`)

    if (existing?.is_managed) {
      console.log(`[${barcode}] managed product — returning DB row as-is`)
      return jsonManagedProduct(existing, corsHeaders)
    }

    if (!fetchAiIngredients && !refetchForGeminiAuto && existing &&
        (isStale(existing) || (force && !existing.is_unknown))) {
      const reason = isStale(existing) ? 'stale (updated_at > last_analysed_at)' : 'force-refresh'
      console.log(`[${barcode}] ${reason} — re-running rules engine on stored data`)
      const { haram: customHaramEntries, suspicious: customSuspiciousEntries } = await loadCustomKeywords(supabase)
      return runStoredProductReanalysis(
        supabase, existing, barcode, customHaramEntries, customSuspiciousEntries, corsHeaders,
      )
    }

    if (!fetchAiIngredients && !refetchForGeminiAuto && existing && !force) {
      const communityIngredients = await getApprovedContribution(supabase, barcode)
      const storedIngredients: string[] = communityIngredients
        ?? (Array.isArray(existing.ingredients) ? existing.ingredients as string[] : [])
      const visionUrlRaw = existing.image_ingredients_url as string | null | undefined
      const visionUrl = typeof visionUrlRaw === 'string' ? visionUrlRaw.trim() : ''
      const needsVisionIngredients = storedIngredients.length === 0 && visionUrl !== ''
      if (!needsVisionIngredients) {
        return jsonResponse(
          { product: toProduct(withCommunitySource(existing, communityIngredients)) },
          200,
          corsHeaders,
        )
      }
      console.log(`[${barcode}] DB stub has ingredient image — running vision/analysis path`)
    }

    const { haram: customHaramEntries, suspicious: customSuspiciousEntries } = await loadCustomKeywords(supabase)

    let pd: Record<string, unknown> | null = null
    let isNonFood = false
    if (!existing) {
      const off = await fetchOpenFactsProduct(barcode)
      if (off) {
        pd = off.pd
        isNonFood = off.isNonFood
      }
    }

    if (!pd) {
      if (!existing) {
        return jsonResponse({ product: null }, 200, corsHeaders)
      }
      return analyzeFromDbStub(
        supabase, existing, barcode, fetchAiIngredients, geminiAutoEmptyOff,
        customHaramEntries, customSuspiciousEntries, corsHeaders,
      )
    }

    const name = parseOffProductName(pd)
    const brand = parseOffBrand(pd)
    let ingredients = parseOffIngredientList(pd)
    let ingredientSource: 'off' | 'ai' | 'community' = 'off'

    console.log(`[${barcode}] OFF: name="${name}" brand="${brand}" ingredients=${ingredients.length}`)

    const approvedAiRequest = fetchAiIngredients
      ? await hasApprovedAiIngredientRequest(supabase, barcode)
      : false

    const geminiResolved = await resolveGeminiIngredients({
      barcode,
      name,
      brand,
      ingredients,
      ingredientSource,
      existing,
      geminiAutoEmptyOff,
      fetchAiIngredients,
      hasApprovedAiRequest: approvedAiRequest,
    })
    ingredients = geminiResolved.ingredients
    ingredientSource = geminiResolved.ingredientSource

    const communityIngredients = await getApprovedContribution(supabase, barcode)
    if (communityIngredients) {
      ingredients = communityIngredients
      ingredientSource = 'community'
      console.log(`[${barcode}] community override: ${ingredients.length} ingredients`)
    }

    const labels = parseOffLabels(pd)
    const rawCategories: string[] = Array.isArray(pd.categories_tags) ? pd.categories_tags as string[] : []
    const classified = classifyOffCategories(rawCategories, isNonFood)
    isNonFood = classified.isNonFood

    console.log(
      `[${barcode}] ingredients: source=${ingredientSource} count=${ingredients.length} ` +
      `list=[${ingredients.slice(0, 10).join(' | ')}${ingredients.length > 10 ? '…' : ''}]`,
    )

    const verdict = await computeVerdict({
      barcode,
      ingredients,
      name,
      labels,
      rawCategories,
      isNonFood,
      ingredientSource,
      haramCategory: classified.haramCategory,
      isHalalByCategory: classified.isHalalByCategory,
      customHaramEntries,
      customSuspiciousEntries,
      imageIngredientsUrl: resolveImg(pd, 'image_ingredients_url', 'ingredients') || '',
    })

    const images = productImagesFromExisting(existing, pd)
    return saveFullLookup(
      supabase, corsHeaders, barcode, name, verdict.ingredients, ingredientSource,
      verdict, classified.isNonFood, labels, images,
      existing?.fetched_at as string | undefined,
      geminiResolved.geminiAt, geminiResolved.geminiNameKey,
    )
  } catch (err) {
    console.error(err)
    return jsonResponse({ error: String(err) }, 500, corsHeaders)
  }
})

async function analyzeFromDbStub(
  supabase: SupabaseClient,
  existing: HalalScanProduct,
  barcode: string,
  fetchAiIngredients: boolean,
  geminiAutoEmptyOff: boolean,
  customHaramEntries: import('./keyword.ts').KeywordEntry[],
  customSuspiciousEntries: import('./keyword.ts').KeywordEntry[],
  corsHeaders: Record<string, string>,
): Promise<Response> {
  console.log(`[${barcode}] OFF miss — analysing from Supabase DB (approved pack-photo stub or curated row)`)

  let name = typeof existing.name === 'string' && existing.name.trim().length > 0
    ? existing.name.trim()
    : 'Unknown Product'
  const brand = ''
  const communityDb = await getApprovedContribution(supabase, barcode)
  let ingredientSource: 'off' | 'ai' | 'community' = 'off'
  let ingredients: string[] =
    communityDb ?? (Array.isArray(existing.ingredients) ? existing.ingredients as string[] : [])
  if (communityDb) {
    ingredientSource = 'community'
  } else if (existing.ingredient_source === 'ai' || existing.ingredient_source === 'community') {
    ingredientSource = existing.ingredient_source as 'ai' | 'community'
  }

  const approvedAiRequestStub = fetchAiIngredients
    ? await hasApprovedAiIngredientRequest(supabase, barcode)
    : false

  const geminiResolved = await resolveGeminiIngredients({
    barcode,
    name,
    brand,
    ingredients,
    ingredientSource,
    existing,
    geminiAutoEmptyOff,
    fetchAiIngredients,
    hasApprovedAiRequest: approvedAiRequestStub,
  })
  ingredients = geminiResolved.ingredients
  ingredientSource = geminiResolved.ingredientSource

  if (communityDb) {
    ingredients = communityDb
    ingredientSource = 'community'
  }

  const labels = normalizeStoredLabels(existing.labels)
  const isNonFood = !!(existing.is_non_food ?? false)

  console.log(`[${barcode}] DB stub name="${name}" ingredients=${ingredients.length}`)
  console.log(
    `[${barcode}] ingredients: source=${ingredientSource} count=${ingredients.length} ` +
    `list=[${ingredients.slice(0, 10).join(' | ')}${ingredients.length > 10 ? '…' : ''}]`,
  )

  const verdict = await computeVerdict({
    barcode,
    ingredients,
    name,
    labels,
    rawCategories: [],
    isNonFood,
    ingredientSource,
    haramCategory: null,
    isHalalByCategory: false,
    customHaramEntries,
    customSuspiciousEntries,
    imageIngredientsUrl: typeof existing.image_ingredients_url === 'string'
      ? existing.image_ingredients_url.trim()
      : '',
  })

  const images = productImagesFromExisting(existing)
  return saveFullLookup(
    supabase, corsHeaders, barcode, name, verdict.ingredients, ingredientSource,
    verdict, isNonFood, labels, images,
    existing.fetched_at as string | undefined,
    geminiResolved.geminiAt, geminiResolved.geminiNameKey,
    (existing.is_managed ?? false) as boolean,
  )
}

async function saveFullLookup(
  supabase: SupabaseClient,
  corsHeaders: Record<string, string>,
  barcode: string,
  name: string,
  ingredients: string[],
  ingredientSource: 'off' | 'ai' | 'community',
  verdict: Awaited<ReturnType<typeof computeVerdict>>,
  isNonFood: boolean,
  labels: string[],
  images: ReturnType<typeof productImagesFromExisting>,
  fetchedAt?: string,
  geminiAt?: string,
  geminiNameKey?: string,
  isManaged = false,
): Promise<Response> {
  const {
    isHalal, isUnknown, haramIngredients, suspiciousIngredients,
    ingredientWarnings, explanation, analyzedByAI, requiresHalalCert,
  } = verdict

  const productRow: ProductRow = {
    barcode,
    name,
    ingredients,
    ingredientSource,
    isNonFood,
    labels,
    ...images,
    requiresHalalCert,
    isManaged: isManaged || undefined,
    fetchedAt: fetchedAt ?? new Date().toISOString(),
    geminiAt,
    geminiNameKey,
  }

  const analysisRow: AnalysisRow = {
    barcode,
    isHalal,
    isUnknown,
    isNonFood,
    haramIngredients,
    suspiciousIngredients,
    ingredientWarnings,
    explanation,
    analyzedByAI,
  }

  const fallbackRow = {
    barcode,
    name,
    ingredients,
    ingredient_source: ingredientSource,
    is_halal: isHalal,
    is_unknown: isUnknown,
    is_non_food: isNonFood,
    haram_ingredients: haramIngredients,
    suspicious_ingredients: suspiciousIngredients,
    ingredient_warnings: ingredientWarnings,
    labels,
    image_url: images.imageUrl,
    image_front_url: images.imageFrontUrl,
    image_ingredients_url: images.imageIngredientsUrl,
    image_nutrition_url: images.imageNutritionUrl,
    explanation,
    analyzed_by_ai: analyzedByAI,
    requires_halal_cert: requiresHalalCert,
    last_analysed_at: new Date().toISOString(),
    fetched_at: productRow.fetchedAt,
    gemini_web_ingredient_lookup_at: geminiAt ?? null,
    gemini_web_ingredient_lookup_name_key: geminiNameKey ?? null,
  }

  return persistLookupAndRespond(supabase, corsHeaders, productRow, analysisRow, fallbackRow)
}
