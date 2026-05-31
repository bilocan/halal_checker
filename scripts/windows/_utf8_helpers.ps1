# UTF-8 helpers for release-notes scripts (Windows PowerShell 5.1+).
#
# Do NOT use Get-Content -Encoding UTF8 / Set-Content -Encoding UTF8 on release_notes:
# on PS 5.1 those cmdlets use UTF-8 *with BOM* and mis-read UTF-8 *without BOM* files
# (umlauts, Turkish, Arabic, em dashes become mojibake).
#
# .ps1 scripts themselves: use ASCII-only punctuation in this repo (hyphen -, not em dash).
# PS 5.1 parses .ps1 without BOM as system ANSI; UTF-8 em dash bytes break string literals.
#
# release_notes/*.md: save as UTF-8 without BOM (Cursor/VS Code status bar -> UTF-8).

$Script:Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Read-Utf8Lines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return @()
    }

    return [System.IO.File]::ReadAllLines($Path, $Script:Utf8NoBom)
}

function Read-Utf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return ""
    }

    return [System.IO.File]::ReadAllText($Path, $Script:Utf8NoBom)
}

function Write-Utf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Text, $Script:Utf8NoBom)
}

function Append-Utf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }

    [System.IO.File]::AppendAllText($Path, $Text, $Script:Utf8NoBom)
}
