---
phase: "31"
plan: "02"
subsystem: "ui"
tags: ["phoenix", "generator", "device-flow", "verification", "tdd"]
requires:
  - phase: "31"
    provides: "Typed device-verification lookup/mutation APIs and verification_uri_complete from plan 31-04"
provides:
  - "Generated host-owned /verify routes and editable Phoenix verification files"
  - "Controller-first verification starter seam with prefill-only GET behavior"
  - "Executable generator and template-contract proof for anti-phishing verification UX rules"
affects:
  - "Host onboarding for Phase 31 device verification"
  - "Later host-side /verify customization and Phase 32 polling follow-up"
tech-stack:
  added: []
  patterns: ["host-owned generator seam", "controller-first verification flow", "template contract TDD"]
key-files:
  created:
    - "priv/templates/lockspire.install/verification_controller.ex"
    - "priv/templates/lockspire.install/verification_html.ex"
    - "priv/templates/lockspire.install/verification_html/index.html.heex"
    - ".planning/phases/31-host-owned-verification-ui-seam/31-02-SUMMARY.md"
  modified:
    - "lib/lockspire/generators/install.ex"
    - "lib/lockspire/generators/templates.ex"
    - "priv/templates/lockspire.install/router.ex"
    - "test/integration/install_generator_test.exs"
    - "test/lockspire/web/controllers/lockspire_verification_controller_test.exs"
key-decisions:
  - "Kept the primary Phase 31 verification seam as generated host-owned Phoenix controller/template code instead of a Lockspire-owned browser surface."
  - "Used GET /verify only for visible code prefill and moved all lookup and mutation behavior behind explicit POST actions."
  - "Bound approve and deny mutations to claims-derived subject context from Lockspire.account_resolver!/0 before calling the device verification protocol."
patterns-established:
  - "Generator-delivered browser seams should ship with route comments that point hosts to the canonical security guide and warn against raw query-string logging."
  - "Verification seams should re-display the user code, client name, and scopes before separate approve or deny submits on an opaque handle route."
requirements-completed: ["DEV-04", "DEV-05"]
duration: 7min
completed: 2026-04-28
---

# Phase 31 Plan 02: Host-Owned Verification UI Seam Summary

**Generated a host-owned Phoenix `/verify` seam with prefill-only GET behavior, protocol-backed POST lookup, and actor-bound approve or deny starter actions.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-28T09:48:00Z
- **Completed:** 2026-04-28T09:54:39Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Extended `mix lockspire.install` so host apps now receive editable `/verify` routes, verification controller/template files, and next-step guidance that points directly to `docs/device-flow-host-guide.md`.
- Added router and controller comments that keep `verification_uri_complete` prefill-only, keep GET side-effect free, and warn hosts not to log raw verification query strings or raw user codes.
- Implemented a controller-first starter seam that looks up pending device authorizations on POST, re-displays the code/client/scopes for possession checking, and binds approve or deny mutations to the signed-in host account subject.
- Added executable generator and template-contract tests that prove file generation, overwrite safety, no auto-submit hooks, and the explicit review-step copy.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing verification seam generation tests** - `ff5b2b7` (`test`)
2. **Task 1 GREEN: Generate host-owned verification seam** - `7c97bac` (`feat`)
3. **Task 2 RED: Add failing controller-first verification seam tests** - `4166062` (`test`)
4. **Task 2 GREEN: Implement controller-first verification starter seam** - `6421ee9` (`feat`)

## Files Created/Modified

- `lib/lockspire/generators/install.ex` - Adds install-time `/verify` guidance and points hosts to `docs/device-flow-host-guide.md`.
- `lib/lockspire/generators/templates.ex` - Registers the verification controller, HTML module, and HEEx template in the generated host inventory.
- `priv/templates/lockspire.install/router.ex` - Adds the host-owned `/verify` GET/POST/approve/deny routes and the anti-phishing route comments.
- `priv/templates/lockspire.install/verification_controller.ex` - Starter host-owned controller with prefill-only `show/2`, POST lookup, and actor-bound approve or deny actions.
- `priv/templates/lockspire.install/verification_html.ex` - HTML module for the generated verification surface.
- `priv/templates/lockspire.install/verification_html/index.html.heex` - Entry and review-step UI that re-displays the code and request context before mutation.
- `test/integration/install_generator_test.exs` - Verifies emitted files, `/verify` route generation, install guidance, and overwrite refusal.
- `test/lockspire/web/controllers/lockspire_verification_controller_test.exs` - Template-contract proof for prefill-only GET behavior, protocol wiring, and absence of auto-submit markers.

## Decisions Made

- Chose the controller-first generated seam described in Phase 31 planning instead of adding another required LiveView or a library-owned browser route.
- Used opaque handle routes for approve or deny actions so generated host code does not mutate on raw `user_code` after lookup.
- Kept the starter seam host-editable and calm, with no JavaScript auto-submit behavior and no GET-triggered lookup or approval path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the new template-contract test paths during Task 1**
- **Found during:** Task 1 verification
- **Issue:** The initial RED test pointed at `test/priv/...` instead of the repo-root `priv/templates/...` path, so the failure mode was a missing-file path bug rather than the intended generator gap.
- **Fix:** Corrected the relative template paths in `test/lockspire/web/controllers/lockspire_verification_controller_test.exs`.
- **Files modified:** `test/lockspire/web/controllers/lockspire_verification_controller_test.exs`
- **Verification:** `MIX_ENV=test mix test test/integration/install_generator_test.exs test/lockspire/web/controllers/lockspire_verification_controller_test.exs`
- **Committed in:** `7c97bac`

**2. [Rule 1 - Bug] Narrowed the GET-only contract assertion during Task 2**
- **Found during:** Task 2 verification
- **Issue:** After the controller gained real POST lookup and mutation actions, the original GET-safety test still scanned the whole file and incorrectly treated valid POST logic as a GET violation.
- **Fix:** Scoped the GET-safety assertion to the `show/2` block while keeping the stronger controller-wide assertions in separate tests.
- **Files modified:** `test/lockspire/web/controllers/lockspire_verification_controller_test.exs`
- **Verification:** `MIX_ENV=test mix test test/integration/install_generator_test.exs test/lockspire/web/controllers/lockspire_verification_controller_test.exs`
- **Committed in:** `6421ee9`

---

**Total deviations:** 2 auto-fixed (2 bug fixes)
**Impact on plan:** Both fixes were test-contract corrections needed to keep the TDD gates honest. No scope creep.

## Issues Encountered

- None beyond the two test-contract fixes documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Host apps can now generate and edit a secure `/verify` browser seam without Lockspire becoming the browser-UI owner.
- The starter controller is wired to the device verification protocol and ready for host-specific auth/session/rate-limit customization.
- Phase 32 can build on the same opaque-handle and durable-state contracts without revisiting the browser seam shape.

## Self-Check: PASSED

- `.planning/phases/31-host-owned-verification-ui-seam/31-02-SUMMARY.md` FOUND
- `priv/templates/lockspire.install/verification_controller.ex` FOUND
- `priv/templates/lockspire.install/verification_html.ex` FOUND
- `priv/templates/lockspire.install/verification_html/index.html.heex` FOUND
- `ff5b2b7` FOUND
- `7c97bac` FOUND
- `4166062` FOUND
- `6421ee9` FOUND

---
*Phase: 31-host-owned-verification-ui-seam*
*Completed: 2026-04-28*
