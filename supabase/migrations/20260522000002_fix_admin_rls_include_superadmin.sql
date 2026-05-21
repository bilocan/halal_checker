-- RLS policies created before/with RBAC only checked role = 'admin'.
-- Superadmins have the same admin.approvals operations but failed these checks.

DROP POLICY IF EXISTS "Admins can update AI requests" ON ai_ingredient_requests;
CREATE POLICY "Admins can update AI requests"
  ON ai_ingredient_requests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  );

DROP POLICY IF EXISTS "Admins can read ingredient reports" ON ingredient_reports;
CREATE POLICY "Admins can read ingredient reports"
  ON ingredient_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  );

DROP POLICY IF EXISTS "Admins can update ingredient reports" ON ingredient_reports;
CREATE POLICY "Admins can update ingredient reports"
  ON ingredient_reports FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  );

DROP POLICY IF EXISTS "Authors and admins can update discussions" ON discussions;
CREATE POLICY "Authors and admins can update discussions"
  ON discussions FOR UPDATE
  USING (
    auth.uid() = created_by
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
  );
