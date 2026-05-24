# Phase 38: Session Tracking & RP-Initiated Logout - Research

**Researched:** 2026-04-29
**Domain:** OIDC RP-Initiated Logout, sid tracking, host logout seam, Phoenix controller patterns
**Confidence:** HIGH

## Summary

Phase 38 adds durable `sid` (Session ID) tracking to interactions and tokens, implements the `GET/POST /end_session` endpoint per the OIDC RP-Initiated Logout specification, and wires a host-owned session-clearing seam that mirrors the existing `redirect_for_login` pattern. The work is largely additive and follows well-established codebase conventions: Ecto migrations, domain struct extension, Storage.Ecto.Repository query additions, a new protocol module, a plain Phoenix controller, and admin LiveView field additions.

The codebase already has `post_logout_redirect_uris` in `ClientRecord` and `Client` domain struct (it is already listed in both `changeset/2` and `to_domain/1`). This field exists in the database column but is NOT yet in `update_changeset/2`, which means the admin UI path cannot yet update it. Phase 38 must add it to `update_changeset/2` and the admin form.

The signed `return_to` mechanism for the host logout seam does not currently exist in Lockspire — there is no `Phoenix.Token`-based signing helper in the library codebase. The existing login `redirect_for_login` path delegates `return_to` entirely to the host (it passes the path string directly). For Phase 38's completion endpoint, a signed, time-limited `return_to` is required per D-06 and D-07. The plan must introduce a signing approach (JOSE-based or Phoenix.Token-based against `secret_key_base`).

**Primary recommendation:** Build in this order: (1) migrations + domain extensions, (2) `revoke_by_sid/1` in Repository, (3) `EndSessionProtocol` module with all validation logic, (4) `EndSessionController`, (5) completion endpoint and host redirect, (6) discovery update, (7) admin UI, (8) generator update, (9) integration test.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**sid scope & lifecycle**
- D-01: `sid` is per-interaction scope. Each authorization flow generates its own sid.
- D-02: `sid` is generated at interaction creation time when the `lockspire_interactions` row is first inserted.
- D-03: `sid` is denormalized on `token_record` as a new `sid` field on `lockspire_tokens`. Same pattern as `interaction_id`.
- D-04: `sid` is always emitted as the OIDC `sid` claim in issued ID tokens (`IdToken.sign/1`).
- D-05: Phase 38 includes `revoke_by_sid/1` in the token store.

**Host logout seam**
- D-06: Redirect pattern — mirrors `redirect_for_login`. Signed, time-limited `return_to` URL.
- D-07: Lockspire passes `account_id` + signed `return_to` URL to the host logout path.
- D-08: Host logout path configured via `config :lockspire, logout_path: "/your/path"`.
- D-09: Always immediate — no confirmation step in the Lockspire protocol.
- D-10: If `return_to` signed token fails validation, treat as logout success anyway — log failure, revoke if sid is known, redirect to `post_logout_redirect_uri` or logged-out page.
- D-11: `revoke_by_sid` called at end_session completion (after host returns), not at start.
- D-12: If `logout_path` config key is not set, raise at startup with a clear error message.
- D-13: Generator update — Phase 38 emits a host logout route template.

**`/end_session` strictness**
- D-14: `id_token_hint` validation: validate signature using Lockspire's own JOSE signing keys, tolerate expiry. Extract `sub` and `sid` from validated claims.
- D-15: `post_logout_redirect_uri` requires exact match against client's registered `post_logout_redirect_uris`. Same strict model as `redirect_uri`.
- D-16: If no `id_token_hint` provided: proceed anyway. Token revocation skipped (no sid to revoke against).
- D-17: If no `post_logout_redirect_uri` (or not registered): show Lockspire-owned minimal "You have been signed out" page.
- D-18: `/end_session` accepts both GET and POST.
- D-19: `end_session_endpoint` published in discovery; `backchannel_logout_supported: false` and `frontchannel_logout_supported: false` also published.
- D-20: If both `client_id` and `id_token_hint` are provided, reject if `client_id` is not in `id_token_hint`'s `aud`.

**Admin UI surface**
- D-21: `sid` in existing token detail view. View-only in Phase 38.
- D-22: No separate Sessions admin LiveView in Phase 38.
- D-23: `post_logout_redirect_uris` added to client edit + show views.
- D-24: Lockspire-owned "logged out" page is a plain controller render.

### Claude's Discretion

None specified — all decisions are locked.

### Deferred Ideas (OUT OF SCOPE)

