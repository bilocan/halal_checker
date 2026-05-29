#!/usr/bin/env bash
# Convert release_notes/<version>/*.md to Google Play whatsnew-* files.
#
# Usage:
#   ./scripts/linux/prepare_store_whatsnew.sh <version>
#
# Prints the output directory path on success; prints nothing when no notes exist.
# Always exits 0 so deploy pipelines can skip whatsNewDirectory without failing.
#
# Environment:
#   PLAY_WHATSNEW_DIR   output directory (default: build/play-whatsnew)
#   PLAY_WHATSNEW_MAX   max characters per locale (default: 500, Play Console limit)
#
# Encoding: release_notes/*.md must be UTF-8 without BOM (see release_notes/README.md).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_release_note_text.sh
source "$SCRIPT_DIR/_release_note_text.sh"

VERSION="${1:?version required (e.g. 1.3.7)}"
NOTES_ROOT="${RELEASE_NOTES_ROOT:-release_notes}"
SOURCE="$NOTES_ROOT/$VERSION"
OUT="${PLAY_WHATSNEW_DIR:-build/play-whatsnew}"
MAX="${PLAY_WHATSNEW_MAX:-500}"

declare -A PLAY_LOCALES=(
  [en]=en-US
  [de]=de-DE
  [tr]=tr-TR
  [ar]=ar
)

if [ ! -d "$SOURCE" ]; then
  echo "Warning: no release notes at $SOURCE - Play What's New skipped." >&2
  exit 0
fi

rm -rf "$OUT"
mkdir -p "$OUT"

written=0
for locale in en de tr ar; do
  src="$SOURCE/$locale.md"
  play_locale="${PLAY_LOCALES[$locale]}"
  if ! release_note_file_has_bullets "$src"; then
    continue
  fi

  text="$(release_note_extract_text "$src" "$MAX" "$src")" || continue
  [ -z "$text" ] && continue

  printf '%s' "$text" > "$OUT/whatsnew-$play_locale"
  echo "Prepared whatsnew-$play_locale from $locale.md ($(release_note_char_count "$text") chars)"
  written=$((written + 1))
done

if [ "$written" -eq 0 ]; then
  rm -rf "$OUT"
  echo "Warning: no Play What's New bullets for v$VERSION - upload continues without them." >&2
  exit 0
fi

echo "$OUT"
