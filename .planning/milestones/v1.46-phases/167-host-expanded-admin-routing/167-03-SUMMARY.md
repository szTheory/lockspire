---
phase: 167-host-expanded-admin-routing
plan: "03"
subsystem: testing
tags: [phoenix, routing, oauth, oidc, admin, consent]
requires:
  - phase: 167-01
    provides: Shared host-expanded admin routing and protected host mount
  - phase: 167-02
    provides: Host lifecycle coverage across configured mount prefixes
provides:
  - Independent ordered baseline for all 29 admin routes and concrete route selection
  - Regression coverage for public OAuth/OIDC, host-owned consent, and protected admin separation
affects: [phase-168-authorization-boundaries, phase-169-generator-convergence]
actuals:
  tokens: 8509
  tasks: 2
  commits: 3
plan_head_before: d3bda9dc9176ab5c22cdb89cd072f2fc8d3c375a
plan_head_after: 7e242aee6fce60d9e6d6aea363bc2583c515b06d
tech-stack:
  added: []
  patterns:
    - Independent literal route tuple baselines with native Phoenix route_info selection
    - Host-owned consent fixture with separate session and callback provenance
key-files:
  created:
    - test/lockspire/web/admin_route_inventory_test.exs
    - test/lockspire/web/admin_route_separation_test.exs
    - .planning/phases/167-host-expanded-admin-routing/167-03-task2-red.json
  modified:
    - test/support/lockspire/web/admin_route_host.ex
key-decisions:
  - "Freeze route meaning in literal test data independent of the implementation under test."
  - "Keep consent behavior in the host fixture with its own session, pipeline, and hooks."
patterns-established:
  - "Exercise compiled route selection and concrete substituted paths, not source-text declarations."
  - "Use per-request callback traces to prove concurrent route-surface isolation."
requirements-completed: [MNT-01, MNT-03, MNT-04]
coverage:
  - id: D1
    description: "Retained and host-expanded routers preserve the exact ordered 29-route admin inventory and concrete selected actions."
    requirement: MNT-03
    verification:
      - kind: unit
        ref: test/lockspire/web/admin_route_inventory_test.exs
        status: pass
      - kind: integration
        ref: "mix test.fast — 1961 passed, 6 skipped, 497 excluded"
        status: pass
    human_judgment: false
  - id: D2
    description: "Public OAuth/OIDC, host consent, and protected admin routes retain independent access and callback/session behavior."
    requirement: MNT-04
    verification:
      - kind: integration
        ref: test/lockspire/web/admin_route_separation_test.exs
        status: pass
      - kind: integration
        ref: "focused Phase 167 command — 43 tests passed"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-10-22
status: complete
---

# Phase 167 Plan 03: Host-Expanded Admin Routing Summary

**Literal route contracts and host-surface integration tests now fence all 29 admin routes and verify independent public, consent, and staff-admin behavior.**

## Performance

- **Duration:** approximately 17 minutes
- **Completed:** 2026-10-22
- **Tasks:** 2
- **Files modified:** 4 task artifacts, including the TDD RED evidence record

## Accomplishments

- Added an independent literal 29-route baseline and asserted ordered tuple parity for the retained router and default, nested, and root host routers. Concrete paths are checked through Phoenix route selection, including task suffixes, method mismatches, near-prefix boundaries, route metadata, repeat inspection, and concurrent dispatch.
- Extended the host fixture with a host-owned consent LiveView/session and public forward, then verified route ordering, anonymous public protocol behavior, host consent, staff-only admin access, callback provenance, and isolation during concurrent requests.
- Completed focused and full test gates without changing production routing code or adding dependencies.

## Verification

- Task 1 focused command: `mix test test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_router_test.exs` — 7 passed.
- Task 2 separation tests — 5 passed.
- Focused Phase 167 union command covering separation, inventory, compile, integration, runtime contract, and config tests — 43 passed.
- `mix format --check-formatted` — passed.
- `git diff --check` — passed.
- Full `mix test.fast` with the prescribed Phase 167 database and Elixir/OTP versions — exit 0; 1961 passed (2 properties and 1959 tests), 6 skipped, 497 excluded; 114.1 seconds. Captured output: `/tmp/lockspire-167-final-test-fast.log`.
- Phase state snapshot `.planning/state.json` remained byte-identical to `/tmp/lockspire-167-original-state.json`.

## Task Commits

1. **Task 1: Preserve the full ordered route/action inventory and actual match selection** — `3b5ea0e1` (`test`).
2. **Task 2 RED: Add host surface separation regressions** — `090661cc` (`test`).
3. **Task 2 GREEN: Add independent consent routing fixture** — `7e242aee` (`test`).

The measured plan commit count is 3, from `d3bda9dc9176ab5c22cdb89cd072f2fc8d3c375a` through `7e242aee6fce60d9e6d6aea363bc2583c515b06d`.

## Files Created/Modified

- `test/lockspire/web/admin_route_inventory_test.exs` — literal route contract and compiled match-selection assertions.
- `test/lockspire/web/admin_route_separation_test.exs` — integration coverage for independent public, consent, and admin surfaces.
- `test/support/lockspire/web/admin_route_host.ex` — host-owned consent session/hooks and public route fixture.
- `.planning/phases/167-host-expanded-admin-routing/167-03-task2-red.json` — checker-accepted TDD RED evidence for Task 2.

## Decisions Made

- Expected route tuples remain literal acceptance data rather than being generated from shared route declarations.
- Host consent remains outside the Lockspire admin mount and uses its own session and callback hooks.

## Deviations from Plan

**1. TDD evidence used a temporary ExUnit TAP formatter.** The default ExUnit output was not accepted by the RED evidence checker, so a temporary formatter emitted a supported TAP report for the failing target. The formatter was removed after evidence capture; the report and checker metadata remain in `/tmp/lockspire-167-separation-red-tap.log` and the committed RED record. No product dependency or source change resulted.

No production source changes were needed; Plans 01–02 already provided the routing behavior validated here.

## Issues Encountered

The full suite emitted an existing compile-time `missing_pipeline/2` diagnostic from a compile-test fixture while still completing with exit 0 and all reported tests passing. Existing unrelated signing-key warnings also appeared; neither was changed under this plan's scope.

## User Setup Required

None.

## Next Phase Readiness

The route inventory and cross-surface isolation contract are ready for Phase 168's authorization-boundary work. Generator, upgrade, browser, package, and supported-floor validation remain with their planned owners.

---
*Phase: 167-host-expanded-admin-routing*
*Completed: 2026-10-22*

## Self-Check: PASSED

- Summary file exists and is committed after task commits.
- All three task commit hashes are ancestors of the plan head recorded above.
- No temporary formatter remains in the working tree.
- Original `.planning/state.json` snapshot remains byte-identical.
