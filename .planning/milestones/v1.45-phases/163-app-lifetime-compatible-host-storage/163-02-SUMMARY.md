---
phase: 163-app-lifetime-compatible-host-storage
plan: "02"
subsystem: database
tags: [elixir, ecto, client-lifetime, storage-adapters, transactions]

requires:
  - phase: 163-app-lifetime-compatible-host-storage
    provides: Client lifetime fields and eligibility semantics from plan 163-01
provides:
  - Typed v1 client lifetime adapter support and current-row lock contract
  - Role-specific shared transaction authority validation during token dependency adaptation
  - Focused adapter round-trip, lock-order, fail-closed and rollback conformance tests
affects: [163-03, 163-04, 163-05, 163-06, 163-07, 163-08, 163-09, 163-10, 163-11, 163-12, 163-13, 163-14]

actuals:
  tokens: 18734.25
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - Adapter-owned versioned lifetime declaration adapted once into a typed dependency
    - Transaction authority maps identify the module responsible for each participating store role
    - Stable client ID ordering for row locks inside an active transaction

key-files:
  created:
    - lib/lockspire/storage/client_lifetime.ex
    - test/lockspire/storage/client_lifetime_conformance_test.exs
  modified:
    - lib/lockspire/storage/client_store.ex
    - lib/lockspire/storage/ecto/repository/client_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/storage/transaction_store.ex
    - lib/lockspire/protocol/token_exchange/internal/dependencies.ex
    - lib/lockspire/protocol/token_exchange/internal/legacy_options.ex
    - test/lockspire/protocol/token_exchange/dependencies_test.exs

key-decisions:
  - "Lifetime support is accepted only from an adapter-owned v1 declaration with a current-row guard and matching transaction authority."
  - "Transaction authority identifies store roles explicitly; capability declarations and callback presence do not certify atomicity."

requirements-completed: [] # Phase-wide requirements remain pending upgrade and consumer proof
coverage:
  - id: D1
    description: Client adapters preserve explicit v0/v1 versions and finite or unlimited lifetime deadlines through storage round trips.
    requirement: DCR-13
    verification:
      - kind: integration
        ref: test/lockspire/storage/client_lifetime_conformance_test.exs#built-in finite, unlimited and explicit v0 round trips
        status: pass
    human_judgment: false
  - id: D2
    description: Token dependencies reject undeclared or mismatched transaction authorities and share rollback across guarded client, token, grant and audit writes.
    requirement: DCR-14
    verification:
      - kind: integration
        ref: test/lockspire/storage/client_lifetime_conformance_test.exs#rollback and authority conformance cases
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-10-20
status: complete
---

# Phase 163 Plan 02: Adapter Lifetime and Transaction Authority Summary

**Typed app-lifetime adapter declarations now require current-row guards and a declared shared transaction authority across participating stores.**

## Performance

- **Duration:** approximately 15 minutes
- **Started:** 2026-10-20 (exact start time was not captured)
- **Completed:** 2026-10-20T23:40:22Z
- **Tasks:** 2
- **Files modified:** 9 implementation and test files

## Accomplishments

- Added `ClientLifetime` adaptation and validation for explicit v0/v1 client state, rejecting missing/unknown versions, malformed dates and legacy app/management deadlines.
- Added adapter-owned lifetime contract and guarded current-row lock callbacks. The Ecto repository facade delegates to an Ecto implementation that requires an active transaction and locks deduplicated IDs in stable client ID order.
- Added role-specific transaction authority declarations tied to the configured Ecto repo. Dependency adaptation validates the typed lifetime contract and checks the declared participants required by each grant before durable work.
- Added real-storage conformance for v1 finite/unlimited and v0 round trips, expired/disabled reads, lock order, transaction requirements, and client/token/grant/audit rollback. A deliberately split fixture that leaks child writes fails the atomicity conformance check.
- Updated existing dependency test doubles to declare their supported adapter and transaction contract explicitly.

## Task Commits

The parent executor owns commits for this shared-workspace task. Task commit hashes are pending parent execution; no commit was made by this agent.

