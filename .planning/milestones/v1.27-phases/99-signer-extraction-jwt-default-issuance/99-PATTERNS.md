# Phase 99: Signer Extraction + JWT-Default Issuance - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 13 (1 new module, 1 new migration, 11 modified)
**Analogs found:** 12 / 13 (1 net-new module with extraction-source + precedence-template analogs)

> All line numbers verified against the live codebase on 2026-05-28. Per RESEARCH.md these are stable but `token_exchange.ex` / `rfc8693_exchange.ex` line refs should be re-confirmed if those files change before execution. The planner MUST also read 99-RESEARCH.md "Common Pitfalls" — five of these patterns have a non-obvious twist (return-shape, aud string-vs-list carve-out, refresh `sub` source, discovery gating, Ecto.Enum/text pairing).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/access_token_signer.ex` | service (protocol core) | transform (token → signed/opaque) | `rfc8693_exchange.ex:317-399` (extraction source) + `security_profile.ex:29-59` (precedence) | exact (assembled from two precedents) |
| `lib/lockspire/protocol/rfc8693_exchange.ex` | service (protocol core) | transform | self (remove `sign_jwt_access_token/6` body, call shared signer) | self-refactor |
| `lib/lockspire/protocol/token_exchange.ex` | service (protocol core) | request-response (AC/device/CIBA mint) | self (`build_access_token/6:1387-1418`) + `validate_requested_resources/2:661` | self-refactor + role-match |
| `lib/lockspire/protocol/refresh_exchange.ex` | service (protocol core) | request-response (rotation mint) | self (`build_rotated_access_token/6:291-310`) | self-refactor |
| `lib/lockspire/protocol/discovery.ex` | service (metadata) | request-response | self (`id_token_signing_alg_values_supported`, `discovery.ex:95`) | self, exact sibling |
| `lib/lockspire/domain/server_policy.ex` | model (plain struct) | n/a (state) | self (`security_profile`/`dpop_policy` fields) | self, exact sibling |
| `lib/lockspire/storage/ecto/server_policy_record.ex` | model (Ecto schema) | CRUD | self (`security_profile` Ecto.Enum, `server_policy_record.ex:17-20`) | self, exact sibling |
| `lib/lockspire/domain/client.ex` | model (plain struct) | n/a (state) | self (`id_token_signed_response_alg`, `client.ex:50,112`) | self, exact sibling |
| `lib/lockspire/storage/ecto/client_record.ex` | model (Ecto schema) | CRUD | self (`id_token_signed_response_alg`, `client_record.ex:57,129,218,288`) | self, exact sibling |
| `lib/lockspire/admin/clients.ex` | service (context) | transform (normalize) | self (`normalize_dpop_policy:575` + `normalize_authorization_signing_alg:611`) | self, hybrid of two siblings |
| `lib/lockspire/admin/server_policy.ex` | service (context) | CRUD | self (`put_dpop_policy/1`, `server_policy.ex:55-63`) | self, exact sibling |
| `lib/lockspire/web/live/admin/clients_live/form_component.ex` | component (LiveView) | request-response (form) | self (`dpop_policy` select `:95-106` + `defaults_for(:edit):406-416` + nil-guard `:427-429`) | self, exact sibling |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | component (LiveView) | request-response (display) | self (security-profile trio `:169-171`) | self, exact sibling |
| `priv/repo/migrations/<ts>_add_access_token_format.exs` | migration | CRUD (schema) | `20260430151849_add_security_profile_to_clients_and_policies.exs` | exact |

---

## Pattern Assignments

### `lib/lockspire/protocol/access_token_signer.ex` (NEW — service, transform)

**Analogs:** `rfc8693_exchange.ex:317-399` (extraction source for the `:jwt` branch + key fetch); `security_profile.ex:29-59` (format-resolution precedence); `token_formatter.ex:13-27` (`:opaque` branch delegate + `hash_token/1`).

This module is the phase's single new file. It is **assembled** from existing precedents — it is not greenfield. Public shape per D-01: `issue(%Token{}, %Client{}, request) :: {:ok, raw, hash}` (`issue/3` suggested).

**`:jwt` signing block to extract wholesale** (`rfc8693_exchange.ex:317-348`):
```elixir
defp sign_jwt_access_token(client, subject_token, scopes, issued_at, custom_claims, request) do
  case fetch_signing_key(request) do
    {:ok, %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}} ->
      {:ok, jwk_map} = decode_private_jwk(private_jwk)
      jti = TokenFormatter.format_access_token(token_format_options(request)).token

      base_claims = %{
        "iss" => Config.issuer!(),
        "sub" => subject_token.account_id,
        "aud" => client.client_id,            # <-- RFC 8693 STRING carve-out (Pitfall 3)
        "exp" => DateTime.add(issued_at, 3600, :second) |> DateTime.to_unix(),
        "iat" => DateTime.to_unix(issued_at),
        "client_id" => client.client_id,
        "jti" => jti,
        "scope" => Enum.join(scopes, " ")
      }

      restricted = ~w(iss sub aud exp iat jti client_id)
      claims = Map.merge(base_claims, Map.drop(custom_claims, restricted))

      {_, compact} =
        JOSE.JWT.sign(JOSE.JWK.from_map(jwk_map),
          %{"alg" => alg, "kid" => kid, "typ" => "at+jwt"}, claims)
        |> JOSE.JWS.compact()

      {:ok, compact, Policy.hash_token(compact)}
    {:error, reason} -> # ...500 :token_signing_failed (see error path below)...
  end
