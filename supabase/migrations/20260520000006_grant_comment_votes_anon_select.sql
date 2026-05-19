-- Allow unsigned clients to read vote totals when browsing discussions.
GRANT SELECT ON TABLE public.comment_votes TO anon;
