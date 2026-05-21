const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CLAUDE_URL = 'https://api.anthropic.com/v1/messages'
const CLAUDE_MODEL = 'claude-haiku-4-5'

const GEMINI_URL_BASE = 'https://generativelanguage.googleapis.com/v1beta/models'
const GEMINI_MODEL = 'gemini-2.5-flash'

const OCR_SYSTEM = `You are an OCR assistant specialized in reading food product ingredient labels.
Given an image of a food product label, extract ONLY the ingredient list text.
IMPORTANT: Only extract the INGREDIENT LIST — text that starts with words like "Ingredients:", "Zutaten:", "İçindekiler:", "Ingrédients:", "Ingrediënten:", "Ingredienser:", "Összetevők:", "Ingredientes:", "Состав:", "成分:" or similar headings in any language.
Do NOT extract nutrition facts, energy values (kJ/kcal), protein, fat, carbohydrate tables, allergen-only boxes, or any other non-ingredient text.
Return a raw JSON object only — no markdown, no prose:
{
  "ingredients_text": "the full ingredient list text as a single string, preserving original language"
}
If you cannot find an ingredient list in the image (e.g. the image only shows nutrition facts, front label, or barcode), return:
{
  "ingredients_text": null
}`

const OCR_PROMPT = 'This image shows a food product label. Extract ONLY the ingredient list (e.g. starting with "Ingredients:", "Zutaten:", etc.). Do NOT extract nutrition tables, energy values, or other label sections. Return the ingredient list text as-is in the original language. If no ingredient list is visible, return null. Respond with the JSON format specified.'

// Ingredient-list heading keywords across common languages.
const INGREDIENT_HEADINGS = [
  'ingredients', 'zutaten', 'içindekiler', 'ingrédients', 'ingrediënten',
  'ingredienser', 'összetevők', 'ingredientes', 'состав', '成分',
  'składniki', 'ingredienti', 'sastojci', 'ainekset', 'ingrediente',
]

// Nutrition-table keywords — if the text is dominated by these, it's not ingredients.
const NUTRITION_KEYWORDS = [
  'nährwerte', 'nutrition facts', 'nutritional information', 'valeurs nutritionnelles',
  'energy', 'energie', 'kcal', 'protein', 'eiweiß', 'kohlenhydrate', 'carbohydrate',
  'davon zucker', 'of which sugars', 'besin değeri', 'enerji',
]

// Validate that extracted text looks like an ingredient list, not a nutrition table.
function looksLikeIngredients(text: string): boolean {
  const lower = text.toLowerCase()
  // Positive: contains an ingredient heading
  const hasHeading = INGREDIENT_HEADINGS.some(h => lower.includes(h))
  // Negative: dominated by nutrition keywords
  const nutritionHits = NUTRITION_KEYWORDS.filter(k => lower.includes(k)).length
  // If 3+ nutrition keywords and no ingredient heading → likely a nutrition table
  if (nutritionHits >= 3 && !hasHeading) return false
  // If it has an ingredient heading, trust it
  if (hasHeading) return true
  // Heuristic: ingredient lists typically use commas to separate items
  const commaCount = (text.match(/,/g) || []).length
  return commaCount >= 2
}

// Resolve image to base64+mimeType from either a URL or inline base64 data.
async function resolveImage(imageUrl: string | null, imageBase64: string | null): Promise<{ base64: string; mimeType: string } | null> {
  if (imageBase64) {
    return { base64: imageBase64, mimeType: 'image/jpeg' }
  }
  if (!imageUrl) return null
  try {
    const imgRes = await fetch(imageUrl)
    if (!imgRes.ok) return null
    const imgBuf = await imgRes.arrayBuffer()
    const bytes = new Uint8Array(imgBuf)
    let binary = ''
    const chunkSize = 0x8000
    for (let i = 0; i < bytes.length; i += chunkSize) {
      binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize))
    }
    return {
      base64: btoa(binary),
      mimeType: imgRes.headers.get('content-type') || 'image/jpeg',
    }
  } catch (e) {
    console.error('[extract-ingredients] Image fetch failed:', e)
    return null
  }
}

