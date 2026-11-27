-- Configurable promo popup (image + link) shown on app start and on halalscan.at.
-- Single-row table; superadmin edits it from Admin → Settings.
-- campaign_id is regenerated whenever image_url or link_url changes, so clients
-- that dismissed the previous campaign see the new one again.

CREATE TABLE IF NOT EXISTS public.promo_announcement (
  id          smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  image_url   text,
  link_url    text,
  show_in_app boolean NOT NULL DEFAULT false,
  show_on_web boolean NOT NULL DEFAULT false,
  ends_at     timestamptz,
  campaign_id uuid NOT NULL DEFAULT gen_random_uuid(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.promo_announcement (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.promo_announcement_before_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  IF NEW.image_url IS DISTINCT FROM OLD.image_url
     OR NEW.link_url IS DISTINCT FROM OLD.link_url THEN
    NEW.campaign_id := gen_random_uuid();
  ELSE
    NEW.campaign_id := OLD.campaign_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS promo_announcement_before_update ON public.promo_announcement;
CREATE TRIGGER promo_announcement_before_update
  BEFORE UPDATE ON public.promo_announcement
  FOR EACH ROW EXECUTE FUNCTION public.promo_announcement_before_update();

ALTER TABLE public.promo_announcement ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read promo announcement" ON public.promo_announcement;
CREATE POLICY "Public read promo announcement"
  ON public.promo_announcement FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Superadmin update promo announcement" ON public.promo_announcement;
CREATE POLICY "Superadmin update promo announcement"
  ON public.promo_announcement FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );

-- Storage bucket for promo posters (public read, superadmin write).
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'promo-images', 'promo-images', true, 5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Public read promo images" ON storage.objects;
CREATE POLICY "Public read promo images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'promo-images');

DROP POLICY IF EXISTS "Superadmin insert promo images" ON storage.objects;
CREATE POLICY "Superadmin insert promo images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'promo-images'
    AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );

DROP POLICY IF EXISTS "Superadmin update promo images" ON storage.objects;
CREATE POLICY "Superadmin update promo images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'promo-images'
    AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );

DROP POLICY IF EXISTS "Superadmin delete promo images" ON storage.objects;
CREATE POLICY "Superadmin delete promo images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'promo-images'
    AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );
