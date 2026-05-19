create table ingredient_reports (
  id bigint generated always as identity primary key,
  barcode text not null,
  product_name text,
  reported_ingredients text[] not null,
  explanation text,
  status text not null default 'pending',
  user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table ingredient_reports enable row level security;

create policy "Anyone can insert ingredient reports"
  on ingredient_reports for insert
  with check (true);

create policy "Admins can read ingredient reports"
  on ingredient_reports for select
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );

create policy "Admins can update ingredient reports"
  on ingredient_reports for update
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );
