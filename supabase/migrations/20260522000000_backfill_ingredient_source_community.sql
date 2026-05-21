-- analyzed_by_ai was moved to product_analysis in 20260520000000; the
-- 20260521000000 trigger accidentally re-added NEW.analyzed_by_ai on products.
CREATE OR REPLACE FUNCTION restore_approved_ingredients_on_product_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  approved_text TEXT;
BEGIN
  SELECT ingredient_text
  INTO approved_text
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
    NEW.ingredient_source := 'community';
  END IF;

  RETURN NEW;
END;
$$;

-- Backfill ingredient_source for products that already have an approved contribution.
UPDATE products p
SET ingredient_source = 'community'
WHERE ingredient_source IS DISTINCT FROM 'community'
  AND EXISTS (
    SELECT 1
    FROM ingredient_contributions ic
    WHERE ic.barcode = p.barcode
      AND ic.status = 'approved'
  );

-- Set ingredient_source immediately when a contribution is approved.
CREATE OR REPLACE FUNCTION apply_approved_ingredient_contribution()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
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
      ingredient_source = 'community',
      fetched_at = NOW() - INTERVAL '31 days'
    WHERE barcode = NEW.barcode;

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
