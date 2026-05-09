-- Comments inside a discussion thread.
-- parent_id enables one level of replies (top-level + replies only, no deep nesting).
-- Deleted comments are soft-deleted: body is cleared, is_deleted set to true.
CREATE TABLE IF NOT EXISTS comments (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id  UUID        NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  parent_id      UUID        REFERENCES comments(id) ON DELETE CASCADE,
  body           TEXT        NOT NULL,
  is_deleted     BOOLEAN     NOT NULL DEFAULT false,
  created_by     UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_discussion_id ON comments (discussion_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id     ON comments (parent_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_by    ON comments (created_by);

CREATE TRIGGER comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are readable by everyone"
  ON comments FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can post comments"
  ON comments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = created_by);

-- Authors can soft-delete or edit their own comments.
CREATE POLICY "Authors can update own comments"
  ON comments FOR UPDATE
  USING (auth.uid() = created_by);

-- Service role can hard-delete or moderate any comment.
CREATE POLICY "Service role can delete comments"
  ON comments FOR DELETE
  USING (auth.role() = 'service_role');
