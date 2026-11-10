#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; restore_object deployment cartservice; clear_state 07-pending-unschedulable-resources
summary "07-pending-unschedulable-resources: reverted cartservice"