- Session-level revocation UI
- Back-Channel Logout webhook dispatch (Phase 39 / SLO-03)
- Front-Channel Logout iframe rendering (Phase 39 / SLO-04)
- `frontchannel_logout_supported: true` / `backchannel_logout_supported: true` discovery flags
- `check_session_iframe`
- New Sessions admin LiveView
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SLO-01 | Add durable Session ID (`sid`) tracking to interaction and token records | Migrations add `sid` column to `lockspire_interactions` and `lockspire_tokens`; domain structs and changeset functions extended; sid generated at interaction insert time via `Lockspire.Security.Policy.generate_token/1` or `:crypto.strong_rand_bytes`; denormalized onto token at issuance time same as `interaction_id` |
| SLO-02 | Implement `GET /end_session` (RP-Initiated Logout) with host-owned session clearing seam | New `EndSessionController` wired at `GET /end_session` and `POST /end_session`; `EndSessionProtocol` module owns all validation; host logout seam via configured `logout_path` + signed `return_to`; completion endpoint at `GET /end_session/complete`; discovery updated; admin UI for `post_logout_redirect_uris` |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| sid generation | Protocol / Storage | — | Generated at interaction creation in `InteractionStore.put_interaction/1`; a protocol invariant, not web-layer concern |
| sid denormalization onto tokens | Storage (Repository) | Protocol (token issuance callers) | Mirrors `interaction_id` denormalization; token store `store_token/1` receives sid from caller |
| sid claim in ID token | Protocol (`IdToken.sign/1`) | — | Protocol-owned claim emission; consistent with how `auth_time`, `nonce` are emitted |
| `revoke_by_sid/1` | Storage (Repository) | — | Bulk UPDATE query on `lockspire_tokens` by sid; same shape as `revoke_token_family/1` |
| `/end_session` validation logic | Protocol (`EndSessionProtocol`) | — | Thin Phoenix adapter calls protocol; validation stays protocol-owned per established pattern |
| `/end_session` HTTP adapter | Web (Controller) | — | Thin delivery layer; handles GET + POST; delegates to protocol module |
| Host logout seam redirect | Web (Controller) → Host | — | Controller redirects to configured `logout_path`; host clears session; returns to completion URL |
| signed `return_to` for logout completion | Protocol (new signing helper) | — | Needs to be verified on completion endpoint; should reuse or extend existing signing infrastructure |
| `end_session_endpoint` in discovery | Protocol (`Discovery`) | Web (DiscoveryController) | Discovery module owns metadata map; controller already delegates to `Discovery.openid_configuration/0` |
| `post_logout_redirect_uris` on client | Storage (ClientRecord) | Admin UI | Column already exists in DB and schema; `update_changeset/2` needs the field added |
| Admin token detail sid display | Admin UI (TokensLive.Show) | — | View-only field addition in existing template |
| Admin client `post_logout_redirect_uris` | Admin UI (ClientsLive) | — | Form + show view extension following `redirect_uris` textarea pattern |
| Generator host logout route | Generators (Install) | — | New template file or extension to existing `account_resolver.ex`/`router.ex` template |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| JOSE | ~> 1.11 [VERIFIED: mix.exs] | JWT signing/verification for `id_token_hint` validation | Already in use for ID token signing, JAR, DPoP |
| Ecto.SQL | ~> 3.13.5 [VERIFIED: mix.exs] | Migrations, bulk UPDATE for `revoke_by_sid/1` | Project-wide storage layer |
| Phoenix (Controller) | ~> 1.8.5 [VERIFIED: mix.exs] | HTTP adapter for `EndSessionController` | Existing controller pattern |
| Phoenix.LiveView | ~> 1.1.28 [VERIFIED: mix.exs] | Admin UI extensions | All admin surfaces use LiveView |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Plug.Crypto | included with Phoenix [ASSUMED] | `Plug.Crypto.MessageVerifier` or `Phoenix.Token` for signed return_to | Signing completion redirect token |
| Jason | ~> 1.4 [VERIFIED: mix.exs] | JSON encoding/decoding | Already used throughout |

**Installation:** No new dependencies needed — all required libraries are already in `mix.exs`.

---

## Architecture Patterns

### System Architecture Diagram

```
RP Browser              Lockspire                    Host App
    |                       |                            |
    |  GET/POST /end_session |                            |
    |----------------------->|                            |
    |                       |                            |
    |           EndSessionController.show/create         |
    |                       |                            |
    |            EndSessionProtocol.validate/1           |
    |                       |                            |
    |           [validate id_token_hint via JOSE]        |
    |           [lookup client, check aud match]         |
    |           [validate post_logout_redirect_uri]      |
    |                       |                            |
    |                       | redirect to logout_path    |
    |                       | (account_id + signed       |
    |                       |  return_to token)          |
    |<--------- redirect ---|                            |
    |                                                    |
    |  GET /host/logout?return_to=...                    |
    |-------------------------------------------------->|
    |                        host clears session         |
    |<--------------------------------------------------|
    |  redirect to /end_session/complete?token=...      |
    |                       |                            |
    |   /end_session/complete                            |
    |----------------------->|                            |
    |                       |                            |
    |           EndSessionController.complete            |
    |           [verify signed return_to token]         |
    |           [revoke_by_sid/1 — token store]         |
    |           [redirect to post_logout_redirect_uri   |
    |            OR render "logged out" page]            |
    |<----------------------|                            |
```

