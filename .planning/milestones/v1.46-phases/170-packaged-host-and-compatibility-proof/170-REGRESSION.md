---
phase: "170"
status: passed
source_revision: 3a908e71
files: 17
tests_passed: 202
test_exit: 0
timeout_seconds: 1800
---

# Phase 170 — Prior-phase regression gate

The 17 existing ExUnit files referenced by current-milestone phase 167, 168
and 169 verification reports ran sequentially against a fresh uniquely named
test database and writable temporary Hex home. Local BEAM was Elixir
1.20.4 / OTP 29. `mix test.setup` exited zero; the selected one-shot
`asdf exec mix test` run exited zero with **202 passed** in 123.7 seconds.

The run used GSD `run-with-timeout 1800`; no watch mode, timeout, filter skip
or failure override was used. The selector is recorded in
`.git/gsd-handoff/regression-files` for this run.

Files: integration install_admin_integration, install_generator and
install_upgrade; adoption_demo_admin_integration and adoption_demo_docker_contract;
clean_room_admin_integration and clean_room_release_source_contract;
compatibility_baseline_contract; config; install/file_transaction and
install/verify; web/admin_route_inventory, admin_route_separation and
admin_routes_compile; web/live/admin/admin_liveview_runtime_contract and
admin_route_integration; mix/tasks/lockspire_verify.

This is prior-phase regression evidence, separate from the current 96-case
packaged browser matrix, exact-floor runtime suite and historical broad run.
