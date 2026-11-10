# Kubernetes demo and incident scenarios

## Prerequisites

- Docker Desktop
- `kind`, `kubectl`, and Helm
- Git Bash or WSL for the scenario scripts

## Run the local demo

From the repository root in PowerShell:

```powershell
.\scripts\deploy.ps1
kubectl get pods
kubectl port-forward service/frontend 8000:8000
```

Open `http://localhost:8000` after port-forwarding.

Install the monitoring stack with:

```powershell
.\scripts\install-monitoring.ps1
```

## Run incident scenarios

The Online Boutique checkout is tracked in `demo-apps/microservices-demo`. The scenario scripts work against the namespace that contains the deployed Boutique workloads; set it explicitly before running them.

```bash
export NAMESPACE=default
./scenarios/run.sh snapshot
./scenarios/run.sh
```

The interactive menu lets you test one scenario, test all scenarios, reset scenarios, view status, or recapture the baseline. For a non-interactive smoke test:

```bash
./scenarios/verify_all.sh
```

See [scenarios/README.md](scenarios/README.md) for the scenario table and recovery details.