#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; restore_object deployment recommendationservice; clear_state 02-oomkilled-low-memory-limit
summary "02-oomkilled-low-memory-limit: reverted recommendationservice"