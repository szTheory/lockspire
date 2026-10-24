---
phase: 169-install-and-upgrade-convergence
plan: "05"
subsystem: install-upgrade
tags: [phoenix, liveview, host-admin, upgrade, documentation]

requires:
  - phase: 169-01
    provides: "Canonical native AdminRoutes macro and generated deny-by-default host authorization seam."
  - phase: 169-02
    provides: "Checksum-trusted managed conversion and transactional upgrade recovery."
  - phase: 169-03
    provides: "Inventory-backed structural verifier and explicit diagnostic proof limits."
  - phase: 169-04
    provides: "Converged demo and clean-room host route, policy, session, and endpoint wiring."
provides:
  - "Canonical install, admin, supported-surface, and host-admin upgrade guidance aligned with the emitted helper and native route macro."
  - "Host-owned endpoint, browser, session, signing-salt, asset, policy, and migration responsibilities with safe upgrade/reconciliation steps."
  - "Source-grounded closure records for HDX-01 through HDX-04 and P-169-01 through P-169-03, with explicit Phase 170 evidence owners."
affects: [install, upgrade, host-admin, adoption-demo, documentation, phase-170]

actuals:
  tokens: 16754.25
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Keep administrator identity and authorization policy in the host Plug and LiveView hook, with current-policy checks on mount and navigation."
    - "Separate source-verified route wiring from host behavior, packaged-consumer, browser/socket, and exact-version evidence."

key-files:
  created:
    - docs/upgrading/host-admin-integration.md
    - .planning/phases/169-install-and-upgrade-convergence/169-UAT.md
  modified:
    - README.md
    - docs/install-and-onboard.md
    - docs/operator-admin.md
    - docs/supported-surface.md
    - docs/adoption-demo.md
    - .planning/phases/169-install-and-upgrade-convergence/169-VALIDATION.md
    - mix.exs
    - lib/lockspire/install/verify.ex
    - lib/mix/tasks/lockspire.verify.ex
    - priv/templates/lockspire.install/router.ex
    - test/lockspire/adoption_demo_docker_contract_test.exs
    - test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs
    - test/support/generated_host_app_web/router/lockspire.ex
    - test/support/lockspire/release_proof/documentation_assertions.ex
    - test/support/lockspire/web/admin_proof/route_assertions.ex

key-decisions:
  - "Keep host authentication, identity, staff policy, endpoint/session wiring, branding, and product decisions with the adopting Phoenix app."
  - "Treat static route verification and connected source tests as bounded evidence; Phase 170 owns candidate-package, browser/socket, exact-floor, and required CI proof."
  - "Keep the descriptor-less probe assumption A-169-HDX-04 flagged without inventing an acceptance predicate or human pass."

requirements-completed: [HDX-01, HDX-02, HDX-03, HDX-04]

coverage:
  - id: D1
    description: "Install, admin, supported-surface, README, demo, and upgrade entry points give adopters one canonical path and explicit host-owned responsibilities."
    requirement: HDX-01
    verification:
      - kind: integration
        ref: "test/lockspire/documentation_contract_test.exs and test/integration/install_admin_integration_test.exs; final phase union"
        status: pass
    human_judgment: false
  - id: D2
    description: "Historical conversion and manual drift reconciliation preserve host policy while previews, checksums, recovery, and repeat runs stay bounded."
    requirement: HDX-02
    verification:
      - kind: integration
        ref: "test/integration/install_upgrade_test.exs and test/lockspire/install/file_transaction_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Verifier output and maintained guidance state structural proof limits and assign package, browser/socket, exact-version, and CI execution to Phase 170."
    requirement: HDX-03
    verification:
      - kind: unit
        ref: "test/lockspire/install/verify_test.exs and test/mix/tasks/lockspire_verify_test.exs"
        status: pass
      - kind: other
        ref: ".planning/phases/169-install-and-upgrade-convergence/169-UAT.md#P-169-03"
        status: pass
    human_judgment: false
  - id: D4
    description: "Demo, generated host, clean-room host, and documentation use the canonical route inventory without copied admin routes or a masking forward."
    requirement: HDX-04
    verification:
      - kind: integration
        ref: "test/lockspire/adoption_demo_admin_integration_test.exs, test/lockspire/clean_room_admin_integration_test.exs, test/lockspire/adoption_demo_docker_contract_test.exs"
        status: pass
    human_judgment: false

duration: 27min
completed: 2026-10-23
status: complete
plan_head_before: 51e258be4af105f3fd95764ba389e2233ea14c97
plan_head_after: a8e22e8a2712dd175b7beb6bf871d8271cf02557
---

# Phase 169 Plan 05: Install and Upgrade Convergence Summary

