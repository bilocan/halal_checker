-- Prevent repeat Gemini web ingredient lookups for the same barcode + product name
-- (normalized). Exposed via products_full for the app and edge function.

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS gemini_web_ingredient_lookup_at timestamptz,
  ADD COLUMN IF NOT EXISTS gemini_web_ingredient_lookup_name_key text;

DROP VIEW IF EXISTS products_full;
CREATE OR REPLACE VIEW products_full AS
SELECT
  p.barcode, p.name, p.ingredients, p.ingredient_source,
  p.fetched_at, p.updated_at, p.last_analysed_at,
  p.labels, p.image_url, p.image_front_url, p.image_ingredients_url,
  p.image_nutrition_url, p.requires_halal_cert, p.is_managed, p.is_non_food,
  p.gemini_web_ingredient_lookup_at,
  p.gemini_web_ingredient_lookup_name_key,
  COALESCE(pa.is_halal,               false)       AS is_halal,
  COALESCE(pa.is_unknown,             true)        AS is_unknown,
  COALESCE(pa.haram_ingredients,      '[]'::jsonb) AS haram_ingredients,
  COALESCE(pa.suspicious_ingredients, '[]'::jsonb) AS suspicious_ingredients,
  COALESCE(pa.ingredient_warnings,    '{}'::jsonb) AS ingredient_warnings,
  COALESCE(pa.analyzed_by_ai,         false)       AS analyzed_by_ai,
  COALESCE(pa.explanation,            '')          AS explanation
FROM products p
LEFT JOIN product_analysis pa ON p.barcode = pa.barcode;

GRANT SELECT ON products_full TO anon, authenticated;
