---
phase: 99-signer-extraction-jwt-default-issuance
plan: 05
subsystem: api
tags: [jwt, jose, rfc9068, rfc8693, oauth, refresh-rotation, signer, audience, sub]

# Dependency graph
requires:
  - phase: 99-01
    provides: "access_token_format column + :jwt ServerPolicy default (format resolution)"
  - phase: 99-03
    provides: "Lockspire.Protocol.AccessTokenSigner — issue/3 (list aud) + issue_exchange/4 (string aud)"
provides:
  - "Refresh rotation mints at+jwt via AccessTokenSigner with a non-nil sub sourced from the presented refresh token"
  - "Refresh resource= -> aud == [resource]; absent -> aud == [client_id] (AUD-01/02)"
  - "RFC 8693 token-exchange path delegates all signing to AccessTokenSigner; no duplicated signing logic remains (SC5)"
  - "RFC 8693 no-resource path keeps a bare-string aud == client_id (AUD-03 sentinel preserved)"
affects:
  - "100 (sender-constraint end-to-end: refresh cnf now carried into the minted at+jwt via the signer)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mint-before-persist for refresh: build the rotated %Token{}, sign it, re-point token_hash to the signer's hash (Pitfall 1), then run the rotation transaction"
    - "Subject carry-through: the rotated access token's account_id is sourced from the presented refresh token (the rotated token's own account_id is nil) so the signer derives a non-nil sub (Pitfall 5)"
    - "Single signing site: rfc8693_exchange now holds zero JOSE sign/compact calls and zero key-fetch helpers; the exchange carve-out (string aud + restricted-claim drop) lives entirely in AccessTokenSigner.issue_exchange/4"

key-files:
  created: []
  modified:
    - lib/lockspire/protocol/refresh_exchange.ex
    - lib/lockspire/protocol/rfc8693_exchange.ex
    - test/lockspire/protocol/refresh_exchange_test.exs
    - test/lockspire/protocol/rfc8693_exchange_test.exs
    - test/lockspire/web/token_controller_test.exs
    - test/integration/phase62_private_key_jwt_e2e_test.exs

key-decisions:
  - "Restructured rotate_refresh_token_with_audit/6 to sign the access token BEFORE the rotation transaction so the persisted %Token{}.token_hash equals Policy.hash_token(issued_jwt); signer {:error, %Error{}} short-circuits via a with/1"
  - "Sourced the rotated access token's account_id AND scopes from the presented refresh token so the at+jwt sub and scope claims are correct; the rotated refresh token's own account_id stays nil (the Repository fills it from the presented record — unchanged refresh-token behavior)"
  - "Deleted the rfc8693 in-file signing block + key-fetch helpers and delegated the custom-claims branch to AccessTokenSigner.issue_exchange/4; the opaque (no-custom-claims) branch still mints via TokenFormatter as before"

requirements-completed: [SIGNER-01, AUD-01, AUD-02, AUD-03]

# Metrics
duration: 11min
completed: 2026-05-28
---

# Phase 99 Plan 05: Signer Wiring (Refresh + RFC 8693) Summary

**Routed the refresh rotation path and the RFC 8693 token-exchange path through the shared `AccessTokenSigner`, fixed the refresh `sub` (rotated token had `account_id: nil`), and deleted the duplicated `at+jwt` signing block from `rfc8693_exchange.ex` so no signing logic survives outside the shared module (SC5).**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-05-28T14:26:13Z
- **Completed:** 2026-05-28T14:36:57Z
- **Tasks:** 2 (both TDD)
- **Files modified:** 6 (2 source, 4 test)

## Accomplishments

- **Refresh rotation now mints `at+jwt` via the signer (Task 1).** `rotate_refresh_token_with_audit/6` builds the rotated `%Token{}`, calls `AccessTokenSigner.issue/3`, re-points `%Token{}.token_hash` to the signer's returned hash (Pitfall 1), then runs the rotation transaction. The signer's `{:error, %Error{}}` (missing-key 500) short-circuits.
- **Fixed the refresh `sub` gap (Pitfall 5, T-99-14).** The rotated access token's `account_id` is now sourced from `presented_refresh_token.account_id` (it was hardcoded `nil`), so the minted JWT carries a non-nil `sub` and passes the Phase 98 verifier's `:missing_sub` check. `scopes` are likewise carried from the presented token so the `scope` claim is correct.
- **Refresh aud derivation satisfied (AUD-01/02).** With `resource=`, decoded `aud == [resource]`; absent, `aud == [client_id]` — verified by new tests.
- **RFC 8693 delegates all signing to the shared module (Task 1/SC5).** Deleted `sign_jwt_access_token/6`, `fetch_signing_key/1`, `decode_private_jwk/1`, `decode_erlang_jwk/1`, and the inline `JOSE.JWT.sign`/`JOSE.JWS.compact` block. The custom-claims branch now calls `AccessTokenSigner.issue_exchange/4`.
- **AUD-03 sentinel preserved (T-99-15).** `rfc8693_exchange_test.exs` still asserts a bare-**string** `aud == client.client_id`; hardened to also assert `typ == "at+jwt"` and that an attacker-supplied `aud`/`iss` custom claim cannot override the protocol claims (T-99-17).
- **Whole repo stays green:** `1030 tests, 0 failures (275 excluded)` after the change plus four test-fixture deviations.

