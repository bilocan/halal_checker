#!/usr/bin/env bash
# Move release_notes/unreleased/*.md to release_notes/<version>/ and reset unreleased/.
#
# Usage:
#   ./scripts/linux/finalize_release_notes.sh <version> [--dry-run]
#
# Prints the path to the English notes file when content exists, otherwise nothing.
# Exit 0 always (callers decide fallback).
set -euo pipefail

VERSION="${1:?version required (e.g. 1.3.7)}"
DRY_RUN=false
if [ "${2:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

ROOT="${RELEASE_NOTES_ROOT:-release_notes}"
UNRELEASED="$ROOT/unreleased"
TARGET="$ROOT/$VERSION"
TEMPLATE="$ROOT/_template.md"
LOCALES=(en de tr ar)

if [ ! -f "$TEMPLATE" ]; then
  echo "Error: missing $TEMPLATE" >&2
  exit 1
fi

file_has_content() {
  local file="$1"
  [ -f "$file" ] && grep -qE '^[[:space:]]*-[[:space:]]+' "$file"
}

any_content=false
if [ -d "$UNRELEASED" ]; then
  for f in "$UNRELEASED"/*.md; do
    [ -f "$f" ] || continue
    if file_has_content "$f"; then
      any_content=true
      break
    fi
  done
fi

if ! $any_content; then
  exit 0
fi

if ! file_has_content "$UNRELEASED/en.md"; then
  echo "Warning: unreleased notes exist but en.md is empty; GitHub Release will use --generate-notes." >&2
fi

if $DRY_RUN; then
  if file_has_content "$UNRELEASED/en.md"; then
    echo "$UNRELEASED/en.md"
  fi
  exit 0
fi

if [ -d "$TARGET" ]; then
  echo "Error: $TARGET already exists." >&2
  exit 1
fi

mkdir -p "$TARGET"
shopt -s nullglob
for f in "$UNRELEASED"/*.md; do
  mv "$f" "$TARGET/"
done
shopt -u nullglob

mkdir -p "$UNRELEASED"
for locale in "${LOCALES[@]}"; do
  locale_template="$ROOT/_template.$locale.md"
  if [ -f "$locale_template" ]; then
    cp "$locale_template" "$UNRELEASED/$locale.md"
  else
    cp "$TEMPLATE" "$UNRELEASED/$locale.md"
  fi
done

if [ -f "$TARGET/en.md" ]; then
  echo "$TARGET/en.md"
fi
