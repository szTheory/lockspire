---
phase: 18-authorization-path-enforcement
plan: 01
subsystem: auth
tags: [oauth, oidc, par, phoenix, protocol, testing]
requires:
  - phase: 17-effective-par-policy-model
    provides: durable server/client PAR policy state and shared effective-policy resolution
provides:
  - required-PAR enforcement at the `/authorize` validation seam
  - redirect-safe versus browser-safe classification for missing PAR under required policy
  - protocol tests covering required-PAR rejection, optional-PAR continuity, and preserved invalid `request_uri` semantics
affects: [18-02 browser proof, authorization flow, observability]
tech-stack:
  added: []
  patterns: [shared PAR policy resolver reuse, protocol-owned redirect safety classification, focused protocol matrix]
key-files:
  created: [.planning/phases/18-authorization-path-enforcement/18-01-SUMMARY.md]
  modified:
    - lib/lockspire/protocol/authorization_request.ex
    - test/lockspire/protocol/authorization_request_test.exs
key-decisions:
  - "Load durable server policy inside AuthorizationRequest and reuse ParPolicy.resolve_effective_policy/2 instead of creating a second resolver."
  - "Keep missing-PAR failures on invalid_request with an internal :par_required_request_uri reason code while classifying redirect safety in protocol code."
patterns-established:
  - "Required PAR is enforced before ordinary direct-request validation but after client lookup."
  - "Invalid supplied request_uri values continue to use existing invalid_request_uri handling even when PAR is required."
requirements-completed: [PARPOL-03]
duration: 4min
completed: 2026-04-24
---

# Phase 18 Plan 01: Authorization Path Enforcement Summary

**Effective PAR policy enforcement in `/authorize` with a dedicated missing-PAR reason code and preserved invalid `request_uri` semantics**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-24T17:13:00Z
- **Completed:** 2026-04-24T17:17:26Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added a RED protocol matrix for required-PAR redirect-safe rejection, browser-safe rejection, client/global policy overrides, and preserved invalid `request_uri` behavior.
- Enforced effective PAR policy inside `Lockspire.Protocol.AuthorizationRequest` using the shared Phase 17 resolver and durable server policy lookup.
- Kept the browser-safe versus redirect-safe split inside protocol code with `invalid_request` on missing PAR and `:par_required_request_uri` as the internal diagnostic.

## Task Commits

1. **Task 1: Extend protocol tests to pin required-PAR enforcement and reason-code separation** - `68851a6` (`test`)
2. **Task 2: Enforce effective PAR policy inside AuthorizationRequest without creating a second resolver** - `1664df5` (`feat`)

## Files Created/Modified

- `test/lockspire/protocol/authorization_request_test.exs` - Added focused required-PAR coverage and telemetry assertions at the protocol seam.
- `lib/lockspire/protocol/authorization_request.ex` - Loaded server policy, resolved effective PAR policy, and rejected direct required-PAR requests before ordinary validation.
- `.planning/phases/18-authorization-path-enforcement/18-01-SUMMARY.md` - Recorded execution, verification, and task commit history for Plan 18-01.

## Decisions Made

- Resolved effective PAR policy in `AuthorizationRequest` with `Repository.get_server_policy/0` plus `ParPolicy.resolve_effective_policy/2` to keep runtime and admin policy truth aligned.
- Used `validate_redirect_uri/2` only as the trust gate for redirect safety, while returning the dedicated policy reason code on both redirect-safe and browser-safe missing-PAR outcomes.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The RED test run failed on four new required-PAR cases before implementation, which confirmed the validation gap and satisfied the TDD gate.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `AuthorizationRequest` now owns the required-PAR runtime decision and exposes stable protocol tuples for Phase 18-02 browser and integration proof.
- No in-scope blockers were found in the owned files.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/18-authorization-path-enforcement/18-01-SUMMARY.md`.
- Task commits `68851a6` and `1664df5` exist in git history.

---
*Phase: 18-authorization-path-enforcement*
*Completed: 2026-04-24*
