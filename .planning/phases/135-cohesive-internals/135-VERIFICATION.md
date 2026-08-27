---
phase: 135-cohesive-internals
verified: 2026-08-27T20:14:16Z
status: gaps_found
score: 2/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Authorization-code redemption, refresh reuse, DCR-plus-audit writes, and key transitions retain their atomic rollback and concurrency behavior."
    status: failed
    reason: "The required DB-backed concurrent authorization-code redemption characterization crashes before exercising a contender, so it proves neither concurrency nor exactly-one-winner semantics."
    artifacts:
      - path: test/lockspire/storage/repository_atomicity_test.exs
        issue: "Each Task calls SQL Sandbox.allow/3 with itself as the owner instead of the checked-out test process; allow/3 returns :not_found at line 67."
    missing:
      - "Repair the Sandbox sharing arrangement and make the concurrent test execute ten contenders, asserting one durable winner and nine already-redeemed outcomes."
  - truth: "The stable token facade delegates authentication, resource selection, issuance, persistence, polling, and observability to focused collaborators."
    status: failed
    reason: "GrantSupport remains a 1,736-line implementation owner for authorization-code/device/CIBA redemption, durable persistence, audit construction, and telemetry emission rather than a compatibility-only seam."
    artifacts:
      - path: lib/lockspire/protocol/token_exchange/internal/grant_support.ex
        issue: "It defines persist_authorization_code_grant, persist_device_authorization_grant, persist_ciba_authorization_grant, transact_with_audit_event, emit_success, and failure-audit functions instead of delegating these responsibilities to GrantPersistence and GrantObservability."
    missing:
      - "Move the remaining redemption/persistence/observability orchestration into focused collaborators and have grant coordinators compose them directly or through thin compatibility delegates."
  - truth: "Internal collaborators use explicit dependency bundles without capability sniffing or runtime environment branching, while existing injection remains compatible."
    status: failed
    reason: "The internal GrantSupport collaborator still adapts request option bags itself and reads global Config/Observability directly; the architecture fitness test exempts that file, leaving the stated invariant unenforced."
    artifacts:
      - path: lib/lockspire/protocol/token_exchange/internal/grant_support.ex
        issue: "LegacyOptions.from_request occurs at lines 100, 133, and 166; Config.issuer!/0 and Config.account_resolver!/0 occur at lines 1007 and 1073; direct Observability.emit calls occur throughout lines 1117-1223."
      - path: test/lockspire/architecture_fitness_test.exs
        issue: "The token-option rule scans all token internals except LegacyOptions, but its allowed GrantSupport compatibility assertion does not prohibit the remaining option/global-dependency ownership."
    missing:
      - "Restrict LegacyOptions adaptation to the one adapter, thread Dependencies through the remaining GrantSupport compatibility calls, inject config/telemetry, and extend fitness so this regression fails."
---

# Phase 135: Cohesive Internals Verification Report

**Phase Goal:** Storage and grant internals are navigable, explicit, and behaviorally stable behind their existing public facades.
**Verified:** 2026-08-27T20:14:16Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Aggregate-specific Ecto behavior is navigable behind the existing Repository facade. | VERIFIED | `Repository` delegates its declared storage behavior families to sixteen aggregate modules; it has no Ecto query/schema/changeset/lock constructs. `mix qa.architecture` passed its facade and synthetic-regression checks. |
| 2 | Code redemption, refresh reuse, DCR-plus-audit, and key transitions retain atomic rollback and concurrency behavior. | FAILED | Direct one-winner, refresh-reuse, DCR rollback, and key-transition tests exist, but the actual concurrent redemption test fails at `repository_atomicity_test.exs:67` with `:not_found` from `Sandbox.allow/3`; its claimed concurrency proof is not executable. |
| 3 | Stable token exchange delegates focused authentication, resource selection, issuance, persistence, polling, and observability responsibilities. | FAILED | `ClientAuthentication`, `ResourceSelection`, `GrantPolling`, `TokenIssuer`, `GrantPersistence`, and `GrantObservability` exist, but the authorization-code/device/CIBA paths still call a 1,736-line `GrantSupport` that owns redemption, persistence, audit, and telemetry logic. |
| 4 | Explicit dependencies replace capability sniffing/runtime environment behavior while legacy injection remains compatible. | FAILED | `Dependencies` and `LegacyOptions` compatibility tests pass, and no `function_exported?/3`/`Mix.env/0` occurs. But GrantSupport itself reads legacy request options and global Config/Observability, contrary to the one-adapter explicit-dependency requirement. |
| 5 | Five grants preserve endpoint responses/errors, tokens, audit events, and telemetry. | VERIFIED | Characterization test (4/0) covers authorization-code, refresh, device, CIBA, and RFC 8693 public flows; controller test (18/0) verifies their mounted OAuth wire contracts; helper asserts durable tokens/audit/telemetry for the five-flow spine. |

