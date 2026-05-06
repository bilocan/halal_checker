-- Weekly job: delete products not scanned in the last 90 days.
-- Keeps the DB well under the 500 MB free-tier limit as the catalogue grows.
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
  'cleanup-stale-products',
  '0 3 * * 0',  -- every Sunday at 03:00 UTC
  $$DELETE FROM public.products WHERE fetched_at < NOW() - INTERVAL '90 days'$$
);
