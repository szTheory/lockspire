---
phase: 133-clean-room-saas-journey
plan: 05
subsystem: clean-room acceptance
tags: [oauth, oidc, refresh-token, introspection, revocation, negative-testing]
requires:
  - phase: 133-04
    provides: separate-origin confidential authorization-code journey
provides:
  - real HTTP refresh rotation, reuse containment, introspection, and idempotent revocation proof
  - independent live rejection matrix for redirect, callback state, code, nonce, token, audience, and scope failures
affects: [133-06, clean-room acceptance]
tech-stack:
  added: []
  patterns: [safe acceptance-only client receipts, redacted wire-level lifecycle assertions]
key-files:
  modified:
    - scripts/acceptance/clean_room_saas_journey.py
    - test/integration/phase133_clean_room_saas_journey_test.exs
key-decisions:
  - "Lifecycle evidence asserts durable authorization-server state through authenticated introspection, never immediate offline JWT invalidation."
  - "Client-side state and nonce failures use narrow safe receipts rather than provider rows or sensitive token output."
requirements-completed: [E2E-04, E2E-05]
coverage:
  - id: D1
    description: Refresh rotation, family reuse containment, authenticated introspection, and idempotent revocation over live HTTP.
    requirement: E2E-04
    verification:
      - kind: integration
        ref: mix test --include integration test/integration/phase133_clean_room_saas_journey_test.exs --only lifecycle
        status: pass
    human_judgment: false
  - id: D2
    description: Redirect, state, nonce, code, token, audience, and scope negative outcomes over live HTTP.
    requirement: E2E-05
    verification:
      - kind: integration
        ref: mix test --include integration test/integration/phase133_clean_room_saas_journey_test.exs --only negative
        status: pass
    human_judgment: false
status: complete
---

# Phase 133 Plan 05: Lifecycle and Negative Matrix Summary

The clean-room acceptance journey now proves refresh-family containment and every planned non-DPoP failure through redacted, stable HTTP outcomes.

## Accomplishments

- Added a fresh confidential lifecycle transaction with PKCE, distinct refresh rotation, replay rejection, authenticated inactive introspection, and repeat revocation success.
- Added independent real-listener cases for redirect drift, code reuse, callback-state terminality, client nonce validation, missing token, wrong audience, and insufficient scope.
- Kept fixture diagnostics safe: the acceptance client exposes only a nonce-replaced acknowledgment and a token-exchange attempt count; no token, secret, code, verifier, cookie, or claims leave process memory.

## Verification

- Passed: `mix test --include integration test/integration/phase133_clean_room_saas_journey_test.exs --only lifecycle`
- Passed: `mix test --include integration test/integration/phase133_clean_room_saas_journey_test.exs --only negative`
- Passed: `mix test --include integration test/integration/phase133_clean_room_saas_journey_test.exs --only happy_path --only boundary`
- Passed: `python3 scripts/acceptance/clean_room_saas_journey.py --only negative`

## Task Commits

1. Task 1 RED: `39011bb` — lifecycle proof test.
2. Task 1 GREEN: `281ed12` — live refresh lifecycle proof.
3. Task 2 RED: `f204cad` — negative matrix test.
4. Task 2 GREEN: `2925027` — live negative wire matrix.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 2 - Missing critical functionality] Enabled `offline_access` only in the isolated fixture.**
   Refresh issuance requires it, so the clean-room client registration and generated provider configuration now declare the scope.

2. **[Rule 2 - Missing critical functionality] Added fixture-only safe client receipts.**
   A controlled nonce replacement and exchange-attempt counter prove nonce and state failures without inspecting provider internals.

## Self-Check: PASSED

- All four TDD commits exist.
- Focused lifecycle, negative, and Plan 04 regression commands passed.
