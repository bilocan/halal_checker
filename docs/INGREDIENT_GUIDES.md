# Ingredient guide links (mobile)

When a scan result flags ingredients, the app can show **Related guides** and open the matching article on [halalscan.at](https://halalscan.at) in the browser.

Full cross-project workflow (web + mobile + blog): see **`halal-checker-web/docs/ingredient-guides.md`**.

## Sources

| Source | Where | When used |
|--------|--------|-----------|
| Built-in map | `IngredientGuides.byCanonical` in Dart | Offline fallback; CI/web contract |
| DB overlay | `ingredient_guide_links` in Supabase | Loaded on lookup; admin-editable |
| Card copy | `IngredientGuides.copyBySlug` in Dart | Known slugs; unknown slugs use a generic title |

**Merge rule:** `effectiveSlugs(canonical) = dedupe(builtIn + db)` — union, not override. Built-in slugs come first.

## Files

| File | Purpose |
|------|---------|
| `lib/constants/ingredient_guides.dart` | Built-in map, card copy, runtime merge |
| `lib/services/ingredient_guide_link_service.dart` | Fetch/upsert `ingredient_guide_links` |
| `lib/services/product_service.dart` | Loads guide links with custom keywords |
| `lib/constants/site_urls.dart` | `https://halalscan.at/{locale}/blog/{slug}` |
| `supabase/migrations/20260621130000_ingredient_guide_links.sql` | Table + seed + moves off `keywords` |
| `tool/export_rules.dart` | Exports built-in `guides` to `keyword-rules.json` for web |

## Admin workflow

**Built-in tab:** tap the book icon → edit slugs for that canonical (e.g. `e471`).

**Custom tab:** edit rule as usual; guide slugs field saves to `ingredient_guide_links`, not `keywords`.

No app release needed for new or updated slugs once the migration is applied.

## Add a built-in link in code (still needed for new canonicals)

1. Blog post in **halal-checker-web** (`content/blog/<slug>.mdx`).
2. Update **`IngredientGuides.byCanonical`** and **`copyBySlug`** in Dart.
3. Mirror in **halal-checker-web** `lib/ingredient-guides.ts`.
4. Add seed row in a migration (or admin UI after deploy).
5. Re-export: `dart run tool/export_rules.dart keyword-rules.json`.

## Tests

```bash
flutter test test/constants/ingredient_guides_test.dart
flutter test test/services/ingredient_guide_link_service_test.dart
flutter test test/services/keyword_service_test.dart
```

`test/fixtures/ingredient_guides_canonical_map.json` remains the cross-project contract for the **built-in** map.
