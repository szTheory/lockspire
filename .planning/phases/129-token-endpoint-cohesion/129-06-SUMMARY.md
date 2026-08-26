---
phase: 129
plan: 06
status: complete
---

# Phase 129 Plan 06: CIBA Grant Boundary Summary

Added internal `CibaGrant` dispatch while preserving the public Push worker contract and the existing poll/Push redemption behavior.

## Verification

- `mix test test/lockspire/protocol/token_exchange_test.exs test/integration/phase53_ciba_delivery_modes_e2e_test.exs --seed 0`

## Commits

- `9a0d60e` refactor(129): centralize token policy and key decoding
