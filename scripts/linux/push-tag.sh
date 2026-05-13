#!/usr/bin/env bash
latest=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -z "$latest" ]; then echo "No tags found" >&2; exit 1; fi
git push origin "$latest"
echo "Pushed $latest"
