#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; require_baseline recommendationservice
started=$SECONDS
state_start 02-oomkilled-low-memory-limit deployment recommendationservice
kctl patch deployment recommendationservice --type strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"server","resources":{"limits":{"memory":"16Mi"}}}]}}}}' >/dev/null
wait_for "recommendationservice OOMKilled" oom_seen recommendationservice
summary "02-oomkilled-low-memory-limit: recommendationservice observed OOMKilled at 16Mi after $((SECONDS-started))s"