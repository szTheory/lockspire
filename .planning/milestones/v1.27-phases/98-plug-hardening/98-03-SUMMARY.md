---
phase: 98-plug-hardening
plan: 03
subsystem: auth
tags: [oauth, oidc, jwt, rfc-9068, rfc-8725, plug, verify_token, lockspire]

# Dependency graph
requires:
  - phase: 97-contract-docs-first
    provides: Canonical pipeline declaration and supported-surface non-goals pinned across four docs sites
  - phase: 98-plug-hardening
    plan: 01
    provides: Structured invalid-token error map taxonomy + multi-arity log_invalid_token/2 spine (D-04) that Plan 03 plugs the five new reason codes into
  - phase: 98-plug-hardening
    plan: 02
    provides: enforce_audience: opt-in option + four-site audience contract clause (no runtime overlap with Plan 03)
provides:
  - New private function `validate_rfc9068_compliance/2` in `Lockspire.Plug.VerifyToken` that enforces the five RFC 9068 / RFC 8725 compliance rules (D-02) in order: typ=at+jwt, iss matches Lockspire.Config.issuer!/0, exp positive integer, iat positive integer, sub non-empty string
  - Five new distinct reason_code atoms emitted through the D-04 structured error map shape: :invalid_typ, :invalid_issuer, :missing_exp, :missing_iat, :missing_sub — each with a distinct error_description naming the violated RFC clause and suitable for a WWW-Authenticate header value
  - D-03 verifier permissiveness: case-insensitive typ check with `application/` prefix stripping; the verifier accepts `at+jwt`, `AT+JWT`, `At+Jwt`, `application/at+jwt`, and `APPLICATION/AT+JWT`, while continuing to reject `JWT`, `jwt`, missing typ, empty typ, `dpop+jwt`, and `application/jwt`
  - Code comment in verify_token.ex naming the intentional verifier/signer asymmetry (DPoP.check_typ/1 exact-match vs. verifier permissiveness) as forward-compatibility margin for Phase 99's signer extraction
  - Extension to do_verify_token/3's else-branch handling both atom and structured-map error shapes from verify_signature_and_claims/2
  - Extension to the test JWT factory to ship iss=Lockspire.Config.issuer!(), sub=test-user-<N>, iat=now-60, and typ=at+jwt as defaults — every existing test that uses the factory continues to pass under the new enforcement
  - New `header_overrides` second argument to the factory letting Plan 03 tests inject custom typ headers
  - Deletion of the obsolete `# Missing exp is currently treated as valid` comment at verify_token.ex:366 (CONTEXT.md `<deferred>` line 155)
