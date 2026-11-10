$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$clusterName = "dev-cluster"
$images = @(
    "kubernetes-demo/users:latest",
    "kubernetes-demo/orders:latest",
    "kubernetes-demo/frontend:latest"
)

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

$clusters = @()
try {
    $clusters = @(kind get clusters 2>$null)
} catch {
    $clusters = @()
}
if ($clusters -notcontains $clusterName) {
    Invoke-Checked "kind" @("create", "cluster", "--config", "cluster-config.yaml")
}

& "$PSScriptRoot\build-images.ps1"

foreach ($image in $images) {
    Invoke-Checked "kind" @("load", "docker-image", $image, "--name", $clusterName)
}

Invoke-Checked "kubectl" @("apply", "-f", "Kubernetes\users.yaml")
Invoke-Checked "kubectl" @("apply", "-f", "Kubernetes\orders.yaml")
Invoke-Checked "kubectl" @("apply", "-f", "Kubernetes\frontend.yaml")
Invoke-Checked "kubectl" @("apply", "-f", "Kubernetes\ingress.yaml")
& "$PSScriptRoot\install-ingress.ps1"
if ($LASTEXITCODE -ne 0) {
    throw "Ingress installation failed with exit code $LASTEXITCODE"
}
& "$PSScriptRoot\install-monitoring.ps1"
if ($LASTEXITCODE -ne 0) {
    throw "Monitoring installation failed with exit code $LASTEXITCODE"
}
Invoke-Checked "kubectl" @("rollout", "status", "deployment/users", "--timeout=120s")
Invoke-Checked "kubectl" @("rollout", "status", "deployment/orders", "--timeout=120s")
Invoke-Checked "kubectl" @("rollout", "status", "deployment/frontend", "--timeout=120s")

Write-Host ""
Write-Host "Deployment completed successfully." -ForegroundColor Green
kubectl get deployments,pods,services
Write-Host ""
Write-Host "Open the frontend with: kubectl port-forward service/frontend 8000:8000" -ForegroundColor Cyan
