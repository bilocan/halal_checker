-- Community-contributed ingredient text for products with missing data.
-- When a user submits ingredients from the packaging, the text is stored here
-- and the product is re-analysed on next lookup (via force-refresh).
CREATE TABLE IF NOT EXISTS ingredient_contributions (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  barcode         TEXT        NOT NULL,
  ingredient_text TEXT        NOT NULL,
  submitted_by    UUID        REFERENCES auth.users (id),
  status          TEXT        NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ingredient_contributions_barcode
  ON ingredient_contributions (barcode);

-- RLS: anyone can insert, only admins can update/delete.
ALTER TABLE ingredient_contributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can submit ingredient contributions"
  ON ingredient_contributions FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Anyone can read ingredient contributions"
  ON ingredient_contributions FOR SELECT
  TO anon, authenticated
  USING (true);
