---
phase: "178"
slug: "packaged-upgrade-proof-delivery-handoff"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-26"
---

# Phase 178 — Validation Strategy

> Draft execution sampling contract. Planning checks are not executed package proof.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit plus Python standard-library unittest acceptance contracts |
| Config | `mix.exs`, `config/test.exs`, host/template dependency locks |
| Existing fast baseline | `python3 -m unittest discover -s test/acceptance -p '*test.py'` |
| Focused source regression | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_concurrency_test.exs` |
| Full contributor gate | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix ci` |
| Package gate | New verifier runner/strict receipt aggregate: four core pair/store cells, delegated faults on both pairs, five-endpoint breadth per pair, separate pinned-public control, locked running-release RPC |
| Runtime | Measure changed helper tests and installed cells; no unobserved latency guarantee |

## Sampling Rate

- After each task commit, run changed helper/receipt/adapter tests and the affected installed scenario when available.
- After each wave, run its applicable package cells; before goal verification, all required cells and final contributor/candidate gates must have executed successfully at recorded identities.
- Preserve complete failed attempts and explicit unavailable/blocking dispositions. No watch mode, structural-check substitution or omitted-case passing skip.
- Target fast feedback within 60 seconds for helper/receipt checks; measure full package/CI runtime and retain existing bounded workflow timeouts unless evidence warrants an explicit revision.

## Per-Task Verification Map

Every row names actual planned task/wave/threats. Command IDs resolve verbatim below. Creation ownership is explicit; a future path is not runnable until its owner commits it. Planning does not certify runtime or hosted outcomes.

| Task | Wave | Requirement | Threat refs | Automated commands | Command creation dependency | State |
|------|------|-------------|-------------|--------------------|-----------------------------|-------|
| 178-01-01 | 1 | VPROOF-02 | T-178-01, T-178-02, T-178-03 | A01, A02 | 178-01-01 | Planned; no execution |
| 178-01-02 | 1 | VPROOF-02 | T-178-01, T-178-02, T-178-03 | A03, A04 | 178-01-01 | Planned; no execution |
| 178-02-01 | 2 | VPROOF-02 | T-178-04, T-178-05, T-178-06 | A05, A06 | 178-01-01; own 178-02-01 | Planned; no execution |
| 178-02-02 | 2 | VPROOF-02 | T-178-04, T-178-05, T-178-06 | A05, A07, A08 | 178-01-01; own 178-02-01 | Planned; no execution |
| 178-03-01 | 3 | VPROOF-02 | T-178-07, T-178-08, T-178-09 | A09, A10 | 178-01-01/178-02-01; own 178-03-01 | Planned; no execution |
| 178-03-02 | 3 | VPROOF-02 | T-178-07, T-178-08, T-178-09 | A09, A11 | 178-01-01/178-02-01; own 178-03-01 | Planned; no execution |
| 178-04-01 | 3 | VPROOF-02 | T-178-10, T-178-11, T-178-12 | A12, A13 | 178-01-01/178-02-01; own 178-04-01 | Planned; no execution |
| 178-04-02 | 3 | VPROOF-02 | T-178-10, T-178-11, T-178-12 | A12, A14 | 178-01-01/178-02-01; own 178-04-01 | Planned; no execution |
| 178-05-01 | 3 | VPROOF-02 | T-178-13, T-178-14, T-178-15 | A15, A16, A17 | 178-01-01/178-02-01; own 178-05-01 | Planned; no execution |
| 178-05-02 | 3 | VPROOF-02 | T-178-13, T-178-14, T-178-15 | A15, A18 | 178-01-01/178-02-01; own 178-05-01 | Planned; no execution |
| 178-06-01 | 3 | VPROOF-02 | T-178-16, T-178-17, T-178-18, T-178-19 | A19, A20, A21 | 178-01-01/178-02-01; own 178-06-01 | Planned; no execution |
| 178-06-02 | 3 | VPROOF-02 | T-178-16, T-178-17, T-178-18, T-178-19 | A19, A22, A23 | 178-01-01/178-02-01; own 178-06-01 | Planned; no execution |
| 178-07-01 | 3 | VPROOF-02 | T-178-20, T-178-21, T-178-22 | A24, A25 | 178-01-01/178-02-01; own 178-07-01 | Planned; no execution |
| 178-07-02 | 3 | VPROOF-02 | T-178-20, T-178-21, T-178-22 | A24, A26, A27 | 178-01-01/178-02-01; own 178-07-01 | Planned; no execution |
| 178-08-01 | 4 | VPROOF-02, VDELIV-01 | T-178-23, T-178-24, T-178-25 | A28, A29 | 178-01-01; own aggregate 178-08-01 | Planned; no execution |
| 178-08-02 | 4 | VPROOF-02, VDELIV-01 | T-178-23, T-178-24, T-178-25 | A30, A31, A32, A33 | own wrapper 178-08-02 | Planned; no execution |
| 178-09-01 | 5 | VDELIV-01 | T-178-26, T-178-27 | A34, A35 | 178-08-01/02 | Planned; no execution |
| 178-09-02 | 5 | VDELIV-01 | T-178-26, T-178-27 | A34 | 178-08-01/02 | Planned; no execution |
| 178-10-01 | 6 | VPROOF-02, VDELIV-01 | T-178-28, T-178-29, T-178-30 | A36, A37 | own validator 178-10-01 | Planned; no execution |
| 178-10-02 | 6 | VPROOF-02, VDELIV-01 | T-178-28, T-178-29, T-178-30 | A38 | own validator 178-10-01 | Planned; no execution |
| 178-10-03 | 6 | VPROOF-02, VDELIV-01 | T-178-28, T-178-29, T-178-30 | A39, A40, A41 | own validator 178-10-01 | Planned; no execution |
| 178-11-01 | 7 | VDELIV-01, VDELIV-02 | T-178-31, T-178-32, T-178-33 | A41, A42 | 178-10-01 | Planned; no execution |
| 178-11-02 | 7 | VDELIV-01, VDELIV-02 | T-178-31, T-178-32, T-178-33 | A43 | 178-10-01 | Planned; no execution |
| 178-12-01 | 8 | VDELIV-01, VDELIV-02 | T-178-34, T-178-35, T-178-36 | A41, A44 | 178-10-01 | Planned; no execution |
| 178-12-02 | 8 | VDELIV-01, VDELIV-02 | T-178-34, T-178-35, T-178-36 | A43, A45 | 178-10-01 | Planned; no execution |

