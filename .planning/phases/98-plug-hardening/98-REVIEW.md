---
phase: 98-plug-hardening
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - docs/protect-phoenix-api-routes.md
  - examples/adoption_demo/lib/adoption_demo_web/router.ex
  - lib/lockspire/plug/require_token.ex
  - lib/lockspire/plug/verify_token.ex
  - priv/templates/lockspire.install/router.ex
  - scripts/demo/adoption_smoke.py
  - test/lockspire/plug/require_token_test.exs
  - test/lockspire/plug/verify_token_test.exs
  - test/lockspire/release_readiness_contract_test.exs
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
---

# Phase 98: Code Review Report

**Reviewed:** 2026-05-27
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 98 introduces four substantive changes to the Plug pipeline:

1. **Plan 01 (opaque-token rejection)** — Front-edge structural shape check in `VerifyToken.verify_token/3` short-circuits opaque tokens with `reason_code: :opaque_token_not_accepted` before they reach JOSE.
2. **Plan 02 (D-07 `enforce_audience`)** — New `NimbleOptions` key with `init/1` raise + a release-readiness contract clause asserting a non-empty `audience:` substring across the four RECIPE-01 canonical-pipeline sites.
3. **Plan 03 (RFC 9068 compliance)** — New `validate_rfc9068_compliance/3` step enforcing five RFC 9068 / RFC 8725 rules (`typ=at+jwt`, exact `iss`, positive-integer `exp`/`iat`, non-empty `sub`) with five new structured reason codes.
4. **Plan 04 (D-05/D-06 challenge wire-up)** — `challenge_for/2` + `challenge_from_scheme/1` helpers derive the `WWW-Authenticate` scheme atom from the `cnf` binding (with the request `Authorization` scheme as tiebreaker); `RequireToken` propagates that atom on the 403 insufficient-scope path.

Plan-level coverage is solid and the tests are thorough. The substantive correctness concerns are:

- **One blocker**: the three new RFC 9068 reason-code descriptions (`:invalid_typ`, `:invalid_issuer`, and the three `missing_*` descriptions that use literal `"exp"` / `"iat"` / `"sub"`) contain unescaped double-quote characters that get interpolated directly into the `WWW-Authenticate` quoted-string. The emitted header is structurally malformed per RFC 7235 §2.2 and is observed at the wire on every failure of those five rules, in both the Bearer and DPoP emission paths. Tests assert "description contains the substring 'typ'" rather than asserting a well-formed header, so this slipped through.
- **Several warnings**: case-sensitive `Authorization` scheme matching, an unused `dpop_nonce` field, redundant header-peek calls, and `Config.issuer!/0` re-validating on every request with rescue-swallowed failure mode.

## Critical Issues

### CR-01: Five new RFC 9068 reason-code descriptions emit a malformed WWW-Authenticate header

**File:** `lib/lockspire/plug/verify_token.ex:309-352`
**Issue:** The five `rfc9068_error/2` entries embed literal double-quote characters in `error_description`:

```elixir
error_description:
  "access token JWT header \"typ\" is not \"at+jwt\" per RFC 9068 §2.1 / RFC 8725 §3.11"
# ...
error_description:
  "access token \"iss\" claim does not match expected issuer per RFC 9068 §4"
# ...
error_description: "access token is missing required \"exp\" claim per RFC 9068 §2.2"
error_description: "access token is missing required \"iat\" claim per RFC 9068 §2.2"
error_description: "access token is missing required \"sub\" claim per RFC 9068 §2.2"
```

Those descriptions are interpolated unescaped into the `WWW-Authenticate` quoted-string by two emission paths:

- `lib/lockspire/plug/require_token.ex:157` — `~s(Bearer realm="Lockspire", error="#{error}", error_description="#{description}")`
- `lib/lockspire/web/protected_resource_challenge.ex:63` — `~s(DPoP realm="#{realm}", error="#{error}", error_description="#{description}", algs="#{algorithms}")`

The wire bytes for a `:invalid_typ` failure become:

```
WWW-Authenticate: Bearer realm="Lockspire", error="invalid_token", error_description="access token JWT header "typ" is not "at+jwt" per RFC 9068 §2.1 / RFC 8725 §3.11"
```

Per RFC 7235 §2.2, `quoted-string = DQUOTE *( qdtext / quoted-pair ) DQUOTE` and `qdtext` excludes `DQUOTE`. A standards-compliant parser sees the value terminate at the first unescaped `"` (after `header `), leaving `typ` and the rest as unexpected garbage. Strict clients will report a malformed challenge; lenient clients will surface a truncated description. The DPoP path is affected identically (Phase 98 Plan 04 derives `challenge: :dpop` from `cnf.jkt`, so DPoP-bound tokens failing any of the five rules also emit this malformed header).

