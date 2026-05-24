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
| UI E2E registry | `test/e2e_coverage.json`, `lib/integration_test_keys.dart` |

## E2E coverage

Track **screens and flows** in [`test/e2e_coverage.json`](test/e2e_coverage.json) (not Codecov — device UI E2E does not upload `lcov`). Human summary: [TESTING.md → UI E2E coverage](TESTING.md#ui-e2e-coverage).

After navigation, scan, or result UI changes:

1. Update `test/e2e_coverage.json`, `test/barcodes_e2e.txt`, and `lib/integration_test_keys.dart` together.
2. `./scripts/preview_e2e_coverage.sh` to read the registry in the terminal.
3. `./scripts/validate_e2e_coverage.sh` (also run via `flutter test test/constants/` in CI).
4. `./run_ui_e2e_test.sh` on a device/emulator when behavior changed.

## Run app (debug)

```bash
flutter run --dart-define-from-file=dart_defines.json
```
