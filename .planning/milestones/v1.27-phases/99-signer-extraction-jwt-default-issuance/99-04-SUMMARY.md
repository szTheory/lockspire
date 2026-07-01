---
phase: 99-signer-extraction-jwt-default-issuance
plan: 04
subsystem: api
tags: [jwt, jose, rfc9068, rfc8707, oauth, access-token, signer, audience, device, ciba]

# Dependency graph
requires:
  - phase: 99-01
    provides: "access_token_format nullable column on Client + :jwt default on ServerPolicy"
  - phase: 99-03
    provides: "Lockspire.Protocol.AccessTokenSigner.issue/3 ({:ok, raw, hash} | {:error, %Error{}}) + aud list-form derivation + cnf carry-through"
provides:
  - "AC/device/CIBA mint seam (build_access_token/6) routed through AccessTokenSigner.issue/3 (SIGNER-01)"
  - "Persisted %Token{}.token_hash re-pointed to the signer's returned hash (introspection/revocation by hash intact across formats)"
  - "Net-new device + CIBA resource validation + audience threading (validate_grant_resources/2): resource= -> aud=[resource], absent -> aud=[client_id] (AUD-01/AUD-02)"
  - "invalid_target (:invalid_resource, 400) rejection for an out-of-set resource when a grant carries a recorded audience (T-99-11 guard)"
affects:
  - "99-05 (refresh + rfc8693 mint seams — same {%Token{}, raw} 2-tuple + signer pattern, owns refresh_exchange.ex/rfc8693_exchange.ex in parallel)"
  - "100 (sender-constraint end-to-end proof — cnf now flows into the AC/device/CIBA at+jwt via the signer)"
  - "101 (adoption-demo re-wire — AC default token is now at+jwt)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "build_access_token/6 returns the {%Token{}, raw} 2-tuple on success and {:error, %Error{}} on signer failure; callers disambiguate with a %Token{}-guarded with-clause so the error 2-tuple ({:error, %Error{}}) cannot be mistaken for the success 2-tuple"
    - "Token-hash ownership lives with the signer: build_access_token re-points %Token{}.token_hash to the signer's hash rather than the formatter's"
    - "Grant-path resource validation reuses the AC validate_requested_resources/2 cond shape; device/CIBA carve-out: empty authorized set accepts any binary resource, non-empty set enforces membership"

key-files:
  created: []
  modified:
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/test_repo.ex
    - test/lockspire/protocol/token_exchange_test.exs
    - test/lockspire/web/token_controller_test.exs

key-decisions:
  - "build_access_token/6 returns the bare {%Token{}, raw} 2-tuple on success (per plan) and {:error, %Error{}} on signer failure; the three callers guard with `{%Token{} = access_token, raw}` so the error 2-tuple is never mis-matched as success"
  - "Device/CIBA grants carry no recorded audience today, so validate_grant_resources/2 accepts any binary resource when the authorized set is empty (AC requested==[] default semantics) and only rejects out-of-set resources when a recorded audience exists; AC is the reachable surface for the invalid_target rejection branch, and a test seam exercises the device/CIBA rejection directly"
  - "The legacy access_token_generator opt no longer drives access-token minting (the signer owns generation); opaque-shape tests opt clients into access_token_format: :opaque and look up the persisted token by the actual issued token's hash"

patterns-established:
  - "Pattern: %Token{}-guarded with-clause to split a success 2-tuple from an {:error, %Error{}} 2-tuple without a tagged success shape"
  - "Pattern: shared resource-validation cond reused across AC/device/CIBA with a carve-out clause for the empty-authorized (no recorded audience) case"

requirements-completed: [SIGNER-01, AUD-01, AUD-02]

# Metrics
duration: ~35min
completed: 2026-05-28
---

# Phase 99 Plan 04: Signer Mint Seam (AC/device/CIBA) + Device/CIBA Resource Threading Summary

