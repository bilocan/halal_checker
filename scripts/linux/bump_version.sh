#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# bump_version.sh — bump the app version via a release branch + tag.
#
# Usage:
#   ./scripts/linux/bump_version.sh <major|minor|patch>        # auto-increment
#   ./scripts/linux/bump_version.sh 1.3.0                      # explicit version
#   ./scripts/linux/bump_version.sh --dry-run patch            # preview only
#
# What it does:
#   1. Reads the current version from pubspec.yaml
#   2. Calculates the next version (or uses the one you provided)
#   3. Increments the build number (+N) by 1
#   4. Creates a release/vX.Y.Z branch from the current branch
#   5. Updates pubspec.yaml and commits
#   6. Creates git tag vX.Y.Z
#   7. Pushes branch + tag to origin
#   8. Opens a GitHub PR (if `gh` CLI is available)
#
# The tag push triggers deploy-android.yml and deploy-ios.yml.
# Merge the PR to keep pubspec.yaml in sync on main.
# ──────────────────────────────────────────────────────────────────────
set -euo pipefail

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  shift
fi

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
  echo "  $0 <major|minor|patch>       # auto-increment"
  echo "  $0 1.3.0                     # explicit version"
  echo "  $0 --dry-run <major|minor|patch>  # preview only"
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
BRANCH="release/$TAG"

echo "New version:     $NEW_FULL"
echo "Git tag:         $TAG"
echo "Branch:          $BRANCH"
echo ""

if $DRY_RUN; then
  echo "(dry run — no changes made)"
  exit 0
fi

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

# ── Create release branch ─────────────────────────────────────────────
git checkout -b "$BRANCH"
echo "Created branch $BRANCH"

# ── Update pubspec.yaml ───────────────────────────────────────────────
sed -i "s/^version:.*/version: $NEW_FULL/" "$PUBSPEC"
echo "Updated $PUBSPEC → $NEW_FULL"

# ── Commit, tag, push ─────────────────────────────────────────────────
git add "$PUBSPEC"
git commit -m "chore: bump version to $NEW_VERSION"
git tag "$TAG"
git push origin "$BRANCH" --tags

echo ""
echo "Tag $TAG pushed — deploy workflows will start automatically."
echo ""

# ── Open PR if gh CLI is available ─────────────────────────────────────
if command -v gh &>/dev/null; then
  echo "Opening pull request..."
  gh pr create \
    --title "chore: bump version to $NEW_VERSION" \
    --body "Bumps \`pubspec.yaml\` to \`$NEW_FULL\` and tags \`$TAG\`." \
    --base main \
    --head "$BRANCH"
else
  echo "Merge the branch into main to keep pubspec.yaml in sync:"
  echo "  → https://github.com/$(git remote get-url origin | sed 's|.*github.com[:/]||;s|\.git$||')/compare/$BRANCH?expand=1"
fi
