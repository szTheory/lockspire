---
phase: 135-cohesive-internals
plan: 09
subsystem: architecture-quality
tags: [fitness, compatibility, atomicity, oauth, qa]
requirements-completed: [COH-01, COH-02, COH-03, COH-04, COH-05]
status: complete
requires: [135-05, 135-08]
provides:
  - Parse-once AST architecture fitness with synthetic regression examples
  - Explicit token dependency capability declarations without runtime probes
  - Final compatibility, atomicity, five-grant, QA, and documentation evidence
affects: [storage, token-exchange, ci]
key-files:
  modified:
    - test/lockspire/architecture_fitness_test.exs
    - lib/lockspire/protocol/token_exchange/internal/dependencies.ex
    - lib/lockspire/storage/ecto/repository/token_store.ex
    - lib/lockspire/storage/ecto/repository/initial_access_token_store.ex
decisions:
  - Token dependency capabilities are declared during legacy option normalization, never discovered on protocol paths.
  - Reuse-family revocation remains authoritative while operator family revocation is idempotent.
---

# Phase 135 Plan 09: Final Convergence Summary

Permanent AST fitness, compatibility characterization, atomic lifecycle behavior, and the repository quality gates now protect the cohesive-internals refactor.

## Completed Work

- Added parse-once AST checks for pure Repository delegation, aggregate ownership, focused token collaborators, explicit dependency threading, and forbidden runtime capability, environment, and request-option probes. Every predicate has allowed and violating synthetic examples.
- Replaced token-internal `function_exported?/3` behavior with capabilities declared by `LegacyOptions` in the typed dependency bundle.
- Corrected chronological expiration comparisons for refresh rotation and initial access token redemption, kept refresh-reuse family containment authoritative, and made operator family revocation idempotent.
- Made persisted characterization inputs unique, refreshed stale storage walkthrough anchors, formatted final fixtures, simplified six public compatibility wrappers, and removed hidden internal type references from generated docs.

## Verification

- `mix compile --warnings-as-errors` — passed.
- Focused public-wrapper and five-flow characterization suite — 35 tests, 0 failures.
- Compatibility, atomicity, characterization, and mounted token-controller suite — 32 tests, 0 failures.
- `mix test.fast` — 1,392 tests, 0 failures, 6 skipped.
- `mix test.integration` — 283 tests, 0 failures.
- `mix credo --strict` — 0 issues across 538 source files.
- `mix qa` — passed; architecture topology reports no cycles and 13 tests, 0 failures.
- `mix docs.verify` — passed.

## Task Commits

1. `a92548fc` — enforce cohesive token architecture.
2. `1bcbac86` — preserve atomic lifecycle behavior.
3. `90237deb` — retain reuse-family revocation semantics.
4. `a100f1e4` — format final convergence fixtures.
5. `a1d0f824` — simplify public token wrappers.
6. `37271718` — keep internal dependency types out of docs.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Replaced term ordering of `DateTime` structs with `DateTime.compare/2` for refresh and initial-access-token expiration checks.
2. [Rule 1 - Bug] Separated idempotent operator family revocation from security-critical refresh-reuse family revocation so reuse containment still updates the full family.
3. [Rule 3 - QA] Formatted final convergence fixtures and replaced six Credo-flagged single-clause `with` wrappers with equivalent `case` expressions.

## Self-Check: PASSED

- All task commits are present in git history.
- No stubs or skipped verification remain in plan-owned work.