end
```
**Generalize for the shared signer (D-03):** `sub` from `%Token{}.account_id`, `scope` from `Enum.join(%Token{}.scopes, " ")`, `aud` from `derive_aud/2` (below), and ADD `cnf` from `%Token{}.cnf` when non-nil (Phase 100 carry-through — `cnf` is dropped today, must be propagated). Custom-claim merge with the `~w(iss sub aud exp iat jti client_id)` drop stays ONLY on the exchange path.

**Key fetch + JWK decode to move with the signer** (`rfc8693_exchange.ex:363-399`):
```elixir
defp fetch_signing_key(request) do
  key_store =
    request |> Map.get(:opts, []) |> Keyword.get(:key_store, Config.repo!())
  case key_store.fetch_active_signing_key() do
    {:ok, %{alg: alg, private_jwk_encrypted: private_jwk} = key}
    when is_binary(private_jwk) and is_binary(alg) -> {:ok, key}
    {:ok, nil} -> {:error, :signing_key_not_found}
    {:ok, _key} -> {:error, :invalid_signing_key}
    {:error, _reason} -> {:error, :signing_key_lookup_failed}
  end
end

defp decode_private_jwk(binary) when is_binary(binary) do
  case Jason.decode(binary) do
    {:ok, %{} = jwk} -> {:ok, jwk}
    _other -> decode_erlang_jwk(binary)   # Plug.Crypto.non_executable_binary_to_term(binary, [:safe])
  end
end
```
Per Claude's discretion (D-02): move these wholesale OR into a shared helper both modules call — provided no JOSE-sign logic stays duplicated.

**Error path to preserve** (`rfc8693_exchange.ex:350-359`) — missing/invalid key returns the existing 500:
```elixir
{:error, reason} ->
  Logger.error("Failed to sign token exchange JWT: #{inspect(reason)}")
  {:error, %Error{status: 500, error: "server_error",
     error_description: "Unable to sign access token.",
     reason_code: :token_signing_failed}}
```
SECURITY (AGENTS.md): no key material in logs; `alg`/`kid` pinned from the active key only; never `alg=none`.

**Format-resolution precedence — copy `security_profile.ex:29-59` shape, adapt `:inherit` → `nil`** (D-05). The template:
```elixir
# security_profile.ex:53-59 (VERIFIED) — the per-client-override → global → default idiom
defp effective_profile(global_profile, :inherit), do: global_profile
defp effective_profile(_global_profile, :fapi_2_0_message_signing), do: :fapi_2_0_message_signing
defp effective_profile(_global_profile, :fapi_2_0_security), do: :fapi_2_0_security
defp effective_profile(_global_profile, :none), do: :none
```
Adapted for `access_token_format` (branch on `nil`, NOT `:inherit` — D-06 uses a nullable column):
```elixir
defp resolve_format(%Client{access_token_format: fmt}, _server_policy)
     when fmt in [:jwt, :opaque], do: fmt
