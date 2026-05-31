# Convert release_notes/<version>/*.md to Google Play whatsnew-* files.
#
# Usage:
#   .\scripts\windows\prepare_store_whatsnew.ps1 <version>
#
# Writes to build/play-whatsnew/ and prints the directory path on success.
# Exits 0 always; warns when notes are missing.
#
# Encoding: see scripts/windows/_utf8_helpers.ps1 and release_notes/README.md.
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_utf8_helpers.ps1")
. (Join-Path $PSScriptRoot "_release_note_text.ps1")

$NotesRoot = if ($env:RELEASE_NOTES_ROOT) { $env:RELEASE_NOTES_ROOT } else { "release_notes" }
$Source = Join-Path $NotesRoot $Version
$Out = if ($env:PLAY_WHATSNEW_DIR) { $env:PLAY_WHATSNEW_DIR } else { "build/play-whatsnew" }
$Max = if ($env:PLAY_WHATSNEW_MAX) { [int]$env:PLAY_WHATSNEW_MAX } else { 500 }

$PlayLocales = [ordered]@{
    en = "en-US"
    de = "de-DE"
    tr = "tr-TR"
    ar = "ar"
}

if (-not (Test-Path $Source -PathType Container)) {
    Write-Warning "No release notes at $Source - Play What's New skipped."
    exit 0
}

if (Test-Path $Out) {
    Remove-Item -Recurse -Force $Out
}
New-Item -ItemType Directory -Path $Out -Force | Out-Null

$written = 0
foreach ($entry in $PlayLocales.GetEnumerator()) {
    $locale = $entry.Key
    $playLocale = $entry.Value
    $src = Join-Path $Source "$locale.md"
    if (-not (Test-ReleaseNoteHasBullets $src)) { continue }

    $text = Get-ReleaseNoteText -FilePath $src -Limit $Max -LimitLabel "Play limit"
    if (-not $text) { continue }

    $dest = Join-Path $Out "whatsnew-$playLocale"
    Write-Utf8Text -Path $dest -Text $text
    Write-Host "Prepared whatsnew-$playLocale from $locale.md ($((Get-ReleaseNoteCharCount $text)) chars)"
    $written++
}

if ($written -eq 0) {
    Remove-Item -Recurse -Force $Out
    Write-Warning "No Play What's New bullets for v$Version - upload continues without them."
    exit 0
}

Write-Output $Out
