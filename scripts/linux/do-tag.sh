#!/usr/bin/env bash
next=$(bash "$(dirname "$0")/next-tag.sh")
git tag "$next"
echo "Tagged $next"