defp resolve_format(%Client{access_token_format: nil},
       %ServerPolicy{access_token_format: server_fmt}), do: server_fmt || :jwt
```
The signer reads `ServerPolicy` itself via `request.opts[:server_policy_store]` (= `Repository`, set at `token_controller.ex`) so all five call sites stay one line (RESEARCH A1).

**`:opaque` branch — delegate to TokenFormatter** (`token_formatter.ex:13-15` + `hash_token/1:22-27`):
```elixir
formatted = TokenFormatter.format_access_token(token_format_options(request))
{:ok, formatted.token, formatted.token_hash}   # same shape as rfc8693_exchange.ex:309-310
```
Note `Policy.hash_token/1` and `TokenFormatter.hash_token/1` are identical SHA-256 hex (RESEARCH A4) — pick ONE and use it for both branches.

**Audience derivation — D-08 + Pitfall 3 carve-out** (the one genuinely novel bit). The list form for AC/refresh/device/CIBA:
```elixir
defp derive_aud([], client_id), do: [client_id]                      # AUD-02
defp derive_aud(audience, _client_id) when audience != [], do: audience  # AUD-01: [resource]
```
The RFC 8693 no-resource path keeps `aud = client.client_id` as a **bare string** (matches `rfc8693_exchange.ex:327` and the regression sentinel `rfc8693_exchange_test.exs:192`: `assert payload["aud"] == client.client_id`). Per RESEARCH Open Question 2 / Claude's discretion: a shared `sign/4` core (jwk, header, claims) with two thin callers (one assembling a list `aud`, one a string `aud`) keeps JOSE-sign single-sourced while honoring the carve-out.

---

### `lib/lockspire/protocol/rfc8693_exchange.ex` (MODIFY — service, transform)

**Analog:** self. Replace the body of `sign_jwt_access_token/6` (`:317-361`) — and move `fetch_signing_key/1` + `decode_private_jwk/1` + `decode_erlang_jwk/1` (`:363-399`) — into `AccessTokenSigner`. The exchange-path entry `sign_or_format_access_token/6` (`:299-315`) routes both its `nil`-claims (opaque) and custom-claims (JWT) branches through the shared module. KEEP the custom-claim merge + the **string** `aud` carve-out here (or pass it as the signer's exchange-path mode). After this, no JOSE-sign logic remains in this file (ROADMAP criterion #5).

---

### `lib/lockspire/protocol/token_exchange.ex` (MODIFY — service, request-response; AC + device + CIBA)

**Analog:** self. Two distinct edits per RESEARCH Pitfall 1 and Pitfall 2.

**(a) Mint-seam swap — `build_access_token/6` (`:1387-1418`).** NOT a literal one-liner (Pitfall 1): the seam returns `{%Token{}, raw}`, not `{:ok, raw, hash}`. Today (`:1397-1417`):
```elixir
formatted_access_token = TokenFormatter.format_access_token(token_format_options(request, :access_token))
access_token = %Token{
  token_hash: formatted_access_token.token_hash,   # <-- re-point this to signer's hash
  token_type: :access_token, family_id: family_id, generation: 0,
  client_id: client.client_id, account_id: authorization_code.account_id,
  ...
  scopes: authorization_code.scopes,
  audience: authorization_code.audience,           # <-- signer reads this for aud (D-08)
  cnf: issuance_context.cnf,                        # <-- signer carries this to JWT (Phase 100)
  issued_at: issued_at, expires_at: DateTime.add(issued_at, @access_token_ttl, :second)
}
{access_token, formatted_access_token.token}
```
Swap: call `AccessTokenSigner.issue(token, client, request)` → `{:ok, raw, hash}`; set `%Token{... token_hash: hash}`; keep returning `{access_token, raw}` (preserve the 2-tuple internal contract so persistence + `build_success_response/8` are unaffected). The persisted `%Token{}.token_hash` MUST equal `hash-of-returned-token` or `/introspect`/revocation lookups break.

**(b) Device/CIBA resource threading — NET-NEW (Pitfall 2, D-09).** AC already threads resource (`redeem_code:702-710` sets `%Token{authorization_code | audience: requested_resources}`). Device (`build_device_grant:945-958`) and CIBA (`build_ciba_grant:799-812`) hardcode `audience: []` and never validate resource. The AC validator to mirror (`validate_requested_resources/2:661-689`):
```elixir
defp validate_requested_resources(params, %Token{} = authorization_code) do
  requested = params |> Map.get("resource") |> List.wrap()
              |> Enum.flat_map(fn r when is_binary(r) -> [r]; _ -> [] end)
  authorized = authorization_code.audience
  cond do
    requested == [] -> {:ok, authorized}
    Enum.all?(requested, &(&1 in authorized)) -> {:ok, requested}
    true -> {:error, oauth_error(400, "invalid_target",
              "The requested resource is invalid or was not authorized", :invalid_resource)}
  end
