const CLAUDE_URL = 'https://api.anthropic.com/v1/messages'
const CLAUDE_MODEL = 'claude-haiku-4-5'
const GEMINI_URL_BASE = 'https://generativelanguage.googleapis.com/v1beta/models'
const GEMINI_MODEL = 'gemini-2.5-flash'

export const CLAUDE_SYSTEM = `You are an expert in Islamic dietary laws (halal). Analyze ingredient lists and determine if a product is halal.

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

export interface AiVerdict {
  isHalal: boolean
  isUnknown: boolean
  haramIngredients: string[]
  suspiciousIngredients: string[]
  ingredientWarnings: Record<string, string>
  explanation: string
}

// deno-lint-ignore no-explicit-any
function parseAiJson(text: string): any | null {
  try {
    return JSON.parse(text.replace(/```json\n?|\n?```/g, '').trim())
  } catch {
    return null
  }
}

function toVerdict(
  // deno-lint-ignore no-explicit-any
  p: any,
  ingredientsLength: number,
  unknownDefault = false,
): AiVerdict {
  return {
    isHalal:               p.isHalal ?? false,
    isUnknown:             p.isUnknown ?? (ingredientsLength === 0 ? unknownDefault : false),
    haramIngredients:      p.haramIngredients ?? [],
    suspiciousIngredients: p.suspiciousIngredients ?? [],
    ingredientWarnings:    p.ingredientWarnings ?? {},
    explanation:           p.explanation ?? '',
  }
}

export async function geminiIngredientLookup(
  name: string,
  barcode: string,
  key: string,
): Promise<string[]> {
  console.log(`[${barcode}] Gemini ingredient lookup: asking for ingredients of "${name}"...`)
  try {
    const res = await fetch(
      `${GEMINI_URL_BASE}/${GEMINI_MODEL}:generateContent?key=${key}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: `Ingredients of "${name}" (barcode ${barcode}), comma-separated English list. Unknown if not found: UNKNOWN` }] }],
          generationConfig: { maxOutputTokens: 300, temperature: 0, thinkingConfig: { thinkingBudget: 0 } },
        }),
      },
    )
    if (!res.ok) {
      const errBody = await res.text()
      console.error(`[${barcode}] Gemini ingredient lookup: HTTP ${res.status} — ${errBody}`)
      return []
    }
    const ld = await res.json()
    const text: string = (ld.candidates?.[0]?.content?.parts?.[0]?.text ?? '').trim()
    const usage = ld.usageMetadata
    console.log(`[${barcode}] Gemini ingredient lookup: response="${text.slice(0, 120)}" prompt=${usage?.promptTokenCount ?? '?'} output=${usage?.candidatesTokenCount ?? '?'} thoughts=${usage?.thoughtsTokenCount ?? 0} total=${usage?.totalTokenCount ?? '?'} tokens`)
    if (text && text.toUpperCase() !== 'UNKNOWN') {
      const ingredients = text.split(',').map((s: string) => s.trim()).filter((s: string) => s.length > 0)
      console.log(`[${barcode}] Gemini ingredient lookup: found ${ingredients.length} ingredients`)
      return ingredients
    }
  } catch (e) {
    console.error(`[${barcode}] Gemini ingredient lookup: exception:`, e)
  }
  return []
}

export async function analyzeWithGemini(
  ingredients: string[],
  barcode: string,
  key: string,
): Promise<AiVerdict | null> {
  console.log(`[${barcode}] Gemini: calling ${GEMINI_MODEL}...`)
  try {
    const res = await fetch(
      `${GEMINI_URL_BASE}/${GEMINI_MODEL}:generateContent?key=${key}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: `Analyze these ingredients:\n${ingredients.join(', ')}` }] }],
          systemInstruction: { parts: [{ text: CLAUDE_SYSTEM }] },
          generationConfig: { maxOutputTokens: 512, temperature: 0, thinkingConfig: { thinkingBudget: 0 } },
        }),
      },
    )
    if (!res.ok) {
      const body = await res.text()
      console.error(`[${barcode}] Gemini: HTTP ${res.status} — ${body}`)
      return null
    }
    const gd = await res.json()
    const text: string = gd.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
    const usage = gd.usageMetadata
    const p = parseAiJson(text)
    if (!p) { console.error(`[${barcode}] Gemini: JSON parse failed`); return null }
    console.log(`[${barcode}] Gemini: success — isHalal=${p.isHalal} isUnknown=${p.isUnknown} haram=[${(p.haramIngredients ?? []).join(', ')}] suspicious=[${(p.suspiciousIngredients ?? []).join(', ')}] warnings=${JSON.stringify(p.ingredientWarnings ?? {})} prompt=${usage?.promptTokenCount ?? '?'} output=${usage?.candidatesTokenCount ?? '?'} thoughts=${usage?.thoughtsTokenCount ?? 0} total=${usage?.totalTokenCount ?? '?'} tokens`)
    return toVerdict(p, ingredients.length)
  } catch (e) {
    console.error(`[${barcode}] Gemini: exception:`, e)
    return null
  }
}

export async function analyzeWithClaude(
  ingredients: string[],
  barcode: string,
  key: string,
): Promise<AiVerdict | null> {
  console.log(`[${barcode}] Claude: calling ${CLAUDE_MODEL}...`)
  try {
    const res = await fetch(CLAUDE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': key,
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
    if (!res.ok) {
      const body = await res.text()
      console.error(`[${barcode}] Claude: HTTP ${res.status} — ${body}`)
      return null
    }
    const cd = await res.json()
    const text: string = cd.content?.find((c: { type: string }) => c.type === 'text')?.text ?? ''
    const p = parseAiJson(text)
    if (!p) { console.error(`[${barcode}] Claude: JSON parse failed`); return null }
    console.log(`[${barcode}] Claude: success`)
    return toVerdict(p, ingredients.length)
  } catch (e) {
    console.error(`[${barcode}] Claude: exception:`, e)
    return null
  }
}

export async function analyzeWithClaudeVision(
  imgUrl: string,
  barcode: string,
  key: string,
): Promise<AiVerdict | null> {
  console.log(`[${barcode}] Claude vision: calling...`)
  try {
    const res = await fetch(CLAUDE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': key,
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
    if (!res.ok) {
      const body = await res.text()
      console.error(`[${barcode}] Claude vision: HTTP ${res.status} — ${body}`)
      return null
    }
    const cd = await res.json()
    const text: string = cd.content?.find((c: { type: string }) => c.type === 'text')?.text ?? ''
    const p = parseAiJson(text)
    if (!p) { console.error(`[${barcode}] Claude vision: JSON parse failed`); return null }
    console.log(`[${barcode}] Claude vision: success`)
    return toVerdict(p, 0, true)
  } catch (e) {
    console.error('[lookup-product] Vision Claude request failed:', e)
    return null
  }
}
