-- Lets an admin scan a subset of products (specific barcodes, name search, or
-- "not analyzed since" date) instead of always scanning the whole catalog.
-- The filter is persisted with the run so resuming after a page reload keeps
-- scanning the same subset instead of silently falling back to "all products".
ALTER TABLE product_retest_runs
  ADD COLUMN IF NOT EXISTS filter_barcodes        JSONB,
  ADD COLUMN IF NOT EXISTS filter_name_query       TEXT,
  ADD COLUMN IF NOT EXISTS filter_analyzed_before  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS filter_analyzed_after   TIMESTAMPTZ;
