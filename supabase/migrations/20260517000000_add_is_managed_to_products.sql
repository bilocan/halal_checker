-- Flag products that have been manually curated by an admin.
-- When is_managed = true, the lookup-product Edge Function skips the
-- Open Food Facts fetch and returns the DB row as-is, preventing
-- external data from overwriting admin corrections.
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_managed BOOLEAN NOT NULL DEFAULT false;

-- Automatically mark a product as managed when an admin resolves its
-- analysis (status → 'resolved'). Uses SECURITY DEFINER so the trigger
-- can update the products table regardless of RLS policies.
CREATE OR REPLACE FUNCTION mark_product_managed_on_resolve()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'resolved' AND OLD.status IS DISTINCT FROM 'resolved' THEN
    UPDATE products
    SET is_managed = true
    WHERE barcode = NEW.barcode;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_analysis_resolved_mark_managed
  AFTER UPDATE ON product_analyses
  FOR EACH ROW
  EXECUTE FUNCTION mark_product_managed_on_resolve();