end
```
In `redeem_device_grant/5` (`:970-988`) and `redeem_ciba_grant/5` (`:824-842`), extract `resource` from `params` and validate against the grant's authorized audience BEFORE `build_access_token`, then set `%Token{audience: validated}`. AUD-01 verification MUST exercise a `resource=`-scoped device flow AND a `resource=`-scoped CIBA flow (not AC/refresh alone).

---

### `lib/lockspire/protocol/refresh_exchange.ex` (MODIFY — service, request-response; rotation)

**Analog:** self. `build_rotated_access_token/6` (`:291-310`) already threads resource into `audience` (`:306 audience: requested_resources`) and carries `cnf` (`:307`). Two edits:
1. Swap the `TokenFormatter.format_access_token(...)` mint in `format_refresh_rotation_tokens/1` (`:284-289`) / re-point `token_hash` (`:300`) to the signer's `hash` (Pitfall 1).
2. **Refresh `sub` source — Pitfall 5.** `build_rotated_access_token` sets `account_id: nil` (`:303`). The signer derives `sub` from `%Token{}.account_id`, so a `nil` `account_id` yields `sub: nil` → fails the Phase 98 verifier's `:missing_sub`. Fix: populate the rotated token's `account_id` from `presented_refresh_token.account_id` before calling the signer.

---

### `lib/lockspire/protocol/discovery.ex` (MODIFY — service, metadata)

**Analog:** self — the `id_token_signing_alg_values_supported` sibling (`:95`), which sits in the **static, unconditional** map block (Pitfall 4). Add the new key in `openid_configuration/0` (`:86-96`) alongside it:
```elixir
%{
  "issuer" => issuer,
  ...
  "id_token_signing_alg_values_supported" => id_token_signing_alg_values_supported(),
  "access_token_signing_alg_values_supported" => ["RS256", "ES256", "PS256"]  # <-- D-11, literal
}
```
Do NOT reuse `SecurityProfile.allowed_signing_algorithms/1` (it returns `["RS256","ES256","PS256","EdDSA"]` for `:none` and `["ES256","PS256"]` under FAPI — `security_profile.ex:62-64`). Do NOT gate on `token_endpoint` mounting — the true sibling is unconditional (Pitfall 4 corrects D-11's phrasing).

---

### `lib/lockspire/domain/server_policy.ex` (MODIFY — model)

**Analog:** self — the `dpop_policy`/`security_profile` fields. Add a type + struct default mirroring `:6-8` / `:31-35`:
```elixir
@type access_token_format :: :jwt | :opaque
# in @type t: access_token_format: access_token_format(),
# in defstruct: access_token_format: :jwt,
```
Default `:jwt` (FORMAT-01). Thread through the record's `changeset/2` cast + `validate_required` + `to_domain/1` (next file).

---

### `lib/lockspire/storage/ecto/server_policy_record.ex` (MODIFY — model, CRUD)

**Analog:** self — `security_profile` Ecto.Enum (`:17-20`). Add the field, the cast list entry, the `validate_required` entry, and the `to_domain/1` mapping:
```elixir
# schema (mirror :17-20)
field(:access_token_format, Ecto.Enum, values: [:jwt, :opaque], default: :jwt)
# changeset/2 cast list (:51-67) — add :access_token_format
# validate_required (:68-74) — add :access_token_format
# to_domain/1 (:81-103) — add: access_token_format: record.access_token_format,
```
Pitfall 6: this Ecto.Enum MUST pair with a `:text` column in the migration or `:jwt` pattern-matches silently fail (value is the string `"jwt"`). Comment idiom for the new field mirrors the `:22-24` note.

---

### `lib/lockspire/domain/client.ex` (MODIFY — model)

**Analog:** self — `id_token_signed_response_alg` (`:50` in `@type t`, `:112` in `defstruct`). Add:
```elixir
@type access_token_format :: :jwt | :opaque
# @type t: access_token_format: access_token_format() | nil,   (mirror :50)
# defstruct: access_token_format: nil,                         (mirror :112)
```
`nil` is the inherit state (D-06) — NO `:inherit` sentinel.

---

### `lib/lockspire/storage/ecto/client_record.ex` (MODIFY — model, CRUD)

**Analog:** self — `id_token_signed_response_alg` threaded record→changeset→update_changeset→to_domain (the field-for-field worked example, D-06). FOUR edits:
```elixir
# 1. schema field (mirror :57)
field(:access_token_format, Ecto.Enum, values: [:jwt, :opaque])   # no default -> nil = inherit
# 2. changeset/2 cast list (:106-162) — add :access_token_format alongside :id_token_signed_response_alg (:129)
# 3. update_changeset/2 cast list (:200-234) — MUST add here too (admin-mutable path, alongside :218)
# 4. to_domain/1 (:263+) — add: access_token_format: record.access_token_format,  (alongside :288)
```
CRITICAL: must be in BOTH `changeset/2` AND `update_changeset/2` — the admin UI mutates via `update_changeset/2`. Do NOT add to `validate_required` (nullable). No FAPI-validation coupling needed (unlike `id_token_signed_response_alg` at `validate_fapi_metadata/1:247-261`).

---

### `lib/lockspire/admin/clients.ex` (MODIFY — service, transform)

**Analog:** self — HYBRID of `normalize_dpop_policy/1` (`:575-590`, the `inherit` option idiom) and `normalize_authorization_signing_alg/1` (`:611-631`, the `nil`/`""` → `{:ok, nil}` cast). Two edits:

1. Add `access_token_format` to `@mutable_fields` (`:14-33`).
2. Add a `normalize_mutable_field(:access_token_format, value)` clause in the `:472-524` region (mirror the `:dpop_policy` dispatch at `:484-489`) backed by a new `normalize_access_token_format/1`:
```elixir
# dispatch (mirror :484-489)
defp normalize_mutable_field(:access_token_format, value) do
  case normalize_access_token_format(value) do
    {:ok, fmt} -> fmt
    :error -> value
  end
