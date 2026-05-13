# Scripts

Helper scripts for releasing and maintaining HalalScan. Each script has a **Linux/macOS** (bash) and **Windows** (PowerShell) version.

---

## Release: `bump_version`

Bump the app version, commit, tag, and push — triggering the store deploy workflows.

```bash
# Linux / macOS
./scripts/linux/bump_version.sh <major|minor|patch>   # auto-increment
./scripts/linux/bump_version.sh 1.3.0                 # explicit version

# Windows (PowerShell)
.\scripts\windows\bump_version.ps1 <major|minor|patch>
.\scripts\windows\bump_version.ps1 1.3.0
```

**Examples:**

| Command | Before | After |
|---------|--------|-------|
| `bump_version.sh patch` | `1.2.3+5` | `1.2.4+6` |
| `bump_version.sh minor` | `1.2.3+5` | `1.3.0+6` |
| `bump_version.sh major` | `1.2.3+5` | `2.0.0+6` |
| `bump_version.sh 3.0.0` | `1.2.3+5` | `3.0.0+6` |

**What it does:**

1. Reads the current version from `pubspec.yaml`
2. Calculates the next version (or uses the explicit one)
3. Increments the build number (`+N`) by 1
4. Updates `pubspec.yaml`
5. Commits: `chore: bump version to X.Y.Z`
6. Creates git tag `vX.Y.Z`
7. Pushes the commit and tag to origin

The tag push triggers `deploy-android.yml` and `deploy-ios.yml` automatically.

**Safety checks:** refuses to run with uncommitted changes, validates version format, checks the tag doesn't already exist, and asks for confirmation.

---

## Tagging helpers

Simple scripts for creating and pushing git tags without updating `pubspec.yaml`. Useful for quick patches where you only need a tag.

### `next-tag` — print the next patch version tag

```bash
# Linux / macOS
./scripts/linux/next-tag.sh       # prints e.g. "v1.2.4"

# Windows
.\scripts\windows\next-tag.ps1
```

Reads the latest git tag and increments the patch number by 1. Prints `v1.0.0` if no tags exist yet.

### `do-tag` — create the next patch tag locally

```bash
# Linux / macOS
./scripts/linux/do-tag.sh         # creates tag e.g. "v1.2.4"

# Windows
.\scripts\windows\do-tag.ps1
```

Calls `next-tag` internally and runs `git tag` with the result. Does **not** push.

### `push-tag` — push the latest tag to origin

```bash
# Linux / macOS
./scripts/linux/push-tag.sh       # pushes the latest tag

# Windows
.\scripts\windows\push-tag.ps1
```

Pushes the most recent tag (from `git describe --tags`) to the remote.

> **Tip:** For most releases, prefer `bump_version` over the individual tag helpers — it keeps `pubspec.yaml` in sync and does everything in one step.

---

## Other scripts

### `generate_icon.dart` — generate the app launcher icon

```bash
dart run scripts/generate_icon.dart
```

Generates the app icon assets. Uses the `flutter_launcher_icons` package configuration in `pubspec.yaml`.
