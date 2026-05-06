-- Enable RLS on products: anonymous users can read, but only the Edge Function
-- (which runs as service role and bypasses RLS) can write.
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon read"
  ON products FOR SELECT
  USING (true);
