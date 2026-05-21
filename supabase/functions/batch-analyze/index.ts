// Admin-only endpoint: triggers deep analysis for all products with status='pending'.
// Called from the in-app admin panel or directly via Supabase dashboard.
//
// POST /functions/v1/batch-analyze
// Body: { limit?: number }   — max products to process in one call (default 10)
// Auth: must be a user with role='admin' in the profiles table.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const GEMINI_URL_BASE     = 'https://generativelanguage.googleapis.com/v1beta/models'
const GEMINI_MODEL        = 'gemini-2.5-flash'
const CLAUDE_URL          = 'https://api.anthropic.com/v1/messages'
const CLAUDE_MODEL        = 'claude-sonnet-4-6'
const DEFAULT_BATCH_LIMIT = 10

const DEEP_ANALYSIS_SYSTEM = `You are an Islamic halal certification expert with deep knowledge of Islamic dietary laws (fiqh al-at'ima).

Analyze each ingredient individually and provide a thorough per-ingredient verdict.

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

verdict: halal=permissible, haram=definitively impermissible, suspicious=source-dependent, unknown=cannot determine.
confidence: high=universally agreed, medium=mainstream opinion, low=genuinely contested across madhabs.`

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

type Outcome = { status: 'done' | 'skipped' | 'error'; reason?: string }

