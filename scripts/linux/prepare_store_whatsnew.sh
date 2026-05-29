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
# CI uses ubuntu-latest (UTF-8). For local runs, prefer Git Bash or ensure LC_ALL=C.UTF-8.
set -euo pipefail

if locale -a 2>/dev/null | grep -qxF 'C.UTF-8'; then
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8
fi

VERSION="${1:?version required (e.g. 1.3.7)}"
NOTES_ROOT="${RELEASE_NOTES_ROOT:-release_notes}"
SOURCE="$NOTES_ROOT/$VERSION"
OUT="${PLAY_WHATSNEW_DIR:-build/play-whatsnew}"
MAX="${PLAY_WHATSNEW_MAX:-500}"

# release_notes locale file -> Play BCP 47 tag for whatsnew-<LOCALE>
declare -A PLAY_LOCALES=(
  [en]=en-US
  [de]=de-DE
  [tr]=tr-TR
  [ar]=ar
)

char_count() {
  printf '%s' "$1" | wc -m | tr -d '[:space:]'
}

strip_bold() {
  local text="$1"
  text="${text//\*\*/}"
  printf '%s' "$text"
}

file_has_bullets() {
  local file="$1"
  [ -f "$file" ] && grep -qE '^[[:space:]]*-[[:space:]]+' "$file"
}

extract_bullets() {
  local file="$1"
  local bullets=()
  local line content

  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*\<!-- ]] && continue
    [[ "$line" =~ ^[[:space:]]*--\> ]] && continue
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+) ]]; then
      content="${BASH_REMATCH[1]}"
      content="$(strip_bold "$content")"
      content="${content#"${content%%[![:space:]]*}"}"
      content="${content%"${content##*[![:space:]]}"}"
      [ -n "$content" ] && bullets+=("- $content")
    fi
  done < "$file"

  if [ "${#bullets[@]}" -eq 0 ]; then
    return 1
  fi

  local result="" candidate count
  for line in "${bullets[@]}"; do
    if [ -z "$result" ]; then
      candidate="$line"
    else
      candidate="$result"$'\n'"$line"
    fi
    count="$(char_count "$candidate")"
    if [ "$count" -gt "$MAX" ]; then
      if [ -z "$result" ]; then
        result="${line:0:$MAX}"
        echo "Warning: $file exceeds Play limit ($MAX chars); hard-truncated first bullet." >&2
      else
        echo "Warning: $file exceeds Play limit ($MAX chars); dropped trailing bullets." >&2
      fi
      break
    fi
    result="$candidate"
  done

  printf '%s' "$result"
}

if [ ! -d "$SOURCE" ]; then
  echo "Warning: no release notes at $SOURCE — Play What's New skipped." >&2
  exit 0
fi

rm -rf "$OUT"
mkdir -p "$OUT"

written=0
for locale in en de tr ar; do
  src="$SOURCE/$locale.md"
  play_locale="${PLAY_LOCALES[$locale]}"
  if ! file_has_bullets "$src"; then
    continue
  fi

  text="$(extract_bullets "$src")" || continue
  [ -z "$text" ] && continue

  printf '%s' "$text" > "$OUT/whatsnew-$play_locale"
  echo "Prepared whatsnew-$play_locale from $locale.md ($(char_count "$text") chars)"
  written=$((written + 1))
done

if [ "$written" -eq 0 ]; then
  rm -rf "$OUT"
  echo "Warning: no Play What's New bullets for v$VERSION — upload continues without them." >&2
  exit 0
fi

echo "$OUT"
