# Preview App Store What's New text from release_notes/<version>/ (no API upload).
#
# Usage:
#   .\scripts\windows\prepare_appstore_whatsnew.ps1 <version>
#
# Writes build/appstore-whatsnew/<locale>.txt and prints the directory path.
# Exits 0 always; warns when notes are missing.
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_utf8_helpers.ps1")
. (Join-Path $PSScriptRoot "_release_note_text.ps1")

$NotesRoot = if ($env:RELEASE_NOTES_ROOT) { $env:RELEASE_NOTES_ROOT } else { "release_notes" }
$Source = Join-Path $NotesRoot $Version
$Out = if ($env:APPSTORE_WHATSNEW_DIR) { $env:APPSTORE_WHATSNEW_DIR } else { "build/appstore-whatsnew" }
$Max = if ($env:APPSTORE_WHATSNEW_MAX) { [int]$env:APPSTORE_WHATSNEW_MAX } else { 4000 }

$AppStoreLocales = [ordered]@{
    en = "en-US"
    de = "de-DE"
    tr = "tr"
    ar = "ar-SA"
}

if (-not (Test-Path $Source -PathType Container)) {
    Write-Warning "No release notes at $Source - App Store What's New skipped."
    exit 0
}

if (Test-Path $Out) {
    Remove-Item -Recurse -Force $Out
}
New-Item -ItemType Directory -Path $Out -Force | Out-Null

$written = 0
foreach ($entry in $AppStoreLocales.GetEnumerator()) {
    $locale = $entry.Key
    $ascLocale = $entry.Value
    $src = Join-Path $Source "$locale.md"
    if (-not (Test-ReleaseNoteHasBullets $src)) { continue }

    $text = Get-ReleaseNoteText -FilePath $src -Limit $Max -LimitLabel "App Store limit"
    if (-not $text) { continue }

    $dest = Join-Path $Out "$ascLocale.txt"
    Write-Utf8Text -Path $dest -Text $text
    Write-Host "Prepared App Store $ascLocale from $locale.md ($((Get-ReleaseNoteCharCount $text)) chars)"
    $written++
}

if ($written -eq 0) {
    Remove-Item -Recurse -Force $Out
    Write-Warning "No App Store What's New bullets for v$Version - skipped."
    exit 0
}

Write-Output $Out
