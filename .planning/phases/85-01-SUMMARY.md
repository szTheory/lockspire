---
phase: 85
plan: 1
subsystem: api
tags: [oauth, oidc, dcr, logout, validation]
requires: []
provides:
  - RFC 7591 intake validation for Lockspire logout propagation metadata
  - Shared DCR logout metadata validator wired to existing client/logout primitives
affects: [phase-85-02, phase-85-03, dcr, logout]
tech-stack:
  added: []
  patterns: [shared logout metadata validation for DCR intake]
key-files:
  created: []
  modified:
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/protocol/registration.ex
    - test/support/fixtures/dcr_fixtures.ex
    - test/lockspire/protocol/registration_test.exs
key-decisions:
  - "DCR intake now reuses Lockspire client/logout URI primitives instead of maintaining a DCR-only truth model."
  - "Logout session_required fields are strict JSON booleans at registration intake."
patterns-established:
  - "Validate redirect URIs before frontchannel logout origin checks so field attribution stays stable."
requirements-completed: [DCR-01, DCR-02, DCR-03, DCR-04, DCR-05]
duration: 25min
completed: 2026-05-24
---

# Phase 85 Plan 1 Summary

**RFC 7591 registration now accepts and validates the shipped logout propagation metadata with Lockspire-native URI and origin semantics**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-24T16:00:00Z
- **Completed:** 2026-05-24T16:25:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Replaced the blanket logout metadata rejection with explicit DCR intake validation.
- Reused existing logout URI and frontchannel origin semantics from the client/admin layer.
- Added positive and negative RFC 7591 protocol coverage for URI, boolean, paired-field, and origin-mismatch cases.

## Task Commits

1. **Task 85-01-01: shared logout metadata validator for DCR wire input** - `0c5a70c`
2. **Task 85-01-02: reuse existing client/logout primitives** - `0c5a70c`
3. **Task 85-01-03: extend fixtures and protocol tests** - `0c5a70c`

## Files Created/Modified

- `lib/lockspire/admin/clients.ex` - exposed shared logout metadata validation and normalization helpers
- `lib/lockspire/protocol/registration.ex` - validated logout metadata and removed the unsupported-in-slice rejection path
- `test/support/fixtures/dcr_fixtures.ex` - added valid and invalid logout metadata fixture builders
- `test/lockspire/protocol/registration_test.exs` - covered positive registration and negative logout metadata failure shapes

## Decisions Made

- Lockspire keeps a single logout validation truth by reusing the existing URI/origin checks already used for durable client updates.
- DCR intake rejects stringified booleans to preserve explicit RFC-shaped wire semantics.

## Deviations from Plan

None.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Registration create can now accept the four logout fields safely.
- The persistence and response/readback proofs can build directly on the normalized create path.

---
*Phase: 85*
*Completed: 2026-05-24*
