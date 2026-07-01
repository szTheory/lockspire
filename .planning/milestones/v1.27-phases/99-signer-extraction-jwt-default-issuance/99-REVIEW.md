---
phase: 99-signer-extraction-jwt-default-issuance
reviewed: 2026-05-28T14:57:40Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - lib/lockspire/protocol/access_token_signer.ex
  - lib/lockspire/protocol/token_exchange.ex
  - lib/lockspire/protocol/refresh_exchange.ex
  - lib/lockspire/protocol/rfc8693_exchange.ex
  - lib/lockspire/protocol/discovery.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/domain/server_policy.ex
  - lib/lockspire/admin/clients.ex
  - lib/lockspire/admin/server_policy.ex
  - lib/lockspire/storage/ecto/client_record.ex
  - lib/lockspire/storage/ecto/server_policy_record.ex
  - lib/lockspire/web/live/admin/clients_live/form_component.ex
  - lib/lockspire/web/live/admin/clients_live/show.ex
  - lib/lockspire/test_repo.ex
  - priv/repo/migrations/20260528150000_add_access_token_format.exs
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
remediated:
  - "CR-01 — fixed (commit 6134f75): sign_jwt/2 with/else returns structured :token_signing_failed on a corrupt key; regression tests added"
  - "WR-01 — fixed (commit 6134f75): signer + test mocks use the arity-1 KeyStore callback"
  - "WR-02 — fixed (commit 9b05f46): single issued_at threaded through RFC 8693 signing + persistence"
remaining: "WR-03, WR-04, WR-05, IN-01..IN-04 not addressed (out of approved remediation scope)"
---

# Phase 99: Code Review Report

**Reviewed:** 2026-05-28T14:57:40Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

This phase extracts all RFC 9068 `at+jwt` access-token signing into `Lockspire.Protocol.AccessTokenSigner` and flips the server-wide default access-token format to `:jwt`. I verified the load-bearing claims in the change description and they largely hold up:

- **Format resolution precedence is correct.** `resolve_format/2` (signer lines 89-98) implements per-client override -> server default -> `:jwt` exactly, with a `nil`/garbage server-policy normalizing to `nil` and falling through to the `:jwt` literal. The admin override surface (`Admin.Clients.normalize_access_token_format/1`, `Admin.ServerPolicy.normalize_access_token_format/1`) is a strict allowlist of `:jwt | :opaque` (plus `nil`/`inherit` for the per-client variant only); no injection vector is exposed.
- **Audience derivation is correct.** The four standard grant paths funnel through `issue/3` -> `derive_aud/2`, emitting a LIST aud (`[client_id]` when empty); the RFC 8693 carve-out funnels through `issue_exchange/4` with a bare-string `aud == client_id` and a hardened restricted-claim drop. Test coverage (`access_token_signer_test.exs`) pins both shapes and proves the custom-claim `iss`/`aud` override-attack is dropped.
- **The refresh `sub` source fix is real and necessary.** Previously `build_rotated_access_token` set `account_id: nil` (harmless when tokens were opaque); now it sources `source_token.account_id` so the minted JWT carries a non-nil `sub`. The persisted refresh token keeping `account_id: nil` is safe because `Repository.rotate_refresh_token` back-fills via `account_id: ... || record.account_id` at persistence (repository.ex:2037/2061).
- **`token_hash` re-pointing is sound.** `Policy.hash_token/1` and `TokenFormatter.hash_token/1` are byte-identical (`:sha256` -> `Base.encode16(:lower)`), and introspection (`introspection.ex:70`) hashes the presented raw token with `TokenFormatter.hash_token/1`, so a raw `at+jwt` resolves to the persisted `%Token{}.token_hash` set by the signer. Introspection/revocation by hash works regardless of issued format.
- **No JOSE signing logic remains duplicated for access tokens.** All four standard paths plus the exchange path now route through the single `sign_jwt/2` site; the prior `rfc8693_exchange.ex` signing block was removed.
- **Error paths do not leak key material.** `sign_jwt/2` logs only `inspect(reason)` (an atom), and the `none` alg is never emitted (`alg`/`kid` come only from the active key). Tests assert no `private_jwk`/`d` exponent reaches logs.

