---
phase: 38-session-tracking-rp-initiated-logout
plan: "01"
subsystem: testing
tags: [elixir, exunit, oidc, session, logout, slo, end-session, rp-initiated-logout]

# Dependency graph
requires:
  - phase: 37-protocol-strictness-conformance
    provides: Protocol strictness and OIDC conformance baseline on which Phase 38 builds

provides:
  - Wave 0 test stub harness for Phase 38 session tracking and RP-initiated logout
  - test/lockspire/protocol/end_session_test.exs — 9 skipped stubs for EndSession protocol validation
  - test/lockspire/web/end_session_controller_test.exs — 8 skipped stubs for EndSessionController HTTP adapter
  - test/integration/phase38_session_logout_e2e_test.exs — 3 skipped stubs for full SLO flow
  - Phase 38 stubs in discovery_test.exs — 3 skipped stubs for end_session_endpoint and BCL/FCL fields

affects:
  - 38-02 (sid tracking implementation — tests stub the revoke_by_sid behavior)
  - 38-03 (EndSessionController and Protocol.EndSession implementation)
  - 38-04 (discovery metadata implementation)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Wave 0 Nyquist stub pattern — all test cases @tag :skip at plan creation, filled in during implementation waves
    - Security behavior comments in stubs link to VALIDATION.md threat IDs (T-38-01 through T-38-05)
    - Integration test uses async: false and @tag :skip without @moduletag :integration to stay flexible for Wave 1

key-files:
  created:
    - test/lockspire/protocol/end_session_test.exs
    - test/lockspire/web/end_session_controller_test.exs
    - test/integration/phase38_session_logout_e2e_test.exs
  modified:
    - test/lockspire/protocol/discovery_test.exs

key-decisions:
  - "Wave 0 stubs use @tag :skip (not @moduletag) so individual tests can be un-skipped in later waves without removing others"
  - "EndSessionControllerTest references Lockspire.TestEndpoint even though controller does not exist yet — compile warning is acceptable for stubs"
  - "E2E integration test module name follows Lockspire.Phase38SessionLogoutE2ETest (not Lockspire.Integration.*) to match plan specification"

patterns-established:
  - "Stub comments cite decision IDs (D-14, D-15, etc.) and threat IDs (T-38-03) for traceability back to VALIDATION.md and RESEARCH.md"

requirements-completed:
  - SLO-01
  - SLO-02

# Metrics
duration: 5min
completed: 2026-04-29
---

# Phase 38 Plan 01: Wave 0 Test Stub Harness for Session Tracking and RP-Initiated Logout

**Nyquist Wave 0 stub harness: 3 new ExUnit files (20 total @tag :skip cases) and 3 discovery stubs define the full Phase 38 SLO behavior contract before any implementation code is written.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-29T16:13:07Z
- **Completed:** 2026-04-29T16:18:24Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Created `test/lockspire/protocol/end_session_test.exs` with 9 skipped stubs covering id_token_hint signature validation, expiry tolerance, open-redirect prevention, and client_id/aud cross-check (SLO-02 requirements D-14 through D-17, D-20)
- Created `test/lockspire/web/end_session_controller_test.exs` with 8 skipped stubs for GET/POST /end_session and /end_session/complete behaviors including security-critical rejection paths (T-38-03, T-38-04, T-38-05)
- Created `test/integration/phase38_session_logout_e2e_test.exs` with 3 skipped stubs for full SLO-01 (sid generation/revocation) and SLO-02 (end-to-end logout flow)
- Extended `test/lockspire/protocol/discovery_test.exs` with Phase 38 describe block: 3 skipped stubs for end_session_endpoint and BCL/FCL metadata fields

## Task Commits

Each task was committed atomically:

1. **Task 1: Create EndSessionProtocol test stub** - `f70d4f7` (test)
2. **Task 2: Create EndSessionController test stub and integration test stub** - `43ac4ab` (test)
3. **Task 2 expansion: Expand controller stubs to meet 60-line minimum** - `8fd6c2e` (test)

