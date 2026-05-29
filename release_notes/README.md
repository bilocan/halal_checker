# Release notes

User-facing “What’s new” text for GitHub Releases and (optionally) App Store / Play Store metadata.

## Layout

```text
release_notes/
  _template.md          # en placeholder (reset after bump)
  _template.de.md       # de placeholder
  _template.tr.md       # tr placeholder
  _template.ar.md       # ar placeholder
  unreleased/           # accumulate bullets during development
    en.md
    de.md
    tr.md
    ar.md
  1.3.6/                # frozen notes for a shipped version
    en.md
    ...
```

## During development

When a PR includes **user-visible** changes, add bullets under `release_notes/unreleased/` (see item 4 in **[DEFINITION_OF_DONE.md](../DEFINITION_OF_DONE.md)**).

- **en.md** — required for GitHub Release body at bump time
- **de.md**, **tr.md**, **ar.md** — store listings

Use `-` markdown bullets. Remove HTML comment placeholders before merging.

### Encoding (required)

Two rules - do not swap them:

| Files | Encoding | Why |
|-------|----------|-----|
| **`release_notes/**/*.md`** | **UTF-8 without BOM** | Store copy, GitHub Release, Linux CI |
| **`scripts/windows/*.ps1`** | **ASCII-only** (or UTF-8 **with BOM** if you must use Unicode) | PS 5.1 reads `.ps1` without BOM as system ANSI; a UTF-8 em dash (`—`) breaks string parsing |

**Markdown (release notes)**

| Editor | Setting |
|--------|---------|
| **Cursor / VS Code** | Status bar -> **UTF-8** (not "UTF-8 with BOM") |
| **Windows Notepad** | Save as **UTF-8** |

**PowerShell scripts**

- Read/write `release_notes` via [`scripts/windows/_utf8_helpers.ps1`](../scripts/windows/_utf8_helpers.ps1) - never `Get-Content -Encoding UTF8` / `Set-Content -Encoding UTF8` on those `.md` files.
- In `.ps1` source, use `-` not `—` in strings and messages (see helpers file header).

**Linux / CI:** default UTF-8 (`ubuntu-latest`); `prepare_store_whatsnew.sh` sets `LC_ALL=C.UTF-8` when available.

If store text shows `Ã¶` or `` instead of `ö`, the `.md` file encoding is wrong. If a `.ps1` script misbehaves after adding `—` or other Unicode punctuation, save the script as UTF-8 with BOM or switch to ASCII `-`.

Agents run `add_release_note` at **task done** per `DEFINITION_OF_DONE.md`. Script details below; exact duplicate lines are skipped.

```bash
# Linux / macOS / Git Bash
./scripts/linux/add_release_note.sh \
  --en "**Title** — English." \
  --de "**Titel** — Deutsch." \
  --tr "**Başlık** — Türkçe." \
  --ar "**العنوان** — العربية."

# Windows
.\scripts\windows\add_release_note.ps1 `
  -En "**Title** — English." `
  -De "**Titel** — Deutsch." `
  -Tr "**Başlık** — Türkçe." `
  -Ar "**العنوان** — العربية."
```

## At release (`bump_version`)

`bump_version` calls `finalize_release_notes`:

1. If `unreleased/*.md` has content → moves files to `release_notes/<version>/`
2. Resets `unreleased/` from `_template.md`
3. Commits the move with the version bump
4. Creates the GitHub Release with `release_notes/<version>/en.md` (falls back to `--generate-notes` if English is empty)

```bash
./scripts/linux/bump_version.sh patch
# or
.\scripts\windows\bump_version.ps1 patch
```

Preview without changes:

```bash
./scripts/linux/bump_version.sh --dry-run patch
```

## Store metadata

### Google Play (automated)

On tag deploy, `deploy-android.yml` runs `prepare_store_whatsnew.sh` and uploads localized “What’s New” from `release_notes/<version>/` via `whatsNewDirectory`. Markdown bullets are stripped to plain text; Play’s **500 character** limit per locale is enforced (truncates with a workflow warning).

If no frozen notes exist for the tag version, the upload continues without release notes (non-breaking).

Local preview:

```bash
./scripts/linux/prepare_store_whatsnew.sh 1.3.6
# or
.\scripts\windows\prepare_store_whatsnew.ps1 1.3.6
```

Output: `build/play-whatsnew/whatsnew-de-DE`, `whatsnew-tr-TR`, `whatsnew-ar`, `whatsnew-en-US`.

### App Store Connect (automated)

On tag deploy, Gate 1 (`submit-review` in `deploy-ios.yml`) runs `upload_appstore_whatsnew.sh` before submitting for review. It PATCHes `whatsNew` on existing `appStoreVersionLocalizations` for the version in **Prepare for Submission** (`en-US`, `de-DE`, `tr`, `ar-SA`). Markdown bullets are stripped to plain text; App Store's **4000 character** limit per locale is enforced (truncates with a workflow warning).

If frozen notes or the ASC version/localization is missing, the step warns and continues (non-breaking). Screenshots and other listing metadata remain manual in App Store Connect.

Local preview:

```bash
./scripts/linux/prepare_appstore_whatsnew.sh 1.3.6
# or
.\scripts\windows\prepare_appstore_whatsnew.ps1 1.3.6
```

Output: `build/appstore-whatsnew/en-US.txt`, `de-DE.txt`, `tr.txt`, `ar-SA.txt`.

## Backfill

Older versions may not have a folder here. Notes were added starting with **1.3.6**.