Additionally, the `§` character in the descriptions is U+00A7 (multi-byte UTF-8). RFC 9110 §5.5 strongly recommends US-ASCII for field values; some Plug/Cowboy/Bandit middleware will reject non-ASCII bytes in response headers or coerce them.

The existing tests at `test/lockspire/plug/verify_token_test.exs:856-862, 860, 723-732, etc.` only assert `assert www_authenticate =~ "typ"` / `=~ "at+jwt"` / `=~ "exp"`, which trivially passes on the malformed bytes — the broken-quote shape is not asserted against.

**Fix:** Drop the embedded quotes (and ideally the `§` characters) from the descriptions, and/or escape any operator-derived text that flows into the quoted-string. The simplest correct form keeps the regulatory reference but drops the inner quoting:

```elixir
defp rfc9068_error(:invalid_typ, challenge) do
  %{
    category: :token_validation,
    challenge: challenge,
    reason_code: :invalid_typ,
    error: "invalid_token",
    error_description:
      "access token JWT header typ is not at+jwt per RFC 9068 section 2.1 / RFC 8725 section 3.11"
  }
end

defp rfc9068_error(:invalid_issuer, challenge) do
  %{
    category: :token_validation,
    challenge: challenge,
    reason_code: :invalid_issuer,
    error: "invalid_token",
    error_description:
      "access token iss claim does not match expected issuer per RFC 9068 section 4"
  }
end

defp rfc9068_error(:missing_exp, challenge) do
  %{
    category: :token_validation,
    challenge: challenge,
    reason_code: :missing_exp,
    error: "invalid_token",
    error_description: "access token is missing required exp claim per RFC 9068 section 2.2"
  }
end
# ...analogous for :missing_iat, :missing_sub
```

Pair this with a regression test that asserts the emitted `WWW-Authenticate` header has an even count of `"` characters (or parses cleanly as `auth-param = token "=" ( token / quoted-string )`), not just a substring match. Consider also adding a defense at the emission site (`require_token.ex` and `protected_resource_challenge.ex`) that escapes or rejects descriptions containing `"`, `\`, or non-ASCII bytes, so a future structured-error contributor cannot reintroduce the same bug.

## Warnings

### WR-01: Authorization scheme parsing is case-sensitive; RFC 7235 §2.1 requires case-insensitive match

**File:** `lib/lockspire/plug/verify_token.ex:83-89`
**Issue:** `extract_token/1` pattern-matches `"Bearer " <> token` and `"DPoP " <> token` exactly. RFC 7235 §2.1 requires `auth-scheme` to be compared case-insensitively; RFC 6750 §2.1 confirms `"Bearer"` is case-insensitive. A request with `Authorization: bearer abc` or `Authorization: BEARER abc` silently falls into `{:error, :missing_token}`, producing a generic 401 instead of the actual verification path.

This is the gateway helper that also produces the second argument to `challenge_from_scheme/1` (Plan 04). `challenge_from_scheme("DPoP")` is matched literally, so a client legitimately sending `Authorization: dpop ...` against an opaque token gets `:bearer` instead of `:dpop` in the D-05 row-3 tiebreaker, which contradicts the documented "request-scheme tiebreaker" behavior.

Pre-existing on the `"Bearer "` branch, but Phase 98 extends the surface (DPoP branch + the new `challenge_from_scheme/1`), so it is in scope to fix.

**Fix:** Match scheme case-insensitively and normalize the returned scheme token:

```elixir
defp extract_token(conn) do
  with [value | _] <- get_req_header(conn, "authorization"),
       [scheme, token] <- String.split(value, " ", parts: 2) do
    case String.downcase(scheme) do
      "bearer" -> {:ok, "Bearer", String.trim(token)}
      "dpop"   -> {:ok, "DPoP",   String.trim(token)}
      _other   -> {:error, :missing_token}
    end
  else
    _ -> {:error, :missing_token}
  end
