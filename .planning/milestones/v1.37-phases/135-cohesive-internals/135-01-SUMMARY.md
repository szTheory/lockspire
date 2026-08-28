---
phase: 135-cohesive-internals
plan: 01
subsystem: OAuth/OIDC token facade and Ecto durability
tags: [characterization, oauth, oidc, ecto, transactions]
status: complete
provides:
  - Stable authorization-code, refresh, device, and CIBA facade characterization
  - Mounted authorization-code replay wire contract
  - DB-backed single-winner authorization-code redemption proof
requires: []
affects: [135-02, 135-03, 135-04]
key-files:
  created:
    - test/support/token_exchange_characterization.ex
    - test/lockspire/protocol/token_exchange/characterization_test.exs
    - test/lockspire/storage/repository_atomicity_test.exs
  modified:
    - test/lockspire/web/token_controller_test.exs
---

# Phase 135 Plan 01: Token and Storage Characterization Summary

The public token facade now has a focused contract spine for all five grants: stable-facade outcomes, durable state, authorization-code replay audit/telemetry, and mounted OAuth success/error wire responses.

## Completed Tasks

1. Characterized the authorization-code S256 PKCE journey at the stable facade and mounted endpoint.
2. Expanded focused facade coverage to refresh, device, CIBA, and RFC 8693 paths and added DB-backed one-winner redemption, refresh-family revocation, DCR audit rollback, and guided key-transition coverage.

## Verification

`mix test test/lockspire/protocol/token_exchange/characterization_test.exs test/lockspire/storage/repository_atomicity_test.exs test/lockspire/web/token_controller_test.exs --trace`

Result: 26 tests, 0 failures.

## Decisions Made

- Kept characterization helpers observability-focused; they reuse `TokenExchangeCase` rather than reproducing grant implementation.
- Refresh rotation uses a distinct deterministic generator from initial issuance, matching the production uniqueness contract for token hashes.
- Storage characterizations assert state after a failed DCR audit append and guided key transitions rather than private repository call order.
- Mounted endpoint coverage retains status, cache headers, and JSON contracts for authorization-code, refresh, device, CIBA, and RFC 8693 flows.

## Deviations from Plan

### Investigated Rule 1 - Suspected refresh rotation bug

- **Found during:** Task 2
- **Issue:** A first implementation reused the same deterministic refresh-token generator for initial issuance and rotation, causing the repository's unique `token_hash` constraint to roll back the second insert.
- **Resolution:** This was a characterization fixture error, not a production defect. The test now supplies a distinct rotated token value; no production code changed.

## Self-Check: PASSED

- Characterization helper and three focused test files exist.
- RED and GREEN commits are present in repository history.
