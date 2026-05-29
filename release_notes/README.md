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

## Store metadata (manual today)

Copy from `release_notes/<version>/de.md` (etc.) into App Store Connect and Google Play Console “What’s New” fields. Deploy workflows do not upload this text yet.

## Backfill

Older versions may not have a folder here. Notes were added starting with **1.3.6**.