The one Critical finding is a latent crash that this phase materially widened: a hard pattern-match on `decode_private_jwk/1` that, on a stored-but-corrupt JWK, raises `MatchError` (HTTP 500 with a stacktrace) instead of returning the structured `:token_signing_failed` error. Previously this lived only on the rarely-exercised RFC 8693 custom-claims path; the JWT default now makes it reachable on every authorization-code, refresh, device-code, and CIBA issuance.

## Critical Issues

### CR-01: Hard match on `decode_private_jwk/1` crashes the signer on a corrupt stored JWK, now on all default grant paths

**File:** `lib/lockspire/protocol/access_token_signer.ex:169`
**Issue:** `sign_jwt/2` does a hard match:

```elixir
{:ok, jwk_map} = decode_private_jwk(private_jwk)
```

`fetch_signing_key/1` only guarantees `private_jwk_encrypted` is a binary (line 204-205, `is_binary(private_jwk)`), not that it decodes to a JWK map. `decode_private_jwk/1` can return `{:error, :invalid_signing_key}` (lines 222, 229) when the stored material is neither valid JSON nor a safe-decodable Erlang term map (e.g. partial/corrupt ciphertext, a non-map encoding, or a future key-storage format). When it does, the hard match raises `MatchError`, which escapes `sign_jwt/2` entirely — there is no surrounding `try`/`rescue` and no `else` clause — so the request 500s with a raw stacktrace instead of the structured `%Error{reason_code: :token_signing_failed}` the module is designed to return. The module's own moduledoc and tests promise a clean 500 on "a missing or invalid key."

This pattern is carried over verbatim from the pre-extraction `rfc8693_exchange.ex`, but that path only signed JWTs when the host validator returned custom claims (a minority path). By flipping the default access-token format to `:jwt`, this phase routes the authorization-code, refresh, device-code, and CIBA grants through the same hard match, so a single corrupt active signing key now fails every token issuance with an unstructured crash rather than a graceful `server_error`.

Note the sibling `IdToken.sign/1` already handles this correctly with a `with {:ok, jwk_map} <- decode_private_jwk(...)` and an `else {:error, reason} -> {:error, reason}` (`id_token.ex:36,56-58`). The signer should mirror that.

**Fix:**
```elixir
defp sign_jwt(claims, request) do
  with {:ok, %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}} <-
         fetch_signing_key(request),
       {:ok, jwk_map} <- decode_private_jwk(private_jwk) do
    {_, compact} =
      JOSE.JWT.sign(
        JOSE.JWK.from_map(jwk_map),
        %{"alg" => alg, "kid" => kid, "typ" => "at+jwt"},
        claims
      )
      |> JOSE.JWS.compact()

    {:ok, compact, Policy.hash_token(compact)}
  else
    {:error, reason} ->
      Logger.error("Failed to sign access token: #{inspect(reason)}")

      {:error,
       %Error{
         status: 500,
         error: "server_error",
         error_description: "Unable to sign access token.",
         reason_code: :token_signing_failed
       }}
  end
end
```
A regression test seeding an active key whose `private_jwk_encrypted` is a non-decodable binary should assert `{:error, %Error{reason_code: :token_signing_failed}}` rather than a raised `MatchError`.

## Warnings

### WR-01: Signer calls `fetch_active_signing_key/0` but the `KeyStore` behaviour only declares arity 1

**File:** `lib/lockspire/protocol/access_token_signer.ex:203`
**Issue:** `sign_jwt` -> `fetch_signing_key/1` calls `key_store.fetch_active_signing_key()` (arity 0). The `KeyStore` behaviour callback is `@callback fetch_active_signing_key(keyword())` — arity 1 only (`storage/key_store.ex:15`). `Repository.fetch_active_signing_key/1` happens to compile to an arity-0 clause because of its default arg (`def fetch_active_signing_key(opts \\ [])`, repository.ex:1064), and the test mock defines an explicit arity-0 `fetch_active_signing_key/0`, so the happy path works today. But any host-supplied `:key_store` that implements the documented behaviour faithfully (arity 1, no default) will raise `UndefinedFunctionError` at issuance. Every other caller (`introspection_jwt.ex:48`, `jarm.ex:69`) calls the arity-1 form. This is carried over from `token_exchange.ex:1232`, but the signer is now the canonical issuance site and should match the contract.
**Fix:** Call the behaviour-declared arity: `key_store.fetch_active_signing_key([])` (or pass relevant opts). Keep `Config.repo!()` fallback as-is.

