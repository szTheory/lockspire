---
phase: 98-plug-hardening
fixed_at: 2026-05-28T11:22:00Z
review_path: .planning/phases/98-plug-hardening/98-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 98: Code Review Fix Report

**Fixed at:** 2026-05-28T11:22:00Z
**Source review:** .planning/phases/98-plug-hardening/98-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (CR-01 + WR-01 through WR-05)
- Fixed: 6
- Skipped: 0

All fixes verified against `mix compile --warnings-as-errors` (clean) and the full
`mix test` suite (baseline 992 tests / 0 failures; 995 tests / 0 failures after
adding 3 regression tests). Info findings (IN-01 through IN-04) were out of scope
for this `critical_warning` run and were not touched.

## Fixed Issues

### CR-01: Five new RFC 9068 reason-code descriptions emit a malformed WWW-Authenticate header

**Files modified:** `lib/lockspire/plug/verify_token.ex`, `test/lockspire/plug/verify_token_test.exs`
**Commit:** ec78502
**Applied fix:** Reworded all five `rfc9068_error/2` `error_description` strings to
drop the embedded literal double-quote characters (`\"typ\"`, `\"at+jwt\"`,
`\"iss\"`, `\"exp\"`, `\"iat\"`, `\"sub\"`) and replaced the multi-byte `§`
(U+00A7) with the ASCII word `section`. The descriptions now interpolate into the
`WWW-Authenticate` quoted-string as a single well-formed `qdtext` run per RFC 7235
§2.2, and the header is pure US-ASCII per RFC 9110 §5.5. The existing substring
assertions (`=~ "typ"`, `=~ "at+jwt"`, etc.) still pass because the bare claim
names remain in the reworded text — no expected-substring updates were needed.
Added a CR-01 regression assertion to the end-to-end `invalid_typ` test that the
emitted header has an even count of `"` (each quoted-string opens and closes) and
contains only single-byte ASCII characters (`String.length == byte_size`), which
would have caught the original malformed bytes.

### WR-01: Authorization scheme parsing is case-sensitive

**Files modified:** `lib/lockspire/plug/verify_token.ex`, `test/lockspire/plug/verify_token_test.exs`
**Commit:** 125dff0
**Applied fix:** Rewrote `extract_token/1` to split the `Authorization` value on
the first space and compare the scheme with `String.downcase/1`, normalizing back
to the canonical `"Bearer"` / `"DPoP"` tokens so `challenge_from_scheme/1`
continues to match `"DPoP"` literally (preserving the D-05 row-3 request-scheme
tiebreaker). Added two regression tests: lowercase `bearer` normalizes to
`authorization_scheme: "Bearer"` and uppercase `DPOP` normalizes to `"DPoP"`, both
verifying successfully.

### WR-02: Config.issuer!/0 misconfiguration is swallowed by the verify rescue

**Files modified:** `lib/lockspire/plug/verify_token.ex`, `test/lockspire/plug/verify_token_test.exs`
**Commit:** 83449d0
**Applied fix:** Chose review Option 2 (re-raise) over Option 1 (memoize at
`init/1`). `VerifyToken` is declared in a Phoenix router pipeline
(`plug Lockspire.Plug.VerifyToken, ...` in both the install template and the
adoption demo), where `init/1` is evaluated at **compile time** — memoizing
`Config.issuer!()` there would read config that may be unset during compilation
and bake a stale value, which is the riskier change. Instead, added an
`error in ArgumentError -> reraise error, __STACKTRACE__` clause ahead of the
catch-all in `verify_signature_and_claims/3`'s `rescue`, so a runtime issuer
misconfiguration (operator clears `:issuer`) now fails loudly with the real
`ArgumentError` instead of being coerced to `:verification_crashed` / generic
`invalid_token`. Genuine verification crashes still degrade to
`:verification_crashed`. Added a regression test that clears `:issuer` config
(restored via `on_exit`) and asserts `ArgumentError` is raised.

### WR-03: peek_typ/1 re-decodes the protected header that extract_kid/1 already decoded

**Files modified:** `lib/lockspire/plug/verify_token.ex`
**Commit:** da7f018
**Applied fix:** Introduced a single `peek_protected_header/1` helper that decodes
the JWS protected header once (`JOSE.JWT.peek_protected/1` + `JOSE.JWS.to_map/1`)
and returns `{:ok, map}` / `{:error, :malformed}`. Refactored `extract_kid/1` and
`check_at_jwt_typ/2` to both consume it, deleting the duplicate `peek_typ/1`. A
header that fails to parse now yields a uniform `:malformed` from both consumers
(previously `peek_typ/1` returned `nil` and `check_at_jwt_typ/2` misclassified it
as `:invalid_typ`). No observable behavior change in the live flow because
`extract_kid/1` already runs first and short-circuits malformed headers, so the
full suite stayed green without test changes.

### WR-04: normalize_insufficient_scope_error/1 propagates a dpop_nonce no caller sets

**Files modified:** `lib/lockspire/plug/require_token.ex`
**Commit:** a46fd86
**Applied fix:** Deleted the speculative `dpop_nonce: Map.get(error, :dpop_nonce)`
line from `normalize_insufficient_scope_error/1`. No upstream path sets
`dpop_nonce` on an insufficient-scope error, and
`ProtectedResourceChallenge.put_dpop_challenge/2` already calls
`maybe_put_dpop_nonce/2`, which threads any nonce present on the structured error
and passes through when the key is absent. Removing the key makes
`maybe_put_dpop_nonce/2` fall to its pass-through clause exactly as before, so the
full suite stayed green without test changes.

### WR-05: Smoke test issues two unrelated GET /verify requests in one expression

**Files modified:** `scripts/demo/adoption_smoke.py`
**Commit:** 6b53e0e
**Applied fix:** Split the inline nested `browser.request("GET", "/verify")` out
into its own `verify_page = browser.request("GET", "/verify")` statement with an
explicit `assert_status(verify_page, 200, "verify page")`, then read
`verify_page["body"]` for the CSRF token in the subsequent POST. This makes both
HTTP requests visible and surfaces a GET failure directly instead of masking it as
a `csrf()` "missing CSRF token" assertion on an empty body. Verified with a Python
AST parse (the smoke script requires a running server and is not part of
`mix test`).

---

_Fixed: 2026-05-28T11:22:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
