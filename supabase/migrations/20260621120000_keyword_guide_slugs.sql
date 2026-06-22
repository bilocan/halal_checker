-- Optional blog guide slugs per approved keyword (halalscan.at/{locale}/blog/{slug}).

alter table keywords
  add column if not exists guide_slugs text[] not null default '{}';

comment on column keywords.guide_slugs is
  'Blog post slugs on halalscan.at, e.g. {e-numbers-guide}. Merged with app built-in map at runtime.';
