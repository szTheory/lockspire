---
phase: 133-clean-room-saas-journey
plan: 06
subsystem: clean-room acceptance and CI
tags: [oauth, oidc, dpop, replay-protection, ci, postgres]
requires:
  - phase: 133-05
    provides: bearer lifecycle and negative HTTP journey evidence
provides:
  - opaque client-owned DPoP resource nonce and exact-proof replay evidence
  - durable replay rejection across provider restart using the configured repository
  - discoverable clean-room E2E alias and bounded child dependency CI cache
affects: [phase-133-verification, ci, clean-room acceptance]
tech-stack:
  added: []
  patterns: [opaque encrypted DPoP session state, safe HTTP receipts, dependency-only child cache]
key-files:
  modified:
    - scripts/acceptance/clean_room_saas_journey.py
    - test/integration/phase133_clean_room_saas_journey_test.exs
    - mix.exs
    - scripts/ci/run_test_matrix.sh
    - .github/workflows/ci.yml
key-decisions:
  - "The client owns encrypted DPoP key, token, nonce, and exact proof state; the runner observes only allowlisted receipts."
  - "Protected-resource replay uses the documented DPoP invalid_token challenge, while the token endpoint retains its own error contract."
  - "Root ExUnit ignores nested child-app tests; the child builder remains their sole test owner."
requirements-completed: [E2E-01, E2E-05, E2E-06]
coverage:
  - id: D1
    description: DPoP token and userinfo nonce retries, resource nonce retry, exact replay rejection, and restart durability over real HTTP.
    requirement: E2E-06
    verification:
      - kind: integration
        ref: mix test test/integration/phase133_clean_room_saas_journey_test.exs --only dpop
        status: pass
    human_judgment: false
  - id: D2
    description: One clean-room command performs the full journey with redaction scanning and teardown.
    requirement: E2E-01
    verification:
      - kind: integration
        ref: mix test.clean-room.e2e
        status: pass
    human_judgment: false
  - id: D3
    description: CI-compatible full journey preserves lifecycle and negative wire evidence without retaining sensitive material.
    requirement: E2E-05
    verification:
      - kind: integration
        ref: mix test.integration
        status: pass
    human_judgment: false
status: complete
---

# Phase 133 Plan 06: Durable DPoP Acceptance and CI Summary

The clean-room SaaS journey now proves DPoP-bound resource access, byte-identical replay rejection before and after provider restart, and a maintained CI entry point.

## Accomplishments

- Completed the fixed confidential DPoP route through AS and userinfo nonce retries, then handed encrypted state to an opaque client session.
- Proved a resource nonce challenge, fresh proof success, same-byte rejection, and durable post-restart replay denial without replay-store injection or row inspection.
- Added `mix test.clean-room.e2e`, integration-lane timing, and lock/runtime-keyed dependency-only caching for provider and client children.
- Kept console and retained evidence redacted, verified exact teardown, and excluded nested child-app tests from root ExUnit discovery.

## Verification

- `mix test test/integration/phase133_clean_room_saas_journey_test.exs --only dpop` — 1 test, 0 failures.
- Direct DPoP runner — all token, userinfo, resource challenge/retry, exact replay, and post-restart markers passed.
- `mix test.clean-room.e2e` — passed.
- `mix test.fast` — 1,351 tests, 0 failures.
- `mix test.integration` — 269 tests, 0 failures.
- `mix qa` — Credo clean; Sobelow complete.
- `mix docs.verify` — warning-free documentation generation.

## Task Commits

1. `2ef40ed` — test-first durable DPoP journey contract.
2. `2c5e2cf` — encrypted client-owned DPoP resource replay flow.
3. `d04fb2b` — discoverable clean-room CI gate.
4. `e4558ad` — complete durable replay proof and correct focused command.
5. `12a3b24` — complete acceptance teardown and evidence handling.
6. `ec644a7` — restrict root ExUnit from nested fixture tests.
7. `e9c22db` — ratchet clean-room command and CI contracts.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 2 - Missing critical functionality] Completed the client-owned DPoP composition seam.**
   Existing encrypted key/session primitives were not wired through callback, resource nonce, and exact replay operations. The fixture now keeps all credential and proof material server-side and exposes only safe receipts.

2. **[Rule 1 - Bug] Matched replay validation to the protected-resource challenge contract.**
   Protected-resource replay returns `invalid_token`; the client now requires that documented HTTP denial rather than token-endpoint-style `invalid_dpop_proof`.

3. **[Rule 1 - Bug] Excluded nested fixture tests from root ExUnit discovery.**
   The root suite previously loaded the child application’s isolated tests without its dependencies; root and child test ownership are now separated.

## Self-Check: PASSED

- All seven implementation commits exist.
- Isolated DPoP, clean-room alias, fast, integration, QA, and documentation gates passed after the final fixes.
