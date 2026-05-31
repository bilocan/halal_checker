# Definition of done (HalalScan)

**Single source of truth** for Cursor, Claude Code, and humans. Edit **only this file** when adding or changing done criteria — `.cursor/rules/` and [AGENTS.md](AGENTS.md) link here; they do not duplicate steps.

Say **task done** (or **done** / **finish** / **complete**) to run the full flow below.

---

## Checklist (what applies when)

### Always — non-trivial code changes (items 1–3)

| # | Item | Command |
|---|------|---------|
| 1 | Dart formatted | `./scripts/linux/format_dart.sh --check` or `.\scripts\windows\format_dart.ps1 -Check` |
| 2 | Analyzer clean | `flutter analyze --no-fatal-infos` |
| 3 | CI unit tests | `flutter test test/services/ test/constants/ test/models/ test/config_test.dart` |

Quick runner for 1–3:

```bash
./scripts/linux/task_done.sh
```

```powershell
.\scripts\windows\task_done.ps1
```

Use `format_dart` script, not `dart format .` (breaks on Windows when `build/` has stale paths).

### User-visible changes (items 4–5)

| # | Item | Action |
|---|------|--------|
| 4 | Release notes | Run `add_release_note` — **en + de + tr + ar** (see [Release notes](#release-notes)) |
| 5 | PR template | Confirm release-notes checkboxes if opening a PR |

Skip 4 for internal-only work (CI, refactors, tests-only, docs-only, dependency pins).

### UI / navigation / scan / result (items 6–7)

| # | Item | Action |
|---|------|--------|
| 6 | E2E registry | Update `test/e2e_coverage.json`, `test/barcodes_e2e.txt`, `lib/integration_test_keys.dart` together |
| 7 | UI E2E | Run `./run_ui_e2e_test.sh` on device/emulator when behavior changed |

See [TESTING.md → UI E2E coverage](TESTING.md#ui-e2e-coverage).

### Supabase / edge / halal logic (items 8–9)

| # | Item | Action |
|---|------|--------|
| 8 | Verdict pipeline docs | Update `supabase/functions/lookup-product/VERDICT_PIPELINE.md` if verdict rules or step order changed |
| 9 | Keyword safety | Do not weaken keyword safety override (`product_service.dart`, `keyword_service.dart`, edge `verdictRules.ts`) |

### Before merge / release (items 10–11)

| # | Item | Action |
|---|------|--------|
| 10 | Commit | Agent **suggests** a message at task done; runs `git commit` **only** when you explicitly ask |
| 11 | Version bump | `bump_version` when shipping; unreleased notes finalize automatically ([release_notes/README.md](release_notes/README.md)) |

---

## During implementation (before “task done”)

After non-trivial code changes, run items **1–3** before claiming progress. Do not dump the full checklist on every reply.

Scope: minimal diff; never commit or push unless asked. Architecture: [CLAUDE.md](CLAUDE.md).

---

## Task done (agent flow)

**Triggers:** task done, done, finish, complete, wrap up, we're good.

Execute in order:

1. **Verify (1–3)** — run `task_done` script if code changed; skip for question-only / no-code tasks.
2. **Release notes (4)** — if user-visible: one bullet per change, then:

```powershell
.\scripts\windows\add_release_note.ps1 `
  -En "**Title** — English." `
  -De "**Titel** — Deutsch." `
  -Tr "**Başlık** — Türkçe." `
  -Ar "**العنوان** — العربية."
```

```bash
./scripts/linux/add_release_note.sh \
  --en "**Title** — English." \
  --de "**Titel** — Deutsch." \
  --tr "**Başlık** — Türkçe." \
  --ar "**العنوان** — العربية."
```

3. **Reply** — post checklist (pass / fail / skipped / N/A per applicable item). Include English release-note bullet when item 4 applied.
4. **Suggested commit** — copy-paste-ready message under `## Suggested commit` (see [Commit messages](#commit-messages)). Do not commit unless asked.
5. **Remind** — any remaining items (5–11) that apply. Offer to commit if 1–3 passed.
6. **Do not** claim complete if 1–3 failed unless failures are reported clearly.

### Reply template

```markdown
## Definition of done

| # | Item | Status |
|---|------|--------|
| 1 | Format | … |
| 2 | Analyze | … |
| 3 | Unit tests | … |
| 4 | Release notes | done / N/A |
| … | (other applicable rows) | … |

## Release note
- **Title** — English bullet (if item 4)

## Suggested commit
```

(Then a fenced code block with the commit message.)

---

## Release notes

Format: `- **Short title** — one sentence.`

Files: `release_notes/unreleased/` — **en.md** (GitHub Release), **de.md**, **tr.md**, **ar.md** (stores). Layout and bump flow: [release_notes/README.md](release_notes/README.md).

Never edit frozen `release_notes/<shipped-version>/`. Script dedupes exact lines.

---

## Commit messages

```
feat: imperative summary after prefix

- Optional body bullet
```

Prefixes: `feat:`, `fix:`, `chore:`, `docs:`. Subject ≤72 chars. Include `release_notes/unreleased/` in the commit when item 4 ran.

Examples: `feat: community display names, profile role, and Android WAL fix`, `fix: native google sign in on ios block issue`, `chore: bump version to 1.3.6`.
