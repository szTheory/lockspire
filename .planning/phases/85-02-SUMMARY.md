---
phase: 85
plan: 2
subsystem: database
tags: [oauth, oidc, dcr, logout, persistence]
requires:
  - phase: 85-01
    provides: validated DCR logout metadata intake
provides:
  - Typed persistence of logout propagation metadata on self-registered clients
  - Round-trip proof that logout metadata lives on durable client fields, not extension metadata
affects: [phase-85-03, dcr, storage]
tech-stack:
  added: []
  patterns: [persist normalized DCR fields on Lockspire.Domain.Client typed attributes]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/registration.ex
    - test/lockspire/protocol/registration_test.exs
    - test/lockspire/storage/ecto/client_record_test.exs
key-decisions:
  - "Logout propagation metadata stays on typed client fields instead of sidecar metadata."
patterns-established:
  - "Use ClientRecord round-trip tests to prove DCR persistence follows the durable client schema."
requirements-completed: [DCR-01, DCR-02, DCR-03, DCR-04]
duration: 10min
completed: 2026-05-24
---

# Phase 85 Plan 2 Summary

**Accepted logout propagation metadata now persists through DCR create onto typed client fields and survives repository round-trips**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-24T16:25:00Z
- **Completed:** 2026-05-24T16:35:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Threaded normalized logout metadata into the DCR create path before persistence.
- Proved repository round-trips preserve the four logout fields on `%Lockspire.Domain.Client{}`.
- Kept the phase boundary narrow by leaving generic extension metadata and RFC 7592 write semantics unchanged.

## Task Commits

1. **Task 85-02-01: thread normalized logout metadata into registration create** - `0c5a70c`
2. **Task 85-02-02: add protocol and record round-trip proof** - `51b1123`
3. **Task 85-02-03: keep typed-field-only persistence boundary** - `51b1123`

## Files Created/Modified

- `lib/lockspire/protocol/registration.ex` - persisted normalized logout metadata onto typed client fields
- `test/lockspire/protocol/registration_test.exs` - asserted successful DCR registration returns the persisted logout values
- `test/lockspire/storage/ecto/client_record_test.exs` - proved logout metadata round-trips through `ClientRecord`

## Decisions Made

- The DCR create path now builds durable logout state directly on `%Lockspire.Domain.Client{}` before handing off to `Admin.Clients.create_dcr_client/1`.

## Deviations from Plan

None.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- DCR success and management-read serializers can now expose persisted logout metadata truthfully from stored client state.

---
*Phase: 85*
*Completed: 2026-05-24*
