// Queues a product for deep analysis.
// The actual AI analysis runs later via the batch-analyze admin function.
//
// POST /functions/v1/deep-analyze-product
// Body: { barcode: string, productData?: { name, ingredients, haram_ingredients, suspicious_ingredients } }
// Auth: any signed-in user

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { isDeepAnalysisEnabled } from '../_shared/deep_analysis_gate.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  // ── auth ────────────────────────────────────────────────────────────────────
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

  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey)

  if (!(await isDeepAnalysisEnabled(adminClient))) {
    return json({ error: 'Deep analysis is disabled' }, 403)
  }

  // ── ensure profile exists ────────────────────────────────────────────────────
  // The trigger auto-creates profiles only for new sign-ups, so users who
  // existed before the profiles migration were applied have no row.
  await adminClient
    .from('profiles')
    .upsert({
      id: user.id,
      username: user.user_metadata?.full_name
        ?? user.email?.split('@')[0]
        ?? 'Anonymous',
      avatar_url: user.user_metadata?.avatar_url ?? null,
    }, { onConflict: 'id', ignoreDuplicates: true })

  // ── parse body ───────────────────────────────────────────────────────────────
  let barcode: string
  let productDataFallback: {
    name?: string
    ingredients?: string[]
    haram_ingredients?: string[]
    suspicious_ingredients?: string[]
  } | null = null
  try {
    const body = await req.json()
    barcode = (body?.barcode ?? '').trim()
    productDataFallback = body?.productData ?? null
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }
  if (!barcode) return json({ error: 'barcode is required' }, 400)

  // ── return existing analysis if already queued or completed ──────────────────
  const { data: existing } = await adminClient
    .from('product_analyses')
    .select('*')
    .eq('barcode', barcode)
    .maybeSingle()

  if (existing) {
    return json({ analysis: existing })
  }

  // ── ensure product is in the shared DB before inserting the FK reference ─────
  const { data: product } = await adminClient
    .from('products')
    .select('barcode')
    .eq('barcode', barcode)
    .maybeSingle()

  if (!product) {
    if (!productDataFallback) {
      return json({ error: 'Product not found. Scan the product first.' }, 404)
    }
    // Back-fill: product reached Flutter via the direct OFf fallback path and
    // was never written to Supabase. Write it now so the FK and batch-analyze work.
    const ingredients = productDataFallback.ingredients ?? []
    const haramIngredients = productDataFallback.haram_ingredients ?? []
    await adminClient
      .from('products')
      .upsert({
        barcode,
        name: productDataFallback.name ?? 'Unknown product',
        ingredients,
        is_non_food: false,
        fetched_at: new Date().toISOString(),
      }, { onConflict: 'barcode', ignoreDuplicates: false })
    await adminClient
      .from('product_analysis')
      .upsert({
        barcode,
        haram_ingredients:     haramIngredients,
        suspicious_ingredients: productDataFallback.suspicious_ingredients ?? [],
        is_halal:              haramIngredients.length === 0,
        is_non_food:           false,
        is_unknown:            ingredients.length === 0,
        ingredient_warnings:   {},
        analyzed_at:           new Date().toISOString(),
      }, { onConflict: 'barcode', ignoreDuplicates: false })
  }

  // ── queue the analysis as pending ────────────────────────────────────────────
  const { data: queued, error: insertErr } = await adminClient
    .from('product_analyses')
    .insert({ barcode, status: 'pending', queued_by: user.id })
    .select()
    .single()

  if (insertErr || !queued) {
    console.error('[deep-analyze] insert error:', insertErr)
    return json({ error: 'Failed to queue analysis' }, 500)
  }

  return json({ analysis: queued })
})
