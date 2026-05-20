# Contributing to HalalScan

Thank you for helping make halal food verification more accessible.

## Before you start

- For bug reports and feature requests, open a GitHub issue first
- For small fixes (typos, minor bugs), a PR is fine without a prior issue
- For larger changes, discuss in an issue first to avoid wasted effort

## Setting up the development environment

### Prerequisites

- Flutter SDK (stable channel)
- A [Supabase](https://supabase.com) project with the `lookup-product` Edge Function deployed
- An [Anthropic](https://console.anthropic.com) API key set as a Supabase secret (`CLAUDE_API_KEY`)

### Local configuration

Copy the example config and fill in your own values:

```bash
cp dart_defines.example.json dart_defines.json
```

Edit `dart_defines.json` with your Supabase project credentials. This file is gitignored and must never be committed.

### Run

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## Making changes

### Tests

Run the test suite before submitting a PR:

```bash
flutter test test/services/
```

Tests cover the keyword matching engine and halal verdict logic. All PRs must pass CI (format check, lint, tests).

### Code style

- Follow standard Dart formatting: `dart format .`
- Follow Flutter lint rules: `flutter analyze`
- CI enforces both — PRs with formatting or lint failures will not be merged

### Translation contributions

To fix a translation or add a new language, see **[docs/TRANSLATING.md](docs/TRANSLATING.md)** for a step-by-step guide. No Dart knowledge required — translations are plain JSON files in `lib/l10n/`.

### Keyword contributions

To add or correct halal/haram keywords, open an issue with:
- The keyword
- Why it should be flagged (haram) or cleared (false positive)
- Sources (scholarly references or food science citations preferred)

Do not add keywords directly to the codebase without discussion — incorrect keyword additions affect every user.

## Pull request checklist

- [ ] `flutter format .` passes with no changes
- [ ] `flutter analyze` passes with no warnings
- [ ] `flutter test test/services/` passes
- [ ] PR description explains *why* the change is needed, not just what it does

## License

By contributing, you agree that your contributions will be licensed under the [GNU General Public License v3.0](LICENSE).
