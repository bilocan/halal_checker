-- Allow user deletion without orphaning contribution/submission rows.
-- Both tables used ON DELETE RESTRICT (the default), which caused adminClient.auth.admin.deleteUser()
-- to fail with a FK violation when the user had contributed ingredients or submitted images.

ALTER TABLE ingredient_contributions
  DROP CONSTRAINT IF EXISTS ingredient_contributions_submitted_by_fkey,
  ADD CONSTRAINT ingredient_contributions_submitted_by_fkey
    FOREIGN KEY (submitted_by) REFERENCES auth.users (id) ON DELETE SET NULL;

ALTER TABLE product_image_submissions
  DROP CONSTRAINT IF EXISTS product_image_submissions_submitted_by_fkey,
  ADD CONSTRAINT product_image_submissions_submitted_by_fkey
    FOREIGN KEY (submitted_by) REFERENCES auth.users (id) ON DELETE SET NULL;
