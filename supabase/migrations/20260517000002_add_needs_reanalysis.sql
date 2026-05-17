-- Tracks whether the stored verdict is stale and must be recalculated by the
-- rules engine. Set to true when product fields (ingredients, name, labels)
-- are manually edited by an admin. The lookup-product Edge Function detects
-- this flag, re-runs keyword analysis on the stored ingredients, writes the
-- new verdict, and resets the flag to false.
ALTER TABLE products ADD COLUMN IF NOT EXISTS needs_reanalysis BOOLEAN NOT NULL DEFAULT FALSE;
