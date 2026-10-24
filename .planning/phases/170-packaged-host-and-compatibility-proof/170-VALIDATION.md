---
phase: "170"
slug: "packaged-host-and-compatibility-proof"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-23"
---

# Phase 170 — Validation Strategy

The planning matrix below has execution outcomes recorded after the final local
commands. The verifier makes the independent phase-goal judgment; this file
records command results and evidence limits only.

## Test infrastructure and prerequisites

Existing ExUnit/Phoenix.LiveViewTest, Python unittest and Node built-in test runner; Chrome headless/CDP for actual browser evidence. No new library or npm/pip dependency. Use Node >=22.15 with native fetch/WebSocket and an existing Chrome binary (`CHROME_BIN` or standard macOS/Linux discovery); missing tools fail with a safe diagnostic. Use normal browser sandboxing, fresh owned profiles/ports/databases and existing CLEAN_ROOM_DB_* / LOCKSPIRE_TEST_DB_* env seams. Shared generated-host tests run sequentially. Set a dedicated fresh LOCKSPIRE_TEST_DB_NAME and run `mix test.setup` before root lifecycle tests; the wrapper owns this setup and cleanup. The exact-floor fixture uses `mix lockspire.test.setup` in its own directory and the same dedicated database.

Local BEAM command prefix for this checkout: `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1`. Use `asdf exec mix` for Mix commands; use system python3/bash/sh with those variables inherited so their Mix subprocesses select the same BEAM. Do not run `asdf exec bash/python3/sh` because those programs are not BEAM plugin executables.

## Frozen runtime matrix

| Pair | Exact Phoenix / LiveView | CI Elixir / OTP | CI PostgreSQL | Packaged mounts |
|---|---|---|---|---|
| locked | 1.8.13 / 1.2.10 | 1.19.5 / 28, existing Integration Checks | existing pinned 16 image | /lockspire; /teams/ops/identity; / |
| floor | 1.8.5 / 1.1.28 | 1.18.4 / 27, existing Minimum Supported Elixir/OTP | existing pinned 14 image | same three, sequential independent hosts |

Actual local runtime values belong in receipts and may differ from expected CI BEAM. Each cell requires the 16 `full` case IDs in Plan 02. Six browser cells produce 96 required scenario results. This is a bounded host integration check, not full protocol recertification or an unsupported-version claim.

## Canonical commands

Run from repository root. New targets below are created by their owning plans before use.

| ID | Command | Evidence / budget |
|---|---|---|
| N | `node --test test/browser/packaged_admin_proof_test.mjs` | Deterministic harness branches, expected <5s |
| P | `python3 -m unittest discover -s test/clean_room -p test_admin_journey.py` | Receipt/provenance/cleanup/failure branches, expected <5s |
| L | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair locked --receipt-dir .artifacts/phase170/final-locked` | Locked shared lifecycle + actual candidate/browser three mounts; <=900s |
| F | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair floor --receipt-dir .artifacts/phase170/final-floor` | Exact-floor shared lifecycle + actual candidate/browser three mounts; <=900s |
| S | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs` | Four original shared server test files under root locked deps; budget 60s warm |
| SF | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 sh -c 'cd compatibility/phoenix_1_8_live_view_1_1 && MIX_ENV=test mix deps.get --check-locked && MIX_ENV=test mix lockspire.test.setup && MIX_ENV=test mix test test/admin_host_runtime_test.exs'` | Same four original files loaded through exact-floor fixture; cold dependency setup separately timed |

CI calls the same wrapper with its setup-beam environment and `.artifacts/ci/host-integration/locked` or `/floor` receipt directory; it does not inherit this checkout's local ASDF override. Wrapper runs the original selectors, not a fake-tool test path. Retain existing run_test_matrix.sh protocol/lifetime partitions.

## Sampling and deadlines