## Task Commits

Each task was committed atomically (TDD: RED then GREEN), plus two in-scope deviation fixes:

1. **Task 1 RED** — `dd14898` (test): failing refresh tests asserting at+jwt + non-nil sub + resource-derived aud.
2. **Task 1 GREEN** — `6708024` (feat): mint refresh rotation via `AccessTokenSigner.issue/3`, source sub from presented token.
3. **Task 2 GREEN/refactor** — `e667a0e` (refactor): route RFC 8693 through `issue_exchange/4`, delete the duplicated signing block + key-fetch helpers, harden the sentinel.
4. **Deviation fix** — `8702687` (test): seed signing key for the controller refresh/replay tests (JWT default).
5. **Deviation fix** — `48285e6` (test): seed signing key for the phase62 private_key_jwt refresh e2e (JWT default).

_No separate REFACTOR commit for Task 1 — the GREEN implementation was already clean. Task 2 IS a refactor (extraction/deletion), so its GREEN commit is typed `refactor`._

## Files Created/Modified

- `lib/lockspire/protocol/refresh_exchange.ex` — Added `AccessTokenSigner` alias; restructured `rotate_refresh_token_with_audit/6` to sign the access token before the transaction and thread the signer's hash + error; `build_rotated_access_token/5` now sources `account_id`/`scopes`/`issued_at` from the presented token; removed the now-unused `format_refresh_rotation_tokens/1`.
- `lib/lockspire/protocol/rfc8693_exchange.ex` — Added `AccessTokenSigner` alias; `sign_or_format_access_token/6` custom-claims branch delegates to `issue_exchange/4`; deleted `sign_jwt_access_token/6` + `fetch_signing_key/1` + `decode_private_jwk/1` + `decode_erlang_jwk/1` and the inline JOSE sign block (net -86 lines). `decode_jwt_claims/1` (JWT *peek* for actor-token delegation claims) is retained — it is decode, not signing.
- `test/lockspire/protocol/refresh_exchange_test.exs` — Added a `MockKeyStore`, a `decode_jwt_payload/1` helper, and 3 new at+jwt/sub/aud tests; updated the legacy DPoP/replay/audit tests to wire `key_store` and assert JWT issuance (look up rotated access tokens by `Policy.hash_token(jwt)`).
- `test/lockspire/protocol/rfc8693_exchange_test.exs` — Hardened the custom-claims sentinel: `typ == "at+jwt"`, string `aud == client_id`, and attacker `aud`/`iss` override ignored.
- `test/lockspire/web/token_controller_test.exs` — Seeded an active signing key in the two controller refresh tests (assertions unchanged).
- `test/integration/phase62_private_key_jwt_e2e_test.exs` — Added a `publish_signing_key/1` helper + `SigningKey` alias; seeded a key in setup for the refresh success paths (assertions unchanged).

## Decisions Made

- **Sign before the transaction.** The refresh path historically minted the raw token *before* building the `%Token{}` and used `formatted_access_token.token_hash`. Because the signer needs the assembled `%Token{}` (to derive `sub`/`scope`/`aud`/`cnf`) and the persisted hash must equal `Policy.hash_token(jwt)` (Pitfall 1), I moved the mint to after `build_rotated_access_token/5` and re-pointed `token_hash` from the signer's return. The refresh token is still minted via `TokenFormatter` (only the access token moved to the signer).
- **Subject + scopes from the presented token.** The signer reads `sub` from `%Token{}.account_id` and `scope` from `%Token{}.scopes`; the rotated access token had neither populated. Sourcing both from `presented_refresh_token` produces correct claims while leaving the Repository's own `account_id || record.account_id` / `scopes` fallbacks intact (no double-source conflict).
- **Carve-out stays in the signer.** Per Plan 03's `issue_exchange/4` contract, the bare-string `aud` and the `~w(iss sub aud exp iat jti client_id)` restricted-claim drop live in the shared module; `rfc8693_exchange.ex` only assembles a minimal `%Token{}` (subject/scopes/cnf/issued_at) and forwards `custom_claims`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored the worktree build environment (`mix deps.get`)**
- **Found during:** Task 1 (running the RED suite)
- **Issue:** The fresh worktree's `deps/`/`_build/` are gitignored and absent; `mix test` aborted.
- **Fix:** Ran `mix deps.get`, fetching the exact versions pinned in the committed `mix.lock` (NOT a new package install — `mix.lock` unchanged).
- **Files modified:** None tracked.
- **Committed in:** N/A.

