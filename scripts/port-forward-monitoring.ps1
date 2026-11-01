$ErrorActionPreference = "Stop"

$forwards = @(
    @{
        Name = "Grafana"
        Resource = "service/monitoring-grafana"
        Namespace = "monitoring"
        LocalPort = 3000
        RemotePort = 80
    },
    @{
        Name = "Prometheus"
        Resource = "service/monitoring-kube-prometheus-prometheus"
        Namespace = "monitoring"
        LocalPort = 9090
        RemotePort = 9090
    },
    @{
        Name = "Alertmanager"
        Resource = "service/monitoring-kube-prometheus-alertmanager"
        Namespace = "monitoring"
        LocalPort = 9093
        RemotePort = 9093
    },
    @{
        Name = "Frontend"
        Resource = "service/frontend"
        Namespace = "default"
        LocalPort = 8000
        RemotePort = 8000
    },
    @{
        Name = "Users"
        Resource = "service/users"
        Namespace = "default"
        LocalPort = 8001
        RemotePort = 8000
    },
    @{
        Name = "Orders"
        Resource = "service/orders"
        Namespace = "default"
        LocalPort = 8002
        RemotePort = 8000
    }
)

$jobs = @()

try {
    foreach ($forward in $forwards) {
        $targetExists = $true
        try {
            & kubectl get $forward.Resource --namespace $forward.Namespace 2>$null 1>$null
            $targetExists = ($LASTEXITCODE -eq 0)
        } catch {
            $targetExists = $false
        }

        if (-not $targetExists) {
            throw "$($forward.Name) target '$($forward.Resource)' was not found in namespace '$($forward.Namespace)'. Run .\scripts\deploy.ps1 first."
        }
    }

    foreach ($forward in $forwards) {
        $job = Start-Job -Name ("port-forward-" + $forward.Name.ToLower()) -ScriptBlock {
            param($resource, $namespace, $localPort, $remotePort)
            kubectl port-forward $resource ($localPort.ToString() + ":" + $remotePort.ToString()) --namespace $namespace
        } -ArgumentList $forward.Resource, $forward.Namespace, $forward.LocalPort, $forward.RemotePort

        $jobs += $job
    }

    Start-Sleep -Seconds 2

    foreach ($forward in $forwards) {
        $jobName = "port-forward-" + $forward.Name.ToLower()
        $job = Get-Job -Name $jobName
        if ($job.State -eq "Failed" -or $job.State -eq "Stopped") {
            $errorOutput = Receive-Job -Job $job -ErrorAction SilentlyContinue | Out-String
            throw "$($forward.Name) port-forward failed: $errorOutput"
        }
    }

    Write-Host "Monitoring and application port-forwards are running:" -ForegroundColor Green
    Write-Host "  Grafana:     http://localhost:3000"
    Write-Host "  Prometheus:  http://localhost:9090"
    Write-Host "  Alertmanager: http://localhost:9093"
    Write-Host "  Frontend:    http://localhost:8000"
    Write-Host "  Users API:   http://localhost:8001"
    Write-Host "  Orders API:  http://localhost:8002"
    Write-Host ""
    Write-Host "Press Ctrl+C to stop all port-forwards." -ForegroundColor Yellow

    while ($true) {
        foreach ($job in $jobs) {
            $output = Receive-Job -Job $job -ErrorAction SilentlyContinue
            if ($output) {
                Write-Host $output
            }

            $currentJob = Get-Job -Id $job.Id
            if ($currentJob.State -eq "Failed" -or $currentJob.State -eq "Stopped") {
                $errorOutput = Receive-Job -Job $currentJob -ErrorAction SilentlyContinue | Out-String
                throw "A monitoring port-forward stopped unexpectedly: $($job.Name). $errorOutput"
            }
        }

        Start-Sleep -Seconds 1
    }
} finally {
    foreach ($job in $jobs) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Monitoring port-forwards stopped." -ForegroundColor Yellow
}
