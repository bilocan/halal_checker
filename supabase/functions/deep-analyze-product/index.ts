import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CLAUDE_URL   = 'https://api.anthropic.com/v1/messages'
const CLAUDE_MODEL = 'claude-sonnet-4-6'

// ── system prompt ─────────────────────────────────────────────────────────────

const DEEP_ANALYSIS_SYSTEM = `You are an Islamic halal certification expert with deep knowledge of Islamic dietary laws (fiqh al-at'ima).

Analyze each ingredient individually and provide a thorough per-ingredient verdict. Be complete — include clearly halal ingredients too, as a full record is valuable for the community.

Respond with a raw JSON object only — no markdown, no prose outside the JSON:
{
  "summary": "2-3 sentence overall assessment of the product and its main concerns",
  "ingredients": [
    {
      "name": "exact ingredient name as given in the list",
      "verdict": "halal" | "haram" | "suspicious" | "unknown",
      "confidence": "high" | "medium" | "low",
      "reason": "Plain-language explanation of the verdict",
      "islamicBasis": "Relevant Quranic verse, hadith, or scholarly consensus — leave empty string if not applicable",
      "alternativeNames": ["other names or E-numbers this ingredient may appear under"]
    }
  ]
}

verdict definitions:
- halal: Permissible, no concerns
- haram: Definitively impermissible (pork and all derivatives, alcohol, blood, carnivorous animal meat, insects like carmine/E120)
- suspicious: Source-dependent — could be halal or haram depending on origin (e.g. gelatin, enzymes, mono- and diglycerides, rennet, L-cysteine, natural flavors)
- unknown: Cannot determine without more information about processing or origin

confidence levels:
- high: Ruling is clear and universally agreed upon by scholars
- medium: Mainstream scholarly opinion, but some disagreement exists
- low: Genuinely contested — different madhabs reach different conclusions

For islamicBasis, cite specific sources when possible:
- Quranic verses (e.g. "Al-Baqarah 2:173 prohibits blood and pork")
- Hadith (e.g. "The Prophet ﷺ said every intoxicant is khamr — Sahih Muslim 2003")
- Scholarly consensus or fatwa bodies (e.g. "AAOIFI standard", "European Council for Fatwa")
- Madhab differences when relevant (Hanafi, Maliki, Shafi'i, Hanbali)`

// ── helpers ───────────────────────────────────────────────────────────────────

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function parseClaudeJson(text: string): unknown | null {
  try {
    return JSON.parse(text.replace(/```json\n?|\n?```/g, '').trim())
  } catch {
    return null
  }
}

// ── main handler ──────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  // ── auth ────────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return json({ error: 'Unauthorized' }, 401)

  const supabaseUrl            = Deno.env.get('SUPABASE_URL')!
  const supabaseAnonKey        = Deno.env.get('SUPABASE_ANON_KEY')!
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  // User-scoped client (respects RLS).
  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user }, error: authError } = await userClient.auth.getUser()
  if (authError || !user) return json({ error: 'Unauthorized' }, 401)

  // Service-role client (bypasses RLS for writes and status updates).
  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey)

  // ── parse body ───────────────────────────────────────────────────────────────
  let barcode: string
  try {
    const body = await req.json()
    barcode = (body?.barcode ?? '').trim()
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }
  if (!barcode) return json({ error: 'barcode is required' }, 400)

  // ── check for existing completed analysis ────────────────────────────────────
  const { data: existing } = await adminClient
    .from('product_analyses')
    .select('*')
    .eq('barcode', barcode)
    .maybeSingle()

  if (existing && existing.status !== 'pending') {
    // Already running or done — return current state without re-running.
    return json({ analysis: existing })
  }

  // ── fetch product from DB ────────────────────────────────────────────────────
  const { data: product } = await adminClient
    .from('products')
    .select('name, ingredients, is_halal, is_non_food, haram_ingredients, suspicious_ingredients, ingredient_warnings')
    .eq('barcode', barcode)
    .maybeSingle()

  if (!product) return json({ error: 'Product not found. Scan the product first.' }, 404)

  const ingredients: string[] = product.ingredients ?? []
  if (ingredients.length === 0) {
    return json({ error: 'No ingredient data available for deep analysis.' }, 422)
  }

  // ── upsert analysis record, mark as running ──────────────────────────────────
  const upsertPayload = existing
    ? { status: 'ai_analyzing', updated_at: new Date().toISOString() }
    : { barcode, status: 'ai_analyzing', queued_by: user.id }

  const { data: analysisRow, error: upsertErr } = existing
    ? await adminClient
        .from('product_analyses')
        .update(upsertPayload)
        .eq('barcode', barcode)
        .select()
        .single()
    : await adminClient
        .from('product_analyses')
        .insert(upsertPayload)
        .select()
        .single()

  if (upsertErr || !analysisRow) {
    console.error('[deep-analyze] upsert error:', upsertErr)
    return json({ error: 'Failed to create analysis record' }, 500)
  }

  const analysisId: string = analysisRow.id

  // ── run Claude deep analysis ─────────────────────────────────────────────────
  const claudeKey = Deno.env.get('CLAUDE_API_KEY')
  if (!claudeKey) {
    await adminClient
      .from('product_analyses')
      .update({ status: 'pending' })
      .eq('id', analysisId)
    return json({ error: 'AI analysis unavailable — CLAUDE_API_KEY not set' }, 503)
  }

  const userMessage =
    `Product: ${product.name}\n` +
    `Ingredients: ${ingredients.join(', ')}\n\n` +
    `Initial keyword analysis flagged:\n` +
    `- Haram: ${(product.haram_ingredients ?? []).join(', ') || 'none'}\n` +
    `- Suspicious: ${(product.suspicious_ingredients ?? []).join(', ') || 'none'}\n\n` +
    `Please provide a detailed per-ingredient deep analysis.`

  let aiAnalysis: unknown = null
  try {
    const res = await fetch(CLAUDE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': claudeKey,
        'anthropic-version': '2023-06-01',
        'anthropic-beta': 'prompt-caching-2024-07-31',
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: 4096,
        system: [{ type: 'text', text: DEEP_ANALYSIS_SYSTEM, cache_control: { type: 'ephemeral' } }],
        messages: [{ role: 'user', content: userMessage }],
      }),
    })

    if (res.ok) {
      const cd = await res.json()
      const text: string = cd.content?.find((c: { type: string }) => c.type === 'text')?.text ?? ''
      aiAnalysis = parseClaudeJson(text)
      if (!aiAnalysis) console.error('[deep-analyze] Claude JSON parse failed, raw:', text.slice(0, 300))
    } else {
      const errText = await res.text()
      console.error('[deep-analyze] Claude API error:', res.status, errText.slice(0, 300))
    }
  } catch (e) {
    console.error('[deep-analyze] Claude request threw:', e)
  }

  if (!aiAnalysis) {
    await adminClient
      .from('product_analyses')
      .update({ status: 'pending' })
      .eq('id', analysisId)
    return json({ error: 'AI analysis failed — please try again later' }, 503)
  }

  // ── persist results ──────────────────────────────────────────────────────────
  const { data: finalRow, error: saveErr } = await adminClient
    .from('product_analyses')
    .update({
      status: 'ai_done',
      ai_analysis: aiAnalysis,
      updated_at: new Date().toISOString(),
    })
    .eq('id', analysisId)
    .select()
    .single()

  if (saveErr) {
    console.error('[deep-analyze] save error:', saveErr)
    return json({ error: 'Failed to save analysis' }, 500)
  }

  return json({ analysis: finalRow })
})
