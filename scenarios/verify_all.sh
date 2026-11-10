#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

[[ -s "$BASELINE_DIR/deployment-frontend.yaml" ]] || die "baseline missing; run ./run.sh snapshot first"
all_deployments_available || die "cluster is not healthy before smoke test"

assert_symptom() {
  case "$1" in
    01-crashloop-missing-env) crashloop_seen checkoutservice ;;
    02-oomkilled-low-memory-limit) oom_seen recommendationservice ;;
    03-imagepullbackoff-bad-tag) image_pull_failure_seen currencyservice ;;
    04-service-selector-mismatch) no_endpoints_seen productcatalogservice ;;
    05-latency-extra-latency-env) latency_log_seen ;;
    06-readiness-probe-wrong-port) probe_not_ready_seen frontend ;;
    07-pending-unschedulable-resources) pending_seen cartservice ;;
    08-dependency-down-redis-scaled-zero) no_endpoints_seen redis-cart ;;
    *) die "no smoke assertion for $1" ;;
  esac
}

for scenario_dir in "$SCENARIOS_DIR"/[0-9][0-9]-*/; do
  scenario="$(basename "$scenario_dir")"
  started=$SECONDS
  "$SCENARIOS_DIR/run.sh" "$scenario" inject
  assert_symptom "$scenario"
  injected_seconds=$((SECONDS-started))
  "$SCENARIOS_DIR/run.sh" "$scenario" revert
  wait_for "all Boutique deployments available after $scenario" all_deployments_available
  printf '%s: PASS (inject/assert/revert %ss)\n' "$scenario" "$injected_seconds"
done

printf 'All scenarios passed.\n'