---
phase: 134-architecture-topology
plan: 08
subsystem: token-grant-topology
tags: [oauth, refresh-token, rfc8693, token-exchange, xref]
requires: [134-07]
provides:
  - Neutral refresh-token rotation implementation
  - Neutral RFC 8693 token-exchange implementation
  - Retained public grant facades
affects: [refresh-exchange, rfc8693-exchange, token-exchange]
tech-stack:
  added: []
  patterns: [neutral result spine, one-way compatibility facade]
key-files:
  created:
    - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
    - lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex
  modified:
    - lib/lockspire/protocol/refresh_exchange.ex
    - lib/lockspire/protocol/rfc8693_exchange.ex
    - test/lockspire/protocol/refresh_exchange_test.exs
    - test/lockspire/protocol/rfc8693_exchange_test.exs
decisions:
  - Refresh and RFC 8693 internals consume internal signer/DPoP collaborators and return TokenResult values; retained modules alone convert at their public boundary.
metrics:
  duration: 6m
  completed: 2026-08-27
status: complete
---

# Phase 134 Plan 08: Neutral Refresh and RFC 8693 Summary

Refresh rotation and RFC 8693 exchange now operate on the neutral token-result spine while their public facades continue to return the exact established TokenExchange structs.

## Completed Work

- Moved the refresh lifecycle implementation under `TokenExchange.Internal`, swapping public signer/DPoP dependencies for their neutral internal counterparts.
- Kept `RefreshExchange.exchange_refresh_token/2` as a public-compatible adapter that converts neutral success/error values through `Compatibility` only at its boundary.
- Moved RFC 8693 validation, delegation, signing, persistence, and error paths under `TokenExchange.Internal` using neutral values.
- Kept `Rfc8693Exchange.exchange/2` as the compatible public adapter.
- Added durable public-arity assertions alongside existing rotation/reuse, resource, DPoP, persistence, subject/actor/delegation, and validator coverage.

## Verification

- `mix test test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/rfc8693_exchange_test.exs test/lockspire/protocol/token_result_test.exs` — 28 tests, 0 failures.
- `mix xref graph --format cycles` — one dispatcher-level token cycle remains for Plan 10; internal refresh/RFC modules contain no `TokenExchange.Success`, `TokenExchange.Error`, or `Compatibility` dependency.

## Commits

- `c5f0f7f` — refactor(134-08): isolate refresh exchange internals
- `b74df8f` — refactor(134-08): isolate RFC 8693 exchange internals

## Deviations from Plan

None — the established focused suites already supplied the requested security outcome matrix; public arity checks were added as durable compatibility characterization.

No new network endpoints or persistence boundaries were introduced. Refresh family-wide reuse containment, transaction behavior, delegation policy, and safe OAuth error fields remain owned by their original logic.

## Self-Check: PASSED

- Both neutral internal grant modules and both retained facades exist.
- Both Plan 08 implementation commits are present in git history.
