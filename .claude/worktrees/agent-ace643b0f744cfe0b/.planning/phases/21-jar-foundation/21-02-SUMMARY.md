---
phase: 21
plan: 02
subsystem: protocol
tags: [jar, jwt, signature-verification, jose, security]
requires: [JAR-01]
provides: [JAR-02]
affects: [lib/lockspire/protocol/jar.ex]
tech-stack:
  added: []
  patterns: [JOSE.JWT.verify_strict with algorithm allow-list, JWK Set key iteration]
key-files:
  modified:
    - lib/lockspire/protocol/jar.ex
    - test/lockspire/protocol/jar_test.exs
decisions:
  - Use JOSE.JWT.verify_strict with an explicit algorithm allow-list to enforce alg=none rejection without requiring a separate pre-check
  - Normalise client.jwks into a flat list of JOSE.JWK structs before verification to handle both single JWK maps and JWK Set objects uniformly
  - Iterate over all candidate keys and return ok on first match, invalid_signature only after all keys exhausted
metrics:
  duration: 20m
  completed_date: 2026-04-25
---

# Phase 21 Plan 02: JAR Signature Verification Summary

Implemented `verify_signature/2` in `Lockspire.Protocol.Jar` to cryptographically verify JAR request object signatures using the client's registered public keys, mitigating T-21-03 (Spoofing) and T-21-04 (Tampering).

## One-liner
JAR signature verification with JOSE `verify_strict`, explicit algorithm allow-list, and JWK/JWK-Set normalisation.

## Key Changes

- Added `Lockspire.Protocol.Jar.verify_signature/2` accepting a JWT string and `%Lockspire.Domain.Client{}` struct.
- Used `JOSE.JWT.verify_strict/3` with an explicit `@allowed_algorithms` list — `alg=none` is never in the list, so unsigned JWTs are always rejected.
- Implemented JWK normalisation: single JWK map and JWK Set (`{"keys": [...]}`) are both supported by flattening into a list of individual `JOSE.JWK` structs before calling `verify_strict`.
- Error atoms match the plan spec: `:invalid_signature`, `:no_matching_key`, `:invalid_client_keys`.
- Added 9 new unit tests covering: valid single JWK, valid JWK Set, wrong-key rejection, alg=none rejection, nil jwks, non-map jwks, empty map jwks, invalid JWK structure, payload tampering.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] JWK Set not supported by JOSE.JWT.verify_strict directly**
- **Found during:** Task 2 test run
- **Issue:** `JOSE.JWT.verify_strict/3` returns `{:error, ...}` when passed a JOSE JWK Set struct (loaded via `JOSE.JWK.from_map(%{"keys" => [...]})`) — it only works with individual JWK structs.
- **Fix:** Added `extract_public_keys/1` helper that detects JWK Sets (maps with a `"keys"` array) and normalises them into a list of individual `JOSE.JWK` structs. Verification iterates over all keys and succeeds on first match.
- **Files modified:** `lib/lockspire/protocol/jar.ex`
- **Commit:** 625808f

## Known Stubs
None.

## Threat Flags
None — no new network endpoints, auth paths, or trust boundaries introduced beyond those in the plan's threat model.

## Self-Check: PASSED
- [x] `lib/lockspire/protocol/jar.ex` exists and contains `verify_signature/2`
- [x] `test/lockspire/protocol/jar_test.exs` exists with 13 tests (4 decode + 9 verify_signature)
- [x] Commit 482c790 exists: `feat(21-02): implement JAR signature verification using client JWKS`
- [x] Commit 625808f exists: `test(21-02): add unit tests for JAR signature verification`
- [x] `mix test test/lockspire/protocol/jar_test.exs` — 13 tests, 0 failures
- [x] `mix compile` — clean (pre-existing unrelated warnings only)
