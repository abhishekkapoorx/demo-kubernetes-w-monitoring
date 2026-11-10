$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

& "$PSScriptRoot\destroy.ps1"
if ($LASTEXITCODE -ne 0) {
    throw "Destroy step failed with exit code $LASTEXITCODE"
}

& "$PSScriptRoot\deploy.ps1"
if ($LASTEXITCODE -ne 0) {
    throw "Deploy step failed with exit code $LASTEXITCODE"
}

Write-Host ""
Write-Host "Reset completed successfully." -ForegroundColor Green