### Recommended Module Structure

```
lib/lockspire/
├── protocol/
│   └── end_session.ex          # EndSessionProtocol — all validation logic
├── storage/
│   └── token_store.ex          # Add @callback revoke_by_sid/1
├── storage/ecto/
│   ├── interaction_record.ex   # Add sid field + changeset
│   └── token_record.ex         # Add sid field + changeset
├── domain/
│   └── interaction.ex          # Add sid field to struct + typespec
│   └── token.ex                # Add sid field to struct + typespec
│   └── end_session_params.ex   # (optional) Typed params struct
├── web/
│   └── controllers/
│       ├── end_session_controller.ex
│       └── end_session_html/
│           └── logged_out.html.heex
└── host/
    └── account_resolver.ex     # Add redirect_for_logout/2 callback

priv/repo/migrations/
├── 20260429XXXXXX_add_sid_to_lockspire_interactions.exs
├── 20260429XXXXXX_add_sid_to_lockspire_tokens.exs
└── 20260429XXXXXX_add_post_logout_redirect_uris_to_lockspire_clients.exs
    # NOTE: post_logout_redirect_uris column may already exist from early
    # schema work — verify with `\d lockspire_clients` before creating migration.

priv/templates/lockspire.install/
└── logout_controller.ex        # New template for host logout route

test/lockspire/protocol/
└── end_session_test.exs        # Unit tests for EndSessionProtocol
test/lockspire/web/
└── end_session_controller_test.exs
test/integration/
└── phase38_session_logout_e2e_test.exs
```

### Pattern 1: revoke_by_sid/1 (mirrors revoke_token_family/1)

The existing `revoke_token_family/1` is the direct template:

```elixir
# Source: lib/lockspire/storage/ecto/repository.ex:590-603 [VERIFIED: read file]
@impl TokenStore
def revoke_token_family(family_id) when is_binary(family_id) do
  {count, _records} =
    TokenRecord
    |> where([token], token.family_id == ^family_id)
    |> where([token], is_nil(token.revoked_at))
    |> repo_update_all(
      [set: [revoked_at: DateTime.utc_now(), updated_at: DateTime.utc_now()]],
      sensitive: true
    )
  {:ok, count}
rescue
  error -> {:error, error}
end

# New revoke_by_sid/1 follows exact same shape:
@impl TokenStore
def revoke_by_sid(sid) when is_binary(sid) do
  {count, _records} =
    TokenRecord
    |> where([token], token.sid == ^sid)
    |> where([token], is_nil(token.revoked_at))
    |> where([token], is_nil(token.redeemed_at))
    |> repo_update_all(
      [set: [revoked_at: DateTime.utc_now(), updated_at: DateTime.utc_now()]],
      sensitive: true
    )
  {:ok, count}
rescue
  error -> {:error, error}
end
```

### Pattern 2: id_token_hint validation (reuses JOSE pattern from JAR, tolerate expiry)

```elixir
# Source: lib/lockspire/protocol/jar.ex:151-170 [VERIFIED: read file]
# Key difference vs JAR: do NOT check exp — tolerate expiry per OIDC spec D-14.
defp verify_id_token_hint(compact_jwt, signing_keys) do
  Enum.reduce_while(signing_keys, {:error, :invalid_signature}, fn key, _acc ->
    public_jwk = build_public_jwk(key)
    try do
      case JOSE.JWT.verify_strict(public_jwk, ["RS256"], compact_jwt) do
        {true, %JOSE.JWT{} = jwt_struct, _jws} ->
          {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
          # Do NOT check exp — id_token_hint tolerates expiry (D-14)
          {:halt, {:ok, claims}}
        {false, _, _} ->
          {:cont, {:error, :invalid_signature}}
      end
    rescue
      _ -> {:cont, {:error, :invalid_signature}}
    catch
      _, _ -> {:cont, {:error, :invalid_signature}}
    end
  end)
end
```

### Pattern 3: Startup config validation (mirrors Config.mount_path!/0)

```elixir
# Source: lib/lockspire/config.ex + lib/lockspire/security/policy.ex [VERIFIED: read files]
@spec logout_path() :: String.t()
def logout_path do
  case Application.get_env(@app, :logout_path) do
    value when is_binary(value) and value != "" ->
      value
    _missing ->
      raise ArgumentError,
            "missing required config :logout_path for :lockspire. " <>
              "Set it in config/runtime.exs or config/*.exs."
  end
end
```

### Pattern 4: Migration — additive column, non-nullable with default

```elixir
# Source: priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs [VERIFIED: read file]
defmodule Lockspire.Repo.Migrations.AddSidToLockspireInteractions do
  use Ecto.Migration

  def change do
    alter table(:lockspire_interactions) do
      add :sid, :string
    end
  end
end

defmodule Lockspire.Repo.Migrations.AddSidToLockspireTokens do
  use Ecto.Migration

  def change do
    alter table(:lockspire_tokens) do
      add :sid, :string
    end
  end
end
```

