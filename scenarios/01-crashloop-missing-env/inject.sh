#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; require_baseline checkoutservice
started=$SECONDS
state_start 01-crashloop-missing-env deployment checkoutservice
kctl set env deployment/checkoutservice PRODUCT_CATALOG_SERVICE_ADDR- >/dev/null
wait_for "checkoutservice CrashLoopBackOff" crashloop_seen checkoutservice
summary "01-crashloop-missing-env: checkoutservice observed CrashLoopBackOff after $((SECONDS-started))s"