end
```

`challenge_from_scheme/1` then receives the canonical `"DPoP"` token and continues to work unchanged. Add a regression test that `Authorization: bearer ...` and `Authorization: DPOP ...` route through the same paths as the canonical forms.

### WR-02: `Config.issuer!/0` is called on every request and a rescue in `verify_signature_and_claims/3` swallows misconfiguration

**File:** `lib/lockspire/plug/verify_token.ex:620-621, 561-586`
**Issue:** `validate_rfc9068_compliance/3` calls `Config.issuer!()` (line 621) inside `verify_signature_and_claims/3`, which is enclosed by a top-level `rescue _ -> {:error, :verification_crashed}` (line 584-585). If a runtime config drift makes the issuer suddenly invalid (e.g. operator clears `:issuer` config), every verification request raises `ArgumentError` inside `Policy.validate_issuer_and_mount_path!/2` → that raise is caught by the rescue → every token gets `:verification_crashed` → `RequireToken` returns `default_invalid_error()` → operators see a generic `invalid_token` 401 with no signal that the resource server is broken.

This is a quality / operability concern: a misconfigured issuer should fail loudly at boot or on the first failed request, not pretend every token is invalid. The legacy code path before Phase 98 did not call `Config.issuer!()` per request, so the new step regressed this.

**Fix:** Either:
1. Memoize the issuer at plug `init/1` time (the simplest fix — issuer is a process-wide constant in practice and `init/1` already runs at compile/router-load time):
   ```elixir
   def init(opts) do
     opts = NimbleOptions.validate!(opts, @options_schema)
     # ... existing checks ...
     Keyword.put(opts, :__expected_issuer__, Config.issuer!())
   end
   ```
   Then read it back in `validate_rfc9068_compliance/3`.
2. Or call `Config.issuer!()` outside the rescue so misconfiguration crashes the request loudly with the real `ArgumentError`.

### WR-03: `peek_typ/1` re-decodes the protected header that `extract_kid/1` already decoded

**File:** `lib/lockspire/plug/verify_token.ex:542-552, 657-663`
**Issue:** `extract_kid/1` calls `JOSE.JWT.peek_protected/1` and `JOSE.JWS.to_map/1` to pull `kid`. `peek_typ/1` (added in Plan 03) repeats the exact same two calls to pull `typ` from the same header bytes. Both helpers rescue all exceptions, so a malformed-header token gets decoded twice and rescued twice. Beyond duplication, the two helpers have subtly different failure semantics — `extract_kid/1` returns `{:error, :malformed}` on rescue, but `peek_typ/1` returns `nil` and lets `check_at_jwt_typ/2` classify as `:invalid_typ`. That means the **same** malformed-header token can produce different reason codes depending on whether the kid is the first violation or the typ is, even though both come from the same `JOSE.JWS.to_map/1` failure.

**Fix:** Return the protected-header map once from `extract_kid/1` (or a new `peek_protected_header/1` helper) and thread it through. Example:

```elixir
defp peek_protected_header(token) do
  protected = JOSE.JWT.peek_protected(token)
  {_alg_map, map} = JOSE.JWS.to_map(protected)
  {:ok, map}
rescue
  _ -> {:error, :malformed}
end
```

Then both the `kid` and `typ` extractors consume `peek_protected_header/1` output. This also lets `check_at_jwt_typ/2` produce a consistent `:malformed` (vs `:invalid_typ`) reason code when the failure is "header is unparseable" rather than "typ is wrong".

### WR-04: `normalize_insufficient_scope_error/1` pulls a `:dpop_nonce` that no upstream caller ever sets

**File:** `lib/lockspire/plug/require_token.ex:122-145`
**Issue:** The function reads `:dpop_nonce` from the upstream error map and propagates it through the structured error. The inline comment explicitly says *"VerifyToken does not currently set dpop_nonce on its insufficient_scope path; this is wire-up for uniformity"*. The only path that would ever populate `:dpop_nonce` on a `403 insufficient_scope` response is one that doesn't exist yet, and the dead branch is invisible to the test suite (none of the insufficient-scope tests pass `dpop_nonce:`).

Speculative "wire-up for uniformity" code is a code smell — it introduces a behavior contract that the rest of the codebase can rely on without any guarantee of correctness, because no test exercises it. If a future caller does set `dpop_nonce` on an insufficient-scope error, the only emission path is `ProtectedResourceChallenge.put_dpop_challenge/2`, which already calls `maybe_put_dpop_nonce/2`. The wire-up in `normalize_insufficient_scope_error/1` is genuinely redundant — the structured error is passed through as-is to `put_dpop_challenge/2`.

**Fix:** Either delete the line and rely on `put_dpop_challenge/2`'s own `dpop_nonce` handling, or add a test that demonstrates a `403 insufficient_scope` with a `DPoP-Nonce` response header and document the production scenario that produces it. Without that demonstration the line is dead-code-for-symmetry that future readers must trace and verify.

### WR-05: Smoke test issues two unrelated `GET /verify` requests in one expression

**File:** `scripts/demo/adoption_smoke.py:273`
**Issue:** The inline CSRF lookup makes a *second* `GET /verify` request from a nested expression:

```python
lookup = browser.request("POST", "/verify", {
    "_csrf_token": csrf(browser.request("GET", "/verify").get("body", "")),
    "user_code": issued_json["user_code"]
})
```

Both calls go through the same `browser` (same cookies), so the session-bound CSRF token survives. But:

- The order of evaluation makes it nontrivial to see that two HTTP requests are being made on this line.
- The `.get("body", "")` pattern hides what happens if `request()` ever changes its return shape — `csrf()` raises `AssertionError("missing CSRF token")` on an empty body, which would obscure the real failure (the GET itself failed).
- Whether the CSRF token from the inline GET is the canonical one used by Phoenix's CSRF plug depends on session-cookie semantics; if a future change makes CSRF tokens single-use, this stops working without an obvious diff.

**Fix:** Split the GET into its own statement:

```python
verify_page = browser.request("GET", "/verify")
assert_status(verify_page, 200, "verify page")

