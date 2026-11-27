-- Events list (app Events screen + halalscan.at/events). The promo popup now
-- features one event: promo_announcement.event_id. image_url / link_url on
-- promo_announcement are kept (and synced from the event by trigger) so older
-- readers of the popup keep working unchanged.

CREATE TABLE IF NOT EXISTS public.events (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text NOT NULL CHECK (length(btrim(title)) > 0),
  description text,
  image_url   text,
  link_url    text,
  starts_at   timestamptz NOT NULL,
  -- Last session / end of the event; null = single-date event.
  ends_at     timestamptz,
  published   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at IS NULL OR ends_at >= starts_at)
);

CREATE INDEX IF NOT EXISTS events_starts_at_idx ON public.events (starts_at);

CREATE OR REPLACE FUNCTION public.events_touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS events_touch_updated_at ON public.events;
CREATE TRIGGER events_touch_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.events_touch_updated_at();

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- Anon policy must not touch profiles (anon may lack access to it).
DROP POLICY IF EXISTS "Anon read published events" ON public.events;
CREATE POLICY "Anon read published events"
  ON public.events FOR SELECT
  TO anon
  USING (published);

-- Signed-in users see published events; superadmins also see drafts.
DROP POLICY IF EXISTS "Authenticated read events" ON public.events;
CREATE POLICY "Authenticated read events"
  ON public.events FOR SELECT
  TO authenticated
  USING (
    published
    OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );

DROP POLICY IF EXISTS "Superadmin insert events" ON public.events;
CREATE POLICY "Superadmin insert events"
  ON public.events FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );

DROP POLICY IF EXISTS "Superadmin update events" ON public.events;
CREATE POLICY "Superadmin update events"
  ON public.events FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );

DROP POLICY IF EXISTS "Superadmin delete events" ON public.events;
CREATE POLICY "Superadmin delete events"
  ON public.events FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'superadmin')
  );

-- ── Popup features one event ────────────────────────────────────────────────

ALTER TABLE public.promo_announcement
  ADD COLUMN IF NOT EXISTS event_id uuid REFERENCES public.events (id) ON DELETE SET NULL;

-- Popup image/link always come from the featured event; no event = no content.
-- campaign_id still changes only when image or link changes, so re-linking the
-- same poster does not re-show the popup to users who closed it.
CREATE OR REPLACE FUNCTION public.promo_announcement_before_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  ev record;
BEGIN
  NEW.updated_at := now();
  IF NEW.event_id IS NOT NULL THEN
    SELECT e.image_url, e.link_url INTO ev FROM public.events e WHERE e.id = NEW.event_id;
    NEW.image_url := ev.image_url;
    NEW.link_url := ev.link_url;
  ELSE
    NEW.image_url := NULL;
    NEW.link_url := NULL;
  END IF;
  IF NEW.image_url IS DISTINCT FROM OLD.image_url
     OR NEW.link_url IS DISTINCT FROM OLD.link_url THEN
    NEW.campaign_id := gen_random_uuid();
  ELSE
    NEW.campaign_id := OLD.campaign_id;
  END IF;
  RETURN NEW;
END;
$$;

-- Editing the featured event refreshes the popup's image/link.
CREATE OR REPLACE FUNCTION public.events_sync_featured_promo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.image_url IS DISTINCT FROM OLD.image_url
     OR NEW.link_url IS DISTINCT FROM OLD.link_url THEN
    UPDATE public.promo_announcement SET event_id = event_id WHERE event_id = NEW.id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS events_sync_featured_promo ON public.events;
CREATE TRIGGER events_sync_featured_promo
  AFTER UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.events_sync_featured_promo();

-- Deleting (or unpublishing) the featured event switches the popup off.
CREATE OR REPLACE FUNCTION public.events_unfeature_promo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE public.promo_announcement
      SET event_id = NULL, show_in_app = false, show_on_web = false
      WHERE event_id = OLD.id;
    RETURN OLD;
  END IF;
  IF OLD.published AND NOT NEW.published THEN
    UPDATE public.promo_announcement
      SET show_in_app = false, show_on_web = false
      WHERE event_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS events_unfeature_promo ON public.events;
CREATE TRIGGER events_unfeature_promo
  BEFORE DELETE OR UPDATE OF published ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.events_unfeature_promo();

-- ── Backfill: turn the live AGD poster into the first event ─────────────────

DO $$
DECLARE
  promo record;
  new_id uuid;
BEGIN
  SELECT * INTO promo FROM public.promo_announcement WHERE id = 1;
  IF promo.event_id IS NULL AND promo.image_url IS NOT NULL AND promo.link_url IS NOT NULL THEN
    INSERT INTO public.events (title, description, image_url, link_url, starts_at, ends_at)
    VALUES (
      CASE WHEN promo.link_url ILIKE '%helalhayat2026%'
        THEN 'Helal, Temiz & Sağlıklı Hayata İlk Adım Eğitimi'
        ELSE 'Event' END,
      CASE WHEN promo.link_url ILIKE '%helalhayat2026%'
        THEN 'Online seminer serisi (Zoom), CET 19:00 — 05.12, 12.12 ve 19.12.2026. 60 dk seminer + 15 dk soru/cevap. Son oturumda HalalScan uygulaması tanıtılıyor.'
        ELSE NULL END,
      promo.image_url,
      promo.link_url,
      CASE WHEN promo.link_url ILIKE '%helalhayat2026%'
        THEN timestamptz '2026-12-05 19:00 Europe/Vienna' ELSE now() END,
      CASE WHEN promo.link_url ILIKE '%helalhayat2026%'
        THEN timestamptz '2026-12-19 19:00 Europe/Vienna' ELSE NULL END
    )
    RETURNING id INTO new_id;
    -- Same image/link → campaign_id unchanged, users who closed it stay dismissed.
    UPDATE public.promo_announcement SET event_id = new_id WHERE id = 1;
  END IF;
END;
$$;
