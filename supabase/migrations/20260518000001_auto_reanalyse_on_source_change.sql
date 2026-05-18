-- Replace the needs_reanalysis boolean with timestamp-based staleness detection.
-- A product row is "stale" (needs re-analysis) when updated_at > last_analysed_at.
--
-- Two triggers are installed:
--   trg_products_bump_updated_at      (BEFORE UPDATE) — bumps updated_at only when
--                                      source data changes; verdict fields don't fire it.
--   trg_products_schedule_reanalysis  (AFTER UPDATE)  — calls the Edge Function via
--                                      pg_net so re-analysis runs immediately, without
--                                      waiting for the next user scan.
--
-- pg_net setup: see migration 20260518000002 — URL and key are stored in app_config.

-- 1. Drop the superseded boolean
ALTER TABLE products DROP COLUMN IF EXISTS needs_reanalysis;

-- 2. Add updated_at — when source data (ingredients / name / labels / is_non_food) last changed
ALTER TABLE products ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- Backfill: treat all existing rows as already current
UPDATE products
   SET updated_at = COALESCE(last_analysed_at, fetched_at, NOW())
 WHERE updated_at IS NULL;

-- 3. BEFORE UPDATE trigger — bumps updated_at when source fields change
--    (is_halal, haram_ingredients, last_analysed_at, etc. do NOT fire this)
CREATE OR REPLACE FUNCTION products_bump_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF (NEW.ingredients IS DISTINCT FROM OLD.ingredients OR
      NEW.name        IS DISTINCT FROM OLD.name        OR
      NEW.labels      IS DISTINCT FROM OLD.labels      OR
      NEW.is_non_food IS DISTINCT FROM OLD.is_non_food) THEN
    NEW.updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_products_bump_updated_at ON products;
CREATE TRIGGER trg_products_bump_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION products_bump_updated_at();

-- 4. AFTER UPDATE trigger — fires async HTTP call to Edge Function via pg_net
--    Requires pg_net extension (enabled by default in Supabase projects).
--    The same source-data condition is checked so non-source updates are ignored.
CREATE OR REPLACE FUNCTION products_schedule_reanalysis()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  _url text := current_setting('app.supabase_url', true);
  _key text := current_setting('app.anon_key',     true);
BEGIN
  IF (NEW.ingredients IS DISTINCT FROM OLD.ingredients OR
      NEW.name        IS DISTINCT FROM OLD.name        OR
      NEW.labels      IS DISTINCT FROM OLD.labels      OR
      NEW.is_non_food IS DISTINCT FROM OLD.is_non_food) THEN
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

DROP TRIGGER IF EXISTS trg_products_schedule_reanalysis ON products;
CREATE TRIGGER trg_products_schedule_reanalysis
  AFTER UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION products_schedule_reanalysis();
