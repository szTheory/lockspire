---
phase: 163-app-lifetime-compatible-host-storage
plan: "14"
subsystem: host-guidance-and-coverage
tags: [client-lifetime, migration-guidance, compatibility, coverage]
dependency-graph:
  requires: [163-01-through-163-13, 162-lifetime-semantics-upgrade-contract]
  provides: [host-lifetime-upgrade-guidance, app-consumer-coverage, source-decision-audit]
  affects: [host-upgrades, compatibility-contract, phase-163-validation]
tech-stack:
  added: []
  patterns: [prefix-aware-upgrade-guidance, literal-baseline-with-declared-additive-arities]
key-files:
  created:
    - docs/upgrading/client-lifetimes.md
    - test/lockspire/client_lifetime_guidance_test.exs
    - .planning/phases/163-app-lifetime-compatible-host-storage/163-COVERAGE.md
    - .planning/phases/163-app-lifetime-compatible-host-storage/163-SOURCE-AUDIT.md
  modified:
    - docs/upgrading/storage-prefix.md
    - docs/dynamic-registration.md
    - docs/architecture.md
    - test/lockspire/client_lifecycle_test.exs
    - test/lockspire/compatibility_baseline_contract_test.exs
    - test/support/architecture/public_compatibility_manifest.ex
    - .planning/phases/163-app-lifetime-compatible-host-storage/163-VALIDATION.md
decisions:
  - Keep the original AuthorizationRequest v1.x function arities as the literal baseline and separately declare the explicit option-bearing validate/2 and validate_pushed/3 additions.
  - Keep host guidance bound to the observed additive package journey and document the post-v1 fix-forward boundary.
metrics:
  duration: focused guidance work plus fresh 222.2s full-suite gate
  completed: 2026-10-20
  tasks: 2
  files: 11
  commits: 0
status: complete
actuals:
  tokens: 23431
  tasks: 2
  commits: 0
---

# Phase 163 Plan 14: Host Lifetime Guidance and Evidence Summary

Host documentation now describes the exercised prefix-aware migration, custom adapter and shared transaction contract, all-writer drain, first-v1 rollback boundary, and online/offline limits. The app consumer inventory, source audit, and validation record are tied to focused tests and the actual packaged PostgreSQL journey.

## Delivered

- Added [client-lifetimes.md](../../../docs/upgrading/client-lifetimes.md) with installer commands, custom adapter declarations, conformance commands, representative legacy-row treatment, maintenance and lock-timeout guidance, drain/cutover sequence, post-v1 fix-forward policy, and offline JWT limitations.
- Added links from the storage-prefix, dynamic-registration, and architecture guidance.
- Added focused guidance and installer contract tests. The pre-existing lifecycle fixtures now explicitly use legacy lifetime version 0.
- Preserved the literal pre-refactor public API baseline while declaring the option-bearing `AuthorizationRequest.validate/2` and `validate_pushed/3` as intentional additive entrypoints.
- Added the C-APP-01–18 and C-TOK-01–03 proof map, all DCR-05/06/13/14 and roadmap criteria, research constraints/assumptions, and D-01–24 source audit.
- Updated `163-VALIDATION.md` with the fresh full-suite result, clean-database admin rerun, focused tests, previous independent PostgreSQL wait/rollback evidence, and verified package receipt. Independent review remains pending; later credential requirements and the Phase 166 umbrella item remain open.

## Verification

Focused command:

```text
mix test test/lockspire/compatibility_baseline_contract_test.exs test/lockspire/client_lifecycle_test.exs test/lockspire/client_lifetime_guidance_test.exs test/lockspire/install/migrations_test.exs
23 tests, 0 failures
```

Fresh full gate, using task-local Elixir 1.18.4 / OTP 27 and isolated database `lockspire_phase163_plan14_full`:

```text
mix test.fast
2 properties, 2290 tests, 0 failures, 398 excluded, 6 skipped; 222.2s
```

Complete output is at `/private/tmp/phase163-plan14-test-fast-fresh.log`. The previously failing admin LiveView files also passed on an isolated fresh database: 98 tests, 0 failures. The packaged upgrade receipt check passed for both prefixes; its SHA-256 is `5edde26983007bf875e6ea7e10fe273c5a0e5d764359ae1e5069fdc009fa9ebf`. `mix format --check-formatted` and `git diff --check` passed.

An earlier fast run against the pre-existing default test database reported 16 failures. Two direct lifecycle fixtures were corrected to include `lifetime_version: 0`; the compatibility contract now explicitly lists the additive option-bearing arities; and the database-sensitive admin files passed in isolation and in the full fresh-database run. The initial log remains at `/private/tmp/phase163-plan14-test-fast.log` for traceability.

The independent PostgreSQL wait/rollback suite was recorded by plan 163-12 as 13 tests, 0 failures. Its `Sandbox.unboxed_run` fixtures register teardown that removes persisted client-scoped rows, including CIBA rows in grant-wait cases. Those tagged tests are among tests excluded from `mix test.fast`; the full-suite count does not replace their focused proof.

## Deviations from Plan

**1. [Rule 2 - Missing fixture contract] Set explicit legacy lifetime version in two direct lifecycle fixtures.**

- **Found during:** full `mix test.fast`.
- **Issue:** Two old direct fixtures omitted the newly required lifetime version and failed to represent the intended legacy row.
- **Fix:** Set `lifetime_version: 0` in each fixture.
- **Files modified:** `test/lockspire/client_lifecycle_test.exs`.

**2. [Rule 1 - Compatibility contract drift] Record intentional additive authorization option arities.**

- **Found during:** full `mix test.fast`.
- **Issue:** The literal Phase 134 baseline correctly reported `validate/2` and `validate_pushed/3`, which support explicit adapter and clock options, as newly exported arities.
- **Fix:** Preserve and assert the old exact baseline, while listing and testing these two supported additive extensions separately.
- **Files modified:** `test/lockspire/compatibility_baseline_contract_test.exs`, `test/support/architecture/public_compatibility_manifest.ex`.

Parent execution workflow owns git commits and state tracking; this executor did not stage, commit, or update `STATE.md`, `ROADMAP.md`, or `REQUIREMENTS.md`.

## Self-Check: PASSED

- All listed guidance, test, coverage, audit, and validation artifacts exist.
- The fresh full fast suite passed with zero failures, the packaged receipt verified, and the focused compatibility/lifecycle/guidance/migration suite passed.
- Plan 14 is complete. Phase 163 remains pending independent verification and parent-level integration.

Parent implementation commit: `512a5bebe47da26fd48a305b258f139babb0744e`; parentfresh23tests0failures,fullfreshlog2290tests0failuresverified.
