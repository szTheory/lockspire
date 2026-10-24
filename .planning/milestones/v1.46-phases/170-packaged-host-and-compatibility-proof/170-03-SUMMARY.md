---
phase: 170-packaged-host-and-compatibility-proof
plan: "03"
subsystem: testing
tags: [phoenix, liveview, compatibility, clean-room, chrome, receipts]

requires:
  - phase: 170-packaged-host-and-compatibility-proof
    provides: Candidate-installed host and full real-browser boundary matrix from Plan 02
provides:
  - Shared host lifecycle regressions executed on exact Phoenix 1.8.5 / LiveView 1.1.28
  - Floor-pair selection with frozen lock and pair/environment scoped cache
  - Three source-bound full browser receipts at default, nested, and root mounts
affects: [phase-170-04, phase-170-05, packaged-host-proof]

actuals:
  tokens: 5872
  tasks: 2
  commits: 3
  plan_head_before: a53116ee716aea1c10b71fa967fc104d40b9acf4
  plan_head_after: 652d2b4d328cb7fa02ce081e58b1facd68086e14

tech-stack:
  added: []
  patterns: [exact dependency-pair selection, lock-hash and MIX_ENV cache namespaces, compiled source identity checks]

key-files:
  created:
    - compatibility/phoenix_1_8_live_view_1_1/test/test_helper.exs
    - compatibility/phoenix_1_8_live_view_1_1/test/admin_host_runtime_test.exs
    - .planning/phases/170-packaged-host-and-compatibility-proof/170-03-task2-red-evidence.json
  modified:
    - compatibility/phoenix_1_8_live_view_1_1/mix.exs
    - compatibility/phoenix_1_8_live_view_1_1/mix.lock
    - compatibility/phoenix_1_8_live_view_1_1/lib/lockspire_compatibility_fixture.ex
    - scripts/acceptance/clean_room/admin_receipts.py
    - scripts/acceptance/clean_room/build_provider.py
    - scripts/acceptance/clean_room_admin_journey.py
    - test/clean_room/test_admin_journey.py
    - test/lockspire/compatibility_baseline_contract_test.exs

key-decisions:
  - "Keep floor selection opt-in to admin proof; ordinary provider callers retain the locked pair."
  - "Accept compiled and asset sources only from the unique child host or its pair-scoped dependency cache."
  - "Treat the CI-supported dependency floor as separate evidence from the locally observed Elixir/OTP runtime."

patterns-established:
  - "Pair selection is bound to exact manifest pins, frozen lock hash, and MIX_ENV-specific cache identity."
  - "Browser receipts require observed Phoenix/LiveView versions, package-local sources, all 16 cases, and successful cleanup."

requirements-completed: [HPROOF-02]
coverage:
  - id: D1
    description: "The shared host lifecycle regression suite executes under the exact Phoenix and LiveView floor."
    requirement: HPROOF-02
    verification:
      - kind: integration
        ref: "compatibility/phoenix_1_8_live_view_1_1/test/admin_host_runtime_test.exs (44 passed; Phoenix 1.8.5 / LiveView 1.1.28)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The packaged browser matrix passes on the exact floor at default, nested, and root mounts."
    requirement: HPROOF-02
    verification:
      - kind: e2e
        ref: ".artifacts/phase170/floor-default.json (16/16)"
        status: pass
      - kind: e2e
        ref: ".artifacts/phase170/floor-nested.json (16/16)"
        status: pass
      - kind: e2e
        ref: ".artifacts/phase170/floor-root.json (16/16)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Pair and runtime provenance checks reject wrong versions, reused opposite-pair caches, and root-checkout sources."
    requirement: HPROOF-02
    verification:
      - kind: unit
        ref: "python3 -m unittest discover -s test/clean_room -p test_admin_journey.py (18 passed)"
        status: pass
      - kind: integration
        ref: "Focused current-lock root route and compatibility suite (49 passed)"
        status: pass
    human_judgment: false

duration: 38min
completed: 2026-10-24
status: complete
---

# Phase 170 Plan 03: Exact-Floor Compatibility Proof Summary

**Phoenix 1.8.5 and LiveView 1.1.28 now execute the shared host regressions and all three packaged 16-case browser matrices.**

## Performance

- **Duration:** approximately 38 minutes.
- **Started:** approximately 2026-10-24T02:30:00Z.
- **Completed:** 2026-10-24T03:08:23Z.
- **Tasks:** 2/2.
- **Files modified:** 11 across committed plan changes.
- **Task commits:** 3, measured from the plan-head ledger.

## Accomplishments

- Finalized an isolated compatibility fixture lock with Phoenix `1.8.5`, LiveView `1.1.28`, and its existing host/test dependencies. The fixture imports root test configuration and runs the same four original route, inventory, separation, and connected authorization/navigation tests.
- Added explicit `locked` and `floor` dependency-pair selection for disposable packaged hosts. Floor selection updates only the child manifest, copies the reviewed floor lock before dependency verification, and namespaces caches by pair, lock hash, and `MIX_ENV`.
- Verified actual runtime versions and compiled/asset sources before browser startup. Sources must resolve inside the unique child host or its pair-scoped dependency cache; sources from the root checkout are rejected.
- Ran all three floor browser journeys in real Chrome. `/lockspire`, `/teams/ops/identity`, and `/` each passed all 16 cases with successful database, process, profile, and run-root cleanup.
- Confirmed root and ordinary-provider locks remained unchanged during both compatibility and browser verification.

