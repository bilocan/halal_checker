# Cursor Agent UI (one-time setup)

These settings are not stored in the repo. Open **Cursor Settings** (`Ctrl+Shift+J`) → **Agent** and set:

| Setting | Value | Why |
|---------|--------|-----|
| **Include linter errors** | On | Agent sees Dart analyzer issues |
| **Auto-run mode** | Allowlist (or Allowlist with Sandbox) | Works with `~/.cursor/permissions.json` |
| **Legacy Terminal Tool** | On (if using sandbox auto-run) | Ensures allowlist is honored |

Terminal allowlist is defined in `C:\Users\Hamza\.cursor\permissions.json` (`dart`, `flutter`, `git`, `deno`).

Global engineering rules: `C:\Users\Hamza\.cursor\rules\engineering-quality.mdc`.
