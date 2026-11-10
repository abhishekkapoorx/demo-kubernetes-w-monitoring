#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_namespace; restore_object deployment currencyservice; clear_state 03-imagepullbackoff-bad-tag
summary "03-imagepullbackoff-bad-tag: reverted currencyservice"