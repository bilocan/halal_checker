-- Allow the Flutter app (anon key) to read merged product + analysis rows.
GRANT SELECT ON products_full TO anon, authenticated;
