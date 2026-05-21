import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const OFF_BASE = 'https://world.openfoodfacts.org/api/v0/product'
const OBF_BASE = 'https://world.openbeautyfacts.org/api/v0/product'
const OPF_BASE = 'https://world.openproductsfacts.org/api/v0/product'
const CLAUDE_URL = 'https://api.anthropic.com/v1/messages'
const CLAUDE_MODEL = 'claude-haiku-4-5'
const GEMINI_URL_BASE = 'https://generativelanguage.googleapis.com/v1beta/models'
const GEMINI_MODEL = 'gemini-2.5-flash'

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
  ['whey', 'Whey is a dairy ingredient — source verification recommended.',
   'whey', 'molke', 'lactosérum', 'siero di latte',
   'suero de leche', 'peynir suyu', 'wei'],
  ['l-cysteine', 'L-cysteine may be animal-derived',
   'l-cysteine', 'l-cystein', 'l-cystéine', 'l-cisteina', 'l-sistein'],
  ['natural flavour', 'Natural flavor may include animal-derived extracts',
   'natural flavour', 'natural flavor', 'natürliches aroma',
   'natürliche aromen', 'arôme naturel', 'aroma naturale',
   'aroma natural', 'doğal aroma', 'natuurlijk aroma'],
  ['flavouring', 'Aroma / Flavouring — source often unknown.',
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

// Negation words across all supported languages (EN/DE/FR/NL/IT/ES/TR/CS/SR/HU).
// Used to suppress false positives like "enthält keine Zutaten vom Schwein".
const NEGATION_WORDS = /\b(?:keine?|nicht|ohne|frei\s+von|sans|pas|geen|zonder|vrij\s+van|no|not|without|free\s+from|free\s+of|senza|sin|içermez|içermemektedir|neobsahuje|bez|nema|nem|mentes)\b/i

function escape(s: string) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') }

// Unicode-aware word boundaries covering basic Latin + extended Latin (À-ɏ, U+00C0-U+024F).
// ß (U+00DF) is added explicitly to guard against case-folding edge cases.
// Mirrors IngredientKeywords.wPre / wPost in the Dart client.
const wPre = '(?<![a-zA-Z\\dÀ-ɏß])'
const wPost = '(?![a-zA-Z\\dÀ-ɏß])'

function isZeroPercentAlcoholDeclaration(text: string, variant: string): boolean {
  const v = escape(variant)
  return new RegExp(
    `\\b0(?:[.,]0+)?\\s*%\\s*${v}(?:\\b|(?![a-zA-Z\\dÀ-ɏß]))|\\b${v}(?:\\b|(?![a-zA-Z\\dÀ-ɏß]))\\s*(?:\\(?\\s*)?0(?:[.,]0+)?\\s*%`,
    'i',
  ).test(text)
}

function matchesVariant(ingredient: string, variant: string): boolean {
  if (variant.includes(' ')) return ingredient.includes(variant)
  if (ALCOHOL_FAMILY.has(variant)) {
    if (FATTY_ALCOHOL_PREFIX.test(ingredient)) return false
    if (isZeroPercentAlcoholDeclaration(ingredient, variant)) return false
    return new RegExp(`${wPre}${escape(variant)}${wPost}(?![-\\s]*free)`, 'i').test(ingredient)
  }
  return new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').test(ingredient)
}

// True when the matched variant is preceded by a negation word in the same
// ingredient chunk, e.g. "enthält keine Zutaten vom Schwein" → negated.
function isNegated(chunk: string, variant: string): boolean {
  const lower = chunk.toLowerCase()
  let idx: number
  if (variant.includes(' ')) {
    idx = lower.indexOf(variant.toLowerCase())
  } else {
    const m = new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').exec(lower)
    idx = m ? m.index : -1
  }
  if (idx < 0) return false
  return NEGATION_WORDS.test(lower.substring(0, idx))
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
      const matchedVariant = (entry.slice(2) as string[]).find(v => matchesVariant(lower, v))
      if (matchedVariant && !isNegated(lower, matchedVariant)) {
        warnings[ing] = entry[1]; haram.push(ing); foundHaram = true; break
      }
    }
    if (foundHaram) continue
    for (const entry of allSuspicious) {
      const matchedVariant = (entry.slice(2) as string[]).find(v => matchesVariant(lower, v))
      if (matchedVariant && !isNegated(lower, matchedVariant)) {
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
    for (const lang of ['en', 'nl', 'de', 'fr', 'tr', 'es', 'it', 'sr', 'hu', 'cs']) {
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
function isStale(row: Record<string, any>): boolean {
  if (!row.updated_at) return false
  if (!row.last_analysed_at) return true
  return new Date(row.last_analysed_at) < new Date(row.updated_at)
}

// ── main handler ─────────────────────────────────────────────────────────────

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

    // 1. Cache hit?
    const { data: cached } = await supabase
      .from('products_full')
      .select('*')
      .eq('barcode', barcode)
      .maybeSingle()

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
    // OFf is only ever fetched on the very first scan (cached === null below).
    // Unknown products with force=true fall through so OFf can be retried.
    // fetchAiIngredients bypasses this path entirely so Gemini lookup can run.
    if (!fetchAiIngredients && cached && (isStale(cached) || (force && !cached.is_unknown))) {
      const reason = isStale(cached) ? 'stale (updated_at > last_analysed_at)' : 'force-refresh'
      console.log(`[${barcode}] ${reason} — re-running rules engine on stored data`)

      const { data: kwRows } = await supabase
        .from('keywords')
        .select('canonical, category, reason, variants')
      const reHaramEntries: [string, string, ...string[]][] = []
      const reSuspiciousEntries: [string, string, ...string[]][] = []
      if (kwRows) {
        for (const kw of kwRows) {
          const variants = Array.isArray(kw.variants) && kw.variants.length > 0
            ? kw.variants as string[]
            : [kw.canonical as string]
          const entry: [string, string, ...string[]] = [kw.canonical as string, kw.reason as string, ...variants]
          if (kw.category === 'haram') reHaramEntries.push(entry)
          else reSuspiciousEntries.push(entry)
        }
      }

      const storedIngredients: string[] = Array.isArray(cached.ingredients) ? cached.ingredients : []
      const kw = keywordAnalysis(storedIngredients, reHaramEntries, reSuspiciousEntries)

      let reHalal      = kw.isHalal
      let reUnknown    = kw.isUnknown
      let reHaram      = kw.haram
      let reSuspicious = kw.suspicious
      let reWarnings   = kw.warnings
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
        ingredients:           cached.ingredients,
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
        ingredient_source:     cached.ingredient_source ?? 'off',
      }

      await supabase.from('products').upsert({
        barcode:               cached.barcode,
        name:                  cached.name,
        ingredients:           cached.ingredients,
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
        ingredient_source:     cached.ingredient_source ?? 'off',
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
      return new Response(
        JSON.stringify({ product: toProduct(cached) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
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

    // 3. Fetch product from Open*Facts databases in order.
    // Products found via OBF (beauty) or OPF (general products) are non-food.
    let pd = await fetchFromFoodApi(barcode, OFF_BASE)
    let isNonFood = false
    if (!pd) { pd = await fetchFromFoodApi(barcode, OBF_BASE); if (pd) isNonFood = true }
    if (!pd) { pd = await fetchFromFoodApi(barcode, OPF_BASE); if (pd) isNonFood = true }

    // If OFf found the product but has no ingredient data, also probe OBF/OPF.
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
    const ingredientsText = extractIngredientsText(pd)
    let ingredients: string[] = ingredientsText
      .split(/[,;]/)
      .map((s: string) => s.trim())
      .filter((s: string) => s.length > 0)

    let ingredientSource: 'off' | 'ai' | 'community' = ingredients.length > 0 ? 'off' : 'off'

    // Gemini knowledge lookup — when OFF has no ingredient text, ask Gemini to recall
    // the ingredient list from its training data. No web search, no halal verdict — just ingredients.
    if (ingredients.length === 0 && name !== 'Unknown Product') {
      const _geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
      const _geminiKey = Deno.env.get('GEMINI_API_KEY')
      if (_geminiEnabled && _geminiKey) {
        console.log(`[${barcode}] Gemini ingredient lookup: asking for ingredients of "${name}"...`)
        try {
          const lookupRes = await fetch(
            `${GEMINI_URL_BASE}/${GEMINI_MODEL}:generateContent?key=${_geminiKey}`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                contents: [{ parts: [{ text: `What are the ingredients of the food product "${name}" (barcode: ${barcode})? If you know the ingredient list, respond with ONLY a comma-separated list of ingredients in English, nothing else. If you do not know, respond with exactly: UNKNOWN` }] }],
                generationConfig: { maxOutputTokens: 512, temperature: 0 },
              }),
            },
          )
          if (lookupRes.ok) {
            const ld = await lookupRes.json()
            const text: string = (ld.candidates?.[0]?.content?.parts?.[0]?.text ?? '').trim()
            const usage = ld.usageMetadata
            console.log(`[${barcode}] Gemini ingredient lookup: response="${text.slice(0, 120)}" prompt=${usage?.promptTokenCount ?? '?'} total=${usage?.totalTokenCount ?? '?'} tokens`)
            if (text && text.toUpperCase() !== 'UNKNOWN') {
              ingredients = text.split(',').map((s: string) => s.trim()).filter((s: string) => s.length > 0)
              ingredientSource = 'ai'
              console.log(`[${barcode}] Gemini ingredient lookup: found ${ingredients.length} ingredients`)
            }
          } else {
            const errBody = await lookupRes.text()
            console.error(`[${barcode}] Gemini ingredient lookup: HTTP ${lookupRes.status} — ${errBody}`)
          }
        } catch (e) {
          console.error(`[${barcode}] Gemini ingredient lookup: exception:`, e)
        }
      }
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

    // Category-based detection: OFf categories that unambiguously indicate alcohol
    const HARAM_CATEGORIES = new Set([
      'en:alcoholic-beverages', 'en:beers', 'en:wines',
      'en:spirits', 'en:champagnes', 'en:ciders', 'en:sake',
    ])
    // Categories that are inherently halal — mark halal even with no ingredients.
    const HALAL_CATEGORIES = new Set([
      'en:waters', 'en:bottled-waters', 'en:mineral-waters', 'en:spring-waters',
      'en:carbonated-waters', 'en:sparkling-waters', 'en:natural-mineral-waters',
      'en:still-natural-mineral-waters', 'en:still-waters', 'en:sparkling-mineral-waters',
      'en:flavoured-waters', 'en:table-waters', 'en:drinking-water',
      'en:salts', 'en:table-salt', 'en:sea-salt',
      'en:sugars', 'en:white-sugar', 'en:cane-sugar', 'en:granulated-sugar',
      'en:vinegars',
    ])
    // OFF categories that indicate non-food items even when found in the food database.
    const NON_FOOD_CATEGORIES = new Set([
      'en:non-food-products',
      'en:cosmetics', 'en:beauty-products', 'en:body-care',
      'en:make-up', 'en:fragrances',
      'en:oral-care', 'en:oral-hygiene',
      'en:personal-care', 'en:hygiene-products',
      'en:cleaning', 'en:cleaning-products', 'en:cleaning-agents',
      'en:household-products', 'en:household-chemicals',
      'en:laundry', 'en:laundry-products', 'en:dishwashing',
      'en:pet-food', 'en:pet-foods', 'en:cat-food', 'en:cat-foods',
      'en:dog-food', 'en:dog-foods', 'en:pet-care',
      'en:plant-care',
      'en:baby-care', 'en:diapers', 'en:baby-wipes', 'en:baby-lotions',
      'en:office-products', 'en:stationery',
    ])
    // OFf category tags that indicate animal/meat products requiring halal slaughter
    // certification. If a product is in one of these categories but has no halal
    // label, it is flagged as not halal regardless of ingredient analysis.
    const ANIMAL_PRODUCT_CATEGORIES = new Set([
      // English canonical
      'en:meats', 'en:meat', 'en:fresh-meats', 'en:processed-meats',
      'en:meat-products', 'en:meat-based-products', 'en:beef', 'en:beef-products',
      'en:veal', 'en:lamb', 'en:mutton', 'en:lamb-and-mutton', 'en:sheep-meat',
      'en:poultry', 'en:chicken', 'en:turkey', 'en:duck', 'en:goose',
      'en:poultry-products', 'en:chicken-products', 'en:sausages', 'en:deli-meats',
      'en:cold-cuts', 'en:charcuterie', 'en:burgers', 'en:meatballs',
      // German
      'de:fleisch', 'de:fleischwaren', 'de:fleischerzeugnisse', 'de:frisches-fleisch',
      'de:rindfleisch', 'de:kalbfleisch', 'de:lammfleisch', 'de:hammelfleisch',
      'de:geflügel', 'de:geflügelfleisch', 'de:hähnchenfleisch', 'de:putenfleisch',
      'de:entenfleisch', 'de:hackfleisch', 'de:faschiertes', 'de:wurstwaren',
      'de:wurst', 'de:aufschnitt', 'de:frikadellen', 'de:burger',
      // Turkish
      'tr:et', 'tr:et-urunleri', 'tr:et-ürünleri', 'tr:sigir-eti', 'tr:sığır-eti',
      'tr:dana-eti', 'tr:kuzu-eti', 'tr:tavuk', 'tr:tavuk-eti', 'tr:hindi-eti',
      'tr:kiyma', 'tr:kıyma', 'tr:sucuk', 'tr:sosis', 'tr:köfte', 'tr:kofte',
    ])
    // Label strings that indicate a recognised halal certification.
    const HALAL_CERT_LABELS = new Set([
      'halal', 'halal certified', 'halal certificate', 'certified halal',
      'hfa halal', 'halal hfa', 'ifanca', 'isna halal', 'muis halal',
      'muslim consumer group',
    ])
    // Terms used to detect animal/meat products from the product name alone.
    const ANIMAL_PRODUCT_NAME_TERMS = new Set([
      // German / Austrian
      'fleisch', 'faschiertes', 'hackfleisch', 'geschnetzeltes', 'schnitzel',
      'gulasch', 'braten', 'würstchen', 'geflügel', 'rindfleisch', 'kalbfleisch',
      'lammfleisch', 'hähnchenfleisch', 'putenfleisch', 'frikadelle', 'frikadellen',
      // English
      'minced meat', 'ground beef', 'ground chicken', 'ground turkey',
      'chicken breast', 'chicken thigh', 'beef steak', 'lamb chop',
      // French
      'viande', 'poulet haché', 'bœuf haché',
      // Turkish
      'kıyma', 'tavuk göğsü', 'kuzu eti', 'dana eti', 'sığır eti',
      'tavuk but', 'tavuk kanat', 'köfte', 'sucuk', 'kavurma',
    ])
    if (!isNonFood && rawCategories.some(c => NON_FOOD_CATEGORIES.has(c.toLowerCase()))) isNonFood = true
    const haramCategory = isNonFood ? null : (rawCategories.find(c => HARAM_CATEGORIES.has(c.toLowerCase())) ?? null)
    const isHalalByCategory = !isNonFood && !haramCategory && rawCategories.some(c => HALAL_CATEGORIES.has(c.toLowerCase()))

    // 4. Tiered AI analysis — keyword-first to minimize cost.
    // Run keywords upfront; skip AI entirely when the result is already determined.
    const kwFirst = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
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
    let analyzedByAI          = false

    const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
    const claudeEnabled = Deno.env.get('CLAUDE_ENABLED') !== 'false'

    // Skip AI when keywords already found haram, product is in a haram category,
    // is non-food, halal-by-category, or there are no ingredients.
    const skipAI = isNonFood || isHalalByCategory || kwFirst.haram.length > 0 || haramCategory !== null || ingredients.length === 0
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
        console.log(`[${barcode}] Gemini: calling ${GEMINI_MODEL}...`)
        try {
          const geminiRes = await fetch(
            `${GEMINI_URL_BASE}/${GEMINI_MODEL}:generateContent?key=${geminiKey}`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                contents: [{ parts: [{ text: `Analyze these ingredients:\n${ingredients.join(', ')}` }] }],
                systemInstruction: { parts: [{ text: CLAUDE_SYSTEM }] },
                generationConfig: { maxOutputTokens: 1024, temperature: 0 },
              }),
            },
          )
          if (geminiRes.ok) {
            const gd = await geminiRes.json()
            const text: string = gd.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
            try {
              const p = JSON.parse(text.replace(/```json\n?|\n?```/g, '').trim())
              isHalal               = p.isHalal ?? false
              isUnknown             = p.isUnknown ?? (ingredients.length === 0)
              haramIngredients      = p.haramIngredients ?? []
              suspiciousIngredients = p.suspiciousIngredients ?? []
              ingredientWarnings    = p.ingredientWarnings ?? {}
              explanation           = p.explanation ?? ''
              analyzedByAI          = true
              console.log(`[${barcode}] Gemini: success`)
            } catch (e) {
              console.error(`[${barcode}] Gemini: JSON parse failed:`, e)
            }
          } else {
            const body = await geminiRes.text()
            console.error(`[${barcode}] Gemini: HTTP ${geminiRes.status} — ${body}`)
          }
        } catch (e) {
          console.error(`[${barcode}] Gemini: exception:`, e)
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
          console.log(`[${barcode}] Claude: calling ${CLAUDE_MODEL}...`)
        }
        if (claudeEnabled && claudeKey) {
          try {
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
                const p = JSON.parse(text.replace(/```json\n?|\n?```/g, '').trim())
                isHalal               = p.isHalal ?? false
                isUnknown             = p.isUnknown ?? (ingredients.length === 0)
                haramIngredients      = p.haramIngredients ?? []
                suspiciousIngredients = p.suspiciousIngredients ?? []
                ingredientWarnings    = p.ingredientWarnings ?? {}
                explanation           = p.explanation ?? ''
                analyzedByAI          = true
                console.log(`[${barcode}] Claude: success`)
              } catch (e) {
                console.error(`[${barcode}] Claude: JSON parse failed:`, e)
              }
            } else {
              const body = await claudeRes.text()
              console.error(`[${barcode}] Claude: HTTP ${claudeRes.status} — ${body}`)
            }
          } catch (e) {
            console.error(`[${barcode}] Claude: exception:`, e)
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
      }
      if (claudeEnabled && imgUrl && claudeKey) {
        console.log(`[${barcode}] Claude vision: calling...`)
        try {
          const visionRes = await fetch(CLAUDE_URL, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': claudeKey,
              'anthropic-version': '2023-06-01',
            },
            body: JSON.stringify({
              model: CLAUDE_MODEL,
              max_tokens: 1024,
              system: CLAUDE_SYSTEM,
              messages: [{
                role: 'user',
                content: [
                  { type: 'image', source: { type: 'url', url: imgUrl } },
                  { type: 'text', text: 'This image shows the ingredients label of a food product. The text may be in Arabic, Turkish, or another language. The ingredient list is NOT empty — it is visible in the image. Read ALL the ingredient names from the image, translate them to English, and determine if the product is halal. Set isUnknown to false if you can read any ingredients. Respond with the JSON format specified.' },
                ],
              }],
            }),
          })
          if (visionRes.ok) {
            const cd = await visionRes.json()
            const text: string = cd.content?.find((c: { type: string }) => c.type === 'text')?.text ?? ''
            try {
              const p = JSON.parse(text.replace(/```json\n?|\n?```/g, '').trim())
              isHalal               = p.isHalal ?? false
              isUnknown             = p.isUnknown ?? true
              haramIngredients      = p.haramIngredients ?? []
              suspiciousIngredients = p.suspiciousIngredients ?? []
              ingredientWarnings    = p.ingredientWarnings ?? {}
              explanation           = p.explanation ?? ''
              analyzedByAI          = true
              console.log(`[${barcode}] Claude vision: success`)
            } catch (e) {
              console.error(`[${barcode}] Claude vision: JSON parse failed:`, e)
            }
          } else {
            const body = await visionRes.text()
            console.error(`[${barcode}] Claude vision: HTTP ${visionRes.status} — ${body}`)
          }
        } catch (e) {
          console.error('[lookup-product] Vision Claude request failed:', e)
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

    // Adjust isHalal for requiresHalalCert
    if (requiresHalalCert) {
      isHalal = false
      isUnknown = false
    }

    // 5. Upsert to DB — products owns source data, product_analysis owns the verdict.
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

    return new Response(
      JSON.stringify({ product: toProduct(row) }),
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
