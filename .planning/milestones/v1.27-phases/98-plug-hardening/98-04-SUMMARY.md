---
phase: 98-plug-hardening
plan: 04
subsystem: auth
tags: [oauth, oidc, jwt, rfc-6750, rfc-9068, rfc-9449, rfc-8705, plug, verify_token, require_token, challenge-derivation, lockspire]

# Dependency graph
requires:
  - phase: 97-contract-docs-first
    provides: Canonical pipeline declaration and supported-surface non-goals pinned across four docs sites
  - phase: 98-plug-hardening
    plan: 01
    provides: opaque_token_error helper (now widened to /1 accepting derived challenge) + D-04 structured error map shape
  - phase: 98-plug-hardening
    plan: 02
    provides: enforce_audience: option (no overlap with Plan 04 runtime)
  - phase: 98-plug-hardening
    plan: 03
    provides: validate_rfc9068_compliance and the five rfc9068_error helpers (now widened to /2 accepting derived challenge) + extended test factory supporting cnf overrides and DPoP authorization scheme
provides:
  - New private function `challenge_for/2` in `Lockspire.Plug.VerifyToken` implementing the D-05 four-row mapping (cnf.jkt → :dpop; cnf.x5t#S256-only → :bearer; no-cnf + DPoP scheme → :dpop; otherwise → :bearer)
  - Widened error helper signatures so every VerifyToken-produced structured error map carries a binding-derived `challenge:` instead of a hard-coded `:bearer`: `opaque_token_error/1`, `invalid_audience_error/3`, `insufficient_scope_error/2`, `rfc9068_error/2` (all five reason-code clauses)
  - `authorization_scheme` threaded through `verify_signature_and_claims/3` → `validate_rfc9068_compliance/3` → each `check_*/2` helper so the RFC 9068 error paths derive challenge via `challenge_for/2`
  - `apply_restrictions/2` reads `authorization_scheme` from the in-flight AccessToken struct and threads it into `validate_audience/3` and `validate_scopes/3` so audience/scope failures derive challenge via `challenge_for/2`
  - `require_token.ex` `normalize_insufficient_scope_error/1` honors any explicitly-set `:challenge` from the upstream structured map (`Map.get(error, :challenge, :bearer)`) instead of hard-coding `:bearer`; also passes through `:dpop_nonce` for defensive symmetry with `normalize_sender_error/1`
  - `require_token.ex` `handle_insufficient_scope/2` mirrors `handle_invalid_token/2`'s challenge-aware routing: when `challenge: :dpop`, emits `WWW-Authenticate: DPoP realm="..." error="insufficient_scope" ... algs="..."` via `ProtectedResourceChallenge.put_dpop_challenge/2` (status remains 403 per RFC 6750 §3.1)
  - 12 new tests in `verify_token_test.exs` (new describe block "VerifyToken plug -- challenge derivation from binding (D-05, D-06)") covering all four D-05 mapping rows, dpop+mtls combined binding, Plan 01 opaque + each scheme, Plan 03 RFC 9068 errors with cnf, legacy bare-atom regression, and AccessToken.error direct-shape assertions
  - 3 new tests in `require_token_test.exs` covering Task 2's normalize + route changes (DPoP-scope routing, explicit-bearer regression, no-challenge-key back-compat)
affects: [99-signer-extraction, 100-sender-constraint-e2e, 101-adoption-demo-rewire, 102-generated-host-scaffolding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "challenge derivation (challenge_for/2) is a sibling of binding_type/1 but distinct in return type (:bearer | :dpop atoms vs string taxonomy). The two helpers cover sibling concerns but feed different downstream consumers — binding_type → AccessToken.binding_type for EnforceSenderConstraints; challenge_for → structured error map :challenge for WWW-Authenticate scheme letter"
    - "authorization_scheme threaded down through verify_signature_and_claims → validate_rfc9068_compliance → check_*/2 helpers rather than re-reading from conn at each error site. Single derivation point per request: challenge_for/2 is called once per error-emitting code path"
    - "apply_restrictions/2 reads authorization_scheme from the in-flight access_token struct rather than gaining a new arg — keeps function arity stable while still routing the request scheme through to validate_audience/3 and validate_scopes/3 for the cnf-less tiebreaker path"
    - "handle_insufficient_scope/2 mirrors handle_invalid_token/2's case/challenge dispatch shape — both 401 and 403 paths now consistently route DPoP-shaped failures through ProtectedResourceChallenge.put_dpop_challenge/2"

key-files:
  created: []
  modified:
    - lib/lockspire/plug/verify_token.ex
    - lib/lockspire/plug/require_token.ex
    - test/lockspire/plug/verify_token_test.exs
    - test/lockspire/plug/require_token_test.exs

key-decisions:
  - "Helper named `challenge_for/2` taking `(claims_or_nil, authorization_scheme)` returning `:bearer | :dpop`. Placed adjacent to `binding_type/1` so the relationship between the two (sibling helpers operating on the same `cnf` claim) is obvious. Distinct return type from binding_type/1 because the downstream consumers want different taxonomies — binding_type's string output feeds EnforceSenderConstraints' binding-shape dispatch; challenge_for's atom output feeds the WWW-Authenticate emission path"
  - "DPoP-wins over mTLS in dpop+mtls combined-binding tokens (`has_dpop? -> :dpop`, no precedence check needed) per RFC 9449 §7.1 — the DPoP scheme is the stronger protocol indicator. Test 5 covers this. Empty `cnf` (`%{}` with no jkt or x5t#S256) falls through to the request-scheme tiebreaker (D-05 row 3/4 behavior)"
  - "Authorization scheme threaded through verify_signature_and_claims/3 → validate_rfc9068_compliance/3 → check_*/2 rather than re-reading it at each error site. validate_rfc9068_compliance/3 computes `challenge = challenge_for(claims, authorization_scheme)` once, then passes the same value into all five rfc9068_error/2 calls. This is one derivation per error-emitting path, not per error helper"
  - "apply_restrictions/2 reads `access_token.authorization_scheme` from the in-flight struct (set on the success branch at do_verify_token/3:120) rather than gaining an authorization_scheme arg. Keeps the function arity stable and avoids threading-the-rest-of-the-pipeline pattern bloat. validate_audience/3 and validate_scopes/3 each take the scheme as an explicit arg so they don't need to know the AccessToken struct shape"
  - "opaque_token_error widened from /0 to /1 taking the challenge explicitly — the front-edge verify_token/3 site computes `challenge_for(nil, authorization_scheme)` and passes it in. This makes opaque tokens with `Authorization: DPoP` get `challenge: :dpop` per D-05 row 3 (request-scheme tiebreaker, no cnf to derive from). The previous default-arg form (`challenge \\\\ :bearer`) was removed after compile-warning that the default was never used (every call site now explicit)"
  - "require_token.ex line 113 was `challenge: :bearer,` hard-coded — replaced with `challenge: Map.get(error, :challenge, :bearer),` (same precedent as normalize_invalid_error/1 line 99 and normalize_sender_error/1 line 81). Also added `dpop_nonce: Map.get(error, :dpop_nonce)` for defensive symmetry with normalize_sender_error/1 (VerifyToken doesn't currently set :dpop_nonce on insufficient_scope paths, but the wire-up is uniform now)"
  - "handle_insufficient_scope/2 restructured to mirror handle_invalid_token/2's case-on-challenge shape — both 401 and 403 paths route DPoP-bound failures through ProtectedResourceChallenge.put_dpop_challenge/2. The 403 status from RFC 6750 §3.1 is preserved because put_dpop_challenge/2 only sets headers; send_json/3 below sets the 403 status"
  - "default_invalid_error/0 in require_token.ex was deliberately left as `challenge: :bearer,` per Plan 04 done criterion and CONTEXT.md D-06 — this helper only fires on bare-atom errors (`:no_kid`, `:malformed`, `:invalid_signature`, `:verification_crashed`, `:invalid_time_claims`) where no binding can be derived. The value-add of deriving challenge for legacy atom errors is marginal; left as-is for least-surprise"

patterns-established:
  - "Whenever a new error-emitting helper is added in VerifyToken, the helper takes `challenge` as a parameter (not a hard-coded literal) and the caller derives it via challenge_for/2 from the in-flight (claims, authorization_scheme) pair. This is the precedent for any future VerifyToken error reason codes"
  - "Whenever a new structured-error category is introduced in require_token.ex, the normalizer reads `Map.get(error, :challenge, :bearer)` (not a hard-coded literal) and the handler that consumes the normalized map case-dispatches on `%{challenge: :dpop}` vs default to route through ProtectedResourceChallenge.put_dpop_challenge/2 or the Bearer www_authenticate path"
  - "The four-row D-05 mapping table now lives in a code comment block above challenge_for/2 (verify_token.ex:478-499) with explicit RFC references (9449 §7.1, 8705 §3). Future maintainers reading the implementation see the protocol contract before the case clauses"

requirements-completed: [VERIFIER-05]

# Metrics
duration: ~7min
completed: 2026-05-27
---

# Phase 98 Plan 04: Binding-Derived Challenge Wire-Up (D-05 / D-06) Summary

**Add `challenge_for/2` to `Lockspire.Plug.VerifyToken` implementing the D-05 four-row mapping (cnf.jkt → :dpop, cnf.x5t#S256-only → :bearer, no-cnf + DPoP scheme → :dpop, otherwise → :bearer); replace the four hard-coded `challenge: :bearer` sites in error helpers (`invalid_audience_error/3`, `insufficient_scope_error/2`, `rfc9068_error/2` × 5 clauses, `opaque_token_error/1`) with derived values that thread through `verify_signature_and_claims/3` → `validate_rfc9068_compliance/3` → check helpers, plus `apply_restrictions/2` reading the scheme off the in-flight AccessToken struct; replace the hard-coded `challenge: :bearer` in `require_token.ex` `normalize_insufficient_scope_error/1` at line 113 with `Map.get(error, :challenge, :bearer)`; restructure `handle_insufficient_scope/2` to mirror `handle_invalid_token/2`'s challenge-aware routing so DPoP-bound scope failures emit `WWW-Authenticate: DPoP realm="..." error="insufficient_scope" ... algs="..."` via the existing `ProtectedResourceChallenge.put_dpop_challenge/2` (D-06 wire-up — no changes to that file). EnforceSenderConstraints is NOT modified.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-05-27T22:05Z
- **Completed:** 2026-05-27T22:12Z
- **Tasks:** 3 (all `type="auto" tdd="true"`)
- **Files modified:** 4
- **Tests:** test/lockspire/plug/ — 89 tests, 0 failures (was 74 before Plan 04: 56 verify + 9 require + 9 enforce; now 71 verify + 12 require + 9 enforce — 12 new verify + 3 new require tests added)
- **Release contract test:** test/lockspire/release_readiness_contract_test.exs — 30 tests, 0 failures (unchanged)

## Accomplishments

- Added `challenge_for/2` private function at `verify_token.ex:501-518` implementing the D-05 four-row mapping. Sibling of `binding_type/1` at lines 482-493 (adjacent placement makes the relationship obvious). Distinct return type (`:bearer | :dpop` atoms) from `binding_type/1` (string taxonomy) because the downstream consumers want different shapes.
- Added `challenge_from_scheme/1` helper (verify_token.ex:517-518) for the no-cnf request-scheme tiebreaker path (D-05 rows 3/4).
- Widened `opaque_token_error/0` → `opaque_token_error/1` (verify_token.ex:175); call site in `verify_token/3` now passes `challenge_for(nil, authorization_scheme)` so opaque tokens with `Authorization: DPoP` get `challenge: :dpop` per D-05 row 3.
- Widened `invalid_audience_error/2` → `/3` (verify_token.ex:286); call sites in `validate_audience/3` now pass `challenge_for(claims, authorization_scheme)`.
- Widened `insufficient_scope_error/1` → `/2` (verify_token.ex:355); call site in `validate_scopes/3` now passes `challenge_for(claims, authorization_scheme)`.
- Widened `rfc9068_error/1` → `/2` (verify_token.ex:303-352, all five clauses); call sites in `check_at_jwt_typ/2`, `check_issuer/3`, `check_exp_positive_integer/2`, `check_iat_positive_integer/2`, `check_sub_non_empty_string/2` now pass `challenge` derived once at `validate_rfc9068_compliance/3` entry (verify_token.ex:626).
- Threaded `authorization_scheme` through `verify_signature_and_claims/2` → `/3` (verify_token.ex:534) and `validate_rfc9068_compliance/2` → `/3` (verify_token.ex:620) so the five RFC 9068 reason codes can derive challenge.
- `apply_restrictions/2` reads `access_token.authorization_scheme` from the in-flight struct (verify_token.ex:188) and threads it into `validate_audience/3` and `validate_scopes/3`. Function arity stays stable; the AccessToken struct is the single source of truth for the request scheme on the success-then-restriction path.
- Replaced `require_token.ex:113` `challenge: :bearer,` with `challenge: Map.get(error, :challenge, :bearer),` in `normalize_insufficient_scope_error/1` per D-06 wire-up.
- Added `dpop_nonce: Map.get(error, :dpop_nonce)` pass-through to `normalize_insufficient_scope_error/1` for defensive symmetry with `normalize_sender_error/1` (require_token.ex:138-142).
- Restructured `handle_insufficient_scope/2` (require_token.ex:63-82) to mirror `handle_invalid_token/2`'s `case/%{challenge: :dpop}` dispatch shape: DPoP-bound scope failures route through `ProtectedResourceChallenge.put_dpop_challenge/2`; the 403 status from RFC 6750 §3.1 is preserved because `put_dpop_challenge/2` only sets headers.
- Added 12 new tests in `verify_token_test.exs` under a new describe block "VerifyToken plug -- challenge derivation from binding (D-05, D-06)" covering all four D-05 mapping rows plus combined dpop+mtls, opaque + each scheme (D-05 row 3 for opaque), legacy bare-atom regression, and direct-shape AccessToken.error assertions.
- Added 3 new tests in `require_token_test.exs` covering Task 2's changes: DPoP-bound insufficient_scope → 403 + DPoP header; explicit-bearer regression; no-`:challenge`-key default to `:bearer` (back-compat).
- Confirmed all existing tests continue to pass: every existing test sends tokens with no `cnf` claim over `Bearer`, which matches D-05 row 4's default `:bearer`, preserving back-compat across the entire test suite.
- Confirmed `EnforceSenderConstraints` was NOT modified (Phase 98 wire-up scope per Plan 04 `<truths>` line 8) — its existing `sender_error/2` path continues to emit `challenge: :dpop` unchanged.

## Task Commits

Each task was committed atomically:

1. **Task 1: Derive challenge: from cnf binding in VerifyToken (D-05/D-06)** — `3b46f2e` (feat) — `lib/lockspire/plug/verify_token.ex` (+129/-51)
2. **Task 2: Honor binding-derived challenge: in insufficient-scope path** — `fea8526` (feat) — `lib/lockspire/plug/require_token.ex` (+29/-3)
3. **Task 3: Cover D-05/D-06 binding-derived challenge across plugs** — `ba36723` (test) — both test files (+290/-0)

_Note: This plan follows the same plan-granularity TDD pattern as Plans 01, 02, 03. Each task's `<verify>` block is the RED/GREEN gate; per-task implementation-then-tests sequencing is honored by writing tests, watching them fail, implementing, watching them pass, then committing. Tasks 1 and 2 are implementation; Task 3 is the dedicated tests-only commit covering both modules' new behavior plus regression coverage._

## Required Output Fields (from `<output>`)

### Name and arity of the challenge-derivation helper

`challenge_for/2` — takes `(claims_map_or_nil, authorization_scheme_string_or_nil)` and returns `:bearer | :dpop`. Located at `lib/lockspire/plug/verify_token.ex:501` (the `cnf`-matching head) and `:514` (the no-cnf catch-all head).

### Four D-05 mapping rows confirmed via test names

Each test name from `verify_token_test.exs` maps to a D-05 row:

| D-05 Row | Test Name | Expected challenge |
|---|---|---|
| Row 1 (cnf.jkt) | `DPoP-bound token (cnf.jkt) failing audience emits challenge: :dpop and DPoP WWW-Authenticate` | `:dpop` |
| Row 1 (dpop+mtls combined, DPoP wins) | `dpop+mtls combined token (both cnf claims) failing audience emits DPoP (DPoP wins per D-05 row 1)` | `:dpop` |
| Row 2 (cnf.x5t#S256 only) | `mTLS-bound token (cnf.x5t#S256 only) failing audience emits challenge: :bearer (RFC 8705 §3)` | `:bearer` |
| Row 3 (no-cnf + DPoP scheme) | `no-cnf token, request used Authorization: DPoP, audience failure emits DPoP (D-05 row 3 tiebreaker)` | `:dpop` |
| Row 4 (no-cnf + Bearer scheme / default) | `no-cnf token, request used Authorization: Bearer, audience failure emits Bearer (D-05 row 4 default)` | `:bearer` |

Additional coverage outside the four canonical rows:
- DPoP-bound + scope failure (Row 1, 403 path) — `DPoP-bound token (cnf.jkt) failing scope emits 403 with DPoP WWW-Authenticate`
- DPoP-bound + RFC 9068 typ failure (Row 1, RFC 9068 path) — `DPoP-bound token failing RFC 9068 typ check emits DPoP WWW-Authenticate`
- No-cnf + Bearer + missing_exp (Row 4, RFC 9068 path) — `no-cnf token, Bearer scheme, RFC 9068 missing_exp emits Bearer`
- Plan 01 opaque + DPoP scheme (Row 3 for the opaque path) — `Plan 01 opaque token presented as Authorization: DPoP emits DPoP (request-scheme tiebreaker)`
- Plan 01 opaque + Bearer scheme (Row 4 for the opaque path) — `Plan 01 opaque token presented as Authorization: Bearer emits Bearer (regression)`
- Legacy bare-atom regression — `REGRESSION: legacy bare-atom error path (unknown kid) emits Bearer (default_invalid_error/0)`
- Direct AccessToken.error shape — `AccessToken.error on DPoP-bound audience failure carries challenge: :dpop directly` and `... mTLS-bound ... carries challenge: :bearer directly`

### Exact line of require_token.ex where the hard-coded :bearer was replaced

`lib/lockspire/plug/require_token.ex:130` — inside `normalize_insufficient_scope_error/1`. Before:

```
challenge: :bearer,
```

After:

```
challenge: Map.get(error, :challenge, :bearer),
```

The remaining `challenge: :bearer,` at `require_token.ex:107` is in `default_invalid_error/0` (the bare-atom-error path) and is intentionally preserved per Plan 04 done criterion and CONTEXT.md D-06 wire-up scope — that path has no parsed claims to derive a binding from, and the value-add of deriving challenge for legacy atom errors is marginal.

### Confirmation EnforceSenderConstraints was NOT modified

CONFIRMED. `git diff --name-only 75caa27..HEAD` shows only these four files changed in this plan:
```
lib/lockspire/plug/require_token.ex
lib/lockspire/plug/verify_token.ex
test/lockspire/plug/require_token_test.exs
test/lockspire/plug/verify_token_test.exs
```

`lib/lockspire/plug/enforce_sender_constraints.ex` is untouched. Its existing `sender_error/2` path (per CONTEXT.md `<code_context>` lines 130-149) continues to emit `challenge: :dpop` for DPoP-bound sender failures, converging with VerifyToken's new derivation on the same taxonomy.

### Short-form trace: DPoP-bound audience failure end-to-end

Token: signed `at+jwt` with `aud: "wrong-audience"` and `cnf: {"jkt": "proof-thumbprint"}`. Route mount: `plug Lockspire.Plug.VerifyToken, audience: "expected-audience"` then `plug Lockspire.Plug.RequireToken`.

1. **`verify_token/3` (verify_token.ex:91-114)** — token has JWT shape, falls through to `do_verify_token/3`.
2. **`verify_signature_and_claims/3` (verify_token.ex:534)** — JWT signature verifies; `claims` map contains `cnf: %{"jkt" => "proof-thumbprint"}` and `aud: "wrong-audience"`.
3. **`validate_rfc9068_compliance/3` (verify_token.ex:620-630)** — passes (typ=at+jwt, iss/sub/exp/iat all valid from factory defaults). Returns `{:ok, claims}`.
4. **`time_claims_valid?/1`** — passes. Returns `{:ok, claims}`.
5. **`do_verify_token/3` success branch** — builds `%AccessToken{authorization_scheme: "Bearer", claims: %{...}, ...}`, calls `apply_restrictions/2`.
6. **`apply_restrictions/2` (verify_token.ex:181-194)** — reads `authorization_scheme = access_token.authorization_scheme` (= "Bearer"), calls `validate_audience(claims, opts, "Bearer")`.
7. **`validate_audience/3` (verify_token.ex:196-223)** — `expected_audiences = ["expected-audience"]`, token aud = "wrong-audience", no intersection. Calls `invalid_audience_error(:invalid_audience, ["expected-audience"], challenge_for(claims, "Bearer"))`.
8. **`challenge_for/2` (verify_token.ex:501-512)** — claims has `cnf: %{"jkt" => "proof-thumbprint"}`, so `has_dpop? = true` and returns `:dpop` (D-05 row 1).
9. **`invalid_audience_error/3` (verify_token.ex:286-295)** — returns `%{category: :token_restriction, challenge: :dpop, reason_code: :invalid_audience, error: "invalid_token", error_description: "...", required_audiences: [...]}`.
10. **`apply_restrictions/2` error branch** — logs the failure, returns `%AccessToken{... error: <map with challenge: :dpop>}`.
11. **`VerifyToken.call/2`** — assigns the AccessToken to `conn.assigns[:access_token]`.
12. **`RequireToken.call/2` (require_token.ex:18-34)** — matches `%AccessToken{error: error} when is_map(error)`, calls `handle_structured_error(conn, error)`.
13. **`handle_structured_error/2` (require_token.ex:88-93)** — `category: :token_restriction` falls through to the third clause (not `:sender_constraint`, not `:insufficient_scope`), calls `handle_invalid_token(conn, normalize_invalid_error(error))`.
14. **`normalize_invalid_error/1` (require_token.ex:113-120)** — `challenge: Map.get(error, :challenge, :bearer)` → `:dpop` (the value flows through unchanged).
15. **`handle_invalid_token/2` (require_token.ex:48-61)** — matches `%{challenge: :dpop}`, calls `ProtectedResourceChallenge.put_dpop_challenge(conn, error, realm: "Lockspire")`.
16. **`ProtectedResourceChallenge.put_dpop_challenge/2` (protected_resource_challenge.ex:37-44)** — sets `WWW-Authenticate: DPoP realm="Lockspire", error="invalid_token", error_description="The access token audience is invalid for this route", algs="RS256 ES256 PS256 EdDSA"` via `www_authenticate_value/3` clause at protected_resource_challenge.ex:57-64.
17. **Response** — 401 + the DPoP `WWW-Authenticate` header.

The challenge value flows: VerifyToken derivation → AccessToken.error map → RequireToken normalizer pass-through → handle_invalid_token DPoP dispatch → put_dpop_challenge → header. The `challenge: :dpop` atom survives end-to-end with no transformations.

## Decisions Made

- **Helper named `challenge_for/2` taking `(claims, authorization_scheme)`** — the plan allowed executor discretion on the name; `challenge_for/2` reads naturally at the call site (`challenge_for(claims, authorization_scheme)`) and the suffix matches the existing `binding_type/1` precedent for "small focused helper that classifies a single concept". Placed adjacent to `binding_type/1` because both helpers operate on the same `cnf` claim and the relationship should be visually obvious.

- **DPoP wins over mTLS in dpop+mtls combined-binding tokens** — `has_dpop? -> :dpop` clause comes before `has_mtls?` clause in the `cond`, so when both bindings are present, DPoP wins per RFC 9449 §7.1 ("[w]hen both DPoP and mutual-TLS sender constraints are in use, DPoP MUST take precedence"). Test 5 explicitly covers this.

- **Authorization scheme threaded through verify_signature_and_claims/3 → validate_rfc9068_compliance/3 → check_*/2** — alternative would be re-reading the scheme from the conn at each error site (the conn isn't in scope inside verify_signature_and_claims, so this would require additional plumbing). Threading scheme as a function arg through the existing `with` pipeline is the minimal change. `validate_rfc9068_compliance/3` computes `challenge = challenge_for(claims, authorization_scheme)` ONCE at its top (line 626) and passes the same value into all five check helpers — one derivation per error-emitting code path.

- **apply_restrictions/2 reads authorization_scheme from the in-flight access_token struct** — the plan suggested either threading the scheme as a new arg or reading it from the struct; the struct-read approach keeps apply_restrictions/2's arity at /2 and avoids cascading the threading pattern. validate_audience/3 and validate_scopes/3 each take the scheme as an explicit arg so they don't need to know the AccessToken struct shape (they were already pure-claims-and-opts functions; adding a scheme arg keeps that purity).

- **opaque_token_error widened from /0 to /1 (no default arg)** — initially used `defp opaque_token_error(challenge \\\\ :bearer)` to preserve the zero-arity call site, but the compiler warned "default values for the optional arguments in the private function opaque_token_error/1 are never used" because every call site now passes an explicit challenge. Removed the default to keep the warnings-as-errors discipline (per `prompts/` corpus). All call sites pass `challenge_for(nil, authorization_scheme)` explicitly.

- **require_token.ex `normalize_insufficient_scope_error/1` line 113 fix is the minimum behavior change** — the plan also noted Step 2 ("make `handle_insufficient_scope/2` honor `challenge: :dpop`") because the normalizer fix alone wouldn't route DPoP through the right emission path. Both changes ship together: normalizer accepts the upstream `:challenge` value AND the handler dispatches on it.

- **default_invalid_error/0 in require_token.ex was deliberately left as `challenge: :bearer,`** — per Plan 04 done criterion and CONTEXT.md D-06 wire-up scope. This helper only fires on bare-atom errors (`:no_kid`, `:malformed`, `:invalid_signature`, `:verification_crashed`, `:invalid_time_claims`) where no binding can be derived. The plan explicitly allowed this to remain.

- **Added dpop_nonce pass-through to normalize_insufficient_scope_error/1** — defensive symmetry with normalize_sender_error/1 (which has `dpop_nonce: Map.get(error, :dpop_nonce)` at line 85). VerifyToken's insufficient_scope path doesn't currently set :dpop_nonce, but the wire-up is uniform now. Zero behavior change for the existing tests because they don't set :dpop_nonce on insufficient_scope errors.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Test assertion expected wrong `error=` value on DPoP insufficient_scope header**

- **Found during:** Task 3 verify run (`mix test test/lockspire/plug/`)
- **Issue:** My new test `halts with 403 and DPoP WWW-Authenticate when insufficient_scope error carries challenge: :dpop (D-05/D-06)` in `require_token_test.exs` initially asserted `challenge =~ ~s(error="invalid_token")`. But `ProtectedResourceChallenge.www_authenticate_value/3` clause at protected_resource_challenge.ex:57-64 uses the upstream error's `:error` field directly (`%{challenge: :dpop, error: error}`), so when the structured error has `error: "insufficient_scope"`, the emitted header has `error="insufficient_scope"`, not `"invalid_token"`. The actual emitted value: `DPoP realm="Lockspire", error="insufficient_scope", error_description="...", algs="RS256 ES256 PS256 EdDSA"`. RFC 6750 §3.1 specifies `error="insufficient_scope"` for the 403 case, so this is correct behavior — my test's assertion was wrong.
- **Fix:** Updated assertion from `error="invalid_token"` to `error="insufficient_scope"` to match the correct downstream emission (which is RFC-6750-compliant).
- **Files modified:** `test/lockspire/plug/require_token_test.exs` (single-line assertion fix)
- **Commit:** `ba36723` (Task 3)

---

**Total deviations:** 1 auto-fixed (Rule 1 — wrong test assertion, code behavior is correct)
**Impact on plan:** Zero scope creep. The fix is to a test assertion I wrote during Task 3; the underlying code from Tasks 1+2 emits the RFC-compliant header value. The lesson: when piping insufficient_scope through put_dpop_challenge/2, the WWW-Authenticate carries `error="insufficient_scope"` because that's what the error map's `:error` field is set to.

## Issues Encountered

One compiler warning during Task 1: `default values for the optional arguments in the private function opaque_token_error/1 are never used`. Initially used `defp opaque_token_error(challenge \\\\ :bearer)` to make the helper backward-compatible with the prior zero-arity form, but every call site now passes the challenge explicitly. Removed the default to keep the compile clean.

One initial test failure in Task 3: my require_token_test.exs assertion expected `error="invalid_token"` on the DPoP insufficient_scope header, but the actual emission is `error="insufficient_scope"` (RFC-compliant — the structured error's :error field flows through unchanged). Test assertion fixed in the same Task 3 commit.

No other JOSE / Plug / Phoenix friction.

## Verification Evidence

Plan-level `<verification>` block results (all clauses pass):

| Clause | Expected | Actual |
|---|---|---|
| `mix test test/lockspire/plug/` | exits 0 | 89 tests, 0 failures |
| `mix test test/lockspire/release_readiness_contract_test.exs` | exits 0 | 30 tests, 0 failures |
| `grep -c "challenge_for" lib/lockspire/plug/verify_token.ex` | ≥ 4 | 9 (definition split + 8 call/comment sites) |
| `grep -n "challenge: :bearer" lib/lockspire/plug/verify_token.ex` (zero non-comment matches) | 0 non-comment | 1 match total, on line 101 inside a comment |
| `grep -n "challenge: :bearer" lib/lockspire/plug/require_token.ex` (≤ 1 match in default_invalid_error/0) | 1 | 1 (line 107, default_invalid_error/0) |
| WWW-Authenticate scheme varies between DPoP and Bearer across D-05 rows, asserted in Task 3 Tests 1-7 | yes | confirmed by all 12 new verify_token_test cases |
| DPoP-bound + insufficient-scope emits 403 with WWW-Authenticate: DPoP ... | yes | confirmed by Test 2 in verify_token_test.exs and the dedicated test in require_token_test.exs |

Plan-level `<success_criteria>` results (all five satisfied):

1. **Phase 98 Success Criterion #3 — DPoP-bound at+jwt failing audience/scope gets WWW-Authenticate: DPoP with algs=** — PROVEN by the end-to-end tests "DPoP-bound token (cnf.jkt) failing audience emits challenge: :dpop and DPoP WWW-Authenticate" and "DPoP-bound token (cnf.jkt) failing scope emits 403 with DPoP WWW-Authenticate", which both assert the header starts with `DPoP realm="Lockspire"` and contains `algs=`.
2. **RFC 8705 §3 — mTLS-bound at+jwt gets WWW-Authenticate: Bearer** — PROVEN by "mTLS-bound token (cnf.x5t#S256 only) failing audience emits challenge: :bearer (RFC 8705 §3)".
3. **D-05 row 3 — misconfigured client with Authorization: DPoP + no cnf gets DPoP scheme** — PROVEN by "no-cnf token, request used Authorization: DPoP, audience failure emits DPoP (D-05 row 3 tiebreaker)" and "Plan 01 opaque token presented as Authorization: DPoP emits DPoP (request-scheme tiebreaker)".
4. **Four hard-coded `challenge: :bearer` sites in verify_token.ex replaced; one in require_token.ex replaced** — CONFIRMED by `grep -n "challenge: :bearer" lib/lockspire/plug/verify_token.ex` (only one match remains, in a comment) and `grep -n "challenge: :bearer" lib/lockspire/plug/require_token.ex` (only the default_invalid_error/0 site remains, intentionally preserved).
5. **Downstream emission path (ProtectedResourceChallenge.put_dpop_challenge/2) unchanged — D-06 wire-up only** — CONFIRMED by `git diff --name-only 75caa27..HEAD | grep protected_resource_challenge.ex` returning no matches.

## Threat Flags

None new. The plan's `<threat_model>` captured all surface introduced by this change:

- **T-98-04-01 (Info disclosure: DPoP-scheme tiebreaker leaks binding info)** — `accept`, verified. The scheme letter only reflects what the request chose, not what the underlying token actually IS bound to. No new oracle is created.
- **T-98-04-02 (Spoofing: mTLS-bound token via Authorization: DPoP)** — `mitigate`, verified. `challenge_for/2`'s D-05 row 1 wins over row 3 — `has_dpop? -> :dpop` clause in the `cond` returns immediately when `cnf.jkt` is present, no fall-through to the scheme check. Test "mTLS-bound token (cnf.x5t#S256 only) failing audience emits challenge: :bearer (RFC 8705 §3)" covers the inverse case; Test "dpop+mtls combined token (both cnf claims) failing audience emits DPoP (DPoP wins per D-05 row 1)" covers the combined case.
- **T-98-04-03 (Tampering: fabricated cnf on unsigned/fake JWT)** — `mitigate`, verified. `challenge_for/2` operates on the CLAIMS MAP returned by `JOSE.JWT.verify_strict/3` — i.e., post-signature-verified. Fabricated cnf on an unsigned token never reaches `challenge_for/2`; the signature failure produces a bare `:invalid_signature` atom that flows through `default_invalid_error/0` with the safe `:bearer` default.
- **T-98-04-04 (Info disclosure: DPoP algs= parameter)** — `accept`, verified. Per RFC 9449 §7.1 `algs=` is REQUIRED on the DPoP challenge. The current `ProtectedResourceChallenge.www_authenticate_value/3` at protected_resource_challenge.ex:57-64 emits `algs=` populated by `DPoP.signing_alg_values_supported/1`. Not new in Plan 04.
- **T-98-04-05 (Repudiation: taxonomy inconsistency between VerifyToken and EnforceSenderConstraints)** — `mitigate`, verified. After Plan 04, VerifyToken's `challenge_for/2` derives `:dpop` for the same DPoP-bound claim shape (`cnf.jkt`) that EnforceSenderConstraints' `sender_error/2` already emits `:dpop` for. The two emission paths converge on the same taxonomy.
- **T-98-04-06 (DoS via added latency)** — `accept`, verified. `challenge_for/2` is O(1): at most one map lookup on `cnf` plus one string compare on the scheme. Called only on error paths, so adds no latency to the happy path.
- **T-98-04-SC (Supply chain)** — `n/a`, verified. Zero new dependencies.

## Self-Check: PASSED

- `lib/lockspire/plug/verify_token.ex` — FOUND (modified, +129/-51 lines, committed in `3b46f2e`)
- `lib/lockspire/plug/require_token.ex` — FOUND (modified, +29/-3 lines, committed in `fea8526`)
- `test/lockspire/plug/verify_token_test.exs` — FOUND (modified, +231 lines, committed in `ba36723`)
- `test/lockspire/plug/require_token_test.exs` — FOUND (modified, +59 lines, committed in `ba36723`)
- Commit `3b46f2e` (Task 1) — FOUND in `git log`
- Commit `fea8526` (Task 2) — FOUND in `git log`
- Commit `ba36723` (Task 3) — FOUND in `git log`
- Test suite — test/lockspire/plug/ 89 tests, 0 failures; test/lockspire/release_readiness_contract_test.exs 30 tests, 0 failures
- Plan `<verification>` block — all 7 clauses pass
- Plan `<success_criteria>` block — all 5 criteria proved
- EnforceSenderConstraints NOT modified — confirmed (only the four expected files changed)

## Next Phase Readiness

Plan 04 is the last plan in Phase 98. With Plan 04 complete, Phase 98 (plug-hardening) closes. Phase 99 (signer extraction + JWT-default issuance) is ready to open.

Phase 99 inherits from Phase 98 (across Plans 01-04):
- The D-04 structured error map shape (six reason codes: `:opaque_token_not_accepted`, `:invalid_typ`, `:invalid_issuer`, `:missing_exp`, `:missing_iat`, `:missing_sub`) — Phase 99's signer extraction should produce tokens that pass every one of these checks.
- The verifier/signer asymmetry code comment at verify_token.ex naming `Lockspire.Protocol.DPoP.check_typ/1` and Phase 99's `Protocol.AccessTokenSigner` extraction is the precedent for any future verifier/signer asymmetry.
- The D-05 four-row mapping (challenge derivation) — Phase 99's signer should issue tokens whose verified `cnf` claim shapes match what `challenge_for/2` expects (jkt for DPoP, x5t#S256 for mTLS).
- The single-derivation-point pattern (challenge_for/2 called once per error-emitting code path, threaded through validate_rfc9068_compliance/3) is the precedent for any future derived-value computation in the verifier.

---
*Phase: 98-plug-hardening*
*Plan: 04*
*Completed: 2026-05-27*
