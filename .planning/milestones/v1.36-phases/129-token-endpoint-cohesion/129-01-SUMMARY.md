---
phase: 129
plan: 01
status: complete
---

# Phase 129 Plan 01: Authorization Code Boundary Summary

Moved authorization-code request authentication, DPoP resolution, code lookup, and error emission into `AuthorizationCodeGrant`; `TokenExchange` now remains the stable public router and result-struct owner. Token lifetime defaults have one internal owner.

## Verification

- `mix test test/lockspire/protocol/token_exchange_test.exs --seed 0`
- `mix compile --warnings-as-errors`

## Commits

- `9a0d60e` refactor(129): centralize token policy and key decoding
- `0eb3d98` refactor(129): move grant orchestration behind facade
