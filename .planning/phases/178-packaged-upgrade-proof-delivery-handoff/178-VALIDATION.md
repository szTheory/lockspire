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

The planner must replace this requirement-level seed with concrete task IDs, waves, unique threat references and commands from finalized plans before the planning checker accepts Dimension 8. New commands below are dependencies, not existing runnable acceptance.

| Requirement | Secure behavior | Test type | Command/owner | State |
|-------------|-----------------|-----------|---------------|-------|
| VPROOF-02 | Source/archive/vendor/resolved/compiled attribution, exact pair selection and strict missing-case failure | Helper/receipt contracts | New focused tests owned by first implementation plan | Pending creation |
| VPROOF-02 | Real installed fresh/legacy/core rotation/recovery across both pairs × both stores; actual supported HTTP controls | Installed PostgreSQL/HTTP | New finite verifier runner with strict per-cell receipt validation | Pending creation |
| VPROOF-02 | Exact blocker-PID contention, reached audit INSERT rollback, outer rollback, issuance/JTI race, preservation and disclosure | Installed delegated-store integration on both pairs | New host-owned witness scenarios; source precedent above | Pending creation |
| VDELIV-01 | Accurate guidance, focused reviews, all 18 requirement dispositions, canonical audit and exact candidate gates | Contributor/review/CI | Full `mix ci`, independent security/source/integration review, complete same-run seven-job graph | Future execution |
| VDELIV-02 | Truthful blocked-or-accepted delivery, preserved custody/ranking and immutable postmerge main receipt | Evidence/handoff | Existing `repo_hygiene_check.sh --accept-sha` after authorized integration; bounded artifact checks before it | Future execution |

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
