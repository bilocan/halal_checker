# Shared bullet extraction from release_notes markdown files.
# Dot-source from prepare_store_whatsnew.ps1 and prepare_appstore_whatsnew.ps1.

function Get-ReleaseNoteCharCount {
    param([string]$Text)
    return $Text.Length
}

function Remove-ReleaseNoteBold {
    param([string]$Text)
    return $Text -replace '\*\*', ''
}

function Test-ReleaseNoteHasBullets {
    param([string]$FilePath)
    foreach ($line in (Read-Utf8Lines $FilePath)) {
        if ($line -match '^\s*-\s+') {
            return $true
        }
    }
    return $false
}

function Get-ReleaseNoteText {
    param(
        [string]$FilePath,
        [int]$Limit,
        [string]$LimitLabel = "limit"
    )

    $bullets = @()
    foreach ($line in (Read-Utf8Lines $FilePath)) {
        if ($line -match '^\s*<!--') { continue }
        if ($line -match '^\s*-->') { continue }
        if ($line -match '^\s*-\s+(.+)') {
            $content = Remove-ReleaseNoteBold $Matches[1].Trim()
            if ($content) {
                $bullets += "- $content"
            }
        }
    }

    if ($bullets.Count -eq 0) { return $null }

    $result = ""
    foreach ($bullet in $bullets) {
        $candidate = if ($result) { "$result`n$bullet" } else { $bullet }
        if ((Get-ReleaseNoteCharCount $candidate) -gt $Limit) {
            if (-not $result) {
                Write-Warning "$FilePath exceeds $LimitLabel ($Limit chars); hard-truncated first bullet."
                return $bullet.Substring(0, [Math]::Min($Limit, $bullet.Length))
            }
            Write-Warning "$FilePath exceeds $LimitLabel ($Limit chars); dropped trailing bullets."
            break
        }
        $result = $candidate
    }

    return $result
}
