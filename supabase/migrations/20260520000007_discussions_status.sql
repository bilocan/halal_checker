-- Topic workflow: open | in_progress | closed (web forum + app).
ALTER TABLE discussions
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'open';

ALTER TABLE discussions
  DROP CONSTRAINT IF EXISTS discussions_status_check;

ALTER TABLE discussions
  ADD CONSTRAINT discussions_status_check
  CHECK (status IN ('open', 'in_progress', 'closed'));

UPDATE discussions
SET status = 'closed'
WHERE is_locked = true AND status = 'open';

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
