---
phase: 21-jar-foundation
reviewed: 2026-04-25T12:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/lockspire/protocol/jar.ex
  - test/lockspire/protocol/jar_test.exs
findings:
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues_found
---

# Phase 21: Code Review Report

**Reviewed:** 2026-04-25T12:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The JAR foundation module (`Lockspire.Protocol.Jar`) implements RFC 9101 request-object handling across three sub-phases: unverified decoding, signature verification with a strict algorithm allow-list, and RFC 7519 security claims validation. The implementation is generally solid: `alg=none` is fail-closed, only asymmetric algorithms are accepted (no HMAC/algorithm confusion), claim parsing uses string keys throughout (no atom-creation from untrusted input), `exp` uses strict-greater-than comparison, leeway is applied symmetrically to time-based checks, and option validation rejects empty/invalid inputs.

The most notable gap is the absence of a JWT type-confusion check (`typ` header). RFC 9101 §10.8 explicitly recommends `typ=oauth-authz-req+jwt` to prevent a client's privately-key-signed token of one kind (id_token, client_assertion, etc.) from being replayed as a request object. Without this guard, any JWT signed by the client's registered key with a matching `iss`/`aud`/`exp` could be accepted as a JAR. There are also two smaller defensive gaps in audience-list validation and a few testing blind spots (no HMAC-rejection test, no multi-key JWKS test, no `kid`-based selection coverage).

No critical issues were found. Three warnings concern correctness/security hardening worth addressing before this module is wired into the authorize/PAR endpoints. Five info items capture lower-priority improvements and test-coverage suggestions.

## Warnings

### WR-01: Missing `typ` header check enables JWT-type confusion (RFC 9101 §10.8)

**File:** `lib/lockspire/protocol/jar.ex:142-161` (and by extension the public surface of `verify_signature/2` and `validate_claims/2`)

**Issue:** Neither `verify_signature/2` nor `validate_claims/2` enforces the `typ` JOSE header. RFC 9101 §10.8 ("Cross-JWT Confusion") explicitly recommends rejecting request objects whose `typ` is not `oauth-authz-req+jwt`. Without this check, an attacker who can obtain (or replay) any JWT signed by the client's registered private key — for example, a `private_key_jwt` client assertion, an `id_token`, an internally-generated logout token, or any future signed JWT artefact — can submit it to the authorize/PAR endpoint as a request object provided `iss`, `aud`, `exp` happen to align. With `private_key_jwt` in particular, every token endpoint call by the client produces a candidate JWT whose `iss == client_id` and `aud` matches the AS, which is exactly the JAR shape.

This is the single most important security check missing from the foundation. The `@allowed_algorithms` allow-list and `iss`/`aud` checks do not substitute for it: those defend against algorithm confusion and audience confusion across servers, not type confusion within a single client/AS pair.

**Fix:** Either enforce in `verify_signature/2` (preferred, since it has the parsed header) or as a required step in `validate_claims/2`. Example, added after `verify_strict` succeeds:

```elixir
defp verify_with_single_jwk(jwt, public_jwk) do
  try do
    case JOSE.JWT.verify_strict(public_jwk, @allowed_algorithms, jwt) do
      {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
        {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
        {_modules, header} = JOSE.JWS.to_map(jws_struct)

        case check_typ(header) do
          :ok -> {:ok, %__MODULE__{claims: claims, header: header}}
          {:error, _} = err -> err
        end
      ...
    end
  ...
end

# RFC 9101 §10.8: if `typ` is present it must be the request-object type.
# Absent `typ` is tolerated (RFC 9101 allows omission for backward compatibility);
# tighten to require presence once interop is established.
defp check_typ(%{"typ" => typ}) when is_binary(typ) do
  if String.downcase(typ) in ["oauth-authz-req+jwt", "jwt"] do
    :ok
  else
    {:error, :invalid_typ}
  end
end
defp check_typ(_), do: :ok
```

