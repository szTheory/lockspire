---
phase: 86
plan: 1
subsystem: protocol
tags: [oauth, oidc, dcr, logout, rfc7592]
requires: []
provides:
  - RFC 7592 update persistence for the four logout propagation fields
  - Full-replace clearing semantics for omitted logout metadata
affects: [phase-86-02, phase-86-03, dcr, logout]
tech-stack:
  added: []
  patterns: [reuse Admin.Clients logout normalization in RFC 7592 update persistence]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/registration_management.ex
    - test/support/fixtures/dcr_fixtures.ex
    - test/lockspire/protocol/registration_management_test.exs
key-decisions:
  - "RFC 7592 update now reuses the same logout normalization path as create and operator-managed updates."
patterns-established:
  - "Omitted logout metadata clears typed client fields under full-replace semantics."
requirements-completed: [DCRM-02]
duration: 10min
completed: 2026-05-24
---

# Phase 86 Plan 1 Summary

**RFC 7592 management update now persists, replaces, and clears logout propagation metadata on the typed client fields**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-24T16:32:00Z
- **Completed:** 2026-05-24T16:42:30Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Reused `Admin.Clients.normalize_logout_metadata/1` inside the RFC 7592 update write path.
- Persisted all four logout propagation fields during management PUT updates.
- Added protocol proof for set, replace, and clear behavior under full-replace semantics.

## Task Commits

1. **Task 86-01-01: thread normalized logout metadata into update persistence** - `305c7ca`
2. **Task 86-01-02: enforce omission clears for optional logout fields** - `305c7ca`
3. **Task 86-01-03: add focused management-update coverage for set, replace, and clear** - `305c7ca`

## Files Created/Modified

- `lib/lockspire/protocol/registration_management.ex` - applies normalized logout metadata during RFC 7592 full-replace updates
- `test/support/fixtures/dcr_fixtures.ex` - adds replacement logout metadata fixture coverage
- `test/lockspire/protocol/registration_management_test.exs` - proves logout metadata set, replace, and clear flows

## Decisions Made

- The RFC 7592 seam keeps a single logout normalization truth by reusing `Admin.Clients.normalize_logout_metadata/1`.

## Deviations from Plan

None.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Lifecycle invariants can now be proved on a write path that actually persists logout metadata truthfully.

---
*Phase: 86*
*Completed: 2026-05-24*
