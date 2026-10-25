---
phase: "176"
slug: "dedicated-verifier-custody-compatible-runtime"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-25"
---

# Phase 176 — Validation Strategy

> Planning validation contract. No new runtime acceptance test has run yet. The planner must replace the provisional task map with exact plan/task IDs before declaring planning complete.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, existing Mix project and PostgreSQL integration fixtures |
| Config | `mix.exs`, `test/test_helper.exs` |
| Runtime prefix | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` |
| Quick command, once the new suite exists | `MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` |
| Persistence command, once the new suite exists | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_writers_test.exs` |
| Full candidate gate | `mix ci` with the runtime prefix above |
| Runtime estimate | Unmeasured for new suites; measure during execution and record observed feedback latency |

## Sampling Rate

- Every task runs a focused behavior test after its final change and before committing.
- Each wave runs affected verifier/helper/endpoint/persistence suites, including integration tags explicitly where required.
- The final candidate runs the established `mix ci`; record its real exit and source identity, without claiming accepted main or publication.
- No three consecutive tasks may lack automated verification. Runnable commands require an immediately following `<fails_when>` signal in plans.

## Provisional Verification Map

| Requirement | Behavior | Test type | Planned automated verification | File exists | Status |
|-------------|----------|-----------|--------------------------------|-------------|--------|
| SEC-01/02 | Independent keys, all config states, safe diagnostics, unrelated hash authentication survives invalid-present config | unit/application | `MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` plus planner-selected application tests | No — create before use | pending |
| SEC-03 | Exact envelope/AAD, bounded canonical parser, key/version/purpose/client/tag rejection, no legacy retry | unit | Same new verifier suite, adversarial inputs and round-trip checks | No — create before use | pending |
| SEC-04 | Direct/DCR/operator writers choose final ID, persist coherent material and preserve one-time handoff/lifetimes | integration | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_writers_test.exs` | No — create before use | pending |
| SEC-05 | Five positive endpoint families; PAR/FAPI exclusions; HS256/audience/JTI/fingerprint invariants | protocol/integration | Existing `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` plus planner-selected token/fingerprint tests | Existing precedents, new dedicated cases required | pending |
| VUP-01 | Legacy allow/reject, native configured age, migrated original finite deadline, future/unsupported inputs unchanged | unit/integration | New implementation-level tests plus unchanged Phase 175 compatibility/legacy-caller regressions | New cases required | pending |
| VUP-02 | Stage read keys without write activation; old-code read boundary; explicit activation and truthful rollback limits | contract/integration | `MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_rollout_test.exs` | No — create before use | pending |

Use the runtime prefix for every Mix command. A nonexistent future test path is a prerequisite to create, never evidence of a passing check. Plan tasks must order test creation before invoking the corresponding command.

## Wave 0 Requirements

- [ ] New verifier config/envelope suite and explicit-context fixtures.
- [ ] Persisted writer suite covering direct, DCR and operator paths.
- [ ] Local rollout/rollback behavior suite with real legacy-format decoding, not label-only assertions.
- [ ] Dedicated endpoint and native/migrated-age cases; preserve frozen Phase 175 qualification source files unchanged.
- Existing ExUnit/PostgreSQL infrastructure is sufficient; install no framework or dependency.

## Manual-Only Verifications

All scoped library behavior has automated acceptance. Fleet reader/key parity, operator-owned deployment/drain, backups and rollback disposition are host preconditions that local tests cannot certify. Complete packaged deployment journeys remain Phase 178. No manual UI review is selected.

## Validation Sign-Off

- [ ] Exact plan/task and threat references replace the provisional map.
- [ ] Every task has automated verification or an explicit prior test-creation dependency.
- [ ] Sampling continuity and no watch-mode commands.
- [ ] Full frozen case/requirement/decision coverage is mapped.
- [ ] Feedback latency measured during execution.
- [ ] Runtime acceptance results remain pending until executed.

**Approval:** Draft strategy derived from research; execution acceptance is pending.
