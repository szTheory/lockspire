---
phase: 15-authorization-consumption-and-truthful-surface
plan: 02
subsystem: auth
tags: [oauth, oidc, par, discovery, docs]
requires:
  - phase: 14-pushed-request-intake
    provides: mounted PAR endpoint and Lockspire-issued request_uri lifecycle
provides:
  - truthful PAR discovery metadata gated by mounted routes
  - public docs that scope PAR to Lockspire-issued request_uri use on auth-code plus PKCE
  - preserved preview boundary against JAR-by-value, DCR, device flow, and hosted-auth claims
affects: [phase-15-tests, release-readiness, docs]
tech-stack:
  added: []
  patterns: [mounted-route discovery truth, narrow support-contract wording]
key-files:
  created: []
  modified: [lib/lockspire/protocol/discovery.ex, README.md, docs/supported-surface.md, SECURITY.md]
key-decisions:
  - "Advertise PAR only through pushed_authorization_request_endpoint when /par is mounted."
  - "Document PAR only as Lockspire-issued request_uri support on the existing authorization code plus PKCE flow."
patterns-established:
  - "Discovery metadata remains route-derived instead of feature-flagged."
  - "Support-facing docs must qualify PAR support and explicitly keep adjacent request-object and hosted-auth breadth out of scope."
requirements-completed: [PAR-03]
duration: 3min
completed: 2026-04-24
---

# Phase 15 Plan 02: Authorization Consumption and Truthful Surface Summary

**Mounted-route PAR discovery plus preview docs that scope support to Lockspire-issued request_uri use on the existing authorization code + PKCE flow**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-24T14:30:00Z
- **Completed:** 2026-04-24T14:32:26Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `pushed_authorization_request_endpoint` to discovery metadata through the existing mounted-route truth path.
- Updated README, supported-surface, and security wording to describe only the shipped PAR slice.
- Preserved explicit exclusions for request-object-by-value, generic external `request_uri`, device flow, dynamic client registration, hosted auth, and broader CIAM positioning.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add truthful PAR discovery metadata without widening request-object claims** - `09bd15c` (feat)
2. **Task 2: Update support-facing docs to describe the exact supported PAR slice and preserve the preview boundary** - `3fc4451` (docs)

## Files Created/Modified

- `lib/lockspire/protocol/discovery.ex` - publishes the PAR discovery endpoint only when `/par` is mounted.
- `README.md` - narrows top-level PAR wording to Lockspire-issued `request_uri` support on auth-code plus PKCE.
- `docs/supported-surface.md` - moves PAR into the supported surface only for the shipped server-issued reference slice.
- `SECURITY.md` - aligns the supported security surface with the same narrow PAR claim.

## Decisions Made

- Discovery continues to derive endpoint truth from mounted routes, so PAR support is advertised only via `pushed_authorization_request_endpoint`.
- Public docs must say the supported PAR slice explicitly rather than using unqualified "PAR supported" shorthand.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 15 plan 03 can now add discovery and docs contract tests against the truthful PAR surface published here.
- No blockers were introduced by this plan.

## Self-Check: PASSED

- Found `.planning/phases/15-authorization-consumption-and-truthful-surface/15-02-SUMMARY.md`.
- Verified task commits `09bd15c` and `3fc4451` exist in git history.
