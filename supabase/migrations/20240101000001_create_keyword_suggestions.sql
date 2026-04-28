create table if not exists keyword_suggestions (
  id uuid primary key default gen_random_uuid(),
  keyword text not null,
  category text not null check (category in ('haram', 'suspicious')),
  reason text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  submitted_at timestamptz not null default now()
);

alter table keyword_suggestions enable row level security;

-- Anyone (including anonymous users) can insert a suggestion
create policy "Anyone can suggest keywords"
  on keyword_suggestions for insert
  with check (true);
