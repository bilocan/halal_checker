-- When pack photos are approved for a barcode missing from Open Food Facts,
-- ensure a cached [products] + [product_analysis] row exists so lookups can hit
-- the DB and Tier-3 vision can read [image_ingredients_url].

CREATE OR REPLACE FUNCTION update_product_image_on_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
    INSERT INTO products (barcode, name, ingredients, labels)
    VALUES (
      NEW.barcode,
      COALESCE(NULLIF(BTRIM(NEW.product_name), ''), 'Product ' || NEW.barcode),
      '[]'::jsonb,
      '[]'::jsonb
    )
    ON CONFLICT (barcode) DO NOTHING;

    INSERT INTO product_analysis (barcode)
    VALUES (NEW.barcode)
    ON CONFLICT (barcode) DO NOTHING;

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
