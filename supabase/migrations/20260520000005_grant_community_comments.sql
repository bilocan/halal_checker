-- Explicit grants so authenticated clients can post comments (RLS still applies).
GRANT SELECT ON TABLE public.comments TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE public.comments TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.comment_votes TO authenticated;
