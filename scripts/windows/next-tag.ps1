$latest = git describe --tags --abbrev=0 2>$null
if (-not $latest) { Write-Host "v1.0.0"; exit }
$parts = $latest.TrimStart('v') -split '\.'
"v$($parts[0]).$($parts[1]).$([int]$parts[2] + 1)"
