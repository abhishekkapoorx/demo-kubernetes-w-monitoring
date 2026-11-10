#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; restore_object deployment checkoutservice; clear_state 01-crashloop-missing-env
summary "01-crashloop-missing-env: reverted checkoutservice"