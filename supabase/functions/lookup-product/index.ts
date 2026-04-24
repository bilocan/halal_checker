import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000
const OFF_BASE = 'https://world.openfoodfacts.org/api/v0/product'
const CLAUDE_URL = 'https://api.anthropic.com/v1/messages'
const CLAUDE_MODEL = 'claude-haiku-4-5'

const CLAUDE_SYSTEM = `You are an expert in Islamic dietary laws (halal). Analyze ingredient lists and determine if a product is halal.

Respond with a raw JSON object only — no markdown, no prose outside the JSON:
{
  "isHalal": boolean,
  "haramIngredients": ["ingredient names that are definitively haram"],
  "suspiciousIngredients": ["ingredient names that may be non-halal"],
  "ingredientWarnings": {"ingredient name": "reason why haram or suspicious"},
  "explanation": "2-3 sentence plain-language summary of the verdict and the key reasons"
}

Haram: pork and derivatives (lard, bacon, ham, pepperoni, salami, chorizo, prosciutto, pork gelatin), alcohol (ethanol, wine, beer), blood, carnivorous animals, insects (carmine, cochineal, E120).

Suspicious: gelatin (source unspecified), L-cysteine (E920), mono- and diglycerides (E471), rennet (non-microbial), enzymes (source unspecified), natural flavors (source unspecified), emulsifiers that may be animal-derived.

If the ingredients list is empty, respond with isHalal true, empty arrays, and explanation "No ingredient data available to analyze."`

// ── keyword fallback (mirrors ProductService.dart) ──────────────────────────

const HARAM_KW: Record<string, string> = {
  alcohol:    'Contains alcohol or alcohol-derived ingredient',
  ethanol:    'Contains alcohol or alcohol-derived ingredient',
  wine:       'Contains alcohol or alcohol-derived ingredient',
  beer:       'Contains alcohol or alcohol-derived ingredient',
  pork:       'Contains pork or pork-derived ingredient',
  lard:       'Contains pork fat',
  gelatin:    'Gelatin is typically animal-derived',
  bacon:      'Contains pork product',
  ham:        'Contains pork product',
  pepperoni:  'Contains pork product',
  salami:     'Contains pork product',
  chorizo:    'Contains pork product',
  prosciutto: 'Contains pork product',
  carmine:    'Carmine/cochineal is insect-derived',
  cochineal:  'Carmine/cochineal is insect-derived',
  e120:       'Carmine/cochineal color, animal-derived',
  e441:       'Gelatin, animal-derived',
  e542:       'Bone phosphate, animal-derived',
  e904:       'Shellac, animal-derived',
}

const SUSPICIOUS_KW: Record<string, string> = {
  e920:             'L-cysteine may be animal-derived',
  e322:             'Lecithin may be animal-derived',
  e471:             'Mono- and diglycerides may be animal-derived',
  e472:             'Emulsifiers may be animal-derived',
  e473:             'Sucrose esters may be animal-derived',
  e927:             'Glycine may be animal-derived',
  rennet:           'Rennet may be animal-derived',
  whey:             'Whey is a dairy ingredient',
  'l-cysteine':     'L-cysteine may be animal-derived',
  'natural flavour':'Natural flavor may include animal-derived extracts',
  'natural flavor': 'Natural flavor may include animal-derived extracts',
  flavouring:       'Flavouring may include animal-derived extracts',
  flavoring:        'Flavoring may include animal-derived extracts',
  enzymes:          'Enzymes may be extracted from animal sources',
  glycerol:         'Glycerol may be animal-derived',
}

