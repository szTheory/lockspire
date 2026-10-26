---
phase: "177"
slug: "safe-verifier-maintenance-recovery"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-25"
---

# Phase 177 — Validation Strategy

> Draft execution validation contract. Runtime results and final task mapping remain pending.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit; existing Ecto SQL Sandbox plus independent PostgreSQL integration connections |
| Config | `config/test.exs`, `test/test_helper.exs`, `mix.exs` test aliases |
| Runtime | Elixir 1.19.5 / OTP 28.5 through process-local ASDF variables |
| Quick run | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` |
| Full contributor gate | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix ci` |
| Integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test.integration` |
| Runtime estimate | Not measured for new tests; establish during first tracer execution |

## Sampling Rate

- Every task: run its focused test command, with observable nonzero/empty-suite failure direction.
- Every plan wave: run the phase's relevant focused integration and verifier regressions.
- Before independent phase verification: full contributor gate plus actual PostgreSQL contention/rollback evidence.
- No three consecutive tasks without automated feedback; tests are created in their owning task before its verification command runs.
- Target focused feedback under 120 seconds; measure and report actual latency rather than claiming this target achieved.

## Per-Task Verification Map

Planner must replace proposed file/task mapping with final plan task IDs before planning completion. Every row below remains pending; source planning does not establish runtime truth.

| Requirement | Behavior | Test type | Planned test target | Exists | Status |
|---|---|---|---|---|---|
| VUP-03 | Reader-first key rotation, rewrap without credential changes, fresh retirement check | Integration | `test/integration/client_secret_verifier_maintenance_test.exs` | No — owning task creates | Pending |
| VOPS-01 | Modes, partial/conflict outcomes, bare Mix and Repo lifecycle | Unit + task | `test/lockspire/admin/client_verifier_maintenance_test.exs`, `test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | No — owning tasks create | Pending |
| VOPS-02 | Authority, exact CAS, verifier-only fields, audit/outer rollback and both lock orders | PostgreSQL integration | `test/integration/client_secret_verifier_maintenance_test.exs` | No — owning task creates | Pending |
| VOPS-03 | All stored rows, bytewise paging and incomplete status | Unit + integration | `test/lockspire/storage/client_verifier_maintenance_test.exs` | No — owning task creates | Pending |
| VOPS-04 | Key restoration/authorized replacement, failed JWT and unaffected supported methods | Integration | `test/integration/client_secret_verifier_maintenance_test.exs` | No — owning task creates | Pending |
| VPROOF-01 | Sentinels across query/error/Inspect/audit/task/protocol channels | Unit + integration | `test/integration/client_secret_verifier_maintenance_disclosure_test.exs` | No — owning task creates | Pending |

## Wave 0 Requirements

- Existing ExUnit/PostgreSQL infrastructure is available; no framework install or dependency is selected.
- Owning implementation tasks must create the proposed new test files and deterministic independent-connection/barrier fixtures before invoking them.
- Existing `test/lockspire/storage/reencrypt_concurrency_test.exs` and guarded-issuance tests supply patterns, not maintenance acceptance evidence.
- Planner must reconcile target paths, threat IDs and final task IDs; any renamed test appears in the plan's produced artifacts and validation map.

## Manual-Only Verifications

All phase-owned source behavior should have automated proof. Host fleet key parity, quiescence, backups, rollback readiness and PostgreSQL server logging are documented host responsibilities, not local pass claims. Package-installed dependency-pair/composed-adapter journeys belong to Phase 178.

## Validation Sign-Off

- [ ] Final tasks/threats mapped to automated commands
- [ ] New command targets created by owning tasks/dependencies
- [ ] No three consecutive tasks without automated feedback
- [ ] No watch-mode commands
- [ ] Focused runtime latency measured
- [ ] Runtime validation completed; `nyquist_compliant: true` set only with evidence

**Approval:** Pending implementation and validation.
