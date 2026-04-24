---
phase: 15-authorization-consumption-and-truthful-surface
plan: 03
subsystem: testing
tags: [par, oauth, oidc, phoenix, exunit, contract-tests]
requires:
  - phase: 15-01
    provides: "PAR request_uri consumption inside the authorization pipeline"
  - phase: 15-02
    provides: "Truthful PAR discovery metadata and narrow public support wording"
provides:
  - "Browser-path coverage for PAR-backed /authorize success and rejection cases"
  - "Canonical /par -> /authorize -> /token integration proof with PKCE"
  - "Discovery and docs contract tests for the narrow supported PAR slice"
affects: [phase-16-verification, par-coverage, release-truth]
tech-stack:
  added: []
  patterns: ["Phase-level executable truth contracts", "PAR end-to-end browser plus token proof"]
key-files:
  created: [test/integration/phase15_par_authorization_e2e_test.exs]
  modified:
    [
      test/lockspire/web/authorize_controller_test.exs,
      test/lockspire/web/discovery_controller_test.exs,
      test/lockspire/release_readiness_contract_test.exs,
      docs/maintainer-release.md,
      test/lockspire/protocol/pushed_authorization_request_test.exs
    ]
key-decisions:
  - "Keep 15-03 focused on executable proof; rely on the already-shipped 15-01 and 15-02 implementations instead of reopening runtime code."
  - "Pin PAR support claims to Lockspire-issued request_uri references and continue forbidding broader request-object, device-flow, and DCR wording."
patterns-established:
  - "PAR public-surface claims are enforced by repo-owned contract tests across discovery, README, supported-surface, SECURITY, and release docs."
  - "Phase-close verification includes both focused PAR tests and the repo-wide fast lane to catch drift outside the directly edited files."
requirements-completed: [PAR-02, PAR-03]
duration: 4min
completed: 2026-04-24
---

# Phase 15 Plan 03: Lock the PAR browser flow and public truth surface with executable proof

**PAR-backed authorization code + PKCE now has browser-path, integration, discovery, and repo-truth contract coverage.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-24T14:34:30Z
- **Completed:** 2026-04-24T14:38:39Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added browser-surface coverage for PAR success, expiry, replay, and wrong-client rejection in `/authorize`.
- Added a canonical end-to-end PAR proof from `POST /par` through `/authorize` and `/token`, including state and nonce preservation.
- Locked discovery and support-facing wording to the narrow shipped PAR slice with repo-owned contract tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add web and end-to-end tests for the PAR-backed authorization code + PKCE flow** - `2905794` (`test`)
2. **Task 2: Add discovery and public-truth contract coverage for the narrow PAR support claim** - `ae7436b` (`test`)
3. **Blocking suite stabilization: fix stale PAR protocol test timestamps discovered during closeout verification** - `69d4950` (`test`)

## Files Created/Modified

- `test/lockspire/web/authorize_controller_test.exs` - Covers PAR-backed browser success plus expiry, replay, and wrong-client rejection.
- `test/integration/phase15_par_authorization_e2e_test.exs` - Canonical `/par -> /authorize -> /token` proof with PKCE and replay rejection.
- `test/lockspire/web/discovery_controller_test.exs` - Pins `pushed_authorization_request_endpoint` and forbids broader request-object metadata.
- `test/lockspire/release_readiness_contract_test.exs` - Enforces narrow PAR wording across README, supported-surface, SECURITY, and planning truth.
- `docs/maintainer-release.md` - Aligns release-claims guidance with the now-supported narrow PAR slice.
- `test/lockspire/protocol/pushed_authorization_request_test.exs` - Uses wall-clock-safe timestamps so closure verification remains stable over time.

## Decisions Made

- Treated 15-03 as proof-only work because the runtime behavior was already delivered by 15-01 and 15-02.
- Kept PAR truth contracts narrow and concrete so future wording drift requires deliberate test changes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed stale maintainer-release PAR wording**
- **Found during:** Task 2
- **Issue:** `docs/maintainer-release.md` still forbade claiming PAR at all, which drifted from the shipped narrow PAR support wording.
- **Fix:** Replaced the blanket PAR prohibition with wording that forbids broader request-object-by-value and generic external `request_uri` claims instead.
- **Files modified:** `docs/maintainer-release.md`
- **Verification:** `MIX_ENV=test mix test test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs`
- **Committed in:** `ae7436b`

**2. [Rule 3 - Blocking] Stabilized stale fixed timestamps in PAR protocol tests**
- **Found during:** Plan-close verification
- **Issue:** `test/lockspire/protocol/pushed_authorization_request_test.exs` used a hard-coded `2026-04-24T14:00:00Z` timestamp, which had become expired and broke `mix test.fast`.
- **Fix:** Switched the non-expiry assertions to `DateTime.utc_now/0` while keeping the explicit expired-path test intact.
- **Files modified:** `test/lockspire/protocol/pushed_authorization_request_test.exs`
- **Verification:** `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs && MIX_ENV=test mix test.fast && MIX_ENV=test mix test test/integration/phase15_par_authorization_e2e_test.exs`
- **Committed in:** `69d4950`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes were necessary to keep repo truth and closure verification reliable. No scope creep beyond the PAR proof surface.

## Issues Encountered

- The plan is marked `type: tdd`, but the implementation it verifies had already shipped in 15-01 and 15-02, so the new tests passed immediately instead of producing a RED phase.

## TDD Gate Compliance

- `test(15-03)` commits exist for the added proof.
- No separate `feat(15-03)` commit exists because 15-03 is a verification plan layered on top of already-green implementation from 15-01 and 15-02.
- This is an expected warning, not a missing behavior gap.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 16 can now rely on canonical PAR browser, integration, and truth-surface coverage.
- No known blockers remain inside Phase 15 after the timestamp stabilization fix.

## Self-Check

PASSED

---
*Phase: 15-authorization-consumption-and-truthful-surface*
*Completed: 2026-04-24*
