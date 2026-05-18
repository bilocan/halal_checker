CREATE TABLE IF NOT EXISTS product_analysis (
  barcode                TEXT        PRIMARY KEY REFERENCES products(barcode) ON DELETE CASCADE,
  is_halal               BOOLEAN     NOT NULL DEFAULT false,
  is_unknown             BOOLEAN     NOT NULL DEFAULT true,
  is_non_food            BOOLEAN     NOT NULL DEFAULT false,
  haram_ingredients      JSONB       NOT NULL DEFAULT '[]',
  suspicious_ingredients JSONB       NOT NULL DEFAULT '[]',
  ingredient_warnings    JSONB       NOT NULL DEFAULT '{}',
  analyzed_by_ai         BOOLEAN     NOT NULL DEFAULT false,
  explanation            TEXT        NOT NULL DEFAULT '',
  analyzed_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO product_analysis (
  barcode, is_halal, is_unknown, is_non_food,
  haram_ingredients, suspicious_ingredients, ingredient_warnings,
  analyzed_by_ai, explanation
)
SELECT
  barcode,
  COALESCE(is_halal,               false),
  COALESCE(is_unknown,             true),
  COALESCE(is_non_food,            false),
  COALESCE(haram_ingredients,      '[]'::jsonb),
  COALESCE(suspicious_ingredients, '[]'::jsonb),
  COALESCE(ingredient_warnings,    '{}'::jsonb),
  COALESCE(analyzed_by_ai,         false),
  COALESCE(explanation,            '')
FROM products
ON CONFLICT (barcode) DO NOTHING;

DROP VIEW IF EXISTS products_full;
CREATE OR REPLACE VIEW products_full AS
SELECT
  p.barcode, p.name, p.ingredients, p.fetched_at, p.updated_at,
  p.labels, p.image_url, p.image_front_url, p.image_ingredients_url,
  p.image_nutrition_url, p.requires_halal_cert,
  COALESCE(pa.is_halal,               false)       AS is_halal,
  COALESCE(pa.is_unknown,             true)        AS is_unknown,
  COALESCE(pa.is_non_food,            false)       AS is_non_food,
  COALESCE(pa.haram_ingredients,      '[]'::jsonb) AS haram_ingredients,
  COALESCE(pa.suspicious_ingredients, '[]'::jsonb) AS suspicious_ingredients,
  COALESCE(pa.ingredient_warnings,    '{}'::jsonb) AS ingredient_warnings,
  COALESCE(pa.analyzed_by_ai,         false)       AS analyzed_by_ai,
  COALESCE(pa.explanation,            '')          AS explanation
FROM products p
LEFT JOIN product_analysis pa ON p.barcode = pa.barcode;

ALTER TABLE product_analysis ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public read"   ON product_analysis;
DROP POLICY IF EXISTS "service write" ON product_analysis;

CREATE POLICY "public read"   ON product_analysis FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "service write" ON product_analysis FOR ALL    TO service_role         USING (true);
