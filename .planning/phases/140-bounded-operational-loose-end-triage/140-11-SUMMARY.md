---
phase: 140-bounded-operational-loose-end-triage
plan: "11"
subsystem: testing
tags: [ecto, sandbox, exunit, test-fixtures]
requires: [140-10]
provides:
  - Per-test sandbox ownership for seven reported admin, policy, PAR, and browser fixture modules
affects: [140-08, CI-06, LOOSE-03]
actuals:
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [per-test SQL sandbox owner with shared access for LiveView processes]
key-files:
  created: [.planning/phases/140-bounded-operational-loose-end-triage/140-11-PLAN.md]
  modified:
    - test/lockspire/admin/keys_test.exs
    - test/lockspire/protocol/pushed_authorization_request_test.exs
    - test/lockspire/web/authorize_controller_test.exs
    - test/lockspire/web/live/admin/clients_live_test.exs
    - test/lockspire/web/live/admin/policies_live/par_test.exs
    - test/lockspire/web/live/admin/policies_live/dpop_test.exs
    - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
key-decisions:
  - "Use Sandbox.start_owner!/stop_owner per test, with shared access for LiveView child processes, and keep fixture behavior assertions unchanged."
requirements-completed: [LOOSE-03]
coverage:
  - id: D1
    description: Admin key and policy LiveView test fixtures are isolated in per-test sandbox transactions.
    verification:
      - kind: integration
        ref: "mix test test/lockspire/admin/keys_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: PAR and browser JAR fixture tests pass with per-test sandbox ownership.
    verification:
      - kind: integration
        ref: "mix test test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-10-01
status: complete
---

# Phase 140 Plan 11: Test Fixture Isolation Summary

**Admin, policy, PAR, and browser fixture modules now use per-test sandbox owners, preventing persisted test rows from changing key lifecycle, policy summary, and client authentication results.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-01T01:51:00Z
- **Completed:** 2026-10-01T02:03:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Replaced manual per-test checkouts with owner transactions in five admin and LiveView test modules.
- Applied the same per-test owner boundary to PAR and browser authorization tests.
- Preserved all product constraints and existing key lifecycle, client count, policy, and JAR assertions.

## Task Commits

1. **Task 1: Isolate admin key and policy LiveView fixtures** - `a8d5ba3e` (fix)
2. **Task 2: Isolate PAR and browser JAR client fixtures** - `54293d1d` (fix)

**Plan metadata:** `2b6696d0` (docs: plan isolated CI test fixtures)

## Files Created/Modified

- `140-11-PLAN.md` - Exact scope and focused checks for the out-of-scope failure group.
- `test/lockspire/admin/keys_test.exs` - Rolls test key state back per case.
- `test/lockspire/web/live/admin/clients_live_test.exs` - Isolates client count fixtures.
- `test/lockspire/web/live/admin/policies_live/{par,dpop,security_profile}_test.exs` - Isolates policy summary fixtures.
- `test/lockspire/protocol/pushed_authorization_request_test.exs` - Isolates PAR fixtures.
- `test/lockspire/web/authorize_controller_test.exs` - Isolates browser authorization fixtures.

## Decisions Made

- Used the existing SQL sandbox owner pattern so each test rolls back its records; shared ownership remains available to LiveView processes.
- Recreated only the configured `lockspire_test` database before focused verification because earlier local runs had left rows from older fixture code. The full CI workflow's `test.setup` task only creates and migrates storage, so it does not clear existing test data.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Clear persisted local test rows before verifying fixture isolation**
- **Found during:** Task 1
- **Issue:** The configured `lockspire_test` database contained rows from prior local runs, so focused checks failed on duplicate clients and unexpected active keys before per-test isolation could be evaluated.
- **Fix:** Recreated the explicitly configured test database and reran migrations; no application or production database was touched.
- **Files modified:** None (local test database only)
- **Verification:** Both plan selectors passed after setup.
- **Committed in:** No file commit required.

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Required to distinguish historical local test data from current per-test fixture behavior.

## Issues Encountered

The first focused attempt ran against persisted `lockspire_test` rows and failed. After recreating that test database, both focused selectors passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 140-08 can continue with its remaining out-of-scope release-proof and token-signing failures represented by separate gap plans.

## Self-Check: PASSED

- The plan artifact exists and commits `2b6696d0`, `a8d5ba3e`, and `54293d1d` are present.
- Both focused selectors passed after recreating the configured test database.

---
*Phase: 140-bounded-operational-loose-end-triage*
*Completed: 2026-10-01*
