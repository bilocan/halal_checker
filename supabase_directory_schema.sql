-- Run this in the Supabase SQL editor to set up the Halal Directory tables.

-- ── Halal Brands ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS halal_brands (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  name             TEXT        NOT NULL,
  logo_url         TEXT,
  country          TEXT        NOT NULL,
  -- food | cosmetics | pharma | other
  category         TEXT        NOT NULL DEFAULT 'food',
  certification_body TEXT,
  website          TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE halal_brands ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read halal_brands"
  ON halal_brands FOR SELECT USING (true);

-- Allow any authenticated user to insert. Tighten to a specific role later if needed.
CREATE POLICY "Authenticated insert halal_brands"
  ON halal_brands FOR INSERT TO authenticated WITH CHECK (true);

-- ── Halal Stores / Restaurants ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS halal_stores (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  name             TEXT        NOT NULL,
  logo_url         TEXT,
  address          TEXT        NOT NULL,
  city             TEXT        NOT NULL,
  country          TEXT        NOT NULL,
  latitude         FLOAT8      NOT NULL,
  longitude        FLOAT8      NOT NULL,
  -- restaurant | grocery | butcher | bakery | other
  category         TEXT        NOT NULL DEFAULT 'restaurant',
  certification_body TEXT,
  phone            TEXT,
  website          TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE halal_stores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read halal_stores"
  ON halal_stores FOR SELECT USING (true);

CREATE POLICY "Authenticated insert halal_stores"
  ON halal_stores FOR INSERT TO authenticated WITH CHECK (true);

-- ── Sample data (delete or adapt before production) ───────────────────────────

-- INSERT INTO halal_brands (name, country, category, certification_body, website)
-- VALUES ('Example Brand', 'Germany', 'food', 'HFCE', 'https://example.com');

-- INSERT INTO halal_stores (name, address, city, country, latitude, longitude, category, certification_body, phone, website)
-- VALUES ('Example Restaurant', '123 Main St', 'Berlin', 'Germany', 52.5200, 13.4050, 'restaurant', 'HFCE', '+49 30 123456', 'https://example.com');