## Automated Command Registry

All commands assume checkout root. Fast Python contracts target nonzero tests within 60 seconds; installed/full contributor/hosted execution is measured and retains bounded timeouts. Every command's immediately following fails_when lives in its PLAN task; nonzero exit or zero required executed cases/tests is failure. Source commands retain integration selection verbatim.

| ID | Exact command |
|----|---------------|
| A01 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_tracer_test.py'` |
| A02 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store builtin --group tracer --receipt-dir .artifacts/phase178/tracer` |
| A03 | `python3 -m unittest discover -s test/acceptance -p '*test.py'` |
| A04 | `python3 scripts/acceptance/clean_room_verifier_upgrade.py --self-test` |
| A05 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_core_test.py'` |
| A06 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store delegated --group core --receipt-dir .artifacts/phase178/core-delegated` |
| A07 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group core --receipt-dir .artifacts/phase178/core` |
| A08 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs test/lockspire/install/repo_runner_test.exs test/lockspire/install/task_error_test.exs` |
| A09 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_rollout_test.py'` |
| A10 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group rollout --receipt-dir .artifacts/phase178/rollout` |
| A11 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store builtin --group legacy-control --receipt-dir .artifacts/phase178/public-legacy` |
| A12 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_endpoints_test.py'` |
| A13 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store builtin --group endpoints --receipt-dir .artifacts/phase178/endpoints` |
| A14 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store builtin --group release-rpc --receipt-dir .artifacts/phase178/release-rpc` |
| A15 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_transactions_test.py'` |
| A16 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store delegated --group contention --receipt-dir .artifacts/phase178/contention` |
| A17 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_concurrency_test.exs` |
| A18 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store delegated --group atomicity --receipt-dir .artifacts/phase178/atomicity` |
| A19 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_recovery_test.py'` |
| A20 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group recovery --receipt-dir .artifacts/phase178/recovery` |
| A21 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/lockspire/security/client_secret_verifier_maintenance_test.exs test/integration/client_secret_verifier_maintenance_test.exs test/integration/client_secret_jwt_legacy_age_test.exs` |
| A22 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store delegated --group issuance --receipt-dir .artifacts/phase178/issuance` |
| A23 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_issuance_test.exs test/integration/client_secret_verifier_guarded_issuance_test.exs` |
| A24 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_disclosure_test.py'` |
| A25 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store delegated --group disclosure --receipt-dir .artifacts/phase178/disclosure` |
| A26 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store delegated --group disclosure --receipt-dir .artifacts/phase178/disclosure-complete` |
| A27 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs` |
| A28 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_receipts_test.py'` |
| A29 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group all --receipt-dir .artifacts/phase178/complete` |
| A30 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_ci_test.py'` |
| A31 | `bash scripts/ci/lint_workflows.sh` |
| A32 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 bash scripts/ci/run_verifier_upgrade_proof.sh --pair locked --receipt-dir .artifacts/phase178/ci-locked` |
| A33 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 bash scripts/ci/run_verifier_upgrade_proof.sh --pair floor --receipt-dir .artifacts/phase178/ci-floor` |
| A34 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` |
| A35 | `python3 scripts/acceptance/clean_room_verifier_upgrade.py --validate-receipts .artifacts/phase178/complete` |
| A36 | `python3 -m unittest discover -s test/acceptance -p 'client_verifier_delivery_test.py'` |
| A37 | `python3 scripts/acceptance/clean_room/verifier_delivery.py --check reviews --phase-dir .planning/phases/178-packaged-upgrade-proof-delivery-handoff` |
| A38 | `python3 scripts/acceptance/clean_room/verifier_delivery.py --check frozen --phase-dir .planning/phases/178-packaged-upgrade-proof-delivery-handoff` |
| A39 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group all --receipt-dir .artifacts/phase178/final` |
| A40 | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix ci` |
| A41 | `python3 scripts/acceptance/clean_room/verifier_delivery.py --check source --phase-dir .planning/phases/178-packaged-upgrade-proof-delivery-handoff` |
| A42 | `python3 scripts/acceptance/clean_room/verifier_delivery.py --check candidate-identity --phase-dir .planning/phases/178-packaged-upgrade-proof-delivery-handoff` |
| A43 | `python3 scripts/acceptance/clean_room/verifier_delivery.py --check candidate --phase-dir .planning/phases/178-packaged-upgrade-proof-delivery-handoff` |
| A44 | `python3 -c 'from pathlib import Path; import subprocess; p=Path(".planning/phases/178-packaged-upgrade-proof-delivery-handoff"); assert all((p/n).is_file() and (p/n).stat().st_size for n in ["178-CUSTODY.md","178-HANDOFF.md"]); subprocess.run(["git","diff","--check"],check=True)'` |
| A45 | `python3 scripts/acceptance/clean_room/verifier_delivery.py --check handoff --phase-dir .planning/phases/178-packaged-upgrade-proof-delivery-handoff` |

## Evidence boundaries and creation map

- Wave 1 Task 178-01-01 creates the installed tracer, strict receipt module and tracer tests while correcting provenance/pair selection. It must execute real installed HTTP before expansion.
- Wave 2 Task 178-02-01 creates core group and shared host adapter/barrier/allowlist interfaces. Plans 03–07 consume those fixed seams and own disjoint group/fixture/tests in Wave 3.
- Wave 4 Task 178-08-01 creates final all-scope acceptance; Task 178-08-02 creates the CI wrapper. The workflow retains existing locked/floor runtime partitions and seven-job graph.
- Wave 6 Task 178-10-01 creates the semantic delivery validator/tests. Frozen/source checks are used after their actual artifacts exist. Candidate-identity deliberately precedes completed candidate graph, and candidate/handoff stages require their later evidence.
- Exact-millisecond boundary/precision uses retained deterministic source owners plus installed code/tree binding and exact age preservation. Actual mounted HTTP validity/expiry remains separately observed; no private clock API or unobserved HTTP equality instant is invented.
- Postmerge helper execution is conditional on separately authorized integration and refreshed synchronized main. Pending integration can satisfy dated handoff under D-19; it cannot pass accepted-main or authorize next implementation.
- Phase177 E-09/E-10, earlier relevant generic flags and descriptorless prohibitions retain original provenance. Phase178 VDELIV-01/VDELIV-02 unclassified probes remain unresolved/null verification. Projected prohibitions remain descriptorless flagged-unverified; document/judgment checks do not count as runtime.

## Wave 0 Requirements

- [ ] Focused verifier receipt/aggregate tests reject missing cells, omitted witnesses, false identities and unsafe output.
- [ ] Source attribution and generic pair-selection regressions use existing helper infrastructure.
- [ ] Host-owned maintenance adapter/callback/barrier/failure fixtures and boundary allowlist support installed proof.
- [ ] New finite runner invokes installed commands and one real running-release RPC smoke.
- [ ] Final plans provide runnable commands or explicit creation dependencies; no new dependency/framework is selected.

## Manual-Only Verifications

| Behavior | Requirement | Reason and instructions |
|----------|-------------|-------------------------|
| Security/source/integration judgment and scope disposition | VDELIV-01 | Assigned independent reviewers record concrete evidence and retain non-authoritative flags; do not invent human review. |
| Actual integration authorization if required by live train | VDELIV-02 | Prepare concrete reviewed head/checks first; preserve authorization boundary and record pending state truthfully. |
| Fleet parity, backup/key destruction and host logging policy | Outside phase-local proof | Host responsibilities, not passing assertions of the installed test lab. |

## Validation Sign-Off

- [ ] Final task map reconciled with every PLAN.md task and threat reference.
- [ ] Every runnable verify command has an observable failing-direction statement.
- [ ] No three consecutive tasks lack automated sampling or an explicit creation dependency.
- [ ] Required package evidence and actual CI identities are complete before their claims pass.
- [ ] `nyquist_compliant: true` only after independent validation; planning does not set it.

**Approval:** Pending implementation and independent validation.
