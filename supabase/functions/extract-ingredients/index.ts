const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CLAUDE_URL = 'https://api.anthropic.com/v1/messages'
const CLAUDE_MODEL = 'claude-haiku-4-5'

const GEMINI_URL_BASE = 'https://generativelanguage.googleapis.com/v1beta/models'
const GEMINI_MODEL = 'gemini-2.0-flash'

const OCR_SYSTEM = `You are an OCR assistant specialized in reading food product ingredient labels.
Given an image of a food product label, extract ONLY the ingredient list text.
Return a raw JSON object only — no markdown, no prose:
{
  "ingredients_text": "the full ingredient list text as a single string, preserving original language"
}
If you cannot read any ingredient text from the image, return:
{
  "ingredients_text": null
}`

const OCR_PROMPT = 'This image shows a food product label. Read ALL the ingredient names from the image. Return only the ingredient list text as-is in the original language. Respond with the JSON format specified.'

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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const imageUrl: string | null = body.image_url ?? null
    const imageBase64: string | null = body.image_base64 ?? null

    if (!imageUrl && !imageBase64) {
      return new Response(
        JSON.stringify({ error: 'image_url or image_base64 is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Try Gemini first (free tier), fall back to Claude
    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'

    if (geminiEnabled && geminiKey) {
      console.log('[extract-ingredients] Trying Gemini vision...')
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
              if (p.ingredients_text) {
                console.log('[extract-ingredients] Gemini vision: success')
                return new Response(
                  JSON.stringify({ ingredients_text: p.ingredients_text }),
                  { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
                )
              }
            } catch (e) {
              console.error('[extract-ingredients] Gemini vision: JSON parse failed:', e)
            }
          } else {
            console.error(`[extract-ingredients] Gemini vision: HTTP ${geminiRes.status}`)
          }
        }
      } catch (e) {
        console.error('[extract-ingredients] Gemini vision: exception:', e)
      }
    }

    // Fallback: Claude vision
    const claudeKey = Deno.env.get('CLAUDE_API_KEY')
    const claudeEnabled = Deno.env.get('CLAUDE_ENABLED') !== 'false'

    if (claudeEnabled && claudeKey) {
      console.log('[extract-ingredients] Trying Claude vision...')
      try {
        // Claude supports both URL and base64
        const imageContent = imageBase64
          ? { type: 'image' as const, source: { type: 'base64' as const, media_type: 'image/jpeg', data: imageBase64 } }
          : { type: 'image' as const, source: { type: 'url' as const, url: imageUrl! } }

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
            console.log('[extract-ingredients] Claude vision: success')
            return new Response(
              JSON.stringify({ ingredients_text: p.ingredients_text }),
              { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
            )
          } catch (e) {
            console.error('[extract-ingredients] Claude vision: JSON parse failed:', e)
          }
        } else {
          const body = await claudeRes.text()
          console.error(`[extract-ingredients] Claude vision: HTTP ${claudeRes.status} — ${body}`)
        }
      } catch (e) {
        console.error('[extract-ingredients] Claude vision: exception:', e)
      }
    }

    return new Response(
      JSON.stringify({ ingredients_text: null }),
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
