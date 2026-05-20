# Contributing Translations

Translations live in plain JSON files — no Dart knowledge needed.

## How it works

Every user-visible string in the app is stored in one file per language inside `lib/l10n/`:

| File | Language |
|---|---|
| `lib/l10n/app_en.arb` | English (reference — do not remove keys) |
| `lib/l10n/app_tr.arb` | Turkish |
| `lib/l10n/app_de.arb` | German |

ARB files are standard JSON. Each entry is a key–value pair:

```json
"scanButton": "Start Scan"
```

The key (`scanButton`) is used by the code and must never be changed. Only the value (`"Start Scan"`) is translated.

## Making a correction

1. **Fork** the repository on GitHub (button in the top-right corner of the repo page).

2. **Open the file** for the language you want to fix, for example `lib/l10n/app_tr.arb`.

3. **Find the string** — use your browser's or editor's find function (Ctrl+F / Cmd+F) to search for a word from the incorrect translation.

4. **Edit the value** on the right side of the colon. Leave the key and the surrounding punctuation exactly as they are.

5. **Commit** your change with a short message, for example: `fix(tr): correct translation for scanButton`.

6. **Open a pull request** back to this repository. In the PR description, briefly explain what was wrong and what the better wording is.

That is all. A maintainer will review, run the app in that locale to check, and merge.

## Adding a missing language

If you want to add a new language (for example French):

1. Copy `lib/l10n/app_en.arb` and rename it `lib/l10n/app_fr.arb`.
2. Change the first line:
   ```json
   "@@locale": "fr",
   ```
3. Translate every value. Keep keys, `{placeholders}`, and punctuation intact (see below).
4. Open a pull request. A maintainer will wire up the locale code in `lib/main.dart` and `l10n.yaml`.

> **Tip:** You do not have to translate everything at once. Leave untranslated strings out of the file entirely — the app automatically falls back to English for any missing key.

## Rules to follow

### Do not change keys

Keys are identifiers used in code. Changing one breaks the build.

```json
"cancel": "İptal"   ✓  key unchanged, value translated
"iptal":  "İptal"   ✗  key changed — this will break the app
```

### Keep `{placeholders}` exactly as written

Some strings contain placeholders in curly braces. These are filled in at runtime with a number or a word. Copy them verbatim into your translation, placing them where they make grammatical sense.

```json
"daysAgo": "{count} days ago"          ← English
"daysAgo": "{count} gün önce"          ← Turkish ✓  placeholder preserved
"daysAgo": "3 gün önce"                ← ✗  placeholder removed — will always show "3"
```

### Keep escaped double quotes

Some strings include quotes around a word, written as `\"word\"` in the file. These must stay escaped:

```json
"deleteRuleConfirm": "Remove \"{keyword}\" from the rules?"
```

### Do not add `@key` metadata entries

Lines that start with `"@` (like `"@daysAgo"`) are metadata for the code generator and only belong in `app_en.arb`. Do not add them to other locale files.

## Testing your changes locally

If you have Flutter installed, you can preview the app in your language:

```bash
flutter gen-l10n                              # regenerate from the ARB files
flutter run --dart-define-from-file=dart_defines.json
```

Switch the language from the app's settings screen to see your strings in context.

## Suggesting a translation via an issue

If you are not comfortable with GitHub's editing workflow, open an issue instead:

1. Go to **Issues → New issue**.
2. Use the title format: `Translation fix [language]: brief description`.
3. Paste the key name, the current (wrong) value, and your suggested replacement.

A maintainer will apply the change on your behalf and credit you in the commit message.
