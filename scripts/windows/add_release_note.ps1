# Append a user-facing release-note bullet to release_notes/unreleased/*.md
#
# Usage:
#   .\scripts\windows\add_release_note.ps1 -En "Bullet text" [-De "..." -Tr "..." -Ar "..."]
param(
    [Parameter(Mandatory = $true)]
    [string]$En,

    [string]$De,
    [string]$Tr,
    [string]$Ar
)

$ErrorActionPreference = "Stop"

$Root = if ($env:RELEASE_NOTES_ROOT) { $env:RELEASE_NOTES_ROOT } else { "release_notes/unreleased" }

function Format-Bullet {
    param([string]$Text)
    $trimmed = $Text.TrimStart()
    if ($trimmed.StartsWith("- ")) { return $trimmed }
    return "- $trimmed"
}

function Add-BulletToFile {
    param(
        [string]$FilePath,
        [string]$Bullet
    )

    $dir = Split-Path -Parent $FilePath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    if (-not (Test-Path $FilePath)) {
        New-Item -ItemType File -Path $FilePath -Force | Out-Null
    }

    $existing = Get-Content $FilePath -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($existing -contains $Bullet) {
        Write-Host "Already in $(Split-Path -Leaf $FilePath): $Bullet"
        return
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::AppendAllText($FilePath, "`n$Bullet`n", $utf8)
    Write-Host "Added to $(Split-Path -Leaf $FilePath): $Bullet"
}

$enBullet = Format-Bullet $En
Add-BulletToFile (Join-Path $Root "en.md") $enBullet

if ($De) { Add-BulletToFile (Join-Path $Root "de.md") (Format-Bullet $De) }
if ($Tr) { Add-BulletToFile (Join-Path $Root "tr.md") (Format-Bullet $Tr) }
if ($Ar) { Add-BulletToFile (Join-Path $Root "ar.md") (Format-Bullet $Ar) }

if (-not $De -or -not $Tr -or -not $Ar) {
    Write-Warning "Provide -De, -Tr, and -Ar for store-ready multilingual notes."
}
