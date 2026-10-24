---
phase: 168-host-owned-liveview-authorization
plan: "01"
subsystem: auth
tags: [phoenix, liveview, authorization, testing]
requires:
  - phase: 167-host-expanded-admin-routing
    provides: Native admin routes and the host authorization hook seam
provides:
  - Current host identity/session/policy fixture authority with fail-closed resolution
  - HTTP, disconnected and actual connected LiveView authorization entry coverage
  - Required pipeline and hook wiring refusal coverage
affects: [168-02, 168-03, 169]
tech-stack:
  added: []
  patterns: [current-authority resolution at each authorization boundary, per-case lifecycle traces]
key-files:
  created:
    - .planning/phases/168-host-owned-liveview-authorization/deferred-items.md
  modified:
    - test/support/lockspire/web/admin_route_host.ex
    - test/lockspire/web/live/admin/admin_route_integration_test.exs
    - test/lockspire/web/admin_route_separation_test.exs
    - test/lockspire/web/admin_routes_compile_test.exs
decisions:
  - Keep identity and staff policy in mutable test-host authority, independently resolved by HTTP and LiveView boundaries.
  - Prove connected denial by calling public live(conn) on the previously successful static response after authority withdrawal.
metrics:
  duration: 8m
  completed: 2026-10-22
  status: complete
requirements-completed: [HAUTH-01, HAUTH-02]
actuals:
  tokens: 6440
  tasks: 2
  commits: 4
plan_head_before: 5b14e0f37434e70bfeb69014c7f04e5f9ff87017
plan_head_after: 9cdd5f3c05a024df983d4447017690cdbfb7523c
---

# Phase 168 Plan 01: Host-Owned LiveView Authorization Summary

**Current host policy now governs the initial HTTP response, disconnected mount and connected LiveView entry in deterministic integration fixtures.**

## Performance

- **Duration:** 8 minutes
- **Started:** 2026-10-22T20:02:13-04:00
- **Completed:** 2026-10-22T20:09:39-04:00
- **Tasks:** 2
- **Files modified:** 5, including the deferred-items ledger

## Accomplishments

- Added a supervised mutable test-host authority that independently validates session binding, current identity and current staff policy at the HTTP and LiveView boundaries; an installed but unavailable authority fails closed.
- Proved real connected denial using a successful static response followed by host-policy withdrawal and `live(conn)` without a path. Lifecycle traces distinguish disconnected from connected decisions and callback sentinels.
- Covered allowed and denied policy states across default, nested and root mounts, request isolation, sensitive-output protection, action routing, disconnected callback ordering, and missing/nil/empty route authorization wiring.

## Evidence

- **Source revision:** `5b14e0f37434e70bfeb69014c7f04e5f9ff87017` (Plan 01 changes are the four commits listed below).
- **Runtime:** Elixir 1.20.4 / OTP 29.1.1; locked Phoenix 1.8.13 and Phoenix LiveView 1.2.10.
- **Focused verification:** `LOCKSPIRE_TEST_DB_NAME=lockspire_phase168_20261022 ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/admin_route_separation_test.exs` — **31 passed**.
- **Formatting and whitespace:** `mix format --check-formatted` for all four changed test files and `git diff --check` passed.
- **TDD RED evidence:** Task 1’s disallowed valid identity reached the baseline redirect instead of the required 403. Task 2’s independent probe was rejected by the guarded browser pipeline before reaching the disconnected hook. Each failing assertion was committed before its implementation and passed after the fixture changes.
- **Positive controls:** Current allowed staff reached real admin routes and probe mount/params/render/action sentinels. Connected denial followed a 200 static response and produced a connected denial observation without protected connected callbacks.

The evidence covers repository-level HTTP and server lifecycle behavior using the locked dependency pair. It does not prove an arbitrary adopter’s policy implementation, browser rendering, actual transport reconnect behavior, or continuous revocation of an already-connected LiveView; later Phase 168 plans and Phase 170 own their respective evidence.

