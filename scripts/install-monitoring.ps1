$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$releaseName = "monitoring"
$namespace = "monitoring"
$valuesFile = "Kubernetes\monitoring\values.yaml"

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

Invoke-Checked "helm" @("repo", "add", "prometheus-community", "https://prometheus-community.github.io/helm-charts", "--force-update")
Invoke-Checked "helm" @("repo", "update")
Invoke-Checked "helm" @(
    "upgrade",
    "--install",
    $releaseName,
    "prometheus-community/kube-prometheus-stack",
    "--namespace",
    $namespace,
    "--create-namespace",
    "--values",
    $valuesFile,
    "--wait",
    "--timeout",
    "10m"
)

Write-Host "Monitoring stack installed successfully in namespace '$namespace'." -ForegroundColor Green
helm status $releaseName --namespace $namespace
