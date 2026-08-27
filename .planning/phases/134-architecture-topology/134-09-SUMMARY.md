---
phase: 134-architecture-topology
plan: 09
subsystem: token-grant-leaf-topology
tags: [oauth, authorization-code, device-flow, ciba, token-exchange]
requires: [134-08]
provides:
  - Neutral authorization-code and shared grant-support internals
  - Neutral device and CIBA grant internals
  - Retained public grant/helper facades
affects: [token-exchange, device-flow, ciba, authorization-code]
tech-stack:
  added: []
  patterns: [neutral result spine, public facade conversion]
key-files:
  created:
    - lib/lockspire/protocol/token_exchange/internal/grant_support.ex
    - lib/lockspire/protocol/token_exchange/internal/authorization_code_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/device_code_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex
  modified:
    - lib/lockspire/protocol/token_exchange/grant_support.ex
    - lib/lockspire/protocol/token_exchange/authorization_code_grant.ex
    - lib/lockspire/protocol/token_exchange/device_code_grant.ex
    - lib/lockspire/protocol/token_exchange/ciba_grant.ex
    - lib/lockspire/protocol/token_exchange/compatibility.ex
decisions:
  - Grant support and every grant leaf operate on TokenResult internally; public facade modules alone project token outcomes back into the retained public structs.
metrics:
  duration: 7m
  completed: 2026-08-27
status: complete
---

# Phase 134 Plan 09: Neutral Token Grant Leaves Summary

Authorization-code, device, CIBA, and shared redemption orchestration now consume neutral token values behind public-compatible facades, leaving only dispatcher inversion for Plan 10.

## Completed Work

- Moved authorization-code and shared `GrantSupport` orchestration into `TokenExchange.Internal`, using internal signer/DPoP collaborators and `TokenResult` values.
- Retained every public `GrantSupport` helper and converted token-shaped outcomes at the facade edge while passing domain outcomes through unchanged.
- Moved device and CIBA grant state machines into neutral internal leaf modules.
- Retained `AuthorizationCodeGrant.exchange/1`, `DeviceCodeGrant.exchange/1`, `CibaGrant.exchange/1`, and `CibaGrant.issue_tokens/4` as compatible public facades.
- Preserved established polling, atomic redemption, audit, telemetry, PKCE, resource, DPoP, and safe-error tests.

## Verification

- `mix test test/lockspire/protocol/token_exchange/authorization_code_test.exs test/lockspire/protocol/token_exchange/ciba_and_resource_test.exs test/lockspire/protocol/token_exchange/device_code_test.exs test/lockspire/protocol/token_exchange/delegation_test.exs` — 39 tests, 0 failures.
- `mix xref graph --format cycles` — the expected dispatcher-level token cycle remains for Plan 10; all new internal grant modules have no public `TokenExchange.Success`, `TokenExchange.Error`, or `Compatibility` dependency.

## Commits

- `5a1038d` — refactor(134-09): isolate authorization-code grant support
- `3be3f3d` — refactor(134-09): isolate device and CIBA grant leaves

## Deviations from Plan

None — existing focused capability and state-matrix suites supplied the requested security characterization while the public facades preserved their exact callable shapes.

No new endpoints, stores, or trust boundaries were introduced. Grant support continues to own the original repository atomicity, audit, and telemetry paths; compatibility adapters change only result representation.

## Self-Check: PASSED

- All four internal grant modules and their public facades exist.
- Both Plan 09 commits are present in git history.
