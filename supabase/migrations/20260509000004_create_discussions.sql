-- Discussion threads, one per product or per ingredient challenge.
-- challenge_id is NULL for general product discussions.
CREATE TABLE IF NOT EXISTS discussions (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode       TEXT        NOT NULL,
  challenge_id  UUID        REFERENCES ingredient_challenges(id) ON DELETE CASCADE,
  title         TEXT,
  is_locked     BOOLEAN     NOT NULL DEFAULT false,
  created_by    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_discussions_barcode      ON discussions (barcode);
CREATE INDEX IF NOT EXISTS idx_discussions_challenge_id ON discussions (challenge_id);

ALTER TABLE discussions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Discussions are readable by everyone"
  ON discussions FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can start discussions"
  ON discussions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = created_by);

-- Only service role can lock/unlock threads.
CREATE POLICY "Service role can update discussions"
  ON discussions FOR UPDATE
  USING (auth.role() = 'service_role');
