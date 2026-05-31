-- Capture additional OFF tag arrays and brand/quantity on products.
-- These are read-only OFF fields used for display and future analysis.

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS brand           TEXT  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS quantity        TEXT  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS categories_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS additives_tags  JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS allergens_tags  JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS traces_tags     JSONB NOT NULL DEFAULT '[]'::jsonb;

DROP VIEW IF EXISTS products_full;
CREATE OR REPLACE VIEW products_full AS
SELECT
  p.barcode, p.name, p.ingredients, p.ingredient_source,
  p.fetched_at, p.updated_at, p.last_analysed_at,
  p.labels, p.image_url, p.image_front_url, p.image_ingredients_url,
  p.image_nutrition_url, p.requires_halal_cert, p.is_managed, p.is_non_food,
  p.gemini_web_ingredient_lookup_at,
  p.gemini_web_ingredient_lookup_name_key,
  p.display_lang,
  p.brand, p.quantity, p.categories_tags, p.additives_tags,
  p.allergens_tags, p.traces_tags,
  COALESCE(pa.is_halal,               false)       AS is_halal,
  COALESCE(pa.is_unknown,             true)        AS is_unknown,
  COALESCE(pa.haram_ingredients,      '[]'::jsonb) AS haram_ingredients,
  COALESCE(pa.suspicious_ingredients, '[]'::jsonb) AS suspicious_ingredients,
  COALESCE(pa.ingredient_warnings,    '{}'::jsonb) AS ingredient_warnings,
  COALESCE(pa.haram_labels,           '[]'::jsonb) AS haram_labels,
  COALESCE(pa.suspicious_labels,      '[]'::jsonb) AS suspicious_labels,
  COALESCE(pa.label_warnings,         '{}'::jsonb) AS label_warnings,
  COALESCE(pa.analyzed_by_ai,         false)       AS analyzed_by_ai,
  COALESCE(pa.explanation,            '')          AS explanation,
  pa.keyword_match_source,
  COALESCE(pa.keyword_match_origins,  '{}'::jsonb) AS keyword_match_origins,
  pa.analyze_lang
FROM products p
LEFT JOIN product_analysis pa ON p.barcode = pa.barcode;

GRANT SELECT ON products_full TO anon, authenticated;