1. **Task 1: Make the built-in and custom client adapters execute the same guarded contract** — pending parent commit.
2. **Task 2: Validate composed transaction authority during dependency adaptation** — pending parent commit.

## Files Created/Modified

- `lib/lockspire/storage/client_lifetime.ex` — typed adapter contract and authoritative state validation.
- `lib/lockspire/storage/client_store.ex` — documented lifetime declaration and row guard callbacks.
- `lib/lockspire/storage/ecto/repository/client_store.ex` — active-transaction check and sorted current-row locks.
- `lib/lockspire/storage/ecto/repository.ex` — facade delegation and Ecto repo transaction authority declaration.
- `lib/lockspire/storage/transaction_store.ex` — explicit transaction authority callback.
- `lib/lockspire/protocol/token_exchange/internal/dependencies.ex` — typed lifetime field and grant-specific participant checks.
- `lib/lockspire/protocol/token_exchange/internal/legacy_options.ex` — single boundary adaptation and actionable server errors for unsupported authority.
- `test/lockspire/storage/client_lifetime_conformance_test.exs` — storage, adapter, authority, rollback and negative conformance tests.
- `test/lockspire/protocol/token_exchange/dependencies_test.exs` — explicit declarations for existing custom dependency fixtures.

## Decisions Made

- A lifetime-aware adapter must declare version 1, its matching transaction authority, and the current-row lock callback before it can be adapted.
- Transaction participants are represented by store role so grant validation can identify the actual client, token, grant, audit and transaction modules required for that operation.
- Existing test adapters were updated to declare the contract rather than relying on implicit capabilities.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated existing dependency fixtures to declare lifetime and transaction support**
- **Found during:** Task 2
- **Issue:** Dependency adaptation correctly rejected legacy test fixtures that supplied custom stores without the newly required explicit authority contract.
- **Fix:** Added narrow lifetime and participant declarations to those fixtures while retaining their original capability assertions.
- **Files modified:** `test/lockspire/protocol/token_exchange/dependencies_test.exs`
- **Verification:** Focused dependency tests passed (3 tests, 0 failures).
- **Commit:** Pending parent executor.

**Total deviations:** 1 auto-fixed (Rule 3 - Blocking). The adjustment updates only fixtures affected by the new adapter contract.

## Issues Encountered

- The first RED run exposed a timestamp precision mismatch in the new test assertion. The assertion was corrected to compare UTC instants; later focused runs passed.
- Full `mix test.fast` is deferred to the phase-final run as directed by the parent executor. No unrelated `.planning/state.json` or `.planning/config.json` changes were edited.

## TDD Gate Compliance

- Tests were created before implementation and the focused suite was run before the API existed. That first failure was caused by timestamp precision, so it is not valid semantic RED evidence for the planned behavior.
- No RED/GREEN commits were produced in this subtask because the parent executor explicitly owns all commits. The parent executor should record the eventual task commit hashes and handle the plan-level TDD commit gate.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/architecture_fitness_test.exs --max-failures 1` — passed, 19 tests, 0 failures.
- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/protocol/token_exchange/dependencies_test.exs --max-failures 1` — passed, 22 tests, 0 failures.
- `git diff --check` — passed.

## Next Phase Readiness

- Plans 163-03 onward can consume the typed `client_lifetime` dependency and `lock_clients/1` guard. Each custom adapter must declare the same role-specific authority and pass its own conformance before use.
- Phase 164 owns shared-secret enforcement, Phase 165 owns registration-token lifecycle, and Phase 166 owns the complete packaged, race and release proof. This plan does not close those boundaries.

---
*Phase: 163-app-lifetime-compatible-host-storage*
*Plan: 02*
*Completed: 2026-10-20*

## Self-Check: PASSED

- Summary and all nine owned implementation/test files exist.
- No task commit hashes exist yet; commits and hash recording are parent-owned as directed.

Parent implementation commit: `c3e546e30e29e523518bb4e7dc86acefe8b3d320`; fresh parent run:22 tests,0 failures.
