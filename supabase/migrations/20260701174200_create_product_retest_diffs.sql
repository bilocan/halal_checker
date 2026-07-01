-- Staging table for the admin "retest products" tool: keyword/rule changes
-- (e.g. new haram/suspicious entries) don't retroactively touch already
-- analysed products, so admins need to preview what would change before
-- writing it back to products/product_analysis.
CREATE TABLE IF NOT EXISTS product_retest_diffs (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id        UUID        NOT NULL,
  barcode       TEXT        NOT NULL REFERENCES products(barcode) ON DELETE CASCADE,
  -- Compact verdict snapshots (RetestSnapshot) — old is the currently-stored
  -- verdict, new is what the rules engine would produce today. Shown side by
  -- side in the admin diff review UI.
  old_snapshot  JSONB       NOT NULL,
  new_snapshot  JSONB       NOT NULL,
  -- Full { product: ProductRow, analysis: AnalysisRow } payload — everything
  -- needed to persist the new verdict on apply, without recomputing it.
  apply_payload JSONB       NOT NULL,
  applied       BOOLEAN     NOT NULL DEFAULT false,
  applied_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (run_id, barcode)
);

CREATE INDEX IF NOT EXISTS product_retest_diffs_run_applied_idx
  ON product_retest_diffs (run_id, applied);

-- Accessed only via the retest-products edge function (service role);
-- no anon/authenticated policies are defined, so RLS denies all client access.
ALTER TABLE product_retest_diffs ENABLE ROW LEVEL SECURITY;
