---
phase: "177"
slug: "safe-verifier-maintenance-recovery"
status: source-validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-25"
---

# Phase 177 — Validation Strategy

> Final execution map for 9 plans / 18 tasks / 7 waves. Source runtime evidence is recorded in `177-SOURCE-ACCEPTANCE.json`; package and final milestone gates remain outside this source validation.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit; existing Ecto SQL Sandbox plus independent PostgreSQL integration connections |
| Config | `config/test.exs`, `test/test_helper.exs`, `mix.exs` test aliases |
| Runtime | Elixir 1.19.5 / OTP 28.5 through process-local ASDF variables |
| Quick run | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` |
| Full contributor gate | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix ci` |
| Integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test.integration` |
| Runtime estimate | Focused 85-test verifier command: 2.6s ExUnit runtime; canonical `mix ci`: 301s wall time |

## Sampling Rate

- Every task: run its focused test command, with observable nonzero/empty-suite failure direction.
- Every plan wave: run the phase's relevant focused integration and verifier regressions.
- Before independent phase verification: full contributor gate plus actual PostgreSQL contention/rollback evidence.
- No three consecutive tasks without automated feedback; tests are created in their owning task before its verification command runs.
- Target focused feedback under 120 seconds; measure and report actual latency rather than claiming this target achieved.

## Per-Task Verification Map

Final task/command/threat mapping follows. All runtime rows remain pending; structural planning validation does not establish acceptance. Each command has an immediate fails_when in its owning task: nonzero exits, zero/excluded required tests and missing specific behavior evidence fail.

| Task | Requirements | Behavior | Test type | Automated command | Threat Ref | Executed result |
|---|---|---|---|---|---|---|
| 177-01-01 | VUP-03,VOPS-02 | Commit one native verifier-only rewrap through selected authority | PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_test.exs` | T-177-01,T-177-02,T-177-03 | Passed; 3 tests, 0 failures (owning-plan final run); reconfirmed by final 260-test integration stage. |
| 177-01-02 | VUP-03,VOPS-02 | Enforce adapter declaration and exact repeat semantics | PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/lockspire/storage/client_verifier_maintenance_test.exs test/integration/client_secret_verifier_maintenance_test.exs` | T-177-01,T-177-02,T-177-03 | Passed; 7 tests, 0 failures (owning-plan final run); reconfirmed by final gate. |
| 177-02-01 | VUP-03,VOPS-02,VOPS-03 | Preserve authenticated dedicated age through custody rewrap | Unit+PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/lockspire/security/client_secret_verifier_maintenance_test.exs test/integration/client_secret_verifier_maintenance_test.exs` | T-177-04,T-177-05,T-177-06 | Passed in the owning-plan custody/age run; final verifier-focused command 85/0 and canonical CI pass. |
| 177-02-02 | VUP-03,VOPS-02,VOPS-03 | Promote only qualified legacy material | Unit+PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/lockspire/security/client_secret_verifier_maintenance_test.exs test/integration/client_secret_verifier_maintenance_test.exs test/integration/client_secret_jwt_legacy_age_test.exs` | T-177-04,T-177-05,T-177-06 | Passed; 36 tests, 0 failures in final owning-plan selected-store suite; final CI pass. |
| 177-03-01 | VOPS-01,VOPS-03 | Prove all-row bytewise cursor traversal | Unit+PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/lockspire/storage/client_verifier_maintenance_test.exs` | T-177-07,T-177-08,T-177-09,T-177-10 | Passed; 7 tests, 0 failures. |
| 177-03-02 | VOPS-01,VOPS-03 | Expose exhaustive safe status and separate completion facts | Unit+PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/lockspire/admin/client_verifier_maintenance_test.exs test/lockspire/storage/client_verifier_maintenance_test.exs` | T-177-07,T-177-08,T-177-09,T-177-10 | Passed; 17 tests, 0 failures. |
| 177-04-01 | VOPS-01,VOPS-03 | Resolve bare-task configuration without mutating serving context | Unit+subprocess | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/config_client_secret_verifier_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | T-177-11,T-177-12,T-177-13,T-177-14 | Passed; 30 tests, 0 failures in owning-plan run; final config-only 16/0 and full fast stage pass. |
| 177-04-02 | VOPS-01,VOPS-03 | Wire strict CLI modes and Repo ownership to safe outcome rendering | Unit+subprocess | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs test/lockspire/install/repo_runner_test.exs test/lockspire/install/task_error_test.exs` | T-177-11,T-177-12,T-177-13,T-177-14 | Passed; 33 tests, 0 failures; final fast stage pass. |
| 177-05-01 | VOPS-01,VOPS-02 | Serialize maintenance with real rotation and unrelated edits | PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_concurrency_test.exs` | T-177-15,T-177-16,T-177-17 | Passed with independent PostgreSQL connections, captured backend PIDs, and exact `pg_blocking_pids` blocker checks; final focused source run 85/0 and canonical CI pass. |
| 177-05-02 | VOPS-01,VOPS-02 | Prove rollback, overlapping retries and committed progress | PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_concurrency_test.exs test/integration/client_secret_verifier_maintenance_test.exs` | T-177-15,T-177-16,T-177-17 | Passed; 18 tests, 0 failures; final focused source run 85/0 and canonical CI pass. |
| 177-06-01 | VUP-03,VOPS-02,VOPS-04 | Race real maintenance against guarded JWT issuance | PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_issuance_test.exs test/integration/client_secret_verifier_guarded_issuance_test.exs` | T-177-18,T-177-19,T-177-20 | Passed; 3 tests, 0 failures; focused source run 85/0 and canonical integration stage pass. |
| 177-06-02 | VUP-03,VOPS-02,VOPS-04 | Exercise key introduction, local retirement check and key-loss recovery | PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_recovery_test.exs test/integration/client_secret_verifier_rotation_test.exs` | T-177-18,T-177-19,T-177-20 | Passed; 5 tests, 0 failures; final focused source run 85/0 and canonical integration stage pass. |
| 177-07-01 | VPROOF-01 | Redact stored credentials in schema and nested domain inspection | Unit+PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_inspection_test.exs test/lockspire/clients_secret_material_test.exs` | T-177-21,T-177-22,T-177-23 | Passed; original 7 tests/0 failures and final proof/secret command 10/0. |
| 177-07-02 | VPROOF-01 | Suppress both client query channels and map unsafe storage diagnostics | Unit+PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs` | T-177-21,T-177-22,T-177-23 | Passed; 2 tests, 0 failures; canonical integration stage passed. |
| 177-08-01 | VUP-03,VOPS-01,VOPS-03,VOPS-04,VPROOF-01 | Close success and forced-failure disclosure matrix | Unit+PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs` | T-177-24,T-177-25,T-177-26 | Passed; 27 tests, 0 failures in final owning-plan run; final focused source run 85/0 and canonical CI pass. |
| 177-08-02 | VUP-03,VOPS-01,VOPS-03,VOPS-04,VPROOF-01 | Document verified maintenance, retirement and recovery operations | Unit+PostgreSQL | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | T-177-24,T-177-25,T-177-26 | Passed; included in final owning-plan 27-test run and final CI. |
| 177-09-01 | All six | Run the source contributor gate and record exact acceptance cases | Full gate+evidence | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix ci` | T-177-27,T-177-28 | Passed on `8bae1a306e836c6d512c1d7e34ed39ef3c22e088`, exit 0; 15 boundary, 2 properties, 2,138 fast tests (0 failures; 6 skipped, 567 excluded), 260 integration (0 failures; 46 excluded), 301s. |
| 177-09-02 | All six | Reconcile validation and leave bounded source handoff | Full gate+evidence | `python3 -c 'import hashlib,json; from pathlib import Path; p=Path(".planning/phases/177-safe-verifier-maintenance-recovery"); a=json.loads((p/"177-SOURCE-ACCEPTANCE.json").read_text()); f=json.loads(Path(".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-FINAL-SOURCE.json").read_text()); assert a["tested_sha"] and set(a["requirements"])=={"VUP-03","VOPS-01","VOPS-02","VOPS-03","VOPS-04","VPROOF-01"}; assert a["commands"] and all(c["exit_code"]==0 and c["executed_tests"]>0 for c in a["commands"]); assert len(f["frozen_inputs"])==13 and all(hashlib.sha256(Path(x["path"]).read_bytes()).hexdigest()==x["sha256"] for x in f["frozen_inputs"]); assert (p/"177-HANDOFF.md").is_file(); print("source acceptance and frozen inputs checked")'` | T-177-27,T-177-28 | Passed; source receipt/handoff shape and 13 frozen hashes checked. Structural check is not runtime proof. |

