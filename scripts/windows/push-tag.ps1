$latest = git describe --tags --abbrev=0 2>$null
if (-not $latest) { Write-Error "No tags found"; exit 1 }
git push origin $latest
Write-Host "Pushed $latest"
