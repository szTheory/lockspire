---
phase: 98-plug-hardening
verified: 2026-05-28T07:30:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification: null
---

# Phase 98: Plug Hardening Verification Report

**Phase Goal:** `Lockspire.Plug.VerifyToken` accepts only RFC 9068 `at+jwt` access tokens and enforces RFC 9068 / RFC 8725 / RFC 9449 compliance rules that are currently missing, closing five of the seven critical pitfalls before any issuance change ships.
**Verified:** 2026-05-28T07:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|-----------------------------------|--------|----------|
| 1 | Opaque token → distinct `Bearer ... error_description="opaque tokens not accepted on this route"` challenge, not silent `:malformed` | ✓ VERIFIED | `opaque_shape?/1` front-edge check at `verify_token.ex:105-176`; `opaque_token_error/1` at :184-192 emits exact D-01 wording; three-segment-but-bad (`not.a.jwt`) still falls through to `:malformed` (`opaque_shape?/1` returns false for valid Base64URL 3-segment). 7 test occurrences of `opaque_token_not_accepted`; end-to-end wire test asserts the exact `WWW-Authenticate` substring. |
| 2 | JWT with missing/wrong `iss`, missing/non-`at+jwt` `typ`, or missing `exp`/`iat`/`sub` → 401 with distinct reason code naming the RFC rule | ✓ VERIFIED | `validate_rfc9068_compliance/3` at `verify_token.ex:650-665` runs all five checks in order; `rfc9068_error/2` (:312-362) emits five distinct reason codes (`:invalid_typ`, `:invalid_issuer`, `:missing_exp`, `:missing_iat`, `:missing_sub`) each with a distinct RFC-naming `error_description`. `iss` compared exactly to `Config.issuer!()` (:651, 699-704). Step wired AFTER `verify_strict` and BEFORE `time_claims_valid?`/`apply_restrictions` (:583-601). Test coverage: invalid_typ×11, invalid_issuer×4, missing_exp×4, missing_iat×2, missing_sub×3. Runtime log evidence shows `category=token_validation reason=invalid_typ`. |
| 3 | DPoP-bound token failing audience/scope → `DPoP ...` challenge; mTLS-bound and plain-bearer emit correct scheme | ✓ VERIFIED | `challenge_for/2` at `verify_token.ex:510-523` implements the four-row D-05 mapping (cnf.jkt→:dpop, only x5t#S256→:bearer, no-cnf+DPoP-scheme→:dpop, else→:bearer); threaded into audience (:226), scope (:251), and RFC 9068 (:656) error helpers. `require_token.ex` `handle_insufficient_scope/2` (:63-84) and `normalize_insufficient_scope_error/1` (:122-146) now honor `challenge: :dpop` (was hard-coded). DPoP emission via `ProtectedResourceChallenge.put_dpop_challenge/2`. Tests: `DPoP realm`×6, `Bearer realm`×6. Runtime log shows `authorization_scheme=DPoP reason_code=invalid_audience`. |
| 4 | VerifyToken mounted without `audience:` on a pipeline declaring `enforce_audience: true` → `init/1` raises; OR contract test asserts every shipped pipeline declares one | ✓ VERIFIED | BOTH mechanisms shipped (D-07). `init/1` raise at `verify_token.ex:56-61`; test at `verify_token_test.exs:115`. Contract clause at `release_readiness_contract_test.exs:761-791` loops all four RECIPE-01 files via `extract_canonical_pipeline!/2`, flunks (named per file) if `audience:` missing. All four canonical files carry both `enforce_audience: true` and `audience: "billing-api"`. |

**Score:** 4/4 truths verified

### CR-01 Fix Verification (Code Review Blocker)

The 98-REVIEW.md BLOCKER (CR-01: malformed `WWW-Authenticate` headers from unescaped quotes / multi-byte `§` in `error_description`) is confirmed **soundly fixed**:

| Check | Result |
|-------|--------|
| Escaped/embedded double-quotes in any `error_description` (verify_token.ex) | 0 — all five RFC 9068 descriptions reworded to bare claim names (`typ`, `at+jwt`, `iss`, `exp`, `iat`, `sub`) at :318-360 |
| Non-ASCII bytes in `error_description` strings | 0 — `§` replaced with the ASCII word `section`; all 5 remaining `§` are in code comments only (lines 84, 85, 487, 491, 648), never in header-bound strings |
| Both emission paths verified well-formed (behavioral spot-check) | Bearer path (`require_token.ex:158`) and DPoP path (actual `ProtectedResourceChallenge.www_authenticate_value/3`) produce even quote-count + pure US-ASCII for all 5 RFC 9068 codes + opaque |
| CR-01 regression test exists and is end-to-end | `verify_token_test.exs:902-930` asserts the wire header has even `"` count AND `String.length == byte_size` (ASCII-only) — would have caught the original odd-quote malformed bytes |

The five other review findings (WR-01..WR-05) are also present in code: case-insensitive scheme parsing (`extract_token/1` :83-98), `ArgumentError` re-raise for issuer misconfig (:606-616), single `peek_protected_header/1` decode (:568-574), `dpop_nonce` line removed from `normalize_insufficient_scope_error/1` (:139-144), smoke-test GET split (verified by fix report's AST parse).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/lockspire/plug/verify_token.ex` | opaque check, enforce_audience, RFC 9068 step, challenge_for | ✓ VERIFIED | All four plans' code present and wired; compiles clean `--warnings-as-errors` |
| `lib/lockspire/plug/require_token.ex` | DPoP-aware insufficient-scope routing | ✓ VERIFIED | `handle_insufficient_scope/2` + normalizer honor `challenge:`; only legacy `default_invalid_error/0` keeps `:bearer` |
| `test/lockspire/plug/verify_token_test.exs` | opaque, init/1, RFC 9068, challenge tests | ✓ VERIFIED | enforce_audience×18; CR-01 regression at :902-930; all reason codes covered |
| `test/lockspire/plug/require_token_test.exs` | normalize/route DPoP tests | ✓ VERIFIED | 273 lines; passes |
| `test/lockspire/release_readiness_contract_test.exs` | four-file audience: substring clause | ✓ VERIFIED | D-07 clause at :761-791 reuses `extract_canonical_pipeline!/2` (no parallel extractor) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `verify_token.ex` opaque/RFC9068 error map | `require_token.ex` WWW-Authenticate | structured map (`challenge:`, `error:`, `error_description:`) | ✓ WIRED | `do_verify_token/3` :138-149 propagates `%{reason_code: _}` map → `handle_structured_error/2` → emission |
| `verify_token.ex` `challenge: :dpop` | `protected_resource_challenge.ex` `put_dpop_challenge/2` | `require_token.ex:51,75` dispatch | ✓ WIRED | DPoP realm header confirmed in 6 tests + runtime log `authorization_scheme=DPoP` |
| `verify_token.ex` issuer check | `Lockspire.Config.issuer!/0` | exact string compare | ✓ WIRED | `check_issuer/3` :699-704; 2 call sites |
| canonical pipeline files | contract test | `extract_canonical_pipeline!/2` | ✓ WIRED | All 4 files contain `enforce_audience: true` + `audience:`; clause loops & flunks per-file |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Bearer-path headers well-formed (5 RFC codes + opaque) | inline `mix run` against require_token.ex:158 shape | even quotes + ASCII for all 6 | ✓ PASS |
| DPoP-path headers well-formed | `ProtectedResourceChallenge.www_authenticate_value/3` actual builder | even quotes + ASCII for all 6 | ✓ PASS |
| Targeted plug + contract tests | `mix test verify_token_test require_token_test release_readiness_contract_test` | 114 tests, 0 failures | ✓ PASS |
| Full suite | `mix test` | 995 tests, 0 failures (272 excluded) | ✓ PASS |
| Clean compile | `mix compile --warnings-as-errors --force` | Generated lockspire app (no errors) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| VERIFIER-01 | 98-01 | Opaque tokens explicitly rejected with distinct challenge | ✓ SATISFIED | `opaque_shape?/1` + `opaque_token_error/1`; Truth #1 |
| VERIFIER-02 | 98-03 | RFC 9068 §4 issuer pinning, distinct reason | ✓ SATISFIED | `check_issuer/3` vs `Config.issuer!()`; Truth #2 |
| VERIFIER-03 | 98-03 | `typ: at+jwt` enforced, defeats cross-JWT confusion | ✓ SATISFIED | `check_at_jwt_typ/2` (case-insensitive, strips `application/`); Truth #2 |
| VERIFIER-04 | 98-03 | `exp`/`iat`/`sub` required | ✓ SATISFIED | `check_exp/iat/sub_*` :706-732; Truth #2 |
| VERIFIER-05 | 98-04 | WWW-Authenticate scheme derived from binding type + request scheme | ✓ SATISFIED | `challenge_for/2` four-row D-05 mapping; Truth #3 |
| VERIFIER-06 | 98-02 | `audience:` effectively mandatory; cross-API reuse closed | ✓ SATISFIED | `init/1` raise + contract clause; Truth #4 |

All six declared requirement IDs (VERIFIER-01..06) are present in PLAN frontmatter, mapped to Phase 98 in REQUIREMENTS.md (lines 24-29, 121-126, 158), and satisfied. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| verify_token.ex | 110, 487, 491 | `challenge: :bearer` / `→ :bearer` in comments | ℹ️ Info | Comments documenting the default; not hard-coded sites |
| require_token.ex | 107 | `challenge: :bearer` in `default_invalid_error/0` | ℹ️ Info | Intentional per D-06 — legacy bare-atom path has no parseable binding |
| release_readiness_contract_test.exs | 778 | `String.length(captured) > 0` tautological given regex | ℹ️ Info | Review IN-04 (out-of-scope info finding); `flunk` branch is the real enforcement, contract still sound |

No 🛑 Blocker or ⚠️ Warning anti-patterns. No `TODO`/`FIXME`/`TBD`/`XXX` debt markers in modified files. The CR-01 blocker from the code review is fixed and regression-guarded.

### Human Verification Required

None. All four success criteria are wire-level header assertions, init/1 raises, and contract-test invariants — fully verified programmatically via the test suite (995/0), runtime log evidence, and behavioral spot-checks on both emission paths.

### Gaps Summary

No gaps. The phase goal is achieved: `VerifyToken` rejects opaque tokens with a distinct named challenge (VERIFIER-01), enforces RFC 9068 `iss`/`typ`/`exp`/`iat`/`sub` with five distinct reason codes (VERIFIER-02/03/04), derives the `WWW-Authenticate` scheme from binding type per RFC 9449 §7.1 / RFC 8705 §3 (VERIFIER-05), and structurally closes cross-API token reuse via both an `init/1` raise and a release-readiness contract clause (VERIFIER-06). The code-review BLOCKER (CR-01) and all five warnings are fixed; the CR-01 fix produces well-formed RFC 7235 quoted-strings on both Bearer and DPoP emission paths, confirmed by behavioral spot-check and a dedicated end-to-end regression test. Full suite: 995 tests, 0 failures; clean compile with warnings-as-errors.

---

_Verified: 2026-05-28T07:30:00Z_
_Verifier: Claude (gsd-verifier)_
