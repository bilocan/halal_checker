-- Community keyword translations: variants on suggestions, locale map on approved rules.

alter table keyword_suggestions
  add column if not exists variants text[] not null default '{}';

alter table keywords
  add column if not exists translations jsonb not null default '{}';

comment on column keyword_suggestions.variants is
  'Optional multilingual aliases submitted with the suggestion (matching only).';

comment on column keywords.translations is
  'Locale → display/match string, e.g. {"de":"schwein","tr":"domuz"}. Merged into variants at runtime.';

-- When a suggestion is approved via status update, copy keyword + variants into keywords.
create or replace function approve_suggestion_to_keyword()
returns trigger as $$
declare
  merged_variants text[];
begin
  if new.status = 'approved' and (old.status is distinct from 'approved') then
    merged_variants := array(
      select distinct lower(trim(v))
      from unnest(
        array_append(coalesce(new.variants, '{}'), new.keyword)
      ) as v
      where trim(v) <> ''
    );
    insert into keywords (canonical, category, reason, variants)
    values (
      lower(trim(new.keyword)),
      new.category,
      new.reason,
      merged_variants
    )
    on conflict (canonical) do update
      set variants = array(
        select distinct lower(trim(v))
        from unnest(
          keywords.variants || excluded.variants
        ) as v
        where trim(v) <> ''
      );
  end if;
  return new;
end;
$$ language plpgsql security definer;
