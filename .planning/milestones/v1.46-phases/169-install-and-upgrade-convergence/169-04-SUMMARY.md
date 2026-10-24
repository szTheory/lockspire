---
phase: 169-install-and-upgrade-convergence
plan: "04"
subsystem: install-upgrade
tags: [phoenix, liveview, host-authorization, clean-room, adoption-demo]

requires:
  - phase: 169-01
    provides: "Canonical native admin route macro and generated host-owned deny-by-default authorization seam."
provides:
  - "The adoption demo uses one canonical native admin route declaration and re-resolves host account policy at LiveView mount and params transitions."
  - "The maintained clean-room host compiles the generated helper with its matching host-owned denying Plug and hook at default and nested mounts."
  - "The clean-room builder configures a shared browser and LiveView socket session, browser protections, and an explicit test signing salt."
affects: [170, adoption-demo, clean-room, generated-host, install]

actuals:
  tokens: 7893
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Demo HTTP and LiveView authorization share the same host account policy predicate."
    - "Clean-room overlays replace the generated authorization seam at the same path and consume the generated router helper."

key-files:
  created:
    - examples/adoption_demo/lib/adoption_demo_web/operator_authorization.ex
    - test/lockspire/adoption_demo_admin_integration_test.exs
    - test/lockspire/clean_room_admin_integration_test.exs
    - .planning/phases/169-install-and-upgrade-convergence/169-04-task1-red-evidence.json
    - .planning/phases/169-install-and-upgrade-convergence/169-04-task2-red-evidence.json
  modified:
    - examples/adoption_demo/lib/adoption_demo_web/router.ex
    - examples/adoption_demo/lib/adoption_demo_web/plugs/require_operator.ex
    - scripts/acceptance/clean_room/build_provider.py
    - test/clean_room/provider_host/lib/clean_room_provider_web/operator_authorization.ex
    - test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs
    - test/lockspire/clean_room_release_source_contract_test.exs

key-decisions:
  - "Keep the demo's existing HTTP redirect and 403 responses while sharing operator policy with the LiveView hook."
  - "Keep clean-room authorization fail-closed until an adopting host implements its own account policy."
  - "Treat compiled routes and connected LiveViewTest behavior as repository-source evidence; Phase 170 owns package, real transport, and exact-floor proof."

patterns-established:
  - "Compile actual adoption-demo router sources against an isolated test endpoint for root-suite HTTP and connected lifecycle coverage."
  - "Render the current installer helper into an isolated clean-room host before compiling the maintained overlay."

requirements-completed: [HDX-04, HDX-01]
coverage:
  - id: D1
    description: "The demo's canonical 29-route inventory preserves its host layout and HTTP policy, and its ops account reaches the actual connected overview with current account resolution on navigation."
    requirement: HDX-04
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/adoption_demo_operator_guard_test.exs test/lockspire/adoption_demo_admin_integration_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The generated clean-room helper and maintained overlay compile at default and nested mounts with deny-by-default Plug/hook behavior and explicit endpoint session wiring."
    requirement: HDX-01
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/clean_room_release_source_contract_test.exs test/lockspire/clean_room_admin_integration_test.exs test/lockspire/web/admin_route_separation_test.exs"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-10-23
status: complete
plan_head_before: de3e26aaf1c7c430962a6c47079c79eba0848cb3
plan_head_after: 6164db81e1460188c293003861fc287174b5f346
---

# Phase 169 Plan 04: Install and Upgrade Convergence Summary

**The adoption demo and maintained clean-room host now use the generated native admin integration with explicit host-owned authorization and endpoint session wiring.**

## Performance

- **Duration:** 10 minutes
- **Started:** 2026-10-23T22:00:08Z
- **Completed:** 2026-10-23T22:09:45Z
- **Tasks:** 2
- **Files modified:** 11 implementation, test, and RED evidence files

## Accomplishments

- Replaced the demo's copied admin LiveView list and masking forward with one `AdminRoutes.lockspire_admin_routes/2` call. The compiled demo route/action inventory matches all 29 canonical entries and retains the demo's root layout, operator pipeline, host consent controller, and public protocol forward.
- Added a demo-owned LiveView hook that resolves `demo_login` through `Accounts.get/1` on mount and each `handle_params` transition. It ignores cached socket identity and shares the operator predicate with the existing HTTP plug.
- Exercised the actual demo router through anonymous and nonstaff HTTP denial, ops HTTP access, the connected Overview LiveView, and connected params navigation.
- Updated the clean-room overlay to consume the generated helper, compile its matching host-owned deny Plug and hook, and retain a separate public forward. The generated router compiles with all 29 routes at `/lockspire/admin` and `/teams/ops/identity/admin`.
- Added `/live` socket `connect_info` using the same cookie session options as `Plug.Session`; the clean-room browser pipeline now includes LiveView flash, CSRF, and secure browser headers. Its endpoint configuration supplies an explicit test-only LiveView signing salt.

