#!/usr/bin/env bash
latest=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -z "$latest" ]; then echo "v1.0.0"; exit; fi
IFS='.' read -r major minor patch <<< "${latest#v}"
echo "v$major.$minor.$((patch + 1))"
