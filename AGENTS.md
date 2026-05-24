# HalalScan — agent guide

Short checklist for Cursor/Claude agents. Full detail: [CLAUDE.md](CLAUDE.md). **Testing:** [TESTING.md](TESTING.md).

## Verify before done

```bash
dart format .
flutter analyze --no-fatal-infos
flutter test test/services/ test/constants/ test/models/ test/config_test.dart
```

## Do not break

- **Keyword safety override** after AI analysis (`product_service.dart` + `keyword_service.dart`).
- **Secrets** only via `dart_defines.json` / `lib/config.dart` — never in source.

## Where to work

| Area | Path |
|------|------|
| Lookup pipeline | `lib/services/product_service.dart` |
| Keywords | `lib/services/keyword_service.dart` |
| Edge function | `supabase/functions/lookup-product/` |
| Tests | `test/services/`, `test_data/`, [TESTING.md](TESTING.md) |

## Run app (debug)

```bash
flutter run --dart-define-from-file=dart_defines.json
```
