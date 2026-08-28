---
phase: 137-ci-conformance-and-release-proof
plan: 03
subsystem: testing
tags: [coverage, oauth, oidc, phoenix, ecto]
requires:
  - phase: 137-ci-conformance-and-release-proof
    provides: complete fast-plus-integration coverage aggregation
provides:
  - Behavioral regression tests for PKCE, revocation authentication, and operator token views
  - Fresh single-run fast and integration coverage receipt above the complete threshold
affects: [ci, release-proof, oauth-protocol, admin-operator]
tech-stack:
  added: []
  patterns: [behavioral coverage tests, partitioned coverage evidence]
key-files:
  created:
    - test/lockspire/coverage/protocol_behavior_test.exs
    - test/lockspire/coverage/integration_surface_behavior_test.exs
    - test/lockspire/coverage/storage_operator_behavior_test.exs
  modified: []
key-decisions:
  - "Coverage tests assert OAuth wire outcomes and durable operator data, never source text or private implementation details."
  - "The complete receipt is based on one pinned fast partition and one pinned integration partition."
patterns-established:
  - "Use reusable TokenExchangeCase fixtures for security-sensitive protocol lifecycle tests."
requirements-completed: [CI-02]
coverage:
  - id: D1
    description: PKCE and revocation/operator failure paths retain observable fail-closed behavior.
    requirement: CI-02
    verification:
      - kind: integration
        ref: MIX_ENV=test mix test test/lockspire/coverage/protocol_behavior_test.exs test/lockspire/coverage/integration_surface_behavior_test.exs test/lockspire/coverage/storage_operator_behavior_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Native complete coverage aggregate exceeds the sustainable CI floor.
    requirement: CI-02
    verification:
      - kind: other
        ref: .artifacts/coverage-137-03.78SjG4/aggregate/coverage-receipt.json
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-27
status: complete
---

# Phase 137 Plan 03: Behavior-Driven Coverage Summary

**OAuth protocol, HTTP boundary, and operator-token regressions now have direct behavioral proof, with a one-fast plus one-integration aggregate of 84.76%.**

## Accomplishments

- Proved missing PKCE verifier requests fail closed without consuming the authorization code.
- Proved an unauthenticated revocation request receives the OAuth client-authentication failure contract.
- Proved absent token semantics and redacted operator token handles across the durable admin service boundary.
- Exported exactly one fast and one integration partition for source SHA `aa509b26f75e6c45b554a8f79c35135f283eb60d`; the native complete receipt is **84.76%**, exceeding the 84.00% floor.

## Task Commits

1. **Task 1: Protocol behavior** - `c739a290` (RED), `72c06f48` (green)
2. **Task 2: Request-level host boundary** - `7fa9fa42`
3. **Task 3: Storage and operator behavior** - `1bcd6dd9` (RED), `19c04690` and `1cb32855` (green)

## Verification

- `MIX_ENV=test mix test test/lockspire/coverage/protocol_behavior_test.exs test/lockspire/coverage/integration_surface_behavior_test.exs test/lockspire/coverage/storage_operator_behavior_test.exs` — 4 tests, 0 failures.
- `mix format --check-formatted` on the three suites — passed.
- Fresh `scripts/ci/run_test_matrix.sh --fast` — passed in 19 seconds.
- Fresh `scripts/ci/run_test_matrix.sh --integration` — integration tests passed in 36 seconds; clean-room proof passed in 44 seconds.
- Fresh `scripts/ci/aggregate_coverage.sh` — 84.76% total; receipt recorded in `.artifacts/coverage-137-03.78SjG4/aggregate/coverage-receipt.json`.

## Deviations from Plan

None - plan executed with test-only behavioral additions and no production exclusions, threshold changes, or duplicate partitions.

## Self-Check: PASSED

All three owned suites and this summary exist; commits `c739a290`, `72c06f48`, `7fa9fa42`, `1bcd6dd9`, `19c04690`, and `1cb32855` are present in git history.
