#!/usr/bin/env bash
set -euo pipefail

SCENARIOS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCENARIOS_DIR/lib/common.sh"

usage() { printf 'Usage: %s <scenario> inject|revert|status | snapshot | all-revert\n' "$0" >&2; exit 2; }

scenario_slugs=(
  01-crashloop-missing-env
  02-oomkilled-low-memory-limit
  03-imagepullbackoff-bad-tag
  04-service-selector-mismatch
  05-latency-extra-latency-env
  06-readiness-probe-wrong-port
  07-pending-unschedulable-resources
  08-dependency-down-redis-scaled-zero
)

run_scenario() {
  local scenario="$1" action="$2"
  local script="$SCENARIOS_DIR/$scenario/$action.sh"
  [[ -x "$script" ]] || die "unknown scenario or action: $scenario $action"
  "$script"
}

choose_scenario() {
  local choice
  while true; do
    printf '\nScenario to %s:\n' "$1"
    local index=1
    for scenario in "${scenario_slugs[@]}"; do
      printf '  %d) %s\n' "$index" "$scenario"
      ((index += 1))
    done
    printf '  9) all scenarios\n  b) back\n'
    read -r -p 'Enter a number: ' choice
    choice="${choice%$'\r'}"
    if [[ "$choice" == b ]]; then return 1; fi
    if [[ "$choice" =~ ^[1-8]$ ]]; then
      SELECTED_SCENARIO="${scenario_slugs[$((choice - 1))]}"
      return 0
    fi
    if [[ "$choice" == 9 ]]; then
      SELECTED_SCENARIO=all
      return 0
    fi
    printf 'Invalid choice. Enter 1-9 or b.\n'
  done
}

interactive_menu() {
  local choice
  while true; do
    printf '\nOnline Boutique scenario runner (namespace: %s)\n' "$NAMESPACE"
    printf '  1) Test one scenario\n'
    printf '  2) Test all scenarios\n'
    printf '  3) Reset one scenario\n'
    printf '  4) Reset all scenarios\n'
    printf '  5) Show active scenario status\n'
    printf '  6) Capture healthy baseline\n'
    printf '  7) Exit\n'
    read -r -p 'Choose an option: ' choice
    choice="${choice%$'\r'}"
    case "$choice" in
      1)
        if choose_scenario test; then
          if [[ "$SELECTED_SCENARIO" == all ]]; then
            bash "$SCENARIOS_DIR/verify_all.sh"
          else
            run_scenario "$SELECTED_SCENARIO" inject
          fi
        fi
        ;;
      2) bash "$SCENARIOS_DIR/verify_all.sh" ;;
      3)
        if choose_scenario reset; then
          if [[ "$SELECTED_SCENARIO" == all ]]; then
            bash "$SCENARIOS_DIR/run.sh" all-revert
          else
            run_scenario "$SELECTED_SCENARIO" revert
          fi
        fi
        ;;
      4) bash "$SCENARIOS_DIR/run.sh" all-revert ;;
      5) bash "$SCENARIOS_DIR/run.sh" status ;;
      6) snapshot_baseline ;;
      7) printf 'Goodbye.\n'; return 0 ;;
      *) printf 'Invalid choice. Enter 1-7.\n' ;;
    esac
  done
}

if [[ $# -eq 0 ]]; then interactive_menu; exit 0; fi

if [[ $# -eq 1 && $1 == snapshot ]]; then snapshot_baseline; exit 0; fi
if [[ $# -eq 1 && $1 == status ]]; then
  found=0
  for state in "$STATE_DIR"/*.json; do
    [[ -e "$state" ]] || continue
    found=1
    jq -r '"ACTIVE\t" + .scenario + "\t" + .timestamp + "\t" + ([.objects[] | .kind + "/" + .name] | join(","))' "$state"
  done
  [[ $found -eq 1 ]] || printf 'No active scenarios\n'
  exit 0
fi
if [[ $# -eq 1 && $1 == all-revert ]]; then
  for script in "$SCENARIOS_DIR"/[0-9][0-9]-*/revert.sh; do [[ -e "$script" ]] && bash "$script"; done
  exit 0
fi

[[ $# -eq 2 ]] || usage
scenario="$1"
action="$2"
run_scenario "$scenario" "$action"