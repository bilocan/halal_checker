#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# bump_version.sh — bump the app version, commit, tag, and push.
#
# Usage:
#   ./scripts/linux/bump_version.sh <major|minor|patch>   # auto-increment
#   ./scripts/linux/bump_version.sh 1.3.0                 # explicit version
#
# What it does:
#   1. Reads the current version from pubspec.yaml
#   2. Calculates the next version (or uses the one you provided)
#   3. Increments the build number (+N) by 1
#   4. Updates pubspec.yaml
#   5. Commits: "chore: bump version to X.Y.Z"
#   6. Creates git tag vX.Y.Z
#   7. Pushes the commit and tag to origin
#      → This triggers deploy-android.yml and deploy-ios.yml
# ──────────────────────────────────────────────────────────────────────
set -euo pipefail

PUBSPEC="pubspec.yaml"

if [ ! -f "$PUBSPEC" ]; then
  echo "Error: $PUBSPEC not found. Run this script from the project root." >&2
  exit 1
fi

# ── Parse current version ─────────────────────────────────────────────
CURRENT=$(grep -E '^version:' "$PUBSPEC" | head -1 | sed 's/version:[[:space:]]*//')
VERSION_NAME="${CURRENT%%+*}"
BUILD_NUMBER="${CURRENT#*+}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NAME"

echo "Current version: $VERSION_NAME+$BUILD_NUMBER"

# ── Determine new version ─────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo ""
  echo "Usage:"
  echo "  $0 <major|minor|patch>   # auto-increment"
  echo "  $0 1.3.0                 # explicit version"
  exit 1
fi

ARG="$1"

case "$ARG" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    if ! echo "$ARG" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      echo "Error: invalid version '$ARG'. Expected major.minor.patch (e.g. 1.2.3)" >&2
      exit 1
    fi
    IFS='.' read -r MAJOR MINOR PATCH <<< "$ARG"
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
NEW_BUILD=$((BUILD_NUMBER + 1))
NEW_FULL="$NEW_VERSION+$NEW_BUILD"
TAG="v$NEW_VERSION"

echo "New version:     $NEW_FULL"
echo "Git tag:         $TAG"
echo ""

# ── Check for uncommitted changes ──────────────────────────────────────
if ! git diff --quiet HEAD 2>/dev/null; then
  echo "Error: you have uncommitted changes. Commit or stash them first." >&2
  exit 1
fi

# ── Check tag doesn't already exist ────────────────────────────────────
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Error: tag $TAG already exists." >&2
  exit 1
fi

# ── Confirm ────────────────────────────────────────────────────────────
read -rp "Proceed? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ── Update pubspec.yaml ───────────────────────────────────────────────
sed -i "s/^version:.*/version: $NEW_FULL/" "$PUBSPEC"
echo "Updated $PUBSPEC → $NEW_FULL"

# ── Commit, tag, push ─────────────────────────────────────────────────
git add "$PUBSPEC"
git commit -m "chore: bump version to $NEW_VERSION"
git tag "$TAG"
git push origin HEAD --tags

echo ""
echo "Done! Tag $TAG pushed — deploy workflows will start automatically."