## Task Commits

1. **Task 1 RED:** `5886b9b0` — test(168-01): reject disallowed staff at admin HTTP boundary
2. **Task 1 GREEN:** `84e86387` — feat(168-01): add current host authority entry tracer
3. **Task 2 RED:** `96853c70` — test(168-01): prove disconnected hook runs before probe mount
4. **Task 2 GREEN:** `9cdd5f3c` — feat(168-01): expand host authorization entry probes

**Plan commits measured from ledger:** 4 (`5b14e0f37434e70bfeb69014c7f04e5f9ff87017` through `9cdd5f3c05a024df983d4447017690cdbfb7523c`).

## Files Created/Modified

- `test/support/lockspire/web/admin_route_host.ex` — mutable fixture authority, independently evaluated host hooks, and lifecycle/action sentinels.
- `test/lockspire/web/live/admin/admin_route_integration_test.exs` — real connected-entry tracer, policy matrix, protected content controls and route/action checks.
- `test/lockspire/web/admin_route_separation_test.exs` — concurrent request decision and trace isolation checks.
- `test/lockspire/web/admin_routes_compile_test.exs` — refusal tests for missing and nil authorization options.
- `.planning/phases/168-host-owned-liveview-authorization/deferred-items.md` — records a pre-existing duplicate fixture `record_trace/2` clause and its compiler warning for later cleanup.

## Decisions Made

- No production authorization code needed modification: the existing host seam supported the required behavior once the fixture evaluated current authority at each boundary.
- Preserve an immutable legacy fixture baseline only when no mutable authority is installed, maintaining existing test compatibility; all new matrix cases install explicit authority.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Prepared the isolated test database**
- **Found during:** Task 1 verification
- **Issue:** The required fresh database `lockspire_phase168_20261022` did not yet exist, so the first test invocation could not connect before reaching assertions.
- **Fix:** Ran the repository’s `mix test.setup` alias against that isolated database; the shared default test database was not changed.
- **Verification:** Both task-specific commands and the final focused command passed.
- **Committed in:** Not a repository file change.

**2. [Scope boundary - deferred pre-existing warning] Recorded duplicate fixture trace clauses**
- **Found during:** Task 1 compilation
- **Issue:** The existing test host contains duplicate `record_trace/2` clauses that produce compiler warnings; this predates Plan 01 and is unrelated to its authorization changes.
- **Action:** Recorded it in `deferred-items.md`; left the unrelated fixture cleanup untouched.
- **Committed in:** `84e86387`.

**Total deviations:** 2 recorded items (one environment prerequisite, one deferred pre-existing warning). No production scope expansion.

## Issues Encountered

- The expanded matrix initially coupled allow controls to static HTML wording. It now checks successful HTTP status and the router’s resolved LiveView action, which directly verifies the intended route contract.
- Expected compile diagnostics from tests that deliberately submit missing pipeline wiring appear in test output; the suite passes.
- The state counter initially could not parse the legacy “Current Position” section, so the required plan position labels were added before advancing it. The progress helper has no matching body `Progress:` row in this repository; the plan-count frontmatter was updated from the measured summary count.

## User Setup Required

None.

## Next Phase Readiness

The host fixture and entry-boundary evidence are ready for Plan 02’s separate connected-join lifecycle proofs and Plan 03’s full destination/evidence map. No production API, dependency, migration, or host identity store was added.

## Deviations from Plan

The deferred duplicate `record_trace/2` fixture warning is a tracked pre-existing issue; no other plan deviations remain.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commits `5886b9b0`, `84e86387`, `96853c70` and `9cdd5f3c` are ancestors of HEAD.
- The four owned test files pass the focused 31-test command and formatting checks.
- `.planning/state.json` retains its original SHA1 (`45470b25e06271a85eb69014c7f04c7c2e0b11ff9`).

---
*Phase: 168-host-owned-liveview-authorization*
*Completed: 2026-10-22*
