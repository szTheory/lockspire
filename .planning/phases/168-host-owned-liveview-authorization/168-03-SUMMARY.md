---
phase: 168-host-owned-liveview-authorization
plan: "03"
subsystem: testing
tags: [phoenix-liveview, host-authorization, admin-navigation, route-contracts]
requires:
  - phase: 168-01
    provides: Host-owned HTTP/disconnected/connected authorization fixture and entry-denial proof.
  - phase: 168-02
    provides: Cached-response connected rejoin authorization proof.
provides:
  - Public and consent cross-session entry checks with explicit fresh protected entry under current host policy.
  - Host-fixture current-policy handle_params guard for native patches.
  - Allowed and denied LiveView navigation coverage for all 29 protected routes at three mounts.
  - Revision-bound Phase 168 validation and prohibition-closure evidence.
affects: [phase-168-verification, phase-169-install-guidance, phase-170-runtime-proof]
actuals:
  tokens: 10231
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - Host-owned LiveView handle_params authorization re-resolves current policy from signed session references.
    - Public, consent and admin fixtures keep separate LiveView sessions and cross-session navigation models a fresh HTTP entry.
key-files:
  created:
    - .planning/phases/168-host-owned-liveview-authorization/168-03-task2-red-evidence.json
  modified:
    - test/support/lockspire/web/admin_route_host.ex
    - test/lockspire/web/admin_route_separation_test.exs
    - test/lockspire/web/live/admin/admin_route_integration_test.exs
    - .planning/phases/168-host-owned-liveview-authorization/168-VALIDATION.md
    - .planning/phases/168-host-owned-liveview-authorization/deferred-items.md
key-decisions:
  - "Re-resolve host authority at each params transition through the existing on_mount seam; keep account, role, event and logout policy in the host."
  - "Model cross-session LiveView redirect and fresh HTTP/live entry as separate steps; do not claim browser transport proof."
patterns-established:
  - "Fixture-owned authorization hooks can protect same-view native patches without Lockspire interpreting host roles."
  - "Start each denied destination navigation from a fresh allowed origin so prior denials cannot contaminate later checks."
requirements-completed: [HAUTH-01, HAUTH-02, HAUTH-03, HAUTH-04]
coverage:
  - id: D1
    description: Public and consent LiveViews remain separate from admin and require a fresh current-policy admin entry.
    requirement: HAUTH-03
    verification:
      - kind: integration
        ref: test/lockspire/web/admin_route_separation_test.exs#public and consent sessions cross into admin only through fresh current-policy entry
        status: pass
    human_judgment: false
  - id: D2
    description: All protected admin destinations and native params patches recheck the host's current authority.
    requirement: HAUTH-01
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#connects the real overview and clients pages and rejoins with fresh host hooks
        status: pass
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#real client action and query patches check current host policy
        status: pass
    human_judgment: false
  - id: D3
    description: Phase 168 automated scope, source ownership, and evidence limits are recorded.
    verification:
      - kind: other
        ref: .planning/phases/168-host-owned-liveview-authorization/168-VALIDATION.md#execution-evidence
        status: pass
    human_judgment: false
metrics:
  duration: 18m
  completed: "2026-10-22"
  status: complete
---

# Phase 168 Plan 03: Host-Owned Navigation Authorization Summary

**All 29 protected admin destinations now have allowed and withdrawn-policy navigation coverage, and native client patches re-resolve current host authority before protected params run.**

## Performance

- **Duration:** About 18 minutes.
- **Started:** 2026-10-22T20:20:00-04:00.
- **Completed:** 2026-10-22T20:38:48-04:00.
- **Tasks:** 2 completed.
- **Files modified:** 6 plan-owned files, excluding the preserved `state.json` snapshot.

## Accomplishments

- Proved public and consent LiveViews return the distinct-session redirect, then separately exercised fresh admin HTTP/live entry for missing, invalid, disallowed and allowed current authority at default, nested and root mounts.
- Added a host-fixture `handle_params` guard that re-resolves the host's current authority for native patch transitions. Actual client edit, authorization-policy, secret-rotation and query-filter patches are covered with allowed and withdrawn-policy controls.
- Exercised 29 route/view/action destinations under allowed and denied authority at all three mounts: 87 allowed and 87 separately originated denied navigation attempts. Existing literal route inventory, selected actions, ordered host hooks and session metadata assertions remain the independent route contract.
- Recorded runtime results and the closure criteria for both descriptor-less prohibition flags while retaining the three unresolved probe assumptions.

## Task Commits

1. **Task 1: Trace consent-to-admin navigation through the required fresh host entry** — `be017c98` (test-only tracer; the boundary was already green, so no redundant fixture behavior was added).
2. **Task 2: Protect all admin destinations, exercise native patches and close automated evidence** — `b40f79e3` (RED evidence), `d0f12976` (host fixture and regressions), and `9c630565` (measured validation ledger).

