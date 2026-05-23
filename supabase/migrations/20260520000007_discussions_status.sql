-- Topic workflow: open | in_progress | closed (web forum + app).
-- Legacy projects may have discussions (or comments) without community columns.

ALTER TABLE discussions
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE discussions
  ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE discussions
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'open';

ALTER TABLE discussions
  DROP CONSTRAINT IF EXISTS discussions_status_check;

ALTER TABLE discussions
  ADD CONSTRAINT discussions_status_check
  CHECK (status IN ('open', 'in_progress', 'closed'));

-- Backfill from comments only when that column exists (must use dynamic SQL — Postgres
-- validates column names at parse time, so a static UPDATE would fail on legacy DBs).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'comments'
      AND column_name = 'created_by'
  ) THEN
    EXECUTE $sql$
      UPDATE discussions
      SET created_by = (
        SELECT c.created_by
        FROM comments c
        WHERE c.discussion_id = discussions.id
          AND c.created_by IS NOT NULL
        ORDER BY c.created_at ASC
        LIMIT 1
      )
      WHERE discussions.created_by IS NULL
    $sql$;
  END IF;
END $$;

UPDATE discussions
SET created_by = (
  SELECT id FROM profiles ORDER BY created_at ASC NULLS LAST LIMIT 1
)
WHERE discussions.created_by IS NULL
  AND EXISTS (SELECT 1 FROM profiles);

UPDATE discussions
SET status = 'closed'
WHERE is_locked = true
  AND status = 'open';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM discussions WHERE created_by IS NULL) THEN
    ALTER TABLE discussions ALTER COLUMN created_by SET NOT NULL;
  END IF;
END $$;

DROP POLICY IF EXISTS "Authors and admins can update discussions" ON discussions;

CREATE POLICY "Authors and admins can update discussions"
  ON discussions FOR UPDATE
  USING (
    auth.uid() = created_by
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
  );
