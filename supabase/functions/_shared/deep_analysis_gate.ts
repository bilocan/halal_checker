import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export const DEEP_ANALYSIS_ENABLED_CONFIG_KEY = 'deep_analysis_enabled'

export function isDeepAnalysisEnabledDbValue(
  value: string | null | undefined,
): boolean {
  return value === 'true'
}

/** Read `app_config.deep_analysis_enabled` with service role. Default off when missing. */
export async function isDeepAnalysisEnabled(
  supabase: SupabaseClient,
): Promise<boolean> {
  const { data, error } = await supabase
    .from('app_config')
    .select('value')
    .eq('key', DEEP_ANALYSIS_ENABLED_CONFIG_KEY)
    .maybeSingle()
  if (error) {
    console.error(
      `[app_config] read ${DEEP_ANALYSIS_ENABLED_CONFIG_KEY} failed:`,
      error.message,
    )
    return false
  }
  return isDeepAnalysisEnabledDbValue(data?.value as string | undefined)
}
