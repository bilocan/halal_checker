#!/usr/bin/env bash
# Shared bullet extraction from release_notes markdown files.
# Sourced by prepare_store_whatsnew.sh and upload_appstore_whatsnew.sh.

if locale -a 2>/dev/null | grep -qxF 'C.UTF-8'; then
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8
fi

release_note_char_count() {
  printf '%s' "$1" | wc -m | tr -d '[:space:]'
}

release_note_strip_bold() {
  local text="$1"
  text="${text//\*\*/}"
  printf '%s' "$text"
}

release_note_file_has_bullets() {
  local file="$1"
  [ -f "$file" ] && grep -qE '^[[:space:]]*-[[:space:]]+' "$file"
}

# release_note_extract_text <file> <max_chars> [label]
# Prints plain text to stdout. Warnings to stderr. Exit 1 when no bullets.
release_note_extract_text() {
  local file="$1"
  local max="$2"
  local label="${3:-$file}"
  local bullets=()
  local line content

  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*\<!-- ]] && continue
    [[ "$line" =~ ^[[:space:]]*--\> ]] && continue
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+) ]]; then
      content="${BASH_REMATCH[1]}"
      content="$(release_note_strip_bold "$content")"
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
    count="$(release_note_char_count "$candidate")"
    if [ "$count" -gt "$max" ]; then
      if [ -z "$result" ]; then
        result="${line:0:$max}"
        echo "Warning: $label exceeds $max chars; hard-truncated first bullet." >&2
      else
        echo "Warning: $label exceeds $max chars; dropped trailing bullets." >&2
      fi
      break
    fi
    result="$candidate"
  done

  printf '%s' "$result"
}