- After harness/validator edits: N/P after their files exist. After host edits: focused existing clean-room tests plus the real owning journey. Every task has a concrete automated check and stated failing direction.
- Before advancing each wave: run that plan's actual browser/runtime gate; no three-task gap without checks exists (all 10 tasks have automated verification).
- Real browser/candidate builds cannot be replaced by sub-30s unit tests. These explicit tracer/final gates may exceed quick feedback latency; N/P provide fast branch feedback alongside them. Measure warm/cold times independently and retain evidence of actual behavior.
- Per-pair wrapper <=900 seconds overall, per-mount journey <=180 seconds after setup, host readiness <=30 seconds, each CDP wait <=15 seconds, cleanup escalation <=15 seconds. Timeout is failure, never skip. Use portable process timeouts, not an assumption GNU timeout exists on macOS.
- Existing CI jobs have 30-minute caps. Measure the whole job's existing partitions + new leg; insufficient headroom requires evidence-based cap/budget adjustment, never hidden skipping.
- Before phase verification: current L/F, N/P, workflow lint, `mix format --check-formatted`, `mix test.fast` and `git diff --check acda9da47b141978a2a05c2ac795058257f93888`. Re-run only checks invalidated by subsequent covered-source changes.

## Per-task verification map

| Task | Wave | Requirements | Threat refs | Secure behavior | Checks | Target status | Runtime result |
|---|---|---|---|---|---|---|---|
| 170-01-1 | 1 | HPROOF-01 | T-170-01..04 | Real package/browser join/navigation, strict cleanup/identity | New runner --scenario tracer --pair locked --mount /lockspire | Created in same tracer before invocation | passed: actual Chrome tracer; 170-01-SUMMARY.md |
| 170-01-2 | 1 | HPROOF-01 | T-170-01..04 | Failures and injected secrets cannot pass/leak | N, P, existing clean_room_admin_integration + clean_room_release_source_contract tests | New N/P tests created in this task | passed: Node 4, Python 9, clean-room contracts 7; final N/P supersede helper counts |
| 170-02-1 | 2 | HPROOF-01 | T-170-05..08 | Correct native path/navigation/reconnect | N + nested tracer | Existing by wave 1 | passed: nested tracer and route tests 24; 170-02-SUMMARY.md |
| 170-02-2 | 2 | HPROOF-01 | T-170-05..08 | Deny current-authority/cross-session paths; public routes stay public | N, P + 3 explicit locked full mount runs | Existing by wave 1; case additions owned here | passed: three mounts x 16 cases; final L refresh in 170-ACCEPTANCE.md |
| 170-03-1 | 3 | HPROOF-02 | T-170-09..11 | Shared tests really execute on exact floor | SF + no root/provider lock drift | New fixture helper/runtime entry created in same tracer | passed: exact floor 44 tests and lock checks; 170-03-SUMMARY.md |
| 170-03-2 | 3 | HPROOF-02 | T-170-09..11 | Wrong runtime/cache/provenance refuses | P, S + baseline contract + 3 explicit floor mount runs + no lock drift | Existing files with pair support added here | passed: locked selector 49, Python 18, floor three mounts x 16; final F refresh recorded |
| 170-04-1 | 4 | HPROOF-01..03 | T-170-12..15 | Required job executes exact proof, safe upload boundary | L + new workflow contract + compatibility baseline + pinned workflow lint | Wrapper/workflow test created in tracer | passed: L 143s, lifecycle 43, three mounts x 16, focused contracts 10, workflow lint |
| 170-04-2 | 4 | HPROOF-03 | T-170-12..15 | Faults/stale/missing/coerced evidence cannot seal green | P + workflow subprocess fault tests + F | Existing before invocation | passed: Python 28, focused contracts 10, F 141s and three mounts x 16 |
| 170-05-1 | 5 | HPROOF-01..03 | T-170-16..18 | Documented command and accurate evidence interpretation | L + existing documentation_contract_test | Existing before invocation | passed: locked wrapper 137s; docs contract 9 passed |
| 170-05-2 | 5 | HPROOF-01..03 | T-170-16..18 | Final matrix, honest source/evidence closure | F, N, P, format, test.fast, diff check | Existing before invocation | passed: floor 138s; Node 7; Python 28; format; mix test.fast 2027; diff check |

