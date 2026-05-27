import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { keywordAnalysis } from './keyword.ts'
import {
  HARAM_CATEGORIES, HALAL_CATEGORIES, NON_FOOD_CATEGORIES,
  ANIMAL_PRODUCT_CATEGORIES, HALAL_CERT_LABELS, ANIMAL_PRODUCT_NAME_TERMS,
} from './categories.ts'
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
import {
  geminiIngredientLookup, analyzeWithGemini, analyzeWithClaude, analyzeWithClaudeVision,
} from './ai.ts'
import { getHalalScanProduct, loadCustomKeywords } from './productQueries.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { barcode, force = false, fetchAiIngredients = false } = body
    if (!barcode || typeof barcode !== 'string') {
      return new Response(
        JSON.stringify({ error: 'barcode is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

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

      await supabase.from('products').upsert({
        barcode:               existing.barcode,
        name:                  existing.name,
        ingredients:           storedIngredients,
        is_non_food:           existing.is_non_food,
        labels:                existing.labels,
        image_url:             existing.image_url,
        image_front_url:       existing.image_front_url,
        image_ingredients_url: existing.image_ingredients_url,
        image_nutrition_url:   existing.image_nutrition_url,
        requires_halal_cert:   existing.requires_halal_cert,
        is_managed:            existing.is_managed,
        last_analysed_at:      new Date().toISOString(),
        fetched_at:            existing.fetched_at,
        ingredient_source:     resolvedSource,
        ...(existing.gemini_web_ingredient_lookup_name_key
          ? {
            gemini_web_ingredient_lookup_at: existing.gemini_web_ingredient_lookup_at,
            gemini_web_ingredient_lookup_name_key:
              existing.gemini_web_ingredient_lookup_name_key,
          }
          : {}),
      })

      await supabase.from('product_analysis').upsert({
        barcode:               existing.barcode,
        is_halal:              reHalal,
        is_unknown:            reUnknown,
        is_non_food:           existing.is_non_food,
        haram_ingredients:     reHaram,
        suspicious_ingredients: reSuspicious,
        ingredient_warnings:   reWarnings,
        explanation:           reExplanation,
        analyzed_by_ai:        false,
        analyzed_at:           new Date().toISOString(),
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
      const rawCategories: string[] = []
      let isNonFood = !!(existing.is_non_food ?? false)

      console.log(`[${barcode}] DB stub name="${name}" ingredients=${ingredients.length}`)

      const haramCategory: string | null = null
      const isHalalByCategory = false

      console.log(
        `[${barcode}] ingredients: source=${ingredientSource} count=${ingredients.length} list=[${ingredients.slice(0, 10).join(' | ')}${ingredients.length > 10 ? '…' : ''}]`,
      )

      const kwFirst = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
      let isHalal = isNonFood ? false : kwFirst.isHalal
      let isUnknown = isNonFood ? false : kwFirst.isUnknown
      let haramIngredients = kwFirst.haram
      let suspiciousIngredients = kwFirst.suspicious
      let ingredientWarnings = kwFirst.warnings
      let explanation = isNonFood
        ? 'This is a non-food product. Islamic dietary rules do not apply.'
        : kwFirst.explanation
      let analyzedByAI = false

      const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
      const claudeEnabled = Deno.env.get('CLAUDE_ENABLED') !== 'false'

      const skipAI = isNonFood || isHalalByCategory ||
        kwFirst.haram.length > 0 ||
        haramCategory !== null ||
        ingredients.length === 0 ||
        ingredientSource === 'ai'
      if (!skipAI) {
        const geminiKey = Deno.env.get('GEMINI_API_KEY')
        if (geminiEnabled && geminiKey) {
          const verdict = await analyzeWithGemini(ingredients, barcode, geminiKey)
          if (verdict) {
            ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } =
              verdict)
            analyzedByAI = true
          }
        }
        if (!analyzedByAI && claudeEnabled) {
          const claudeKey = Deno.env.get('CLAUDE_API_KEY')
          if (claudeKey) {
            const verdict = await analyzeWithClaude(ingredients, barcode, claudeKey)
            if (verdict) {
              ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } =
                verdict)
              analyzedByAI = true
            }
          }
        }
      }

      // Vision on approved pack-photo URL (same semantics as Tier 3 OFF path).
      if (!analyzedByAI && ingredients.length === 0 && !isNonFood && !isHalalByCategory &&
        haramCategory === null) {
        const imgUrl = typeof existing.image_ingredients_url === 'string'
          ? existing.image_ingredients_url.trim()
          : ''
        const claudeKey = Deno.env.get('CLAUDE_API_KEY')
        if (claudeEnabled && imgUrl && claudeKey) {
          const visionIngredients = await analyzeWithClaudeVision(imgUrl, barcode, claudeKey)
          if (visionIngredients && visionIngredients.length > 0) {
            ingredients = visionIngredients
            const kwVision = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
            isHalal = kwVision.isHalal
            isUnknown = kwVision.isUnknown
            haramIngredients = kwVision.haram
            suspiciousIngredients = kwVision.suspicious
            ingredientWarnings = kwVision.warnings
            explanation = kwVision.explanation
            if (kwVision.haram.length === 0) {
              const gKey = Deno.env.get('GEMINI_API_KEY')
              if (geminiEnabled && gKey) {
                const verdict = await analyzeWithGemini(ingredients, barcode, gKey)
                if (verdict) {
                  ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } =
                    verdict)
                  analyzedByAI = true
                }
              }
              if (!analyzedByAI && claudeKey) {
                const verdict = await analyzeWithClaude(ingredients, barcode, claudeKey)
                if (verdict) {
                  ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } =
                    verdict)
                  analyzedByAI = true
                }
              }
            }
          }
        } else if (!imgUrl) {
          console.log(`[${barcode}] stub Claude vision skipped — no ingredients image URL`)
        }
      }

      if (kwFirst.haram.length > 0 && isHalal) {
        isHalal = false
        isUnknown = false
        haramIngredients = [...new Set([...haramIngredients, ...kwFirst.haram])]
        ingredientWarnings = { ...ingredientWarnings, ...kwFirst.warnings }
        explanation = kwFirst.explanation
      }
      if (kwFirst.suspicious.length > 0 && isHalal) {
        isHalal = false
        isUnknown = false
        suspiciousIngredients = [...new Set([...suspiciousIngredients, ...kwFirst.suspicious])]
        ingredientWarnings = { ...ingredientWarnings, ...kwFirst.warnings }
        if (kwFirst.haram.length === 0) explanation = kwFirst.explanation
      }

      if (isUnknown) {
        const nameCheck = keywordAnalysis([name.toLowerCase()], customHaramEntries, customSuspiciousEntries)
        if (!nameCheck.isHalal) {
          isHalal = false
          isUnknown = false
          haramIngredients = nameCheck.haram
          ingredientWarnings = nameCheck.warnings
          explanation =
            `No ingredient list found, but the product name contains a haram indicator: ${nameCheck.haram.join(', ')}.`
        }
      }

      const categoryIsAnimalProduct = rawCategories.some((c) =>
        ANIMAL_PRODUCT_CATEGORIES.has(c.toLowerCase())
      )
      const nameIsAnimalProduct = [...ANIMAL_PRODUCT_NAME_TERMS].some((term) =>
        name.toLowerCase().includes(term)
      )
      const isAnimalProduct = categoryIsAnimalProduct || nameIsAnimalProduct
      const hasHalalCert = labels.some((l) => HALAL_CERT_LABELS.has(l.toLowerCase()))
      let requiresHalalCert = isAnimalProduct && !hasHalalCert && !isNonFood && !isHalalByCategory &&
        haramIngredients.length === 0

      if (requiresHalalCert) {
        isHalal = false
        isUnknown = false
      }

      if (!isUnknown && !isHalalByCategory && haramIngredients.length === 0 &&
        suspiciousIngredients.length > 0) {
        isHalal = false
      }

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

      const { error: upsertStubErr } = await supabase.from('products').upsert({
        barcode,
        name,
        ingredients,
        ingredient_source: ingredientSource,
        is_non_food: isNonFood,
        labels,
        image_url: existing.image_url ?? null,
        image_front_url: existing.image_front_url ?? null,
        image_ingredients_url: existing.image_ingredients_url ?? null,
        image_nutrition_url: existing.image_nutrition_url ?? null,
        requires_halal_cert: requiresHalalCert,
        is_managed: (existing.is_managed ?? false) as boolean,
        last_analysed_at: new Date().toISOString(),
        fetched_at: (existing.fetched_at as string) ?? new Date().toISOString(),
        ...(geminiKeyOut
          ? {
            gemini_web_ingredient_lookup_at: geminiAtOut,
            gemini_web_ingredient_lookup_name_key: geminiKeyOut,
          }
          : {}),
      })
      if (upsertStubErr) console.error('stub upsert error', upsertStubErr)

      await supabase.from('product_analysis').upsert({
        barcode,
        is_halal: isHalal,
        is_unknown: isUnknown,
        is_non_food: isNonFood,
        haram_ingredients: haramIngredients,
        suspicious_ingredients: suspiciousIngredients,
        ingredient_warnings: ingredientWarnings,
        explanation,
        analyzed_by_ai: analyzedByAI,
        analyzed_at: new Date().toISOString(),
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

    // 5. Tiered AI analysis — keyword-first to minimize cost.
    // Run keywords upfront; skip AI entirely when the result is already determined.
    const kwFirst = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
    console.log(`[${barcode}] keywords: isHalal=${kwFirst.isHalal} isUnknown=${kwFirst.isUnknown} haram=[${kwFirst.haram.join(', ')}] suspicious=[${kwFirst.suspicious.join(', ')}]`)
    let isHalal               = isNonFood ? false : (isHalalByCategory && ingredients.length === 0 ? true : kwFirst.isHalal)
    let isUnknown             = isNonFood ? false : (isHalalByCategory && ingredients.length === 0 ? false : kwFirst.isUnknown)
    let haramIngredients      = kwFirst.haram
    let suspiciousIngredients = kwFirst.suspicious
    let ingredientWarnings    = kwFirst.warnings
    let explanation           = isNonFood
      ? 'This is a non-food product. Islamic dietary rules do not apply.'
      : (isHalalByCategory && ingredients.length === 0
          ? 'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.'
          : kwFirst.explanation)
    let analyzedByAI = false

    const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
    const claudeEnabled = Deno.env.get('CLAUDE_ENABLED') !== 'false'

    // Skip AI when keywords already found haram, product is in a haram category,
    // is non-food, halal-by-category, there are no ingredients, or ingredients
    // were sourced from Gemini knowledge lookup (avoid analyzing AI-invented data with AI).
    const skipAI = isNonFood || isHalalByCategory || kwFirst.haram.length > 0 || haramCategory !== null || ingredients.length === 0 || ingredientSource === 'ai'
    if (skipAI) {
      const skipReason = isNonFood ? 'non-food'
        : isHalalByCategory ? 'halal-by-category'
        : haramCategory !== null ? `haram-category(${haramCategory})`
        : kwFirst.haram.length > 0 ? `keyword-haram(${kwFirst.haram.join(', ')})`
        : 'no-ingredients'
      console.log(`[${barcode}] AI: skipped — ${skipReason}`)
    } else {
      // Tier 1: Gemini Flash — free 1,500 req/day; handles the vast majority of scans
      const geminiKey = Deno.env.get('GEMINI_API_KEY')
      if (!geminiEnabled) {
        console.log(`[${barcode}] Gemini: skipped — disabled by GEMINI_ENABLED=false`)
      } else if (!geminiKey) {
        console.log(`[${barcode}] Gemini: skipped — GEMINI_API_KEY not set`)
      } else {
        const verdict = await analyzeWithGemini(ingredients, barcode, geminiKey)
        if (verdict) {
          ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = verdict)
          analyzedByAI = true
        }
      }

      // Tier 2: Claude Haiku — paid fallback when Gemini is unavailable or fails
      if (!analyzedByAI) {
        const claudeKey = Deno.env.get('CLAUDE_API_KEY')
        if (!claudeEnabled) {
          console.log(`[${barcode}] Claude: skipped — disabled by CLAUDE_ENABLED=false`)
        } else if (!claudeKey) {
          console.log(`[${barcode}] Claude: skipped — CLAUDE_API_KEY not set`)
        } else {
          const verdict = await analyzeWithClaude(ingredients, barcode, claudeKey)
          if (verdict) {
            ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = verdict)
            analyzedByAI = true
          }
        }
      }
    }

    // Tier 3: Vision extraction — when no text ingredients but an ingredients image exists.
    // Claude reads the label photo and returns the raw ingredient list; rule engine verdicts.
    if (!analyzedByAI && ingredients.length === 0 && !isNonFood && !isHalalByCategory && haramCategory === null) {
      const imgUrl = resolveImg(pd, 'image_ingredients_url', 'ingredients')
      const claudeKey = Deno.env.get('CLAUDE_API_KEY')
      if (!claudeEnabled) {
        console.log(`[${barcode}] Claude vision: skipped — disabled by CLAUDE_ENABLED=false`)
      } else if (!imgUrl) {
        console.log(`[${barcode}] Claude vision: skipped — no ingredients image`)
      } else if (!claudeKey) {
        console.log(`[${barcode}] Claude vision: skipped — CLAUDE_API_KEY not set`)
      } else {
        const visionIngredients = await analyzeWithClaudeVision(imgUrl, barcode, claudeKey)
        if (visionIngredients && visionIngredients.length > 0) {
          ingredients = visionIngredients
          const kwVision = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
          isHalal             = kwVision.isHalal
          isUnknown           = kwVision.isUnknown
          haramIngredients    = kwVision.haram
          suspiciousIngredients = kwVision.suspicious
          ingredientWarnings  = kwVision.warnings
          explanation         = kwVision.explanation
          // Run AI text analysis on vision-extracted ingredients (skip if keywords already found haram)
          if (kwVision.haram.length === 0) {
            const geminiKey = Deno.env.get('GEMINI_API_KEY')
            if (geminiEnabled && geminiKey) {
              const verdict = await analyzeWithGemini(ingredients, barcode, geminiKey)
              if (verdict) {
                ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = verdict)
                analyzedByAI = true
              }
            }
            if (!analyzedByAI && claudeEnabled && claudeKey) {
              const verdict = await analyzeWithClaude(ingredients, barcode, claudeKey)
              if (verdict) {
                ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = verdict)
                analyzedByAI = true
              }
            }
          }
        }
      }
    }

    // Keyword safety override: haram/suspicious keywords always win over AI verdict.
    // Reuses kwFirst — no need to re-run keyword analysis.
    if (kwFirst.haram.length > 0 && isHalal) {
      isHalal            = false
      isUnknown          = false
      haramIngredients   = [...new Set([...haramIngredients, ...kwFirst.haram])]
      ingredientWarnings = { ...ingredientWarnings, ...kwFirst.warnings }
      explanation        = kwFirst.explanation
    }
    if (kwFirst.suspicious.length > 0 && isHalal) {
      isHalal                 = false
      isUnknown               = false
      suspiciousIngredients   = [...new Set([...suspiciousIngredients, ...kwFirst.suspicious])]
      ingredientWarnings      = { ...ingredientWarnings, ...kwFirst.warnings }
      if (kwFirst.haram.length === 0) explanation = kwFirst.explanation
    }

    // Category-based override: known alcoholic categories always win.
    if (haramCategory && isHalal) {
      isHalal     = false
      isUnknown   = false
      explanation = `This product belongs to a category that is not permissible: ${haramCategory}.`
    }

    // Name-based fallback: when no ingredients were found, check the product
    // name itself. Names like "Wieselburger Bier" or "Rosé Wine" contain haram
    // keywords that make the verdict unambiguous without ingredient data.
    if (isUnknown) {
      const nameCheck = keywordAnalysis([name.toLowerCase()], customHaramEntries, customSuspiciousEntries)
      if (!nameCheck.isHalal) {
        isHalal            = false
        isUnknown          = false
        haramIngredients   = nameCheck.haram
        ingredientWarnings = nameCheck.warnings
        explanation        = `No ingredient list found, but the product name contains a haram indicator: ${nameCheck.haram.join(', ')}.`
      }
    }

    // Calculate requiresHalalCert
    const categoryIsAnimalProduct = rawCategories.some(c => ANIMAL_PRODUCT_CATEGORIES.has(c.toLowerCase()))
    const nameIsAnimalProduct = [...ANIMAL_PRODUCT_NAME_TERMS].some(term => name.toLowerCase().includes(term))
    const isAnimalProduct = categoryIsAnimalProduct || nameIsAnimalProduct
    const hasHalalCert = labels.some(l => HALAL_CERT_LABELS.has(l.toLowerCase()))
    const requiresHalalCert = isAnimalProduct && !hasHalalCert && !isNonFood && !haramCategory && !isHalalByCategory && haramIngredients.length === 0

    if (requiresHalalCert) {
      isHalal   = false
      isUnknown = false
    }

    // Halal only when no haram, no suspicious, and no missing slaughter cert.
    if (!isUnknown && !isHalalByCategory && haramIngredients.length === 0 &&
        suspiciousIngredients.length > 0) {
      isHalal = false
    }

    console.log(`[${barcode}] verdict: isHalal=${isHalal} isUnknown=${isUnknown} analyzedByAI=${analyzedByAI} requiresHalalCert=${requiresHalalCert} haram=[${haramIngredients.join(', ')}] suspicious=[${suspiciousIngredients.join(', ')}]`)

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

    const { error: upsertErr } = await supabase.from('products').upsert({
      barcode,
      name,
      ingredients,
      ingredient_source:      ingredientSource,
      is_non_food:            isNonFood,
      labels,
      // Preserve community-approved image URLs — never overwrite them with OFF URLs.
      image_url:              existing?.image_url              ?? resolveImg(pd, 'image_url', 'front'),
      image_front_url:        existing?.image_front_url        ?? resolveImg(pd, 'image_front_url', 'front'),
      image_ingredients_url:  existing?.image_ingredients_url  ?? resolveImg(pd, 'image_ingredients_url', 'ingredients'),
      image_nutrition_url:    existing?.image_nutrition_url    ?? resolveImg(pd, 'image_nutrition_url', 'nutrition'),
      requires_halal_cert:    requiresHalalCert,
      last_analysed_at:       new Date().toISOString(),
      fetched_at:             existing?.fetched_at ?? new Date().toISOString(),
      ...(geminiKeyOut
        ? {
          gemini_web_ingredient_lookup_at: geminiAtOut,
          gemini_web_ingredient_lookup_name_key: geminiKeyOut,
        }
        : {}),
    })

    if (upsertErr) {
      console.error('upsert error', upsertErr)
    }

    await supabase.from('product_analysis').upsert({
      barcode,
      is_halal:               isHalal,
      is_unknown:             isUnknown,
      is_non_food:            isNonFood,
      haram_ingredients:      haramIngredients,
      suspicious_ingredients: suspiciousIngredients,
      ingredient_warnings:    ingredientWarnings,
      explanation,
      analyzed_by_ai:         analyzedByAI,
      analyzed_at:            new Date().toISOString(),
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
