---
phase: "31"
plan: "01"
subsystem: "storage"
tags: ["device-authorization", "verification", "ecto", "tdd"]
dependency_graph:
  requires:
    - phase: "30"
      provides: "Core device authorization domain records, hashing, and repository insertion"
  provides:
    - "Durable verification handles and lifecycle state on device authorizations"
    - "Repository callbacks for canonicalized lookup and row-locked transitions"
    - "Integration proof for approve, deny, and stale retry outcomes"
  affects:
    - "Phase 31 protocol verification lookup APIs"
    - "Phase 31 host-owned /verify controller seam"
tech_stack:
  added: []
  patterns: ["Ecto.Enum lifecycle state", "FOR UPDATE transitions", "TDD"]
key_files:
  created:
    - "priv/repo/migrations/20260428090000_extend_lockspire_device_authorizations_verification_state.exs"
    - ".planning/phases/31-host-owned-verification-ui-seam/31-01-SUMMARY.md"
  modified:
    - "lib/lockspire/domain/device_authorization.ex"
    - "lib/lockspire/storage/device_authorization_store.ex"
    - "lib/lockspire/storage/ecto/device_authorization_record.ex"
    - "lib/lockspire/storage/ecto/repository.ex"
    - "test/lockspire/storage/ecto/repository_device_authorization_test.exs"
key_decisions:
  - "Canonicalize every user code by stripping separators and whitespace, uppercasing, then hashing the canonical value."
  - "Approval and denial mutate durable state through opaque verification handles instead of raw user codes."
  - "Repository transitions use FOR UPDATE plus expected-state checks to reject stale retries with :invalid_state."
requirements_completed: ["DEV-04"]
metrics:
  duration_minutes: 10
  completed_date: "2026-04-28"
---

# Phase 31 Plan 01: Host-Owned Verification UI Seam Summary

**One-liner:** Added durable device-verification state, opaque handles, and row-locked repository transitions that let later `/verify` seams approve or deny without reusing raw user codes.

## Task Breakdown

- **Task 1: Extend durable device-authorization verification state** - Added canonicalized `user_code` hashing, generated `verification_handle` values, lifecycle status/timestamps, behaviour callbacks, and the additive verification-state migration.
- **Task 2: Implement race-safe repository lookup and transition rules** - Added RED integration coverage for canonicalized lookup and transition races, then implemented repository lookup-by-hash, lookup-by-handle, and `FOR UPDATE` transition semantics.

## Task Commits

1. **Task 1: Extend durable device-authorization verification state** - `be80f25` (`feat`)
2. **Task 2 RED: Add failing verification repository tests** - `4523efa` (`test`)
3. **Task 2 GREEN: Implement race-safe repository lookup and transition rules** - `2196724` (`feat`)

## Files Created/Modified

- `lib/lockspire/domain/device_authorization.ex` - Canonicalizes `user_code`, hashes the canonical value, and issues opaque verification handles with pending lifecycle defaults.
- `lib/lockspire/storage/device_authorization_store.ex` - Defines behaviour callbacks for verification lookup and transition operations.
- `lib/lockspire/storage/ecto/device_authorization_record.ex` - Persists verification handles, lifecycle status, subject binding, and terminal timestamps.
- `priv/repo/migrations/20260428090000_extend_lockspire_device_authorizations_verification_state.exs` - Extends durable storage with verification lifecycle columns and indexes.
- `lib/lockspire/storage/ecto/repository.ex` - Implements handle/hash lookup and row-locked expected-state transitions.
- `test/lockspire/storage/ecto/repository_device_authorization_test.exs` - Proves canonicalized lookup, handle persistence, approve/deny transitions, and stale retry rejection.

## Decisions Made

- Used `DeviceAuthorization.hash_user_code/1` as the shared canonicalization-and-hash rule so formatted and unformatted user-code input lands on one durable lookup key.
- Stored lifecycle state as `Ecto.Enum` values in the schema while keeping the migration default as `"pending"` for additive rollout safety.
- Returned `:invalid_state` from repository transitions once a record leaves `:pending`, keeping stale submit classification in Lockspire storage instead of later controller code.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Applied the new test migration before repository verification**
- **Found during:** Task 1 verification
- **Issue:** `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs` failed because the test database had not applied the new `status` and `verification_handle` columns yet.
- **Fix:** Ran `MIX_ENV=test mix ecto.migrate` before rerunning the planned verification command.
- **Files modified:** None
- **Verification:** `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs`
- **Committed in:** None (environmental fix only)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. The deviation only aligned the test database with the new migration so planned verification could run.

## Issues Encountered

- The new behaviour callbacks on `Lockspire.Storage.DeviceAuthorizationStore` produced temporary compile warnings until Task 2 implemented the repository side. That was expected during the Task 1 -> Task 2 transition and resolved in the GREEN commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Device authorizations now expose canonicalized lookup keys, opaque handles, and durable lifecycle transitions needed by the Phase 31 protocol lookup layer.
- Later `/verify` controller and protocol slices can rely on repository-owned pending/terminal classification instead of mutating raw `user_code`.

## Self-Check: PASSED

- `.planning/phases/31-host-owned-verification-ui-seam/31-01-SUMMARY.md` FOUND
- `priv/repo/migrations/20260428090000_extend_lockspire_device_authorizations_verification_state.exs` FOUND
- `be80f25` FOUND
- `4523efa` FOUND
- `2196724` FOUND

