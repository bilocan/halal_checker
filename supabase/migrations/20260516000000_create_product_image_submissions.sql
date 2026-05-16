-- User-submitted product photos, stored in the 'product-images' storage bucket.
-- Before running this migration, create the bucket in Supabase dashboard or run:
--   INSERT INTO storage.buckets (id, name, public)
--   VALUES ('product-images', 'product-images', true)
--   ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS product_image_submissions (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  barcode      TEXT        NOT NULL,
  image_type   TEXT        NOT NULL DEFAULT 'front'
               CHECK (image_type IN ('front', 'ingredients', 'nutrition')),
  storage_path TEXT        NOT NULL,
  public_url   TEXT,
  product_name TEXT,
  submitted_by UUID        REFERENCES auth.users (id),
  status       TEXT        NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_image_submissions_barcode
  ON product_image_submissions (barcode);

ALTER TABLE product_image_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can submit images"
  ON product_image_submissions FOR INSERT
  TO authenticated
  WITH CHECK (submitted_by = auth.uid());

CREATE POLICY "Anyone can read image submissions"
  ON product_image_submissions FOR SELECT
  TO anon, authenticated
  USING (true);

-- Storage bucket policies (run these after creating the 'product-images' bucket)
-- CREATE POLICY "Anyone can read product images"
--   ON storage.objects FOR SELECT
--   TO anon, authenticated
--   USING (bucket_id = 'product-images');
--
-- CREATE POLICY "Authenticated users can upload product images"
--   ON storage.objects FOR INSERT
--   TO authenticated
--   WITH CHECK (bucket_id = 'product-images');
