-- Add foreign key constraint from ingredient_contributions.barcode to products.barcode
-- This enables Supabase foreign table joins in the admin panel

ALTER TABLE ingredient_contributions
ADD CONSTRAINT ingredient_contributions_barcode_fkey
FOREIGN KEY (barcode)
REFERENCES products(barcode);