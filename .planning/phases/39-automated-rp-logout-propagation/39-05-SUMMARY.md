---
phase: 39-automated-rp-logout-propagation
plan: 05
subsystem: auth
tags: [oidc, logout, oban, ecto, phoenix]
requires:
  - phase: 39-01
    provides: logout propagation test contracts
  - phase: 39-03
    provides: durable logout event and delivery storage
  - phase: 39-04
    provides: named Oban runtime and backchannel delivery worker
provides:
  - protocol-owned logout completion orchestration
  - transactional logout event, delivery, and job persistence
  - thin `/end_session/complete` controller delegation with replay-safe event ids
affects: [phase-39-06, logout propagation, end-session completion]
tech-stack:
  added: [Oban migrations]
  patterns: [event-id keyed completion idempotency, transactional job-row persistence, controller-to-protocol delegation]
key-files:
  created:
    - lib/lockspire/protocol/logout_propagation.ex
    - priv/repo/migrations/20260429194500_add_oban_jobs.exs
    - .planning/phases/39-automated-rp-logout-propagation/39-05-SUMMARY.md
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/web/controllers/end_session_controller.ex
    - test/lockspire/protocol/logout_propagation_test.exs
    - test/lockspire/web/end_session_controller_test.exs
key-decisions:
  - "Replay-safe completion is keyed by a stable event_id carried through the signed host-return token."
  - "Backchannel enqueue persists an oban_jobs row inside the same repository transaction as logout event and delivery state."
  - "The repo now carries the missing Oban migration because queue-backed completion cannot work without a durable jobs table."
patterns-established:
  - "Protocol completion owns persistence, enqueue, audit, telemetry, and sid revocation ordering."
  - "The controller only verifies the handoff token, delegates completion, then redirects or renders."
requirements-completed: [SLO-03]
duration: 8 min
completed: 2026-04-29
---

# Phase 39 Plan 05: Automated RP Logout Propagation Summary

**Transactional `/end_session/complete` orchestration now snapshots logout targets, persists delivery intent, inserts durable Oban job rows, and reuses the same logout event on duplicate completion hits.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-29T19:48:14Z
- **Completed:** 2026-04-29T19:56:02Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `Lockspire.Protocol.LogoutPropagation.complete/1` to own the authoritative completion seam.
- Made backchannel delivery enqueue durable by persisting `oban_jobs` rows in the same transaction as logout events and deliveries.
- Kept `EndSessionController.complete/2` thin while preserving safe duplicate completion behavior through signed `event_id` handoff.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: logout completion orchestration tests** - `d5b3150` (`test`)
2. **Task 1 GREEN: transactional logout completion orchestration** - `cf06358` (`feat`)
3. **Task 2: thin controller delegation and replay safety** - `59ecd99` (`feat`)

## Files Created/Modified

- `lib/lockspire/protocol/logout_propagation.ex` - protocol-owned completion transaction, replay reuse, audit/telemetry emission, and typed frontchannel result data.
- `lib/lockspire/storage/ecto/repository.ex` - idempotent logout event lookup/reuse plus delivery listing and enqueue-state updates.
- `lib/lockspire/web/controllers/end_session_controller.ex` - signed `event_id` handoff and thin delegation to protocol completion.
- `test/lockspire/protocol/logout_propagation_test.exs` - TDD coverage for transactional persistence, enqueueing, telemetry, and replay safety.
- `test/lockspire/web/end_session_controller_test.exs` - controller coverage for delegated completion, invalid token fallback, and duplicate-hit safety.
- `priv/repo/migrations/20260429194500_add_oban_jobs.exs` - durable Oban storage migration needed for queue-backed completion.

## Decisions Made

- Reused durable logout events by `event_id` instead of re-deriving state from `sid`, which keeps duplicate completion hits safe without duplicating deliveries.
- Inserted the worker changeset directly through the repo transaction so logout event rows, delivery rows, and `oban_jobs` rows commit together.
- Left controller success-path behavior as redirect-or-render only; it never waits for RP HTTP delivery work.

## Verification

- `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs`
  Outcome: failed in RED before implementation, then passed after `LogoutPropagation.complete/1` and repository changes landed.
- `MIX_ENV=test mix test.setup`
  Outcome: applied the missing Oban migration and created the `oban_jobs` table in the test database.
- `MIX_ENV=test mix test test/lockspire/web/end_session_controller_test.exs`
  Outcome: failed in RED before controller delegation, then passed after `event_id` handoff and protocol delegation landed.
- `MIX_ENV=test mix test test/lockspire/protocol/logout_propagation_test.exs test/lockspire/web/end_session_controller_test.exs`
  Outcome: passed, `12 tests, 0 failures`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the missing Oban migration**
- **Found during:** Task 1 (Build transactional logout completion orchestration)
- **Issue:** Queue-backed completion could not persist backchannel jobs because the repo had no `oban_jobs` table migration.
- **Fix:** Added `priv/repo/migrations/20260429194500_add_oban_jobs.exs` and ran `MIX_ENV=test mix test.setup`.
- **Files modified:** `priv/repo/migrations/20260429194500_add_oban_jobs.exs`
- **Verification:** `mix test.setup` created `oban_jobs`, targeted protocol/controller tests passed with real job rows.
- **Committed in:** `cf06358`

**2. [Rule 3 - Blocking] Adjusted stale verification commands from the plan**
- **Found during:** Task 1 verification
- **Issue:** The plan’s `mix test ... -x` commands are not valid in this repo’s current Mix test task.
- **Fix:** Used the same targeted test commands without `-x` and recorded the actual commands in this summary.
- **Files modified:** `.planning/phases/39-automated-rp-logout-propagation/39-05-SUMMARY.md`
- **Verification:** All targeted tests passed with the corrected commands.
- **Committed in:** pending docs commit

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were required for the planned queue-backed completion path to execute and verify end to end. No scope broadening beyond the missing runtime prerequisite.

## Issues Encountered

- Oban queue persistence initially failed because the repo had not yet migrated the `oban_jobs` table.
- The standard `mix test -x` verification strings in the plan/validation docs are stale for the current Mix version.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `/end_session/complete` is now the authoritative, replay-safe propagation fork point.
- Phase 39-06 can render frontchannel UX from the typed completion result and build truthful discovery/admin follow-through on top of durable completion state.

## Self-Check

PASSED

- Verified created files exist: `lib/lockspire/protocol/logout_propagation.ex`, `lib/lockspire/web/controllers/end_session_controller.ex`, `priv/repo/migrations/20260429194500_add_oban_jobs.exs`, `.planning/phases/39-automated-rp-logout-propagation/39-05-SUMMARY.md`
- Verified task commits exist: `d5b3150`, `cf06358`, `59ecd99`

---
*Phase: 39-automated-rp-logout-propagation*
*Completed: 2026-04-29*
