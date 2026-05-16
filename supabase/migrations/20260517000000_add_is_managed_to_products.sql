-- Flag products that have been manually curated by an admin.
-- When is_managed = true, the lookup-product Edge Function skips the
-- Open Food Facts fetch and returns the DB row as-is, preventing
-- external data from overwriting admin corrections.
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_managed BOOLEAN NOT NULL DEFAULT false;

-- Replace the existing product_analyses BEFORE UPDATE trigger with one
-- that also marks the product as managed when an admin resolves the
-- analysis (status → 'resolved'). SECURITY DEFINER lets it update
-- the products table regardless of RLS policies.
DROP TRIGGER IF EXISTS product_analyses_updated_at ON product_analyses;

CREATE OR REPLACE FUNCTION product_analyses_before_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();

  IF NEW.status = 'resolved' AND OLD.status IS DISTINCT FROM 'resolved' THEN
    UPDATE products
    SET is_managed = true
    WHERE barcode = NEW.barcode;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER product_analyses_updated_at
  BEFORE UPDATE ON product_analyses
  FOR EACH ROW
  EXECUTE FUNCTION product_analyses_before_update();