### WR-02: RFC 8693 exchange evaluates `now/1` twice, so the signed JWT `iat`/`exp` and the persisted token timestamps diverge

**File:** `lib/lockspire/protocol/rfc8693_exchange.ex:35-44`
**Issue:** `sign_or_format_access_token(client, subject_token, requested_scopes, now(request), ...)` (line 36) signs the JWT using one `now(request)` value, then `issued_at = now(request)` (line 44) is computed again for the persisted `%Token{issued_at:, expires_at:}` (lines 59-60). In production `:now` is unset, so `now/1` resolves to `DateTime.utc_now/0` and the two calls differ by microseconds. The result is a persisted access-token record whose `issued_at`/`expires_at` do not match the `iat`/`exp` baked into the signed JWT it represents. The standard grant paths in `token_exchange.ex` avoid this by computing `issued_at` once and threading it through both signing (via `%Token{}.issued_at`) and persistence; the exchange path should do the same. Not a security hole (the JWT carries its own authoritative `exp`), but it is a real correctness/consistency defect and will surface as flaky assertions or off-by-a-tick lifecycle math.
**Fix:**
```elixir
issued_at = now(request)

with ...,
     {:ok, token_string, token_hash} <-
       sign_or_format_access_token(client, subject_token, requested_scopes, issued_at, validation_result, request) do
  # reuse the same issued_at for the persisted %Token{}
```

### WR-03: `derive_aud/2` has no `nil` clause and will `FunctionClauseError` if audience is ever nil

**File:** `lib/lockspire/protocol/access_token_signer.ex:121-123`
**Issue:** `derive_aud/2` matches only `[]` and `is_list(audience)`. `Token.audience` defaults to `[]` and is typed `[String.t()]`, so nil is not expected through the reviewed call sites today. However, `issue/3` passes `token.audience` straight in with no guard, so any future/host path that constructs a `%Token{audience: nil}` (e.g. a partially-built grant token) crashes the signer with `FunctionClauseError` instead of degrading gracefully. Given this module is now the single chokepoint for all access-token issuance, a defensive clause is cheap insurance.
**Fix:** Add `defp derive_aud(nil, client_id), do: [client_id]` before the list clauses.

### WR-04: `IdToken` issuance failure inside `build_success_response` is not normalized to `{:error, %Error{}}` consistently

**File:** `lib/lockspire/protocol/token_exchange.ex:1113-1131`
**Issue:** `build_success_response/8` uses `with {:ok, id_token} <- maybe_issue_id_token(...)` but has no `else` clause. `maybe_issue_id_token/6` returns `{:error, oauth_error(...)}` (line 1162) on id_token failure. Without an `else`, the `with` returns that `{:error, %Error{}}` tuple verbatim — which is correct only because the callers (`redeem_code`, `redeem_device_grant`, `redeem_ciba_grant`) all pattern-match `%Success{} = success <- ...` and route a non-`%Success{}` into their own `else {:error, %Error{} = error}`. This works today but is fragile: `build_success_response/8`'s success branch returns a bare `%Success{}` (not `{:ok, ...}`), so the function has two different return shapes (`%Success{}` vs `{:error, %Error{}}`) and relies on every caller's `with` head doing the discrimination. A future caller that binds the result without the `%Success{} = ` guard will silently treat an error tuple as success. Make the contract explicit.
**Fix:** Either return `{:ok, %Success{}}`/`{:error, %Error{}}` uniformly from `build_success_response/8`, or add an explicit `else {:error, %Error{} = error} -> {:error, error}` and document the bare-`%Success{}` success shape.

### WR-05: Refresh-rotation audit/observability `subject_id` is always nil

