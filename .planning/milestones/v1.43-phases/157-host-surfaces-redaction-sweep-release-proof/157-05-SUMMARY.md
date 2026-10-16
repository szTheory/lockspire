---
phase: 157-host-surfaces-redaction-sweep-release-proof
plan: 05
subsystem: protocol
tags: [jose, redaction, signing-keys, private-jwk]
requires:
  - phase: 156
    provides: sealed key envelopes and PrivateJwk.decode/1
provides:
  - PrivateJwk.to_jwk/1 guarded JOSE key construction
  - six signing/decrypting consumers built on it
affects: [157-06, 157-04]
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
plan_head_before: 9c84469be1b5603064c43212c35521360044b2b2
plan_head_after: c78333d859e3dfb766fd4ffde945fb1c288dbacf
commits: 2
tech-stack:
  added: []
  patterns: ["drop exceptions at the JOSE boundary, return only a reason atom"]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/private_jwk.ex
    - lib/lockspire/protocol/id_token.ex
    - lib/lockspire/protocol/logout_token.ex
    - lib/lockspire/protocol/jarm.ex
    - lib/lockspire/protocol/introspection_jwt.ex
    - lib/lockspire/protocol/jar.ex
    - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
    - test/lockspire/protocol/private_jwk_test.exs
    - test/lockspire/protocol/envelope_signing_consumers_test.exs
key-decisions:
  - "to_jwk/1 uses JOSE.JWK.to_public/1 as a structural probe and unbinds the exception, so decoded private bytes never leave it"
requirements-completed: [RED-01, SAFE-01]
duration: 12min
completed: 2026-10-16
status: complete
---

# Phase 157 Plan 05: Guarded private key construction Summary

**`PrivateJwk.to_jwk/1` turns a decoded key map into a JOSE key or `{:error, :invalid_signing_key}`, and all six signing/decrypting consumers use it, so a malformed sealed key (for example an OKP key with a wrong-length `d`) can no longer raise with private bytes in the exception text.**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-10-16T16:18:08Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Final shape: `@spec to_jwk(term()) :: {:ok, JOSE.JWK.t()} | {:error, :invalid_signing_key}`. It builds the key, calls `JOSE.JWK.to_public/1` and discards the result, with `rescue _` and `catch _, _` clauses that bind nothing, plus a non-map clause. It never logs, inspects or re-raises.
- Error for a malformed sealed key, per consumer: ID token, logout token, JARM, introspection JWT return `{:error, :invalid_signing_key}`; access-token signer returns its existing 500 `server_error` (`:token_signing_failed`); JAR returns `{:error, :decryption_failed}`. None raises.
- Client public-JWKS conversion in `jar.ex` and the `rescue ErlangError` in `introspection_jwt.ex` are untouched. No new rescue in any consumer.

## Task Commits

1. **Task 1: to_jwk/1 plus ID token consumer** - `d1de2bf8` (feat)
2. **Task 2: remaining five consumers** - `c78333d8` (feat)

## Decisions Made
None beyond the plan. The RSA malformed-`d` test input is `"abcde"` (length 1 mod 4); `"abc"` decodes without error in JOSE, so it is not a valid malformed case.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. Known limit: the `to_public` probe does not catch every malformed RSA/EC map (some return a key and fail later with `ErlangError`, which carries no key data); this matches the plan's research.

## Known Stubs
None.

## Next Phase Readiness
157-06 can run the shared matcher over logs, exception text and Oban job errors for the malformed-key path through any of the six consumers.

## Self-Check: PASSED
- Files present; commits `d1de2bf8` and `c78333d8` are on `main`.
- Verify commands green on 1.19.5-otp-28 (713 protocol/worker/fitness/readability tests, 0 failures); `mix format --check-formatted` and `mix compile --warnings-as-errors` clean.
- No existing assertion removed from `envelope_signing_consumers_test.exs`.
