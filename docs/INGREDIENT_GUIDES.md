# Ingredient guide links (mobile)

When a scan result flags ingredients, the app can show **Related guides** and open the matching article on [halalscan.at](https://halalscan.at) in the browser.

Full cross-project workflow (web + mobile + blog): see **`halal-checker-web/docs/ingredient-guides.md`**.

## Files

| File | Purpose |
|------|---------|
| `lib/constants/ingredient_guides.dart` | Canonical → blog slug map, localized card copy, resolver |
| `lib/constants/site_urls.dart` | `https://halalscan.at/{locale}/blog/{slug}` |
| `lib/screens/result/widgets/result_related_guides.dart` | UI on scan result + full-details sheet |
| `tool/export_rules.dart` | Adds `guides` to `keyword-rules.json` for web/Storage |

## Add a new link

1. Write the blog post in **halal-checker-web** (`content/blog/<slug>.mdx`).
2. Update **`IngredientGuides.byCanonical`** and **`IngredientGuides.copyBySlug`** in `lib/constants/ingredient_guides.dart`.
3. Mirror the same canonical keys in **halal-checker-web** `lib/ingredient-guides.ts`.
4. Run `flutter test test/constants/ingredient_guides_test.dart`.
5. Re-export rules: `dart run tool/export_rules.dart keyword-rules.json` (CI uploads to Supabase on push).

## Tests

```bash
flutter test test/constants/ingredient_guides_test.dart
```

`test/fixtures/ingredient_guides_canonical_map.json` is the cross-project contract — keep it aligned with **halal-checker-web** `lib/ingredient-guides.ts` (web CI should verify the same fixture).
