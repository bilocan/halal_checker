import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { keywordAnalysis } from './keyword.ts'
import { HARAM_CATEGORIES, HALAL_CATEGORIES, NON_FOOD_CATEGORIES } from './categories.ts'
import { fetchFromFoodApi, extractIngredientsText, resolveImg, OFF_BASE, OBF_BASE, OPF_BASE } from './fetch.ts'
import { toProduct, isStale } from './db.ts'
import { getApprovedContribution, withCommunitySource } from './community.ts'
import {
  hasApprovedAiIngredientRequest,
  resolveGeminiLookupEmptyOffEnabled,
  shouldBypassCacheForGeminiAutoLookup,
  shouldRunGeminiIngredientLookup,
  isGeminiWebIngredientLookupDoneForProductName,
  normalizeProductNameForGeminiKey,
} from './ingredient_lookup_gate.ts'
import { geminiIngredientLookup } from './ai.ts'
import { computeVerdict } from './verdict.ts'
import { upsertProduct, upsertAnalysis } from './persistence.ts'
import { parseRequest } from './requestParser.ts'
import type { LookupRequest } from './requestParser.ts'
import { getHalalScanProduct, loadCustomKeywords } from './productQueries.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  let parsedRequest: LookupRequest
  try {
    parsedRequest = parseRequest(await req.json())
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
  const { barcode, force = false, fetchAiIngredients = false } = parsedRequest

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // 1. Supabase product lookup
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

    // Managed products are never overwritten by OFF data.
    // Return the DB row as-is regardless of the force flag.
    if (existing?.is_managed) {
      console.log(`[${barcode}] managed product — returning DB row as-is`)
      return new Response(
        JSON.stringify({ product: toProduct(existing) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Re-run keyword analysis on stored data when either:
    //   • source data changed since last analysis (updated_at > last_analysed_at), OR
    //   • caller requested a force refresh on an already-known product.
    // OFF is only ever fetched on the very first scan (existing === null below).
    // Unknown products with force=true fall through so OFF can be retried.
    // fetchAiIngredients bypasses the DB lookup so admin-approved Gemini lookup can re-fetch OFF.
    if (!fetchAiIngredients && !refetchForGeminiAuto && existing &&
        (isStale(existing) || (force && !existing.is_unknown))) {
      const reason = isStale(existing) ? 'stale (updated_at > last_analysed_at)' : 'force-refresh'
      console.log(`[${barcode}] ${reason} — re-running rules engine on stored data`)

      const { haram: reHaramEntries, suspicious: reSuspiciousEntries } = await loadCustomKeywords(supabase)

      const communityIngredients = await getApprovedContribution(supabase, barcode)
      const storedIngredients: string[] = communityIngredients
        ?? (Array.isArray(existing.ingredients) ? existing.ingredients : [])
      const resolvedSource = communityIngredients
        ? 'community'
        : (existing.ingredient_source ?? 'off')
      const kw = keywordAnalysis(storedIngredients, reHaramEntries, reSuspiciousEntries)
      console.log(`[${barcode}] re-analysis result: isHalal=${kw.isHalal} isUnknown=${kw.isUnknown} haram=[${kw.haram.join(', ')}] suspicious=[${kw.suspicious.join(', ')}] ingredients=${storedIngredients.length}`)

      let reHalal       = kw.isHalal
      let reUnknown     = kw.isUnknown
      let reHaram       = kw.haram
      let reSuspicious  = kw.suspicious
      let reWarnings    = kw.warnings
      let reExplanation = kw.explanation

      if (reUnknown) {
        const nameKw = keywordAnalysis([(existing.name ?? '').toLowerCase()], reHaramEntries, reSuspiciousEntries)
        if (!nameKw.isHalal) {
          reHalal = false; reUnknown = false
          reHaram = nameKw.haram; reWarnings = nameKw.warnings
          reExplanation = `No ingredient list found, but the product name contains a haram indicator: ${nameKw.haram.join(', ')}.`
        }
      }

      const reRow = {
        barcode:               existing.barcode,
        name:                  existing.name,
        ingredients:           storedIngredients,
        is_halal:              reHalal,
        is_unknown:            reUnknown,
        is_non_food:           existing.is_non_food,
        haram_ingredients:     reHaram,
        suspicious_ingredients: reSuspicious,
        ingredient_warnings:   reWarnings,
        labels:                existing.labels,
        image_url:             existing.image_url,
        image_front_url:       existing.image_front_url,
        image_ingredients_url: existing.image_ingredients_url,
        image_nutrition_url:   existing.image_nutrition_url,
        explanation:           reExplanation,
        analyzed_by_ai:        false,
        requires_halal_cert:   existing.requires_halal_cert,
        is_managed:            existing.is_managed,
        last_analysed_at:      new Date().toISOString(),
        fetched_at:            existing.fetched_at,
        ingredient_source:     resolvedSource,
        gemini_web_ingredient_lookup_at:
          existing.gemini_web_ingredient_lookup_at ?? null,
        gemini_web_ingredient_lookup_name_key:
          existing.gemini_web_ingredient_lookup_name_key ?? null,
      }

      await upsertProduct(supabase, {
        barcode:            existing.barcode,
        name:               existing.name,
        ingredients:        storedIngredients,
        ingredientSource:   resolvedSource,
        isNonFood:          existing.is_non_food as boolean ?? false,
        labels:             existing.labels as string[] ?? [],
        imageUrl:           existing.image_url as string | undefined,
        imageFrontUrl:      existing.image_front_url as string | undefined,
        imageIngredientsUrl: existing.image_ingredients_url as string | undefined,
        imageNutritionUrl:  existing.image_nutrition_url as string | undefined,
        requiresHalalCert:  existing.requires_halal_cert as boolean ?? false,
        isManaged:          existing.is_managed as boolean | undefined,
        fetchedAt:          existing.fetched_at as string,
        geminiAt:           existing.gemini_web_ingredient_lookup_at as string | undefined,
        geminiNameKey:      existing.gemini_web_ingredient_lookup_name_key as string | undefined,
      })

      await upsertAnalysis(supabase, {
        barcode:              existing.barcode,
        isHalal:              reHalal,
        isUnknown:            reUnknown,
        isNonFood:            existing.is_non_food as boolean ?? false,
        haramIngredients:     reHaram,
        suspiciousIngredients: reSuspicious,
        ingredientWarnings:   reWarnings,
        explanation:          reExplanation,
        analyzedByAI:         false,
      })

      return new Response(
        JSON.stringify({ product: toProduct(reRow) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (!fetchAiIngredients && !refetchForGeminiAuto && existing && !force) {
      const communityIngredients = await getApprovedContribution(supabase, barcode)
      const storedIngredients: string[] = communityIngredients
        ?? (Array.isArray(existing.ingredients) ? existing.ingredients : [])
      const visionUrlRaw = existing.image_ingredients_url as string | null | undefined
      const visionUrl = typeof visionUrlRaw === 'string' ? visionUrlRaw.trim() : ''
      const needsVisionIngredients = storedIngredients.length === 0 && visionUrl !== ''
      // Approved pack-photo stubs often have URLs but no text ingredients yet —
      // fall through to Tier-3 vision + analysis instead of freezing as unknown forever.
      if (!needsVisionIngredients) {
        return new Response(
          JSON.stringify({
            product: toProduct(withCommunitySource(existing, communityIngredients)),
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      console.log(`[${barcode}] DB stub has ingredient image — running vision/analysis path`)
    }

    // 2. Load custom approved keywords
    const { haram: customHaramEntries, suspicious: customSuspiciousEntries } = await loadCustomKeywords(supabase)

    // 3. Fetch product from Open*Facts — only for products not yet in Supabase.
    // Existing HalalScanProducts are never re-fetched from OFF; Supabase is the source of truth.
    let pd = null
    let isNonFood = false
    if (!existing) {
      pd = await fetchFromFoodApi(barcode, OFF_BASE)
      if (!pd) { pd = await fetchFromFoodApi(barcode, OBF_BASE); if (pd) isNonFood = true }
      if (!pd) { pd = await fetchFromFoodApi(barcode, OPF_BASE); if (pd) isNonFood = true }

      // If OFF found the product but has no ingredient data, also probe OBF/OPF.
      // A cross-listing there confirms the product is non-food (e.g. a cleaning
      // spray or cosmetic that was also submitted to OpenFoodFacts by mistake).
      if (pd && !isNonFood && !extractIngredientsText(pd)) {
        const obfPd = await fetchFromFoodApi(barcode, OBF_BASE)
        if (obfPd) { isNonFood = true; pd = obfPd }
        else {
          const opfPd = await fetchFromFoodApi(barcode, OPF_BASE)
          if (opfPd) { isNonFood = true; pd = opfPd }
        }
      }
    }

    if (!pd) {
      const canAnalyzeFromDbStub = existing !== null
      if (!canAnalyzeFromDbStub) {
        return new Response(
          JSON.stringify({ product: null }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }

      console.log(
        `[${barcode}] OFF miss — analysing from Supabase DB (approved pack-photo stub or curated row)`,
      )

      let geminiAtOut =
        existing.gemini_web_ingredient_lookup_at as string | undefined
      let geminiKeyOut =
        existing.gemini_web_ingredient_lookup_name_key as string | undefined

      let name =
        typeof existing.name === 'string' &&
          existing.name.trim().length > 0
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
        ingredientSource = existing.ingredient_source as 'community' | 'ai'
      }

      const approvedAiRequestStub = fetchAiIngredients
        ? await hasApprovedAiIngredientRequest(supabase, barcode)
        : false
      if (
        shouldRunGeminiIngredientLookup({
          autoLookupEmptyOff: geminiAutoEmptyOff,
          fetchAiIngredients,
          hasApprovedRequest: approvedAiRequestStub,
          offIngredientCount: ingredients.length,
          productName: name,
        })
      ) {
        if (isGeminiWebIngredientLookupDoneForProductName(existing, name)) {
          console.log(
            `[${barcode}] Gemini web ingredient lookup: skipped — already attempted for this product name`,
          )
        } else {
          const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
          const geminiKey = Deno.env.get('GEMINI_API_KEY')
          if (!geminiEnabled) {
            console.log(`[${barcode}] Gemini ingredient lookup: skipped — disabled by GEMINI_ENABLED=false`)
          } else if (!geminiKey) {
            console.log(`[${barcode}] Gemini ingredient lookup: skipped — GEMINI_API_KEY not set`)
          } else {
            try {
              const found = await geminiIngredientLookup(name, barcode, geminiKey, brand)
              if (found.length > 0) {
                ingredients = found
                ingredientSource = 'ai'
              }
            } finally {
              geminiAtOut = new Date().toISOString()
              geminiKeyOut = normalizeProductNameForGeminiKey(name)
            }
          }
        }
      }

      if (communityDb) {
        ingredients = communityDb
        ingredientSource = 'community'
      }

      const labelsRaw = existing.labels
      const labels: string[] = Array.isArray(labelsRaw)
        ? (labelsRaw as unknown[]).map((x: unknown) => String(x).trim().toLowerCase()).filter((s) => s.length > 0)
        : []
      let isNonFood = !!(existing.is_non_food ?? false)

      console.log(`[${barcode}] DB stub name="${name}" ingredients=${ingredients.length}`)

      console.log(
        `[${barcode}] ingredients: source=${ingredientSource} count=${ingredients.length} list=[${ingredients.slice(0, 10).join(' | ')}${ingredients.length > 10 ? '…' : ''}]`,
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
      const { isHalal, isUnknown, haramIngredients, suspiciousIngredients,
        ingredientWarnings, explanation, analyzedByAI, requiresHalalCert } = verdict
      ingredients = verdict.ingredients

      const row = {
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
        image_url: existing.image_url as string | undefined,
        image_front_url: existing.image_front_url as string | undefined,
        image_ingredients_url: existing.image_ingredients_url as string | undefined,
        image_nutrition_url: existing.image_nutrition_url as string | undefined,
        explanation,
        analyzed_by_ai: analyzedByAI,
        requires_halal_cert: requiresHalalCert,
        last_analysed_at: new Date().toISOString(),
        fetched_at: existing.fetched_at as string ?? new Date().toISOString(),
      }

      await upsertProduct(supabase, {
        barcode,
        name,
        ingredients,
        ingredientSource,
        isNonFood,
        labels,
        imageUrl:           existing.image_url as string | undefined,
        imageFrontUrl:      existing.image_front_url as string | undefined,
        imageIngredientsUrl: existing.image_ingredients_url as string | undefined,
        imageNutritionUrl:  existing.image_nutrition_url as string | undefined,
        requiresHalalCert,
        isManaged:          (existing.is_managed ?? false) as boolean,
        fetchedAt:          (existing.fetched_at as string) ?? new Date().toISOString(),
        geminiAt:           geminiAtOut,
        geminiNameKey:      geminiKeyOut,
      })

      await upsertAnalysis(supabase, {
        barcode,
        isHalal,
        isUnknown,
        isNonFood,
        haramIngredients,
        suspiciousIngredients,
        ingredientWarnings,
        explanation,
        analyzedByAI,
      })

      const { data: savedStub } = await supabase
        .from('products_full')
        .select('*')
        .eq('barcode', barcode)
        .maybeSingle()

      return new Response(
        JSON.stringify({ product: toProduct(savedStub ?? row) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const name: string = (pd.product_name?.trim() || pd.product_name_en?.trim() || pd.abbreviated_product_name?.trim() || 'Unknown Product')
    const brand: string = (pd.brands?.trim() || pd.brand_owner?.trim() || '')
      .split(',')[0]?.trim() ?? ''
    const ingredientsText = extractIngredientsText(pd)
    let ingredients: string[] = ingredientsText
      .split(/[,;]/)
      .map((s: string) => s.trim())
      .filter((s: string) => s.length > 0)

    console.log(`[${barcode}] OFF: name="${name}" brand="${brand}" ingredients=${ingredients.length}`)

    let geminiAtOut =
      existing?.gemini_web_ingredient_lookup_at as string | undefined
    let geminiKeyOut =
      existing?.gemini_web_ingredient_lookup_name_key as string | undefined

    let ingredientSource: 'off' | 'ai' | 'community' = 'off'

    // 4. Gemini + Google Search when OFF has no ingredients:
    //   • app_config.gemini_lookup_empty_off (superadmin) or GEMINI_LOOKUP_EMPTY_OFF env, or
    //   • fetchAiIngredients + approved ai_ingredient_requests (app admin flow).
    const approvedAiRequest = fetchAiIngredients
      ? await hasApprovedAiIngredientRequest(supabase, barcode)
      : false
    if (!shouldRunGeminiIngredientLookup({
      autoLookupEmptyOff: geminiAutoEmptyOff,
      fetchAiIngredients,
      hasApprovedRequest: approvedAiRequest,
      offIngredientCount: ingredients.length,
      productName: name,
    })) {
      if (ingredients.length === 0 && name !== 'Unknown Product') {
        const skipReason = geminiAutoEmptyOff
          ? 'preconditions not met'
          : !fetchAiIngredients
          ? 'requires fetchAiIngredients after admin approval, or enable gemini_lookup_empty_off (superadmin / env)'
          : !approvedAiRequest
          ? 'no approved ai_ingredient_requests row'
          : 'preconditions not met'
        console.log(`[${barcode}] Gemini ingredient lookup: skipped — ${skipReason}`)
      }
    } else {
      if (isGeminiWebIngredientLookupDoneForProductName(existing, name)) {
        console.log(
          `[${barcode}] Gemini web ingredient lookup: skipped — already attempted for this product name`,
        )
      } else {
        const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
        const geminiKey = Deno.env.get('GEMINI_API_KEY')
        if (!geminiEnabled) {
          console.log(`[${barcode}] Gemini ingredient lookup: skipped — disabled by GEMINI_ENABLED=false`)
        } else if (!geminiKey) {
          console.log(`[${barcode}] Gemini ingredient lookup: skipped — GEMINI_API_KEY not set`)
        } else {
          try {
            const found = await geminiIngredientLookup(name, barcode, geminiKey, brand)
            if (found.length > 0) { ingredients = found; ingredientSource = 'ai' }
          } finally {
            geminiAtOut = new Date().toISOString()
            geminiKeyOut = normalizeProductNameForGeminiKey(name)
          }
        }
      }
    }

    const communityIngredients = await getApprovedContribution(supabase, barcode)
    if (communityIngredients) {
      ingredients = communityIngredients
      ingredientSource = 'community'
      console.log(`[${barcode}] community override: ${ingredients.length} ingredients`)
    }

    const labelSet = new Set<string>()
    const addLabels = (v: unknown) => {
      if (!v) return
      const parts = typeof v === 'string' ? v.split(/[,;]/) : (v as string[])
      parts.forEach((p: string) => { const n = p.trim().toLowerCase(); if (n) labelSet.add(n) })
    }
    addLabels(pd.labels); addLabels(pd.labels_tags)
    addLabels(pd.labels_hierarchy); addLabels(pd.labels_en)
    const labels = [...labelSet]

    const rawCategories: string[] = Array.isArray(pd.categories_tags) ? pd.categories_tags : []

    if (!isNonFood && rawCategories.some(c => NON_FOOD_CATEGORIES.has(c.toLowerCase()))) isNonFood = true
    const haramCategory = isNonFood ? null : (rawCategories.find(c => HARAM_CATEGORIES.has(c.toLowerCase())) ?? null)
    const isHalalByCategory = !isNonFood && !haramCategory && rawCategories.some(c => HALAL_CATEGORIES.has(c.toLowerCase()))

    console.log(`[${barcode}] ingredients: source=${ingredientSource} count=${ingredients.length} list=[${ingredients.slice(0, 10).join(' | ')}${ingredients.length > 10 ? '…' : ''}]`)

    // 5. Tiered halal analysis — keyword + AI + vision + safety overrides.
    const verdict = await computeVerdict({
      barcode,
      ingredients,
      name,
      labels,
      rawCategories,
      isNonFood,
      ingredientSource,
      haramCategory,
      isHalalByCategory,
      customHaramEntries,
      customSuspiciousEntries,
      imageIngredientsUrl: resolveImg(pd, 'image_ingredients_url', 'ingredients') || '',
    })
    const { isHalal, isUnknown, haramIngredients, suspiciousIngredients,
      ingredientWarnings, explanation, analyzedByAI, requiresHalalCert } = verdict
    ingredients = verdict.ingredients

    // 6. Upsert to DB — products owns source data, product_analysis owns the verdict.
    const row = {
      barcode,
      name,
      ingredients,
      ingredient_source:      ingredientSource,
      is_halal:               isHalal,
      is_unknown:             isUnknown,
      is_non_food:            isNonFood,
      haram_ingredients:      haramIngredients,
      suspicious_ingredients: suspiciousIngredients,
      ingredient_warnings:    ingredientWarnings,
      labels,
      image_url:              existing?.image_url              ?? resolveImg(pd, 'image_url', 'front'),
      image_front_url:        existing?.image_front_url        ?? resolveImg(pd, 'image_front_url', 'front'),
      image_ingredients_url:  existing?.image_ingredients_url  ?? resolveImg(pd, 'image_ingredients_url', 'ingredients'),
      image_nutrition_url:    existing?.image_nutrition_url    ?? resolveImg(pd, 'image_nutrition_url', 'nutrition'),
      explanation,
      analyzed_by_ai:         analyzedByAI,
      requires_halal_cert:    requiresHalalCert,
      last_analysed_at:       new Date().toISOString(),
      fetched_at:             existing?.fetched_at ?? new Date().toISOString(),
    }

    // Preserve community-approved image URLs — never overwrite them with OFF URLs.
    await upsertProduct(supabase, {
      barcode,
      name,
      ingredients,
      ingredientSource,
      isNonFood,
      labels,
      imageUrl:           existing?.image_url              ?? resolveImg(pd, 'image_url', 'front'),
      imageFrontUrl:      existing?.image_front_url        ?? resolveImg(pd, 'image_front_url', 'front'),
      imageIngredientsUrl: existing?.image_ingredients_url ?? resolveImg(pd, 'image_ingredients_url', 'ingredients'),
      imageNutritionUrl:  existing?.image_nutrition_url    ?? resolveImg(pd, 'image_nutrition_url', 'nutrition'),
      requiresHalalCert,
      fetchedAt:          existing?.fetched_at ?? new Date().toISOString(),
      geminiAt:           geminiAtOut,
      geminiNameKey:      geminiKeyOut,
    })

    await upsertAnalysis(supabase, {
      barcode,
      isHalal,
      isUnknown,
      isNonFood,
      haramIngredients,
      suspiciousIngredients,
      ingredientWarnings,
      explanation,
      analyzedByAI,
    })

    const { data: saved } = await supabase
      .from('products_full')
      .select('*')
      .eq('barcode', barcode)
      .maybeSingle()

    return new Response(
      JSON.stringify({ product: toProduct(saved ?? row) }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error(err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
