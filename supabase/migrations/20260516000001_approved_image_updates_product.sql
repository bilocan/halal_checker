-- When an image submission is approved, write its URL into the cached products
-- row. The function uses SECURITY DEFINER so it runs as the owner (postgres)
-- and can bypass the products RLS policy that normally blocks client writes.
CREATE OR REPLACE FUNCTION update_product_image_on_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
    UPDATE products
    SET
      image_front_url = CASE
        WHEN NEW.image_type = 'front' THEN NEW.public_url
        ELSE image_front_url
      END,
      image_ingredients_url = CASE
        WHEN NEW.image_type = 'ingredients' THEN NEW.public_url
        ELSE image_ingredients_url
      END,
      image_nutrition_url = CASE
        WHEN NEW.image_type = 'nutrition' THEN NEW.public_url
        ELSE image_nutrition_url
      END
    WHERE barcode = NEW.barcode;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_image_submission_approved
  AFTER UPDATE ON product_image_submissions
  FOR EACH ROW
  EXECUTE FUNCTION update_product_image_on_approval();