## Files Created/Modified

- `test/lockspire/protocol/end_session_test.exs` (created, 72 lines) — 9 @tag :skip stubs for EndSession protocol validation: hint validation, redirect URI exact match, aud cross-check
- `test/lockspire/web/end_session_controller_test.exs` (created, 71 lines) — 8 @tag :skip stubs for HTTP adapter: GET/POST methods, host redirect, completion endpoint behaviors
- `test/integration/phase38_session_logout_e2e_test.exs` (created, 40 lines) — 3 @tag :skip stubs for end-to-end SLO-01 and SLO-02 scenarios
- `test/lockspire/protocol/discovery_test.exs` (modified) — added Phase 38 describe block with 3 @tag :skip stubs for discovery fields

## Decisions Made

- Wave 0 stubs use per-test `@tag :skip` (not `@moduletag :skip`) so later waves can un-skip individual cases incrementally
- EndSessionControllerTest references `Lockspire.TestEndpoint` at compile time to match project conventions even though the controller doesn't exist yet; the resulting warning is acceptable for stub-only files
- Integration test module name `Lockspire.Phase38SessionLogoutE2ETest` follows the plan specification exactly (not the `Lockspire.Integration.*` namespace used in some earlier tests)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Expanded EndSessionController stubs to meet 60-line plan minimum**
- **Found during:** Task 2 post-commit verification (line count check)
- **Issue:** Initial stub was 53 lines, below the plan's 60-line artifact minimum
- **Fix:** Added 2 additional @tag :skip stubs (client_id/aud mismatch per T-38-04, nil sid path per D-16) and expanded module-level security comments
- **Files modified:** test/lockspire/web/end_session_controller_test.exs
- **Verification:** wc -l shows 71 lines; mix test --exclude skip exits 0
- **Committed in:** 8fd6c2e (separate expansion commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical threshold)
**Impact on plan:** Expansion added 2 meaningful security-behavior stubs already called for by VALIDATION.md threat references. No scope creep.

## Issues Encountered

Pre-existing test failures (4 failures in `mix test --exclude skip` on full suite) were observed in the existing test suite unrelated to this plan's files — specifically in `Lockspire.ReleaseReadinessContractTest` and `Lockspire.Admin.KeysTest`. These failures exist on the main branch and are outside the scope of Wave 0 stub creation.

## Threat Flags

No new production trust boundaries introduced — Wave 0 creates test stub files only. No new network endpoints, auth paths, or schema changes.

## Known Stubs

All stubs in this plan are intentional Wave 0 placeholders. Each file's `flunk("not yet implemented")` bodies are the expected pre-implementation state:

| File | Stub Count | Resolving Plan |
|------|-----------|----------------|
| test/lockspire/protocol/end_session_test.exs | 9 | Plan 03 (Protocol.EndSession) |
| test/lockspire/web/end_session_controller_test.exs | 8 | Plan 03 (EndSessionController) |
| test/integration/phase38_session_logout_e2e_test.exs | 3 | Plans 02 + 03 |
| test/lockspire/protocol/discovery_test.exs | 3 | Plan 04 (discovery metadata) |

These stubs are intentional and do not prevent the plan's goal (establishing the test contract harness for subsequent waves).

## Next Phase Readiness

- Wave 0 harness complete — Plans 02, 03, and 04 (Wave 1 and 2) have a pre-built test contract to drive against
- `test/lockspire/protocol/end_session_test.exs` will be filled in by Plan 03 when `Lockspire.Protocol.EndSession` is implemented
- `test/lockspire/web/end_session_controller_test.exs` will be filled in by Plan 03 when `Lockspire.Web.EndSessionController` is wired
- `test/integration/phase38_session_logout_e2e_test.exs` depends on both Plans 02 (sid tracking) and 03 (end_session surface)
- `test/lockspire/protocol/discovery_test.exs` Phase 38 stubs will be filled in by Plan 04

---
*Phase: 38-session-tracking-rp-initiated-logout*
*Completed: 2026-04-29*