## TDD Gate Compliance

- Task 1 RED: `169-04-task1-red-evidence.json` records the canonical-route assertion failing against the copied inventory. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` before implementation.
- Task 1 GREEN: the focused demo guard/router selector passed **6 tests**, including actual HTTP and connected LiveView behavior. The tracer rerun passed the same selector before Task 2 began.
- Task 2 RED: `169-04-task2-red-evidence.json` records the builder socket/session contract assertion failing. The evidence checker returned `RED_EVIDENCE_OK` before implementation.
- Task 2 GREEN: the complete clean-room source, compiled overlay, and public separation selector passed **16 tests**.
- The temporary ExUnit TAP formatter used to produce classifier-compatible RED reports was removed before implementation commits; no runtime dependency or permanent reporter was added.

## Task Commits

1. **Task 1 RED: canonical demo route regression** - `335ce9dd`
2. **Task 1 GREEN: demo authorization and native routes** - `541f3a17`
3. **Task 2 RED: clean-room endpoint contract** - `457e485f`
4. **Task 2 GREEN: clean-room integration convergence** - `6164db81`

**Measured task commits:** 4 (`de3e26aaf1c7c430962a6c47079c79eba0848cb3..6164db81e1460188c293003861fc287174b5f346`).

## Verification

- Demo selector — **6 passed**; verifies route metadata, anonymous/nonstaff/ops HTTP behavior, connected Overview, layout, hook denial for invalid/forged identity, and native params navigation.
- Clean-room selector — **16 passed**; compiles generated endpoint/router/helper and overlay at default and nested mounts, verifies deny-by-default Plug/hook behavior, checks session parity and signing configuration, and retains public route separation.
- `mix format` on changed Elixir files and `git diff --check` — passed.
- Current source and connected server-side lifecycle only. No candidate package, real browser/socket transport, or exact supported-floor claim is made; Phase 170 owns those proofs.

## Decisions Made

- Kept demo policy inside its host account resolver and shared only the account predicate between HTTP and LiveView boundaries.
- Kept the clean-room host deny-by-default; the host must supply its own policy before granting access.
- Kept the endpoint and cookie setup local to the clean-room adoption example, with no package installation or external operation in the root-suite tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Import LiveView router helpers for the clean-room browser pipeline**
- **Found during:** Task 2
- **Issue:** The first compiled overlay attempt could not resolve `fetch_live_flash/2` because the router had not imported Phoenix LiveView router helpers.
- **Fix:** Added `import Phoenix.LiveView.Router` to the maintained overlay before compiling its generated routes.
- **Files modified:** `test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs`
- **Verification:** The clean-room integration selector compiled the overlay at both mounts and passed all 16 tests.
- **Committed in:** `6164db81`

### Verification Adaptation

ExUnit's default text report is not accepted by the repository RED classifier. A temporary test-only formatter emitted TAP from the actual ExUnit run; both RED artifacts were classified as `RED_EVIDENCE_OK`. The formatter was removed before the GREEN commits.

**Total deviations:** 1 auto-fixed blocking issue and 1 temporary verification adaptation. **Impact:** Both were required to satisfy the planned compile contract and machine-validated TDD evidence without adding a dependency.

## Issues Encountered

- Phoenix route metadata stores LiveView data under `metadata.phoenix_live_view`, while pipeline data is exposed through `Phoenix.Router.route_info/4`; the integration assertions use those compiled runtime contracts.
- Compilation reported pre-existing type warnings in unrelated Lockspire modules. They were outside the files owned by this plan and were not changed.

## Known Stubs

None. The clean-room Plug and hook intentionally deny access until the adopting host implements its policy; this is the required security behavior.

## User Setup Required

None.

## Next Phase Readiness

The demo, installer-rendered helper, and maintained clean-room source converge on the canonical native routes and host-owned denial seam. Phase 170 remains responsible for packaged adoption, real browser/socket transport, exact supported dependency floors, and required CI proof.

---
*Phase: 169-install-and-upgrade-convergence*
*Completed: 2026-10-23*

## Self-Check: PASSED

- Summary and both RED evidence files exist on disk.
- Task commits `335ce9dd`, `541f3a17`, `457e485f`, and `6164db81` are ancestors of the current plan head.
- `gsd_run check evaluation-scope --plan "169-04" --commits-only --raw` resolved the plan and found all four commits on the current branch.
- The Task 1 selector passed 6 tests and the Task 2 selector passed 16 tests; both RED evidence records were accepted by the classifier.