// Try to extract ingredients from a single image using Gemini, falling back to Claude.
async function extractFromSingleImage(
  imageUrl: string | null,
  imageBase64: string | null,
  geminiKey: string | null,
  geminiEnabled: boolean,
  claudeKey: string | null,
  claudeEnabled: boolean,
): Promise<{ text: string | null; hadError: boolean }> {
  let hadError = false

  // Try Gemini first (free tier)
  if (geminiEnabled && geminiKey) {
    try {
      const img = await resolveImage(imageUrl, imageBase64)
      if (img) {
        const geminiRes = await fetch(
          `${GEMINI_URL_BASE}/${GEMINI_MODEL}:generateContent?key=${geminiKey}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [{
                parts: [
                  { inlineData: { mimeType: img.mimeType, data: img.base64 } },
                  { text: OCR_PROMPT },
                ],
              }],
              systemInstruction: { parts: [{ text: OCR_SYSTEM }] },
              generationConfig: { maxOutputTokens: 1024, temperature: 0 },
            }),
          },
        )
        if (geminiRes.ok) {
          const gd = await geminiRes.json()
          const text: string = gd.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
          try {
            const p = JSON.parse(text.replace(/```json\n?|\n?```/g, '').trim())
            if (p.ingredients_text && looksLikeIngredients(p.ingredients_text)) {
              console.log('[extract-ingredients] Gemini vision: success')
              return { text: p.ingredients_text, hadError: false }
            }
            if (p.ingredients_text) {
              console.log('[extract-ingredients] Gemini vision: extracted text failed validation (likely nutrition table)')
            }
          } catch (e) {
            console.error('[extract-ingredients] Gemini vision: JSON parse failed:', e)
          }
        } else {
          console.error(`[extract-ingredients] Gemini vision: HTTP ${geminiRes.status}`)
          hadError = true
        }
      }
    } catch (e) {
      console.error('[extract-ingredients] Gemini vision: exception:', e)
      hadError = true
    }
  }

  // Fallback: Claude vision
  if (claudeEnabled && claudeKey) {
    try {
      const img = await resolveImage(imageUrl, imageBase64)
      if (!img) return { text: null, hadError }
      const imageContent = {
        type: 'image' as const,
        source: { type: 'base64' as const, media_type: img.mimeType as 'image/jpeg', data: img.base64 },
      }
      const claudeRes = await fetch(CLAUDE_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': claudeKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: CLAUDE_MODEL,
          max_tokens: 1024,
          system: OCR_SYSTEM,
          messages: [{
            role: 'user',
            content: [
              imageContent,
              { type: 'text', text: OCR_PROMPT },
            ],
          }],
        }),
      })
      if (claudeRes.ok) {
        const cd = await claudeRes.json()
        const text: string = cd.content?.find((c: { type: string }) => c.type === 'text')?.text ?? ''
        try {
          const p = JSON.parse(text.replace(/```json\n?|\n?```/g, '').trim())
          if (p.ingredients_text && looksLikeIngredients(p.ingredients_text)) {
            console.log('[extract-ingredients] Claude vision: success')
            return { text: p.ingredients_text, hadError: false }
          }
          if (p.ingredients_text) {
            console.log('[extract-ingredients] Claude vision: extracted text failed validation (likely nutrition table)')
          }
        } catch (e) {
          console.error('[extract-ingredients] Claude vision: JSON parse failed:', e)
        }
      } else {
        const errBody = await claudeRes.text()
        console.error(`[extract-ingredients] Claude vision: HTTP ${claudeRes.status} — ${errBody}`)
        hadError = true
      }
    } catch (e) {
      console.error('[extract-ingredients] Claude vision: exception:', e)
      hadError = true
    }
  }

  return { text: null, hadError }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const imageUrl: string | null = body.image_url ?? null
    const imageUrls: string[] = body.image_urls ?? []
    const imageBase64: string | null = body.image_base64 ?? null

    if (!imageUrl && imageUrls.length === 0 && !imageBase64) {
      return new Response(
        JSON.stringify({ error: 'image_url, image_urls, or image_base64 is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
    const claudeKey = Deno.env.get('CLAUDE_API_KEY')
    const claudeEnabled = Deno.env.get('CLAUDE_ENABLED') !== 'false'

    // Single image (base64 or URL) — direct extraction
    if (imageBase64 || (imageUrl && imageUrls.length === 0)) {
      const { text, hadError } = await extractFromSingleImage(imageUrl, imageBase64, geminiKey, geminiEnabled, claudeKey, claudeEnabled)
      return new Response(
        JSON.stringify({ ingredients_text: text, reason: text ? undefined : (hadError ? 'model_error' : 'not_found') }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Multiple image URLs — try each in order until one yields valid ingredients
    const candidates = imageUrl ? [imageUrl, ...imageUrls.filter(u => u !== imageUrl)] : imageUrls
    let anyError = false
    for (const url of candidates) {
      console.log(`[extract-ingredients] Trying image: ${url}`)
      const { text, hadError } = await extractFromSingleImage(url, null, geminiKey, geminiEnabled, claudeKey, claudeEnabled)
      if (hadError) anyError = true
      if (text) {
        return new Response(
          JSON.stringify({ ingredients_text: text }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    // None of the images yielded valid ingredients
    return new Response(
      JSON.stringify({ ingredients_text: null, reason: anyError ? 'model_error' : 'not_found' }),
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