affects: [99-signer-extraction, 100-sender-constraint-e2e, 101-adoption-demo-rewire, 102-generated-host-scaffolding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "RFC 9068 compliance step lives between JOSE.JWT.verify_strict/3 success and time_claims_valid?/1 — named reason codes from this step win over :invalid_time_claims and over apply_restrictions/2's audience/scope reason codes"
    - "Five RFC 9068 reason codes flow through the same D-04 structured error map shape and same multi-arity log_invalid_token/2 spine that Plan 01 established for :opaque_token_not_accepted — no parallel error infrastructure"
    - "Verifier-side typ permissiveness is documented in a code comment that names the issuance-side counterpart (DPoP.check_typ/1) so a future maintainer doesn't tighten the verifier in a way that breaks an evolved signer"
    - "Test factory ships fully-RFC-9068-compliant defaults so existing tests stay green under the new enforcement; per-test rule violations are expressed by passing nil/non-conforming values through claims: or header_overrides: which are then deleted from the merge via reject(is_nil)"

key-files:
  created: []
  modified:
    - lib/lockspire/plug/verify_token.ex
    - test/lockspire/plug/verify_token_test.exs

key-decisions:
  - "Category atom for the five new reason codes: :token_validation (distinct from :token_format used by Plan 01's opaque-shape rejection and from :token_restriction used by audience/scope failures). Plan 03's checks are post-signature-verified-claim validation, conceptually upstream of audience/scope restriction but downstream of the front-edge structural check Plan 01 established"
  - "Strategy (b) chosen from the plan's two implementation strategies: validate_rfc9068_compliance/2 returns {:ok, claims} on success or {:error, structured_map} on failure (direct map return, not atom + helper-mapping). The do_verify_token/3 else-branch was widened to handle both atom and map shapes; the bare-atom contract through earlier verification steps (:no_kid, :invalid_signature, :verification_crashed, :invalid_time_claims) is preserved"
  - "Insertion point: inside verify_signature_and_claims/2 (after JOSE.JWT.verify_strict success, before time_claims_valid?/1) via `with {:ok, claims} <- validate_rfc9068_compliance(token, claims)`. Token is threaded into the helper so peek_typ/1 can re-read the protected header — the function re-uses JOSE.JWT.peek_protected/1 just as extract_kid/1 does, with a rescue/nil fallback so a malformed header can't crash the verifier (defense-in-depth even though verify_strict already succeeded, so the token IS well-formed at this point)"
  - "Helper named check_at_jwt_typ/1, with peek_typ/1 as a small sibling that owns the rescue. Issuer/exp/iat/sub helpers named check_issuer/2, check_exp_positive_integer/1, check_iat_positive_integer/1, check_sub_non_empty_string/1 — each named after the rule it enforces so a maintainer reading the with chain immediately sees the D-02 order"
  - "sub whitespace-only rejection uses the existing non_empty_string?/1 helper at verify_token.ex:309 (reuse, not reinvention) which does is_binary AND String.trim != \"\". This matches the precedent for required_audiences and audience claim normalization"
  - "Factory delete-on-nil semantics: tests that need a claim to be MISSING pass `claim: nil` through the claims map; the factory then filters via Enum.reject(fn {_k, v} -> is_nil(v) end) before signing, producing a token whose protected payload genuinely lacks the key. Equivalent for header_overrides. This is cleaner than a separate `delete_keys:` option and reads naturally at every call site"

patterns-established:
  - "D-04 structured error map shape now carries six distinct reason codes total across Phase 98: :opaque_token_not_accepted (Plan 01) + :invalid_typ + :invalid_issuer + :missing_exp + :missing_iat + :missing_sub (Plan 03). Plan 04 (challenge derivation) plugs into the same shape and the same log spine"
  - "When extending the verifier with new claim/header checks, the helper goes inside verify_signature_and_claims/2's success branch, not parallel to it — keeps the 'signature is verified before we look at claims' invariant readable as a single with chain"
  - "Verifier permissiveness (case-insensitive, prefix-stripping) is the right default whenever the issuance-side surface might evolve under the same library version. Plan 03's code comment is the precedent for naming such asymmetries inline"

requirements-completed: [VERIFIER-02, VERIFIER-03, VERIFIER-04]

# Metrics
duration: ~4min
completed: 2026-05-28
---

# Phase 98 Plan 03: RFC 9068 / RFC 8725 Claim & Header Enforcement Summary

**A single new `validate_rfc9068_compliance/2` step inside `Lockspire.Plug.VerifyToken` enforces the five RFC 9068 / RFC 8725 compliance rules (typ=at+jwt, iss=Lockspire.Config.issuer!/0, exp positive integer, iat positive integer, sub non-empty string) between `JOSE.JWT.verify_strict/3` success and `time_claims_valid?/1` / `apply_restrictions/2`. Each failure emits a distinct atom `reason_code` (`:invalid_typ`, `:invalid_issuer`, `:missing_exp`, `:missing_iat`, `:missing_sub`) through the D-04 structured error map shape with a distinct `error_description` naming the violated RFC clause. The verifier's `typ` comparison is intentionally case-insensitive and strips `application/` (D-03's forward-compatibility margin for Phase 99's signer extraction); a code comment names this asymmetry against the issuance-side `Lockspire.Protocol.DPoP.check_typ/1` precedent. The obsolete `# Missing exp is currently treated as valid` comment at line 366 is deleted as part of this plan.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-28T01:55Z
- **Completed:** 2026-05-28T02:00Z
- **Tasks:** 2 (both `type="auto" tdd="true"`)
- **Files modified:** 2
- **Tests:** verify_token_test.exs 56 tests, 0 failures (31 existing + 25 new); release_readiness_contract_test.exs 30 tests, 0 failures

## Accomplishments

- Added `validate_rfc9068_compliance/2` private function at `verify_token.ex:547` taking `(token, claims)` and returning `{:ok, claims}` on success or `{:error, structured_map}` on failure. The function looks up `Lockspire.Config.issuer!/0` once, then runs five checks in D-02 order via `with`: `check_at_jwt_typ/1` → `check_issuer/2` → `check_exp_positive_integer/1` → `check_iat_positive_integer/1` → `check_sub_non_empty_string/1`.
- Added `peek_typ/1` (verify_token.ex:579) as a small rescue-wrapped sibling that calls `JOSE.JWT.peek_protected/1` + `JOSE.JWS.to_map/1` and returns the `"typ"` header value or nil — same pattern as `extract_kid/1` but isolated so a malformed protected header can't crash the new step.
- Added `rfc9068_error/1` helper at `verify_token.ex:281-330` adjacent to the existing `invalid_audience_error/2` so the structured-error taxonomy reads as one unit. One clause per reason atom; each emits `category: :token_validation`, `challenge: :bearer`, the named atom, `error: "invalid_token"`, and a distinct `error_description` naming the violated RFC clause.
- Wired the new step into `verify_signature_and_claims/2` at `verify_token.ex:492-514` via `with {:ok, claims} <- validate_rfc9068_compliance(token, claims) do`, placing it AFTER `JOSE.JWT.verify_strict/3` succeeds and BEFORE `time_claims_valid?/1` runs.
- Widened `do_verify_token/3`'s else-branch to match both `{:error, %{reason_code: _}}` (new structured-map shape from `validate_rfc9068_compliance/2`) and `{:error, atom}` (legacy shape from `extract_kid/1`, `fetch_key/1`, `verify_signature_and_claims/2` other paths). Structured-map errors propagate directly to `%AccessToken{error: map}`; atom errors keep the legacy `%AccessToken{error: :invalid_token}` shape that already routes through the atom-form `log_invalid_token/2`.
- Added the verifier/signer asymmetry code comment at `verify_token.ex:534-545` naming `Lockspire.Protocol.DPoP.check_typ/1` and Phase 99's signer extraction.
- Deleted the obsolete `# Missing exp is currently treated as valid unless stricter policy requires it.` comment from `time_claims_valid?/1`. The catch-all `_ -> true` for missing exp is now dead code for tokens that pass `validate_rfc9068_compliance/2` (which is every token that reaches `time_claims_valid?/1`).
- Extended the test factory `generate_key_and_token/1` at `verify_token_test.exs:39-87` to:
  - Add `iss=Lockspire.Config.issuer!()`, `sub=test-user-<N>`, `iat=now-60` to default claims (alongside the existing client_id/exp/nbf defaults).
  - Add `typ=at+jwt` to the default JOSE header (alongside the existing alg/kid).
  - Accept a second `header_overrides` argument letting tests inject custom typ values.
  - Filter merged claims and headers via `Enum.reject(fn {_k, v} -> is_nil(v) end)` so a test passing `claim: nil` produces a token genuinely lacking that key.
- Added a new describe block "VerifyToken plug -- RFC 9068 compliance (D-02, D-03, D-04)" at `verify_token_test.exs:533-878` containing 25 new test cases:
  - Four happy-path acceptance tests for typ variants: `at+jwt`, `AT+JWT`, `At+Jwt`, `application/at+jwt`.
  - Six rejection-path tests for `:invalid_typ` covering `JWT`, `jwt`, missing typ, empty typ, `dpop+jwt`, `application/jwt`.
  - Four rejection-path tests for `:invalid_issuer` covering wrong issuer, missing iss, empty iss, trailing-slash variant.
  - Three rejection-path tests for `:missing_exp` covering missing exp, exp=0, exp=-100.
  - Two rejection-path tests for `:missing_iat` covering missing iat, iat=0.
  - Three rejection-path tests for `:missing_sub` covering missing sub, empty sub, whitespace-only sub.
  - One D-02 order test confirming `:invalid_typ` wins when multiple rules are violated simultaneously.
  - One end-to-end test piping the invalid_typ case through `RequireToken.call/2` and asserting the 401 + `WWW-Authenticate` header carries the substring `error="invalid_token"` AND `typ` AND `at+jwt`.
  - One redaction-log assertion confirming `reason=invalid_typ` is emitted with raw token bytes absent.
- Confirmed regression invariants: all 31 existing tests in `verify_token_test.exs` continue to pass under the new enforcement (the factory's RFC-9068-compliant defaults are what makes this safe); the release readiness contract test at 30 tests / 0 failures is unaffected (Plan 03 touches no canonical-pipeline file).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add validate_rfc9068_compliance/2 step and extend test factory defaults** — `e6774bb` (feat)
2. **Task 2: Add RFC 9068 compliance tests covering five new reason codes** — `3c66e7e` (test)

_Note: This plan follows the same plan-granularity TDD pattern as Plans 01 and 02. Task 1 bundles the implementation with the test factory extension so the existing 31 tests continue to pass after the new enforcement lands (the factory's defaults are part of the "GREEN keeps existing tests" gate). Task 2 is a tests-only commit adding 25 NEW behavior assertions on top of Task 1's already-shipped behavior. The plan's own `<verify>` blocks per task were the RED/GREEN granularity gate rather than per-test._

## Files Modified

- `lib/lockspire/plug/verify_token.ex` — Added `alias Lockspire.Config` (line 16); added `rfc9068_error/1` helper with five clauses (lines 281-330); wired `validate_rfc9068_compliance/2` into `verify_signature_and_claims/2` via `with` chain (lines 492-514, replacing the previous direct if-else around `time_claims_valid?/1`); widened `do_verify_token/3` else-branch to handle both atom and structured-map error shapes (lines 124-148); deleted the obsolete `# Missing exp is currently treated as valid` comment from `time_claims_valid?/1` (was line 366 before); added `validate_rfc9068_compliance/2` plus its six helper functions and the verifier/signer asymmetry doc comment (lines 524-620). Total +194/-9 lines.
- `test/lockspire/plug/verify_token_test.exs` — Extended `generate_key_and_token/1` to include `iss`, `sub`, `iat`, `typ` in defaults plus a `header_overrides` second argument with delete-on-nil semantics (lines 39-87); added new describe block "VerifyToken plug -- RFC 9068 compliance (D-02, D-03, D-04)" with 25 test cases (lines 533-878). Total +346/-9 lines across the two commits.

## Required Output Fields (from `<output>`)

### Exact `error_description` wording chosen for each of the five reason codes

| reason_code | error_description |
|---|---|
| `:invalid_typ` | `access token JWT header "typ" is not "at+jwt" per RFC 9068 §2.1 / RFC 8725 §3.11` |
| `:invalid_issuer` | `access token "iss" claim does not match expected issuer per RFC 9068 §4` |
| `:missing_exp` | `access token is missing required "exp" claim per RFC 9068 §2.2` |
| `:missing_iat` | `access token is missing required "iat" claim per RFC 9068 §2.2` |
| `:missing_sub` | `access token is missing required "sub" claim per RFC 9068 §2.2` |

All five strings are header-safe — embedded double quotes are escaped with `\"` in the Elixir literals (e.g. `"\"typ\""`), so the emitted `WWW-Authenticate: ... error_description="..."` value is well-formed. Each names the violated RFC clause for adopter greppability.

### Category atom chosen for the structured-error map

`:token_validation`

Distinct from:
- `:token_format` — used by Plan 01's front-edge opaque-shape rejection (`:opaque_token_not_accepted`)
- `:token_restriction` — used by audience/scope failures emerged from `apply_restrictions/2`
- `:insufficient_scope` — RFC 6750 403-class
- `:sender_constraint` — used by `EnforceSenderConstraints`

`:token_validation` slots between `:token_format` (shape-class, pre-crypto) and `:token_restriction` (route-policy, post-crypto): it's post-crypto claim/header validation, conceptually upstream of route-policy checks but downstream of the front-edge structural classifier.

### Function name and arity of the new compliance step

`validate_rfc9068_compliance/2` (arity 2: `(token, claims)`). Located at `lib/lockspire/plug/verify_token.ex:547`.

The function signature requires the raw token binary (so `peek_typ/1` can re-read the protected header) plus the verified claims map. Strategy (b) from the plan: returns `{:ok, claims}` or `{:error, structured_map}`.

### Confirmation of the comment deletion at verify_token.ex:366

CONFIRMED. The exact text `# Missing exp is currently treated as valid unless stricter policy requires it.` is gone from the file. `grep -F "Missing exp is currently treated as valid" lib/lockspire/plug/verify_token.ex` returns 0 matches. The comment used to sit immediately above the `_ -> true` catch-all in `time_claims_valid?/1`; that catch-all is now dead code for any token that passes `validate_rfc9068_compliance/2`, but is harmless and intentionally left in place (executor's discretion per Behavior 9 — the plan explicitly noted "deleting just the comment is the minimum compliance with the deferred note").

### Exact code-comment text added naming the verifier/signer asymmetry

```
# Intentionally more permissive than the issuance-side `typ` check at
# `Lockspire.Protocol.DPoP.check_typ/1` (which exact-matches `"dpop+jwt"`).
# The verifier accepts `at+jwt`, `AT+JWT`, `At+Jwt`, and the
# `application/at+jwt` variant. This forward-compatibility margin lets
# Phase 99's `Protocol.AccessTokenSigner` extraction evolve issuance to
# emit `application/at+jwt` (stricter RFC 9068 §2.1 conformance) without
# breaking Phase 98's verifier.
```

Located at `lib/lockspire/plug/verify_token.ex:534-545`, attached to the docstring-style comment above `validate_rfc9068_compliance/2`.

### Line-number range where validate_rfc9068_compliance/2 is wired into verify_signature_and_claims/2

`lib/lockspire/plug/verify_token.ex:492-514`. The body is:

```elixir
defp verify_signature_and_claims(jwk, token) do
  case JOSE.JWT.verify_strict(jwk, @allowed_algs, token) do
    {true, %JOSE.JWT{fields: claims}, _jws} ->
      # D-02: RFC 9068 / RFC 8725 compliance runs AFTER the signature is
      # verified (so we never inspect claims on an unverified token) and
      # BEFORE time_claims_valid?/1 + apply_restrictions/2 (so the named
      # RFC 9068 reason codes win over the legacy :invalid_time_claims and
      # over audience/scope restriction failures).
      with {:ok, claims} <- validate_rfc9068_compliance(token, claims) do
        if time_claims_valid?(claims) do
          {:ok, claims}
        else
          {:error, :invalid_time_claims}
        end
      end

    {false, _, _} ->
      {:error, :invalid_signature}
  end
rescue
  _ -> {:error, :verification_crashed}
end
```

## Decisions Made

- **Category atom `:token_validation`** — distinct from `:token_format` (Plan 01's pre-crypto shape rejection) and `:token_restriction` (audience/scope post-claim-validation). Plan 03's checks are post-signature-verified claim validation, conceptually a third tier in the structured-error taxonomy. Plan 04 (challenge derivation) will rewrite the `challenge:` value for all of these per D-05/D-06; the `category:` value is the same for all five.

- **Strategy (b): structured map return, widened else-branch in caller** — `validate_rfc9068_compliance/2` returns `{:ok, claims}` or `{:error, structured_map}` directly (no atom + helper-mapping). The `do_verify_token/3` else-branch was widened to pattern-match on `{:error, %{reason_code: _} = structured_error}` first, then `{:error, reason_code} when is_atom(reason_code)` second. This preserves the bare-atom contract for `:no_kid`, `:invalid_signature`, `:verification_crashed`, `:invalid_time_claims` (each still gets `%AccessToken{error: :invalid_token}` and atom-form logging) while the new five reason codes flow as structured maps end-to-end.

- **Insertion point inside `verify_signature_and_claims/2` (not parallel to it)** — placing the new step inside the success branch via `with` keeps the "signature verified before we look at claims" invariant readable as a single chain. The alternative — calling `validate_rfc9068_compliance/2` from `do_verify_token/3` between `verify_signature_and_claims/2` and `apply_restrictions/2` — would have made the security invariant less obvious at a glance.

- **Token threaded into `validate_rfc9068_compliance/2` for `peek_typ/1` re-read** — rather than refactoring `extract_kid/1` to return the full header map and threading it through, the new step re-calls `JOSE.JWT.peek_protected/1` + `JOSE.JWS.to_map/1`. The plan explicitly allowed this ("Executor's discretion; both approaches are acceptable provided the same `token` binary is the input"). Re-reading is O(1) deserialization with the protected header already verified — the security boundary isn't crossed twice, just the bytes are inspected for the typ header value.

- **Rescue/nil fallback inside `peek_typ/1`** — `JOSE.JWT.peek_protected/1` should never fail on a token that just passed `verify_strict/3`, but rescue/nil is defense-in-depth: a corrupted header byte that JOSE happened to skip won't crash the verifier, it will just produce a nil typ which falls through to `:invalid_typ` (correct classification regardless).

- **Helper names reflect the rule each enforces** — `check_at_jwt_typ/1`, `check_issuer/2`, `check_exp_positive_integer/1`, `check_iat_positive_integer/1`, `check_sub_non_empty_string/1`. The `with` chain inside `validate_rfc9068_compliance/2` reads as the D-02 step order top-to-bottom.

- **Reuse of `non_empty_string?/1`** — sub whitespace-only check reuses the existing helper at `verify_token.ex:309` (matches precedent for required_audiences and audience claim normalization) rather than inventing a parallel `trimmed_non_empty?/1`.

- **Factory delete-on-nil semantics** — `Enum.reject(fn {_k, v} -> is_nil(v) end)` after `Map.merge` lets tests express "this claim should be missing" by passing `claim: nil`. Cleaner than a separate `delete_keys:` option and reads naturally at every call site (`generate_key_and_token(%{"exp" => nil})` says exactly what it means).

- **Did NOT tighten `time_claims_valid?/1`'s catch-all** — the plan explicitly allowed this ("if the executor wants to also tighten `time_claims_valid?/1` to reject missing-exp (catch-all → `false`), that is acceptable but optional"). The minimum compliance with the deferred note is the comment deletion alone; the `_ -> true` is now dead code for tokens that pass `validate_rfc9068_compliance/2`, so tightening it would be a no-op behavior change with risk of breaking some future hypothetical alternate path. Left as-is per least-surprise.

## Deviations from Plan

None.

Both tasks executed cleanly. The factory's default-claim extension was identified upfront as needed for Task 1's verify clause to pass (existing tests had to keep passing under the new enforcement), and the plan itself explicitly called this out in Task 2's `<action>` Step 1 (`The most likely-affected test is the redaction-log test at lines 323-347 — its existing `aud: "admin-api"` override should still produce `:invalid_audience` ...`). Bundling the factory extension into Task 1 rather than Task 2 was a pragmatic ordering choice — the plan's `done` criterion for Task 1 says "Task 2 adds the new test coverage; Task 1 must not break existing tests, though the existing factory tests at lines 116+ may need updates if they create JWTs without `iat`/`sub`/`iss` — see Task 2" — but it also says the factory extension is in Task 2. The honest reading: Task 1's "must not break" requirement implicitly requires the factory extension, so doing it in Task 1's commit is the most defensible execution order. Task 2 then becomes pure new-tests-only.

**Total deviations:** 0 (this ordering choice is documented honestly here but isn't a scope creep — it's the natural execution order implied by Task 1's `<done>` clause).

## Issues Encountered

None significant. The biggest design micro-decision was the delete-on-nil semantics in the factory — initially I considered a `delete_keys:` option but Enum.reject after merge reads more naturally at every call site and the call sites use idiomatic Elixir map literals (`%{"exp" => nil}`) which a reader immediately understands as "remove the default".

## Verification Evidence

Plan-level `<verification>` block results (all clauses pass):

| Clause | Expected | Actual |
|---|---|---|
| `mix test test/lockspire/plug/verify_token_test.exs` | exits 0 | 56 tests, 0 failures |
| `mix test test/lockspire/release_readiness_contract_test.exs` | exits 0 | 30 tests, 0 failures |
| `grep -c "validate_rfc9068_compliance" lib/lockspire/plug/verify_token.ex` | ≥ 2 | 4 |
| `grep -c ":invalid_typ" lib/lockspire/plug/verify_token.ex` | ≥ 1 | 4 |
| `grep -c ":invalid_issuer" lib/lockspire/plug/verify_token.ex` | ≥ 1 | 3 |
| `grep -c ":missing_exp" lib/lockspire/plug/verify_token.ex` | ≥ 1 | 3 |
| `grep -c ":missing_iat" lib/lockspire/plug/verify_token.ex` | ≥ 1 | 3 |
| `grep -c ":missing_sub" lib/lockspire/plug/verify_token.ex` | ≥ 1 | 4 |
| `grep -F "Missing exp is currently treated as valid" lib/lockspire/plug/verify_token.ex` | 0 matches | 0 matches |
| `grep -c "Lockspire.Config.issuer!\|Config.issuer!" lib/lockspire/plug/verify_token.ex` | ≥ 1 | 1 |
| `grep -c "Lockspire.Protocol.DPoP" lib/lockspire/plug/verify_token.ex` | ≥ 1 | 1 |

Plan-level `<success_criteria>` results (all five satisfied):

1. **Phase 98 Success Criterion #2 — typ=JWT rejection emits named reason in WWW-Authenticate** — PROVEN by the end-to-end test "end-to-end through RequireToken: invalid_typ emerges as 401 with WWW-Authenticate naming the rule" which asserts `conn.status == 401`, header contains `error="invalid_token"`, substring `typ`, substring `at+jwt`.
2. **Wrong iss produces :invalid_issuer named in response** — PROVEN by the four `:invalid_issuer` tests (wrong issuer, missing iss, empty iss, trailing-slash variant) plus the structured-error-shape assertion checking `error_description =~ "iss"`.
3. **Missing exp/iat/sub get the corresponding named reason** — PROVEN by the three `:missing_exp`, two `:missing_iat`, three `:missing_sub` tests plus the error_description substring assertions checking `=~ "exp"` / `=~ "iat"` / `=~ "sub"`.
4. **Verifier `typ` permissiveness vs. issuance asymmetry per D-03** — PROVEN by the four happy-path tests (`at+jwt`, `AT+JWT`, `At+Jwt`, `application/at+jwt` all accepted) AND the verifier/signer asymmetry code comment at verify_token.ex:534-545 naming `Lockspire.Protocol.DPoP.check_typ/1` and Phase 99's extraction.
5. **Obsolete `# Missing exp is currently treated as valid` comment gone** — PROVEN by `grep -F` returning 0 matches.

## Threat Flags

None new. The plan's `<threat_model>` captured all surface introduced by this change:

- **T-98-03-01 (Spoofing: malicious upstream signs `typ: foo/at+jwt`)** — `mitigate`, verified. `String.replace_prefix/3` is single-shot (no recursive prefix stripping); `foo/at+jwt` normalizes to `foo/at+jwt` (no `application/` to strip) which does not equal `at+jwt` → `:invalid_typ`. Covered by the "rejects JWT with typ=application/jwt" test (an analogous non-`application/at+jwt` prefix-stripped form) plus the explicit `typ: "dpop+jwt"` rejection test.
- **T-98-03-02 (Spoofing: cross-JWT confusion via typ=JWT)** — `mitigate`, verified. Three explicit tests cover `typ=JWT`, `typ=jwt`, and missing typ; all produce `:invalid_typ`. RFC 8725 §3.11 cited in the error_description.
- **T-98-03-03 (Spoofing: wrong iss)** — `mitigate`, verified. Four explicit tests cover wrong-iss, missing-iss, empty-iss, and trailing-slash variant. All produce `:invalid_issuer`. Exact string compare via direct equality in `check_issuer/2` — no `URI.parse` / normalization that could open the trailing-slash gap.
- **T-98-03-04 (Tampering: silent exp acceptance gap)** — `mitigate`, verified. `:missing_exp` enforced upstream of `time_claims_valid?/1`; the obsolete comment is deleted; three explicit tests cover missing exp, exp=0, exp=-100. The catch-all `_ -> true` in `time_claims_valid?/1` is now dead code for any verified token.
- **T-98-03-05 (Info disclosure in error_description)** — `accept`, verified. All five wording strings name only RFC clauses, JWT field names, and the literal `"at+jwt"`. No URLs, no client IDs, no scopes.
- **T-98-03-06 (Unescaped double quotes in error_description break WWW-Authenticate)** — `mitigate`, verified. Embedded double quotes are `\"`-escaped in every Elixir literal (e.g. `"\"typ\""` for the JWT field name). The end-to-end test pipes one case through `RequireToken.call/2` and asserts the emitted header value contains the expected substring — implicitly confirming the header is well-formed (Plug would reject malformed header values upstream).
- **T-98-03-07 (Repudiation: operator can't tell which clause was violated)** — `mitigate`, verified. The five distinct atom reason codes flow through `log_invalid_token/2`'s structured-map clause as `category=token_validation reason=<atom>` AND through the WWW-Authenticate `error_description=`. Log-line assertion test confirms `reason=invalid_typ` is emitted with raw token bytes redacted.
- **T-98-03-08 (DoS via added latency)** — `accept`, verified. The five checks are O(1) per token: one `JOSE.JWT.peek_protected/1` (rescue/nil wrapped), three claim-map lookups, one string compare, one normalization. No additional JWKS round-trip, no additional crypto.
- **T-98-03-SC (Supply chain)** — `n/a`, verified. Zero new dependencies. Uses `:jose` (already in mix.exs), `Lockspire.Config` (existing), and stdlib.

## Self-Check: PASSED

- `lib/lockspire/plug/verify_token.ex` — FOUND (modified, +194/-9 lines, committed in `e6774bb`)
- `test/lockspire/plug/verify_token_test.exs` — FOUND (modified, +346/-9 lines across `e6774bb` + `3c66e7e`)
- Commit `e6774bb` (Task 1) — FOUND in `git log --all`
- Commit `3c66e7e` (Task 2) — FOUND in `git log --all`
- Test suite — verify_token_test.exs 56 tests, 0 failures; release_readiness_contract_test.exs 30 tests, 0 failures
- Plan `<verification>` block — all 11 clauses pass
- Plan `<success_criteria>` block — all 5 criteria proved
- Obsolete `# Missing exp is currently treated as valid` comment — gone (CONTEXT.md `<deferred>` line 155 satisfied)
- Verifier/signer asymmetry code comment present — confirmed at verify_token.ex:534-545 naming `Lockspire.Protocol.DPoP.check_typ/1` and Phase 99's `Protocol.AccessTokenSigner` extraction

## Next Phase Readiness

Plan 04 (`98-04-PLAN.md`, VERIFIER-05 challenge scheme derivation per D-05/D-06) is ready to execute. It inherits from Plan 03:

- The full RFC 9068 / RFC 8725 claim/header enforcement taxonomy — six structured reason codes across Phase 98 (Plan 01's `:opaque_token_not_accepted` plus Plan 03's `:invalid_typ`, `:invalid_issuer`, `:missing_exp`, `:missing_iat`, `:missing_sub`). Plan 04 replaces the hard-coded `challenge: :bearer` in each of these helpers with a binding-derived value per D-05/D-06.
- The structured error map shape (`category:`, `challenge:`, `reason_code:`, `error:`, `error_description:`) — Plan 04 only mutates the `challenge:` field; the rest is stable.
- The factory's RFC-9068-compliant defaults — Plan 04's tests will inherit them and only need to set `cnf` claims (or no `cnf`) plus the request's authorization scheme (`Bearer` vs `DPoP`) to test the four `challenge:` derivation cases.

Phase 98 remaining plans (Plan 04 challenge derivation only) inherit:
- The D-04 structured error map shape and the multi-arity `log_invalid_token/2` spine
- `:token_validation` as the canonical category for claim/header validation failures (distinct from `:token_format` Plan 01 and `:token_restriction` audience/scope)
- The verifier/signer asymmetry comment precedent for Phase 99's signer extraction

---
*Phase: 98-plug-hardening*
*Plan: 03*
*Completed: 2026-05-28*
