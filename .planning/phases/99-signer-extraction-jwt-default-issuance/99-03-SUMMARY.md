---
phase: 99-signer-extraction-jwt-default-issuance
plan: 03
subsystem: api
tags: [jwt, jose, rfc9068, rfc8693, oauth, access-token, signer, audience]

# Dependency graph
requires:
  - phase: 99-01
    provides: "access_token_format nullable column on Client + :jwt default on ServerPolicy"
provides:
  - "Lockspire.Protocol.AccessTokenSigner — shared RFC 9068 at+jwt signer + opaque delegate"
  - "One-place access-token format resolution (per-client override -> server default -> :jwt)"
  - "aud derivation: list form ([resource] or [client_id]) for grant paths; bare-string client_id for RFC 8693 exchange"
  - "cnf carry-through from %Token{}.cnf into the minted JWT (Phase 100 sender-constraint prerequisite)"
  - "issue/3 (standard grants) and issue_exchange/4 (token-exchange) public surface"
affects:
  - "99-04 (re-point AC/refresh/device/CIBA mint seams at AccessTokenSigner.issue/3)"
  - "99-05 (re-point rfc8693_exchange at issue_exchange/4 + delete the old in-file signing block)"
  - "100 (sender-constraint end-to-end proof relies on cnf carry-through)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single JOSE.JWT.sign site funnels both list-aud and string-aud callers through one private sign_jwt/2 core"
    - "Format resolution copied from SecurityProfile precedence shape, adapted :inherit -> nil for a nullable column"
    - "aud list-vs-string carve-out lives at the caller boundary (issue/3 vs issue_exchange/4), not inside the signing core"

key-files:
  created:
    - lib/lockspire/protocol/access_token_signer.ex
    - test/lockspire/protocol/access_token_signer_test.exs
  modified: []

key-decisions:
  - "issue_exchange/4 is the explicit exchange-path mode that emits a bare-string aud and applies the restricted-claim drop on custom claims, preserving the rfc8693_exchange_test.exs:192 sentinel"
  - "Used Policy.hash_token/1 for both :jwt and :opaque branches (identical SHA-256 hex to TokenFormatter.hash_token/1)"
  - "exp computed as iat + 3600 (integer) rather than DateTime.add |> to_unix, keeping exp == iat + 3600 exact and avoiding double now() drift"

patterns-established:
  - "Pattern: aud carve-out at the boundary — grant callers pass a list, the exchange caller passes a string, the shared signer is aud-agnostic"
  - "Pattern: maybe_put_cnf/2 conditionally copies %Token{}.cnf only when non-nil so opaque/no-binding tokens stay clean"

requirements-completed: [SIGNER-01, SIGNER-02, AUD-02, AUD-03]

# Metrics
duration: 4min
completed: 2026-05-28
---

# Phase 99 Plan 03: Signer Extraction (AccessTokenSigner) Summary

**Shared RFC 9068 `at+jwt` signer with one-place format resolution, list-vs-string `aud` carve-out, and `cnf` carry-through — assembled from the rfc8693 signing block and the SecurityProfile precedence shape, shipped TDD-first.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-28T14:11:08Z
- **Completed:** 2026-05-28T14:15:00Z
- **Tasks:** 2
- **Files modified:** 2 (both created)

## Accomplishments

- Created `Lockspire.Protocol.AccessTokenSigner` owning the single `JOSE.JWT.sign` site for the whole library (verified: exactly one non-comment sign site).
- One-place format resolution: per-client `access_token_format` (`:jwt`/`:opaque`) wins; `nil` inherits `ServerPolicy.access_token_format` via `request.opts[:server_policy_store]`; absent both falls back to `:jwt`.
- `aud` derivation with the RFC 8693 carve-out: `issue/3` emits a LIST (`[resource]` when `%Token{}.audience` is non-empty, else `[client_id]`) for AC/refresh/device/CIBA; `issue_exchange/4` emits a BARE STRING `client_id` and keeps the custom-claim merge with the `~w(iss sub aud exp iat jti client_id)` drop.
- `cnf` carry-through: the minted JWT copies `%Token{}.cnf` only when present, so Phase 100 can verify DPoP/mTLS binding.
- Missing/invalid signing key returns the existing 500 `:token_signing_failed`; the error path logs `inspect(reason)` only — a test asserts no key material (`private_jwk`, PEM `BEGIN`, JWK `"d":`) appears in captured logs.
- Full Wave-0 unit suite: 14 tests covering jwt claims + hash equality, format precedence (3 branches), opaque delegate, aud list-vs-string, cnf carry-through, and the missing-key 500.

## Task Commits

Each task was committed atomically (TDD: RED then GREEN):

1. **Task 1: Wave 0 failing test suite** - `36c6ab9` (test)
2. **Task 2: Implement AccessTokenSigner** - `b072614` (feat)

_No REFACTOR commit — the GREEN implementation was already clean (single sign site, boundary-level aud carve-out)._

## Files Created/Modified

