# Online Boutique failure scenarios

These fixtures mutate only namespaced Online Boutique objects. They require a reachable `kind-*` kubectl context, `jq`, and a baseline captured from the currently deployed Boutique release.

```bash
export NAMESPACE=boutique
./scenarios/run.sh snapshot
./scenarios/run.sh 01-crashloop-missing-env inject
./scenarios/run.sh 01-crashloop-missing-env revert
./scenarios/run.sh status
./scenarios/run.sh all-revert
```

`NAMESPACE` defaults to `boutique`. Every Kubernetes command passes the current `kind-*` context and this namespace explicitly. The static Alertmanager fixtures use `boutique`; change their labels when replaying them against another namespace.

Run `./scenarios/run.sh` without arguments for the interactive menu. It lets you choose a scenario number, test one or all scenarios, reset one or all scenarios, view active state, or capture a baseline. The numbered menu is equivalent to the command-line forms below.

| Slug | What breaks | Expected symptom | Alert name | Typical time-to-observable |
|---|---|---|---|---|
| 01-crashloop-missing-env | Removes checkoutservice product catalog address | CrashLoopBackOff and startup error | KubePodCrashLooping | 10-45s |
| 02-oomkilled-low-memory-limit | Sets recommendationservice memory limit to 16Mi | OOMKilled | KubeContainerOOMKilled | 20-90s |
| 03-imagepullbackoff-bad-tag | Uses a nonexistent currencyservice image tag | ErrImagePull/ImagePullBackOff | KubePodNotReady | 10-60s |
| 04-service-selector-mismatch | Makes productcatalogservice selector match no pods | Service has zero endpoints | ServiceNoEndpoints | 2-10s |
| 05-latency-extra-latency-env | Sets productcatalogservice EXTRA_LATENCY=5s | Log confirms injected latency | HighLatency | 15-60s |
| 06-readiness-probe-wrong-port | Changes frontend readiness port to 18080 | Frontend pod remains not Ready | KubePodNotReady | 15-60s |
| 07-pending-unschedulable-resources | Requests 1,000 CPU for cartservice replacement | Pending pod and FailedScheduling | KubeDeploymentReplicasMismatch | 5-30s |
| 08-dependency-down-redis-scaled-zero | Scales redis-cart to zero | Redis Service has zero endpoints; cart dependency fails | ServiceNoEndpoints | 2-30s |

## Baselines and reversibility

Run `snapshot` only while the namespace is healthy. It saves sanitized JSON documents with `.yaml` extensions under `baseline/`; JSON is valid YAML and avoids a YAML parser dependency. Revert scripts apply only the Deployment or Service their inject script touches, then wait for Deployment rollout completion. They clear their state file when complete.

The 16Mi limit in scenario 02 is intentionally below the checked-in 450Mi limit and is expected to make the Python process exceed its cgroup limit during startup. Verify it on the target kind node before treating it as a benchmark constant.

## Smoke test

`./scenarios/verify_all.sh` runs every scenario sequentially, records injection timing, checks its scenario-specific symptom, reverts it, and waits for every known Boutique Deployment to be fully available. It stops on the first failure and prints the measured timings collected so far.