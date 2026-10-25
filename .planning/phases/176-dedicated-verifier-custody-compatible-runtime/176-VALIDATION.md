---
phase: "176"
slug: "dedicated-verifier-custody-compatible-runtime"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-25"
---

# Phase 176 — Validation Strategy

> Audited execution coverage: seven plans, fourteen tasks and five waves completed. All planned test files exist; every owned runtime case has observed evidence in 176-RUNTIME-ACCEPTANCE.json. Full candidate CI passed on b8cd395d. Later maintenance and package proof remain pending.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, existing Mix project and PostgreSQL integration fixtures |
| Config | `mix.exs`, `test/test_helper.exs` |
| Runtime prefix | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` |
| Quick command, after 176-01-02 creates the suite | `MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` |
| Tracer command, after 176-01-01 creates the suite | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_tracer_test.exs` |
| Full candidate gate | `mix ci` with the runtime prefix above |
| Runtime estimate | Unmeasured for new suites; measure during execution and record observed feedback latency |

## Sampling Rate

- Every task runs a focused behavior test after its final change and before committing.
- Each wave runs affected verifier/helper/endpoint/persistence suites, including integration tags explicitly where required.
- The final candidate runs the established `mix ci`; record its real exit and source identity, without claiming accepted main or publication.
- No three consecutive tasks may lack automated verification. Runnable commands require an immediately following `<fails_when>` signal in plans.

## Exact Task, Threat and Test Map

Every command below MUST be prefixed with `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5`. All new test files were created within their named task; task summaries record focused passes, and final candidate CI passed. Current existence/result is **yes / green**. Existing baseline suites remain unchanged. Every command in PLAN XML has an immediately following `fails_when` signal.

| Task | Requirement | Behavior | Threat Ref | Automated command after test creation |
|---|---|---|---|---|
| 176-01-01 | SEC-01/02/03/05 | Persisted native tracer, wrong-ID denial, real replay effects | T-176-01,03 | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_tracer_test.exs` |
| 176-01-02 | SEC-03 | Exact independent format/AAD vectors, parser/bounds/no downgrade | T-176-01,02,03 | `MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` |
| 176-02-01 | SEC-01/02, VUP-02 | Startup snapshot, supported states and complete override | T-176-04,05,06 | `MIX_ENV=test mix test test/lockspire/config_client_secret_verifier_test.exs test/lockspire/application_key_encryption_test.exs` |
| 176-02-02 | SEC-01/02 | Key grammar/reuse, invalid-present failure and usable persisted hash auth | T-176-04,05,06 | `MIX_ENV=test mix test --include integration test/lockspire/config_client_secret_verifier_test.exs test/integration/client_secret_verifier_configuration_test.exs` |
| 176-03-01 | SEC-01/02/04 | Typed generation, exact helper shapes, hash-only independence | T-176-08,09 | `mix test test/lockspire/clients_secret_material_test.exs test/lockspire/security/client_secret_verifier_compatibility_test.exs` |
| 176-03-02 | SEC-01/02/04 | Direct final-ID coherent pair, no-write failure and handoff | T-176-07,09 | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_direct_writer_test.exs` |
| 176-04-01 | SEC-03, VUP-01 | Authenticated legacy metadata, migrated finite ages, no timer on native | T-176-10,11,12 | `mix test test/lockspire/security/client_secret_verifier_age_test.exs test/lockspire/security/client_secret_verifier_compatibility_test.exs` |
| 176-04-02 | SEC-05, VUP-01 | Persisted caller/lifecycle equality and unchanged effects | T-176-10,11,12 | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_age_test.exs test/integration/client_secret_jwt_legacy_age_test.exs` |
| 176-05-01 | SEC-01/02/04 | DCR final ID, configured lifetimes, selected stores/audit | T-176-13,15 | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_dcr_writer_test.exs test/integration/client_secret_lifetime_registration_test.exs` |
| 176-05-02 | SEC-01/02/04 | Operator rotation pair, existing lock/transaction and rollback | T-176-14,15 | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_rotation_test.exs test/integration/client_secret_lifetime_rotation_test.exs` |
| 176-06-01 | SEC-03/05, VUP-01 | Existing positive direct endpoints, PAR/FAPI and assertion/error negatives | T-176-16,18 | `mix test test/lockspire/protocol/client_secret_verifier_endpoints_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` |
| 176-06-02 | SEC-05 | Token positive, ciphertext-only guard denial, consumed/fresh JTI | T-176-17,18 | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_guarded_issuance_test.exs` |
| 176-07-01 | SEC-01/02, VUP-01/02 | Real-reader rollout/activation/rollback and reachable guide | T-176-19,21 | `mix test test/lockspire/security/client_secret_verifier_rollout_test.exs` |
| 176-07-02 | All seven | Existing full candidate gate, 22 stable runtime cases and frozen preservation | T-176-20,21,SC | `mix ci`; literal Python frozen-input/result assertion in 176-07-PLAN.md |