**Adopters now have one source-grounded path from fresh install or historical host upgrade to bounded route verification and host-owned authorization.**

## Performance

- **Duration:** 27 minutes, measured from the first task commit; orchestration pre-read start was not captured.
- **Started:** 2026-10-23T22:18:09Z (first task commit)
- **Completed:** 2026-10-23T22:44:52Z
- **Tasks:** 2
- **Files modified:** 18 implementation, test, documentation, and evidence files

## Accomplishments

- Updated the canonical install, admin, supported-surface, README, and adoption-demo entry points to use the generated `lockspire_routes/0` helper and `Lockspire.Web.AdminRoutes.lockspire_admin_routes/2` contract.
- Added a maintained host-admin integration upgrade guide covering legacy forward-only conversion, read-only preview, checksum-trusted managed changes, safe repeats and recovery, and manual reconciliation when host files drift.
- Documented host ownership of the browser pipeline, endpoint socket/session cookie parity, LiveView signing salt, served assets, current staff policy, MFA/roles, layout/branding, and product-specific access decisions. Structural verifier results are explicitly separated from arbitrary host policy and real browser behavior.
- Added per-criterion evidence for HDX-01 through HDX-04 and separate closure records for P-169-01 through P-169-03. The unresolved unclassified assumption A-169-HDX-04 remains flagged without an invented predicate or user-reported pass.
- Kept package-consumer adoption, real browser/socket transport, exact Phoenix 1.8.5 / LiveView 1.1.28 runtime, and required CI proof assigned to Phase 170.

## Task Commits

Task 1 was committed atomically; Task 2 required one implementation/test correction commit and two evidence commits to pin the tested source revision.

1. **Task 1: Walk the documented canonical install and historical upgrade path** — `ff421e34` (`docs(169-05): align host admin install and upgrade guidance`).
2. **Task 2 implementation and regression contracts** — `13e673ce` (`fix(169-05): align generated admin route proof`).
3. **Task 2 adopter links and measured evidence** — `95a4f8d4` (`docs(169-05): reconcile host upgrade entry points`).
4. **Task 2 source revision pins** — `a8e22e8a` (`docs(169-05): pin acceptance evidence revisions`).

**Measured plan commits:** 4 (`51e258be4af105f3fd95764ba389e2233ea14c97..a8e22e8a2712dd175b7beb6bf871d8271cf02557`).

## Files Created/Modified

- `docs/upgrading/host-admin-integration.md` — concrete host-managed upgrade, policy migration, and drift reconciliation guide, included once in ExDoc and the package inventory.
- `docs/install-and-onboard.md`, `docs/operator-admin.md`, `docs/supported-surface.md`, `README.md`, and `docs/adoption-demo.md` — consistent adoption and proof-boundary guidance.
- `169-UAT.md` and `169-VALIDATION.md` — source-revision-pinned acceptance/prohibition closure and measured test outcomes. Validation remains `status: draft` and `nyquist_compliant: false` pending the validation workflow.
- `lib/lockspire/install/verify.ex` and `lib/mix/tasks/lockspire.verify.ex` — durable runtime-facing explanation of proof limits without roadmap labels.
- `priv/templates/lockspire.install/router.ex` and its maintained generated fixture — emitted and checked formatting now agree.
- Existing documentation, route, generator, and adoption-demo contract tests now assert current guide wording and the shared `AdminRoutes` inventory.
- `169-PATTERNS.md` — removed two trailing spaces so the required diff check is clean.

## Decisions Made

- Kept authorization code and admin route declarations in the library while the adopting app supplies identity, login, current staff policy, layouts, and product decisions.
- Kept conversion writes limited to checksum-authorized managed artifacts; untrusted or drifted host files require manual reconciliation.
- Recorded only repository-source, compiled-routing, connected LiveView, and executed suite evidence. No package, browser/socket transport, exact-floor, or CI pass is inferred.
- Ran the final full suite with a fresh disposable database because `mix test.setup` migrates but does not clear a previously used `lockspire_test` database.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Align documentation assertions with the current host-owned wording**
- **Found during:** Task 2 verification.
- **Issue:** Existing release and admin-boundary assertions still expected phrases removed by the canonical guide rewrite.
- **Fix:** Updated the contracts to verify the current deny-by-default `OperatorAuthorization`, native route macro, and proof-limit guidance.
- **Files modified:** `test/support/lockspire/release_proof/documentation_assertions.ex`, `test/support/lockspire/web/admin_proof/route_assertions.ex`.
- **Verification:** Final phase union passed 144 tests; clean `mix test.fast` passed 2,006.
- **Committed in:** `13e673ce`.