T-170-SC in each plan covers dependency/toolchain provenance. New runtime files are explicit plan outputs, not MISSING placeholders. No separate Wave 0 scaffold or package installation is needed; execution must create each owning test before running it, and can never count a stub/zero-test run as a pass.

## Probe and prohibition closure

Original edge-probe JSON is preserved. Two HPROOF-03 categories map to Plan 04's explicit boundary/value-type/case/identity/time-budget rejection tests. A-170-01/02 remain unclassified assumptions without an extra invented acceptance predicate. P-170-01/02 start unresolved and require individually recorded behavior + source/evidence audit closure in 170-UAT.md under VERIFICATION-POLICY.md. No missing descriptor requires human approval by itself.

## Manual-only verification

None planned. Every scoped behavior has machine evidence or a bounded source-responsibility audit. Remote execution outcomes require an actual observed run; unavailable remote results remain unavailable and are not replaced by a local pass. Publication/merge/ref updates are separate workflows.

## Planning sign-off

- [x] All 10 tasks have automated checks with observable failing directions.
- [x] Every new command target is created in its owning task or earlier dependency.
- [x] No watch mode or silent zero-test acceptance.
- [x] Fast feedback and intentional real-browser/runtime gate latency are identified.
- [x] Actual execution outcomes recorded after implementation.
- [x] Nyquist runtime compliance validated after execution.

Approval: planning self-check only, 2026-10-23; not runtime approval.

## Execution outcomes (2026-10-24)

| Check | Command / source | Result |
|---|---|---|
| Locked pair | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair locked --receipt-dir .artifacts/phase170/final-locked` | passed in 137s; 43 lifecycle tests; three mounts × 16 browser cases; receipt identity and cleanup passed |
| Floor pair | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair floor --receipt-dir .artifacts/phase170/final-floor` | passed in 138s; 44 lifecycle tests; three mounts × 16 browser cases; exact Phoenix 1.8.5 / LiveView 1.1.28 and cleanup passed |
| Documentation contract | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/documentation_contract_test.exs` | 9 passed |
| Browser harness | `node --test test/browser/packaged_admin_proof_test.mjs` | 7 passed |
| Receipt/failure suite | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 python3 -m unittest discover -s test/clean_room -p test_admin_journey.py` | 28 passed |
| Guardrail false-positive regression | `LOCKSPIRE_TEST_DB_NAME=lockspire_phase170_plan05_redaction_20261024 ... asdf exec mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs` after `mix test.setup` | 21 passed; safe `data-phx-link-state` excluded only from protocol field-name scan; raw sentinel checks retained |
| CI and documentation focused contracts | `asdf exec mix test test/lockspire/host_integration_ci_contract_test.exs test/lockspire/documentation_contract_test.exs` | 13 passed |
| Formatting | `asdf exec mix format --check-formatted` | passed after formatting the previously unformatted Plan 04 contract test as a Rule 1 fix |
| Broad suite | `LOCKSPIRE_TEST_DB_NAME=lockspire_phase170_plan05_final_20261024 HEX_HOME=/private/tmp/lockspire-phase170-hex-home ... asdf exec mix test.fast` | 2027 passed (2 properties, 2025 tests), 6 skipped, 497 excluded; exit 0 |
| Diff check | `git diff --check acda9da47b141978a2a05c2ac795058257f93888` | passed |

The local BEAM was Elixir 1.20.4 / OTP 29. This is separate from the CI
expectations of Elixir 1.19.5 / OTP 28 with PostgreSQL 16 (locked) and Elixir
1.18.4 / OTP 27 with PostgreSQL 14 (floor). No remote run was dispatched or
observed. The two otherwise unclassified probe assumptions remain so.

## Validation Audit 2026-10-24

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
