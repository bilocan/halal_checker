# Scripts

Helper scripts for releasing and maintaining HalalScan. Each script has a **Linux/macOS** (bash) and **Windows** (PowerShell) version where it matters.

### Release-notes encoding (Windows)

| Files | Encoding |
|-------|----------|
| `release_notes/**/*.md` | UTF-8 **without BOM** |
| `scripts/windows/*.ps1` | **ASCII-only** in strings (PS 5.1 parses `.ps1` without BOM as system ANSI; UTF-8 `—` breaks scripts) |

Read/write `.md` via [`scripts/windows/_utf8_helpers.ps1`](windows/_utf8_helpers.ps1), not `Get-Content -Encoding UTF8`. Full table: [release_notes/README.md](../release_notes/README.md#encoding-required).

---

## Format Dart: `format_dart`

Format (or verify) all app and test Dart under `lib/` and `test/`. Use this instead of `dart format .`, which can fail on Windows when `build/` contains broken transform paths.

```bash
# Linux / macOS / Git Bash
./scripts/linux/format_dart.sh           # apply formatting
./scripts/linux/format_dart.sh --check   # CI check — exit 1 if not formatted

# Windows (PowerShell)
.\scripts\windows\format_dart.ps1          # apply formatting
.\scripts\windows\format_dart.ps1 -Check   # CI check
```

CI runs `bash ./scripts/linux/format_dart.sh --check` in `.github/workflows/test.yml`. Linux scripts in `scripts/linux/` are stored executable (`100755`); use `bash ./scripts/linux/…` if you see “Permission denied”.

---

## Release: `bump_version`

Bump the app version, commit, tag, and push — triggering the store deploy workflows.

```bash
# Linux / macOS
./scripts/linux/bump_version.sh <major|minor|patch>   # auto-increment
./scripts/linux/bump_version.sh 1.3.0                 # explicit version
./scripts/linux/bump_version.sh --dry-run patch       # preview only

# Windows (PowerShell)
.\scripts\windows\bump_version.ps1 <major|minor|patch>
.\scripts\windows\bump_version.ps1 1.3.0
.\scripts\windows\bump_version.ps1 -DryRun patch      # preview only
```

**Examples:**

| Command | Before | After |
|---------|--------|-------|
| `bump_version.sh patch` | `1.2.3+5` | `1.2.4+6` |
| `bump_version.sh minor` | `1.2.3+5` | `1.3.0+6` |
| `bump_version.sh major` | `1.2.3+5` | `2.0.0+6` |
| `bump_version.sh 3.0.0` | `1.2.3+5` | `3.0.0+6` |

**What it does:**

1. Reads the current version from `pubspec.yaml`
2. Calculates the next version (or uses the explicit one)
3. Increments the build number (`+N`) by 1
4. Creates a `release/vX.Y.Z` branch (works with branch protection on `main`)
5. Updates `pubspec.yaml` and commits
6. Finalizes `release_notes/unreleased/` → `release_notes/<version>/` when bullets exist (see below)
7. Creates git tag `vX.Y.Z`
8. Pushes the branch + tag to origin
9. Creates a GitHub Release using `release_notes/<version>/en.md`, or `--generate-notes` if empty
10. Opens a PR (via `gh` CLI), or prints links to do both manually

The tag push triggers `deploy-android.yml` and `deploy-ios.yml` automatically.
Merge the PR to keep `pubspec.yaml` in sync on `main`.

### Release notes (`release_notes/`)

During development, add user-facing bullets to `release_notes/unreleased/` (`en.md` required for GitHub; `de.md`, `tr.md`, `ar.md` for store copy). On bump, `finalize_release_notes` moves them to `release_notes/<version>/` and resets `unreleased/` from `_template.md`.

Full workflow: [release_notes/README.md](../release_notes/README.md).

```bash
# Preview whether unreleased notes will be picked up
./scripts/linux/bump_version.sh --dry-run patch
.\scripts\windows\bump_version.ps1 -DryRun patch
```

### TestFlight only (manual, build bump)

For iOS betas without a new marketing version or App Store gates:

1. Ensure `pubspec.yaml` has the intended version name (e.g. `1.3.3+16`).
2. **Actions** → **Deploy TestFlight (manual)** → **Run workflow** (pick your branch).
3. Each run sets the build number to **max TestFlight build for that marketing version + 1** (e.g. ASC `1.3.4 (160)` → build `161`, even if pubspec still says `+18`), updates `pubspec.yaml` (unless disabled), builds, and uploads.

Same iOS secrets as `deploy-ios.yml`. Optional input: submit external beta review after upload.

**Preview with `--dry-run`:** pass `--dry-run` (Linux) or `-DryRun` (Windows) to see what the next version would be without making any changes.

**Safety checks:** refuses to run with uncommitted changes, validates version format, checks the tag doesn't already exist, and asks for confirmation.

---

## Task done: `task_done`

When you finish a task, run the automated DoD checks and see manual reminders:

```bash
./scripts/linux/task_done.sh
```

```powershell
.\scripts\windows\task_done.ps1
```

In Cursor or Claude Code, say **task done** — full flow in [DEFINITION_OF_DONE.md](../DEFINITION_OF_DONE.md). Scripts below implement items 1–3 and release-note append (item 4).

### `add_release_note` — append unreleased bullets

See **Release notes** in [DEFINITION_OF_DONE.md](../DEFINITION_OF_DONE.md). Quick reference:

```bash
./scripts/linux/add_release_note.sh \
  --en "**Title** — English." \
  --de "**Titel** — Deutsch." \
  --tr "**Başlık** — Türkçe." \
  --ar "**العنوان** — العربية."
```

```powershell
.\scripts\windows\add_release_note.ps1 `
  -En "**Title** — English." `
  -De "**Titel** — Deutsch." `
  -Tr "**Başlık** — Türkçe." `
  -Ar "**العنوان** — العربية."
```

Dedupes exact lines. See [release_notes/README.md](../release_notes/README.md).

### Store What's New (Play + App Store)

| Script | Role |
|--------|------|
| `prepare_store_whatsnew.sh` / `.ps1` | Play: `build/play-whatsnew/whatsnew-*` (500 chars/locale) |
| `prepare_appstore_whatsnew.sh` / `.ps1` | App Store preview: `build/appstore-whatsnew/*.txt` (4000 chars/locale) |
| `upload_appstore_whatsnew.sh` | CI only: PATCH App Store Connect before Gate 1 (`deploy-ios.yml`) |

Shared extraction: `_release_note_text.sh` / `_release_note_text.ps1`. Encoding rules: [release_notes/README.md](../release_notes/README.md#encoding-required).

---

## Tagging helpers

Simple scripts for creating and pushing git tags without updating `pubspec.yaml`. Useful for quick patches where you only need a tag.

### `next-tag` — print the next patch version tag

```bash
# Linux / macOS
./scripts/linux/next-tag.sh       # prints e.g. "v1.2.4"

# Windows
.\scripts\windows\next-tag.ps1
```

Reads the latest git tag and increments the patch number by 1. Prints `v1.0.0` if no tags exist yet.

### `do-tag` — create the next patch tag locally

```bash
# Linux / macOS
./scripts/linux/do-tag.sh         # creates tag e.g. "v1.2.4"

# Windows
.\scripts\windows\do-tag.ps1
```

Calls `next-tag` internally and runs `git tag` with the result. Does **not** push.

### `push-tag` — push the latest tag to origin

```bash
# Linux / macOS
./scripts/linux/push-tag.sh       # pushes the latest tag

# Windows
.\scripts\windows\push-tag.ps1
```

Pushes the most recent tag (from `git describe --tags`) to the remote.

> **Tip:** For most releases, prefer `bump_version` over the individual tag helpers — it keeps `pubspec.yaml` in sync and does everything in one step.

---

## Other scripts

### `generate_icon.dart` — generate the app launcher icon

```bash
dart run scripts/generate_icon.dart
```

Generates the app icon assets. Uses the `flutter_launcher_icons` package configuration in `pubspec.yaml`.