Security enforcement is ASVS 1, blocking high/critical. IDs T-176-01 through T-176-21 are phase-global unique; reserved T-176-SC repeats per plan. No new package or schema task exists. The existing CI alias’s locked dependency resolution does not add a dependency.

Tracer feedback: 176-01-01 must pass and commit, then rerun the literal tracer check before Task 01-02 or any expansion. Execution must record that ordering. Each later task has focused automated feedback; new failing acceptance is written before implementation where behavior is added. Final `mix ci` is the deliberately longer phase gate (previous candidate roughly five minutes), with bounded tool polling. Focused latency is unmeasured until execution; record actual duration and split feedback selection if it exceeds 60 seconds without dropping acceptance.

## Wave 0 Requirements

- [x] 176-01 creates tracer and parser suites; 176-02 creates config and invalid-state persisted suites.
- [x] 176-03 creates helper/direct-writer suites; 176-05 creates DCR/operator suites.
- [x] 176-04 creates native/migrated/legacy unit and persisted age suites.
- [x] 176-06 creates endpoint and guarded-issuance suites; 176-07 creates real-reader rollout suite.
- Existing ExUnit/PostgreSQL infrastructure is sufficient; install no framework or dependency.

## Manual-Only Verifications

All scoped library behavior has automated acceptance. Fleet reader/key parity, operator-owned deployment/drain, backups and rollback disposition are host preconditions that local tests cannot certify. Complete packaged deployment journeys remain Phase 178. No manual UI review is selected.

## Coverage and Remaining Flags

`176-PROBE-DISPOSITION.md` maps all 22 owner-176 frozen case IDs, seven requirements, D-01–D-15, source constraints and all 15 probe edges. Twelve classifiable edges have explicit must_haves; SEC-02/VUP-01/VUP-02 unclassified rows remain flagged unresolved. Three descriptor-less values prohibitions remain flagged-unverified, never mechanically passed. Owner-175 qualification is immutable; all eight owner-177 and one owner-178 cases remain pending. Sequential fingerprint regression is not the later maintenance contention proof. Runtime sentinels apply from introduction; comprehensive disclosure proof remains Phase 177.

## Validation Sign-Off

- [x] Exact plan/task and threat references replace the provisional map.
- [x] Every task has automated verification and test creation precedes new-path commands.
- [x] Sampling continuity and no watch-mode commands.
- [x] Full frozen case/requirement/decision coverage is mapped.
- [ ] Feedback latency measured during execution.
- [x] Runtime acceptance: all22owner176cases recorded against the passing candidate; future-owner cases remain pending.

**Coverage audit:** 2026-10-25 — 7/7 requirements covered, all14task verification paths exist, 22/22 owned runtime cases have recorded successful execution. Candidate CI: 2 properties, 2,097 fast tests and 231 integration tests, zero failures. Independent security/source/goal verification remains separate. Focused feedback latency was not uniformly retained; this is an evidence limit, not a passing timing claim. The final full CI run took 244 seconds, with ERL_FLAGS=+S4 and a task-owned database.

## Validation Audit 2026-10-25

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Independent Security Coverage Correction

The first coverage audit reconciled execution artifacts, but independent security probes found three planned threats untested across four mechanisms (SF-01 through SF-04 in 176-SECURITY-FINDINGS.md). Current validation is partial until those regressions are implemented and rerun. Earlier candidate CI remains historical observed test evidence, not proof of the missing controls.

## Corrective Coverage Re-Audit

SF-01 through SF-04 now have direct regressions and independent source probes. The corrective focused suite passed26/0 and full mixci passed at71627f27 with2102fast+231integrationtests, zero failures. The independent security auditor closed22/22planned threats. All14task paths and22ownedcase mappings remain present; unresolved generic probes/prohibitions retain their separate flagged status. Current coverage gaps:0. See176-SECURITY-FIX-ACCEPTANCE.json and176-SECURITY.md.

## Validation Audit 2026-10-25

| Metric | Count |
|---|---|
| Gaps found | 3 |
| Resolved | 3 |
| Escalated | 0 |