lookup = browser.request("POST", "/verify", {
    "_csrf_token": csrf(verify_page["body"]),
    "user_code": issued_json["user_code"],
})
```

## Info

### IN-01: `enforce_audience` raise message and validation order are subtly inconsistent

**File:** `lib/lockspire/plug/verify_token.ex:56-67`
**Issue:** `init/1` first raises on `enforce_audience: true` with no `:audience`/`:audiences` key, then runs `validate_non_empty_value!(:audience)` / `validate_audiences_not_empty!/1`. The combined behavior is correct, but the error a misconfigured operator sees depends on *which* failure path they hit (key missing vs. key present but empty), and the two paths give different error messages. The "audience" raise specifically mentions D-07; the non-empty-value raise does not.

**Fix:** Move all audience-shape validation into one block that emits a single canonical message naming D-07, so any misconfiguration of the audience surface produces the same operator-readable error.

### IN-02: `opaque_shape?/1` regex allows extremely large segment sizes

**File:** `lib/lockspire/plug/verify_token.ex:157-173`
**Issue:** The base64url match is `~r/^[A-Za-z0-9_\-]+$/` with no upper bound on segment length. A pathological `Authorization: Bearer <100KB of A's>.<100KB of A's>.<100KB of A's>` passes the structural check, then goes into `JOSE.JWT.peek_protected/1`, which decodes ~100KB to confirm the JSON header. This is not a correctness bug (memory cost is bounded by Plug's own request-line and header limits), but the structural check could enforce a sensible upper bound (e.g. 16KB per segment) to fail fast on obviously-out-of-spec inputs.

**Fix:** Optional — bound the regex with `{1,16384}` per segment, or check `byte_size(segment) <= some_max` before the regex.

### IN-03: `binding_type/1` and `challenge_for/2` repeat the same `cnf` lookup logic

**File:** `lib/lockspire/plug/verify_token.ex:458-468, 501-512`
**Issue:** Both helpers read `cnf.jkt` and `cnf["x5t#S256"]`, run `present?/1`, and dispatch on the combination. They return distinct types intentionally (string vs atom), but they should share a single helper:

```elixir
defp cnf_binding(claims) do
  case claims do
    %{"cnf" => %{} = cnf} ->
      %{dpop: present?(Map.get(cnf, "jkt")),
        mtls: present?(Map.get(cnf, "x5t#S256"))}
    _ ->
      %{dpop: false, mtls: false}
  end
end
```

This collapses two functions' worth of branching into one source of truth. A future change to "what counts as a binding" (e.g. a third cnf form) updates one place, not two.

### IN-04: `release_readiness_contract_test.exs` audience contract clause uses `Regex.run` with a captured value that is never verified beyond length

**File:** `test/lockspire/release_readiness_contract_test.exs:771-790`
**Issue:** The new D-07 contract test (line 761-791) captures the audience substring with `~r/Lockspire\.Plug\.VerifyToken,[^\n]*\baudience:\s*"([^"]+)"/` and then only asserts `String.length(captured) > 0`. The capture is non-empty by construction of the regex (`[^"]+` requires at least one character), so the `assert String.length(captured) > 0` clause is tautological — it can never fail given the regex matches.

The actual assertion that matters (audience is non-empty) is enforced by the regex itself. The `String.length > 0` line is dead.

**Fix:** Either drop the `String.length(captured) > 0` assertion (the regex match is the real check, and the `flunk(...)` branch handles the missing/empty case correctly), or change the regex to allow `audience: ""` and let the assertion catch it:

```elixir
case Regex.run(
       ~r/Lockspire\.Plug\.VerifyToken,[^\n]*\baudience:\s*"([^"]*)"/,
       bytes,
       capture: :all_but_first
     ) do
  [captured] when is_binary(captured) ->
    assert String.length(captured) > 0,
           "expected non-empty audience: value..."
  # ...
end
```

The latter has the side benefit of distinguishing "missing audience: keyword" (flunk) from "audience keyword present but empty" (assertion failure with a clearer message).

---

_Reviewed: 2026-05-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
