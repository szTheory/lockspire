---
phase: 169-install-and-upgrade-convergence
plan: "03"
subsystem: testing
tags: [phoenix, liveview, install-verification, native-admin-routes, route-dispatch]

requires:
  - phase: 169-01
    provides: "Generated-style native admin route integration and host-owned authorization seam."
provides:
  - "Inventory-backed verification of canonical compiled native admin routes, guards, pipelines, hooks, and first-match dispatch."
  - "Bounded, secret-safe Mix diagnostics that state the structural proof boundary on successful and failing outcomes."
affects: [170, install, host-router-verification]

actuals:
  tokens: 16191.5
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns:
    - "One internal canonical route inventory feeds both macro expansion and verification."
    - "Compiled Phoenix route metadata and route_info first-match results establish wiring structure only."

key-files:
  created:
    - .planning/phases/169-install-and-upgrade-convergence/169-03-task1-red-evidence.json
    - .planning/phases/169-install-and-upgrade-convergence/169-03-task2-red-evidence.json
  modified:
    - lib/lockspire/web/admin_routes.ex
    - lib/lockspire/install/verify.ex
    - lib/mix/tasks/lockspire.verify.ex
    - test/lockspire/install/verify_test.exs
    - test/mix/tasks/lockspire_verify_test.exs

key-decisions:
  - "Keep __route_inventory__/0 hidden and read-only; host apps do not gain a route extension API."
  - "Treat the host pipeline and hook declarations as structural evidence, and state that host-owned behavior tests establish authorization policy."
  - "Reserve packaged browser transport and exact-floor runtime proof for Phase 170."

patterns-established:
  - "Exercise real compiled root, default, and nested host routers for mount normalization."
  - "Check every canonical route through route_info/4 so earlier forwards and catch-alls cannot shadow native admin views."
  - "Use fixed structural diagnostics and sentinel tests instead of inspecting arbitrary metadata or exception terms."

requirements-completed: [HDX-03]
coverage:
  - id: D1
    description: "Verifier accepts complete compiled native routing and rejects malformed, incomplete, legacy, misordered, and shadowed routes at exact paths."
    requirement: HDX-03
    verification:
      - kind: unit
        ref: "test/lockspire/install/verify_test.exs"
        status: pass
      - kind: unit
        ref: "test/lockspire/web/admin_route_inventory_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Public help and result output preserve actionable structural diagnostics, omit injected sentinels, and state the policy and runtime proof limits."
    requirement: HDX-03
    verification:
      - kind: unit
        ref: "test/mix/tasks/lockspire_verify_test.exs"
        status: pass
      - kind: other
        ref: "node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check tdd-red-evidence .planning/phases/169-install-and-upgrade-convergence/169-03-task2-red-evidence.json --raw"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-10-23
status: complete
plan_head_before: eafa291ca1ba24fd76b29e5481a0ba33d8988614
plan_head_after: 7e7ed1ba2f5fbe1ba1d28bee7bc3fd0fae66332a
---

# Phase 169 Plan 03: Install and Upgrade Convergence Summary

**The verifier now recognizes the host's compiled native admin routes precisely and reports structural proof limits without exposing secret metadata.**

## Performance

- **Duration:** 15 minutes
- **Started:** 2026-10-23T21:42:47Z
- **Completed:** 2026-10-23T21:58:08Z
- **Tasks:** 2
- **Files modified:** 7 implementation, test, and evidence files (plus this summary)

## Accomplishments

- Exposed the existing 29-route inventory through hidden `Lockspire.Web.AdminRoutes.__route_inventory__/0`; route expansion and verification share the same tuples.
- Verified exact compiled path/view/action/session/hook/pipeline structure and confirmed first-match selection for each canonical admin route, including root and nested mounts.
- Added public Mix task coverage for legacy and malformed routers, wrong metadata, route shadowing, and secret-safe success, failure, and exception output.
- Made the structural-policy limit visible in help and in all router success and error outcomes.