function matchesKeyword(ingredient: string, keyword: string): boolean {
  if (keyword === 'alcohol') {
    return /\balcohol\b(?![-\s]*free)/i.test(ingredient)
  }
  return new RegExp(`\\b${keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'i').test(ingredient)
}

function keywordAnalysis(ingredients: string[]) {
  const warnings: Record<string, string> = {}
  const haram: string[] = []
  const suspicious: string[] = []

  for (const ing of ingredients) {
    const lower = ing.toLowerCase()
    let foundHaram = false
    for (const [kw, reason] of Object.entries(HARAM_KW)) {
      if (matchesKeyword(lower, kw)) {
        warnings[ing] = reason
        haram.push(ing)
        foundHaram = true
        break
      }
    }
    if (foundHaram) continue
    for (const [kw, reason] of Object.entries(SUSPICIOUS_KW)) {
      if (matchesKeyword(lower, kw)) {
        warnings[ing] = reason
        suspicious.push(ing)
        break
      }
    }
  }

  const explanation = haram.length > 0
    ? `This product contains ingredient(s) that are not permissible: ${haram.join(', ')}. Assessed by keyword matching.`
    : suspicious.length > 0
      ? `No definitively haram ingredients found, but the following may be animal-derived: ${suspicious.join(', ')}. Assessed by keyword matching.`
      : ingredients.length === 0
        ? 'No ingredient data available to analyze.'
        : 'No haram or suspicious ingredients detected. Assessed by keyword matching.'

  return { isHalal: haram.length === 0, haram, suspicious, warnings, explanation }
}

// ── image URL optimizer ──────────────────────────────────────────────────────

function optImg(url?: string): string | null {
  if (!url) return null
  return url.replace('.100.', '.400.').replace('.200.', '.400.').replace('.300.', '.400.')
}

// ── snake_case DB row → camelCase Flutter Product ────────────────────────────

// deno-lint-ignore no-explicit-any
function toProduct(row: Record<string, any>) {
  return {
    barcode:               row.barcode,
    name:                  row.name,
    ingredients:           row.ingredients,
    isHalal:               row.is_halal,
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
  }
}

// ── main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { barcode } = await req.json()
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

    // 1. Cache hit?
    const { data: cached } = await supabase
      .from('products')
      .select('*')
      .eq('barcode', barcode)
      .single()

    if (cached) {
      const age = Date.now() - new Date(cached.fetched_at).getTime()
      if (age < CACHE_TTL_MS) {
        return new Response(
          JSON.stringify({ product: toProduct(cached) }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    // 2. Fetch OpenFoodFacts
    const offRes = await fetch(`${OFF_BASE}/${barcode}.json`)
    if (!offRes.ok) throw new Error(`OpenFoodFacts HTTP ${offRes.status}`)

    const offData = await offRes.json()
    if (offData.status === 0) {
      return new Response(
        JSON.stringify({ product: null }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const pd = offData.product
    const name: string = pd.product_name || 'Unknown Product'
    const ingredientsText: string = (pd.ingredients_text ?? '').toLowerCase()
    const ingredients: string[] = ingredientsText
      .split(/[,;]/)
      .map((s: string) => s.trim())
      .filter((s: string) => s.length > 0)

    const labelSet = new Set<string>()
    const addLabels = (v: unknown) => {
      if (!v) return
      const parts = typeof v === 'string' ? v.split(/[,;]/) : (v as string[])
      parts.forEach((p: string) => { const n = p.trim().toLowerCase(); if (n) labelSet.add(n) })
    }
    addLabels(pd.labels); addLabels(pd.labels_tags)
    addLabels(pd.labels_hierarchy); addLabels(pd.labels_en)
    const labels = [...labelSet]

    // 3. Claude analysis (with keyword fallback)
    let isHalal = true
    let haramIngredients: string[] = []
    let suspiciousIngredients: string[] = []
    let ingredientWarnings: Record<string, string> = {}
    let explanation = ''
    let analyzedByAI = false

    const claudeKey = Deno.env.get('CLAUDE_API_KEY')
    if (claudeKey) {
      const claudeRes = await fetch(CLAUDE_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': claudeKey,
          'anthropic-version': '2023-06-01',
          'anthropic-beta': 'prompt-caching-2024-07-31',
        },
        body: JSON.stringify({
          model: CLAUDE_MODEL,
          max_tokens: 1024,
          system: [{ type: 'text', text: CLAUDE_SYSTEM, cache_control: { type: 'ephemeral' } }],
          messages: [{ role: 'user', content: `Analyze these ingredients:\n${ingredients.join(', ')}` }],
        }),
      })

      if (claudeRes.ok) {
        const cd = await claudeRes.json()
        const text: string = cd.content?.find((c: { type: string }) => c.type === 'text')?.text ?? ''
        try {
          const p = JSON.parse(text.trim())
          isHalal             = p.isHalal ?? true
          haramIngredients    = p.haramIngredients ?? []
          suspiciousIngredients = p.suspiciousIngredients ?? []
          ingredientWarnings  = p.ingredientWarnings ?? {}
          explanation         = p.explanation ?? ''
          analyzedByAI        = true
        } catch { /* fall through to keyword analysis */ }
      }
    }

    if (!analyzedByAI) {
      const kw = keywordAnalysis(ingredients)
      isHalal             = kw.isHalal
      haramIngredients    = kw.haram
      suspiciousIngredients = kw.suspicious
      ingredientWarnings  = kw.warnings
      explanation         = kw.explanation
    }

    // 4. Upsert to DB
    const row = {
      barcode,
      name,
      ingredients,
      is_halal:               isHalal,
      haram_ingredients:      haramIngredients,
      suspicious_ingredients: suspiciousIngredients,
      ingredient_warnings:    ingredientWarnings,
      labels,
      image_url:              optImg(pd.image_url),
      image_front_url:        optImg(pd.image_front_url),
      image_ingredients_url:  optImg(pd.image_ingredients_url),
      image_nutrition_url:    optImg(pd.image_nutrition_url),
      explanation,
      analyzed_by_ai:         analyzedByAI,
      fetched_at:             new Date().toISOString(),
    }

    const { data: upserted, error: upsertErr } = await supabase
      .from('products')
      .upsert(row)
      .select()
      .single()

    if (upsertErr) throw upsertErr

    return new Response(
      JSON.stringify({ product: toProduct(upserted) }),
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
