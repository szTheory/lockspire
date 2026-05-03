---
phase: 43-end-to-end-fapi-validation
plan: "01"
subsystem: auth
tags: [fapi, oidc, rfc9207, phoenix, redirects]
requires:
  - phase: 41-fapi-2-0-profile-configuration
    provides: FAPI security-profile enforcement and truthful mounted authorization surfaces
provides:
  - Unconditional RFC 9207 `iss` emission on successful authorization redirects
  - Unconditional RFC 9207 `iss` emission on access-denied authorization redirects
  - Unconditional RFC 9207 `iss` emission on redirect-safe authorize validation errors
affects: [43-02, 43-03, 43-06, discovery, conformance]
tech-stack:
  added: []
  patterns:
    - Inject `iss` at the redirect-builder seam instead of branching on security profile
    - Keep controller-thin error redirect assembly aligned with protocol-owned authorization redirects
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/authorization_flow.ex
    - lib/lockspire/web/controllers/authorize_controller.ex
    - test/lockspire/protocol/authorization_flow_test.exs
    - test/lockspire/web/authorize_controller_test.exs
key-decisions:
  - "RFC 9207 `iss` emission is unconditional for all authorization-response redirects, independent of FAPI profile mode."
  - "The success/denial protocol seam and controller error seam both source `iss` from `Lockspire.Config.issuer!/0` to avoid drift."
patterns-established:
  - "Authorization-response redirect maps carry `iss` inline beside `code`, `state`, and `error` fields without changing merge semantics."
  - "Redirect-safe controller validation errors must stay aligned with protocol redirect helpers for mix-up protection truth."
requirements-completed: [FAPI-06]
duration: 2min
completed: 2026-05-03
---

# Phase 43 Plan 01: ISS Emission Summary

**Authorization success, denial, and redirect-safe error responses now all append RFC 9207 `iss` from the configured issuer**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-03T12:44:20Z
- **Completed:** 2026-05-03T12:45:58Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added unconditional `iss` emission to `AuthorizationFlow` approval redirects so successful authorization-code responses carry the configured issuer.
- Added unconditional `iss` emission to `AuthorizationFlow` denial redirects so `access_denied` responses match the same RFC 9207 contract.
- Added unconditional `iss` emission to `AuthorizeController.redirect_location/1` so redirect-safe validation and protocol errors no longer create an `iss`-less bypass.

## Task Commits

1. **Task 1: Append iss to AuthorizationFlow approval and denial redirects** - `bbc933e` (test), `b4b3bed` (feat)
2. **Task 2: Append iss to AuthorizeController error redirect** - `2931bc6` (test), `fa470a9` (feat)

## Files Created/Modified
- `lib/lockspire/protocol/authorization_flow.ex` - Appends `iss` to approval and denial redirect parameter maps.
- `lib/lockspire/web/controllers/authorize_controller.ex` - Adds `Lockspire.Config` and appends `iss` to redirect-safe error redirects.
- `test/lockspire/protocol/authorization_flow_test.exs` - Verifies decoded approval and denial redirect queries contain the configured issuer.
- `test/lockspire/web/authorize_controller_test.exs` - Verifies redirect-safe authorize validation errors include the configured issuer.

## Decisions Made
- Kept `iss` injection inline at the two existing redirect-builder seams instead of changing shared merge helpers or introducing profile-aware branching.
- Reused existing approval, denial, and validation-error tests to prove behavior with minimal surface-area change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unavailable `gsd-sdk query` state handlers with equivalent manual planning-file updates**
- **Found during:** Summary and state finalization
- **Issue:** The installed `gsd-sdk` CLI in this workspace only exposes `run`, `auto`, and `init`, so the documented `query` subcommands for state/roadmap/requirements updates are unavailable.
- **Fix:** Updated `.planning/STATE.md` and `.planning/ROADMAP.md` manually, preserved newer concurrent Phase 43 state from other agents, and documented the missing CLI surface here.
- **Files modified:** `.planning/phases/43-end-to-end-fapi-validation/43-01-iss-emission-SUMMARY.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** Confirmed the summary exists, task commits exist, and the planning files reflect this plan without overwriting newer shared state.
- **Committed in:** metadata commit

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Product code and test scope stayed unchanged. Only workflow metadata handling diverged because the documented CLI interface was unavailable.

## Issues Encountered

- The shared `.planning/STATE.md` had already been advanced by parallel Phase 43 work, so the manual state update was limited to additive decision/progress changes to avoid regressing newer session metadata.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Discovery and end-to-end FAPI proof work can now rely on runtime authorization redirects always carrying `iss`.
- The remaining Phase 43 plans can treat `authorization_response_iss_parameter_supported` as implementable truth rather than planned behavior.

## Self-Check: PASSED

- Found summary file on disk.
- Verified task commits `bbc933e`, `b4b3bed`, `2931bc6`, and `fa470a9` in git history.
