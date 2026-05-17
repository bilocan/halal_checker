-- Update products_schedule_reanalysis to read the Supabase URL and anon key
-- from the app_config table instead of database-level settings (which require
-- superuser privileges unavailable in Supabase).
--
-- One-time setup: insert your project URL and anon key into app_config.
-- Run this once in the Supabase SQL editor (replace the placeholder values):
--
--   INSERT INTO app_config (key, value) VALUES
--     ('supabase_url',      'https://<ref>.supabase.co'),
--     ('supabase_anon_key', '<your-anon-key>')
--   ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

CREATE OR REPLACE FUNCTION products_schedule_reanalysis()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  _url text;
  _key text;
BEGIN
  IF (NEW.ingredients IS DISTINCT FROM OLD.ingredients OR
      NEW.name        IS DISTINCT FROM OLD.name        OR
      NEW.labels      IS DISTINCT FROM OLD.labels      OR
      NEW.is_non_food IS DISTINCT FROM OLD.is_non_food) THEN

    SELECT value INTO _url FROM app_config WHERE key = 'supabase_url'      LIMIT 1;
    SELECT value INTO _key FROM app_config WHERE key = 'supabase_anon_key' LIMIT 1;

    IF _url IS NOT NULL AND _key IS NOT NULL THEN
      PERFORM net.http_post(
        url     := _url || '/functions/v1/lookup-product',
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || _key
        ),
        body    := jsonb_build_object('barcode', NEW.barcode)::text
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
