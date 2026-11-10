#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; require_baseline currencyservice
started=$SECONDS
state_start 03-imagepullbackoff-bad-tag deployment currencyservice
kctl set image deployment/currencyservice server=currencyservice:scenario-nonexistent-tag-20261110 >/dev/null
wait_for "currencyservice ImagePullBackOff" image_pull_failure_seen currencyservice
summary "03-imagepullbackoff-bad-tag: currencyservice observed image pull failure after $((SECONDS-started))s"