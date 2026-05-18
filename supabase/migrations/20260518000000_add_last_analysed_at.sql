-- Records when the rules engine (or AI) last ran on this product.
-- Distinct from fetched_at, which tracks when Open Food Facts data was fetched.
-- Null on legacy rows that predate this field.
ALTER TABLE products ADD COLUMN IF NOT EXISTS last_analysed_at TIMESTAMPTZ;
