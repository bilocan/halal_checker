-- Tracks scan progress per retest run so the admin "retest products" tool
-- (see product_retest_diffs) can resume a scan across page reloads instead of
-- re-scanning the whole product catalog from the start every time, and so the
-- UI can restore an in-progress/reviewable run after a refresh.
CREATE TABLE IF NOT EXISTS product_retest_runs (
  run_id     UUID        PRIMARY KEY,
  cursor     TEXT,
  done       BOOLEAN     NOT NULL DEFAULT false,
  scanned    INTEGER     NOT NULL DEFAULT 0,
  changed    INTEGER     NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS product_retest_runs_updated_at_idx
  ON product_retest_runs (updated_at DESC);

-- Accessed only via the retest-products edge function (service role);
-- no anon/authenticated policies are defined, so RLS denies all client access.
ALTER TABLE product_retest_runs ENABLE ROW LEVEL SECURITY;
