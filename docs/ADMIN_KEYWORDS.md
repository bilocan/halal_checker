# Admin guide: community keywords and translations

This document is for **admins** moderating community keyword suggestions in the HalalScan app (**Admin panel → Rules**). End users submit suggestions from **Keywords → Suggest a keyword**; approved rules are stored in Supabase and merged into the halal rules engine on every device.

For how matching works in the product, see the main [README](../README.md) sections *Custom keywords* and *Managing the Rules Engine*.

---

## Concepts

| Term | Meaning |
|------|---------|
| **Canonical** | Stable English (or E-number) identifier for one ingredient concept, e.g. `pork`, `e471`. Stored uniquely in `keywords.canonical`. |
| **Variants** | All spellings that should **match** ingredient text (any language, hyphen forms, E-number variants). Stored in `keywords.variants` (text array). |
| **Translations** | Optional locale → term map in `keywords.translations` (JSON). Used for **UI labels** on scan results and **also merged into variants** for matching. |

**One concept = one row.** Do not create separate rules for `schwein` and `domuz` if they mean the same ingredient as `pork`. Add them as variants or translations on the same canonical rule.

Supported locale codes for translations (same as built-in keywords): `en`, `de`, `tr`, `fr`, `es`, `it`, `nl`, `sr`, `hu`, `cs`.

---

## Database tables

### `keyword_suggestions` (pending)

| Column | Description |
|--------|-------------|
| `keyword` | Primary term submitted by the user |
| `category` | `haram` or `suspicious` |
| `reason` | Why it should be flagged |
| `variants` | Optional extra spellings submitted with the suggestion |
| `submitted_at` | Submission time |

### `keywords` (approved)

| Column | Description |
|--------|-------------|
| `canonical` | Unique concept id (lowercase) |
| `category` | `haram` or `suspicious` |
| `reason` | Shown in the keyword catalog and analysis |
| `variants` | Deduplicated list used for matching (includes canonical + all aliases) |
| `translations` | `{"de":"schwein","tr":"domuz"}` — locale labels + match aliases |

Migration: `supabase/migrations/20260520000008_keyword_translations.sql`.

**Guide links** are stored separately in **`ingredient_guide_links`** (not on `keywords`). See [INGREDIENT_GUIDES.md](INGREDIENT_GUIDES.md).

---

## Admin panel workflow

Open **Admin panel → Rules** (three tabs: Built-in, Custom, Suggestions).

### Reviewing suggestions

1. Open the **Suggestions** tab.
2. Each card shows the keyword, category, reason, and any **variants** the user submitted.
3. Tap **Approve** or **Reject**.

**Approve behaviour:**

- If the keyword (or a submitted variant) **already matches** an existing rule, you may see **Merge with existing rule?**
  - **Merge** — adds the new spellings to that rule’s variants (recommended).
  - **Create new rule** — only if it is genuinely a different concept.
- If the canonical already exists and matches exactly, approval **merges** variants into that row automatically.

### Creating or editing a custom rule

1. **Custom** tab → **Add rule** (or edit via ⋮ menu).
2. Fill in:
   - **Canonical** — e.g. `pork`
   - **Category** — haram or suspicious
   - **Reason** — clear, source-backed wording
   - **Variants** — comma-separated: `schwein, domuz yağı, porc, lard`
   - **Translations by locale** — one per line, e.g.:
     ```
     de: schwein
     tr: domuz
     fr: porc
     ```
   - **Related guide slugs** (optional) — saved to **`ingredient_guide_links`**, not the keyword row. Comma-separated halalscan.at slugs; merged with built-in guides (union).
3. Save. The app normalizes everything to lowercase and deduplicates.

**Built-in tab:** use the book icon on a rule to edit guide slugs for that canonical without changing matching logic.

---

## SQL examples

Add a rule with variants and translations:

```sql
insert into keywords (canonical, category, reason, variants, translations)
values (
  'pork',
  'haram',
  'Contains pork or pork-derived ingredient',
  array['pork', 'schwein', 'domuz', 'porc', 'lard'],
  '{"de":"schwein","tr":"domuz","fr":"porc"}'::jsonb
);
```

Merge aliases into an existing rule:

```sql
update keywords
set
  variants = array(
    select distinct lower(trim(v))
    from unnest(variants || array['domuz yağı', 'schmalz']) as v
    where trim(v) <> ''
  ),
  translations = translations || '{"de":"schmalz"}'::jsonb
where canonical = 'pork';
```

Find which rule already covers an alias:

```sql
select *
from keywords
where canonical = lower('domuz')
   or lower('domuz') = any(variants)
   or exists (
     select 1
     from jsonb_each_text(translations) t
     where lower(t.value) = lower('domuz')
   );
```

---

## User-facing suggestion form

From **Keywords → Suggest a keyword**, signed-in users can submit:

- Primary **keyword**
- Optional **Other languages** (comma-separated variants)
- Category and reason

Admins should still verify sources before approving. Contributors can also use the repository’s **Keyword suggestion** GitHub issue template.

---

## Matching and display in the app

1. On startup / first scan, `ProductService` loads approved `keywords` from Supabase.
2. `KeywordNormalization.mergeVariants()` builds the effective variant list: canonical + `variants` + all `translations` values.
3. `HalalRulesEngine` matches ingredient text the same way as built-in keywords.
4. `ProductService.canonicalDisplay()` uses `translations[locale]` for community rules when present, else built-in `IngredientDisplayNames`, else the canonical string.

Built-in keywords remain in `lib/constants/ingredient_keywords.dart` for offline safety; community rules require network at least once to cache.

---

## Checklist before approving

- [ ] Same concept as an existing rule? → **Merge**, do not duplicate.
- [ ] Variants cover label spellings (DE/TR/FR, E-number with/without hyphen)?
- [ ] Translations filled for locales where users expect localized chip names?
- [ ] Category correct: **haram** only when always impermissible; **suspicious** when source-dependent?
- [ ] Reason is accurate and reviewable?

---

## Related code

| Piece | Location |
|-------|----------|
| Normalization | `lib/services/keyword_normalization.dart` |
| Supabase API | `lib/services/keyword_service.dart` |
| Merge into product analysis | `lib/services/product_service.dart` |
| Admin UI | `lib/screens/rules_management_screen.dart` |
| User suggest UI | `lib/screens/keywords_screen.dart` |
