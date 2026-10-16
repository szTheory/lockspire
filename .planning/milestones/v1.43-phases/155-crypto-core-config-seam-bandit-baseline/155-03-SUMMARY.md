---
phase: 155-crypto-core-config-seam-bandit-baseline
plan: 03
subsystem: security
tags: [envelope-encryption, private-jwk, signing-consumers]
requires: ["155-02"]
provides:
  - "PrivateJwk.decode/1 map-form only, envelope-aware, post-decrypt kid check"
  - "PrivateJwk.decode_with_reason/1 (@doc false) internal failure reasons"
  - "Six consumers pass the whole signing-key map"
  - "Fitness guard: JWKS/discovery/KeyCache never decrypt"
affects: [155-04, 155-05, 156]
tech-stack:
  added: []
  patterns: ["strict classify/1 dispatch, no legacy fallback on envelope errors"]
key-files:
  created:
    - test/lockspire/protocol/envelope_signing_consumers_test.exs
  modified:
    - lib/lockspire/protocol/private_jwk.ex
    - lib/lockspire/protocol/id_token.ex
    - lib/lockspire/protocol/logout_token.ex
    - lib/lockspire/protocol/jarm.ex
    - lib/lockspire/protocol/introspection_jwt.ex
    - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
    - lib/lockspire/protocol/jar.ex
    - test/lockspire/protocol/private_jwk_test.exs
    - test/lockspire/protocol/jar_test.exs
    - test/lockspire/audit/audit_writer_test.exs
    - test/lockspire/architecture_fitness_test.exs
key-decisions:
  - "Legacy rows get no kid check in 155 (legacy_plaintext not enforced until 156)"
  - "Map-form decode requires a binary kid; fixtures without kid were fixed, not the decoder relaxed"
requirements-completed: []
status: complete
duration: 25 min
completed: 2026-10-15
actuals:
  tokens: 30000
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 33d3b6f3c55a3642fad5310a058eb55d671a566b
plan_head_after: 6c0c4f8dd533fdfadeaa5b395d9714b02989ece0
---

# Phase 155 Plan 03: Envelope-aware PrivateJwk decode and consumer switch Summary

`PrivateJwk.decode/1` now takes only a key map (kid paired with ciphertext), opens `LSK` envelopes through the cached KEK set with a post-decrypt kid-equality check, still reads legacy JSON/ETF rows, and all six signing/decrypting consumers keep their own external error shapes.

## Tasks

1. Tracer: decoder plus ID token consumer, sealed/legacy/tampered proof (47e94cb2).
2. Remaining five consumers switched to pass the whole map (8c9eccc5).
3. Binary clause removed; per-consumer tests (sealed, tampered, unconfigured KEK); audit test; JWKS/discovery/KeyCache fitness test (6c0c4f8d).

## Deviations from Plan

**1. [Rule 3 - Blocking] jar_test fixture lacked a kid** - the "decrypts a 5-part JWE" fixture built a `%SigningKey{}` with `kid: nil`, which the map-form decoder rejects by design. Added `kid: "enc-kid"` to the fixture (commit 8c9eccc5).

**2. [Plan variance] Signer test seeding** - the access-token signer cases use an in-memory key store module (the existing test style) rather than `Repository.publish_key/1`; the signer path under test is identical and needs no DB.

**Toolchain:** CI toolchain (Elixir 1.19.5 / OTP 28.1) used instead of 1.20.4 / OTP 29.1.1.

## Verification

- Targeted: private_jwk, envelope_signing_consumers, audit_writer, architecture_fitness: 41 tests, 0 failures.
- Full `MIX_ENV=test mix test.fast`: 2 properties, 1640 tests, 0 failures, 6 skipped (286 excluded).
- `mix qa` exit 0; `mix qa.dialyzer` passed (0 errors); `mix test.clean-room.e2e` exit 0.
- `git diff` on mix.exs, mix.lock, priv/, key_cache.ex, jwks.ex, discovery.ex: clean.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Created/modified files exist; commits 47e94cb2, 8c9eccc5, 6c0c4f8d are ancestors of HEAD.
