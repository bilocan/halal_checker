-- Tracks the deep-analysis pipeline for a product.
-- One record per product; status advances through the pipeline stages.
--
-- status values:
--   pending          → user marked it for analysis, not yet processed
--   ai_analyzing     → Edge Function is currently running
--   ai_done          → AI finished, awaiting community/admin review
--   community_review → opened for community discussion
--   consulting       → escalated to a scholar
--   resolved         → final verdict set by scholar or admin
--
-- ai_analysis JSONB shape:
--   {
--     "summary": "...",
--     "ingredients": [
--       {
--         "name": "gelatin",
--         "verdict": "suspicious",       -- "halal" | "haram" | "suspicious" | "unknown"
--         "confidence": "medium",         -- "high" | "medium" | "low"
--         "reason": "...",
--         "islamicBasis": "...",
--         "alternativeNames": ["E441"]
--       }
--     ]
--   }
CREATE TABLE IF NOT EXISTS product_analyses (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode               TEXT        NOT NULL REFERENCES products(barcode) ON DELETE CASCADE,
  status                TEXT        NOT NULL DEFAULT 'pending'
                                    CHECK (status IN (
                                      'pending', 'ai_analyzing', 'ai_done',
                                      'community_review', 'consulting', 'resolved'
                                    )),
  ai_analysis           JSONB,
  final_verdict         TEXT        CHECK (final_verdict IN ('halal', 'haram', 'unknown')),
  final_verdict_reason  TEXT,
  queued_by             UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  resolved_by           UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  resolved_at           TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (barcode)
);

CREATE INDEX IF NOT EXISTS idx_product_analyses_status ON product_analyses (status);
CREATE INDEX IF NOT EXISTS idx_product_analyses_barcode ON product_analyses (barcode);

-- Keep updated_at current automatically.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER product_analyses_updated_at
  BEFORE UPDATE ON product_analyses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE product_analyses ENABLE ROW LEVEL SECURITY;

-- Anyone can read analysis records (status + results are public).
CREATE POLICY "Analyses are readable by everyone"
  ON product_analyses FOR SELECT
  USING (true);

-- Authenticated users can queue a product (insert with status=pending).
CREATE POLICY "Authenticated users can queue analyses"
  ON product_analyses FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND status = 'pending');

-- Only service role advances status / writes AI results.
CREATE POLICY "Service role can update analyses"
  ON product_analyses FOR UPDATE
  USING (auth.role() = 'service_role');
