#!/usr/bin/env bash
set -euo pipefail

SCENARIOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-boutique}"
STATE_DIR="$SCENARIOS_DIR/.state"
BASELINE_DIR="$SCENARIOS_DIR/baseline"
TIMEOUT_SECONDS="${SCENARIO_TIMEOUT_SECONDS:-180}"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || die "kubectl is required"
KUBE_CONTEXT="$(kubectl config current-context 2>/dev/null || true)"
[[ "$KUBE_CONTEXT" == kind-* ]] || die "refusing to run: current kubectl context must start with kind- (found: ${KUBE_CONTEXT:-none})"
command -v jq >/dev/null 2>&1 || die "jq is required for baseline sanitization and state files"
mkdir -p "$STATE_DIR" "$BASELINE_DIR"

kctl() { kubectl --context "$KUBE_CONTEXT" -n "$NAMESPACE" "$@"; }
require_namespace() { kctl get namespace "$NAMESPACE" >/dev/null; }

workloads=(adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice redis-cart)
services=(adservice cartservice checkoutservice currencyservice emailservice frontend frontend-external paymentservice productcatalogservice recommendationservice shippingservice redis-cart)

state_start() {
  local scenario="$1"; shift
  local objects='[]' kind_name object_name
  while (($#)); do
    kind_name="$1"; object_name="$2"; shift 2
    objects="$(jq --arg kind "$kind_name" --arg name "$object_name" --arg namespace "$NAMESPACE" '. + [{kind:$kind,name:$name,namespace:$namespace}]' <<<"$objects")"
  done
  jq -n --arg scenario "$scenario" --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg namespace "$NAMESPACE" --argjson objects "$objects" \
    '{scenario:$scenario,timestamp:$timestamp,namespace:$namespace,objects:$objects}' \
    > "$STATE_DIR/$scenario.json"
}

clear_state() { rm -f "$STATE_DIR/$1.json"; }

snapshot_object() {
  local kind="$1" name="$2"
  kctl get "$kind" "$name" -o json \
    | jq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.managedFields,.metadata.creationTimestamp,.metadata.generation,.status)' \
    > "$BASELINE_DIR/${kind}-${name}.yaml"
}

snapshot_baseline() {
  require_namespace
  rm -f "$BASELINE_DIR"/*.yaml
  local name
  for name in "${workloads[@]}"; do
    kctl get deployment "$name" >/dev/null 2>&1 && snapshot_object deployment "$name"
  done
  for name in "${services[@]}"; do
    kctl get service "$name" >/dev/null 2>&1 && snapshot_object service "$name"
  done
  printf 'Baseline saved for namespace %s in %s\n' "$NAMESPACE" "$BASELINE_DIR"
}

require_baseline() { [[ -s "$BASELINE_DIR/deployment-$1.yaml" ]] || die "missing baseline; run ./run.sh snapshot first"; }

restore_object() {
  local kind="$1" name="$2"
  if [[ "$kind" == deployment ]]; then require_baseline "$name"; else [[ -s "$BASELINE_DIR/service-$name.yaml" ]] || die "missing baseline; run ./run.sh snapshot first"; fi
  kctl apply -f "$BASELINE_DIR/${kind}-${name}.yaml" >/dev/null
  [[ "$kind" != deployment ]] || kctl rollout status "deployment/$name" --timeout=120s >/dev/null
}

wait_for() {
  local description="$1"; shift
  local deadline=$((SECONDS + TIMEOUT_SECONDS))
  while ((SECONDS < deadline)); do
    if "$@"; then return 0; fi
    sleep 2
  done
  die "timed out waiting for $description (${TIMEOUT_SECONDS}s)"
}

pod_json() { kctl get pods -l "app=$1" -o json; }
crashloop_seen() { pod_json "$1" | jq -e '[.items[].status.containerStatuses[]? | (.state.waiting.reason // .lastState.terminated.reason)] | any(. == "CrashLoopBackOff")' >/dev/null; }
oom_seen() { pod_json "$1" | jq -e '[.items[].status.containerStatuses[]?.lastState.terminated.reason] | any(. == "OOMKilled")' >/dev/null; }
pending_seen() { pod_json "$1" | jq -e '[.items[].status.phase] | any(. == "Pending")' >/dev/null; }
probe_not_ready_seen() { pod_json "$1" | jq -e '[.items[].status.containerStatuses[]?.ready] | any(. == false)' >/dev/null; }
image_pull_failure_seen() { pod_json "$1" | jq -e '[.items[].status.containerStatuses[]?.state.waiting.reason] | any(. == "ImagePullBackOff" or . == "ErrImagePull")' >/dev/null; }
latency_log_seen() { kctl logs -l app=productcatalogservice --tail=100 2>/dev/null | grep -q 'extra latency enabled'; }
no_endpoints_seen() { kctl get endpoints "$1" -o json 2>/dev/null | jq -e '((.subsets // []) | length) == 0' >/dev/null; }
deployment_available() { kctl get deployment "$1" -o json | jq -e '.status.availableReplicas == .spec.replicas and (.status.availableReplicas // 0) > 0' >/dev/null; }
all_deployments_available() {
  local name
  for name in "${workloads[@]}"; do
    [[ -s "$BASELINE_DIR/deployment-$name.yaml" ]] || continue
    deployment_available "$name" || return 1
  done
}
summary() { printf '%s\n' "$*"; }