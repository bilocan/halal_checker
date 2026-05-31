## What does this PR do?

<!-- Briefly describe the change and why it's needed. -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Keyword addition / correction
- [ ] Refactor
- [ ] Documentation

## Checklist

- [ ] `./scripts/linux/format_dart.sh --check` passes (or `.\scripts\windows\format_dart.ps1 -Check` on Windows)
- [ ] `flutter analyze` passes with no warnings
- [ ] `flutter test test/services/ test/constants/ test/models/ test/config_test.dart` passes
- [ ] Relevant tests added or updated
- [ ] UI / navigation change → ran `./run_ui_e2e_test.sh` (or N/A)
- [ ] New E2E key or SCN → updated `test/e2e_coverage.json` + `test/barcodes_e2e.txt`
- [ ] User-facing change → added a bullet to `release_notes/unreleased/en.md` (and `de.md` / `tr.md` / `ar.md` when applicable); see [release_notes/README.md](../release_notes/README.md)

## Release notes (user-facing only)

<!-- If this PR changes something users will notice, add one `- bullet` per item under
     release_notes/unreleased/ for each locale you maintain. Remove this section if N/A. -->

- [ ] N/A (internal / not user-visible)
- [ ] Updated `release_notes/unreleased/en.md`
- [ ] Updated `release_notes/unreleased/de.md`, `tr.md`, and/or `ar.md` (if applicable)

## Related issues

<!-- Closes # -->
