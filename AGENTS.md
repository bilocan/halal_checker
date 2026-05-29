# HalalScan — agent guide

Short checklist for **Cursor and Claude Code**. Full detail: [CLAUDE.md](CLAUDE.md). **Testing:** [TESTING.md](TESTING.md).

## Definition of done (shared)

**[DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md)** is the only place to define or change done criteria (verify, release notes, commit message, task-done flow). Cursor rules and this file link there — they do not duplicate steps.

Say **task done** for the full agent flow.

## Cursor rules (pointers + file-type rules)

| Rule | Role |
|------|------|
| `agent-checklist` | Architecture, scope → DoD in `DEFINITION_OF_DONE.md` |
| `task-done` | On “task done” → execute `DEFINITION_OF_DONE.md` |
| `dart-quality` | `**/*.dart` |
| `testing` | `test/**` |
| `ui-e2e` | `lib/screens/**`, `lib/widgets/**`, `integration_test/**`, … |
| `supabase` | `supabase/**` |
| `indexing` | `@codebase` — see `.cursor/rules/indexing.mdc` |

## Do not break

- **Keyword safety override** after AI analysis (`product_service.dart` + `keyword_service.dart`).
- **Secrets** only via `dart_defines.json` / `lib/config.dart` — never in source.
- **Integration tests** use `dart_defines.integration.json` (test Supabase project), not `dart_defines.json`.

## Where to work

| Area | Path |
|------|------|
| Lookup pipeline | `lib/services/product_service.dart` |
| Keywords | `lib/services/keyword_service.dart` |
| Edge function | `supabase/functions/lookup-product/` |
| Edge verdict steps | `supabase/functions/lookup-product/VERDICT_PIPELINE.md` |
| Tests | `test/services/`, `test_data/`, [TESTING.md](TESTING.md) |
| UI E2E registry | `test/e2e_coverage.json`, `lib/integration_test_keys.dart` |
| Release notes layout | [release_notes/README.md](release_notes/README.md) |

## E2E coverage

Track **screens and flows** in [`test/e2e_coverage.json`](test/e2e_coverage.json). Human summary: [TESTING.md → UI E2E coverage](TESTING.md#ui-e2e-coverage).

After navigation, scan, or result UI changes: update registry + keys, validate, run `./run_ui_e2e_test.sh` when behavior changed — see item 6–7 in **DEFINITION_OF_DONE.md**.

## Run app (debug)

```bash
flutter run --dart-define-from-file=dart_defines.json
```
