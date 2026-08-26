---
phase: 131-executable-installation
plan: "01"
subsystem: installation
tags: [phoenix, generator, router, oauth, oidc]
requires: []
provides:
  - executable-generated-router-macro
  - truthful-generated-config-and-claims-example
affects: [131-02, installation, host-integration]
tech_stack:
  added: []
  patterns: [Phoenix router macro, compiled generated-host fixture]
key_files:
  created:
    - test/support/generated_host_app_web/plugs/require_operator.ex
  modified:
    - priv/templates/lockspire.install/router.ex
    - priv/templates/lockspire.install/config.exs
    - priv/templates/lockspire.install/account_resolver.ex
    - test/support/generated_host_app_web/router.ex
    - test/support/generated_host_app_web/router/lockspire.ex
    - test/integration/install_generator_test.exs
decisions:
  - Generated Lockspire routes expand as an imported Phoenix macro, with host routes before guarded admin and public forwards.
  - The host fixture owns a real operator authorization plug and generated configuration declares the host logout path.
metrics:
  duration: 8m
  completed: 2026-08-26
  tasks_completed: 2
  files_changed: 7
status: complete
---

# Phase 131 Plan 01: Executable Installation Summary

Generated Lockspire host integration now expands into actual Phoenix routes and its configuration and Claims examples compile truthfully.

## Tasks Completed

1. **Compile the rendered route macro through the generated host** — The generated helper is an imported `defmacro`, the fixture invokes it in its real Phoenix router, and route-table assertions prove host routes precede the operator-guarded admin forward and public Lockspire mount.
2. **Compile truthful generated config and claims seams** — The generated config has a host-owned `logout_path`; the resolver example uses only `subject`, `id_token`, and `userinfo`, and rendered output is evaluated and compiled in the integration test.

## Verification

- `mix test test/integration/install_generator_test.exs` — 8 tests passed.
- `mix compile --warnings-as-errors` — passed.
- The negative generated-router fixture fails compilation when its host `:require_operator` pipeline is omitted, proving the admin mount cannot silently downgrade its authorization boundary.

## Commits

- `47332f5` — `test(131-01): prove generated router compiles`
- `4eae42d` — `feat(131-01): generate executable host routes`
- `a8c74ea` — `test(131-01): compile generated config seams`
- `e70d521` — `fix(131-01): make generated config truthful`
- `850524c` — `fix(131-01): preserve upgrade route proof`

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 2 - Missing authorization fixture] Added a concrete host-owned operator plug**
   - **Found during:** Task 1
   - **Issue:** A named Phoenix pipeline alone did not demonstrate an executable authorization boundary for the generated admin forward.
   - **Fix:** Added the generated-host fixture's `RequireOperator` Plug, which allows only a host scope explicitly marked `operator?: true` and otherwise returns a halted 403 response.
   - **Files modified:** `test/support/generated_host_app_web/plugs/require_operator.ex`, `test/support/generated_host_app_web/router.ex`
   - **Verification:** Compiled route test and missing-pipeline compilation test pass.
   - **Commit:** `4eae42d`

**Total deviations:** 1 auto-fixed (Rule 2). **Impact:** The fixture now proves a real host-owned operator boundary without putting any operator authentication behavior into Lockspire's generated macro.

### Follow-up Regression Repair

The Wave 1 cumulative fast-suite gate found that `InstallUpgradeTest` still asserted the pre-formatter text form of the public forward. The assertion now parses rendered router source and proves the exact `/oauth` → `Lockspire.Web.Router` AST relationship, so valid formatting changes do not weaken or break upgrade evidence.

- **Verification:** `mix test test/integration/install_upgrade_test.exs`, `mix test test/integration/install_generator_test.exs`, and `mix test.fast --max-failures 1` (1,301 tests, 0 failures).
- **Commit:** `850524c`

## Self-Check: PASSED

- Generated router macro, host router fixture, and operator plug exist and are committed.
- All four task commits are present in git history.
- High-severity T-131-01 and T-131-02 have named green automated evidence from the integration test.