Note: `sid` is nullable in DB (new column, existing rows have no sid). Application layer ensures sid is always generated for new interactions. An index on `lockspire_tokens.sid` is appropriate given `revoke_by_sid/1` queries it.

### Pattern 5: post_logout_redirect_uris in ClientRecord update_changeset

```elixir
# Source: lib/lockspire/storage/ecto/client_record.ex:133-157 [VERIFIED: read file]
# IMPORTANT: post_logout_redirect_uris is in changeset/2 but NOT update_changeset/2.
# Phase 38 must add it to update_changeset/2 and the admin form.
def update_changeset(record, attrs) do
  record
  |> cast(attrs, [
    :name,
    :redirect_uris,
    :post_logout_redirect_uris,  # ADD THIS
    :allowed_scopes,
    # ... rest unchanged
  ])
end
```

### Pattern 6: Discovery — adding static fields (mirrors dpop_signing_alg_values_supported)

```elixir
# Source: lib/lockspire/protocol/discovery.ex:157-167 [VERIFIED: read file]
# Pattern: add to openid_configuration/0 map merge, conditionally or always present.
# end_session_endpoint published when route is mounted (same as other endpoints).
# BCL/FCL flags are always published (even as false) per D-19.
def openid_configuration do
  # ... existing code ...
  %{...existing fields...}
  |> Map.merge(endpoint_metadata)
  |> maybe_put_dpop_metadata(endpoint_metadata)
  |> maybe_put_end_session_metadata(endpoint_metadata)
end

defp maybe_put_end_session_metadata(metadata, endpoint_metadata) do
  base = %{
    "backchannel_logout_supported" => false,
    "frontchannel_logout_supported" => false
  }
  if Map.has_key?(endpoint_metadata, "end_session_endpoint") do
    Map.merge(metadata, base)
  else
    Map.merge(metadata, base)
    # Note: BCL/FCL flags published regardless per D-19
  end
end
```

### Pattern 7: Admin form for multi-value URI list (mirrors redirect_uris textarea)

```elixir
# Source: lib/lockspire/web/live/admin/clients_live/form_component.ex:132-135 [VERIFIED: read file]
# post_logout_redirect_uris follows identical textarea/newline-split pattern:
<div :if={@mode in [:new, :redirects]}>
  <label for="client_post_logout_redirect_uris">Post-Logout Redirect URIs</label>
  <textarea id="client_post_logout_redirect_uris"
            name="client[post_logout_redirect_uris]"
            rows="4"><%= @defaults.post_logout_redirect_uris %></textarea>
</div>
```

And in `show.ex`, `redirect_attrs/2` must include `post_logout_redirect_uris: split_lines(params["post_logout_redirect_uris"])`.

### Pattern 8: Plain controller render for "logged out" page (mirrors error pages)

```elixir
# EndSessionController.complete/2 — fallback when no post_logout_redirect_uri
def logged_out(conn, _params) do
  conn
  |> put_status(:ok)
  |> put_resp_content_type("text/html")
  |> put_view(Lockspire.Web.EndSessionHTML)
  |> render(:logged_out)
end
```

### Anti-Patterns to Avoid

- **Putting validation logic in the controller**: All `id_token_hint` parsing, `post_logout_redirect_uri` matching, and `client_id`/`aud` cross-checking belong in `EndSessionProtocol`, not in `EndSessionController`. The controller is a thin delivery adapter.
- **Checking token expiry on `id_token_hint`**: The OIDC RP-Initiated Logout spec explicitly anticipates that hints are presented after expiry. Validating `exp` would break conformant RPs. [CITED: openid.net/specs/openid-connect-rpinitiated-1_0.html section 3]
- **Calling `revoke_by_sid/1` at `/end_session` entry**: Revocation happens at the completion endpoint after the host clears the session (D-11). If called at entry, a network failure between Lockspire and the host would leave the user's web session active despite revoked tokens.
- **Using `redirect_uri` match for `post_logout_redirect_uri`**: These are separate registered lists. A client's `redirect_uris` are not valid `post_logout_redirect_uris` unless explicitly registered in that new field.
- **Omitting index on `lockspire_tokens.sid`**: `revoke_by_sid/1` does a full-table `WHERE sid = ?` scan without it. Add a B-tree index in the migration.
- **Adding `post_logout_redirect_uris` to DCR changeset without review**: The DCR management changeset (`dcr_management_changeset/2`) exists separately. Phase 38 should only add to `update_changeset/2` for operator-admin editing. DCR clients registering post-logout URIs is a Phase 39+ concern.

---

## Existing Codebase Findings (Verified)

### post_logout_redirect_uris Already Partially Present

