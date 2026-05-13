# ──────────────────────────────────────────────────────────────────────
# bump_version.ps1 — bump the app version, commit, tag, and push.
#
# Usage:
#   .\scripts\windows\bump_version.ps1 <major|minor|patch>   # auto-increment
#   .\scripts\windows\bump_version.ps1 1.3.0                 # explicit version
#   .\scripts\windows\bump_version.ps1 -DryRun patch         # preview only
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
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$BumpType,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Pubspec = "pubspec.yaml"

if (-not (Test-Path $Pubspec)) {
    Write-Error "$Pubspec not found. Run this script from the project root."
    exit 1
}

# ── Parse current version ─────────────────────────────────────────────
$line = (Select-String -Path $Pubspec -Pattern '^version:' | Select-Object -First 1).Line
$current = ($line -replace 'version:\s*', '').Trim()
$versionName, $buildNumber = $current -split '\+'
$parts = $versionName -split '\.'
[int]$major = $parts[0]
[int]$minor = $parts[1]
[int]$patch = $parts[2]
[int]$build = $buildNumber

Write-Host "Current version: $versionName+$build"

# ── Determine new version ─────────────────────────────────────────────
switch ($BumpType) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
    }
    "minor" {
        $minor++
        $patch = 0
    }
    "patch" {
        $patch++
    }
    default {
        if ($BumpType -notmatch '^\d+\.\d+\.\d+$') {
            Write-Error "Invalid version '$BumpType'. Expected major.minor.patch (e.g. 1.2.3)"
            exit 1
        }
        $explicitParts = $BumpType -split '\.'
        [int]$major = $explicitParts[0]
        [int]$minor = $explicitParts[1]
        [int]$patch = $explicitParts[2]
    }
}

$newVersion = "$major.$minor.$patch"
$newBuild = $build + 1
$newFull = "$newVersion+$newBuild"
$tag = "v$newVersion"

Write-Host "New version:     $newFull"
Write-Host "Git tag:         $tag"
Write-Host ""

if ($DryRun) {
    Write-Host "(dry run - no changes made)"
    exit 0
}

# ── Check for uncommitted changes ──────────────────────────────────────
$diff = git diff --quiet HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "You have uncommitted changes. Commit or stash them first."
    exit 1
}

# ── Check tag doesn't already exist ────────────────────────────────────
git rev-parse $tag 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Error "Tag $tag already exists."
    exit 1
}

# ── Confirm ────────────────────────────────────────────────────────────
$confirm = Read-Host "Proceed? [y/N]"
if ($confirm -notin @('y', 'Y')) {
    Write-Host "Aborted."
    exit 0
}

# ── Update pubspec.yaml ───────────────────────────────────────────────
(Get-Content $Pubspec) -replace '^version:.*', "version: $newFull" | Set-Content $Pubspec
Write-Host "Updated $Pubspec -> $newFull"

# ── Commit, tag, push ─────────────────────────────────────────────────
git add $Pubspec
git commit -m "chore: bump version to $newVersion"
git tag $tag
git push origin HEAD --tags

Write-Host ""
Write-Host "Done! Tag $tag pushed - deploy workflows will start automatically."
