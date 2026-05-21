-- Add batch_import operation, restricted to superadmin.

INSERT INTO operations (id, name, description) VALUES
  ('admin.batch_import', 'Batch import', 'Import a barcode list file and run bulk halal lookup')
ON CONFLICT (id) DO NOTHING;

INSERT INTO role_operations (role, operation_id) VALUES
  ('superadmin', 'admin.batch_import')
ON CONFLICT DO NOTHING;
