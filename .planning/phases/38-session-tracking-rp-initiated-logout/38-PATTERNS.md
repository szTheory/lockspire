# Phase 38: Session Tracking & RP-Initiated Logout - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 20 new/modified files
**Analogs found:** 20 / 20

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/repo/migrations/*_add_sid_to_lockspire_interactions.exs` | migration | batch | `priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs` | exact |
| `priv/repo/migrations/*_add_sid_to_lockspire_tokens.exs` | migration | batch | `priv/repo/migrations/20260428153000_add_dpop_policy_fields.exs` | exact |
| `priv/repo/migrations/*_add_post_logout_redirect_uris_to_clients.exs` | migration | batch | `priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs` | exact |
| `lib/lockspire/storage/ecto/interaction_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/interaction_record.ex` (modify) | exact |
| `lib/lockspire/storage/ecto/token_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/token_record.ex` (modify) | exact |
| `lib/lockspire/storage/ecto/client_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/client_record.ex` (modify) | exact |
| `lib/lockspire/domain/interaction.ex` | model | CRUD | `lib/lockspire/domain/interaction.ex` (modify) | exact |
| `lib/lockspire/domain/token.ex` | model | CRUD | `lib/lockspire/domain/token.ex` (modify) | exact |
| `lib/lockspire/storage/token_store.ex` | service | CRUD | `lib/lockspire/storage/token_store.ex` (modify) | exact |
| `lib/lockspire/storage/ecto/repository.ex` | service | CRUD | `lib/lockspire/storage/ecto/repository.ex` (modify) | exact |
| `lib/lockspire/protocol/id_token.ex` | service | transform | `lib/lockspire/protocol/id_token.ex` (modify) | exact |
| `lib/lockspire/protocol/authorization_flow.ex` | service | request-response | `lib/lockspire/protocol/authorization_flow.ex` (modify) | exact |
| `lib/lockspire/protocol/end_session.ex` | service | request-response | `lib/lockspire/protocol/revocation.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | service | request-response | `lib/lockspire/protocol/discovery.ex` (modify) | exact |
| `lib/lockspire/config.ex` | config | request-response | `lib/lockspire/config.ex` (modify) | exact |
| `lib/lockspire/host/account_resolver.ex` | service | request-response | `lib/lockspire/host/account_resolver.ex` (modify) | exact |
| `lib/lockspire/web/controllers/end_session_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/interaction_controller.ex` | exact |
| `lib/lockspire/web/controllers/end_session_html/logged_out.html.heex` | component | request-response | plain heex — no analog needed | n/a |
| `lib/lockspire/web/live/admin/tokens_live/show.ex` | component | request-response | `lib/lockspire/web/live/admin/tokens_live/show.ex` (modify) | exact |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | component | request-response | `lib/lockspire/web/live/admin/clients_live/show.ex` (modify) | exact |
| `lib/lockspire/web/live/admin/clients_live/form_component.ex` | component | request-response | `lib/lockspire/web/live/admin/clients_live/form_component.ex` (modify) | exact |
| `lib/lockspire/web/router.ex` | route | request-response | `lib/lockspire/web/router.ex` (modify) | exact |
| `priv/templates/lockspire.install/account_resolver.ex` | config | request-response | `priv/templates/lockspire.install/account_resolver.ex` (modify) | exact |
| `test/lockspire/protocol/end_session_test.exs` | test | request-response | existing protocol test files | role-match |
| `test/lockspire/web/end_session_controller_test.exs` | test | request-response | existing controller test files | role-match |

---

## Pattern Assignments

### Migrations

**Analog:** `priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs` (lines 1-11)

All three migrations use `alter table/2` with `add/3`. The `sid` migrations also need `create index/2`:

```elixir
# add_sid_to_lockspire_interactions
defmodule Lockspire.Repo.Migrations.AddSidToLockspireInteractions do
  use Ecto.Migration
  def change do
    alter table(:lockspire_interactions) do
      add :sid, :string
    end
    create index(:lockspire_interactions, [:sid])
  end
end

# add_sid_to_lockspire_tokens
defmodule Lockspire.Repo.Migrations.AddSidToLockspireTokens do
  use Ecto.Migration
  def change do
    alter table(:lockspire_tokens) do
      add :sid, :string
    end
    create index(:lockspire_tokens, [:sid])
  end
end

# add_post_logout_redirect_uris_to_lockspire_clients
# VERIFY COLUMN DOES NOT EXIST FIRST — schema has it but migration may be missing
defmodule Lockspire.Repo.Migrations.AddPostLogoutRedirectUrisToLockspireClients do
  use Ecto.Migration
  def change do
    alter table(:lockspire_clients) do
      add :post_logout_redirect_uris, {:array, :string}, default: []
    end
  end
end
```

`sid` is nullable — application layer guarantees it for new interactions; pre-Phase-38 rows stay `nil`.

---

### `lib/lockspire/storage/ecto/interaction_record.ex`

**Analog:** self (existing file, lines 14-133)

Add `sid` field in schema (after line 38, before `timestamps()`), add `:sid` to the `cast/3` list in `changeset/2` (line 51-76), add `sid: record.sid` to `to_domain/1` (line 97-126). Do NOT add to `update_changeset/2` — sid is set only at insert.

```elixir
# schema block addition (line 38 area):
field(:sid, :string)

# changeset/2 cast list addition:
|> cast(attrs, [
  :interaction_id,
  # ... existing ...
  :sid              # ADD
])

# to_domain/1 addition:
%Interaction{
  # ... existing ...
  sid: record.sid,  # ADD
}
```

---

### `lib/lockspire/storage/ecto/token_record.ex`

**Analog:** self (existing file, lines 1-92) — `interaction_id` denormalization (line 22) is the direct template for `sid`

```elixir
# schema block (after :interaction_id at line 22):
field(:sid, :string)

# changeset/2 cast list (after :interaction_id):
:sid,    # ADD

# to_domain/1:
sid: record.sid,  # ADD
```

---

### `lib/lockspire/storage/ecto/client_record.ex`

**Analog:** self (existing file, lines 133-157) — `post_logout_redirect_uris` is in `changeset/2` and `to_domain/1` already; only `update_changeset/2` needs it

```elixir
# update_changeset/2 cast list addition (line 133-157):
def update_changeset(record, attrs) do
  record
  |> cast(attrs, [
    :name,
    :redirect_uris,
    :post_logout_redirect_uris,   # ADD — missing from update_changeset, present in changeset/2
    :allowed_scopes,
    :logo_uri,
    :tos_uri,
    :policy_uri,
    :contacts,
    :par_policy,
    :dpop_policy,
    :metadata,
    :active,
    :disabled_at,
    :disabled_by,
    :client_secret_hash,
    :last_secret_rotated_at
  ])
  |> validate_required([:redirect_uris, :allowed_scopes, :active])
end
```

---

### `lib/lockspire/domain/interaction.ex`

**Analog:** self (lines 1-67) — `nonce` is the template for nullable string field

```elixir
# @type t() addition (line 10-37):
sid: String.t() | nil,

# defstruct addition (line 39-66, with nil default):
defstruct [
  :id,
  :interaction_id,
  :sid,           # ADD
  # ... rest unchanged
]
```

---

### `lib/lockspire/domain/token.ex`

**Analog:** self (lines 1-59) — `interaction_id` (line 20, 44) is the template for nullable string denormalization

```elixir
# @type t() addition (line 8-31):
sid: String.t() | nil,

# defstruct addition (after interaction_id at line 44):
interaction_id: nil,
sid: nil,         # ADD
```

---

### `lib/lockspire/storage/token_store.ex`

**Analog:** self (lines 1-53) — `revoke_token_family/1` at line 19 is the template

```elixir
# After @callback revoke_token_family/1 at line 19:
@callback revoke_by_sid(String.t()) :: {:ok, non_neg_integer()} | {:error, store_error()}
```

---

### `lib/lockspire/storage/ecto/repository.ex` — `revoke_by_sid/1`

**Analog:** `lib/lockspire/storage/ecto/repository.ex` lines 589-603 (`revoke_token_family/1`)

```elixir
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

Note: added `is_nil(token.redeemed_at)` guard vs `revoke_token_family/1` to exclude consumed auth codes. Otherwise identical shape.

---

### `lib/lockspire/protocol/id_token.ex`

**Analog:** self (lines 17-69) — `auth_time` is the template for optional param via `Map.get`

```elixir
# sign/1 function (line 27-28, add sid extraction via Map.get):
with {:ok, auth_time} <- validate_auth_time(Map.get(params, :auth_time)),
     sid <- Map.get(params, :sid),     # ADD — tolerate nil (pre-Phase-38 callers)
     {:ok, jwk_map} <- decode_private_jwk(private_jwk),
     claims <- build_claims(host_claims, issuer, client_id, nonce, access_token, issued_at, auth_time, sid),

# build_claims/7 -> build_claims/8 (line 45-57, add sid param and claim):
defp build_claims(%Claims{} = host_claims, issuer, client_id, nonce, access_token, issued_at, auth_time, sid) do
  protocol_claims = %{
    "iss" => issuer,
    "aud" => client_id,
    "iat" => DateTime.to_unix(issued_at),
    "exp" => DateTime.add(issued_at, @id_token_ttl, :second) |> DateTime.to_unix(),
    "nonce" => nonce,
    "at_hash" => at_hash(access_token),
    "auth_time" => encode_auth_time(auth_time),
    "sid" => sid    # ADD — nil is stripped by Claims.build_id_token_claims if nil
  }
  Claims.build_id_token_claims(host_claims, protocol_claims)
end
```

---

### `lib/lockspire/protocol/authorization_flow.ex`

**Analog:** self (lines 249-295) — `build_interaction/5` and `issue_authorization_code/3`

```elixir
# build_interaction/5 (line 249-270), add sid field generated at interaction creation:
defp build_interaction(%Validated{} = validated, interaction_id, subject_id, status, now) do
  %Interaction{
    interaction_id: interaction_id,
    sid: generate_sid(),     # ADD per D-02
    client_id: validated.client_id,
    # ... rest unchanged
  }
end

# generate_sid helper (add alongside generate_interaction_id/1):
defp generate_sid do
  :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
end

# issue_authorization_code/3 (line 277-289), thread sid from interaction:
token = %Token{
  token_hash: token_hash,
  token_type: :authorization_code,
  client_id: interaction.client_id,
  account_id: subject_id,
  interaction_id: interaction.interaction_id,
  sid: interaction.sid,       # ADD per D-03
  # ... rest unchanged
}
```

Also thread `sid` in `TokenExchange.exchange_authorization_code` and `rotate_refresh_token` (Pitfall 4 — all token issuance paths need it).

---

### `lib/lockspire/protocol/end_session.ex` (new)

**Analog:** `lib/lockspire/protocol/revocation.ex` (lines 1-200) — same thin protocol module shape: nested Error struct, one public function, private validation pipeline, no HTTP concerns

**Module structure pattern:**
```elixir
defmodule Lockspire.Protocol.EndSession do
  @moduledoc """
  Validates RP-Initiated Logout requests per OIDC RP-Initiated Logout 1.0.
  """
  alias Lockspire.Domain.Client

  defmodule Error do
    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom()
          }
    defstruct [:status, :error, :error_description, :reason_code]
  end

  defmodule Result do
    @type t :: %__MODULE__{
            sid: String.t() | nil,
            account_id: String.t() | nil,
            post_logout_redirect_uri: String.t() | nil,
            state: String.t() | nil
          }
    defstruct [:sid, :account_id, :post_logout_redirect_uri, :state]
  end

  @spec validate(map()) :: {:ok, Result.t()} | {:error, Error.t()}
  def validate(request) when is_map(request) do
    params = Map.get(request, :params, request)
    with {:ok, id_token_claims} <- validate_id_token_hint(params, request),
         {:ok, client} <- maybe_fetch_client(params, id_token_claims, request),
         :ok <- validate_aud_if_client_id(params, id_token_claims, client),
         {:ok, post_logout_redirect_uri} <- validate_post_logout_redirect_uri(params, client) do
      {:ok, %Result{
        sid: get_in(id_token_claims || %{}, ["sid"]),
        account_id: get_in(id_token_claims || %{}, ["sub"]),
        post_logout_redirect_uri: post_logout_redirect_uri,
        state: Map.get(params, "state")
      }}
    end
  end
```

**id_token_hint validation** (from jar.ex lines 141-170, JOSE.JWT.verify_strict pattern — no exp check):
```elixir
defp validate_id_token_hint(%{"id_token_hint" => hint}, request) when is_binary(hint) do
  signing_keys = fetch_signing_keys(request)
  Enum.reduce_while(signing_keys, {:error, invalid_request("invalid id_token_hint signature", :invalid_id_token_hint)}, fn key, _acc ->
    public_jwk = build_public_jwk(key)
    try do
      case JOSE.JWT.verify_strict(public_jwk, ["RS256"], hint) do
        {true, %JOSE.JWT{} = jwt_struct, _jws} ->
          {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
          # Do NOT check exp — id_token_hint tolerates expiry per D-14 / OIDC spec
          {:halt, {:ok, claims}}
        {false, _, _} ->
          {:cont, {:error, invalid_request("invalid id_token_hint signature", :invalid_id_token_hint)}}
      end
    rescue
      _ -> {:cont, {:error, invalid_request("invalid id_token_hint signature", :invalid_id_token_hint)}}
    catch
      _, _ -> {:cont, {:error, invalid_request("invalid id_token_hint signature", :invalid_id_token_hint)}}
    end
  end)
end

defp validate_id_token_hint(_params, _request), do: {:ok, nil}
```

**post_logout_redirect_uri validation** (exact-match against client's registered list, same as redirect_uri):
```elixir
defp validate_post_logout_redirect_uri(%{"post_logout_redirect_uri" => uri}, %Client{} = client)
    when is_binary(uri) do
  if uri in client.post_logout_redirect_uris do
    {:ok, uri}
  else
    {:error, invalid_request("post_logout_redirect_uri not registered", :unregistered_post_logout_redirect_uri)}
  end
end

defp validate_post_logout_redirect_uri(_params, _client), do: {:ok, nil}
```

**Error helpers** (from revocation.ex lines 111-127):
```elixir
defp invalid_request(description, reason_code) do
  %Error{status: 400, error: "invalid_request", error_description: description, reason_code: reason_code}
end
```

---

### `lib/lockspire/protocol/discovery.ex`

**Analog:** self (lines 157-167) — `maybe_put_dpop_metadata/2` is the template for `put_bcl_fcl_metadata/1`

```elixir
# @endpoint_paths addition (line 9-19):
@endpoint_paths %{
  # ... existing entries ...
  "end_session_endpoint" => "/end_session"   # ADD
}

# openid_configuration/0 pipeline (line 91-93, add pipe):
|> maybe_put_dpop_metadata(endpoint_metadata)
|> put_bcl_fcl_metadata()    # ADD

# New private function:
defp put_bcl_fcl_metadata(metadata) do
  Map.merge(metadata, %{
    "backchannel_logout_supported" => false,
    "frontchannel_logout_supported" => false
  })
end
```

---

### `lib/lockspire/config.ex`

**Analog:** self (lines 39-50) — `mount_path/0` is the exact template

```elixir
@spec logout_path() :: String.t()
def logout_path do
  case Application.get_env(@app, :logout_path) do
    value when is_binary(value) and value != "" ->
      value
    _missing ->
      raise ArgumentError,
            "missing required config :logout_path for :lockspire. " <>
              "Set it in config/runtime.exs or config/*.exs. " <>
              "See the install guide for the host logout route seam."
  end
end
```

---

### `lib/lockspire/host/account_resolver.ex`

**Analog:** self (lines 23-24) — `redirect_for_login/2` is the template

```elixir
# After redirect_for_login/2 at line 24, before end:
@optional_callbacks [redirect_for_logout: 2]

@callback redirect_for_logout(conn_or_socket :: term(), context()) ::
            InteractionResult.t()
```

Context map: `%{account_id: String.t() | nil, return_to: String.t()}`. Minimal surface, mirrors `redirect_for_login/2`.

---

### `lib/lockspire/web/controllers/end_session_controller.ex` (new)

**Analog:** `lib/lockspire/web/controllers/interaction_controller.ex` (lines 1-196) — thin Phoenix adapter, `with` pipeline, delegates to protocol module

**Module header** (interaction_controller.ex lines 1-12):
```elixir
defmodule Lockspire.Web.EndSessionController do
  @moduledoc """
  Thin `/end_session` delivery adapter for OIDC RP-Initiated Logout.
  """

  use Phoenix.Controller, formats: [:html]

  alias Lockspire.Config
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Protocol.EndSession
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.EndSessionHTML
```

**GET + POST unified handler** (both methods share handler, mirrors interaction_controller.ex `show/2` / `complete/2` shape):
```elixir
def show(conn, params), do: handle_end_session(conn, params)
def create(conn, params), do: handle_end_session(conn, params)

defp handle_end_session(conn, params) do
  case EndSession.validate(%{params: params, opts: [client_store: Repository]}) do
    {:ok, %EndSession.Result{} = result} ->
      redirect_to_host_logout(conn, result)
    {:error, %EndSession.Error{} = error} ->
      conn
      |> put_status(error.status)
      |> put_resp_content_type("text/html")
      |> send_resp(error.status, EndSessionHTML.error_page(error))
  end
end
```

**Host logout redirect** (authorize_controller.ex lines 41-59 + 120-128 for redirect pattern):
```elixir
defp redirect_to_host_logout(conn, %EndSession.Result{} = result) do
  resolver = Lockspire.account_resolver!()

  return_to_token = Phoenix.Token.sign(conn, "lockspire_logout", %{
    sid: result.sid,
    post_logout_redirect_uri: result.post_logout_redirect_uri,
    state: result.state
  }, max_age: 600)

  completion_url =
    Lockspire.mount_path() <> "/end_session/complete"
    |> append_query_param("token", return_to_token)

  context = %{account_id: result.account_id, return_to: completion_url}

  %InteractionResult{} = lr = resolver.redirect_for_logout(conn, context)

  destination =
    lr.login_path
    |> append_query_param("return_to", lr.return_to)
    |> append_query_params(lr.params)

  redirect(conn, to: destination)
end
```

**Completion endpoint** (interaction_controller.ex `show/2` shape):
```elixir
def complete(conn, %{"token" => token}) do
  case Phoenix.Token.verify(conn, "lockspire_logout", token, max_age: 600) do
    {:ok, %{sid: sid, post_logout_redirect_uri: post_logout_redirect_uri, state: state}} ->
      _ = maybe_revoke_by_sid(sid)
      redirect_or_render_logged_out(conn, post_logout_redirect_uri, state)
    {:error, _reason} ->
      # D-10: treat as logout success — log failure, do not strand user
      redirect_or_render_logged_out(conn, nil, nil)
  end
end

def complete(conn, _params) do
  redirect_or_render_logged_out(conn, nil, nil)
end
```

**Logged-out render** (interaction_controller.ex `render_browser_error/3` shape):
```elixir
defp render_logged_out(conn) do
  conn
  |> put_status(:ok)
  |> put_view(Lockspire.Web.EndSessionHTML)
  |> render(:logged_out)
end
```

**Query param helpers** (copy from authorize_controller.ex lines 147-158):
```elixir
defp append_query_params(path, params) when is_map(params) do
  Enum.reduce(params, path, fn {key, value}, acc ->
    append_query_param(acc, key, value)
  end)
end

defp append_query_param(path, _key, nil), do: path
defp append_query_param(path, _key, ""), do: path

defp append_query_param(path, key, value) do
  separator = if String.contains?(path, "?"), do: "&", else: "?"
  path <> separator <> URI.encode_query(%{to_string(key) => value})
end
```

---

### `lib/lockspire/web/router.ex`

**Analog:** self (lines 24-25) — existing GET route pairs

```elixir
# Add after line 25:
get("/end_session", Lockspire.Web.EndSessionController, :show)
post("/end_session", Lockspire.Web.EndSessionController, :create)
get("/end_session/complete", Lockspire.Web.EndSessionController, :complete)
```

---

### `lib/lockspire/web/live/admin/tokens_live/show.ex`

**Analog:** self (lines 97-141) — render section card with `<p>` rows

```heex
<!-- Add after "Family:" row at line 112: -->
<p>Session ID (sid): <code>{@token_detail.token.sid || "Not recorded"}</code></p>
```

The `token_detail.token` map must expose `sid` — update `lib/lockspire/admin/tokens.ex` to include it from the database record.

---

### `lib/lockspire/web/live/admin/clients_live/show.ex`

**Analog:** self (lines 179-185) — `redirect_uris` `<ul>` display and `redirect_attrs/2` + `split_lines/1`

```heex
<!-- Add after redirect_uris list at line 185: -->
<h3>Post-Logout Redirect URIs</h3>
<ul>
  <%= for uri <- @client.post_logout_redirect_uris do %>
    <li>{uri}</li>
  <% end %>
</ul>
```

```elixir
# redirect_attrs/2 modification (line 326-329):
defp redirect_attrs(params) do
  %{
    redirect_uris: split_lines(params["redirect_uris"]),
    post_logout_redirect_uris: split_lines(params["post_logout_redirect_uris"])  # ADD
  }
end
```

---

### `lib/lockspire/web/live/admin/clients_live/form_component.ex`

**Analog:** self (lines 132-135) — `redirect_uris` textarea is the exact template

```heex
<!-- form_component.ex, inside div :if={@mode in [:new, :redirects]}, after redirect_uris textarea: -->
<label for="client_post_logout_redirect_uris">Post-Logout Redirect URIs</label>
<textarea id="client_post_logout_redirect_uris"
          name="client[post_logout_redirect_uris]"
          rows="4"><%= @defaults.post_logout_redirect_uris %></textarea>
```

```elixir
# defaults_for(:redirects) modification (line 195-198):
defp defaults_for(:redirects, %Client{} = client) do
  %{
    redirect_uris: Enum.join(client.redirect_uris, "\n"),
    post_logout_redirect_uris: Enum.join(client.post_logout_redirect_uris, "\n")  # ADD
  }
end
```

---

### `priv/templates/lockspire.install/account_resolver.ex`

**Analog:** self (lines 45-53) — `redirect_for_login/2` stub is the exact template

```elixir
# Add after redirect_for_login/2 stub:
@impl true
def redirect_for_logout(_conn_or_socket, context) do
  %InteractionResult{
    login_path: "/logout",
    return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
    params: %{
      "account_id" => Map.get(context, :account_id) || Map.get(context, "account_id")
    }
  }
end
```

Note: `/logout` is a stub. The host replaces it with their real session-clearing route.

---

## Shared Patterns

### Host Seam Redirect
**Source:** `lib/lockspire/web/controllers/authorize_controller.ex` lines 41-59 and 120-128
**Apply to:** `EndSessionController`

`redirect_for_login/2` + `redirect_to_result/2` pattern is the template for `redirect_for_logout/2` + the host redirect in `EndSessionController`. The `append_query_param/3` and `append_query_params/2` helpers (authorize_controller.ex lines 147-158) must be copied or extracted to a shared location.

### Config Validation (fail-fast startup)
**Source:** `lib/lockspire/config.ex` lines 39-50
**Apply to:** `Config.logout_path/0`

```elixir
case Application.get_env(@app, :logout_path) do
  value when is_binary(value) and value != "" -> value
  _missing -> raise ArgumentError, "missing required config :logout_path for :lockspire. ..."
end
```

### Protocol Error Struct
**Source:** `lib/lockspire/protocol/revocation.ex` lines 13-26
**Apply to:** `EndSession.Error`

Same `%{status, error, error_description, reason_code}` struct shape — used by all protocol modules in Lockspire.

### JOSE Signature Verification (no exp check)
**Source:** `lib/lockspire/protocol/jar.ex` lines 141-170
**Apply to:** `EndSession.validate_id_token_hint/2`

`JOSE.JWT.verify_strict/3` in `reduce_while` loop with try/rescue/catch. Key difference from JAR: do NOT call `Jar.validate_claims/2` or check `exp` on the result. Extract claims directly after `{true, jwt_struct, _}`.

### Bulk Token Revocation
**Source:** `lib/lockspire/storage/ecto/repository.ex` lines 589-603
**Apply to:** `Repository.revoke_by_sid/1`

`repo_update_all/3` with `sensitive: true`. `revoke_by_sid/1` adds an `is_nil(token.redeemed_at)` guard that `revoke_token_family/1` lacks.

### Textarea List Field (newline-split)
**Source:** `lib/lockspire/web/live/admin/clients_live/form_component.ex` lines 132-135 and `show.ex` lines 362-368
**Apply to:** `post_logout_redirect_uris` form + redirect_attrs

`split_lines/1` (already defined in `clients_live/show.ex`) is applied to `params["post_logout_redirect_uris"]` in `redirect_attrs/2`.

### sid Generation
**Source:** `lib/lockspire/security/policy.ex` line 116-119
**Apply to:** `AuthorizationFlow.generate_sid/0`

```elixir
:crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
```

32 bytes = 256 bits entropy; same approach as `generate_token/1` and existing `generate_code/1`.

---

## No Analog Found

All files have analogs. The only truly new file without a codebase analog is:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/lockspire/web/controllers/end_session_html/logged_out.html.heex` | template | request-response | Plain `.heex` page — no comparable standalone logged-out page exists yet. Use the error page template structure from `authorize_html.ex` as loose reference for layout |

---

## Metadata

**Analog search scope:** `lib/lockspire/`, `priv/repo/migrations/`, `priv/templates/lockspire.install/`
**Files scanned:** 26
**Pattern extraction date:** 2026-04-29
