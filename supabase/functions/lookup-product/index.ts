// Entry: Deno.serve. Orchestration: handler.ts (VERDICT_PIPELINE.md + verdictRules.ts)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders, createLookupDeps, handleLookupRequest } from './handler.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  return handleLookupRequest(req, createLookupDeps(supabase))
})