async function analyzeOne(
  adminClient: ReturnType<typeof createClient>,
  analysisId: string,
  barcode: string,
): Promise<Outcome> {
  const { data: product, error: productErr } = await adminClient
    .from('products_full')
    .select('name, ingredients, haram_ingredients, suspicious_ingredients')
    .eq('barcode', barcode)
    .maybeSingle()

  if (productErr) return { status: 'error', reason: `DB lookup failed: ${productErr.message}` }
  if (!product) return { status: 'skipped', reason: 'product not in DB' }
  if (!product.ingredients?.length) return { status: 'skipped', reason: 'no ingredients' }

  await adminClient
    .from('product_analyses')
    .update({ status: 'ai_analyzing', updated_at: new Date().toISOString() })
    .eq('id', analysisId)

  const userMessage =
    `Product: ${product.name}\n` +
    `Ingredients: ${product.ingredients.join(', ')}\n\n` +
    `Initial keyword analysis flagged:\n` +
    `- Haram: ${(product.haram_ingredients ?? []).join(', ') || 'none'}\n` +
    `- Suspicious: ${(product.suspicious_ingredients ?? []).join(', ') || 'none'}\n\n` +
    `Please provide a detailed per-ingredient deep analysis.`

  let aiAnalysis: unknown = null
  const failures: string[] = []

  const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
  const claudeEnabled = Deno.env.get('CLAUDE_ENABLED') !== 'false'

  // Tier 1: Gemini Flash — free 1,500 req/day
  const geminiKey = Deno.env.get('GEMINI_API_KEY')
  if (!geminiEnabled) {
    console.log(`[${barcode}] Gemini: skipped — disabled by GEMINI_ENABLED=false`)
    failures.push('Gemini: disabled')
  } else if (!geminiKey) {
    console.log(`[${barcode}] Gemini: skipped — GEMINI_API_KEY not set`)
    failures.push('Gemini: no key')
  } else {
    console.log(`[${barcode}] Gemini: calling ${GEMINI_MODEL}...`)
    try {
      const res = await fetch(
        `${GEMINI_URL_BASE}/${GEMINI_MODEL}:generateContent?key=${geminiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: userMessage }] }],
            systemInstruction: { parts: [{ text: DEEP_ANALYSIS_SYSTEM }] },
            generationConfig: { maxOutputTokens: 4096, temperature: 0 },
          }),
        },
      )
      if (res.ok) {
        const gd = await res.json()
        const text: string = gd.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
        aiAnalysis = parseClaudeJson(text)
        if (aiAnalysis) {
          console.log(`[${barcode}] Gemini: success`)
        } else {
          console.error(`[${barcode}] Gemini: JSON parse failed`)
          failures.push('Gemini: bad JSON')
        }
      } else {
        const body = await res.text()
        console.error(`[${barcode}] Gemini: HTTP ${res.status} — ${body}`)
        failures.push(`Gemini: HTTP ${res.status}`)
      }
    } catch (e) {
      console.error(`[${barcode}] Gemini: exception:`, e)
      failures.push(`Gemini: exception`)
    }
  }

  // Tier 2: Claude Sonnet — paid fallback
  if (!aiAnalysis) {
    const claudeKey = Deno.env.get('CLAUDE_API_KEY')
    if (!claudeEnabled) {
      console.log(`[${barcode}] Claude: skipped — disabled by CLAUDE_ENABLED=false`)
      failures.push('Claude: disabled')
    } else if (!claudeKey) {
      console.log(`[${barcode}] Claude: skipped — CLAUDE_API_KEY not set`)
      failures.push('Claude: no key')
    } else {
      console.log(`[${barcode}] Claude: calling ${CLAUDE_MODEL}...`)
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
          if (aiAnalysis) {
            console.log(`[${barcode}] Claude: success`)
          } else {
            console.error(`[${barcode}] Claude: JSON parse failed`)
            failures.push('Claude: bad JSON')
          }
        } else {
          const body = await res.text()
          console.error(`[${barcode}] Claude: HTTP ${res.status} — ${body}`)
          failures.push(`Claude: HTTP ${res.status}`)
        }
      } catch (e) {
        console.error(`[${barcode}] Claude: exception:`, e)
        failures.push(`Claude: exception`)
      }
    }
  }

  if (!aiAnalysis) {
    await adminClient
      .from('product_analyses')
      .update({ status: 'pending' })
      .eq('id', analysisId)
    return { status: 'error', reason: failures.join(', ') }
  }

  await adminClient
    .from('product_analyses')
    .update({
      status: 'ai_done',
      ai_analysis: aiAnalysis,
      updated_at: new Date().toISOString(),
    })
    .eq('id', analysisId)

  return { status: 'done' }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  // ── auth ─────────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return json({ error: 'Unauthorized' }, 401)

  const supabaseUrl            = Deno.env.get('SUPABASE_URL')!
  const supabaseAnonKey        = Deno.env.get('SUPABASE_ANON_KEY')!
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user }, error: authError } = await userClient.auth.getUser()
  if (authError || !user) return json({ error: 'Unauthorized' }, 401)

  // Verify admin role.
  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey)
  const { data: profile } = await adminClient
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle()

  if (profile?.role !== 'admin') return json({ error: 'Forbidden — admin only' }, 403)

  // ── parse body ────────────────────────────────────────────────────────────────
  let limit = DEFAULT_BATCH_LIMIT
  let ids: string[] | null = null
  try {
    const body = await req.json()
    if (typeof body?.limit === 'number') limit = Math.min(Math.max(1, body.limit), 50)
    if (Array.isArray(body?.ids) && body.ids.length > 0) ids = body.ids as string[]
  } catch { /* no body is fine */ }

  // ── fetch pending analyses ────────────────────────────────────────────────────
  let query = adminClient
    .from('product_analyses')
    .select('id, barcode')
    .eq('status', 'pending')
    .order('created_at', { ascending: true })

  if (ids) query = query.in('id', ids)

  const { data: pending, error: fetchErr } = await query.limit(ids ? ids.length : limit)

  if (fetchErr) return json({ error: 'Failed to fetch pending analyses' }, 500)
  if (!pending?.length) return json({ processed: 0, message: 'No pending analyses' })

  // ── process sequentially to avoid rate-limit spikes ──────────────────────────
  const results = { done: 0, skipped: 0, error: 0 }
  const errorDetails: { barcode: string; reason: string }[] = []
  for (const row of pending) {
    const outcome = await analyzeOne(adminClient, row.id, row.barcode)
    results[outcome.status]++
    if (outcome.status === 'error' && outcome.reason) {
      errorDetails.push({ barcode: row.barcode, reason: outcome.reason })
    }
  }

  return json({ processed: pending.length, results, errorDetails })
})