## Verification

- Exact-floor fixture command from `compatibility/phoenix_1_8_live_view_1_1`: `MIX_ENV=test mix deps.get --check-locked && MIX_ENV=test mix lockspire.test.setup && MIX_ENV=test mix test test/admin_host_runtime_test.exs` — 44 passed, with observed Phoenix `1.8.5` and LiveView `1.1.28`.
- `python3 -m unittest discover -s test/clean_room -p test_admin_journey.py` — 18 passed.
- Current locked-pair focused root suite, including compatibility contract, route compilation/inventory/separation, and admin route integration — 49 passed.
- Floor browser receipts report Phoenix `1.8.5`, LiveView `1.1.28`, Elixir `1.20.4`, OTP `29`, Node `26.10.0`, and Chrome `155.0.8059.85`:
  - `.artifacts/phase170/floor-default.json` — `/lockspire`, 16/16 passed.
  - `.artifacts/phase170/floor-nested.json` — `/teams/ops/identity`, 16/16 passed.
  - `.artifacts/phase170/floor-root.json` — `/`, 16/16 passed.
- Root and provider lock no-drift check: `git diff --exit-code -- mix.lock test/clean_room/provider_host/mix.lock compatibility/phoenix_1_8_live_view_1_1/mix.lock` — passed after fixture lock generation.

### TDD Gate Compliance

- **RED:** `3dc0c892` added the floor-pair runtime and CLI contract tests. The focused tests failed because the validator rejected the floor receipt pair and the runner did not accept `--pair floor`. `.planning/phases/170-packaged-host-and-compatibility-proof/170-03-task2-red-evidence.json` records the failed target tests; `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- **GREEN:** `652d2b4d` implemented pair selection, exact runtime/source verification, cache refusal behavior, and compatibility contract updates. Python tests and all three full floor browser journeys passed.
- **REFACTOR:** None required.

## Task Commits

1. **Task 1: Execute shared host lifecycle regressions inside the exact-floor host** — `ea3815fd` (`feat`).
2. **Task 2 RED: Specify exact floor pair selection** — `3dc0c892` (`test`).
3. **Task 2 GREEN: Run packaged browser matrix under frozen floor dependencies** — `652d2b4d` (`feat`).

## Decisions Made

- Keep pair selection opt-in to admin proof so ordinary provider behavior remains bound to its existing locked dependencies.
- Treat runtime identity and source location as separate checks: exact application versions are required, and loaded code/assets must originate from the unique provider host or the selected pair's isolated dependency cache.
- Record local Elixir/OTP observations separately from the exact Phoenix/LiveView compatibility floor; no remote CI run is claimed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Load the existing root ErrorView support for the floor regression suite**
- **Found during:** Task 1.
- **Issue:** A route mount mismatch exercised the suite's existing error rendering path, but the narrow compatibility helper had not loaded its existing ErrorView support module.
- **Fix:** Explicitly loaded `test/support/error_view.ex` with the selected support modules.
- **Files modified:** `compatibility/phoenix_1_8_live_view_1_1/test/test_helper.exs`.
- **Verification:** The exact-floor suite passed 44 tests.
- **Committed in:** `ea3815fd`.

**2. [Rule 1 - Bug] Allow floor assets from the isolated pair dependency cache and expose sanitized probe failures**
- **Found during:** Task 2 browser verification.
- **Issue:** The first actual runtime probe rejected static asset paths served from the dedicated dependency cache, even though code and assets belonged to the isolated selected pair. Its stage diagnostic also reduced the reason to `unknown`.
- **Fix:** Accept files only under the unique provider host or its explicit `MIX_DEPS_PATH`; keep root-checkout sources rejected and expose only stable, sanitized runtime-probe reasons.
- **Files modified:** `scripts/acceptance/clean_room_admin_journey.py`, `test/clean_room/test_admin_journey.py`.
- **Verification:** The source-boundary regression passed; all three full floor browser matrices passed.
- **Committed in:** `652d2b4d`.

**Total deviations:** 2 auto-fixed issues (one Rule 2, one Rule 1). Both were required for correct execution and source provenance; no architectural or dependency-scope change was introduced.

## Issues Encountered

- Chrome startup failed when attempted inside the default sandbox. Per the execution dispatch's explicit authorization, the browser journeys were rerun with normal Chrome sandbox permissions; all three passed.
- The floor package advisory scanner reports advisories for dependencies pinned by the plan-mandated Phoenix 1.8.5 floor. The exact floor was retained as required, and no advisory was hidden or resolved by changing the reviewed lock.
- Existing unrelated compiler warnings surfaced during the focused suite; the 49-test command passed.

## Known Stubs

None found in files created or modified by this plan.

## User Setup Required

None.

## Next Phase Readiness

The supported floor now has executed shared lifecycle and real packaged browser evidence. Plans 04 and 05 can consume the exact-pair selection, source provenance checks, and full receipt matrix without relabeling compile-only or current-lock results as floor evidence.

## Self-Check: PASSED

- Exact-floor suite and three full browser receipts exist and report passing results with successful cleanup.
- Task commits `ea3815fd`, `3dc0c892`, and `652d2b4d` are ancestors of the plan head recorded above.
- The root and ordinary-provider lock no-drift checks passed.
- `.planning/state.json` has not been staged and remains restorable from `/private/tmp/lockspire-phase170-original-state.json`.

---
*Phase: 170-packaged-host-and-compatibility-proof*
*Completed: 2026-10-24*
