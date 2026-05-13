-- Fix the iOS App Store URL: the original seed used the bundle ID
-- (idapp.halalscan) which is not a valid App Store URL format.
-- Apple App Store URLs require the numeric Apple ID, not the bundle ID.
-- Until the actual numeric ID is configured, use a search-friendly URL.
UPDATE app_config
SET value = 'https://apps.apple.com/app/halalscan'
WHERE key = 'ios_store_url'
  AND value = 'https://apps.apple.com/app/idapp.halalscan';
