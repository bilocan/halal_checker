// Request orchestration (testable). Verdict steps: VERDICT_PIPELINE.md + verdictRules.ts
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { toProduct, isStale } from './db.ts'
import {
  fetchOpenFactsProduct,
  parseOffBrand,
  parseOffLabels,
  parseOffProductName,
  parseOffTags,
  resolveImg,
} from './fetch.ts'
import { resolveOffIngredientAnalysis } from './ingredientResolution.ts'
import { getApprovedContribution, withCommunitySource } from './community.ts'
import {
  hasApprovedAiIngredientRequest,
  resolveGeminiLookupEmptyOffEnabled,
  shouldBypassCacheForGeminiAutoLookup,
} from './ingredient_lookup_gate.ts'
import { resolveGeminiIngredients } from './ingredientResolver.ts'
import { classifyOffCategories, normalizeStoredLabels } from './lookupHelpers.ts'
import { computeVerdict } from './verdictRules.ts'
import type { KeywordEntry } from './keyword.ts'
import {
  jsonResponse,
  patchProductTags,
  persistLookupAndRespond,
  type AnalysisRow,
  type ProductRow,
} from './persistence.ts'
import { parseRequest } from './requestParser.ts'
import type { LookupRequest } from './requestParser.ts'
import { getHalalScanProduct, loadCustomKeywords } from './productQueries.ts'
import type { HalalScanProduct } from './productQueries.ts'
import { jsonManagedProduct, runStoredProductReanalysis } from './reanalysis.ts'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

export interface LookupDeps {
  supabase: SupabaseClient
  fetchOpenFactsProduct: typeof fetchOpenFactsProduct
  resolveGeminiLookupEmptyOffEnabled: typeof resolveGeminiLookupEmptyOffEnabled
  getHalalScanProduct: typeof getHalalScanProduct
  loadCustomKeywords: typeof loadCustomKeywords
  getApprovedContribution: typeof getApprovedContribution
  hasApprovedAiIngredientRequest: typeof hasApprovedAiIngredientRequest
  resolveGeminiIngredients: typeof resolveGeminiIngredients
  computeVerdict: typeof computeVerdict
  runStoredProductReanalysis: typeof runStoredProductReanalysis
  jsonManagedProduct: typeof jsonManagedProduct
}

export function createLookupDeps(supabase: SupabaseClient): LookupDeps {
  return {
    supabase,
    fetchOpenFactsProduct,
    resolveGeminiLookupEmptyOffEnabled,
    getHalalScanProduct,
    loadCustomKeywords,
    getApprovedContribution,
    hasApprovedAiIngredientRequest,
    resolveGeminiIngredients,
    computeVerdict,
    runStoredProductReanalysis,
    jsonManagedProduct,
  }
}

/** HTTP entry: parse JSON body, run lookup orchestration. */
export async function handleLookupRequest(req: Request, deps: LookupDeps): Promise<Response> {
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

  try {
    return await handleLookup(parsedRequest, deps)
  } catch (err) {
    console.error(err)
    return jsonResponse({ error: String(err) }, 500, corsHeaders)
  }
}

