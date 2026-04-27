---
phase: 15-authorization-consumption-and-truthful-surface
plan: 01
subsystem: auth
tags: [oauth, par, authorization, ecto, phoenix]
requires:
  - phase: 14-pushed-request-intake
    provides: durable Lockspire-issued PAR references keyed by request_uri_hash
provides:
  - atomic PAR consume semantics with expiry and client-binding enforcement
  - `/authorize` resolution of Lockspire-issued `request_uri` values into canonical validated params
  - protocol coverage for replay, wrong-client burn, and mixed-input rejection
affects: [authorization-flow, authorize-controller, phase-15-plan-03]
tech-stack:
  added: []
  patterns: [transactional PAR consume-once repository semantics, canonical `%Validated{}` handoff for PAR-backed requests]
key-files:
  created: []
  modified:
    - lib/lockspire/storage/pushed_authorization_request_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/protocol/authorization_request.ex
    - test/lockspire/protocol/authorization_request_test.exs
key-decisions:
  - "Burn PAR references inside the repository transaction even on wrong-client or expired use so replay resistance does not depend on controller logic."
  - "Resolve Lockspire-issued PAR references into canonical authorization params before validation so `AuthorizationFlow` keeps the existing `%Validated{}` contract."
patterns-established:
  - "PAR consumption is a storage-level consume-once operation keyed by hashed request_uri values."
  - "PAR-backed `/authorize` requests reject mixed raw parameters instead of merging ambiguous sources of truth."
requirements-completed: [PAR-02]
duration: 5min
completed: 2026-04-24
---

# Phase 15 Plan 01: Authorization Consumption Summary

**Single-use PAR resolution for `/authorize` with repository-enforced burn semantics and unchanged `%Validated{}` handoff**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-24T14:24:43Z
- **Completed:** 2026-04-24T14:29:20Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added an atomic `consume_pushed_authorization_request/2` store contract and Ecto implementation that locks, deletes, and validates PAR references in one transaction.
- Taught `AuthorizationRequest.validate/1` to resolve only Lockspire-issued `request_uri` values, reject mixed raw input, and rebuild canonical params before normal validation.
- Extended protocol coverage for successful PAR-backed validation plus expiry, replay, wrong-client burn, and mixed-input rejection.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add atomic PAR-consumption protocol coverage and the store/repository contract it depends on** - `b946243` (feat)
2. **Task 2: Resolve PAR-issued `request_uri` values inside `AuthorizationRequest` while preserving the canonical validated contract** - `5d83807` (feat)

TDD red gate:

1. **Failing PAR authorize consumption coverage** - `c9dceff` (test)

## Files Created/Modified
- `lib/lockspire/storage/pushed_authorization_request_store.ex` - adds the atomic PAR consume callback used by `/authorize`.
- `lib/lockspire/storage/ecto/repository.ex` - enforces single-use PAR consumption with row locking, expiry checks, and wrong-client burn semantics.
- `lib/lockspire/protocol/authorization_request.ex` - resolves Lockspire-issued `request_uri` references into canonical params and preserves the existing validated contract.
- `test/lockspire/protocol/authorization_request_test.exs` - covers repository consume semantics and PAR-backed `/authorize` success and negative paths.

## Decisions Made
- Used browser-safe `invalid_request` errors for stale, replayed, wrong-client, and unsupported `request_uri` values because no redirect-safe context should be trusted before PAR resolution succeeds.
- Restricted PAR-backed `/authorize` input to `client_id` plus `request_uri`; any additional raw authorization parameters are rejected before store lookup.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `MIX_ENV=test mix test.fast` surfaced two out-of-scope failures in `test/lockspire/protocol/pushed_authorization_request_test.exs`. Those tests hard-code `expires_at` values on `2026-04-24 14:05:00Z`, which are expired on the current test clock. Logged in `deferred-items.md` and left unchanged because they predate this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 15 plan 02 can now publish truthful PAR discovery/docs against a real `/authorize` consumption path, and plan 03 can exercise the end-to-end PAR-backed authorization flow against the canonical validated contract.

## Self-Check: PASSED
