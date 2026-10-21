---
phase: "164"
slug: "client-secret-expiry-atomic-rotation"
status: planned
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-20"
---

# Phase 164 — Validation Strategy

Planning map only; runtime evidence remains pending. No strict phase-wide TDD mode is enabled. All task behavior blocks specify regression expectations.

## Infrastructure and environment

Every command below uses Elixir 1.18.4 / OTP 27.3.4.15, supplied isolated Mix/Hex homes and LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation. Never omit the dedicated database variable or use the shared default. PostgreSQL is available; the fresh database is not yet created. Task 164-01-01 runs mix test.setup first.

Existing ExUnit, Ecto sandbox, transaction fixtures and ClientLifetimeRaceHelpers provide infrastructure; no installs are required. Every new test file is explicitly created in its owning task before its command runs. Wave 0 remains incomplete until setup/selections actually run.

## Sampling and budgets

Run exact focused commands after each task; target feedback under 60 seconds with per-test timeout 55000. Split measured longer focused selections without dropping tests. The normal full suite has the configured 1800-second budget; stream/poll output and communicate within 60 seconds.

Wave 2 plans have disjoint files and rollback-isolated fixtures; neither resets the DB. Independent committed-session tests run in wave 4. Run normal unfiltered mix test.fast and separately include postgres_race with explicit files; the three new race modules carry integration and postgres_race tags. Excluded totals never prove race execution.

Prior normal baseline: 2 properties, 2291 tests, 0 failures, 398 excluded, 6 skipped. Keep exclusions/skips visible and record actual new counts. Existing heavyweight packaged upgrade proof is not repeated unless schema/install/migration/package inputs change. Final cross-phase packaged proof remains Phase 166.

## Per-task verification map

Every task has automated and fails_when clauses in its PLAN. Existing files are grounded in git; newly named tests are created by the referenced task.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure behavior | Exact command IDs | Status |
|---|---|---:|---|---|---|---|---|
| 164-01-01 | 01 | 1 | DCR-07/08 | T-164-01/02/03 | Register one finite Basic secret and prove its actual boundary | C011 | pending |
| 164-01-02 | 01 | 1 | DCR-07/08 | T-164-01 | Reject invalid secret policy at write and use boundaries | C012 | pending |
| 164-01-03 | 01 | 1 | DCR-07/08 | T-164-03 | Complete unlimited, provenance, legacy and no-secret metadata cases | C013 | pending |
| 164-02-01 | 02 | 2 | DCR-08 | T-164-04/06 | Apply one strict secret gate across every auth method | C021 | pending |
| 164-02-02 | 02 | 2 | DCR-08 | T-164-05/06 | Recheck current secret authority after code and refresh locks | C022 | pending |
| 164-02-03 | 02 | 2 | DCR-08 | T-164-07 | Preserve endpoint errors for expired secret callers | C023 | pending |
| 164-03-01 | 03 | 2 | DCR-07/09 | T-164-08/10/12 | Rotate from the locked row using current policy and deferred time | C031 | pending |
| 164-03-02 | 03 | 2 | DCR-07/09 | T-164-09 | Prove adapter transport and whole-row legacy canonicalization | C032 | pending |
| 164-03-03 | 03 | 2 | DCR-07/09 | T-164-11/12 | Preserve operator policy and roll back failed secret delivery | C033 | pending |
| 164-04-01 | 04 | 3 | DCR-08 | T-164-13/14/15 | Guard authenticated device and CIBA polls without gating queued push | C041 | pending |
| 164-04-02 | 04 | 3 | DCR-08 | T-164-15/16 | Revalidate only the RFC 8693 requesting secret after token locks | C042 | pending |
| 164-04-03 | 04 | 3 | DCR-08 | T-164-15 | Prove existing tokens and non-secret finalizers remain usable | C043 | pending |
| 164-05-01 | 05 | 4 | DCR-08/09 | T-164-17 | Prove expiry and committed replacement during a client-row wait | C051 | pending |
| 164-05-02 | 05 | 4 | DCR-08/09 | T-164-17 | Prove expiry during every later grant or token wait | C052 | pending |
| 164-05-03 | 05 | 4 | DCR-08/09 | T-164-18/19/20 | Prove serialized operator winners, post-wait truth and rollback | C053 | pending |
| 164-06-01 | 06 | 5 | DCR-07/08/09 | T-164-21 | Observe finite-secret events and prove redaction | C061 | passed |
| 164-06-02 | 06 | 5 | DCR-07/08/09 | T-164-22 | Make secret lifetime admin guidance truthful | C062 | passed |
| 164-06-03 | 06 | 5 | DCR-07/08/09 | T-164-23 | Reconcile host guidance and execute the complete phase gate | C063a, C063b, C063c | passed |

## Exact command registry

Commands run from repository root. Pending selections are not current runtime evidence.

### C011 — 164-01-01

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test.setup && env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_registration_test.exs --max-failures 1 --timeout 55000
```

### C012 — 164-01-02

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/lockspire/protocol/client_secret_lifetime_policy_test.exs test/lockspire/web/controllers/registration_controller_test.exs --max-failures 1 --timeout 55000
```

### C013 — 164-01-03

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_registration_test.exs test/lockspire/web/registration_json_test.exs --max-failures 1 --timeout 55000
```

### C021 — 164-02-01

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/lockspire/protocol/client_secret_lifetime_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs --max-failures 1 --timeout 55000
```

### C022 — 164-02-02

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_code_refresh_test.exs test/integration/app_lifetime_code_redemption_test.exs test/integration/app_lifetime_refresh_test.exs --max-failures 1 --timeout 55000
```

### C023 — 164-02-03

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/lockspire/web/token_controller_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/revocation_controller_test.exs --max-failures 1 --timeout 55000
```

### C031 — 164-03-01

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_rotation_test.exs test/lockspire/admin/clients_test.exs --max-failures 1 --timeout 55000
```

### C032 — 164-03-02

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs test/lockspire/client_lifecycle_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000
```

### C033 — 164-03-03

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/lockspire/admin/clients_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs test/integration/client_secret_lifetime_rotation_test.exs --max-failures 1 --timeout 55000
```

### C041 — 164-04-01

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_poll_exchange_test.exs test/integration/app_lifetime_ciba_push_test.exs test/integration/app_lifetime_poll_issuance_test.exs --max-failures 1 --timeout 55000
```

### C042 — 164-04-02

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_poll_exchange_test.exs test/integration/app_lifetime_rfc8693_test.exs --max-failures 1 --timeout 55000
```

### C043 — 164-04-03

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/integration/client_secret_lifetime_existing_tokens_test.exs test/integration/client_secret_lifetime_poll_exchange_test.exs test/integration/app_lifetime_online_consumers_test.exs --max-failures 1 --timeout 55000
```

### C051 — 164-05-01

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test --include postgres_race test/lockspire/storage/client_secret_lifetime_client_wait_test.exs --max-failures 1 --timeout 55000
```

### C052 — 164-05-02

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test --include postgres_race test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs --max-failures 1 --timeout 55000
```

### C053 — 164-05-03

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test --include postgres_race test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs --max-failures 1 --timeout 55000
```

### C061 — 164-06-01

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/lockspire/protocol/dcr_telemetry_redaction_test.exs test/lockspire/redaction/redaction_test.exs --max-failures 1 --timeout 55000
```

### C062 — 164-06-02

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs --max-failures 1 --timeout 55000
```

### C063a — 164-06-03

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000
```

### C063b — 164-06-03

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test.fast
```

### C063c — 164-06-03

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test --include postgres_race test/lockspire/storage/client_secret_lifetime_client_wait_test.exs test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs --max-failures 1 --timeout 55000
```

## Required evidence

- Real registration → fetched durable deadline → wire value → actual Basic verification before/equality/after. Include nil/zero, policy edits, provenance, microsecond/default clocks, v0/no-secret representations.
- Every method uses real verification. Three secret methods agree; JWT algorithm/claims/timing/JTI remain independent. Corrupt policy/state/clock is server_error, not invalid_client or unlimited.
- Code, refresh, device, CIBA polling and RFC requester recheck locked identity plus fresh time after final required locks. Denials preserve full code/request/token/family/audit state.
- Existing token validity, non-secret methods, issuer/online targets and queued push remain secret-independent; confidential refresh still authenticates.
- Rotation uses current locked provenance/policy and post-wait time; hash/verifier/time/deadline/version/audit commit/rollback together. V0 clears ALL old dates, v1 preserves unrelated state. Preserve no-old-proof, no-renewal, last-commit-winner behavior.
- Actual independent PostgreSQL sessions have distinct backend PIDs, exact pg_blocking_pids proof, later-lock NOWAIT probes, barrier clocks advanced only after observation and bounded cleanup. All five shipped finalizers have later-lock cases; client wait/committed replacement are separate.
- Reached write and audit failure compare complete durable state and return no success plaintext.
- Real finite-secret lifecycle event classes have positive observed counts before redaction assertions across audit, telemetry, logs, inspected results and errors.
- Literal public compatibility/architecture pass; changed rendered copy/docs match runtime and PRODUCT retired wording. No Phase 165 policy is added.

Any failed command or missing evidence remains a visible gap. ASVS level 1 high/critical mitigations block completion. All three unclassified edge-probe entries remain flagged unresolved in plans/source audit; concrete tests derive from requirements/CONTEXT rather than fabricated detector resolution.

## Manual-only checks

None planned. No external account/API setup or new irreversible decision is introduced; stored/wire format is already settled by the normative contract.

## Phase 164 plan 164-06 execution results

All Mix commands ran from the repository root with Elixir `1.18.4-otp-27`, OTP `27.3.4.15`, the supplied Mix/Hex homes, `MIX_ENV=test`, and the dedicated `LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation` database.

| Command | Result | Notes |
|---|---|---|
| C061 — finite-secret redaction and redaction matcher | **26 tests, 0 failures** | The lifecycle test observed positive DCR registration, token issuance, expiry-failure, and operator-rotation telemetry counts. It exercised a real finite DCR registration, successful authorization-code token exchange, equality rejection, and operator replacement; scanned captured telemetry, persisted audit rows, captured failure logs, and inspected public errors for plaintext, stored hashes, verifier material, and sensitive structural keys. |
| C062 — admin hint, rendered DCR page, vocabulary contract | **23 tests, 0 failures** | Blank and zero display no automatic expiry; positive duration remains readable; help explains prospective issue/replacement behavior; retired wording is recorded in `PRODUCT.md`. |
| C063a — guidance, architecture, public compatibility | **20 tests, 0 failures** | Re-run after the final documentation edits. |
| C063b — `mix test.fast` | **2 properties, 2,348 tests, 0 failures, 440 excluded, 6 skipped** | Normal suite only; the exclusions and skips remain visible and are not race or packaged-upgrade evidence. |
| C063c — explicit PostgreSQL race, rollback, and adapter-conformance files with `--include postgres_race` | **32 tests, 0 failures** | Included the three real PostgreSQL race modules, secret rollback coverage, and adapter conformance. The dedicated database was queried afterward: `current_database()` was `lockspire_phase164_validation`; counts for `secret-%` clients and related audit, token, JTI, interaction, device, and CIBA rows were all zero; singleton server-policy rows were zero. |

The separate PostgreSQL run includes all selected cases and passes with the explicit race tag enabled. Phase 164 plan 164-05's previously measured race-only subset was 11 tests, 0 failures, and no exclusions; C063c adds the rollback and adapter-conformance modules to that evidence. Adapter failures are covered by the conformance tests, and write/audit rollback failures by `client_lifetime_rollback_test.exs` and the rotation race suite.

The packaged clean-room upgrade proof was not rerun because plan 164-06 changed no schema, migration, installer, package, or generated-host input. Phase 166 retains the final packaged cross-phase proof. Management-token lifetime and recovery remain owned by Phase 165. The validation map records execution, not independent Nyquist or security sign-off; `nyquist_compliant` remains `false` until the independent audit supplies that evidence.

## Validation sign-off

- [ ] Every exact task selection passes on the named database.
- [ ] New tests exist and execute rather than being excluded.
- [ ] Actual independent-session races prove every blocker and durable outcome.
- [ ] Finite-secret event counts are nonzero and every channel is redacted.
- [ ] Normal counts/exclusions/skips and separate race counts are recorded.
- [ ] Adapter conformance and architecture/public compatibility pass.
- [ ] Changed guidance/copy matches behavior and scope.
- [ ] Independent coverage/security audit justifies nyquist_compliant.

Approval: pending implementation and independent audit.
