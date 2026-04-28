---
phase: "32"
plan: "01"
subsystem: "auth"
tags: ["oauth", "device-flow", "ecto", "postgres", "tdd"]
requires:
  - phase: "31"
    provides: "Durable device-authorization lifecycle state, verification handles, and row-locked host approval transitions"
provides:
  - "Durable poll interval state on device authorizations with next allowed poll timestamps"
  - "Row-locked repository callbacks for device-code lookup, sticky slow_down backpressure, and single-winner consume"
  - "Executable repository proof for early polling, terminal classification, and replay-safe consume"
affects:
  - "Phase 32 token exchange grant routing"
  - "Phase 32 discovery and HTTP polling contract"
tech-stack:
  added: []
  patterns: ["durable poll-window state", "row-locked consume", "repository-first TDD"]
key-files:
  created:
    - "priv/repo/migrations/20260428130000_extend_lockspire_device_authorizations_polling_state.exs"
    - ".planning/phases/32-polling-token-issuance/32-01-SUMMARY.md"
  modified:
    - "lib/lockspire/domain/device_authorization.ex"
    - "lib/lockspire/storage/device_authorization_store.ex"
    - "lib/lockspire/storage/ecto/device_authorization_record.ex"
    - "lib/lockspire/storage/ecto/repository.ex"
    - "test/lockspire/storage/ecto/repository_device_authorization_test.exs"
key-decisions:
  - "Device authorizations now carry both effective poll interval seconds and next_poll_allowed_at so polling truth stays durable across nodes and deploys."
  - "Too-early polls widen the next window from the current allowed timestamp, not from wall-clock now, to preserve sticky RFC 8628 slow_down behavior."
  - "Approved device authorizations remain poll-readable as approved_ready and are consumed only through a separate row-locked callback."
patterns-established:
  - "Device poll evaluation should return typed repository outcomes and reserve OAuth public error shaping for the protocol layer."
  - "Device-flow success paths must lock and transition the authorization row before later token issuance work reuses it."
requirements-completed: ["DEV-09"]
duration: 5min
completed: 2026-04-28
---

# Phase 32 Plan 01: Polling Token Issuance Summary

**Durable device poll-window state, row-locked slow_down backpressure, and single-winner consume semantics for Phase 32 token redemption**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-28T11:58:00Z
- **Completed:** 2026-04-28T12:03:04Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added durable poll state to device authorizations with a default 5-second interval and deterministic first allowed poll timestamp.
- Extended the Ecto repository with device-code lookup, row-locked poll evaluation, sticky `slow_down` widening, and single-winner `approved -> consumed` transitions.
- Added repository proof for early polling, repeated backpressure, compliant pending polls, terminal classifications, approved-ready behavior, and replay-safe consume.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend durable polling-state fields and storage callbacks** - `72a5dce` (`feat`)
2. **Task 2 RED: Add failing repository polling and consume specs** - `66fc8b5` (`test`)
3. **Task 2 GREEN: Implement row-locked poll evaluation and single-winner consume** - `cfbfc29` (`feat`)

## Files Created/Modified

- `lib/lockspire/domain/device_authorization.ex` - Adds durable poll interval fields and deterministic initial poll-window helpers at issuance time.
- `lib/lockspire/storage/device_authorization_store.ex` - Extends the storage contract with device-code lookup, typed poll outcomes, and consume callbacks.
- `lib/lockspire/storage/ecto/device_authorization_record.ex` - Persists poll interval state and maps it back into the domain model.
- `priv/repo/migrations/20260428130000_extend_lockspire_device_authorizations_polling_state.exs` - Adds the poll-state columns, backfills existing rows, and indexes `next_poll_allowed_at`.
- `lib/lockspire/storage/ecto/repository.ex` - Implements row-locked poll evaluation and single-winner consume semantics.
- `test/lockspire/storage/ecto/repository_device_authorization_test.exs` - Proves sticky `slow_down`, terminal poll outcomes, and replay-safe consume behavior.

## Decisions Made

- Kept poll-timing truth on the device-authorization row instead of controller or process memory so Phase 32 remains node-safe.
- Returned typed repository outcomes such as `:pending`, `:slow_down`, `:approved_ready`, and `:client_mismatch` so later protocol work can map them into RFC-tight token errors without losing private reason detail.
- Required consume to operate by verification handle under row lock and reject all non-approved states with `:invalid_state`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Migrated the test database before verifying the widened schema**
- **Found during:** Task 1 (Extend durable polling-state fields and storage callbacks)
- **Issue:** The repository test file failed immediately because the test database did not yet have the new `effective_poll_interval_seconds` and `next_poll_allowed_at` columns.
- **Fix:** Ran `MIX_ENV=test mix ecto.migrate` before rerunning the targeted repository test file.
- **Files modified:** None
- **Verification:** `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs`
- **Committed in:** n/a

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for truthful verification only. No scope creep.

## Issues Encountered

- Widening the storage behaviour before Task 2 temporarily produced compile warnings until the repository callbacks were implemented in the GREEN commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Lockspire.Protocol.TokenExchange` can now consume durable repository outcomes for `authorization_pending`, `slow_down`, terminal invalid-grant paths, and winning redemption.
- Discovery and controller work in later Phase 32 plans can rely on Postgres-backed poll and consume truth instead of reconstructing timing rules in protocol code.

## Self-Check: PASSED

- `.planning/phases/32-polling-token-issuance/32-01-SUMMARY.md` FOUND
- `72a5dce` FOUND
- `66fc8b5` FOUND
- `cfbfc29` FOUND

---
*Phase: 32-polling-token-issuance*
*Completed: 2026-04-28*
