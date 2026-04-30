import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000
const OFF_BASE = 'https://world.openfoodfacts.org/api/v0/product'
const OBF_BASE = 'https://world.openbeautyfacts.org/api/v0/product'
const OPF_BASE = 'https://world.openproductsfacts.org/api/v0/product'
const CLAUDE_URL = 'https://api.anthropic.com/v1/messages'
const CLAUDE_MODEL = 'claude-haiku-4-5'

const CLAUDE_SYSTEM = `You are an expert in Islamic dietary laws (halal). Analyze ingredient lists and determine if a product is halal.

Respond with a raw JSON object only — no markdown, no prose outside the JSON:
{
  "isHalal": boolean,
  "isUnknown": boolean,
  "haramIngredients": ["ingredient names that are definitively haram"],
  "suspiciousIngredients": ["ingredient names that may be non-halal"],
  "ingredientWarnings": {"ingredient name": "reason why haram or suspicious"},
  "explanation": "2-3 sentence plain-language summary of the verdict and the key reasons"
}

Haram: pork and derivatives (lard, bacon, ham, pepperoni, salami, chorizo, prosciutto, pork gelatin), alcohol (ethanol, wine, beer), blood, carnivorous animals, insects (carmine, cochineal, E120).

Suspicious: gelatin (source unspecified), L-cysteine (E920), mono- and diglycerides (E471), rennet (non-microbial), enzymes (source unspecified), natural flavors (source unspecified), emulsifiers that may be animal-derived.

If the ingredients list is empty, set isHalal to false, isUnknown to true, and explanation to "No ingredient data found. Halal status cannot be determined — check the packaging directly."`

// ── keyword analysis (mirrors ProductService.dart) ───────────────────────────

const HARAM_ENTRIES: [string, string, ...string[]][] = [
  ['alcohol',    'Contains alcohol or alcohol-derived ingredient',
   'alcohol', 'alkohol', 'alcool', 'alcol', 'alkol', 'álcool'],
  ['ethanol',    'Contains alcohol or alcohol-derived ingredient',
   'ethanol', 'äthanol', 'éthanol', 'etanolo', 'etanol'],
  ['wine',       'Contains alcohol or alcohol-derived ingredient',
   'wine', 'wein', 'vin', 'vino', 'şarap', 'wijn', 'vinho'],
  ['beer',       'Contains alcohol or alcohol-derived ingredient',
   'beer', 'bier', 'bière', 'birra', 'cerveza', 'bira', 'cerveja'],
  ['cognac',    'Contains cognac (alcoholic spirit)',   'cognac', 'kognak'],
  ['brandy',    'Contains brandy (alcoholic spirit)',   'brandy', 'branntwein', 'brandewijn'],
  ['whisky',    'Contains whisky (alcoholic spirit)',   'whisky', 'whiskey', 'whiskie', 'viski'],
  ['vodka',     'Contains vodka (alcoholic spirit)',    'vodka', 'wodka'],
  ['rum',       'Contains rum (alcoholic spirit)',      'rum', 'rhum', 'ron'],
  ['gin',       'Contains gin (alcoholic spirit)',      'gin'],
  ['liqueur',   'Contains liqueur (alcoholic)',         'liqueur', 'likör', 'licor', 'likeur', 'liquore'],
  ['schnapps',  'Contains schnapps (alcoholic spirit)', 'schnapps', 'schnaps'],
  ['champagne', 'Contains champagne (alcoholic)',       'champagne', 'sekt', 'cava', 'spumante'],
  ['prosecco',  'Contains prosecco (alcoholic)',        'prosecco'],
  ['bourbon',   'Contains bourbon (alcoholic spirit)',  'bourbon'],
  ['sake',      'Contains sake (alcoholic)',            'sake', 'saké'],
  ['pork',       'Contains pork or pork-derived ingredient',
   'pork', 'schwein', 'schweinefleisch', 'porc', 'maiale', 'cerdo',
   'domuz', 'varkens', 'varkensvlees', 'porco'],
  ['lard',       'Contains pork fat',
   'lard', 'schmalz', 'schweineschmalz', 'saindoux', 'strutto',
   'manteca', 'domuz yağı', 'banha'],
  ['gelatin',    'Gelatin is typically animal-derived',
   'gelatin', 'gelatine', 'gelatina', 'jelatin', 'gélatine'],
  ['bacon',      'Contains pork product',
   'bacon', 'speck', 'lardons', 'pancetta', 'domuz pastırması'],
  ['ham',        'Contains pork product',
   'ham', 'schinken', 'jambon', 'prosciutto', 'jamón', 'presunto'],
  ['pepperoni',  'Contains pork product',   'pepperoni'],
  ['salami',     'Contains pork product',   'salami', 'salame'],
  ['chorizo',    'Contains pork product',   'chorizo'],
  ['prosciutto', 'Contains pork product',   'prosciutto'],
  ['carmine',    'Carmine/cochineal is insect-derived',
   'carmine', 'karmin', 'carmín', 'karmín', 'carmin'],
  ['cochineal',  'Carmine/cochineal is insect-derived',
   'cochineal', 'cochenille', 'cocciniglia', 'cochinilla', 'koşnil'],
  ['e120', 'Carmine/cochineal color, animal-derived', 'e120', 'e-120'],
  ['e441', 'Gelatin, animal-derived',       'e441', 'e-441'],
  ['e542', 'Bone phosphate, animal-derived','e542', 'e-542'],
  ['e904', 'Shellac, animal-derived',       'e904', 'e-904'],
]