**2. [Rule 1 - Bug] Update stale direct-route assertions after the demo moved to the canonical macro**
- **Found during:** Task 2 full-suite verification.
- **Issue:** Existing contracts required literal `live/3` calls in the demo router and expected `AdminRouter` routes, although Phase 169-04 had moved those routes into `AdminRoutes`.
- **Fix:** Assert the actual macro declaration, shared inventory ordering, compiled route inventory, host layout, and absence of the old forward.
- **Files modified:** `test/lockspire/adoption_demo_docker_contract_test.exs`, `test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs`.
- **Verification:** Focused demo/runtime tests passed; final phase union and clean full suite passed.
- **Committed in:** `13e673ce`.

**3. [Rule 3 - Blocking] Align the generated router template with the formatted fixture**
- **Found during:** Task 2 clean full-suite verification.
- **Issue:** The emitted router omitted a blank line after the `AdminRoutes` requirement, so generator parity tests failed and the generated source was not formatter-clean.
- **Fix:** Added the blank line to the template; kept the fixture aligned.
- **Files modified:** `priv/templates/lockspire.install/router.ex`, `test/support/generated_host_app_web/router/lockspire.ex`.
- **Verification:** Generator selector passed 15 tests; final clean fast suite passed 2,006; formatter check passed.
- **Committed in:** `13e673ce`.

**4. [Rule 3 - Blocking] Remove planning labels from runtime-facing proof explanations**
- **Found during:** Task 2 `mix test.fast` readability contract.
- **Issue:** Runtime and Mix task help text named a roadmap phase, violating the existing runtime source rule and making the proof explanation planning-specific.
- **Fix:** Replaced the planning label with durable language describing packaged-consumer browser and supported-version evidence limits.
- **Files modified:** `lib/lockspire/install/verify.ex`, `lib/mix/tasks/lockspire.verify.ex`.
- **Verification:** Readability contract passed in final `mix test.fast`; phase verifier tests passed in the 144-test union.
- **Committed in:** `13e673ce`.

**5. [Rule 3 - Blocking] Remove pre-existing whitespace flagged by the required diff check**
- **Found during:** Task 2 final whitespace verification.
- **Issue:** Two trailing spaces in the phase pattern map caused `git diff --check 9500bb4707e24639886382ad5f5e0f0d89488bb9` to fail.
- **Fix:** Removed the trailing spaces without changing the map content.
- **Files modified:** `.planning/phases/169-install-and-upgrade-convergence/169-PATTERNS.md`.
- **Verification:** Required `git diff --check` passed.
- **Committed in:** `95a4f8d4`.

**Total deviations:** 5 auto-fixed (2 existing-contract corrections, 3 gate-blocking corrections). **Impact:** All changes directly supported the plan's current-source behavior and required verification; no product scope or dependencies were added.

## Issues Encountered

- An initial fast-suite run against the existing persistent `lockspire_test` database found stale rows and 16 failures. A focused fresh-database run passed 131 tests; the final full suite on a separate fresh database passed 2,006. No drop or truncate command was run against the existing database.
- The generated router and source fixtures emit existing compiler/type-analysis warnings. They did not fail the final checks and unrelated warnings were left unchanged.
- `git diff --check` initially flagged two whitespace lines in the phase pattern map; those were corrected and the exact required check passed.

## Known Stubs

None. A-169-HDX-04 remains an unresolved, unclassified assumption rather than an implementation stub or acceptance criterion.

## User Setup Required

None — no external service, secret, package installation, or manual browser verification was required for this plan.

## Next Phase Readiness

The docs, ExDoc/package inventory, verifier wording, generator contracts, demo, and clean-room hosts now present one consistent adoption model. Phase 170 can run the still-open package-consumer, real browser/socket, exact dependency-floor, and required-CI proof without treating Phase 169 repository tests as substitutes. The shared project tracking files were left to the parent executor, and `.planning/state.json` remains byte-identical to the user's pre-execution snapshot.

---
*Phase: 169-install-and-upgrade-convergence*
*Completed: 2026-10-23*

## Self-Check: PASSED

- Summary written to the planned path and UAT/validation artifacts are present.
- Plan commit ledger measured four commits from `51e258be4af105f3fd95764ba389e2233ea14c97` through `a8e22e8a2712dd175b7beb6bf871d8271cf02557`.
- All four plan commits are ancestors of the current branch head.
- `gsd-tools check evaluation-scope --plan 169-05 --commits-only --raw` resolved all four Plan 169-05 commits with no missing or unreachable commits.
- Final phase union passed 144 tests, formatter check passed, clean full fast suite passed 2,006 tests/properties, and required diff check passed.
- `.planning/state.json` remains byte-identical to `/tmp/lockspire169-user-state.json`; shared state and roadmap files were not staged.
