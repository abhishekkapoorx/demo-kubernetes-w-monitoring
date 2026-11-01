$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$clusterName = "dev-cluster"
$clusters = @()
try {
    $clusters = @(kind get clusters 2>$null)
} catch {
    $clusters = @()
}

if ($clusters -contains $clusterName) {
    helm uninstall monitoring --namespace monitoring --ignore-not-found
    if ($LASTEXITCODE -ne 0) {
        throw "helm failed with exit code $LASTEXITCODE"
    }

    kubectl delete -f Kubernetes --ignore-not-found
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl failed with exit code $LASTEXITCODE"
    }

    kind delete cluster --name $clusterName
    if ($LASTEXITCODE -ne 0) {
        throw "kind failed with exit code $LASTEXITCODE"
    }

    Write-Host "Cluster and Kubernetes resources deleted." -ForegroundColor Green
} else {
    Write-Host "Cluster '$clusterName' does not exist. Nothing to delete." -ForegroundColor Yellow
}