end

# helper — HYBRID: inherit/nil -> nil (like :611-612), jwt/opaque -> atom (like :575-577)
defp normalize_access_token_format(nil), do: {:ok, nil}
defp normalize_access_token_format(:jwt), do: {:ok, :jwt}
defp normalize_access_token_format(:opaque), do: {:ok, :opaque}
defp normalize_access_token_format(value) when is_binary(value) do
  case String.trim(value) do
    "inherit" -> {:ok, nil}     # inherit -> nil (D-06, NO :inherit sentinel)
    "" -> {:ok, nil}
    "jwt" -> {:ok, :jwt}
    "opaque" -> {:ok, :opaque}
    _other -> :error
  end
end
defp normalize_access_token_format(_value), do: :error
```

---

### `lib/lockspire/admin/server_policy.ex` (MODIFY — service, CRUD)

**Analog:** self — `put_dpop_policy/1` (`:55-63`). Add the runtime setter (RESEARCH Open Question 1: ship the context fn in Phase 99; defer a dedicated `policies_live` page unless the user wants it):
```elixir
@spec put_access_token_format(atom() | String.t()) ::
        {:ok, ServerPolicy.t()} | {:error, [error_detail()]} | {:error, term()}
def put_access_token_format(format) do
  with {:ok, normalized} <- normalize_access_token_format(format) do  # add this normalizer (mirror :592-609)
    Repository.update_server_policy(fn %ServerPolicy{} = current ->
      %ServerPolicy{current | access_token_format: normalized}
    end)
  end
