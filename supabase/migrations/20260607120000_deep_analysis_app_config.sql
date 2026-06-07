-- Superadmin toggle for Deep Analysis (per-ingredient AI queue + admin Analysis tab).

INSERT INTO app_config (key, value) VALUES
  ('deep_analysis_enabled', 'false')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.set_superadmin_app_config_flag(p_key text, p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_key NOT IN ('gemini_lookup_empty_off', 'closed_beta_banner', 'deep_analysis_enabled') THEN
    RAISE EXCEPTION 'key not allowed: %', p_key;
  END IF;
  IF p_value NOT IN ('true', 'false') THEN
    RAISE EXCEPTION 'value must be true or false';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'superadmin'
  ) THEN
    RAISE EXCEPTION 'forbidden: superadmin only';
  END IF;
  INSERT INTO app_config (key, value) VALUES (p_key, p_value)
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
END;
$$;

REVOKE ALL ON FUNCTION public.set_superadmin_app_config_flag(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_superadmin_app_config_flag(text, text) TO authenticated;
