# Shared Edge Function modules

## `gemini_ingredient_lookup.ts`

Single source for Gemini **web ingredient lookup** (Google Search grounding):

- Used by `lookup-product` → Flutter app (`fetchAiIngredients` / empty-OFF auto lookup)
- Used by `admin-gemini-ingredient-lookup` → web admin probe (`/admin/gemini-probe`)

**Do not** copy prompts or `generateContent` JSON elsewhere. Change this file and run:

```bash
deno test supabase/functions/_shared/
deno test --allow-env supabase/functions/lookup-product/
```

`gemini_ingredient_lookup_test.ts` asserts the request body snapshot with **no Gemini API calls** (zero tokens in CI).
