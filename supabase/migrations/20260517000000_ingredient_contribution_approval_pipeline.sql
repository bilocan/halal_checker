-- 1. Allow authenticated users to update ingredient contribution status.
--    Mirrors the equivalent policy on product_image_submissions.
CREATE POLICY "Authenticated users can update ingredient contribution status"
  ON ingredient_contributions FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 2. When a contribution is approved, immediately write the ingredients into
--    the cached products row and back-date fetched_at so the edge function
--    re-runs AI analysis on the next scan with the new ingredients.
CREATE OR REPLACE FUNCTION apply_approved_ingredient_contribution()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
    UPDATE products
    SET
      ingredients = (
        SELECT COALESCE(jsonb_agg(token), '[]'::jsonb)
        FROM (
          SELECT trim(item) AS token
          FROM unnest(string_to_array(NEW.ingredient_text, ',')) AS item
          WHERE trim(item) <> ''
        ) sub
      ),
      -- Clear stale AI verdicts — edge function re-analyses on next lookup.
      is_halal               = false,
      haram_ingredients      = '[]'::jsonb,
      suspicious_ingredients = '[]'::jsonb,
      ingredient_warnings    = '{}'::jsonb,
      explanation            = '',
      analyzed_by_ai         = false,
      fetched_at             = NOW() - INTERVAL '31 days'
    WHERE barcode = NEW.barcode;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_ingredient_contribution_approved
  AFTER UPDATE ON ingredient_contributions
  FOR EACH ROW
  EXECUTE FUNCTION apply_approved_ingredient_contribution();

-- 3. Protect approved ingredients from being overwritten by the edge function.
--    The edge function does a full upsert from OpenFoodFacts data which would
--    clobber the approved ingredients. This BEFORE trigger restores them on
--    every products INSERT or UPDATE, mirroring restore_approved_images_on_product_write().
CREATE OR REPLACE FUNCTION restore_approved_ingredients_on_product_write()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  approved_text TEXT;
BEGIN
  SELECT ingredient_text
  INTO approved_text
  FROM ingredient_contributions
  WHERE barcode = NEW.barcode AND status = 'approved'
  ORDER BY created_at DESC
  LIMIT 1;

  IF approved_text IS NOT NULL THEN
    NEW.ingredients := (
      SELECT COALESCE(jsonb_agg(token), '[]'::jsonb)
      FROM (
        SELECT trim(item) AS token
        FROM unnest(string_to_array(approved_text, ',')) AS item
        WHERE trim(item) <> ''
      ) sub
    );
    -- Force re-analysis with the community ingredients on next scan.
    NEW.analyzed_by_ai := false;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER preserve_approved_ingredients_on_product_upsert
  BEFORE INSERT OR UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION restore_approved_ingredients_on_product_write();
