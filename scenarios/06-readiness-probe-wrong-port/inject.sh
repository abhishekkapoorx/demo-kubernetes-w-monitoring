#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; require_baseline frontend
started=$SECONDS
state_start 06-readiness-probe-wrong-port deployment frontend
kctl patch deployment frontend --type strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"server","readinessProbe":{"httpGet":{"port":18080}}}]}}}}' >/dev/null
wait_for "frontend pod not ready" probe_not_ready_seen frontend
summary "06-readiness-probe-wrong-port: frontend observed not-ready pod after $((SECONDS-started))s"