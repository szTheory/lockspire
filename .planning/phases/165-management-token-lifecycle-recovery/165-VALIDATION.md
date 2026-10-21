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

Each command reference links to the exact runnable command(s) below, copied from the canonical task. All seven plans' behavioral tests and the corrected phase gates have passing evidence in their summaries. The initial failed run is preserved as historical evidence and superseded by clean corrective reruns. The DCR-10 spec-less probe remains unclassified as recorded in Plan 02, while the requirement's concrete issuance and policy behaviors are tested in tasks 165-02-01, 165-02-02, and final gate 165-07-01/02. This is not an automated coverage gap. Independent phase security, code review, and goal-backward verification remain subsequent audits and are not prerequisites for Nyquist coverage status. Every runnable task command has an immediately following observable fails_when in its PLAN.md.

| Task ID | Wave | Requirement | Secure Behavior | Test Type | Command | Threat Ref | Status |
|---|---|---|---|---|---|---|---|
| 165-01-01 | 1 | DCR-11 | Finite GET, post-lock expiry and safe effective extensions | E2E integration | [165-01-01](#command-165-01-01) | T-165-01, T-165-02 | pass — 3 tests, 0 failures (165-01-SUMMARY) |
| 165-01-02 | 1 | DCR-11 | All operations, app-state exceptions, non-renewal and final DELETE audit time | protocol + endpoint | [165-01-02](#command-165-01-02) | T-165-01 | pass — 44 tests, 0 failures (165-01-SUMMARY) |
| 165-01-03 | 1 | DCR-11 | Absent/invalid Bearer and redacted server errors | endpoint | [165-01-03](#command-165-01-03) | T-165-03 | pass — 19 tests, 0 failures (165-01-SUMMARY) |
| 165-02-01 | 2 | DCR-10 | Issuance snapshots, provenance and wire truth | integration + serializer | [165-02-01](#command-165-02-01) | T-165-05 | pass — 15 tests, 0 failures (165-02-SUMMARY) |
| 165-02-02 | 2 | DCR-10 | Real policy/admin write and reload, typed use rejection, malformed in-memory registration and corrupt-policy HTTP500 without issuance | persistence + protocol + router | [165-02-02](#command-165-02-02) | T-165-04 | pass — 35 tests, 0 failures (165-02-SUMMARY) |
| 165-03-01 | 3 | DCR-11, DCR-12 | Required body identity and atomic PUT hash/deadline/metadata/audit | E2E integration | [165-03-01](#command-165-03-01) | T-165-06, T-165-07, T-165-08 | pass — 3 tests, 0 failures (165-03-SUMMARY) |
| 165-03-02 | 3 | DCR-11, DCR-12 | Field/extension/secret rules, intake rejection and repeat-operation semantics | protocol + endpoint | [165-03-02](#command-165-03-02) | T-165-06 | pass — 62 tests, 0 failures (165-03-SUMMARY) |
| 165-04-01 | 4 | DCR-11, DCR-12 | Current-policy host recovery, stale snapshot and no app renewal | integration | [165-04-01](#command-165-04-01) | T-165-09, T-165-10 | pass — 9 tests, 0 failures (165-04-SUMMARY) |
| 165-04-02 | 4 | DCR-12 | Executed adapter round trips, dropping controls and whole-row promotion | adapter conformance | [165-04-02](#command-165-04-02) | T-165-10, T-165-11 | pass — 22 tests, 0 failures (165-04-SUMMARY) |
| 165-04-03 | 4 | DCR-11, DCR-12 | Client-write/audit rollback and no successful plaintext | fault injection | [165-04-03](#command-165-04-03) | T-165-08, T-165-11 | pass — 6 tests, 0 failures (165-04-SUMMARY) |
| 165-05-01 | 5 | DCR-11, DCR-12 | Real blocker, expiry and stale GET/PUT/DELETE | independent PostgreSQL | [165-05-01](#command-165-05-01) | T-165-12 | pass — 3 tests, 10 blocker observations (165-05-SUMMARY) |
| 165-05-02 | 5 | DCR-12 | One-winner PUT/PUT, PUT/recovery and recovery/recovery | independent PostgreSQL | [165-05-02](#command-165-05-02) | T-165-13 | pass — 2 tests, 5 blocker observations (165-05-SUMMARY) |
| 165-05-03 | 5 | DCR-11, DCR-12 | Concurrent secret/disable preservation and contended rollback | independent PostgreSQL | [165-05-03](#command-165-05-03) | T-165-14 | pass — 5 tests, 9 blocker observations (165-05-SUMMARY) |
| 165-06-01 | 6 | DCR-11, DCR-12 | Observed event counts, distinct actors and sensitive-material redaction | telemetry + audit | [165-06-01](#command-165-06-01) | T-165-15 | pass — included in 68-test combined run (165-06-SUMMARY) |
| 165-06-02 | 6 | DCR-11, DCR-12 | Confirmed one-time mounted recovery and host/public route boundary | LiveView + router | [165-06-02](#command-165-06-02) | T-165-09, T-165-16 | pass — included in 68-test combined run (165-06-SUMMARY) |
| 165-06-03 | 6 | DCR-11 | Prospective finite-token copy and retired vocabulary contract | rendered contracts | [165-06-03](#command-165-06-03) | T-165-16 | pass — included in 24-test policy/copy run (165-06-SUMMARY) |
| 165-07-01 | 7 | DCR-10, DCR-11, DCR-12 | Source-backed lifecycle and lost-response guidance | guidance contracts | [165-07-01](#command-165-07-01) | T-165-17 | pass — combined guidance/architecture/compatibility 21/0 after manifest correction |
| 165-07-02 | 7 | DCR-10, DCR-11, DCR-12 | Fast and explicit race/conformance/rollback evidence | phase gates | [165-07-02](#command-165-07-02) | T-165-18 | pass — explicit PostgreSQL 34/0; final fast suite 2412/0 |

## Plan 165-07 Execution Evidence

All commands used the dedicated `lockspire_phase165_validation` database and
the pinned Elixir/OTP, `MIX_HOME`, and `HEX_HOME` selectors shown in the command
catalog. No dependency installation was performed.

| Task | Command/result | Duration | Threat and evidence disposition |
|---|---|---:|---|
| 165-07-01 historical | Guidance + architecture suites: **15 tests, 0 failures**. Initial exact combined gate: **9 tests, 1 failure** at the additive API manifest. | 0.20s / 0.06s | Preserved as the first observed outcome; resolved by explicitly adding phase-approved `read/3`, `delete/3`, and `rotate_registration_access_token/2` extensions in `f91a975a`. |
| 165-07-01 rerun | Exact plan command with guidance, architecture, and compatibility contract: **21 tests, 0 failures**. Affected regression suites: **48 tests, 0 failures**. | 0.1s / 0.7s | T-165-17: all selected contracts pass. Host recovery remains on the approved host operation; protocol discovery behavior was not changed. |
| 165-07-02 historical fast | `mix test.fast`: **2,411 tests, 6 failures, 483 excluded, 6 skipped** in **139.4s**. | 139.4s | Preserved historical failed-run evidence. The singleton policy assumptions, stale UI wording assertion, and policy-dependent discovery assertion were corrected in `f91a975a`; the same run also exposed five order-dependent issuer/mount-path failures, corrected in `0d2b0051`. Full causes and commit references are in `deferred-items.md`. |
| 165-07-02 corrected fast | `mix test.fast`: **2 properties, 2,411 tests, 0 failures, 483 excluded, 6 skipped** in **134.0s**. | 134.0s | T-165-18: zero-failure full fast gate. Exclusions and skips remain reported but are not credited as race evidence. |
| 165-07-02 explicit PostgreSQL | All six selected management race, rollback, adapter conformance and promotion modules with `--include postgres_race`: **34 tests, 0 failures**. The three 165-05 race modules account for **24 previously observed PostgreSQL blocker relationships** (10 + 5 + 9); the current run also executed the selected rollback and adapter suites. | 1.0s | T-165-18: explicit race inclusion executed positive counts and passed; race proof is independent of the fast-suite result. |

The corrected full-suite run also re-executed the exact combined gate after the
test-environment fix: **21 tests, 0 failures**. The recovery LiveView and
private-key JWT modules passed together: **9 tests, 0 failures**. Formatting
checks passed for all modified Elixir files. The original failed-run logs remain
historical evidence; the results above supersede their gate status.

The 165-07-01 RED attempt added source-backed guidance assertions and ran the
exact focused command before the documentation changes. ExUnit reported the
new target test failing at the missing `Lockspire.mount_path` guidance
assertion (1 test, 1 failure; exit 2), not during compilation or fixture setup.
The default ExUnit console format is not accepted by the GSD RED evidence
classifier, so this is recorded as a semantic RED observation only; no
classifier-approved RED is claimed. This task changes documentation and
contract assertions only and adds no runtime implementation. Its test commit
precedes the documentation commit.

### Security-audit follow-up (superseding evidence)

The post-plan security audit found T-165-03 and T-165-17. T-165-03 is fixed by
`63041a41`: an expired management credential now takes precedence over missing
or invalid PUT metadata, while current-row locking, row-ID and token-hash
comparison, preparation-before-final-clock ordering, and final-clock expiry
evaluation remain intact. The observed regression was HTTP 400 where the
contract requires HTTP 401 / `invalid_token`. T-165-17 is fixed by `2c88994b`:
recovery preserves app expiry and expired-app PUT remains HTTP 403 /
`registration_expired`.

After these fixes, the access integration module passed **4 tests, 0
failures**, guidance passed **6 tests, 0 failures**, and all **27** test files
changed since `ee7f8d2c` passed with **217 tests, 0 failures** (integration
files explicitly included). The exact combined guidance/architecture/
compatibility gate passed **21/0**; the explicit PostgreSQL race/rollback/
adapter batch passed **34/0**. The final `mix test.fast` supersedes earlier
clean-run counts with **2 properties, 2,412 tests, 0 failures, 484 excluded,
and 6 skipped** in 136.3s. Earlier failed-run evidence remains historical and
is not erased. Independent security review, code review, and goal-backward
verification are still open; these results do not complete Phase 165.

**Gate status:** the combined guidance/compatibility gate, explicit PostgreSQL
batch, and full fast suite pass. Keep this validation record `draft`,
`nyquist_compliant: false`, and `wave_0_complete: false` while independent
phase-wide security, code-review, and goal-backward verification remain open.
Phase 166 remains responsible for final packaged cross-phase proof, final
security/guidance audit and umbrella-todo closure.

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

- [x] Initialize `lockspire_phase165_validation` using the setup command before tests; 165-01-SUMMARY records successful setup (“Migrations already up”).
- [ ] Add focused tests and any minimal clock/race fixtures in the implementation tasks that first need them; plans must name every new test path and establish creation before invocation.
- Existing ExUnit and PostgreSQL helpers provide infrastructure; no new framework or dependency is needed.

## Manual-Only Verifications

All selected phase behaviors have automated verification. Host authorization and one-time display are exercised through the existing host/admin test seams. Phase 166 owns final packaged cross-phase journeys and final guidance proof.

## Validation Sign-Off

- [x] Every final task has automated verification or an explicit Wave 0 dependency.
- [x] No three consecutive tasks lack automated verification.
- [x] All referenced test paths exist or have explicit preceding creation ownership.
- [x] No watch-mode flags; real PostgreSQL blocker evidence for race claims.
- [x] Actual feedback timings recorded during execution.
- [x] `nyquist_compliant: true` set only after the applicable audit.

**Approval:** automated coverage audit complete. All 18 task rows map to executed behavioral verification; requirements DCR-10, DCR-11, and DCR-12 have direct automated coverage. Corrective final gates passed: combined guidance/compatibility 21/0, explicit PostgreSQL 34/0, and fast suite 2 properties + 2,411 tests/0 failures (483 excluded, 6 skipped). Independent security, code-review, and goal-backward reports remain for their next hooks.

## Validation Audit 2026-10-21

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
