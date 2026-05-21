import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { keywordAnalysis } from './keyword.ts'
import type { KeywordEntry } from './keyword.ts'
import {
  HARAM_CATEGORIES, HALAL_CATEGORIES, NON_FOOD_CATEGORIES,
  ANIMAL_PRODUCT_CATEGORIES, HALAL_CERT_LABELS, ANIMAL_PRODUCT_NAME_TERMS,
} from './categories.ts'
import { fetchFromFoodApi, extractIngredientsText, resolveImg, OFF_BASE, OBF_BASE, OPF_BASE } from './fetch.ts'
import { toProduct, isStale } from './db.ts'
import { getApprovedContribution, withCommunitySource } from './community.ts'
import {
  geminiIngredientLookup, analyzeWithGemini, analyzeWithClaude, analyzeWithClaudeVision,
} from './ai.ts'

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

    console.log(`[${barcode}] request: force=${force} fetchAiIngredients=${fetchAiIngredients}`)

    // 1. Cache hit?
    const { data: cached } = await supabase
      .from('products_full')
      .select('*')
      .eq('barcode', barcode)
      .maybeSingle()

    console.log(`[${barcode}] cache: ${cached ? `hit (is_managed=${cached.is_managed} is_unknown=${cached.is_unknown} ingredient_source=${cached.ingredient_source} ingredients=${Array.isArray(cached.ingredients) ? cached.ingredients.length : 0})` : 'miss'}`)

    // Managed products are never overwritten by OFF data.
    // Return the DB row as-is regardless of the force flag.
    if (cached?.is_managed) {
      console.log(`[${barcode}] managed product — returning DB row as-is`)
      return new Response(
        JSON.stringify({ product: toProduct(cached) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Re-run keyword analysis on stored data when either:
    //   • source data changed since last analysis (updated_at > last_analysed_at), OR
    //   • caller requested a force refresh on an already-known product.
    // OFF is only ever fetched on the very first scan (cached === null below).
    // Unknown products with force=true fall through so OFF can be retried.
    // fetchAiIngredients bypasses this path entirely so Gemini lookup can run.
    if (!fetchAiIngredients && cached && (isStale(cached) || (force && !cached.is_unknown))) {
      const reason = isStale(cached) ? 'stale (updated_at > last_analysed_at)' : 'force-refresh'
      console.log(`[${barcode}] ${reason} — re-running rules engine on stored data`)

      const { data: kwRows } = await supabase
        .from('keywords')
        .select('canonical, category, reason, variants')
      const reHaramEntries: KeywordEntry[] = []
      const reSuspiciousEntries: KeywordEntry[] = []
      if (kwRows) {
        for (const kw of kwRows) {
          const variants = Array.isArray(kw.variants) && kw.variants.length > 0
            ? kw.variants as string[]
            : [kw.canonical as string]
          const entry: KeywordEntry = [kw.canonical as string, kw.reason as string, ...variants]
          if (kw.category === 'haram') reHaramEntries.push(entry)
          else reSuspiciousEntries.push(entry)
        }
      }

      const communityIngredients = await getApprovedContribution(supabase, barcode)
      const storedIngredients: string[] = communityIngredients
        ?? (Array.isArray(cached.ingredients) ? cached.ingredients : [])
      const resolvedSource = communityIngredients
        ? 'community'
        : (cached.ingredient_source ?? 'off')
      const kw = keywordAnalysis(storedIngredients, reHaramEntries, reSuspiciousEntries)
      console.log(`[${barcode}] re-analysis result: isHalal=${kw.isHalal} isUnknown=${kw.isUnknown} haram=[${kw.haram.join(', ')}] suspicious=[${kw.suspicious.join(', ')}] ingredients=${storedIngredients.length}`)

      let reHalal       = kw.isHalal
      let reUnknown     = kw.isUnknown
      let reHaram       = kw.haram
      let reSuspicious  = kw.suspicious
      let reWarnings    = kw.warnings
      let reExplanation = kw.explanation

      if (reUnknown) {
        const nameKw = keywordAnalysis([(cached.name ?? '').toLowerCase()], reHaramEntries, reSuspiciousEntries)
        if (!nameKw.isHalal) {
          reHalal = false; reUnknown = false
          reHaram = nameKw.haram; reWarnings = nameKw.warnings
          reExplanation = `No ingredient list found, but the product name contains a haram indicator: ${nameKw.haram.join(', ')}.`
        }
      }

      const reRow = {
        barcode:               cached.barcode,
        name:                  cached.name,
        ingredients:           storedIngredients,
        is_halal:              reHalal,
        is_unknown:            reUnknown,
        is_non_food:           cached.is_non_food,
        haram_ingredients:     reHaram,
        suspicious_ingredients: reSuspicious,
        ingredient_warnings:   reWarnings,
        labels:                cached.labels,
        image_url:             cached.image_url,
        image_front_url:       cached.image_front_url,
        image_ingredients_url: cached.image_ingredients_url,
        image_nutrition_url:   cached.image_nutrition_url,
        explanation:           reExplanation,
        analyzed_by_ai:        false,
        requires_halal_cert:   cached.requires_halal_cert,
        is_managed:            cached.is_managed,
        last_analysed_at:      new Date().toISOString(),
        fetched_at:            cached.fetched_at,
        ingredient_source:     resolvedSource,
      }

      await supabase.from('products').upsert({
        barcode:               cached.barcode,
        name:                  cached.name,
        ingredients:           storedIngredients,
        is_non_food:           cached.is_non_food,
        labels:                cached.labels,
        image_url:             cached.image_url,
        image_front_url:       cached.image_front_url,
        image_ingredients_url: cached.image_ingredients_url,
        image_nutrition_url:   cached.image_nutrition_url,
        requires_halal_cert:   cached.requires_halal_cert,
        is_managed:            cached.is_managed,
        last_analysed_at:      new Date().toISOString(),
        fetched_at:            cached.fetched_at,
        ingredient_source:     resolvedSource,
      })

      await supabase.from('product_analysis').upsert({
        barcode:               cached.barcode,
        is_halal:              reHalal,
        is_unknown:            reUnknown,
        is_non_food:           cached.is_non_food,
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

    if (!fetchAiIngredients && cached && !force) {
      const communityIngredients = await getApprovedContribution(supabase, barcode)
      return new Response(
        JSON.stringify({
          product: toProduct(withCommunitySource(cached, communityIngredients)),
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // 2. Load custom approved keywords from DB
    const customHaramEntries: KeywordEntry[] = []
    const customSuspiciousEntries: KeywordEntry[] = []
    const { data: customKeywords } = await supabase
      .from('keywords')
      .select('canonical, category, reason, variants')
    if (customKeywords) {
      for (const kw of customKeywords) {
        const variants: string[] = Array.isArray(kw.variants) && kw.variants.length > 0
          ? kw.variants as string[]
          : [kw.canonical as string]
        const entry: KeywordEntry = [kw.canonical as string, kw.reason as string, ...variants]
        if (kw.category === 'haram') customHaramEntries.push(entry)
        else customSuspiciousEntries.push(entry)
      }
    }

    // 3. Fetch product from Open*Facts databases in order.
    // Products found via OBF (beauty) or OPF (general products) are non-food.
    let pd = await fetchFromFoodApi(barcode, OFF_BASE)
    let isNonFood = false
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

    if (!pd) {
      return new Response(
        JSON.stringify({ product: null }),
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

    let ingredientSource: 'off' | 'ai' | 'community' = 'off'

    // 4. Gemini + Google Search — when OFF has no ingredient text, search the web for the list.
    if (ingredients.length === 0 && name !== 'Unknown Product') {
      const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
      const geminiKey = Deno.env.get('GEMINI_API_KEY')
      if (!geminiEnabled) {
        console.log(`[${barcode}] Gemini ingredient lookup: skipped — disabled by GEMINI_ENABLED=false`)
      } else if (!geminiKey) {
        console.log(`[${barcode}] Gemini ingredient lookup: skipped — GEMINI_API_KEY not set`)
      } else {
        const found = await geminiIngredientLookup(name, barcode, geminiKey, brand)
        if (found.length > 0) { ingredients = found; ingredientSource = 'ai' }
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

    // Tier 3: Vision analysis — when no text ingredients but an ingredients image exists.
    // Claude reads the label photo (handles Arabic, Turkish, etc.) and returns a full verdict.
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
        const verdict = await analyzeWithClaudeVision(imgUrl, barcode, claudeKey)
        if (verdict) {
          ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = verdict)
          analyzedByAI = true
        }
      }
    }

    // Keyword safety override: haram keywords always win over AI verdict.
    // Reuses kwFirst — no need to re-run keyword analysis.
    if (kwFirst.haram.length > 0 && isHalal) {
      isHalal            = false
      isUnknown          = false
      haramIngredients   = [...new Set([...haramIngredients, ...kwFirst.haram])]
      ingredientWarnings = { ...ingredientWarnings, ...kwFirst.warnings }
      explanation        = kwFirst.explanation
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
      image_url:              cached?.image_url              ?? resolveImg(pd, 'image_url', 'front'),
      image_front_url:        cached?.image_front_url        ?? resolveImg(pd, 'image_front_url', 'front'),
      image_ingredients_url:  cached?.image_ingredients_url  ?? resolveImg(pd, 'image_ingredients_url', 'ingredients'),
      image_nutrition_url:    cached?.image_nutrition_url    ?? resolveImg(pd, 'image_nutrition_url', 'nutrition'),
      explanation,
      analyzed_by_ai:         analyzedByAI,
      requires_halal_cert:    requiresHalalCert,
      last_analysed_at:       new Date().toISOString(),
      fetched_at:             cached?.fetched_at ?? new Date().toISOString(),
    }

    const { error: upsertErr } = await supabase.from('products').upsert({
      barcode,
      name,
      ingredients,
      ingredient_source:      ingredientSource,
      is_non_food:            isNonFood,
      labels,
      // Preserve community-approved image URLs — never overwrite them with OFF URLs.
      image_url:              cached?.image_url              ?? resolveImg(pd, 'image_url', 'front'),
      image_front_url:        cached?.image_front_url        ?? resolveImg(pd, 'image_front_url', 'front'),
      image_ingredients_url:  cached?.image_ingredients_url  ?? resolveImg(pd, 'image_ingredients_url', 'ingredients'),
      image_nutrition_url:    cached?.image_nutrition_url    ?? resolveImg(pd, 'image_nutrition_url', 'nutrition'),
      requires_halal_cert:    requiresHalalCert,
      last_analysed_at:       new Date().toISOString(),
      fetched_at:             cached?.fetched_at ?? new Date().toISOString(),
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
