---
phase: 85
plan: 3
subsystem: api
tags: [oauth, oidc, dcr, logout, json]
requires:
  - phase: 85-01
    provides: validated DCR logout metadata intake
  - phase: 85-02
    provides: persisted logout metadata on typed client fields
provides:
  - DCR create and read responses that expose persisted logout metadata truthfully
  - Serializer omission semantics for absent logout metadata
affects: [phase-86, dcr, management]
tech-stack:
  added: []
  patterns: [serialize logout metadata directly from stored client state]
key-files:
  created: []
  modified:
    - lib/lockspire/web/registration_json.ex
    - test/lockspire/web/registration_json_test.exs
    - test/lockspire/web/controllers/registration_controller_test.exs
    - test/lockspire/protocol/registration_management_test.exs
key-decisions:
  - "DCR JSON responses include logout session_required fields only when the corresponding URI is present."
patterns-established:
  - "Registration JSON surfaces derive logout metadata directly from persisted client fields."
requirements-completed: [DCR-05, DCRM-01]
duration: 12min
completed: 2026-05-24
---

# Phase 85 Plan 3 Summary

**DCR create and management-read responses now serialize the stored logout propagation metadata directly from persisted client state**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-24T16:35:00Z
- **Completed:** 2026-05-24T16:47:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Extended the DCR JSON serializer to emit the four logout metadata fields from stored clients.
- Added end-to-end controller proof for create and read response truth.
- Added management-read proof for already-persisted clients, not only DCR-created ones.

## Task Commits

1. **Task 85-03-01: extend registration JSON serializer** - `5cfc8d6`
2. **Task 85-03-02: add end-to-end create/read proof** - `5cfc8d6`
3. **Task 85-03-03: prove read truth for persisted clients** - `5cfc8d6`

## Files Created/Modified

- `lib/lockspire/web/registration_json.ex` - serialized stored logout metadata with omission semantics for absent fields
- `test/lockspire/web/registration_json_test.exs` - covered presence and absence response cases
- `test/lockspire/web/controllers/registration_controller_test.exs` - proved successful create and subsequent read expose the same stored values
- `test/lockspire/protocol/registration_management_test.exs` - proved management read reflects persisted logout metadata unchanged

## Decisions Made

- DCR response truth is driven solely by persisted client state; no response-only reconstruction layer was introduced.

## Deviations from Plan

None.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Phase 86 can focus strictly on RFC 7592 full-replace update semantics, RAT rotation, and broader proof.

---
*Phase: 85*
*Completed: 2026-05-24*
