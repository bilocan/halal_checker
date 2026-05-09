-- Key-value config table used by the app for version checking.
-- Bump latest_version here whenever a new release is published.
CREATE TABLE IF NOT EXISTS app_config (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Anonymous clients may read; only service role may write.
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon read"
  ON app_config FOR SELECT
  USING (true);

INSERT INTO app_config (key, value) VALUES
  ('latest_version',    '1.1.0'),
  ('android_store_url', 'https://play.google.com/store/apps/details?id=app.halalscan'),
  ('ios_store_url',     'https://apps.apple.com/app/idapp.halalscan')
ON CONFLICT (key) DO NOTHING;
