#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; restore_object service productcatalogservice; clear_state 04-service-selector-mismatch
summary "04-service-selector-mismatch: reverted productcatalogservice Service"