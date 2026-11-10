.PHONY: scenario-snapshot scenario-inject scenario-revert scenario-status scenario-reset-all

scenario-snapshot:
	./scenarios/run.sh snapshot

scenario-inject:
	test -n "$(S)"
	./scenarios/run.sh $(S) inject

scenario-revert:
	test -n "$(S)"
	./scenarios/run.sh $(S) revert

scenario-status:
	./scenarios/run.sh status

scenario-reset-all:
	./scenarios/run.sh all-revert