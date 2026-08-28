---
phase: 136-static-analysis-and-sustainable-proof
plan: "09"
subsystem: leaf-callers-and-tooling
tags: [dialyzer, liveview, dcr, installer, migrations]
requires: [136-08]
provides: [zero-warning-dialyzer-baseline, truthful-admin-and-installer-control-flow]
affects: [136-11]
tech-stack:
  added: []
  patterns: [reachable-result-matches, explicit-no-return-refusals]
key-files:
  modified:
    - lib/lockspire/admin/tokens.ex
    - lib/lockspire/web/live/admin/iat_live/new.ex
    - lib/lockspire/web/live/admin/tokens_live/show.ex
    - lib/lockspire/generators/install.ex
    - lib/lockspire/install/migrations.ex
    - lib/mix/tasks/lockspire.upgrade.ex
decisions:
  - Admin leaf callers retain only result branches their owning collaborators can return.
  - Installer and upgrade refusal helpers are explicitly non-returning so unsafe host changes cannot continue.
metrics:
  tasks_completed: 2
  tests: 71
  dialyzer_errors: 0
  dialyzer_skipped: 0
status: complete
---

# Phase 136 Plan 09: Leaf Caller and Tooling Dialyzer Summary

Admin, installer, and migration leaf callers now reflect their actual collaborator results, producing the project’s first zero-warning Dialyzer baseline without suppressions.

## Accomplishments

- Removed only impossible admin error branches while retaining token-family no-family handling and IAT plaintext disclosure flow.
- Preserved HTTP and rendered admin behavior, including filtered credential values and safe failure copy.
- Declared generator and upgrade refusal helpers as `no_return()` and removed the migration error clause already covered by the real return union.
- Reached zero Dialyzer errors, zero skipped checks, and zero unnecessary skips with no ignore baseline.

## Verification

- `mix test test/lockspire/web/controllers/registration_controller_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs` — 36 tests, 0 failures.
- `mix test --include integration test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/install/migrations_test.exs` — 35 tests, 0 failures.
- `mix qa.dialyzer` — 0 errors, 0 skipped, 0 unnecessary skips; no ignore baseline configured.

## Task Commits

1. `03d261f5` — remove impossible admin result branches.
2. `51cd9b60` — type installer termination paths.

## Deviations from Plan

None - every removed branch was confirmed impossible by Dialyzer and covered by the existing HTTP, LiveView, and installer proof.

## Known Stubs

None.

## Self-Check: PASSED

- Both task commits are present in git history.
- The final Dialyzer capture reports no project source diagnostics.