end
```
For the server-wide setter the value is `:jwt | :opaque` (NOT nullable — server default always concrete). Add a `normalize_access_token_format/1` here mirroring `normalize_dpop_policy/1` minus the nil branch.

---

### `lib/lockspire/web/live/admin/clients_live/form_component.ex` (MODIFY — component, LiveView form)

**Analog:** self — the `dpop_policy` `<select>` (`:95-106`), `defaults_for(:edit, ...)` (`:406-416`), and the nil-guard idiom at `:427-429`. See 99-UI-SPEC.md for locked copy. Two edits:

1. Add the `<select>` immediately after `dpop_policy` (`:106`), edit-mode gated, param `client[access_token_format]` (mirror `:95-106`):
```elixir
<label :if={@mode == :edit} for="client_access_token_format">Access token format override</label>
<select :if={@mode == :edit} id="client_access_token_format" name="client[access_token_format]">
  <option value="inherit" selected={@defaults.access_token_format == "inherit"}>Inherit from server default</option>
  <option value="jwt" selected={@defaults.access_token_format == "jwt"}>JWT (RFC 9068 at+jwt)</option>
  <option value="opaque" selected={@defaults.access_token_format == "opaque"}>Opaque (Lockspire-stored)</option>
</select>
<div class="lockspire-admin-help">
  <p>JWT (at+jwt) is the default and is what host Phoenix API routes verify. ...</p>
  <a href="docs/protect-phoenix-api-routes.md">Learn when to choose JWT vs opaque</a>
</div>
```
LOCKED: option values `inherit/jwt/opaque`, the `inherit`→`nil` cast, the doclink target. Copy is Claude's discretion (UI-SPEC supplies it).

2. Extend `defaults_for(:edit, client)` (`:406-416`). UNLIKE `dpop_policy` (`:409` plain `Atom.to_string` — never nil), `access_token_format` stores `nil`, so use a nil-aware helper modeled on the `authorization_signed_response_alg` nil-guard (`:427-429`): `nil → "inherit"`, `:jwt → "jwt"`, `:opaque → "opaque"`:
```elixir
access_token_format: format_default_for_select(client.access_token_format)
# defp format_default_for_select(nil), do: "inherit"
# defp format_default_for_select(fmt), do: Atom.to_string(fmt)
```

---

### `lib/lockspire/web/live/admin/clients_live/show.ex` (MODIFY — component, LiveView display)

**Analog:** self — the security-profile global/override/effective trio (`:169-171`). Add three `<p>` rows alongside it; render the `nil` override as `inherit` using a nil-guard modeled on `value_or_not_configured/1` (`:660-661`) but emitting `"inherit"` not `"Not configured"`:
```elixir
# mirror :169-171 exactly (<code> for global/override, <strong> for effective)
<p>Global access token format: <code>{@global_access_token_format}</code></p>
<p>Client access token override: <code>{access_token_format_label(@client.access_token_format)}</code></p>
<p>Effective access token format: <strong>{@effective_access_token_format}</strong></p>
# defp access_token_format_label(nil), do: "inherit"
# defp access_token_format_label(fmt), do: to_string(fmt)
```
The effective value uses the same per-client → server-default → `:jwt` resolution as the signer (assign it in `mount`/`handle_params` reading `ServerPolicy.access_token_format`). Do NOT borrow the `lockspire-admin-warning` block (`:194-203`) — `access_token_format` is a reversible, non-destructive override (UI-SPEC Color section).

---

### `priv/repo/migrations/<ts>_add_access_token_format.exs` (NEW — migration, CRUD)

**Analog:** `20260430151849_add_security_profile_to_clients_and_policies.exs` (the dual-table `:text` add precedent):
```elixir
defmodule Lockspire.TestRepo.Migrations.AddSecurityProfileToClientsAndPolicies do
  use Ecto.Migration
  def change do
    alter table(:lockspire_clients) do
      add :security_profile, :text, null: false, default: "inherit"
    end
    alter table(:lockspire_server_policies) do
      add :security_profile, :text, null: false, default: "none"
    end
  end
end
```
Adapt (D-04/D-06, Pitfall 6 — `:text` columns to pair with the `Ecto.Enum` fields):
```elixir
alter table(:lockspire_clients) do
  add :access_token_format, :text                        # NULLABLE, no default (nil = inherit)
end
alter table(:lockspire_server_policies) do
  add :access_token_format, :text, null: false, default: "jwt"   # singleton backfilled to "jwt"
