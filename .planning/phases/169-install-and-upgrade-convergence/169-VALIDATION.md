---
phase: "169"
slug: "install-and-upgrade-convergence"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-22"
---

# Phase 169 — Validation Strategy

> Validate generated adoption, migration safety, structural diagnostics and maintained host convergence on the current locked runtime. Execution fills outcomes and source revisions; planning does not assert passing implementation tests.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Phoenix.ConnTest, Phoenix.LiveViewTest, compiled Phoenix router metadata |
| Config | `mix.exs`, `config/test.exs` |
| Runtime prefix | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec` |
| Quick routing check | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs` |
| Full regression gate | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast` |
| Format gate | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix format --check-formatted` |
| Timing | Measure focused command runtime during execution; full suite is a wave/phase gate, not the per-edit feedback loop. |

## Sampling Rate

- After each task, run its owning focused tests. Every runnable PLAN verification command must have an observable `fails_when` signal.
- After each wave, run the relevant completed-phase test union; before closure run the whole phase union, format check, `mix test.fast`, and `git diff --check`.
- Capture test counts, elapsed time, source revision, result and evidence limits. If a focused command exceeds 30 seconds, choose a meaningful smaller target for per-edit feedback and retain the full check at the task/wave gate.

## Requirement Verification Map

The planner refines this into task IDs and phase-unique threat references once plans are finalized. All entries are pending execution.

| Requirement | Secure behavior / acceptance | Type | Owning existing test files | Status |
|-------------|------------------------------|------|----------------------------|--------|
| HDX-01 | Fresh helper compiles native shared routes; unfinished HTTP and LiveView authorization deny access; endpoint/browser/session guidance is explicit; no assumed host account schema | integration / compiled routes / connected mount | `test/integration/install_generator_test.exs`, `test/lockspire/web/admin_routes_compile_test.exs`, `test/lockspire/web/admin_route_inventory_test.exs` | pending |
| HDX-02 | Legacy managed conversion; dry-run leaves bytes and manifest unchanged; repeat apply is safe; drift/collisions refuse; host policy/config bytes preserved; transaction/recovery stays intact | filesystem integration | `test/integration/install_upgrade_test.exs` | pending |
| HDX-03 | Compiled route/action/session/pipeline/hook inventory and actual first-match dispatch distinguish canonical, incomplete, shadowed and legacy hosts; sentinel secrets absent; policy-proof limit explicit | unit / Mix task / compiled routing | `test/lockspire/install/verify_test.exs`, `test/mix/tasks/lockspire_verify_test.exs` | pending |
| HDX-04 | Demo and maintained generated/clean-room hosts use reusable declarations; no duplicate inventory or masking admin forward; docs agree | source contract / compiled routing / connected lifecycle | `test/lockspire/adoption_demo_operator_guard_test.exs`, `test/lockspire/clean_room_release_source_contract_test.exs`, `test/lockspire/web/admin_route_separation_test.exs`, `test/lockspire/web/live/admin/admin_route_integration_test.exs` | pending |

Focused phase union:

```bash
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/adoption_demo_operator_guard_test.exs test/lockspire/clean_room_release_source_contract_test.exs
```

## Wave 0 Requirements

Existing infrastructure covers the phase; no new framework or dependency setup is needed. Add regression cases to the owning files as part of implementation, and keep generated host fixtures coherent with the manifest ownership model. If new test files are introduced, declare their creation before any verification command references them.

## Manual-Only Verifications

None planned. Follow `.planning/VERIFICATION-POLICY.md`: close routine acceptance and prohibitions with executable evidence and a durable closure ledger. A missing descriptor is a planning defect with an explicit closure rule, not an automatic human checkpoint. No UI copy overhaul or manual signoff is in scope.

Phase 170 owns packaged candidate adoption, real browser/socket transport and exact minimum dependency runtime proof. Current repository compile, connected LiveViewTest and source-contract checks establish only their stated properties.

## Validation Sign-Off

- [ ] Final task IDs, threat references and verification commands mapped after planning.
- [ ] Every task has automated verification; no three consecutive tasks without it.
- [ ] New test references have creation dependencies; no watch-mode commands.
- [ ] Focused check timings measured and acceptable for per-edit feedback.
- [ ] Execution outcomes, source revision and scope limits recorded.
- [ ] `nyquist_compliant: true` set only when validated by the applicable workflow.

**Approval:** pending automated validation; no separate human UAT requested.
