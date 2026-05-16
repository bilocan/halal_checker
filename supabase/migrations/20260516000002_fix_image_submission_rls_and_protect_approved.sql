-- 1. Allow authenticated users to update submission status (approve/reject).
--    Without this policy RLS silently blocks the admin's UPDATE call and the
--    approval trigger never fires.
CREATE POLICY "Authenticated users can update image submission status"
  ON product_image_submissions FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 2. Protect approved images from being overwritten by the edge function.
--    The edge function does a full upsert from OpenFoodFacts data, which sets
--    image URLs to whatever OFF has (often null). This BEFORE trigger runs on
--    every products INSERT/UPDATE and restores any approved image URLs so they
--    are never clobbered.
CREATE OR REPLACE FUNCTION restore_approved_images_on_product_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  approved_front       TEXT;
  approved_ingredients TEXT;
  approved_nutrition   TEXT;
BEGIN
  SELECT
    MAX(CASE WHEN image_type = 'front'       THEN public_url END),
    MAX(CASE WHEN image_type = 'ingredients' THEN public_url END),
    MAX(CASE WHEN image_type = 'nutrition'   THEN public_url END)
  INTO approved_front, approved_ingredients, approved_nutrition
  FROM product_image_submissions
  WHERE barcode = NEW.barcode AND status = 'approved';

  IF approved_front       IS NOT NULL THEN NEW.image_front_url       := approved_front;       END IF;
  IF approved_ingredients IS NOT NULL THEN NEW.image_ingredients_url := approved_ingredients; END IF;
  IF approved_nutrition   IS NOT NULL THEN NEW.image_nutrition_url   := approved_nutrition;   END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER preserve_approved_images_on_product_upsert
  BEFORE INSERT OR UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION restore_approved_images_on_product_write();
