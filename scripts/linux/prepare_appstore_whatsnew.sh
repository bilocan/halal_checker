#!/usr/bin/env bash
# Local preview: write build/appstore-whatsnew/*.txt without App Store Connect API calls.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/upload_appstore_whatsnew.sh" "${1:?version required (e.g. 1.3.7)}" --dry-run