/** Core barcode lookup flow (inject deps for tests). */
export async function handleLookup(
  parsedRequest: LookupRequest,
  deps: LookupDeps,
): Promise<Response> {
  const { barcode, force = false, fetchAiIngredients = false } = parsedRequest
  const { supabase } = deps

  const existing = await deps.getHalalScanProduct(supabase, barcode)

  const geminiAutoEmptyOff = await deps.resolveGeminiLookupEmptyOffEnabled(supabase)
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
    return deps.jsonManagedProduct(existing, corsHeaders)
  }

  // Protect AI/community ingredients — OFF has dummy/worse data for those products.
  const hasNonOffIngredients = existing?.ingredient_source === 'ai' ||
    existing?.ingredient_source === 'community'
  const hasStoredIngredients = Array.isArray(existing?.ingredients) &&
    (existing.ingredients as string[]).length > 0
  const isUnknownOff = !!(existing?.is_unknown && !hasNonOffIngredients && !hasStoredIngredients)
  // Stale, force-refresh, or unknown+OFF with stored tags: re-run rules on stored data.
  // No OFF refetch — stored categories_tags drive halal-by-category.
  // Unknown+OFF rows without stored tags fall through to the tag-backfill path below.
  const hasStoredTags = (existing?.tags_version ?? 0) > 0
  if (!fetchAiIngredients && !refetchForGeminiAuto && existing &&
      (isStale(existing) || force || (isUnknownOff && hasStoredTags))) {
    const reason = isStale(existing) ? 'stale (updated_at > last_analysed_at)' : 'force-refresh'
    console.log(`[${barcode}] ${reason} — re-running rules engine on stored data`)
    const { haram: customHaramEntries, suspicious: customSuspiciousEntries } =
      await deps.loadCustomKeywords(supabase)
    // Backfill tags during force/stale if tags_version=0 — tags patch is skipped on the
    // normal path because force intercepts first, so we do it here before reanalysis.
    if (!hasStoredTags && !hasNonOffIngredients && !existing.is_managed) {
      const off = await deps.fetchOpenFactsProduct(barcode)
      if (off?.pd) {
        const tags = parseOffTags(off.pd)
        await patchProductTags(supabase, barcode, tags)
        Object.assign(existing, {
          brand: tags.brand, quantity: tags.quantity,
          categories_tags: tags.categoriesTags,
          additives_tags: tags.additivesTags,
          allergens_tags: tags.allergensTags,
          traces_tags: tags.tracesTags,
          tags_version: 1,
        })
        console.log(`[${barcode}] patched tags during ${reason}`)
      }
    }
    return deps.runStoredProductReanalysis(
      supabase, existing, barcode, customHaramEntries, customSuspiciousEntries, corsHeaders,
    )
  }

  if (!fetchAiIngredients && !refetchForGeminiAuto && existing && !force) {
    const communityIngredients = await deps.getApprovedContribution(supabase, barcode)
    const storedIngredients: string[] = communityIngredients
      ?? (Array.isArray(existing.ingredients) ? existing.ingredients as string[] : [])
    const visionUrlRaw = existing.image_ingredients_url as string | null | undefined
    const visionUrl = typeof visionUrlRaw === 'string' ? visionUrlRaw.trim() : ''
    const needsVisionIngredients = storedIngredients.length === 0 && visionUrl !== ''
    // Re-fetch OFF when tags have never been populated (pre-migration rows have tags_version=0).
    // Skipped for managed/AI/community products — those don't use OFF tags.
    const needsTagFetch = (existing.tags_version ?? 0) === 0 && !hasNonOffIngredients && !existing.is_managed
    if (!needsVisionIngredients && !isUnknownOff && !needsTagFetch) {
      return jsonResponse(
        { product: toProduct(withCommunitySource(existing, communityIngredients)) },
        200,
        corsHeaders,
      )
    }
    // Tags-only backfill: fetch OFF for tag columns only — never touch ingredients or
    // analysis for existing Supabase products, regardless of unknown/known status.
    if (needsTagFetch && !needsVisionIngredients) {
      console.log(`[${barcode}] tags_version=0 — fetching OFF tags only, preserving stored ingredients`)
      const off = await deps.fetchOpenFactsProduct(barcode)
      if (off?.pd) {
        const tags = parseOffTags(off.pd)
        await patchProductTags(supabase, barcode, tags)
        return jsonResponse(
          { product: toProduct({ ...withCommunitySource(existing, communityIngredients), ...tags, tags_version: 1 }) },
          200,
          corsHeaders,
        )
      }
      // OFF unavailable — serve existing product; tags_version stays 0 so next scan retries.
      console.log(`[${barcode}] OFF unavailable for tag fetch — serving existing, will retry`)
      return jsonResponse(
        { product: toProduct(withCommunitySource(existing, communityIngredients)) },
        200,
        corsHeaders,
      )
    }
    if (!needsVisionIngredients) {
      console.log(`[${barcode}] unknown+OFF — re-fetching OFF for halal-by-category detection`)
    } else {
      console.log(`[${barcode}] DB stub has ingredient image — running vision/analysis path`)
    }
  }

  const { haram: customHaramEntries, suspicious: customSuspiciousEntries } =
    await deps.loadCustomKeywords(supabase)

    let pd: Record<string, unknown> | null = null
    let isNonFood = false
    // Only fetch OFF for brand-new products (no existing DB row).
    // Existing products always use stored data — ingredients are never overwritten from OFF.
    if (!existing) {
      const off = await deps.fetchOpenFactsProduct(barcode)
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
      deps, existing, barcode, fetchAiIngredients, geminiAutoEmptyOff,
      customHaramEntries, customSuspiciousEntries,
    )
  }

  const name = parseOffProductName(pd)
  const brand = parseOffBrand(pd)
  const resolved = resolveOffIngredientAnalysis(pd)
  let ingredients = resolved.display
  let analyzeSources = resolved.sources
  let displayLang = resolved.displayLang
  let analyzeLang = resolved.analyzeLang
  let ingredientSource: 'off' | 'ai' | 'community' = 'off'

  console.log(`[${barcode}] OFF: name="${name}" brand="${brand}" ingredients=${ingredients.length}`)

  const approvedAiRequest = fetchAiIngredients
    ? await deps.hasApprovedAiIngredientRequest(supabase, barcode)
    : false

  const geminiResolved = await deps.resolveGeminiIngredients({
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
  if (ingredientSource === 'ai') {
    analyzeSources = [{ key: 'primary', ingredients }]
    displayLang = ''
    analyzeLang = null
  }

  const communityIngredients = await deps.getApprovedContribution(supabase, barcode)
  if (communityIngredients) {
    ingredients = communityIngredients
    analyzeSources = [{ key: 'primary', ingredients: communityIngredients }]
    displayLang = ''
    analyzeLang = null
    ingredientSource = 'community'
    console.log(`[${barcode}] community override: ${ingredients.length} ingredients`)
  }

  const labels = parseOffLabels(pd)
  const rawCategories: string[] = Array.isArray(pd.categories_tags) ? pd.categories_tags as string[] : []
  const offAdditivesTags: string[] = Array.isArray(pd.additives_tags) ? pd.additives_tags as string[] : []
  const offAllergensTags: string[] = Array.isArray(pd.allergens_tags) ? pd.allergens_tags as string[] : []
  const offTracesTags: string[] = Array.isArray(pd.traces_tags) ? pd.traces_tags as string[] : []
  const offQuantity: string = typeof pd.quantity === 'string' ? pd.quantity.trim() : ''
  const classified = classifyOffCategories(rawCategories, isNonFood)
  isNonFood = classified.isNonFood

  console.log(
    `[${barcode}] ingredients: source=${ingredientSource} count=${ingredients.length} ` +
    `list=[${ingredients.slice(0, 10).join(' | ')}${ingredients.length > 10 ? '…' : ''}]`,
  )

  const verdict = await deps.computeVerdict({
    barcode,
    ingredients,
    analyzeSources,
    displayLang,
    analyzeLang,
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
    supabase, barcode, name, verdict.ingredients, ingredientSource,
    verdict, classified.isNonFood, labels, images,
    existing?.fetched_at as string | undefined,
    geminiResolved.geminiAt, geminiResolved.geminiNameKey,
    false,
    {
      brand, quantity: offQuantity,
      categoriesTags: rawCategories,
      additivesTags: offAdditivesTags,
      allergensTags: offAllergensTags,
      tracesTags: offTracesTags,
    },
  )
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

async function analyzeFromDbStub(
  deps: LookupDeps,
  existing: HalalScanProduct,
  barcode: string,
  fetchAiIngredients: boolean,
  geminiAutoEmptyOff: boolean,
  customHaramEntries: KeywordEntry[],
  customSuspiciousEntries: KeywordEntry[],
): Promise<Response> {
  const { supabase } = deps
  console.log(`[${barcode}] OFF miss — analysing from Supabase DB (approved pack-photo stub or curated row)`)

  const name = typeof existing.name === 'string' && existing.name.trim().length > 0
    ? existing.name.trim()
    : 'Unknown Product'
  const brand = ''
  const communityDb = await deps.getApprovedContribution(supabase, barcode)
  let ingredientSource: 'off' | 'ai' | 'community' = 'off'
  let ingredients: string[] =
    communityDb ?? (Array.isArray(existing.ingredients) ? existing.ingredients as string[] : [])
  if (communityDb) {
    ingredientSource = 'community'
  } else if (existing.ingredient_source === 'ai' || existing.ingredient_source === 'community') {
    ingredientSource = existing.ingredient_source as 'ai' | 'community'
  }

  const approvedAiRequestStub = fetchAiIngredients
    ? await deps.hasApprovedAiIngredientRequest(supabase, barcode)
    : false

  const geminiResolved = await deps.resolveGeminiIngredients({
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
  const rawCategories: string[] = Array.isArray(existing.categories_tags)
    ? existing.categories_tags as string[]
    : []
  const isNonFoodBase = !!(existing.is_non_food ?? false)
  const classified = classifyOffCategories(rawCategories, isNonFoodBase)
  const isNonFood = classified.isNonFood

  console.log(`[${barcode}] DB stub name="${name}" ingredients=${ingredients.length}`)
  console.log(
    `[${barcode}] ingredients: source=${ingredientSource} count=${ingredients.length} ` +
    `list=[${ingredients.slice(0, 10).join(' | ')}${ingredients.length > 10 ? '…' : ''}]`,
  )

  const displayLang = typeof existing.display_lang === 'string'
    ? existing.display_lang
    : ''
  const analyzeSources = ingredients.length > 0
    ? [{ key: 'primary' as const, ingredients }]
    : []

  const verdict = await deps.computeVerdict({
    barcode,
    ingredients,
    analyzeSources,
    displayLang,
    analyzeLang: null,
    name,
    labels,
    rawCategories,
    isNonFood,
    ingredientSource,
    haramCategory: classified.haramCategory,
    isHalalByCategory: classified.isHalalByCategory,
    customHaramEntries,
    customSuspiciousEntries,
    imageIngredientsUrl: typeof existing.image_ingredients_url === 'string'
      ? existing.image_ingredients_url.trim()
      : '',
  })

  const images = productImagesFromExisting(existing)
  return saveFullLookup(
    supabase, barcode, name, verdict.ingredients, ingredientSource,
    verdict, isNonFood, labels, images,
    existing.fetched_at as string | undefined,
    geminiResolved.geminiAt, geminiResolved.geminiNameKey,
    (existing.is_managed ?? false) as boolean,
  )
}

async function saveFullLookup(
  supabase: SupabaseClient,
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
  offTags: {
    brand?: string; quantity?: string
    categoriesTags?: string[]; additivesTags?: string[]
    allergensTags?: string[]; tracesTags?: string[]
  } = {},
): Promise<Response> {
  const {
    isHalal, isUnknown, haramIngredients, suspiciousIngredients,
    ingredientWarnings, haramLabels, suspiciousLabels, labelWarnings,
    explanation, analyzedByAI, requiresHalalCert,
    keywordMatchSource, keywordMatchOrigins, analyzeLang, displayLang,
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
    displayLang: displayLang ?? '',
    brand:          offTags.brand ?? '',
    quantity:       offTags.quantity ?? '',
    categoriesTags: offTags.categoriesTags ?? [],
    additivesTags:  offTags.additivesTags ?? [],
    allergensTags:  offTags.allergensTags ?? [],
    tracesTags:     offTags.tracesTags ?? [],
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
    explanation,
    analyzedByAI,
    keywordMatchSource,
    keywordMatchOrigins,
    analyzeLang,
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
    haram_labels: haramLabels,
    suspicious_labels: suspiciousLabels,
    label_warnings: labelWarnings,
    labels,
    image_url: images.imageUrl,
    image_front_url: images.imageFrontUrl,
    image_ingredients_url: images.imageIngredientsUrl,
    image_nutrition_url: images.imageNutritionUrl,
    explanation,
    analyzed_by_ai: analyzedByAI,
    requires_halal_cert: requiresHalalCert,
    keyword_match_source: keywordMatchSource ?? null,
    keyword_match_origins: keywordMatchOrigins ?? {},
    analyze_lang: analyzeLang ?? null,
    display_lang: displayLang || null,
    last_analysed_at: new Date().toISOString(),
    fetched_at: productRow.fetchedAt,
    gemini_web_ingredient_lookup_at: geminiAt ?? null,
    gemini_web_ingredient_lookup_name_key: geminiNameKey ?? null,
    brand:           offTags.brand ?? '',
    quantity:        offTags.quantity ?? '',
    categories_tags: offTags.categoriesTags ?? [],
    additives_tags:  offTags.additivesTags ?? [],
    allergens_tags:  offTags.allergensTags ?? [],
    traces_tags:     offTags.tracesTags ?? [],
  }

  return persistLookupAndRespond(supabase, corsHeaders, productRow, analysisRow, fallbackRow)
}
