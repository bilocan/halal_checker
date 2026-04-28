-- Approved custom keywords (populated from suggestions via trigger)
create table if not exists keywords (
  id uuid primary key default gen_random_uuid(),
  canonical text not null unique,
  category text not null check (category in ('haram', 'suspicious')),
  reason text not null,
  variants text[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table keywords enable row level security;

-- App can read approved keywords
create policy "Anyone can read keywords"
  on keywords for select
  using (true);

-- Trigger: when a suggestion's status is set to 'approved', add it to keywords
create or replace function approve_suggestion_to_keyword()
returns trigger as $$
begin
  if new.status = 'approved' and (old.status is distinct from 'approved') then
    insert into keywords (canonical, category, reason, variants)
    values (
      new.keyword,
      new.category,
      new.reason,
      array[new.keyword]
    )
    on conflict (canonical) do nothing;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_suggestion_approved
  after update on keyword_suggestions
  for each row
  execute function approve_suggestion_to_keyword();
