#!/usr/bin/env bash
# Append a user-facing release-note bullet to release_notes/unreleased/*.md
#
# Usage:
#   ./scripts/linux/add_release_note.sh --en "Bullet text" [--de "..." --tr "..." --ar "..."]
#
# Bullets are deduplicated per file (exact line match). Text may omit the leading "- ".
set -euo pipefail

ROOT="${RELEASE_NOTES_ROOT:-release_notes/unreleased}"

normalize_bullet() {
  local text="$1"
  text="${text#"${text%%[![:space:]]*}"}"
  if [[ "$text" == "- "* ]]; then
    printf '%s\n' "$text"
  else
    printf -- '- %s\n' "$text"
  fi
}

append_bullet() {
  local file="$1"
  local bullet="$2"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if grep -qxF "$bullet" "$file" 2>/dev/null; then
    echo "Already in $(basename "$file"): $bullet"
    return 0
  fi

  printf '\n%s\n' "$bullet" >> "$file"
  echo "Added to $(basename "$file"): $bullet"
}

EN=""
DE=""
TR=""
AR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --en) EN="${2:?--en requires text}"; shift 2 ;;
    --de) DE="${2:?--de requires text}"; shift 2 ;;
    --tr) TR="${2:?--tr requires text}"; shift 2 ;;
    --ar) AR="${2:?--ar requires text}"; shift 2 ;;
    -h|--help)
      sed -n '2,6p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$EN" ]; then
  echo "Error: --en is required." >&2
  echo "Usage: $0 --en \"Bullet\" [--de \"...\" --tr \"...\" --ar \"...\"]" >&2
  exit 1
fi

append_bullet "$ROOT/en.md" "$(normalize_bullet "$EN")"
[ -n "$DE" ] && append_bullet "$ROOT/de.md" "$(normalize_bullet "$DE")"
[ -n "$TR" ] && append_bullet "$ROOT/tr.md" "$(normalize_bullet "$TR")"
[ -n "$AR" ] && append_bullet "$ROOT/ar.md" "$(normalize_bullet "$AR")"

if [ -z "$DE" ] || [ -z "$TR" ] || [ -z "$AR" ]; then
  echo "Warning: provide --de, --tr, and --ar for store-ready multilingual notes." >&2
fi
