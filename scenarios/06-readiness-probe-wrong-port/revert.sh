#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; restore_object deployment frontend; clear_state 06-readiness-probe-wrong-port
summary "06-readiness-probe-wrong-port: reverted frontend"