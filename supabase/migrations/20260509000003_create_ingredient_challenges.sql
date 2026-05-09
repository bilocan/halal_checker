-- A formal challenge by a community member to the verdict on a specific ingredient.
--
-- status values:
--   open       → awaiting community discussion or admin review
--   resolved   → admin/scholar set a resolution
--   dismissed  → not enough basis to change the verdict
CREATE TABLE IF NOT EXISTS ingredient_challenges (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode          TEXT        NOT NULL,
  ingredient       TEXT        NOT NULL,
  current_verdict  TEXT        NOT NULL CHECK (current_verdict IN ('halal', 'haram', 'suspicious', 'unknown')),
  claimed_verdict  TEXT        NOT NULL CHECK (claimed_verdict IN ('halal', 'haram', 'suspicious')),
  reason           TEXT        NOT NULL,
  status           TEXT        NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'dismissed')),
  created_by       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  resolved_by      UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  resolution_note  TEXT,
  resolved_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_challenges_barcode  ON ingredient_challenges (barcode);
CREATE INDEX IF NOT EXISTS idx_challenges_status   ON ingredient_challenges (status);
CREATE INDEX IF NOT EXISTS idx_challenges_created_by ON ingredient_challenges (created_by);

ALTER TABLE ingredient_challenges ENABLE ROW LEVEL SECURITY;

-- Everyone can read challenges.
CREATE POLICY "Challenges are readable by everyone"
  ON ingredient_challenges FOR SELECT
  USING (true);

-- Authenticated users can submit challenges.
CREATE POLICY "Authenticated users can submit challenges"
  ON ingredient_challenges FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = created_by);

-- Service role / admin resolves challenges.
CREATE POLICY "Service role can update challenges"
  ON ingredient_challenges FOR UPDATE
  USING (auth.role() = 'service_role');
