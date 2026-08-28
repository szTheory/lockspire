---
phase: 131-executable-installation
plan: "03"
subsystem: oauth-oidc-installation
tags: [phoenix, liveview, oauth, oidc, consent, installer]
requires:
  - phase: 131-01
    provides: generated host router mounting and installer configuration seams
  - phase: 131-02
    provides: idempotent installed-host persistence migration path
provides:
  - protocol-authoritative, redaction-safe consent render context
  - generated host-owned consent LiveView wired before public OAuth routes
  - executable installer fixture covering consent approval through token issuance
affects: [phase-131, install-dx, oauth-authorization-flow]
tech-stack:
  added: []
  patterns:
    - safe protocol-to-host render context with terminal redirects as a distinct result
    - generated template parity test against a compiling executable host fixture
key-files:
  created:
    - lib/lockspire/web/consent_context.ex
    - test/lockspire/web/consent_context_test.exs
    - test/support/generated_host_app_web/live/lockspire_consent_live.ex
  modified:
    - lib/lockspire/web/live/consent_live.ex
    - priv/templates/lockspire.install/consent_live.ex
    - priv/templates/lockspire.install/router.ex
    - test/integration/phase6_onboarding_e2e_test.exs
key-decisions:
  - "Expose only presentation-safe consent fields to host UI while terminal protocol states redirect without rendering."
  - "Treat the installer template and executable fixture as exact peers so generated consent UI is compiled and exercised end to end."
patterns-established:
  - "ConsentContext.load/2 returns {:ok, context}, {:redirect, uri}, or a stable safe error atom."
  - "Generated host LiveViews submit native POST completion forms via phx-trigger-action after LiveView validation."
requirements-completed: [INST-02]
coverage:
  - id: D1
    description: "Consent context preserves subject, expiry, pending-login, and remembered-consent protocol decisions without exposing raw protocol data."
    requirement: INST-02
    verification:
      - kind: unit
        ref: "test/lockspire/web/consent_context_test.exs"
        status: pass
      - kind: unit
        ref: "test/lockspire/web/live/consent_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The installer-rendered host consent LiveView compiles, mounts through generated routes, approves consent, and completes OAuth code exchange."
    requirement: INST-02
    verification:
      - kind: integration
        ref: "test/integration/install_generator_test.exs"
        status: pass
      - kind: automated_ui
        ref: "test/integration/phase6_onboarding_e2e_test.exs"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-08-26
status: complete
---

# Phase 131 Plan 03: Executable Installation Summary

**A host-owned, accessible consent LiveView now receives only safe protocol context and is proven from generated route through approval, authorization code, and token exchange.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-08-26T21:15:00Z
- **Completed:** 2026-08-26T21:32:52Z
- **Tasks:** 2/2
- **Files modified:** 11

## Accomplishments

- Extracted `Lockspire.Web.ConsentContext` from the built-in surface so generated host UI receives a narrow, redaction-safe presentation contract while existing subject binding, expiry, pending-login resume, remembered consent, completion paths, and terminal redirects remain protocol-authoritative.
- Generated an accessible host-owned consent LiveView with semantic request details, distinct generic error states, confirmation controls, and a `phx-trigger-action` POST to the existing completion controller.
- Mounted the LiveView ahead of the public Lockspire forward and established exact template-to-fixture parity that compiles and exercises the actual generated authorization completion flow.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract consent render context with TDD** - `3235a3a` (test), `896a549` (feat)
2. **Task 2: Generate and exercise host consent LiveView** - `fcb08b8` (feat)

## Files Created/Modified

- `lib/lockspire/web/consent_context.ex` - Safe consent UI context and terminal state resolution.
- `lib/lockspire/web/live/consent_live.ex` - Existing consent surface refactored to consume the safe context.
- `priv/templates/lockspire.install/consent_live.ex` - Installer-owned host consent LiveView template.
- `priv/templates/lockspire.install/router.ex` - Generated consent route mounted before the public forward.
- `test/support/generated_host_app_web/live/lockspire_consent_live.ex` - Executable generated-module fixture.
- `test/integration/install_generator_test.exs` - Template parity, compile, and generated route coverage.
- `test/integration/phase6_onboarding_e2e_test.exs` - LiveView approval and native completion-to-token flow coverage.

## Decisions Made

- Keep raw interaction, subject, redirect, and authorization-detail values out of the host render contract; only a scoped completion path and display-safe fields cross the protocol/UI boundary.
- Retain the host's normal layout, authentication seam, and styles rather than introducing a Lockspire visual system.
- Use the same source shape for template and fixture so the tested LiveView is the code an installer writes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical route wiring] Mount generated consent before the public forward**
- **Found during:** Task 2
- **Issue:** A consent LiveView mounted after `forward` would be unreachable because the public OAuth router captures the mount path first.
- **Fix:** Added the generated LiveView route before the existing public Lockspire forward.
- **Files modified:** `priv/templates/lockspire.install/router.ex`, `test/support/generated_host_app_web/router/lockspire.ex`
- **Verification:** Generated route metadata and the end-to-end LiveView test both pass.
- **Committed in:** `fcb08b8`

**2. [Rule 3 - Executable fixture support] Enable LiveView session transport in the generated host fixture**
- **Found during:** Task 2
- **Issue:** The fixture endpoint and account resolver only supported controller connections, so the installer-rendered LiveView could not resolve the host account during mount.
- **Fix:** Added the fixture LiveView socket/session configuration and a narrowly scoped socket resolver path backed by the host session.
- **Files modified:** `test/support/generated_host_app_web/endpoint.ex`, `test/support/generated_host_app/lockspire/test_account_resolver.ex`
- **Verification:** `phase6_onboarding_e2e_test.exs` mounts, approves, posts completion, and exchanges the resulting code.
- **Committed in:** `fcb08b8`

---

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 3)
**Impact on plan:** Both changes are required to make the documented generated LiveView executable; no product scope was broadened.

## Verification

- `mix format --check-formatted` on all modified Elixir source and tests — passed.
- `mix compile --warnings-as-errors` — passed.
- `mix test test/lockspire/web/consent_context_test.exs test/lockspire/web/live/consent_live_test.exs` — passed (8 tests).
- `mix test test/integration/install_generator_test.exs` — passed (9 tests).
- `mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` — passed (1 test).

## Known Stubs

None.

## Issues Encountered

The generated fixture initially lacked a LiveView socket/session seam. It was completed as an executable-test requirement and remains isolated to test support code.

## User Setup Required

None - generated hosts continue to own authentication, branding, layouts, and account resolution through their configured seam.

## Next Phase Readiness

The installation path now has a compiled, route-reachable consent surface with an end-to-end proof through OAuth token exchange. Subsequent executable-installation work can reuse the safe context and template-parity pattern.

## Self-Check: PASSED

- `lib/lockspire/web/consent_context.ex` and `test/support/generated_host_app_web/live/lockspire_consent_live.ex` exist.
- Task commits `3235a3a`, `896a549`, and `fcb08b8` exist in git history.

---
*Phase: 131-executable-installation*
*Completed: 2026-08-26*