**File:** `lib/lockspire/protocol/refresh_exchange.ex:332` (and consumers at lines 204, 425, 444, 456)
**Issue:** `build_rotated_refresh_token/5` sets `account_id: nil`. The repository back-fills `account_id` at persistence (`record.account_id` fallback), but the in-memory `refresh_token`/`rotated` structs returned to `emit_success/3` (line 204: `subject_id: refresh_token.account_id`) and `refresh_rotation_audit_event/3` (line 425: `subject_id: rotated.account_id`) still carry nil. So every refresh-rotation success event and audit record emits `subject_id: nil`, losing the subject attribution on the rotation path. This is pre-existing (the prior code also set `account_id: nil`), but the phase's `sub` fix already demonstrates the correct source (`source_token.account_id`); applying it to the refresh token too would close the observability gap. Flagging as a warning because audit completeness is a security-adjacent concern for an authz server.
**Fix:** Set `account_id: source_token.account_id` in `build_rotated_refresh_token/5` (mirrors the access-token fix and matches the value the repository back-fills anyway).

## Info

### IN-01: Non-standard discovery metadata key `access_token_signing_alg_values_supported`

**File:** `lib/lockspire/protocol/discovery.ex:102`
**Issue:** `access_token_signing_alg_values_supported` is not a registered OAuth Server Metadata / OIDC Discovery parameter (RFC 8414 / OIDC Discovery 1.0 define no such key; RFC 9068 does not register one either). Publishing a custom key is harmless to spec-conformant clients (they ignore unknown members) and is clearly intentional/documented (DISCOVERY-01 comment), but consumers should not expect interop tooling to read it. The literal `["RS256","ES256","PS256"]` correctly omits `none` and `EdDSA` and is published unconditionally — consistent with the stated design.
**Fix:** None required; optionally prefix with a vendor namespace (e.g. `lockspire_access_token_signing_alg_values_supported`) to signal it is non-standard, or document it in the discovery contract.

### IN-02: Dead `edit_attrs`/`redirect_attrs` arity ambiguity is fine, but `redirect_attrs/3` first arg of `:redirects` clause shadows intent

**File:** `lib/lockspire/web/live/admin/clients_live/show.ex:488-499`
**Issue:** `edit_attrs/2` reads `params["access_token_format"]` straight into the update attrs (line 494). This is safe — `Admin.Clients.update_client` routes it through `@mutable_fields` and `validate_access_token_format_if_present/1`, which rejects anything outside `jwt | opaque | inherit | ""`. No injection. Noting only that the LiveView passes the raw form value through without local normalization, relying entirely on the admin boundary's allowlist; that is the correct layering but worth a comment so a future refactor does not "helpfully" pre-cast it.
**Fix:** Optional: add a comment that `access_token_format` validation/normalization is owned by `Admin.Clients`, not the LiveView.

### IN-03: `now/1` in `token_exchange.ex` and `rfc8693_exchange.ex` expect a 0-arity `:now` function; mismatch is silent

**File:** `lib/lockspire/protocol/token_exchange.ex:1437-1442`, `lib/lockspire/protocol/rfc8693_exchange.ex:264-269`
**Issue:** `now/1` does `Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end) |> then(& &1.())` — it calls the configured `:now` with zero args. If a host/test passes a non-function or a 1-arity function as `:now`, this raises `BadArityError`/`BadFunctionError` at issuance time rather than failing fast at config time. Test-only seam, low risk.
**Fix:** Optional: guard or document that `:now` must be `(-> DateTime.t())`.

### IN-04: `decode_private_jwk/1` is now duplicated across five modules

**File:** `lib/lockspire/protocol/access_token_signer.ex:219-233` (also in `id_token.ex`, `logout_token.ex`, `jar.ex`, `introspection_jwt.ex`)
**Issue:** The JSON-then-safe-Erlang-term JWK decode helper is copy-pasted into five protocol modules with identical bodies (and, per CR-01, subtly different error-handling discipline). The phase consolidated access-token *signing* into one module but left the JWK *decode* primitive duplicated. This is the kind of drift that produced the CR-01 hard-match inconsistency (signer/rfc8693 hard-match vs id_token's graceful `with`). Consider extracting a single `Lockspire.Security.JwkDecode.decode_private/1`.
**Fix:** Out of v1 scope to fix, but extracting the shared decoder would let CR-01's fix apply uniformly and prevent future inconsistency.

---

_Reviewed: 2026-05-28T14:57:40Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
