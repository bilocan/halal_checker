-- Superadmin toggle: auto-approve user photo submissions (skip admin queue).

INSERT INTO app_config (key, value) VALUES
  ('photo_submissions_auto_approve', 'false')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.set_superadmin_app_config_flag(p_key text, p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_key NOT IN (
    'gemini_lookup_empty_off',
    'closed_beta_banner',
    'deep_analysis_enabled',
    'photo_submissions_auto_approve'
  ) THEN
    RAISE EXCEPTION 'key not allowed: %', p_key;
  END IF;
  IF p_value NOT IN ('true', 'false') THEN
    RAISE EXCEPTION 'value must be true or false';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'superadmin'
  ) THEN
    RAISE EXCEPTION 'forbidden: superadmin only';
  END IF;
  INSERT INTO app_config (key, value) VALUES (p_key, p_value)
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
END;
$$;

REVOKE ALL ON FUNCTION public.set_superadmin_app_config_flag(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_superadmin_app_config_flag(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.photo_submissions_auto_approve_enabled()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT value = 'true' FROM app_config WHERE key = 'photo_submissions_auto_approve'),
    false
  );
$$;

REVOKE ALL ON FUNCTION public.photo_submissions_auto_approve_enabled() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.photo_submissions_auto_approve_enabled() TO anon, authenticated;

DROP POLICY IF EXISTS "Authenticated users can submit images" ON product_image_submissions;
CREATE POLICY "Authenticated users can submit images"
  ON product_image_submissions FOR INSERT
  TO authenticated
  WITH CHECK (
    submitted_by = auth.uid()
    AND status IN ('pending', 'approved')
    AND (
      status = 'pending'
      OR public.photo_submissions_auto_approve_enabled()
    )
  );

DROP POLICY IF EXISTS "Authenticated users can update image submission status"
  ON product_image_submissions;
CREATE POLICY "Admins can update image submission status"
  ON product_image_submissions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role IN ('admin', 'superadmin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role IN ('admin', 'superadmin')
    )
  );

CREATE OR REPLACE FUNCTION update_product_image_on_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND (
    TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'approved'
  ) THEN
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

DROP TRIGGER IF EXISTS on_image_submission_approved_insert ON product_image_submissions;
CREATE TRIGGER on_image_submission_approved_insert
  AFTER INSERT ON product_image_submissions
  FOR EACH ROW
  EXECUTE FUNCTION update_product_image_on_approval();
