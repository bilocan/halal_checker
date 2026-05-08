$next = & "$PSScriptRoot\next-tag.ps1"
git tag $next
Write-Host "Tagged $next"
