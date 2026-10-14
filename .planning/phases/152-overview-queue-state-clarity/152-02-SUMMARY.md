---
phase: overview-queue-state-clarity
plan: "02"
subsystem: ui
tags: [phoenix-liveview, admin, device-authorizations, logout-deliveries, read-filter]

# Dependency graph
requires:
  - phase: 152-01
    provides: Allowlisted read-filter pattern for exact overview pivots.
provides:
  - Pending-device overview pivot and allowlisted read-only queue filter.
  - Logout-review overview pivot and allowlisted retryable/discarded filter.
  - Full-history default routes with filtered counts, empty states, and a return path.
affects: [overview-queue-state-clarity, admin-ui]

# Actuals (#2632)
actuals:
  tokens: 7959
  tasks: 2
  commits: 0
plan_head_before: 067235ab818c957b72446eca75c8965581ea7b45
plan_head_after: 067235ab818c957b72446eca75c8965581ea7b45

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Strict URL allowlists select read-only subsets from existing Admin list results.
    - Filtered counts and visible rows use the same status predicate; direct routes retain full history.

key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/overview_live/index.ex
    - lib/lockspire/web/live/admin/device_authorizations_live/index.ex
    - lib/lockspire/web/live/admin/logout_deliveries_live/index.ex
    - test/lockspire/web/live/admin/overview_live_test.exs
    - test/lockspire/web/live/admin/device_authorizations_live_test.exs
    - test/lockspire/web/live/admin/logout_deliveries_live_test.exs

key-decisions:
  - "Only status=pending narrows device authorization records; unknown values show full history."
  - "Only status=needs_review narrows logout deliveries to retryable or discarded records; unknown values show full history."
  - "Filtered views show a count of their own rows, hide all-history metrics, and provide a direct link back to all records."
  - "A read reload preserves the recognized filter, while read failures remain unavailable rather than empty."

patterns-established:
  - "Overview subset links must match the exact destination rows and count."
  - "URL filters are read-only allowlists; unknown values never create hidden or mutable behavior."

requirements-completed: [UI-03]
coverage:
  - id: D1
    description: "The pending-device overview count opens only pending device requests, while the direct route retains all recorded statuses."
    requirement: UI-03
    verification:
      - kind: integration
        ref: "test/lockspire/web/live/admin/overview_live_test.exs#overview renders task-centered status and journey links at both entry routes"
        status: pass
      - kind: integration
        ref: "test/lockspire/web/live/admin/device_authorizations_live_test.exs#pending filter shows only requests waiting for the user and links to full history"
        status: pass
    human_judgment: false
  - id: D2
    description: "The logout-attention overview count opens only retryable and discarded deliveries, while the direct route retains full history."
    requirement: UI-03
    verification:
      - kind: integration
        ref: "test/lockspire/web/live/admin/overview_live_test.exs#overview renders task-centered status and journey links at both entry routes"
        status: pass
      - kind: integration
        ref: "test/lockspire/web/live/admin/logout_deliveries_live_test.exs#needs-review filter shows only retryable and discarded deliveries"
        status: pass
    human_judgment: false
  - id: D3
    description: "Unknown filter values safely fall back to full history, and filtered empty/error states remain distinct and read-only."
    requirement: UI-03
    verification:
      - kind: integration
        ref: "test/lockspire/web/live/admin/device_authorizations_live_test.exs#unknown device status filters safely show the full history"
        status: pass
      - kind: integration
        ref: "test/lockspire/web/live/admin/logout_deliveries_live_test.exs#unknown logout status filters safely show the full history"
        status: pass
      - kind: integration
        ref: "test/lockspire/web/live/admin/device_authorizations_live_test.exs#device queue loading and failed reads remain distinct from successful empty"
        status: pass
      - kind: integration
        ref: "test/lockspire/web/live/admin/logout_deliveries_live_test.exs#failed logout reads show unavailable and a same-route retry"
        status: pass
    human_judgment: false

# Metrics
duration: 7min
completed: 2026-10-12
status: complete
---

# Phase 152 Plan 02: Pending Device and Logout Review Pivots Summary

**Pending-device and logout-review overview counts now open exact read-only subsets while the direct queue routes retain full history.**

## Performance

- **Duration:** 7 min (approximate)
- **Started:** 2026-10-12T14:14:00Z (approximate)
- **Completed:** 2026-10-12T14:21:09Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- The overview's pending-device link now opens `status=pending`; its row list contains only pending device authorization requests.
- The overview's logout-attention link now opens `status=needs_review`; its list contains only retryable and discarded deliveries.
- Both filters use strict allowlists over the existing list reads. Unknown values safely show full history, and the routes still show all statuses when opened without a recognized filter.
- Filtered pages show an exact count, hide all-history metrics, provide “View all …” navigation, and keep filtered empty and failed reads distinct. Reloading an unavailable read preserves the recognized filter.
- Existing redaction and read-only controls remain intact; no storage, protocol, dependency, or queue mutation changes were made.

## Task Commits

No commits were created. The parent orchestrator requested workspace-only changes; task and summary files remain unstaged for parent aggregation.

1. **Task 1: Filter device requests to the pending subset** — workspace edit; no commit per orchestrator instruction.
2. **Task 2: Filter logout deliveries that need review** — workspace edit; no commit per orchestrator instruction.

**Plan metadata:** Not committed per orchestrator instruction.

## Files Created/Modified

- `lib/lockspire/web/live/admin/overview_live/index.ex` — points pending-device and logout-attention counts to their matching URL filters.
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` — adds the allowlisted pending-only view, matching count, full-history link, and filter-preserving read reload.
- `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` — adds the allowlisted retryable/discarded view, matching count, full-history link, and filter-preserving read reload.
- `test/lockspire/web/live/admin/overview_live_test.exs` — verifies the count/link and confirms excluded historical device/logout records do not appear at the destination.
- `test/lockspire/web/live/admin/device_authorizations_live_test.exs` — covers exact membership, full-history defaults, unknown values, filtered empty state, and unavailable reads.
- `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` — covers exact membership, full-history defaults, unknown values, filtered empty state, and unavailable reads.

## Decisions Made

- Device filtering recognizes only `status=pending`; logout filtering recognizes only `status=needs_review` with the exact `retryable` or `discarded` predicate.
- Filtered views derive displayed rows and count from the same collection and hide metrics that describe full history.
- Unknown status values fall back to all recorded history rather than applying a partial or empty filter.
- Read reload links preserve a recognized filter and do not change any protocol or delivery record.

## Deviations from Plan

None. Error-state reload labels were clarified to say “Reload” and name the records, in line with the approved Phase 152 UI contract.

## Issues Encountered

- The first test run failed as expected because the overview still linked to the unfiltered routes. After implementing the filters and pivots, the focused suite passed.
- Existing compile warnings in unrelated modules remain unchanged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 is ready for parent aggregation. Plan 03 can build on the established strict URL-filter pattern; the read-only and redaction boundaries are unchanged.

## Self-Check: PASSED (workspace-only)

- Summary file created at the planned path; all six modified files exist.
- No task commits were expected under the parent orchestrator's workspace-only instruction; HEAD remains `067235ab818c957b72446eca75c8965581ea7b45`.
- `git diff --check` passed.
- `mix format --check-formatted` passed for all six files.
- Combined focused test run passed: `MIX_ENV=test mix test test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` — 26 tests.
- No stub, new endpoint, authorization path, data access pattern, schema change, or new dependency was introduced.

---
*Phase: overview-queue-state-clarity*
*Completed: 2026-10-12*
