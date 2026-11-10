$ErrorActionPreference = "Stop"

$resource = "service/ingress-nginx-controller"
$namespace = "ingress-nginx"
$localPort = 8080
$remotePort = 80

try {
    & kubectl get $resource --namespace $namespace 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Ingress Controller service was not found. Run .\scripts\deploy.ps1 first."
    }

    Write-Host "Forwarding http://localhost:$localPort to the NGINX Ingress Controller." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Frontend:     http://localhost:$localPort/"
    Write-Host "  Users API:    http://localhost:$localPort/users"
    Write-Host "  Orders API:   http://localhost:$localPort/orders"
    Write-Host "  Grafana:      http://localhost:$localPort/grafana/"
    Write-Host "  Prometheus:   http://localhost:$localPort/prometheus/"
    Write-Host "  Alertmanager: http://localhost:$localPort/alertmanager/"
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the port-forward." -ForegroundColor Yellow

    kubectl port-forward $resource "$localPort`:$remotePort" --namespace $namespace
    if ($LASTEXITCODE -ne 0) {
        throw "Ingress port-forward failed with exit code $LASTEXITCODE"
    }
} finally {
    Write-Host "Ingress port-forward stopped." -ForegroundColor Yellow
}
