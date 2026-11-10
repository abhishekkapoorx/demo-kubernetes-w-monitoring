#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; restore_object deployment productcatalogservice; clear_state 05-latency-extra-latency-env
summary "05-latency-extra-latency-env: reverted productcatalogservice"