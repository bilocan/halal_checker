-- RBAC: superadmin role, operations catalog, role-operation mapping, and profile role guards.

-- Extend profiles.role to include superadmin.
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('user', 'moderator', 'scholar', 'admin', 'superadmin'));

-- Catalog of admin operations (seeded; extended via migrations).
CREATE TABLE IF NOT EXISTS operations (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT ''
);

-- Which operations each role may perform.
CREATE TABLE IF NOT EXISTS role_operations (
  role          TEXT NOT NULL,
  operation_id  TEXT NOT NULL REFERENCES operations(id) ON DELETE CASCADE,
  PRIMARY KEY (role, operation_id),
  CHECK (role IN ('user', 'moderator', 'scholar', 'admin', 'superadmin'))
);

ALTER TABLE operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_operations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Operations readable by authenticated"
  ON operations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Role operations readable by authenticated"
  ON role_operations FOR SELECT
  TO authenticated
  USING (true);

INSERT INTO operations (id, name, description) VALUES
  ('admin.products',       'Manage products',        'Edit product records and analysis flags'),
  ('admin.approvals',      'Review approvals',       'Approve or reject community submissions'),
  ('admin.keywords',       'Manage keywords',        'Edit approved community keyword rules'),
  ('admin.rules',            'Upload rules',           'Upload keyword-rules.json to storage'),
  ('admin.users.view',       'View users',             'List registered users and their roles'),
  ('admin.users.assign',     'Assign roles',           'Change a user''s role (superadmin only)'),
  ('admin.roles.view',       'View role permissions',  'See which operations each role may perform')
ON CONFLICT (id) DO NOTHING;

INSERT INTO role_operations (role, operation_id) VALUES
  ('admin', 'admin.products'),
  ('admin', 'admin.approvals'),
  ('admin', 'admin.keywords'),
  ('admin', 'admin.rules'),
  ('admin', 'admin.users.view'),
  ('admin', 'admin.roles.view'),
  ('superadmin', 'admin.products'),
  ('superadmin', 'admin.approvals'),
  ('superadmin', 'admin.keywords'),
  ('superadmin', 'admin.rules'),
  ('superadmin', 'admin.users.view'),
  ('superadmin', 'admin.users.assign'),
  ('superadmin', 'admin.roles.view')
ON CONFLICT DO NOTHING;

-- Prevent users from self-promoting by changing their own role.
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role IS NOT DISTINCT FROM (SELECT p.role FROM profiles p WHERE p.id = auth.uid())
  );

-- Only superadmins may change any profile (including role assignment).
CREATE POLICY "Superadmin can update any profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );
