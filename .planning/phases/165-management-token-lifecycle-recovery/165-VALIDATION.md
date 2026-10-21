---
phase: "165"
slug: "management-token-lifecycle-recovery"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-21"
---

# Phase 165 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Ecto SQL sandbox, independent PostgreSQL transactions |
| Config files | `mix.exs`, `config/test.exs`, `test/test_helper.exs` |
| Quick run | Use the environment below with `mix test test/lockspire/protocol/registration_management_test.exs --max-failures 1 --timeout 55000` |
| Full suite | Same environment with `mix test.fast`, then explicit `--include postgres_race` management race tests |
| Runtime | Not measured in planning; focused feedback target 60 seconds, full-suite budget 1800 seconds |

Use the prior phase's verified runtime/dependency selectors, changing only the dedicated database:

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test.setup
```

Prefix every Mix verification command with the same `env` assignments. Setup creates the isolated test database before tests. Never substitute the shared default database. Research checked runtime/dependencies/PostgreSQL availability; planning does not claim execution results.

## Sampling Rate

- After each task: run its focused automated verification with an observable non-zero/zero-tests failure signal.
- After each wave: run all focused suites changed in that wave.
- Before phase verification: run `mix test.fast` plus explicit independent-transaction management race and adapter rollback/conformance suites. The fast suite does not replace race proof.
- Feedback target: 60 seconds for a focused batch; split a growing batch. Do not use sleeps as concurrency evidence.

## Per-Task Verification Map

Each command reference links to the exact runnable command(s) below, copied from the canonical task. All statuses remain pending: planning has not run implementation verification. Every runnable task command has an immediately following observable fails_when in its PLAN.md.

| Task ID | Wave | Requirement | Secure Behavior | Test Type | Command | Threat Ref | Status |
|---|---|---|---|---|---|---|---|
| 165-01-01 | 1 | DCR-11 | Finite GET, post-lock expiry and safe effective extensions | E2E integration | [165-01-01](#command-165-01-01) | T-165-01, T-165-02 | pending |
| 165-01-02 | 1 | DCR-11 | All operations, app-state exceptions, non-renewal and final DELETE audit time | protocol + endpoint | [165-01-02](#command-165-01-02) | T-165-01 | pending |
| 165-01-03 | 1 | DCR-11 | Absent/invalid Bearer and redacted server errors | endpoint | [165-01-03](#command-165-01-03) | T-165-03 | pending |
| 165-02-01 | 2 | DCR-10 | Issuance snapshots, provenance and wire truth | integration + serializer | [165-02-01](#command-165-02-01) | T-165-05 | pending |
| 165-02-02 | 2 | DCR-10 | Real policy/admin write and reload, typed use rejection, malformed in-memory registration and corrupt-policy HTTP500 without issuance | persistence + protocol + router | [165-02-02](#command-165-02-02) | T-165-04 | pending |
| 165-03-01 | 3 | DCR-11, DCR-12 | Required body identity and atomic PUT hash/deadline/metadata/audit | E2E integration | [165-03-01](#command-165-03-01) | T-165-06, T-165-07, T-165-08 | pending |
| 165-03-02 | 3 | DCR-11, DCR-12 | Field/extension/secret rules, intake rejection and repeat-operation semantics | protocol + endpoint | [165-03-02](#command-165-03-02) | T-165-06 | pending |
| 165-04-01 | 4 | DCR-11, DCR-12 | Current-policy host recovery, stale snapshot and no app renewal | integration | [165-04-01](#command-165-04-01) | T-165-09, T-165-10 | pending |
| 165-04-02 | 4 | DCR-12 | Executed adapter round trips, dropping controls and whole-row promotion | adapter conformance | [165-04-02](#command-165-04-02) | T-165-10, T-165-11 | pending |
| 165-04-03 | 4 | DCR-11, DCR-12 | Client-write/audit rollback and no successful plaintext | fault injection | [165-04-03](#command-165-04-03) | T-165-08, T-165-11 | pending |
| 165-05-01 | 5 | DCR-11, DCR-12 | Real blocker, expiry and stale GET/PUT/DELETE | independent PostgreSQL | [165-05-01](#command-165-05-01) | T-165-12 | pending |
| 165-05-02 | 5 | DCR-12 | One-winner PUT/PUT, PUT/recovery and recovery/recovery | independent PostgreSQL | [165-05-02](#command-165-05-02) | T-165-13 | pending |
| 165-05-03 | 5 | DCR-11, DCR-12 | Concurrent secret/disable preservation and contended rollback | independent PostgreSQL | [165-05-03](#command-165-05-03) | T-165-14 | pending |
| 165-06-01 | 6 | DCR-11, DCR-12 | Observed event counts, distinct actors and sensitive-material redaction | telemetry + audit | [165-06-01](#command-165-06-01) | T-165-15 | pending |
| 165-06-02 | 6 | DCR-11, DCR-12 | Confirmed one-time mounted recovery and host/public route boundary | LiveView + router | [165-06-02](#command-165-06-02) | T-165-09, T-165-16 | pending |
| 165-06-03 | 6 | DCR-11 | Prospective finite-token copy and retired vocabulary contract | rendered contracts | [165-06-03](#command-165-06-03) | T-165-16 | pending |
| 165-07-01 | 7 | DCR-10, DCR-11, DCR-12 | Source-backed lifecycle and lost-response guidance | guidance contracts | [165-07-01](#command-165-07-01) | T-165-17 | pending |
| 165-07-02 | 7 | DCR-10, DCR-11, DCR-12 | Fast and explicit race/conformance/rollback evidence | phase gates | [165-07-02](#command-165-07-02) | T-165-18 | pending |

### Exact command catalog

The setup command in165-01-01 must run before any suite. All paths resolve from the checkout root; new suite creation is owned by the task naming that file. Commands are intentionally explicit to preserve the prior-phase runtime/dependency selectors.

<a id="command-165-01-01"></a>

**165-01-01 — Wave 1**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test.setup
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/integration/management_token_lifetime_access_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-01-02"></a>

**165-01-02 — Wave 1**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/protocol/registration_management_test.exs test/integration/management_token_lifetime_access_test.exs test/integration/app_lifetime_management_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-01-03"></a>

**165-01-03 — Wave 1**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/web/controllers/registration_controller_test.exs test/integration/app_lifetime_management_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-02-01"></a>

**165-02-01 — Wave 2**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/integration/management_token_lifetime_registration_test.exs test/lockspire/web/registration_json_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-02-02"></a>

**165-02-02 — Wave 2**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/protocol/management_token_lifetime_policy_test.exs test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/protocol/dcr_policy_test.exs test/integration/management_token_lifetime_registration_test.exs --max-failures 1 --timeout 55000
```

Required scenarios in the selected management policy suite: accepted policy write/reload; rejected typed Repository/admin writes with unchanged durable state; form casts persisted through the admin API; resolver/domain rejection; malformed in-memory Registration.register with no issuance; and a real Router POST reading a sandbox-corrupted management duration of -1, returning HTTP500/server_error without invalid_token or credential/success-audit disclosure. The selected ServerPolicyRecord suite independently exercises existing management3600/nil Ecto round trips. Record positive counts for these cases; suite names alone do not establish boundary coverage. Task165-02-02's fails_when applies to every assertion above; status remains pending until execution.

<a id="command-165-03-01"></a>

**165-03-01 — Wave 3**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/integration/management_token_lifetime_update_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-03-02"></a>

**165-03-02 — Wave 3**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/protocol/management_token_request_contract_test.exs test/lockspire/web/controllers/registration_controller_test.exs test/lockspire/protocol/registration_management_test.exs test/integration/app_lifetime_management_test.exs test/integration/management_token_lifetime_update_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-04-01"></a>

**165-04-01 — Wave 4**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/integration/management_token_lifetime_recovery_test.exs test/integration/management_token_lifetime_update_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-04-02"></a>

**165-04-02 — Wave 4**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-04-03"></a>

**165-04-03 — Wave 4**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/storage/management_token_rollback_test.exs test/lockspire/client_lifecycle_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-05-01"></a>

**165-05-01 — Wave 5**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include postgres_race test/lockspire/storage/management_token_client_wait_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-05-02"></a>

**165-05-02 — Wave 5**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include postgres_race test/lockspire/storage/management_token_replacement_race_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-05-03"></a>

**165-05-03 — Wave 5**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include postgres_race test/lockspire/storage/management_token_mutation_race_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-06-01"></a>

**165-06-01 — Wave 6**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/protocol/dcr_telemetry_redaction_test.exs test/lockspire/protocol/dcr_audit_attribution_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-06-02"></a>

**165-06-02 — Wave 6**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/admin_router_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-06-03"></a>

**165-06-03 — Wave 6**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-07-01"></a>

**165-07-01 — Wave 7**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000
```

<a id="command-165-07-02"></a>

**165-07-02 — Wave 7**

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test.fast
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include postgres_race test/lockspire/storage/management_token_client_wait_test.exs test/lockspire/storage/management_token_replacement_race_test.exs test/lockspire/storage/management_token_mutation_race_test.exs test/lockspire/storage/management_token_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs --max-failures 1 --timeout 55000
```

### Ordering and evidence constraints

- Seven plans, eighteen tasks, seven waves. Verify165-01-01's production GET tracer before expansion.
- Plan05 and Plan06 are serialized despite disjoint files: independent test processes share the dedicated database and mutable server-policy singleton. All scoped schema/adapter helpers already exist; no dependency or migration install is planned.
- Plan03 retains its two-task PUT slice and24,000 calibrated/48,000 raw estimate. Its measured source reads are included in raw work; a68,000-token fixed/context allowance gives92,000 calibrated total against the resolved200,000-token window and100,000 smart zone. The116,000 uncalibrated stress case leaves84,000 headroom. Its PLAN.md records byte counts, calibration and bounded history/research reads; no estimate reduction or task/dependency change was made.
- Every race uses independent backend PIDs and the expected pg_blocking_pids relationship before advancing an injected clock. Every telemetry stage needs positive observed event counts before redaction scans.
- DCR-10/unclassified remains a flagged unresolved assumption inPlan02. The other three probe rows have explicit contract truths inPlans03/05. Two descriptor-less prohibitions remain flagged-unverified inPlans04/07; no check path is fabricated.
- All T-165-01 through T-165-18 mitigations have task/command ownership above; T-165-SC in each plan records no package install task.

## Wave 0 Requirements

- [ ] Initialize `lockspire_phase165_validation` using the setup command before tests.
- [ ] Add focused tests and any minimal clock/race fixtures in the implementation tasks that first need them; plans must name every new test path and establish creation before invocation.
- Existing ExUnit and PostgreSQL helpers provide infrastructure; no new framework or dependency is needed.

## Manual-Only Verifications

All selected phase behaviors have automated verification. Host authorization and one-time display are exercised through the existing host/admin test seams. Phase 166 owns final packaged cross-phase journeys and final guidance proof.

## Validation Sign-Off

- [ ] Every final task has automated verification or an explicit Wave 0 dependency.
- [ ] No three consecutive tasks lack automated verification.
- [ ] All referenced test paths exist or have explicit preceding creation ownership.
- [ ] No watch-mode flags; real PostgreSQL blocker evidence for race claims.
- [ ] Actual feedback timings recorded during execution.
- [ ] `nyquist_compliant: true` set only after the applicable audit.

**Approval:** pending execution and validation audit.
