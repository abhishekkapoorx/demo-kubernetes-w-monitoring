#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; restore_object deployment redis-cart; clear_state 08-dependency-down-redis-scaled-zero
summary "08-dependency-down-redis-scaled-zero: reverted redis-cart"