### Produced new test targets

- `test/integration/client_secret_verifier_maintenance_concurrency_test.exs` — NEW, created by the first owning task before its command.
- `test/integration/client_secret_verifier_maintenance_disclosure_test.exs` — NEW, created by the first owning task before its command.
- `test/integration/client_secret_verifier_maintenance_issuance_test.exs` — NEW, created by the first owning task before its command.
- `test/integration/client_secret_verifier_maintenance_recovery_test.exs` — NEW, created by the first owning task before its command.
- `test/integration/client_secret_verifier_maintenance_test.exs` — NEW, created by the first owning task before its command.
- `test/lockspire/admin/client_verifier_maintenance_test.exs` — NEW, created by the first owning task before its command.
- `test/lockspire/security/client_secret_verifier_inspection_test.exs` — NEW, created by the first owning task before its command.
- `test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs` — NEW, created by the first owning task before its command.
- `test/lockspire/security/client_secret_verifier_maintenance_test.exs` — NEW, created by the first owning task before its command.
- `test/lockspire/storage/client_verifier_maintenance_test.exs` — NEW, created by the first owning task before its command.
- `test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` — NEW, created by the first owning task before its command.

## Wave 0 Requirements

- Existing ExUnit/PostgreSQL infrastructure is available; no framework install or dependency is selected.
- Owning implementation tasks must create the proposed new test files and deterministic independent-connection/barrier fixtures before invoking them.
- Existing `test/lockspire/storage/reencrypt_concurrency_test.exs` and guarded-issuance tests supply patterns, not maintenance acceptance evidence.
- Final task IDs and unique phase-wide T-177-01–T-177-28 threats are mapped above; T-177-SC is the reserved shared supply-chain row. Any renamed target must update its produced-artifact declaration and this map.

## Manual-Only Verifications

All phase-owned source behavior should have automated proof. Host fleet key parity, quiescence, backups, rollback readiness and PostgreSQL server logging are documented host responsibilities, not local pass claims. Package-installed dependency-pair/composed-adapter journeys belong to Phase 178.

## Validation Sign-Off

- [x] Final tasks/threats mapped to automated commands
- [x] New command targets created by owning tasks/dependencies (declared NEW; executed in their owning plans and final gates)
- [ ] No three consecutive tasks without automated feedback
- [ ] No watch-mode commands
- [x] Focused runtime latency measured: 2.6s for the 85-test verifier-focused source run (full command duration 4s including startup)
- [x] Runtime source validation completed; all six requirements have automated evidence. Unclassified edges and prohibitions remain separately flagged; package and milestone gates remain pending.

**Approval:** Source validation recorded; independent Phase 177 verification remains the next gate.

The final mixed verifier-family attempt that combined unit and integration tests in one invocation is retained as a failed noncanonical attempt in `177-SOURCE-ACCEPTANCE.json`; its configuration module passes alone and the canonical `mix ci` stages pass separately. The acceptance receipt records exact log digests and does not hide this result.
