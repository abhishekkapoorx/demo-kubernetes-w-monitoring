#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; require_baseline productcatalogservice
started=$SECONDS
state_start 05-latency-extra-latency-env deployment productcatalogservice
kctl set env deployment/productcatalogservice EXTRA_LATENCY=5s >/dev/null
wait_for "productcatalogservice rollout with EXTRA_LATENCY" deployment_available productcatalogservice
wait_for "EXTRA_LATENCY in productcatalogservice logs" latency_log_seen
summary "05-latency-extra-latency-env: productcatalogservice reports 5s extra latency after $((SECONDS-started))s"