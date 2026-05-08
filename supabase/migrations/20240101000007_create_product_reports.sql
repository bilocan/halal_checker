create table if not exists product_reports (
  id bigint generated always as identity primary key,
  barcode text not null,
  product_name text not null,
  current_result text not null,
  expected_result text not null,
  note text,
  created_at timestamptz not null default now(),
  github_issue_number int,
  github_issue_url text
);

-- Public insert (anonymous reports from app users).
alter table product_reports enable row level security;

create policy "Anyone can insert reports"
  on product_reports for insert
  with check (true);

-- Only service role can read/update (for Claude Code sessions).
create policy "Service role can read reports"
  on product_reports for select
  using (auth.role() = 'service_role');

create policy "Service role can update reports"
  on product_reports for update
  using (auth.role() = 'service_role');