const SUSPICIOUS_ENTRIES: [string, string, ...string[]][] = [
  ['e920', 'L-cysteine may be animal-derived',          'e920', 'e-920'],
  ['e322', 'Lecithin may be animal-derived',            'e322', 'e-322'],
  ['e471', 'Mono- and diglycerides may be animal-derived','e471','e-471'],
  ['e472', 'Emulsifiers may be animal-derived',         'e472', 'e-472'],
  ['e473', 'Sucrose esters may be animal-derived',      'e473', 'e-473'],
  ['e927', 'Glycine may be animal-derived',             'e927', 'e-927'],
  ['rennet', 'Rennet may be animal-derived',
   'rennet', 'lab', 'labferment', 'présure', 'caglio', 'cuajo',
   'peynir mayası', 'stremsel'],
  ['whey', 'Whey is a dairy ingredient',
   'whey', 'molke', 'lactosérum', 'siero di latte',
   'suero de leche', 'peynir suyu', 'wei'],
  ['l-cysteine', 'L-cysteine may be animal-derived',
   'l-cysteine', 'l-cystein', 'l-cystéine', 'l-cisteina', 'l-sistein'],
  ['natural flavour', 'Natural flavor may include animal-derived extracts',
   'natural flavour', 'natural flavor', 'natürliches aroma',
   'natürliche aromen', 'arôme naturel', 'aroma naturale',
   'aroma natural', 'doğal aroma', 'natuurlijk aroma'],
  ['flavouring', 'Flavouring may include animal-derived extracts',
   'flavouring', 'flavoring', 'aroma', 'arôme', 'smaakstof'],
  ['enzymes', 'Enzymes may be extracted from animal sources',
   'enzymes', 'enzyme', 'enzimi', 'enzimas', 'enzim', 'enzymen'],
  ['glycerol', 'Glycerol may be animal-derived',
   'glycerol', 'glycerin', 'glycérol', 'glicerina', 'gliserin', 'glycerine'],
]

const ALCOHOL_FAMILY = new Set([
  'alcohol','alkohol','alcool','alcol','alkol','álcool',
  'ethanol','äthanol','éthanol','etanolo','etanol',
])

const FATTY_ALCOHOL_PREFIX = /\b(cetyl|stearyl|behenyl|lauryl|myristyl|arachidyl|oleyl|cetostearyl|lanolin|isostearyl|octyldodecyl|decyl)\s+/i

function escape(s: string) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') }

function matchesVariant(ingredient: string, variant: string): boolean {
  if (variant.includes(' ')) return ingredient.includes(variant)
  if (ALCOHOL_FAMILY.has(variant)) {
    if (FATTY_ALCOHOL_PREFIX.test(ingredient)) return false
    return new RegExp(`\\b${escape(variant)}\\b(?![-\\s]*free)`, 'i').test(ingredient)
  }
  return new RegExp(`\\b${escape(variant)}\\b`, 'i').test(ingredient)
}

function matchesEntry(ingredient: string, entry: [string, string, ...string[]]): boolean {
  return (entry.slice(2) as string[]).some(v => matchesVariant(ingredient, v))
}

function keywordAnalysis(
  ingredients: string[],
  extraHaram: [string, string, ...string[]][] = [],
  extraSuspicious: [string, string, ...string[]][] = [],
) {
  const warnings: Record<string, string> = {}
  const haram: string[] = []
  const suspicious: string[] = []
  const allHaram = [...HARAM_ENTRIES, ...extraHaram]
  const allSuspicious = [...SUSPICIOUS_ENTRIES, ...extraSuspicious]

  for (const ing of ingredients) {
    const lower = ing.toLowerCase()
    let foundHaram = false
    for (const entry of allHaram) {
      if (matchesEntry(lower, entry)) {
        warnings[ing] = entry[1]; haram.push(ing); foundHaram = true; break
      }
    }
    if (foundHaram) continue
    for (const entry of allSuspicious) {
      if (matchesEntry(lower, entry)) {
        warnings[ing] = entry[1]; suspicious.push(ing); break
      }
    }
  }

  const isUnknown = ingredients.length === 0
  const explanation = haram.length > 0
    ? `This product contains ingredient(s) that are not permissible: ${haram.join(', ')}. Assessed by keyword matching.`
    : suspicious.length > 0
      ? `No definitively haram ingredients found, but the following may be animal-derived: ${suspicious.join(', ')}. Assessed by keyword matching.`
      : isUnknown
        ? 'No ingredient data found. Halal status cannot be determined — check the packaging directly.'
        : 'No haram or suspicious ingredients detected. Assessed by keyword matching.'

  return { isHalal: !isUnknown && haram.length === 0, isUnknown, haram, suspicious, warnings, explanation }
}

// ── image URL optimizer ──────────────────────────────────────────────────────

function optImg(url?: string): string | null {
  if (!url) return null
  return url.replace('.100.', '.400.').replace('.200.', '.400.').replace('.300.', '.400.')
}

// ── resolve image with selected_images fallback ──────────────────────────────

// deno-lint-ignore no-explicit-any
function resolveImg(pd: any, directField: string, selectedKey: string): string | null {
  const direct = optImg(pd[directField])
  if (direct) return direct
  const sel = pd['selected_images']
  if (sel && typeof sel === 'object') {
    const section = sel[selectedKey]
    if (section?.display && typeof section.display === 'object') {
      const first = Object.values(section.display)[0]
      if (typeof first === 'string') return optImg(first)
    }
  }
  return null
}

// ── fetch product data from one Open*Facts base URL ─────────────────────────

// deno-lint-ignore no-explicit-any
async function fetchFromFoodApi(barcode: string, baseUrl: string): Promise<any | null> {
  try {
    const res = await fetch(`${baseUrl}/${barcode}.json`)
    if (!res.ok) return null
    const data = await res.json()
    if (data.status === 0) return null
    return data.product
  } catch {
    return null
  }
}

// ── extract ingredients text with language + structured fallbacks ─────────────

// deno-lint-ignore no-explicit-any
function extractIngredientsText(pd: any): string {
  let text: string = (pd['ingredients_text'] ?? '').trim()
  if (!text) {
    for (const lang of ['en', 'nl', 'de', 'fr', 'tr', 'es', 'it']) {
      const t = (pd[`ingredients_text_${lang}`] ?? '').trim()
      if (t) { text = t; break }
    }
  }
  if (!text) {
    const structured = pd['ingredients']
    if (Array.isArray(structured) && structured.length > 0) {
      text = structured
        // deno-lint-ignore no-explicit-any
        .filter((i: any) => typeof i?.text === 'string')
        // deno-lint-ignore no-explicit-any
        .map((i: any) => i.text as string)
        .join(', ')
    }
  }
  return text.toLowerCase()
}

// ── snake_case DB row → camelCase Flutter Product ────────────────────────────

