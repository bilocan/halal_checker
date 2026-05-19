-- Rebuild products_full now that product_analysis owns the verdict columns.
-- Adds is_managed and last_analysed_at (missing from the previous view), and
-- pulls is_non_food from products directly because the bump/reanalysis triggers
-- reference that column and it doubles as source data, not just verdict data.
DROP VIEW IF EXISTS products_full;
CREATE OR REPLACE VIEW products_full AS
SELECT
  p.barcode, p.name, p.ingredients, p.fetched_at, p.updated_at, p.last_analysed_at,
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

-- Drop pure verdict columns now owned by product_analysis.
-- is_non_food is intentionally kept: both reanalysis triggers fire on it.
ALTER TABLE products
  DROP COLUMN IF EXISTS is_halal,
  DROP COLUMN IF EXISTS is_unknown,
  DROP COLUMN IF EXISTS haram_ingredients,
  DROP COLUMN IF EXISTS suspicious_ingredients,
  DROP COLUMN IF EXISTS ingredient_warnings,
  DROP COLUMN IF EXISTS explanation,
  DROP COLUMN IF EXISTS analyzed_by_ai;
