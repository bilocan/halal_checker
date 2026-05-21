create table ai_ingredient_requests (
  id           bigint generated always as identity primary key,
  barcode      text        not null,
  product_name text,
  requested_by uuid        references auth.users(id) on delete set null,
  status       text        not null default 'pending'
               check (status in ('pending', 'approved', 'rejected')),
  created_at   timestamptz not null default now(),
  reviewed_at  timestamptz,
  reviewed_by  uuid        references auth.users(id) on delete set null
);

alter table ai_ingredient_requests enable row level security;

-- Only one pending request per barcode is needed; duplicates are harmless but
-- the app checks before submitting anyway.

create policy "Authenticated users can submit AI requests"
  on ai_ingredient_requests for insert
  to authenticated
  with check (requested_by = auth.uid());

-- Allow any authenticated user to read status for any barcode (needed to show
-- "pending" state on result screen without exposing who requested it).
create policy "Authenticated users can read AI requests"
  on ai_ingredient_requests for select
  to authenticated
  using (true);

create policy "Admins can update AI requests"
  on ai_ingredient_requests for update
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );
