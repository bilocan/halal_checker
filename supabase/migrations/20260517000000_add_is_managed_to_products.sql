-- Flag products that have been manually curated by an admin.
-- When is_managed = true, the lookup-product Edge Function skips the
-- Open Food Facts fetch and returns the DB row as-is, preventing
-- external data from overwriting admin corrections.
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_managed BOOLEAN NOT NULL DEFAULT false;
