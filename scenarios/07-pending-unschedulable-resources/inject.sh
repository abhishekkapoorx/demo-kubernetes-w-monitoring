#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; require_baseline cartservice
started=$SECONDS
state_start 07-pending-unschedulable-resources deployment cartservice
kctl patch deployment cartservice --type strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"server","resources":{"requests":{"cpu":"1000"}}}]}}}}' >/dev/null
wait_for "cartservice Pending pod" pending_seen cartservice
summary "07-pending-unschedulable-resources: cartservice has a Pending replacement after $((SECONDS-started))s"