/**
 * Admin-only Gemini ingredient web lookup (probe / web chat).
 * POST { barcode, productName?, brand? }
 * Auth: JWT + profiles.role = superadmin. verify_jwt = true.
 *
 * Uses _shared/gemini_ingredient_lookup.ts — same request as lookup-product (Flutter).
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import {
  geminiIngredientLookupDetailed,
} from '../_shared/gemini_ingredient_lookup.ts'
import {
  fetchOpenFactsProduct,
  parseOffBrand,
  parseOffProductName,
} from '../lookup-product/fetch.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function isSuperAdminRole(role: string | null | undefined): boolean {
  return role === 'superadmin'
}

async function resolveNameAndBrand(
  supabase: ReturnType<typeof createClient>,
  barcode: string,
  productName?: string,
  brand?: string,
): Promise<{ name: string; brand: string }> {
  if (productName?.trim()) {
    return { name: productName.trim(), brand: (brand ?? '').trim() }
  }

  const { data: row } = await supabase
    .from('products')
    .select('name, brand')
    .eq('barcode', barcode)
    .maybeSingle()

  if (row?.name && String(row.name).trim() !== 'Unknown Product') {
    return {
      name: String(row.name).trim(),
      brand: (brand ?? row.brand ?? '').toString().trim(),
    }
  }

  const off = await fetchOpenFactsProduct(barcode)
  if (off?.pd) {
    return {
      name: parseOffProductName(off.pd),
      brand: (brand ?? parseOffBrand(off.pd)).trim(),
    }
  }

  return {
    name: productName?.trim() || 'Unknown Product',
    brand: (brand ?? '').trim(),
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return json({ error: 'Unauthorized' }, 401)

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user }, error: authError } = await userClient.auth.getUser()
  if (authError || !user) return json({ error: 'Unauthorized' }, 401)

  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey)
  const { data: profile } = await adminClient
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle()

  if (!isSuperAdminRole(profile?.role as string | undefined)) {
    return json({ error: 'Forbidden — superadmin only' }, 403)
  }

  let body: { barcode?: string; productName?: string; brand?: string }
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }

  const barcode = typeof body.barcode === 'string' ? body.barcode.trim() : ''
  if (!barcode) return json({ error: 'barcode is required' }, 400)

  const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
  const geminiKey = Deno.env.get('GEMINI_API_KEY')
  if (!geminiEnabled) {
    return json({ error: 'Gemini disabled (GEMINI_ENABLED=false)' }, 503)
  }
  if (!geminiKey) {
    return json({ error: 'GEMINI_API_KEY not configured' }, 503)
  }

  const { name, brand } = await resolveNameAndBrand(
    adminClient,
    barcode,
    typeof body.productName === 'string' ? body.productName : undefined,
    typeof body.brand === 'string' ? body.brand : undefined,
  )

  if (name === 'Unknown Product') {
    return json({
      error: 'productName required when product is not in DB or Open Food Facts',
      barcode,
    }, 400)
  }

  console.log(
    `[admin-gemini-ingredient-lookup] user=${user.id} barcode=${barcode} name="${name}"`,
  )

  const result = await geminiIngredientLookupDetailed(
    name,
    barcode,
    geminiKey,
    brand,
  )

  return json({
    barcode,
    name,
    brand,
    ingredients: result.ingredients,
    rawText: result.rawText,
    finishReason: result.finishReason,
    grounding: result.grounding,
  })
})
