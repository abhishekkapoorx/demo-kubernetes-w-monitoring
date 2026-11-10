#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; require_baseline redis-cart
started=$SECONDS
state_start 08-dependency-down-redis-scaled-zero deployment redis-cart
kctl scale deployment redis-cart --replicas=0 >/dev/null
wait_for "redis-cart zero endpoints" no_endpoints_seen redis-cart
summary "08-dependency-down-redis-scaled-zero: redis-cart has zero endpoints; cartservice dependency is down after $((SECONDS-started))s"