`ClientRecord` already has `post_logout_redirect_uris` in the schema and `changeset/2`, and `Client` domain struct has the field. [VERIFIED: read files] The DB column may already exist if earlier phases ran the base client migration. **The planner must verify whether the column exists before generating a migration for it.** The column is NOT in `update_changeset/2`, which is the actual gap Phase 38 must close.

### No Signed return_to Infrastructure Exists Yet

The existing login flow passes `return_to` as a plain string path from Lockspire to the host (the host's `redirect_for_login` returns the `InteractionResult` with whatever `return_to` was given). The host's completion path (`/interactions/:id`) does not verify a signed token. [VERIFIED: read interaction_controller.ex]

For the logout completion endpoint, a signed `return_to` is required by D-06 so Lockspire can trust the host redirected back legitimately. Options:
- `Phoenix.Token.sign/verify` against `Endpoint.config(:secret_key_base)` — established Phoenix pattern [ASSUMED: Phoenix.Token is available via phoenix dep]
- Custom JOSE HMAC signing — consistent with JOSE already in use

**Recommendation**: Use `Phoenix.Token` for signed return_to because it handles TTL natively, is well-tested, and is idiomatic Phoenix. The `secret_key_base` is configured on the host's Endpoint.

### `AccountResolver` Callback Extension

Phase 38 adds a `redirect_for_logout/2` callback (or equivalent) to `Lockspire.Host.AccountResolver`. The existing callbacks are `resolve_current_account/2`, `resolve_account/2`, `build_claims/2`, and `redirect_for_login/2`. [VERIFIED: read account_resolver.ex]

The logout seam needs the host to receive `account_id` and `return_to`. The natural approach is a new `@callback redirect_for_logout(conn_or_socket, context) :: InteractionResult.t()` where `context` contains `%{account_id: ..., return_to: ...}`.

### IdToken.sign/1 Signature Pattern

`IdToken.sign/1` takes a flat map with named keys (not a struct). Adding `sid` follows the same pattern as `auth_time`: the caller includes `sid:` in the map, and `build_claims/7` (or expanded arity) reads it. [VERIFIED: read id_token.ex]

The function signature `sign(%{... interaction_nonce: nonce, ..., signed_at: ...})` will need `sid:` added. It must NOT break the pattern-match head — use `Map.get(params, :sid)` inside `build_claims` rather than adding it to the match pattern, to preserve backward compatibility.

### Token Issuance Path for sid Propagation

In `AuthorizationFlow.issue_authorization_code/3`, the `%Token{}` struct is built without `sid`. The `interaction` struct will have `sid` after Phase 38 migrations. The token builder must thread `sid: interaction.sid` into the `%Token{}` struct. Similarly in `TokenExchange` for access tokens and refresh tokens derived from the authorization code. [VERIFIED: read authorization_flow.ex and token.ex]

### Discovery Already Driven by Route Mounting

`Discovery.openid_configuration/0` checks mounted routes to decide which endpoints to publish. Adding `end_session_endpoint` to `@endpoint_paths` and adding the route to `Router` is the correct approach — it will auto-appear when the route is mounted. [VERIFIED: read discovery.ex]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Signed return_to URL | Custom HMAC + base64 encode | `Phoenix.Token.sign/4` | Built-in TTL, tamper protection, Phoenix-standard |
| JWT signature verification for id_token_hint | Custom JWT parsing | `JOSE.JWT.verify_strict/3` | Already used in `Jar` and `IdToken` — proven pattern |
| sid generation | UUID v4 or custom format | `:crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)` | Matches existing `generate_interaction_id/1` and `generate_code/1` patterns |
| Bulk token revocation query | Iterate and revoke one-by-one | Ecto `update_all` WHERE sid = ? | Single DB round-trip; existing `revoke_token_family/1` is the template |
| URL parameter encoding for redirect | Manual string concat | `URI.encode_query/1` + `URI.to_string/1` | Existing `build_redirect/2` pattern in `AuthorizationFlow` |

---

## Common Pitfalls

### Pitfall 1: post_logout_redirect_uris column existence ambiguity
**What goes wrong:** Migration fails because column already exists, or plan assumes it doesn't and skips migration.
**Why it happens:** `ClientRecord` schema already declares `post_logout_redirect_uris` but the migration may or may not have been run.
**How to avoid:** Wave 0 of the plan must check `\d lockspire_clients` or run `mix ecto.migrations` to verify column state. Conditionally create migration only if column is absent.
**Warning signs:** `Postgrex.Error: column "post_logout_redirect_uris" of relation "lockspire_clients" already exists`.

### Pitfall 2: id_token_hint expiry check
**What goes wrong:** Calling `Jar.validate_claims/2` or any exp-checking function on the id_token_hint rejects legitimate hints because ID tokens expire in 3600s.
**Why it happens:** The JAR validation path requires `exp` to be in the future. id_token_hint validation deliberately skips `exp` per OIDC spec.
**How to avoid:** id_token_hint validation must use only `JOSE.JWT.verify_strict/3` for signature, then directly extract claims without expiry check.
**Warning signs:** RPs who present hints minutes/hours after token issuance get spurious `invalid_id_token_hint` errors.

### Pitfall 3: revoke_by_sid called at wrong point in flow
**What goes wrong:** Tokens are revoked before the host clears the browser session; user's web session remains active but their tokens are gone, causing a confusing broken state.
**Why it happens:** It feels natural to revoke first, then redirect to host.
**How to avoid:** D-11 is explicit — `revoke_by_sid` called at completion endpoint, after host returns to Lockspire.
**Warning signs:** Integration test shows tokens revoked but user can still access the RP's session.

### Pitfall 4: Missing sid on tokens issued from device_code and refresh exchanges
**What goes wrong:** `revoke_by_sid/1` finds no tokens to revoke because device-code-derived or refreshed tokens have `sid = nil`.
**Why it happens:** Only `authorization_code` issuance path is updated, but access tokens and refresh tokens derived from it also need `sid` propagated.
**How to avoid:** Check all token issuance paths: `AuthorizationFlow.issue_authorization_code`, `TokenExchange.exchange_authorization_code`, `TokenExchange.rotate_refresh_token`. In all cases, the sid from the original interaction should flow through.
**Warning signs:** `revoke_by_sid/1` returns `{:ok, 0}` in integration tests when tokens exist.

### Pitfall 5: update_changeset missing post_logout_redirect_uris validation
**What goes wrong:** Admin UI saves empty string instead of list, or comma-separated string instead of newline-split list.
**Why it happens:** Textarea returns a string; `split_lines/1` must be applied in `redirect_attrs/2`.
**How to avoid:** Follow existing `redirect_uris` pattern exactly: `split_lines(params["post_logout_redirect_uris"])` in `redirect_attrs/2` inside `clients_live/show.ex`.
**Warning signs:** `post_logout_redirect_uri` exact-match check fails for URIs that were registered via the admin UI.

### Pitfall 6: sid is nil for interactions created before Phase 38 migration
**What goes wrong:** Existing tokens have `sid = nil`; `revoke_by_sid` with `WHERE sid = ?` finds nothing for old sessions.
**Why it happens:** Migration adds nullable column; existing rows stay null.
**How to avoid:** This is acceptable behavior per D-03 (sid always generated for new interactions going forward). Document in code that `sid = nil` tokens are pre-Phase-38 and cannot be revoked by sid. `revoke_by_sid/1` with `nil` input should return `{:ok, 0}` without querying.
**Warning signs:** None — this is expected behavior for pre-existing data.

### Pitfall 7: Phoenix.Token signing needs Endpoint reference
**What goes wrong:** `Phoenix.Token.sign/4` raises because no Endpoint module is available inside a protocol module.
**Why it happens:** `Phoenix.Token.sign(endpoint, salt, data)` requires the Endpoint module or the `secret_key_base` directly.
**How to avoid:** Retrieve `secret_key_base` via `Application.get_env(:lockspire, Endpoint, [])[:secret_key_base]` or accept it as a parameter from the controller (which has access to `conn.secret_key_base`). Alternatively, use `Plug.Crypto.MessageVerifier` directly with a configured secret. The controller layer is the right place to call `Phoenix.Token`.
**Warning signs:** `ArgumentError: no secret_key_base` at runtime.

---

## OIDC RP-Initiated Logout Specification Summary

**Standard:** OpenID Connect RP-Initiated Logout 1.0 [CITED: openid.net/specs/openid-connect-rpinitiated-1_0.html]

### Required Parameters
| Parameter | Required | Notes |
|-----------|----------|-------|
| `id_token_hint` | RECOMMENDED | Previously issued ID token passed as hint; validate signature, tolerate expiry |
| `logout_hint` | OPTIONAL | Out of scope for Phase 38 |
| `client_id` | OPTIONAL | Required if no `id_token_hint` to identify client |
| `post_logout_redirect_uri` | OPTIONAL | Must be pre-registered; exact match |
| `state` | OPTIONAL | Opaque value passed back with post-logout redirect |
| `ui_locales` | OPTIONAL | Out of scope for Phase 38 |

### Behavior Matrix (per CONTEXT.md decisions)

| id_token_hint | post_logout_redirect_uri | client_id | Behavior |
|--------------|--------------------------|-----------|----------|
| Present, valid | Present, registered | — | Revoke tokens by sid, redirect to host, then to redirect URI |
| Present, valid | Absent or unregistered | — | Revoke tokens by sid, redirect to host, then show logged-out page |
| Absent | Present, registered | client_id needed | No sid revocation, redirect to host, then to redirect URI |
| Absent | Absent | — | No sid revocation, redirect to host, then show logged-out page |
| Present, invalid sig | — | — | Reject with appropriate error |
| Both id_token_hint and client_id | — | client_id not in aud | Reject: D-20 |

### Discovery Fields to Add

```json
{
  "end_session_endpoint": "https://example.test/lockspire/end_session",
  "backchannel_logout_supported": false,
  "frontchannel_logout_supported": false
}
```

---

## Runtime State Inventory

This is a schema migration phase, not a rename/refactor phase. No runtime state inventory is needed beyond the database migration itself. The migration adds nullable columns to existing tables; existing rows are unaffected. No stored data migration is required.

**Nothing found in category:** verified by codebase inspection.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Migration, revoke_by_sid query | Assumed available (project runs on Postgres) [ASSUMED] | — | — |
| Elixir/Mix | Migration, tests | ✓ (implied by active development) [ASSUMED] | — | — |
| JOSE | id_token_hint signature verification | ✓ [VERIFIED: mix.exs] | ~> 1.11 | — |

No blocking missing dependencies. All required libraries are in `mix.exs`.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/lockspire/protocol/end_session_test.exs -x` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SLO-01 | sid generated at interaction creation | unit | `mix test test/lockspire/protocol/authorization_flow_test.exs -x` | ✅ (extend existing) |
| SLO-01 | sid denormalized onto issued tokens | unit | `mix test test/lockspire/storage/ecto/repository_test.exs -x` | ✅ (extend existing) |
| SLO-01 | sid emitted as OIDC claim in ID tokens | unit | `mix test test/lockspire/protocol/id_token_test.exs -x` | ✅ (extend existing) |
| SLO-01 | revoke_by_sid/1 marks active tokens revoked | unit | `mix test test/lockspire/storage/ecto/repository_test.exs -x` | ✅ (extend existing) |
| SLO-02 | /end_session accepts GET and POST | unit | `mix test test/lockspire/web/end_session_controller_test.exs -x` | ❌ Wave 0 |
| SLO-02 | id_token_hint signature validated, expiry tolerated | unit | `mix test test/lockspire/protocol/end_session_test.exs -x` | ❌ Wave 0 |
| SLO-02 | post_logout_redirect_uri exact match | unit | `mix test test/lockspire/protocol/end_session_test.exs -x` | ❌ Wave 0 |
| SLO-02 | client_id/aud mismatch rejected | unit | `mix test test/lockspire/protocol/end_session_test.exs -x` | ❌ Wave 0 |
| SLO-02 | host logout redirect issued to logout_path | unit | `mix test test/lockspire/web/end_session_controller_test.exs -x` | ❌ Wave 0 |
| SLO-02 | completion endpoint triggers revoke_by_sid | unit | `mix test test/lockspire/web/end_session_controller_test.exs -x` | ❌ Wave 0 |
| SLO-02 | end_session_endpoint in discovery | unit | `mix test test/lockspire/protocol/discovery_test.exs -x` | ✅ (extend existing) |
| SLO-02 | BCL/FCL discovery flags false | unit | `mix test test/lockspire/protocol/discovery_test.exs -x` | ✅ (extend existing) |
| SLO-02 | Full RP-initiated logout flow end-to-end | integration | `mix test.integration test/integration/phase38_session_logout_e2e_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/lockspire/protocol/end_session_test.exs` — covers SLO-02 protocol validation
- [ ] `test/lockspire/web/end_session_controller_test.exs` — covers SLO-02 HTTP adapter
- [ ] `test/integration/phase38_session_logout_e2e_test.exs` — covers SLO-01 and SLO-02 end-to-end

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Host owns authentication; Lockspire owns protocol |
| V3 Session Management | Yes | `revoke_by_sid/1` revokes all active tokens for the session |
| V4 Access Control | Yes | `post_logout_redirect_uri` exact-match registration check prevents open-redirect |
| V5 Input Validation | Yes | All inbound params validated in `EndSessionProtocol` before any redirect |
| V6 Cryptography | Yes | id_token_hint verified with JOSE (RS256); signed return_to uses Phoenix.Token or Plug.Crypto |

### Known Threat Patterns for OIDC Logout

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Open redirect via unregistered `post_logout_redirect_uri` | Spoofing | Exact match against registered `post_logout_redirect_uris` (D-15) |
| id_token_hint from a different OP / tampered hint | Tampering | Signature verification against Lockspire's own JOSE keys (D-14) |
| Cross-client logout via `client_id` / `id_token_hint` mismatch | Tampering | `client_id` must appear in `aud` claim of the hint (D-20) |
| Replay of signed `return_to` URL | Repudiation | TTL on signed token (Phoenix.Token max_age); single-use is not strictly required but short TTL mitigates |
| Stranding user via validation failure on completion | Denial of Service | D-10: treat validation failure as logout success; always redirect to known safe destination |
| Token enumeration via timing on revoke_by_sid | Information Disclosure | Bulk UPDATE; no per-token response variation |
| Forged `return_to` token redirecting to attacker's completion endpoint | Spoofing | Signed `return_to` token; completion endpoint validates signature before acting |

---

## Open Questions (RESOLVED)

1. **post_logout_redirect_uris column existence in production DB**
   - What we know: The column is declared in `ClientRecord` schema and `changeset/2` already includes it, suggesting it was added to the schema at some point.
   - **RESOLVED:** Planning confirmed via codebase inspection that `post_logout_redirect_uris` is declared in the schema but no dedicated migration exists for it. Wave 0 of the plan verifies DB state before running; if the column already exists (it was added in an earlier base-client migration), no new migration is generated for the clients table. Only `update_changeset/2` and the admin UI gap remain. Plan 04 handles this gap.

2. **signed return_to: Phoenix.Token vs custom JOSE HMAC**
   - What we know: No signed URL infrastructure exists yet. Phoenix.Token is available via the Phoenix dep. Plug.Crypto is also available.
   - **RESOLVED:** Plan 03 uses `Phoenix.Token.sign(conn, "lockspire_logout", payload, max_age: 600)` in the controller (conn is always available there; no protocol-layer signing needed). The completion endpoint calls `Phoenix.Token.verify(conn, "lockspire_logout", token, max_age: 600)`. This is the idiomatic Phoenix approach and avoids the `secret_key_base` availability pitfall (Pitfall 7).

3. **AccountResolver callback extension approach**
   - What we know: `AccountResolver` is a `@behaviour` with four callbacks. Adding a new `@callback redirect_for_logout/2` is a breaking change for existing implementations.
   - **RESOLVED:** Plan 03 uses `@optional_callbacks [redirect_for_logout: 2]`. Existing host implementations compile without error. The controller includes a `function_exported?/3` guard: if the host has not implemented the optional callback, the controller falls back to `Config.logout_path()` with `return_to` as a query param. This satisfies D-13 without breaking existing hosts. The generated host template in Plan 04 includes the stub implementation so new installs get it wired by default.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `post_logout_redirect_uris` DB column already exists (was added with the base client schema) | Pitfall 1, Open Questions | Migration would fail if column doesn't exist and plan skips its creation |
| A2 | `Phoenix.Token` is available as `Phoenix.Token.sign/4` via the `phoenix ~> 1.8.5` dep | Pattern 8, Security Domain | Would need alternative signing approach (Plug.Crypto.MessageVerifier) |
| A3 | `@optional_callbacks` is the correct mechanism for non-breaking AccountResolver extension | Open Question 3 | If not used, adding callback breaks all existing host implementations at compile time |

---

## Sources

### Primary (HIGH confidence)
- Codebase: `lib/lockspire/storage/ecto/client_record.ex` — `post_logout_redirect_uris` field already in schema + changeset [VERIFIED: read file]
- Codebase: `lib/lockspire/storage/ecto/repository.ex` — `revoke_token_family/1` pattern for `revoke_by_sid/1` [VERIFIED: read file]
- Codebase: `lib/lockspire/protocol/jar.ex` — JOSE.JWT.verify_strict pattern for id_token_hint validation [VERIFIED: read file]
- Codebase: `lib/lockspire/protocol/id_token.ex` — existing claim emission pattern for `sid` addition [VERIFIED: read file]
- Codebase: `lib/lockspire/protocol/discovery.ex` — endpoint metadata pattern for `end_session_endpoint` addition [VERIFIED: read file]
- Codebase: `lib/lockspire/config.ex` + `lib/lockspire/security/policy.ex` — startup config validation pattern for `logout_path` [VERIFIED: read file]
- Codebase: `lib/lockspire/web/live/admin/clients_live/form_component.ex` — redirect_uris textarea pattern for `post_logout_redirect_uris` [VERIFIED: read file]
- Codebase: `lib/lockspire/storage/token_store.ex` — existing TokenStore callbacks pattern [VERIFIED: read file]
- CONTEXT.md D-01 through D-24 [VERIFIED: read file]

### Secondary (MEDIUM confidence)
- [CITED: openid.net/specs/openid-connect-rpinitiated-1_0.html] — parameter semantics, GET+POST requirement, id_token_hint expiry tolerance
- [CITED: openid.net/specs/openid-connect-backchannel-1_0.html] — `sid` claim semantics for BCL compatibility (Phase 39)

### Tertiary (LOW confidence)
- Phoenix.Token API shape — assumed available at `Phoenix.Token.sign/4` with `max_age` option [ASSUMED]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified in mix.exs
- Architecture: HIGH — patterns verified by reading all key implementation files
- Pitfalls: HIGH — identified from direct code inspection of changeset patterns and existing token revocation
- OIDC spec compliance: MEDIUM — spec summarized from training knowledge (cited source), not verified via live fetch this session

**Research date:** 2026-04-29
**Valid until:** 2026-06-15 (stable OIDC spec; Phoenix/Ecto versions stable)