Add `:invalid_typ` to the verify_signature error type and add a test that signs a JWT with `typ=JWT-bearer` (or a fabricated `typ`) and asserts rejection. Decide explicitly whether to require presence; document the choice in the `@moduledoc`.

### WR-02: `aud` list path silently accepts non-binary entries

**File:** `lib/lockspire/protocol/jar.ex:253-258`

**Issue:** The list branch of `check_audience/2` only checks "is the expected value present?" via `Enum.any?`. It does not validate that each entry is a binary, which means a malformed token with an `aud` array containing maps, integers, or `nil` mixed with the expected string will pass. While there is no direct exploit (the expected audience is required to be a binary by `parse_opts`), accepting structurally invalid claims encourages defects elsewhere — for example, downstream code that iterates `aud` later will encounter unexpected types — and silently tolerates non-conforming JARs that should be rejected per RFC 7519 §4.1.3 (StringOrURI values).

The string-aud branch already enforces type strictness implicitly via the `is_binary(aud)` guard, so the list branch is the only inconsistent path.

**Fix:** Reject lists containing non-binary entries:

```elixir
aud when is_list(aud) ->
  cond do
    aud == [] -> {:error, :invalid_audience}
    not Enum.all?(aud, &is_binary/1) -> {:error, :invalid_audience}
    Enum.member?(aud, expected_audience) -> :ok
    true -> {:error, :invalid_audience}
  end
```

Add corresponding tests for `aud: []` and `aud: [@audience, 42]`.

### WR-03: `validate_claims/2` does not enforce `exp` is positive / not absurdly large

**File:** `lib/lockspire/protocol/jar.ex:265-282`

**Issue:** `check_expiration/3` accepts any integer `exp`. A negative `exp` (e.g., `-1`) is correctly rejected as expired because `-1 + 0 > now_unix` is false, but a *very large future* `exp` (e.g., `999_999_999_999_999`) is accepted unconditionally. RFC 9101 itself does not bound `exp`, but most ASs apply a maximum lifetime to request objects (typically 1–10 minutes) to limit the replay window between issuance and use, and to make replay caches finite-size. The current API exposes no way for the caller to enforce a max-age, so every consumer must duplicate that logic.

This is a defense-in-depth concern, not a vulnerability per se, but worth fixing before the module is plumbed into PAR/authorize: those endpoints will want a single knob for the JAR lifetime ceiling.

**Fix:** Add an optional `:max_age` (seconds) option to `validate_claims/2`. When present, also verify `exp - iat <= max_age` (when `iat` is present) and `exp - now <= max_age + leeway` (always), rejecting otherwise with a new `:expiration_too_far` reason. Example sketch:

```elixir
# in parse_opts/1 — accept :max_age (positive integer or nil)
max_age = Keyword.get(opts, :max_age)

# in check_expiration/4 — also verify upper bound
defp check_expiration(claims, now, leeway, max_age) do
  with {:ok, exp} <- fetch_exp(claims),
       :ok <- check_not_expired(exp, now, leeway),
       :ok <- check_max_age(exp, claims, now, leeway, max_age) do
    :ok
  end
end
```

Document the rationale in the `@moduledoc` and test that an `exp` 1 hour out is rejected when `max_age: 600`.

## Info

### IN-01: No `kid`-based key selection in `verify_against_keys/2`

**File:** `lib/lockspire/protocol/jar.ex:133-140`

**Issue:** When the client's JWKS contains multiple keys, `verify_against_keys/2` tries each in arbitrary list order until one verifies. `JOSE.JWT.verify_strict` does honor `kid` matching internally, so it's not a correctness bug — but iterating all keys when a `kid` is present in the header is wasted work and leaks negligible timing information about the key set. More importantly, the implementation is untested with multi-key JWKS, so a future refactor could regress without detection.

