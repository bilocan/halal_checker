-- Fix two triggers that reference columns dropped from products in 20260520000000.
--
-- restore_approved_ingredients_on_product_write set NEW.analyzed_by_ai which
-- no longer exists on products, breaking every products INSERT and UPDATE.
--
-- apply_approved_ingredient_contribution reset six verdict columns on products
-- (is_halal, haram_ingredients, etc.) that are now owned by product_analysis.

-- 1. Remove the analyzed_by_ai assignment — product_analysis owns that field.
--    The edge function re-analyses on next scan when it detects updated_at >
--    last_analysed_at (bumped by trg_products_bump_updated_at on ingredient change).
CREATE OR REPLACE FUNCTION restore_approved_ingredients_on_product_write()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  approved_text TEXT;
BEGIN
  SELECT ingredient_text INTO approved_text
  FROM ingredient_contributions
  WHERE barcode = NEW.barcode AND status = 'approved'
  ORDER BY created_at DESC
  LIMIT 1;

  IF approved_text IS NOT NULL THEN
    NEW.ingredients := (
      SELECT COALESCE(jsonb_agg(token), '[]'::jsonb)
      FROM (
        SELECT trim(item) AS token
        FROM unnest(string_to_array(approved_text, ',')) AS item
        WHERE trim(item) <> ''
      ) sub
    );
  END IF;

  RETURN NEW;
END;
$$;

-- 2. Write verdict reset to product_analysis (not products) on approval.
CREATE OR REPLACE FUNCTION apply_approved_ingredient_contribution()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
    -- Source data: update ingredients and back-date so edge function re-analyses.
    UPDATE products
    SET
      ingredients = (
        SELECT COALESCE(jsonb_agg(token), '[]'::jsonb)
        FROM (
          SELECT trim(item) AS token
          FROM unnest(string_to_array(NEW.ingredient_text, ',')) AS item
          WHERE trim(item) <> ''
        ) sub
      ),
      fetched_at = NOW() - INTERVAL '31 days'
    WHERE barcode = NEW.barcode;

    -- Verdict data: reset in product_analysis so the edge function re-analyses.
    UPDATE product_analysis
    SET
      is_halal               = false,
      haram_ingredients      = '[]',
      suspicious_ingredients = '[]',
      ingredient_warnings    = '{}',
      explanation            = '',
      analyzed_by_ai         = false
    WHERE barcode = NEW.barcode;
  END IF;
  RETURN NEW;
END;
$$;
