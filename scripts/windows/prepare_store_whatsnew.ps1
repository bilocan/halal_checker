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

function Get-CharCount {
    param([string]$Text)
    return $Text.Length
}

function Remove-Bold {
    param([string]$Text)
    return $Text -replace '\*\*', ''
}

function Test-HasBullets {
    param([string]$FilePath)
    foreach ($line in (Read-Utf8Lines $FilePath)) {
        if ($line -match '^\s*-\s+') {
            return $true
        }
    }
    return $false
}

function Get-PlayWhatsNewText {
    param(
        [string]$FilePath,
        [int]$Limit
    )

    $bullets = @()
    foreach ($line in (Read-Utf8Lines $FilePath)) {
        if ($line -match '^\s*<!--') { continue }
        if ($line -match '^\s*-->') { continue }
        if ($line -match '^\s*-\s+(.+)') {
            $content = Remove-Bold $Matches[1].Trim()
            if ($content) {
                $bullets += "- $content"
            }
        }
    }

    if ($bullets.Count -eq 0) { return $null }

    $result = ""
    foreach ($bullet in $bullets) {
        $candidate = if ($result) { "$result`n$bullet" } else { $bullet }
        if ((Get-CharCount $candidate) -gt $Limit) {
            if (-not $result) {
                Write-Warning "$FilePath exceeds Play limit ($Limit chars); hard-truncated first bullet."
                return $bullet.Substring(0, [Math]::Min($Limit, $bullet.Length))
            }
            Write-Warning "$FilePath exceeds Play limit ($Limit chars); dropped trailing bullets."
            break
        }
        $result = $candidate
    }

    return $result
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
    if (-not (Test-HasBullets $src)) { continue }

    $text = Get-PlayWhatsNewText -FilePath $src -Limit $Max
    if (-not $text) { continue }

    $dest = Join-Path $Out "whatsnew-$playLocale"
    Write-Utf8Text -Path $dest -Text $text
    Write-Host "Prepared whatsnew-$playLocale from $locale.md ($((Get-CharCount $text)) chars)"
    $written++
}

if ($written -eq 0) {
    Remove-Item -Recurse -Force $Out
    Write-Warning "No Play What's New bullets for v$Version - upload continues without them."
    exit 0
}

Write-Output $Out
