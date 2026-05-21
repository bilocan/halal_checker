-- Track where a product's ingredient list came from: OFF, AI lookup, or community contribution.
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS ingredient_source TEXT DEFAULT 'off'
  CHECK (ingredient_source IN ('off', 'ai', 'community'));

-- When a community contribution is approved, mark the source as 'community'.
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
    NEW.analyzed_by_ai := false;
  END IF;

  RETURN NEW;
END;
$$;

-- Rebuild products_full to expose ingredient_source to the edge function.
DROP VIEW IF EXISTS products_full;
CREATE OR REPLACE VIEW products_full AS
SELECT
  p.barcode, p.name, p.ingredients, p.ingredient_source,
  p.fetched_at, p.updated_at, p.last_analysed_at,
  p.labels, p.image_url, p.image_front_url, p.image_ingredients_url,
  p.image_nutrition_url, p.requires_halal_cert, p.is_managed, p.is_non_food,
  COALESCE(pa.is_halal,               false)       AS is_halal,
  COALESCE(pa.is_unknown,             true)        AS is_unknown,
  COALESCE(pa.haram_ingredients,      '[]'::jsonb) AS haram_ingredients,
  COALESCE(pa.suspicious_ingredients, '[]'::jsonb) AS suspicious_ingredients,
  COALESCE(pa.ingredient_warnings,    '{}'::jsonb) AS ingredient_warnings,
  COALESCE(pa.analyzed_by_ai,         false)       AS analyzed_by_ai,
  COALESCE(pa.explanation,            '')          AS explanation
FROM products p
LEFT JOIN product_analysis pa ON p.barcode = pa.barcode;
