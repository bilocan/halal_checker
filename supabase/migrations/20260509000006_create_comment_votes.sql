-- One vote row per (comment, user) pair.
-- value: 1 = upvote, -1 = downvote.
-- Upsert to change vote; delete row to retract.
CREATE TABLE IF NOT EXISTS comment_votes (
  comment_id  UUID      NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id     UUID      NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  value       SMALLINT  NOT NULL DEFAULT 1 CHECK (value IN (1, -1)),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (comment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_votes_comment_id ON comment_votes (comment_id);
CREATE INDEX IF NOT EXISTS idx_votes_user_id    ON comment_votes (user_id);

ALTER TABLE comment_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Votes are readable by everyone"
  ON comment_votes FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can vote"
  ON comment_votes FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "Users can change their own vote"
  ON comment_votes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can retract their own vote"
  ON comment_votes FOR DELETE
  USING (auth.uid() = user_id);
