-- Canonical ingredient → halalscan.at blog slug map (independent of keyword rules).

create table if not exists ingredient_guide_links (
  canonical   text primary key,
  guide_slugs text[] not null default '{}',
  updated_at  timestamptz not null default now()
);

comment on table ingredient_guide_links is
  'Blog guide slugs per ingredient canonical. Merged with app built-in map at runtime (union).';

alter table ingredient_guide_links enable row level security;

create policy "Anyone can read ingredient guide links"
  on ingredient_guide_links for select
  using (true);

create policy "Admins can manage ingredient guide links"
  on ingredient_guide_links for all
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

-- Move any slugs stored on keywords (Phase 1) before dropping the column.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'keywords'
      and column_name = 'guide_slugs'
  ) then
    insert into ingredient_guide_links (canonical, guide_slugs)
    select canonical, guide_slugs
    from keywords
    where cardinality(guide_slugs) > 0
    on conflict (canonical) do update
      set guide_slugs = (
        select coalesce(array_agg(distinct s order by s), '{}')
        from unnest(
          ingredient_guide_links.guide_slugs || excluded.guide_slugs
        ) as s
      ),
      updated_at = now();

    alter table keywords drop column guide_slugs;
  end if;
end $$;

-- Seed built-in map (matches IngredientGuides.byCanonical / web fixture).
insert into ingredient_guide_links (canonical, guide_slugs) values
  ('natural flavour', array['gida-aromalarinda-alkol']),
  ('flavouring', array['gida-aromalarinda-alkol', 'mono-propylene-glycol-halal-alternative']),
  ('e120', array['carmine-e120']),
  ('carmine', array['carmine-e120']),
  ('cochineal', array['carmine-e120']),
  ('gelatin', array['what-is-gelatin']),
  ('e441', array['what-is-gelatin']),
  ('e920', array['e-numbers-guide']),
  ('l-cysteine', array['e-numbers-guide']),
  ('e322', array['e-numbers-guide']),
  ('e471', array['e-numbers-guide']),
  ('e472', array['e-numbers-guide']),
  ('e473', array['e-numbers-guide']),
  ('e927', array['e-numbers-guide']),
  ('glycerol', array['e-numbers-guide'])
on conflict (canonical) do nothing;
