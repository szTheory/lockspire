---
phase: 135-cohesive-internals
plan: 03
subsystem: storage
tags: [ecto, postgres, repository, oauth, par, consent, interactions]
requires:
  - phase: 135-02
    provides: explicit repo-injected Ecto aggregate collaborator pattern
provides:
  - Aggregate-owned interaction state queries and locked transitions
  - Aggregate-owned consent lifecycle and filtering
  - Atomic pushed authorization request lifecycle behind the stable Repository facade
affects: [authorization-flow, par, storage]
tech-stack:
  added: []
  patterns: [explicit Ecto repo collaborator dependency, aggregate-owned locked transactional mutation]
key-files:
  created:
    - lib/lockspire/storage/ecto/repository/interaction_store.ex
    - lib/lockspire/storage/ecto/repository/consent_store.ex
    - lib/lockspire/storage/ecto/repository/pushed_authorization_request_store.ex
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/storage/repository_test.exs
    - test/lockspire/protocol/pushed_authorization_request_test.exs
key-decisions:
  - "Repository remains the compatible configured-repo facade while authorization-session collaborators receive the resolved repo explicitly."
  - "Interaction transitions and PAR consumption own their FOR UPDATE query and transaction at the aggregate boundary."
requirements-completed: [COH-01, COH-02]
completed: 2026-08-27
status: complete
---

# Phase 135 Plan 03: Authorization-Session Storage Summary

Interaction, consent, and pushed authorization request persistence now have searchable aggregate owners while the public `Repository` contract remains behavior-compatible.

## Accomplishments

- Extracted interaction put/fetch/list/active lookup plus locked expected-state transitions into `InteractionStore`.
- Extracted consent create, filter/list, reuse, fetch, and idempotent locked revocation into `ConsentStore`.
- Extracted PAR put, active fetch, and locked atomic single-use consumption into `PushedAuthorizationRequestStore`.
- Kept all collaborators repo-explicit and returned only domain values or established errors to the facade.

## Verification

`mix compile --warnings-as-errors`

`mix test test/lockspire/storage/repository_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/protocol/authorization_flow_test.exs`

Result: 57 tests, 0 failures.

## Task Commits

1. Task 1 RED: `86fe130` — characterize session aggregate delegates.
2. Task 1 GREEN: `bea5a20` — extract interaction and consent stores.
3. Task 2 RED: `7c82ef1` — characterize atomic PAR delegate.
4. Task 2 GREEN: `b1ceb1e8` — extract atomic PAR store.

## Decisions Made

- `Repository` continues to resolve `Config.repo!/0`; session collaborators accept that concrete repo as their first dependency.
- The interaction and PAR `FOR UPDATE` query remains inside the same collaborator transaction as the state transition or consumption write.
- PAR preserves established expiry, client-binding, and consumed-request result normalization without exposing Ecto records.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Removed obsolete private facade helpers after their record types moved into aggregates.
   - **Found during:** Task 1 and Task 2 compilation.
   - **Fix:** Deleted stale interaction and PAR private helpers, including the unused repository delete wrapper.
   - **Verification:** `mix compile --warnings-as-errors` passed.

## Self-Check: PASSED

- All three aggregate modules exist.
- All four TDD commits are present.
- No stub markers were found in the plan-owned source or tests.