**Measured plan commits before summary:** 4, from `2a256b08b2b507dce93e9e4d8dc6926a0a989e2b` through `9c630565`.

## Files Created/Modified

- `test/support/lockspire/web/admin_route_host.ex` — fixture-only public session and current-policy params hook.
- `test/lockspire/web/admin_route_separation_test.exs` — cross-session and fresh-entry matrix for public/consent sources.
- `test/lockspire/web/live/admin/admin_route_integration_test.exs` — all-destination navigation, native patch behavior and RED evidence target.
- `.planning/phases/168-host-owned-liveview-authorization/168-03-task2-red-evidence.json` — retained TDD RED output.
- `.planning/phases/168-host-owned-liveview-authorization/168-VALIDATION.md` — measured phase-wide runtime evidence and scoped prohibition closures.
- `.planning/phases/168-host-owned-liveview-authorization/deferred-items.md` — records unrelated existing fixture warning and planning-document whitespace findings.

## Verification

- Focused union: **44 passed** across route compilation, inventory, separation, integration and LiveView runtime-contract tests.
- `mix format --check-formatted`: passed.
- `mix test.fast`: **1,976 passed** (2 properties and 1,974 tests), 6 skipped, 497 excluded. The first broad run could not write Hex's cache under the read-only home; rerun with `HEX_HOME=/tmp/lockspire-phase168-hex` passed without installing packages.
- `git diff --check`: passed for the working tree. The expanded phase-base check surfaced trailing spaces in the already-authored `168-PATTERNS.md` and `168-RESEARCH.md`; these are recorded as deferred and were left untouched.
- Runtime: Elixir 1.20.4 / OTP 29.1.1; locked Phoenix 1.8.13, LiveView 1.2.10 and Ecto SQL 3.13.5. Tests used isolated database `lockspire_phase168_20261022`.

## Decisions Made

- The current-policy callback captures session references and performs host authorization on each params transition; it does not capture an allowed boolean or add library role logic.
- Native params guards cover navigation boundaries. Event-level policy, active logout/disconnect, and ongoing old-socket revocation remain host responsibilities. The tests do not claim browser transport, packaged adoption, or supported-floor proof; those remain Phase 170. Generator/demo/install guidance convergence remains Phase 169.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the denied patch assertion to match LiveViewTest's redirect result.**
- **Found during:** Task 2.
- **Issue:** The RED test showed the protected params callback ran after authority withdrawal, as expected; after adding the guard, an assertion incorrectly treated the redirect tuple as HTML.
- **Fix:** Assert the exact host sign-in redirect result and the absence of the protected callback marker.
- **Files modified:** `test/lockspire/web/live/admin/admin_route_integration_test.exs`.
- **Verification:** The focused patch test and final 44-test union passed.
- **Committed in:** `d0f12976`.

**2. [Rule 3 - Blocking] Used an isolated writable Hex cache for the broad test selector.**
- **Found during:** Task 2 verification.
- **Issue:** Release artifact tests invoke `mix hex.info`; the default Hex cache path was read-only in the sandbox and caused 22 unrelated setup failures on the first broad run.
- **Fix:** Re-ran `mix test.fast` with `HEX_HOME=/tmp/lockspire-phase168-hex`; no package installation was performed.
- **Files modified:** None in the project for this environment adjustment.
- **Verification:** The broad selector passed all 1,976 selected tests/properties.
- **Committed in:** Not a repository file change.

**Total deviations:** 2 auto-fixed (1 assertion correction, 1 verification environment adjustment). **Impact:** No production code or dependency changed; the only source addition is in test support.

## Issues Encountered

- Task 1's consent tracer passed against the existing host HTTP boundary; the new behavior was already present, so its atomic commit retained the regression test without duplicating fixture behavior.
- The broader source-base whitespace check found pre-existing trailing spaces in phase research/pattern artifacts outside this plan's source ownership. `deferred-items.md` records them; current task files pass the working-tree check.
- Existing duplicate `record_trace/2` fixture clauses and their compiler warning remain deferred, unchanged.

## User Setup Required

None. No external service configuration or new package is required.

## Next Phase Readiness

The automated host-owned authorization and navigation evidence is complete. Phase 169 can proceed with generator/demo/install guidance convergence. Phase 170 retains browser/socket transport, package adoption and exact supported-floor runtime proof. No manual UAT pass is asserted.

---
*Phase: 168-host-owned-liveview-authorization*
*Completed: 2026-10-22*

## Self-Check: PASSED

- Summary file exists and all four measured plan commits are ancestors of `HEAD`.
- Plan-owned source and evidence files contain no added TODO/FIXME or placeholder stubs.
- The preserved `.planning/state.json` still matches SHA1 `45470b25e06271a85e4947c9594dc7c2e0b11ff9`.
