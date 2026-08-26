---
phase: 129
plan: 06
status: complete
---

# Phase 129 Plan 06: CIBA Grant Boundary Summary

Moved CIBA client authentication, poll-state lookup, DPoP resolution, and Push issuance delegation into `CibaGrant`; the public worker contract and poll/Push behavior remain unchanged.

## Verification

- `mix test test/lockspire/protocol/token_exchange_test.exs test/integration/phase53_ciba_delivery_modes_e2e_test.exs --seed 0`

## Commits

- `9a0d60e` refactor(129): centralize token policy and key decoding
- `0eb3d98` refactor(129): move grant orchestration behind facade
