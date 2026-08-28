---
phase: 129
plan: 03
status: complete
---

# Phase 129 Plan 03: Primary Private JWK Consumers Summary

Introduced total, fail-closed `PrivateJwk.decode/1` and moved access-token, ID-token, and JARM signing to it.

## Verification

- `mix test test/lockspire/protocol/private_jwk_test.exs test/lockspire/protocol/access_token_signer_test.exs test/lockspire/protocol/id_token_test.exs test/lockspire/protocol/jarm_test.exs`
- `mix qa`

## Commits

- `9a0d60e` refactor(129): centralize token policy and key decoding
- `a9ff0df` fix(129): preserve decoder failure boundary