- `lib/lockspire/protocol/access_token_signer.ex` - Shared signer: `issue/3` + `issue_exchange/4`, `resolve_format/2`, `derive_aud/2`, single `sign_jwt/2` JOSE site, key fetch + JWK decode (moved-style copy from rfc8693_exchange precedent).
- `test/lockspire/protocol/access_token_signer_test.exs` - 14-case ExUnit suite with `MockKeyStore`/`MissingKeyStore`/`MockServerPolicyStore` mirroring `token_controller.ex` opts.

## Decisions Made

- **`issue_exchange/4` as the explicit exchange mode.** Per PATTERNS D-08 / RESEARCH Open Question 2, the bare-string `aud` carve-out and the custom-claim merge/restricted-drop live only on this caller, while the JOSE sign core stays single-sourced. This preserves the `rfc8693_exchange_test.exs:192` regression sentinel (`payload["aud"] == client.client_id`) once Plan 05 re-points the exchange path.
- **`exp = iat + 3600` (integer arithmetic).** The original block computed `exp` via `DateTime.add(issued_at, 3600) |> to_unix` and `iat` via `to_unix(issued_at)`; both resolve from the same `issued_at`, so integer `iat + 3600` is exactly equivalent, asserted directly by the test (`exp == iat + 3600`), and avoids re-deriving `now` twice.
- **`Policy.hash_token/1` for both branches.** Identical SHA-256 hex to `TokenFormatter.hash_token/1` (RESEARCH A4); the test asserts both equalities for the opaque path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched declared dependencies into the fresh worktree**
- **Found during:** Task 1 (running the RED suite)
- **Issue:** The worktree's `deps/` and `_build/` are gitignored and absent on spawn; `mix test` aborted with "the dependency is not available".
- **Fix:** Ran `mix deps.get`, which fetches the exact versions already pinned in the committed `mix.lock`. This is NOT a package-manager *install* of a new/unknown package — no new dependency was added; `mix.lock` was unchanged.
- **Files modified:** None tracked (deps are gitignored).
- **Verification:** `mix compile --warnings-as-errors` exits 0; both suites green.
- **Committed in:** N/A (no tracked file changes).

---

**Total deviations:** 1 auto-fixed (1 blocking, environment-only).
**Impact on plan:** No code or scope impact — purely restored the worktree build environment. Plan executed exactly as written.

## Issues Encountered

- A background `KeyCache` refresh emits a benign `could not lookup Ecto repo Lockspire.TestRepo` error during the async unit suite. This is pre-existing infrastructure noise unrelated to the signer (the signer's tests inject their own key/policy stores and never touch the repo) — out of scope, not fixed.

## Threat Surface

All Plan-99-03 threat-register mitigations are honored, no new surface introduced:

- **T-99-06 (alg confusion):** `alg`/`kid` taken only from `fetch_active_signing_key/1`; no client-controlled alg; `none` never emitted.
- **T-99-07 (key material in logs):** error path logs `inspect(reason)` only; test asserts captured logs contain no `private_jwk` / PEM / JWK private exponent.
- **T-99-08 (audience confusion):** `aud` derives strictly from `%Token{}.audience` or `[client_id]`; the restricted-claim drop on the exchange path prevents custom-claim `aud` override (test asserts an attacker `aud` is ignored).
- **T-99-09 (typ confusion):** signer sets exact `typ: "at+jwt"`; asserted in the header round-trip test.
- **T-99-10 (cnf drop / sender-constraint downgrade):** signer copies `%Token{}.cnf` when present; asserted by the cnf carry-through test.

## Known Stubs

None. `issue_exchange/4` is a fully-implemented public function that is intentionally not yet wired into a caller — Plan 05 re-points `rfc8693_exchange.ex` at it and deletes the duplicated in-file signing block. The extraction-source body in `rfc8693_exchange.ex` is deliberately left intact this plan (per the objective).

## TDD Gate Compliance

- RED gate: `test(99-03)` commit `36c6ab9` (suite failed because the module was undefined — verified `RED-as-expected`).
- GREEN gate: `feat(99-03)` commit `b072614` (14 tests, 0 failures).
- REFACTOR gate: not needed.

## Next Phase Readiness

- `AccessTokenSigner.issue/3` is ready for Plan 04 to re-point the AC/refresh/device/CIBA mint seams (note the 2-tuple internal contract at the AC seam — the seam returns `{%Token{}, raw}`, so set `%Token{token_hash: hash}` from the signer's returned hash).
- `AccessTokenSigner.issue_exchange/4` is ready for Plan 05 to re-point `rfc8693_exchange.ex` and delete the old signing block (`sign_jwt_access_token/6` + `fetch_signing_key/1` + `decode_private_jwk/1` + `decode_erlang_jwk/1`).
- No blockers.

## Self-Check: PASSED

- FOUND: `lib/lockspire/protocol/access_token_signer.ex`
- FOUND: `test/lockspire/protocol/access_token_signer_test.exs`
- FOUND commit: `36c6ab9` (test, RED)
- FOUND commit: `b072614` (feat, GREEN)

---
*Phase: 99-signer-extraction-jwt-default-issuance*
*Completed: 2026-05-28*