// deno-lint-ignore no-explicit-any
function toProduct(row: Record<string, any>) {
  return {
    barcode:               row.barcode,
    name:                  row.name,
    ingredients:           row.ingredients,
    isHalal:               row.is_halal,
    isUnknown:             row.is_unknown ?? false,
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
    const body = await req.json()
    const { barcode, force = false } = body
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

    if (cached && !force) {
      const age = Date.now() - new Date(cached.fetched_at).getTime()
      if (age < CACHE_TTL_MS) {
        return new Response(
          JSON.stringify({ product: toProduct(cached) }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    // 2. Load custom approved keywords from DB
    const customHaramEntries: [string, string, ...string[]][] = []
    const customSuspiciousEntries: [string, string, ...string[]][] = []
    const { data: customKeywords } = await supabase
      .from('keywords')
      .select('canonical, category, reason, variants')
    if (customKeywords) {
      for (const kw of customKeywords) {
        const variants: string[] = Array.isArray(kw.variants) && kw.variants.length > 0
          ? kw.variants as string[]
          : [kw.canonical as string]
        const entry: [string, string, ...string[]] = [kw.canonical as string, kw.reason as string, ...variants]
        if (kw.category === 'haram') customHaramEntries.push(entry)
        else customSuspiciousEntries.push(entry)
      }
    }

    // 3. Fetch product from Open*Facts databases in order
    let pd = await fetchFromFoodApi(barcode, OFF_BASE)
    if (!pd) pd = await fetchFromFoodApi(barcode, OBF_BASE)
    if (!pd) pd = await fetchFromFoodApi(barcode, OPF_BASE)

    if (!pd) {
      return new Response(
        JSON.stringify({ product: null }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const name: string = (pd.product_name?.trim() || pd.product_name_en?.trim() || pd.abbreviated_product_name?.trim() || 'Unknown Product')
    const ingredientsText = extractIngredientsText(pd)
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

    // Category-based detection: OFf categories that unambiguously indicate alcohol
    const HARAM_CATEGORIES = new Set([
      'en:alcoholic-beverages', 'en:beers', 'en:wines',
      'en:spirits', 'en:champagnes', 'en:ciders', 'en:sake',
    ])
    const rawCategories: string[] = Array.isArray(pd.categories_tags) ? pd.categories_tags : []
    const haramCategory = rawCategories.find(c => HARAM_CATEGORIES.has(c.toLowerCase())) ?? null

    // 4. Claude analysis (with keyword fallback)
    let isHalal = false
    let isUnknown = ingredients.length === 0 && !haramCategory
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
          isHalal               = p.isHalal ?? false
          isUnknown             = p.isUnknown ?? (ingredients.length === 0)
          haramIngredients      = p.haramIngredients ?? []
          suspiciousIngredients = p.suspiciousIngredients ?? []
          ingredientWarnings    = p.ingredientWarnings ?? {}
          explanation           = p.explanation ?? ''
          analyzedByAI          = true
        } catch { /* fall through to keyword analysis */ }
      }
    }

    if (!analyzedByAI) {
      const kw = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
      isHalal               = kw.isHalal
      isUnknown             = kw.isUnknown
      haramIngredients      = kw.haram
      suspiciousIngredients = kw.suspicious
      ingredientWarnings    = kw.warnings
      explanation           = kw.explanation
    }

    // Keyword safety override: haram keywords always win over AI verdict.
    const kwCheck = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
    if (!kwCheck.isHalal && isHalal) {
      isHalal            = false
      isUnknown          = false
      haramIngredients   = [...new Set([...haramIngredients, ...kwCheck.haram])]
      ingredientWarnings = { ...ingredientWarnings, ...kwCheck.warnings }
      explanation        = kwCheck.explanation
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

    // 5. Upsert to DB
    const row = {
      barcode,
      name,
      ingredients,
      is_halal:               isHalal,
      is_unknown:             isUnknown,
      haram_ingredients:      haramIngredients,
      suspicious_ingredients: suspiciousIngredients,
      ingredient_warnings:    ingredientWarnings,
      labels,
      image_url:              resolveImg(pd, 'image_url', 'front'),
      image_front_url:        resolveImg(pd, 'image_front_url', 'front'),
      image_ingredients_url:  resolveImg(pd, 'image_ingredients_url', 'ingredients'),
      image_nutrition_url:    resolveImg(pd, 'image_nutrition_url', 'nutrition'),
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