**2. [Rule 3 - Blocking] Seeded signing keys in two consuming controller tests**
- **Found during:** Post-Task verification (full-suite sweep)
- **Issue:** `token_controller_test.exs` refresh/replay tests returned `500 :signing_key_not_found` because refresh now mints an at+jwt (JWT default) and those tests never seeded an active signing key.
- **Fix:** Added `publish_signing_key/...` (existing in-file helper) to both tests. Assertions (200 + `access_token` present) unchanged; no opaque-vs-JWT format assertion touched (that format scope is Plan 04's `token_exchange.ex`).
- **Files modified:** `test/lockspire/web/token_controller_test.exs`
- **Committed in:** `8702687`

**3. [Rule 3 - Blocking] Seeded a signing key in the phase62 refresh e2e**
- **Found during:** Post-Task verification (full-suite sweep)
- **Issue:** `phase62_private_key_jwt_e2e_test.exs` refresh success paths returned `500 :signing_key_not_found` for the same reason; the file had no key-seeding helper.
- **Fix:** Added a `publish_signing_key/1` helper + `SigningKey` alias and seeded a key in setup. Assertions unchanged.
- **Files modified:** `test/integration/phase62_private_key_jwt_e2e_test.exs`
- **Committed in:** `48285e6`

---

**Total deviations:** 3 auto-fixed (all blocking; #1 environment-only, #2/#3 test-fixture updates directly required by this plan's intended refresh JWT-default flip).
**Impact on plan:** No scope creep. Deviations #2/#3 are direct downstream consequences of routing refresh through the signer; both only seed a key fixture and leave assertions intact. Plan executed as written.

## Issues Encountered

- The benign background `KeyCache` `could not lookup Ecto repo Lockspire.TestRepo` error appears during async unit suites (pre-existing infra noise documented in Plan 03) — out of scope, not fixed.
- `token_exchange.ex` (the AC/device/CIBA mint seams) is **owned by Plan 04** and is unchanged in this worktree; AC still mints opaque by default here. Integration tests that exercise AC-then-refresh (e.g. phase57) already publish a signing key, so they stayed green without any change from this plan.

## Threat Surface

All Plan-99-05 threat-register mitigations are honored; no new surface introduced:

- **T-99-14 (refresh sub: nil / repudiation):** sub sourced from `presented_refresh_token.account_id`; tests assert non-nil `sub == "subject-refresh"` and a verifier-compatible at+jwt.
- **T-99-15 (AUD-03 regression):** the exchange path keeps a bare-**string** `aud == client_id`; the sentinel test asserts `is_binary(payload["aud"])` and equality.
- **T-99-16 (duplicated signing logic):** the JOSE block + key-fetch helpers are deleted from `rfc8693_exchange.ex` (grep gate `JOSE.(JWT|JWS).(sign|compact)` == 0, `defp (fetch_signing_key|decode_private_jwk|decode_erlang_jwk)` == 0).
- **T-99-17 (custom-claim override):** the restricted-claim drop lives in `issue_exchange/4`; the sentinel asserts an attacker `aud`/`iss` custom claim is ignored.
- **T-99-18 (key material in logs):** the missing-key error path is the signer's (logs `inspect(reason)` only); covered by Plan 03's no-leak test.

## Known Stubs

None. No placeholder values, empty data sources, or TODO/FIXME markers introduced (verified by scan of both modified source files).

## TDD Gate Compliance

- **Task 1 RED gate:** `test(99-05)` commit `dd14898` — 3 new refresh tests failed because the rotated access token was still an opaque string (verified RED-as-expected; existing 12 tests stayed green).
- **Task 1 GREEN gate:** `feat(99-05)` commit `6708024` — refresh test green (15/15).
- **Task 2 gate:** structural RED demonstrated pre-edit (`JOSE.(JWT|JWS).(sign|compact)` == 2, key-fetch helpers == 3, AccessTokenSigner == 0); GREEN/refactor commit `e667a0e` flips all three gates (0 / 0 / 2) with the hardened sentinel green. The exchange path is a deletion/extraction, committed as `refactor`.

## Next Phase Readiness

- Refresh and RFC 8693 now both route through `AccessTokenSigner`; combined with Plan 03 (the signer) and Plan 04 (AC/device/CIBA seams), Phase 99's "single signing site" invariant (SC5) holds for the refresh + exchange paths.
- Refresh `cnf` carry-through is in place (signer copies `%Token{}.cnf`), satisfying the Phase 100 sender-constraint prerequisite for the refresh path.
- No blockers.

## Self-Check: PASSED

- FOUND: `lib/lockspire/protocol/refresh_exchange.ex`
- FOUND: `lib/lockspire/protocol/rfc8693_exchange.ex`
- FOUND commit: `dd14898` (test, RED)
- FOUND commit: `6708024` (feat, GREEN — refresh signer)
- FOUND commit: `e667a0e` (refactor, SC5 — rfc8693 delegation + deletion)
- FOUND commit: `8702687` (test, deviation — controller key seed)
- FOUND commit: `48285e6` (test, deviation — phase62 key seed)
- VERIFIED: `JOSE.(JWT|JWS).(sign|compact)` count in `rfc8693_exchange.ex` == 0 (SC5)
- VERIFIED: refresh + rfc8693 target suites == 24 tests, 0 failures; full suite == 1030 tests, 0 failures

---
*Phase: 99-signer-extraction-jwt-default-issuance*
*Completed: 2026-05-28*
