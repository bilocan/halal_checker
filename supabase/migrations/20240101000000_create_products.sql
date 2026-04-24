CREATE TABLE IF NOT EXISTS products (
  barcode                TEXT        PRIMARY KEY,
  name                   TEXT        NOT NULL,
  ingredients            JSONB       NOT NULL DEFAULT '[]',
  is_halal               BOOLEAN     NOT NULL DEFAULT false,
  haram_ingredients      JSONB       NOT NULL DEFAULT '[]',
  suspicious_ingredients JSONB       NOT NULL DEFAULT '[]',
  ingredient_warnings    JSONB       NOT NULL DEFAULT '{}',
  labels                 JSONB       NOT NULL DEFAULT '[]',
  image_url              TEXT,
  image_front_url        TEXT,
  image_ingredients_url  TEXT,
  image_nutrition_url    TEXT,
  explanation            TEXT        NOT NULL DEFAULT '',
  analyzed_by_ai         BOOLEAN     NOT NULL DEFAULT false,
  fetched_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_fetched_at ON products (fetched_at DESC);
