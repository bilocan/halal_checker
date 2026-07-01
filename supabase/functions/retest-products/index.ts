// Admin-only endpoint: previews and applies keyword/rule changes against
// already-analysed products in `products_full`.
//
// Products are only re-analysed lazily (on next lookup, when stale/forced) —
// adding a new keyword or custom rule does not retroactively touch rows
// already sitting in Supabase. This tool lets an admin scan all stored
// products, review a diff of what would change, then apply it.
//
// POST /functions/v1/retest-products — see handler.ts for the action contract.
// Auth: must be a user with role='superadmin' in the profiles table.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders, handleRetestRequest, json } from './handler.ts'

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

  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey)
  const { data: profile } = await adminClient
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle()

  if (profile?.role !== 'superadmin') {
    return json({ error: 'Forbidden — superadmin only' }, 403)
  }

  return handleRetestRequest(req, adminClient)
})
