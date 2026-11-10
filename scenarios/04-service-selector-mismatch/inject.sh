#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; require_baseline productcatalogservice
started=$SECONDS
state_start 04-service-selector-mismatch service productcatalogservice
kctl patch service productcatalogservice --type strategic -p '{"spec":{"selector":{"app":"scenario-no-such-pod"}}}' >/dev/null
wait_for "productcatalogservice zero endpoints" no_endpoints_seen productcatalogservice
summary "04-service-selector-mismatch: productcatalogservice has zero endpoints after $((SECONDS-started))s"