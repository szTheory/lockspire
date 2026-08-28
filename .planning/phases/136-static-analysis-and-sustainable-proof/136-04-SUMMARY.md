---
phase: 136-static-analysis-and-sustainable-proof
plan: "04"
subsystem: admin-proof
tags: [exunit, admin, css, routes, redaction]
requires:
  - phase: 136-static-analysis-and-sustainable-proof
    provides: repository-relative proof cleanup baseline
provides:
  - explicit CSS and route capability proof helpers without macro-injected state
affects: [136-11]
key-files:
  created:
    - test/support/lockspire/web/admin_proof/paths.ex
    - test/support/lockspire/web/admin_proof/css_assertions.ex
    - test/support/lockspire/web/admin_proof/route_assertions.ex
  modified:
    - test/lockspire/web/live/admin/design_system/css_contract_test.exs
    - test/lockspire/web/live/admin/design_system/route_contract_test.exs
key-decisions:
  - "Admin visual and route proof exposes domain capability functions rather than injecting paths and assertions into test modules."
  - "Current router, source, documentation, and package contracts replace archived milestone inventories."
metrics:
  completed: 2026-08-27
status: complete
---

# Phase 136 Plan 04: Explicit Admin Capability Proof Summary

**CSS and route contracts now call focused helpers that read only current repository artifacts.**

## Accomplishments

- Added repository-rooted `Paths` accessors shared by narrow proof helpers.
- Replaced macro-injected CSS assertions with explicit checks for namespaced controls, semantic tokens, theme/focus/motion, responsive layouts, and redaction-safe long values.
- Replaced historical route scorecard checks with current mounted-route, host boundary, read-only operate, configure action, redaction, and package-ceiling contracts.

## Task Commits

1. Task 1 RED — `0d7737b8` `test(136-04): specify explicit CSS proof helpers`
2. Task 1 GREEN — `9e92fa9f` `refactor(136-04): extract explicit CSS proof`
3. Task 2 RED — `94350691` `test(136-04): specify explicit route proof helpers`
4. Task 2 GREEN — `90aa9445` `refactor(136-04): extract explicit route proof`

## Verification

- `mix test test/lockspire/web/live/admin/design_system/css_contract_test.exs test/lockspire/web/live/admin/design_system/route_contract_test.exs` — 13 tests, 0 failures.
- `mix compile --warnings-as-errors` — passed.
- `mix credo --strict` — 554 source files checked, no issues.

## Deviations from Plan

None - plan executed as specified. Existing macro-backed proof remains owned by later migration plans; these suites no longer depend on it or archived history.

## Known Stubs

None.

## Self-Check: PASSED

- All three explicit helper modules and both contract suites exist.
- All four task commits are present in git history.
