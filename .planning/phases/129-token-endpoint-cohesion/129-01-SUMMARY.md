---
phase: 129
plan: 01
status: complete
---

# Phase 129 Plan 01: Authorization Code Boundary Summary

Added the stable authorization-code coordinator dispatch boundary while preserving the public `TokenExchange` API and result structs. Token lifetime defaults now have one internal owner.

## Verification

- `mix test test/lockspire/protocol/token_exchange_test.exs --seed 0`
- `mix compile --warnings-as-errors`

## Commits

- `9a0d60e` refactor(129): centralize token policy and key decoding
