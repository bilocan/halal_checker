-- Localized card title/description for blog slugs (result screen guide cards).

create table if not exists ingredient_guide_slug_metadata (
  slug            text primary key,
  title_en        text not null,
  description_en  text not null default '',
  title_de        text,
  description_de  text,
  title_tr        text,
  description_tr  text,
  updated_at      timestamptz not null default now()
);

comment on table ingredient_guide_slug_metadata is
  'Card copy for halalscan.at blog slugs. Used when slug is not in app copyBySlug.';

alter table ingredient_guide_slug_metadata enable row level security;

create policy "Anyone can read ingredient guide slug metadata"
  on ingredient_guide_slug_metadata for select
  using (true);

create policy "Admins can manage ingredient guide slug metadata"
  on ingredient_guide_slug_metadata for all
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
        and profiles.role in ('admin', 'superadmin')
    )
  )
  with check (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
        and profiles.role in ('admin', 'superadmin')
    )
  );

insert into ingredient_guide_slug_metadata (
  slug, title_en, description_en, title_de, description_de, title_tr, description_tr
) values (
  'mono-ve-digliseridler',
  'Mono and diglycerides (E471)',
  'What E471 mono- and diglycerides are, why source matters for halal, and what to check on labels.',
  'Mono- und Diglyceride (E471)',
  'Was E471 (Mono- und Diglyceride) ist, warum die Quelle für Halal wichtig ist und was Sie auf Etiketten prüfen sollten.',
  'Mono ve digliseridler (E471)',
  'E471 mono ve digliseridler nedir, helal açısından kaynak neden önemlidir ve etikette nelere bakılmalı.'
) on conflict (slug) do nothing;