**Score:** 2/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/storage/ecto/repository.ex` | Public facade over aggregate owners | VERIFIED | Behavior-complete, aggregate delegates wired, with configuration kept at `repo/0`. |
| `lib/lockspire/storage/ecto/repository/*_store.ex` | Aggregate-specific Ecto ownership | VERIFIED | Sixteen substantive aggregate modules own query/lock/transaction work. |
| `test/lockspire/storage/repository_atomicity_test.exs` | DB rollback and concurrency characterization | STUB FOR CONCURRENCY | Four single-process atomicity cases execute; its essential Task/Sandbox concurrency case crashes before redemption. |
| `lib/lockspire/protocol/token_exchange/internal/{dependencies,legacy_options}.ex` | Explicit bundle and compatibility adapter | PARTIAL | The bundle/adapter are substantive and tested, but GrantSupport bypasses the intended boundary. |
| `lib/lockspire/protocol/token_exchange/internal/{client_authentication,resource_selection,grant_polling,token_issuer,grant_persistence,grant_observability}.ex` | Focused token collaborators | PARTIAL | Modules exist and are used, but not by the complete authorization-code/device/CIBA orchestration. |
| `test/lockspire/protocol/token_exchange/characterization_test.exs` | Five-flow behavioral spine | VERIFIED | 4 tests passed independently. |
| `test/lockspire/web/token_controller_test.exs` | Mounted endpoint response contracts | VERIFIED | 18 tests passed independently. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Repository` | aggregate Ecto stores | facade delegation | WIRED | `mix qa.architecture` passes and AST test requires all aggregate aliases. |
| public `TokenExchange` | typed `Dependencies` | `LegacyOptions.from_request` at stable facade boundary | WIRED | All five grant dispatches call `with_dependencies/3`; dependency compatibility test passed. |
| authorization/device/CIBA grants | focused persistence/observability | coordinator composition | NOT_WIRED | They delegate broad work to `GrantSupport`; that module contains the persistence/audit/telemetry implementation instead of calling the corresponding focused owners. |
| standard QA | architecture fitness | `mix.exs` `qa.architecture` alias | WIRED | Alias invokes zero-cycle script and architecture/compatibility tests; independently passed. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Architecture ownership/explicit-dependency gate | `mix qa.architecture` | 13 tests, 0 failures; no cycles | PASS, but incomplete against GrantSupport scope |
| Public compatibility and dependency injection | `mix test ...dependencies_test.exs ...compatibility_baseline_contract_test.exs --trace` | 9 tests, 0 failures | PASS |
| Five stable-facade grant characterizations | `mix test ...characterization_test.exs --trace` | 4 tests, 0 failures | PASS |
| Mounted token endpoint response contracts | `mix test ...token_controller_test.exs --trace` | 18 tests, 0 failures | PASS |
| Concurrent authorization-code redemption | `mix test ...repository_atomicity_test.exs:49 --trace` | 1 test, 1 failure: `Sandbox.allow/3` returned `:not_found` | FAIL |
| Zero dependency cycles | `mix xref graph --format cycles` | `No cycles found` | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| COH-01 | 02–05, 09 | Aggregate-specific Ecto implementation behind Repository | SATISFIED | Pure delegate facade plus aggregate-store modules and passing AST facade gate. |
| COH-02 | 01, 02, 05, 08, 09 | Atomic code/refresh/DCR/key behavior under rollback and concurrency proof | BLOCKED | The required concurrent code-redemption proof crashes. |
| COH-03 | 06–09 | Focused token grant responsibilities behind stable facade | BLOCKED | GrantSupport still owns substantial redemption/persistence/observability behavior. |
| COH-04 | 06–09 | Explicit bundles without capability sniffing/runtime environment behavior; compatible injection | BLOCKED | GrantSupport reads legacy options and Config/Observability directly, outside LegacyOptions/bundle construction. |
| COH-05 | 01, 06–09 | Five-flow response/error/token/audit/telemetry characterization | SATISFIED | Five-flow facade and controller characterizations pass independently. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `test/lockspire/storage/repository_atomicity_test.exs` | 67 | Broken SQL Sandbox ownership in concurrency test | BLOCKER | Leaves exactly-one-winner behavior unproven and makes the planned combined gate fail. |
| `lib/lockspire/protocol/token_exchange/internal/grant_support.ex` | 1–1736 | Broad compatibility module retains core protocol responsibilities | BLOCKER | COH-03's intended responsibility split is incomplete. |
| `lib/lockspire/protocol/token_exchange/internal/grant_support.ex` | 100, 133, 166, 1007, 1073, 1117–1223 | Legacy option/global configuration/telemetry access outside explicit dependencies | BLOCKER | COH-04's explicit dependency boundary is incomplete; current fitness gives a false-green result. |

### Gaps Summary

Three blocking gaps remain. First, fix the SQL Sandbox setup so the DB-backed concurrency proof actually runs. Second, complete the authorization-code/device/CIBA extraction out of `GrantSupport` into `GrantPersistence` and `GrantObservability` (and focused grant coordinators) instead of only extracting refresh-path collaborators. Third, make `LegacyOptions` the sole option-bag adapter and inject configuration/telemetry into the remaining compatibility calls; extend architecture fitness to scan those paths.

The full Phase 135 focused command also fails because of the concurrency-test failure, even though the individual five-flow/controller and compatibility checks pass.

---

_Verified: 2026-08-27T20:14:16Z_
_Verifier: the agent (gsd-verifier)_
