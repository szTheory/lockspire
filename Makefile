.PHONY: demo demo-info demo-smoke demo-logs demo-stop demo-reset demo-clean demo-clean-execute

demo:
	@scripts/demo/admin-ui up

demo-info:
	@scripts/demo/admin-ui info

demo-smoke:
	@scripts/demo/admin-ui smoke

demo-logs:
	@scripts/demo/admin-ui logs

demo-stop:
	@scripts/demo/admin-ui stop

demo-reset:
	@scripts/demo/admin-ui reset

demo-clean:
	@scripts/demo/admin-ui cleanup

demo-clean-execute:
	@scripts/demo/admin-ui cleanup --execute