**The AC/device/CIBA mint seam now issues access tokens through `AccessTokenSigner.issue/3` (re-pointing the persisted hash to the signer's hash), and the device + CIBA grant paths gained net-new `resource`→`aud` validation so `resource=` yields `aud=[resource]` and absent `resource=` yields `aud=[client_id]`.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-05-28T14:27Z
- **Completed:** 2026-05-28T14:50Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Routed `build_access_token/6` (the shared AC/device/CIBA mint seam) through `AccessTokenSigner.issue/3`; the persisted `%Token{}.token_hash` is re-pointed to the signer's returned hash so introspection/revocation by hash resolves regardless of issued format (SIGNER-01, Pitfall 1 / T-99-12).
- Signer `{:error, %Error{}}` (missing-key 500) is propagated through all three callers (`redeem_code`, `redeem_ciba_grant`, `redeem_device_grant`) via a `%Token{}`-guarded `with`-clause that disambiguates the success 2-tuple from the error 2-tuple.
- Added net-new `validate_grant_resources/2` and threaded it into `redeem_device_grant/5` and `redeem_ciba_grant/5` before minting, setting `%Token{audience: validated}` — device and CIBA `resource=` now produce `aud=[resource]` (AUD-01) and absent `resource=` produces `aud=[client_id]` (AUD-02). The literal `audience: []` hardcodes in `build_device_grant`/`build_ciba_grant` were removed in favor of the `%Token{}` default + threaded validated value.
- Proved the threading with `resource=`-scoped device AND CIBA flows (not just AC) per Pitfall 2 / T-99-13, plus AUD-02 device/CIBA no-resource flows, an AC unauthorized→`invalid_target` case, and a direct device/CIBA `validate_grant_resources` rejection/accept case.
- AC AUD-01/AUD-02 are now proven through the signer (AC already threads `resource` into `%Token{}.audience`).

## Task Commits

Each task was committed atomically:

1. **Task 1: AC mint-seam — issue via signer and re-point token_hash (incl. error plumbing for all three callers)** - `00cde4b` (feat)
2. **Task 2: Device + CIBA — net-new resource validation + audience threading** - `1cb5e8c` (feat)

_Note: Task 1 and Task 2 were each committed as a single `feat` covering test + implementation. The JWT-default flip is interdependent (the new tests cannot be green without the implementation, and the implementation changes the default that existing tests assert), so a single atomic feat per task is the cleaner unit. RED was established before GREEN for both (new at+jwt assertions failed against the opaque-formatter mint before the signer was wired in)._

## Files Created/Modified

- `lib/lockspire/protocol/token_exchange.ex` — `build_access_token/6` now mints via `AccessTokenSigner.issue/3` and re-points the hash; `redeem_code`/`redeem_ciba_grant`/`redeem_device_grant` use a `%Token{}`-guarded `with`; new `validate_grant_resources/2` + `request_params/1` + a `@doc false` `validate_grant_resources_for_test/2` seam; device/CIBA `audience: []` hardcodes removed.
- `lib/lockspire/test_repo.ex` — delegates `fetch_active_signing_key/0` to `Repository` so the CIBA Push worker (which issues with `request == %{}`, falling back to `Config.repo!()` for the key store) can sign under the JWT default.
- `test/lockspire/protocol/token_exchange_test.exs` — new at+jwt default + hash re-point + AUD-01/AUD-02 (AC/device/CIBA) + invalid_target coverage; `verify_at_jwt/1`/`opaque_token_is_at_jwt?/1` helpers; `create_client`/`create_authorization_code` extended with `:access_token_format`/`:audience`; opaque-shape tests opt into `access_token_format: :opaque` and look up by the issued token's hash; shape-agnostic flows publish a signing key.
- `test/lockspire/web/token_controller_test.exs` — publishes a default signing key in `setup` so the JWT-default `/token` responses can sign.

## Decisions Made

- **Success vs error 2-tuple disambiguation.** `build_access_token/6` returns the bare `{%Token{}, raw}` 2-tuple on success (per the plan's "preserve the internal 2-tuple contract") and `{:error, %Error{}}` on signer failure. Because `{:error, %Error{}}` is itself a 2-tuple, the callers match `{%Token{} = access_token, raw}` (struct-guarded first element) so the error tuple falls through to the `with` `else` clause rather than being mis-bound as a success.
- **Device/CIBA empty-authorized semantics.** Device and CIBA grants record no authorized audience today (no domain field). Per the plan's binding parenthetical, `validate_grant_resources/2` accepts any binary resource when the authorized set is empty (matching AC `requested == [] -> {:ok, authorized}`) so AUD-01 works, and rejects out-of-set resources only when a recorded audience exists (the T-99-11 guard). The rejection branch is structurally identical to AC's `validate_requested_resources/2`; AC is the reachable rejection surface (the auth code records an audience), and a `@doc false` test seam exercises the device/CIBA rejection/accept paths directly against a seeded grant audience.
- **`access_token_generator` is no longer the access-token mint seam.** The signer owns token generation, so the legacy `access_token_generator` opt no longer determines the access token. Opaque-shape regression tests opt clients into `access_token_format: :opaque` (genuine opaque-path coverage, also exercising the opaque opt-in requirement) and look up the persisted token by `hash_token(success.access_token)` instead of a hardcoded generator value.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched pinned dependencies + ensured the test DB into the fresh worktree**
- **Found during:** Task 1 (running the baseline + RED suites)
- **Issue:** The worktree's `deps/`/`_build/` are gitignored and absent on spawn; `mix test` could not run.
- **Fix:** `mix deps.get` (exact versions from the committed `mix.lock`; not a package install of a new package — `mix.lock` unchanged) and `MIX_ENV=test mix ecto.create/migrate` (migrations already up from the merged base).
- **Files modified:** None tracked (deps/DB are environment-only).
- **Verification:** `mix compile --warnings-as-errors` exits 0; suites run.
- **Committed in:** N/A (no tracked file changes).

**2. [Rule 1 - Bug] Existing AC/device/CIBA tests broke on the JWT-default flip (no signing key / opaque-shape assertions)**
- **Found during:** Task 1 (full token_exchange + token_controller suites)
- **Issue:** Flipping the default access-token format to `:jwt` (the point of the plan) made every AC/device/CIBA success test that minted a token without an active signing key fail with `:signing_key_not_found` (500), and made opaque-shape assertions (`success.access_token == "<generator>"`, hash lookups by generator value) invalid because the signer owns generation.
- **Fix:** Shape-agnostic tests publish a signing key (exercising the JWT default); opaque-shape tests opt clients into `access_token_format: :opaque` and look up by the issued token's hash; the controller suite publishes a key in `setup`.
- **Files modified:** `test/lockspire/protocol/token_exchange_test.exs`, `test/lockspire/web/token_controller_test.exs`.
- **Verification:** token_exchange (35), token_controller (15), full protocol suite (527) all green.
- **Committed in:** `00cde4b` (Task 1).

**3. [Rule 1 - Bug] CIBA Push worker could not sign under the JWT default (TestRepo lacked fetch_active_signing_key/0)**
- **Found during:** Task 2 (CIBA delivery-modes e2e; latent since Task 1's signer wiring)
- **Issue:** The CIBA Push worker issues tokens with `request == %{}`, so `AccessTokenSigner` falls back to `Config.repo!()` (= `Lockspire.TestRepo` in tests) for the key store. `TestRepo` did not define `fetch_active_signing_key/0`, so signing crashed and the Push authorization never transitioned to `:consumed`. (Production `Config.repo!()` is the real `Repository`, which has the function — this was a test-infra gap surfaced by the JWT default.)
- **Fix:** `TestRepo` now delegates `fetch_active_signing_key/0` to `Repository`, matching its existing delegation pattern for `get_server_policy`/`record_dpop_proof`.
- **Files modified:** `lib/lockspire/test_repo.ex`.
- **Verification:** phase51/52/53 CIBA e2e suites green (10 tests, 0 failures).
- **Committed in:** `1cb5e8c` (Task 2).

---

**Total deviations:** 3 auto-fixed (1 blocking env-only, 2 bugs from the intentional JWT-default flip). All within the plan's scope (the flip is the deliverable; the breakages are its direct, expected consequences). No scope creep; no architectural changes; the device/CIBA authorization domain was not modified.
**Impact on plan:** Plan executed as written. The only test-infra change (`TestRepo` delegate) is a correctness fix required for the JWT default to function on the worker path.

## Issues Encountered

- A background `KeyCache` refresh logs a benign `could not lookup Ecto repo Lockspire.TestRepo` during async suites — pre-existing infrastructure noise unrelated to this plan (noted in 99-03 SUMMARY too); out of scope, not fixed.

## Known Stubs

None. `validate_grant_resources/2` is fully wired into both `redeem_device_grant/5` and `redeem_ciba_grant/5`. The device/CIBA `invalid_target` rejection branch is structurally live (shared `cond` with AC) but only reachable through the public flow when a grant carries a recorded audience; device/CIBA grants record none today (no domain field — out of scope for this plan), so their reachable behavior is accept-any-binary (AUD-01) and the rejection branch is proven via the AC unauthorized test plus the `validate_grant_resources_for_test/2` seam.

## Threat Surface

All Plan-99-04 threat-register mitigations are honored; no new surface introduced:

- **T-99-11 (audience confusion on device/CIBA):** `validate_grant_resources/2` rejects an out-of-set resource with `invalid_target` (`:invalid_resource`, 400) when the grant carries a recorded audience; only validated values reach `%Token{audience}`, and the signer derives `aud` solely from the validated audience.
- **T-99-12 (stored hash ≠ hash-of-issued-token):** `build_access_token/6` re-points `%Token{}.token_hash` to the signer's returned hash; a test asserts `token_hash == Policy.hash_token(issued_raw)`.
- **T-99-13 (device/CIBA resource silently ignored):** `resource=`-scoped device AND CIBA flows explicitly assert `aud == [resource]` (live threading, not stubbed); absent-resource flows assert `aud == [client_id]`.

No new threat flags: no new network endpoints, auth paths, file access, or trust-boundary schema changes were introduced (the only schema-adjacent files — device/CIBA authorizations — were not modified).

## TDD Gate Compliance

- Both tasks are `tdd="true"`. RED was established before GREEN: the new at+jwt assertions (`verify_at_jwt/1`) and AUD assertions failed against the opaque-formatter mint before the signer/validator were wired in (verified `RED-as-expected` during execution).
- Task 1 GREEN: `feat(99-04)` `00cde4b`. Task 2 GREEN: `feat(99-04)` `1cb5e8c`. No separate `test(...)` RED commits were created — each task is committed as one atomic `feat` because the JWT-default flip makes test and implementation interdependent (existing-test breakage is a direct consequence of the default change). No REFACTOR commits needed.

## Next Phase Readiness

- AC/device/CIBA all mint through `AccessTokenSigner.issue/3`; `cnf` flows into the at+jwt (Phase 100 sender-constraint prerequisite satisfied for these three paths).
- Plan 05 can re-point `refresh_exchange.ex` (mind the refresh `sub`-sourcing pitfall) and `rfc8693_exchange.ex` (`issue_exchange/4`, bare-string aud) using the same `{%Token{}, raw}` + `%Token{}`-guarded-`with` pattern established here.
- No blockers.

## Self-Check: PASSED

- FOUND: `lib/lockspire/protocol/token_exchange.ex` (modified — `AccessTokenSigner.issue` present; `audience: []` device/CIBA hardcodes absent)
- FOUND: `lib/lockspire/test_repo.ex` (modified — `fetch_active_signing_key/0` delegate present)
- FOUND: `test/lockspire/protocol/token_exchange_test.exs` (modified — AUD-01/AUD-02 device+CIBA + invalid_target tests present)
- FOUND commit: `00cde4b` (feat, Task 1)
- FOUND commit: `1cb5e8c` (feat, Task 2)
- Verification: `mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/device_authorization_test.exs` -> 37 tests, 0 failures; full protocol suite -> 527 tests, 0 failures.

---
*Phase: 99-signer-extraction-jwt-default-issuance*
*Completed: 2026-05-28*