end
```
Per RESEARCH Runtime State: the existing `lockspire_server_policies` singleton (`@singleton_id 1`) is backfilled to `"jwt"` by the column default; existing `lockspire_clients` rows become `NULL` = inherit = the new default. No row rewrite. Filename timestamp must sort after `20260525143000_...` (the latest existing migration).

---

## Shared Patterns

### Format-policy resolution (one place)
**Source:** `lib/lockspire/protocol/security_profile.ex:29-59` (`resolve_effective_profile/2`)
**Apply to:** `AccessTokenSigner` ONLY (D-05). Adapt the `:inherit`-atom branch to `nil`-branch. Do NOT replicate this resolution at call sites or in `show.ex` beyond a thin read for display.

### Token hashing (one convention)
**Source:** `lib/lockspire/protocol/token_formatter.ex:22-27` (`hash_token/1`); identical `Policy.hash_token/1`
**Apply to:** Both signer branches; the persisted `%Token{}.token_hash` at all five mint seams. SHA-256 hex. The stored hash MUST equal `hash-of-issued-token` (Pitfall 1) or revocation/introspection by hash breaks.

### `request.opts` accessor convention
**Source:** `rfc8693_exchange.ex:363-367` (`request |> Map.get(:opts, []) |> Keyword.get(:key_store, Config.repo!())`); controller assembly at `token_controller.ex` sets `key_store`, `server_policy_store`, `now`
**Apply to:** The signer reads `key_store` (signing key) and `server_policy_store` (format default) the same way.

### Per-client nullable Ecto.Enum plumbing
**Source:** `client_record.ex` `id_token_signed_response_alg` (`:57` schema, `:129` changeset, `:218` update_changeset, `:288` to_domain) + `domain/client.ex:50,112`
**Apply to:** `access_token_format` field-for-field. Cardinal rule: BOTH changesets, nullable, no DB default, no `validate_required`.

### Runtime ServerPolicy Ecto.Enum (with default)
**Source:** `server_policy_record.ex:17-20` (`security_profile`) + `domain/server_policy.ex:8,34`
**Apply to:** the server-wide `access_token_format` (default `:jwt`, NOT nullable).

### Admin override `<select>` + normalize + display idiom
**Source:** `form_component.ex:95-106` (`dpop_policy` select), `:406-416`/`:427-429` (`defaults_for` + nil-guard); `admin/clients.ex:484-489` (`normalize_mutable_field` dispatch) + `:575-590`/`:611-631` (the two normalizer shapes); `show.ex:169-171` (display trio)
**Apply to:** the per-client override surface. HYBRID: select idiom from `dpop_policy`, `inherit→nil` cast from `authorization_signed_response_alg`. `nil` renders as `inherit`. See 99-UI-SPEC.md Anti-Drift Checklist.

### JOSE signing (never hand-roll)
**Source:** `rfc8693_exchange.ex:340-346` (`JOSE.JWT.sign/3` + `JOSE.JWS.compact/1`)
**Apply to:** the signer's `:jwt` branch. Header pins `alg`+`kid` from the active key; `typ: "at+jwt"`; no `alg=none` (AGENTS.md). Phase 98 verifier (`verify_token.ex`) accepts exactly this.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | — | — | All thirteen files have a strong precedent. The new `AccessTokenSigner` is the only net-new module, and it is assembled from two exact precedents (the `rfc8693_exchange.ex` signing block + the `security_profile.ex` precedence resolver), so it is a "construct-from-precedents" file rather than a "no-analog" file. |

The only genuinely novel logic (no copy-paste analog, must be written fresh) per RESEARCH "Key insight": (a) the signer's `aud` string-vs-list carve-out, (b) device/CIBA net-new resource validation+threading (reuses `validate_requested_resources/2`'s shape), (c) the refresh `sub`-from-presented-token fix. The planner should size these three as real implementation, not propagation.

## Metadata

**Analog search scope:** `lib/lockspire/protocol/`, `lib/lockspire/domain/`, `lib/lockspire/storage/ecto/`, `lib/lockspire/admin/`, `lib/lockspire/web/live/admin/clients_live/`, `priv/repo/migrations/`
**Files scanned (read):** 18 (CONTEXT, RESEARCH, UI-SPEC, AGENTS.md, + 14 source/analog files; Token domain field check)
**Project conventions:** AGENTS.md security defaults (no `alg=none`, strong redaction); no CLAUDE.md at root; no `.claude/skills` or `.agents/skills` present
**Pattern extraction date:** 2026-05-28
