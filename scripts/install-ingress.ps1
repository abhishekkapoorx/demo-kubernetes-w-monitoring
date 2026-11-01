$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$releaseName = "ingress-nginx"
$namespace = "ingress-nginx"

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

Invoke-Checked "helm" @("repo", "add", "ingress-nginx", "https://kubernetes.github.io/ingress-nginx", "--force-update")
Invoke-Checked "helm" @("repo", "update")
Invoke-Checked "helm" @(
    "upgrade",
    "--install",
    $releaseName,
    "ingress-nginx/ingress-nginx",
    "--namespace",
    $namespace,
    "--create-namespace",
    "--set",
    "controller.service.type=ClusterIP",
    "--wait",
    "--timeout",
    "10m"
)

Write-Host "NGINX Ingress Controller installed successfully." -ForegroundColor Green
helm status $releaseName --namespace $namespace
