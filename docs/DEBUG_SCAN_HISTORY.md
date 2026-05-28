# Scan history diagnostics (debug branch only)

Production builds on `dev` / `main` do **not** include in-app scan-history diagnostics.
They live on branch **`debug/scan-history-diagnostics`** (commit `9c91ee4` and descendants).

## When to use

iOS scan history fails on a TestFlight device and you have no Mac/Xcode console.

## Enable on a build branch

```bash
git fetch origin
git checkout -b testflight/scan-history-debug origin/dev   # or your release branch
git cherry-pick -x 9c91ee4
# resolve conflicts if any, then build & upload TestFlight
```

`9c91ee4` adds:

- Home tab error UI (Retry, Details) when DB load fails
- About → tap installed version **5 times** → copyable diagnostics
- `ScanHistoryDiagnostics` (DB path, scan count, last error)

## After debugging

Do not merge the diagnostic commit into `dev`. Drop the cherry-pick branch or revert before release.

## Keep on `dev`

iOS DB fixes (`history_db`, WAL-safe migration, `DELETE` journal) are separate commits (`0ebd650`, follow-ups) and must stay on `dev`.

When removing diagnostics (`b8da463`), keep counting rows on the **open** DB connection in `_open()` — do not call `scanCountAtPath` while the file is already open (iOS can report 0 and skip migration). Home tab still shows Retry on load failure without the About/diagnostics UI.