**Fix:** When `header["kid"]` is set on the JWT, prefer the JWK whose `kid` matches; fall back to all keys only if none match (or if the header omits `kid`). Add a test that asserts: (a) a JWT with `kid=A` verifies against a JWKS containing keys A and B; (b) a JWT with `kid=A` does NOT verify against a JWKS containing only B (`:invalid_signature`); (c) a JWT with no `kid` verifies against any matching key.

### IN-02: No regression test that HMAC algorithms are rejected

**File:** `test/lockspire/protocol/jar_test.exs:97-108`

**Issue:** The test suite covers `alg=none` rejection (line 97) but does not assert that `HS256`/`HS384`/`HS512` are rejected. The allow-list correctly excludes them, but a future "let's add HS256 for legacy clients" change to `@allowed_algorithms` would silently break the algorithm-confusion defence (where an attacker uses the public key bytes as an HMAC secret). A regression test makes the security boundary explicit.

**Fix:** Add a test along the lines of:

```elixir
test "returns {:error, :invalid_signature} for HS256-signed JWTs (algorithm confusion defence)", %{
  pub_jwk_map: pub_jwk_map
} do
  # An attacker who knows the client's public key tries to use it as an HMAC secret.
  hmac_jwk = JOSE.JWK.from_oct(Jason.encode!(pub_jwk_map))
  jwt = JOSE.JWT.sign(hmac_jwk, %{"alg" => "HS256"}, %{"iss" => "client_id"})
        |> JOSE.JWS.compact() |> elem(1)

  client = %Client{jwks: pub_jwk_map}
  assert {:error, :invalid_signature} = Jar.verify_signature(jwt, client)
end
```

### IN-03: No test coverage for non-RSA algorithms (ES256, EdDSA, PS256)

**File:** `test/lockspire/protocol/jar_test.exs:34-159`

**Issue:** The `verify_signature/2` test block exclusively uses RS256/2048-bit RSA. The `@allowed_algorithms` list also includes ES256/ES384/ES512, PS256/PS384/PS512, and EdDSA, but none are exercised. Subtle JOSE configuration issues (Erlang/OTP crypto curve availability, EdDSA registration) tend to surface only at runtime under specific algorithms.

**Fix:** Parameterise the happy-path test across at least RS256, ES256, and EdDSA. ExUnit `for alg <- ["RS256", "ES256", "EdDSA"], do: ...` or a helper that generates the appropriate key per `alg` is sufficient.

### IN-04: Replay-protection (`jti`) is out of scope but not documented

**File:** `lib/lockspire/protocol/jar.ex:163-200`

**Issue:** The `validate_claims/2` doc lists `iss`, `aud`, `exp`, `nbf`, `iat` but says nothing about `jti`. RFC 9101 does not require `jti` for request objects, but a JAR's `exp` window (typically minutes) leaves a replay window unless the AS tracks JTIs. Downstream readers may assume "validate_claims" is sufficient when in fact the caller (PAR/authorize endpoint) must add a JTI cache.

**Fix:** Add a "Non-goals" or "Caller responsibilities" paragraph to `@moduledoc` explicitly stating that this module does not perform replay protection (no `jti` cache) and that callers MUST add one if `exp - iat` exceeds their tolerated replay window. This matches the architecture of similar modules and documents the security boundary for reviewers.

### IN-05: `decode/1` test for 4-segment string is mislabeled

**File:** `test/lockspire/protocol/jar_test.exs:18-21`

**Issue:** The test "returns error for malformed JWT strings" uses `"header.payload.signature.extra"` and labels it malformed. A 4-segment compact string is not a valid JWS compact serialization (which is 3 segments) nor a valid JWE compact (which is 5), so the test is correct, but the naming and grouping with `"not.a.jwt"` blur two distinct cases (truly malformed vs. "extra segment"). This is purely cosmetic.

**Fix:** Split into two named tests: `"rejects strings with too few segments"` and `"rejects strings with too many segments"`. Alternatively, keep the test but rename to `"rejects strings without a valid 3-segment JWS structure"` and add a comment explaining the `.extra` case explicitly.

---

_Reviewed: 2026-04-25T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
