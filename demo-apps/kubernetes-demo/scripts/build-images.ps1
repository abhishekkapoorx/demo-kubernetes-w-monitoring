$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Invoke-Checked {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE"
    }
}

Invoke-Checked "docker" @("build", "-t", "kubernetes-demo/users:latest", "package\users")
Invoke-Checked "docker" @("build", "-t", "kubernetes-demo/orders:latest", "package\orders")
Invoke-Checked "docker" @("build", "-t", "kubernetes-demo/frontend:latest", "package\frontend")

Write-Host "All service images built successfully." -ForegroundColor Green