## TDD Gate Compliance

- Task 1 recorded failing native-router regressions in `169-03-task1-red-evidence.json`, then passed its focused verifier tests (31 passed).
- Task 2 recorded the help-contract failure in `169-03-task2-red-evidence.json`; the evidence checker returned `RED_EVIDENCE_OK` before implementation. Its complete verification command passed (40 tests).
- `mix format --check-formatted` and `git diff --check` passed.

## Task Commits

1. **Task 1 RED: native admin verifier regressions** - `32c07502`
2. **Task 1 GREEN: compiled native admin wiring** - `74916616`
3. **Task 2 RED: exact router matrix and output tests** - `3279488c`
4. **Task 2 GREEN: bounded routing proof and help** - `b0a4b21a`
5. **Task 2 follow-up: unavailable-router proof limit** - `7e7ed1ba`

## Files Created/Modified

- `lib/lockspire/web/admin_routes.ex` - internal accessor for the existing canonical route inventory.
- `lib/lockspire/install/verify.ex` - exact inventory, host pipeline and hook, guard argument, and first-match route checks with safe fixed diagnostics.
- `lib/mix/tasks/lockspire.verify.ex` - native routing guidance and explicit structural proof boundary in help.
- `test/lockspire/install/verify_test.exs` - compiled root/default/nested routers, malformed and negative metadata, ordering and dispatch shadowing tests.
- `test/mix/tasks/lockspire_verify_test.exs` - public success/failure, help, unavailable-router, and sentinel redaction tests.
- `169-03-task1-red-evidence.json`, `169-03-task2-red-evidence.json` - validated TDD RED records.

## Decisions Made

- Kept the inventory accessor internal and read-only; route declaration remains in `lockspire_admin_routes/2`.
- Pipeline and hook declarations establish structure only. Host request and LiveView tests remain the evidence for host-owned authorization behavior.
- Phase 170 owns packaged browser transport and exact-floor runtime proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Keep valid host pipeline names out of router errors**
- **Found during:** Task 2
- **Issue:** The pipeline names from a valid route were accidentally returned as diagnostics, causing complete native routers to fail verification.
- **Fix:** Separated the observed host pipeline list from the error list and require it to be nonempty before `:lockspire_admin_mount`.
- **Files modified:** `lib/lockspire/install/verify.ex`
- **Verification:** The 40-test verifier and route inventory command passed.
- **Committed in:** `b0a4b21a`

**2. [Rule 2 - Missing Critical] Preserve the proof limit for unavailable router metadata**
- **Found during:** Final scope audit
- **Issue:** Router errors for unavailable modules and invalid mount configuration omitted the structural-policy boundary.
- **Fix:** Added the same policy limit to those error details and fixes, with a public Mix task regression.
- **Files modified:** `lib/lockspire/install/verify.ex`, `test/mix/tasks/lockspire_verify_test.exs`
- **Verification:** The complete 40-test verifier and route inventory command passed.
- **Committed in:** `7e7ed1ba`

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical diagnostic requirement)
**Impact on plan:** Both changes close planned correctness and proof-boundary requirements.

## Issues Encountered

- Existing unrelated compiler and typespec warnings appeared during the first compile; the focused tests passed after the planned fixes.
- The final verification establishes compiled structural wiring only. It does not certify arbitrary host authorization policy or prove packaged/browser behavior or exact-floor runtime behavior.

## User Setup Required

None.

## Next Phase Readiness

Phase 170 can use this verifier as the structural baseline and continue with packaged browser transport and exact-floor runtime evidence.

---
*Phase: 169-install-and-upgrade-convergence*
*Completed: 2026-10-23*

## Self-Check: PASSED

- Summary file exists at the planned path.
- All five task commits are ancestors of the current plan head.
- Both recorded RED evidence files returned `RED_EVIDENCE_OK`.
- The final 40-test command, format check, and `git diff --check` passed.
