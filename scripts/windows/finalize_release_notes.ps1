# Move release_notes/unreleased/*.md to release_notes/<version>/ and reset unreleased/.
#
# Usage:
#   .\scripts\windows\finalize_release_notes.ps1 <version> [-DryRun]
#
# Writes the path to the English notes file to stdout when content exists.
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Version,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$Root = if ($env:RELEASE_NOTES_ROOT) { $env:RELEASE_NOTES_ROOT } else { "release_notes" }
$Unreleased = Join-Path $Root "unreleased"
$Target = Join-Path $Root $Version
$Template = Join-Path $Root "_template.md"
$Locales = @("en", "de", "tr", "ar")

function Test-ReleaseNotesContent {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    return [bool](Select-String -Path $FilePath -Pattern '^\s*-\s+' -Quiet)
}

if (-not (Test-Path $Template)) {
    Write-Error "Missing $Template"
    exit 1
}

$anyContent = $false
if (Test-Path $Unreleased) {
    foreach ($f in Get-ChildItem -Path $Unreleased -Filter "*.md" -File) {
        if (Test-ReleaseNotesContent $f.FullName) {
            $anyContent = $true
            break
        }
    }
}

if (-not $anyContent) {
    exit 0
}

$enPath = Join-Path $Unreleased "en.md"
if (-not (Test-ReleaseNotesContent $enPath)) {
    Write-Warning "Unreleased notes exist but en.md is empty; GitHub Release will use --generate-notes."
}

if ($DryRun) {
    if (Test-ReleaseNotesContent $enPath) {
        Write-Output $enPath
    }
    exit 0
}

if (Test-Path $Target) {
    Write-Error "$Target already exists."
    exit 1
}

New-Item -ItemType Directory -Path $Target -Force | Out-Null
Get-ChildItem -Path $Unreleased -Filter "*.md" -File | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $Target
}

New-Item -ItemType Directory -Path $Unreleased -Force | Out-Null
foreach ($locale in $Locales) {
    $localeTemplate = Join-Path $Root "_template.$locale.md"
    $src = if (Test-Path $localeTemplate) { $localeTemplate } else { $Template }
    Copy-Item -Path $src -Destination (Join-Path $Unreleased "$locale.md") -Force
}

$targetEn = Join-Path $Target "en.md"
if (Test-ReleaseNotesContent $targetEn) {
    Write-Output $targetEn
}
