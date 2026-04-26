# Phase 26: Protocol Pipeline — RFC 7591 Intake and RFC 7592 Management Core - Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** 16 (12 NEW, 4 MODIFIED)
**Analogs found:** 16 / 16

## File Classification

### NEW files

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/registration.ex` | protocol orchestrator (Plug.Conn-free) | request-response (intake) | `lib/lockspire/protocol/pushed_authorization_request.ex` (lines 1-180) | exact (Success/Error substructs + private validator + `with` pipeline) |
| `lib/lockspire/protocol/registration_management.ex` | protocol orchestrator (Plug.Conn-free) | request-response (CRUD on Domain.Client) | `lib/lockspire/protocol/pushed_authorization_request.ex` (lines 1-180) for shape; `lib/lockspire/admin/clients.ex` (lines 125-148) for delete delegation | exact (orchestrator shape) + role-match (admin delegation) |
| `lib/lockspire/protocol/initial_access_token.ex` | protocol primitive (atomic redemption + collapse) | request-response (single-use lifecycle) | `lib/lockspire/protocol/pushed_authorization_request.ex` (lines 76-90) for `wrap_jar_error/1` collapsing pattern; repository helper at `lib/lockspire/storage/ecto/repository.ex` (lines 534-557) | exact (collapse + Repository delegation) |
| `lib/lockspire/protocol/registration_access_token.ex` | protocol primitive (generate/hash/verify) | pure-function transform | `lib/lockspire/security/policy.ex` (lines 84-89, 116-127) for primitives; `lib/lockspire/clients.ex` (lines 388-392) for token generation idiom | exact (Security.Policy + crypto generation) |
| `test/support/fixtures/dcr_fixtures.ex` | test fixtures (RFC 7591 intake maps + RAT plaintext) | constructor helpers | `test/support/fixtures/initial_access_token_fixtures.ex` (lines 1-44) | exact (fixture module shape — `:plaintext` opt-in + `default_plaintext/0`) |
| `test/lockspire/protocol/registration_test.exs` | test (orchestrator — happy + sad) | unit (DB-backed, sandbox) | `test/lockspire/protocol/pushed_authorization_request_test.exs` (lines 1-100) | exact (`async: false`, sandbox `:manual`, `Repository.register_client/1` setup) |
| `test/lockspire/protocol/registration_management_test.exs` | test (RFC 7592 read/update/delete + RAT rotation) | unit (DB-backed, sandbox) | `test/lockspire/protocol/pushed_authorization_request_test.exs` (lines 1-63) | exact (same orchestrator-test shape, additional cases for RAT rotation) |
| `test/lockspire/protocol/initial_access_token_test.exs` | test (freshness ladder + atomicity) | unit (DB-backed, sandbox) + concurrent (`Task.async_many`) | `test/lockspire/protocol/pushed_authorization_request_test.exs` (setup) + research §"Concurrency Test Pattern" | role-match (no existing concurrent-redemption test) |
| `test/lockspire/protocol/registration_access_token_test.exs` | test (pure primitives) | unit (no DB) | `test/lockspire/protocol/par_policy_test.exs` (resolver-test pure-module shape) | role-match (closest pure-module test in protocol dir) |
| `test/lockspire/protocol/dcr_audit_attribution_test.exs` | regression test (audit-row sweep) | unit (DB-backed, sandbox) | `test/lockspire/admin/clients_test.exs` (lines 232-240, `latest_audit!/1` helper — note: must be adapted to a list-by-prefix helper since `Repository.list_audit_events/1` does NOT exist) | role-match (existing pattern is single-row `one!`; Phase 26 needs `all` filtered by `like` prefix) |
| `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` | sweep test (single-pass plaintext leak detector) | unit (telemetry handler + DB read) | `test/lockspire/admin/clients_test.exs` (lines 207-230 — `attach_events/1` + `handle_event/4` + `assert_received`) | role-match (existing pattern uses `assert_received`; Phase 26 needs `drain_events/0` accumulator + `String.contains?` sweep — new pattern, justified by D-27) |

### MODIFIED files

| Modified File | Role | Data Flow | Modification Pattern | Source of Modification Pattern |
|---------------|------|-----------|----------------------|-------------------------------|
| `lib/lockspire/admin/clients.ex` | admin/application surface | audit attribution chokepoint | (1) tighten `actor_from_attrs/1`/`normalize_actor_type/1` (lines 397-419) — change three silent `:operator` fallbacks to `raise ArgumentError`; (2) audit existing operator callers (`create_client/1`, `update_client/2`, `rotate_client_secret/2`, `disable_client/2`, `enable_client/2`) to ensure each receives explicit `attrs[:actor][:type]` | self (lines 397-419) — three branches at lines 407, 414, 419 |
| `lib/lockspire/clients.ex` | client lifecycle | credential primitive | promote `generate_client_id/0` from `defp` (lines 384-386) to `def` with `@spec generate_client_id() :: String.t()` (or wrap behind a `Lockspire.Clients.Identifiers` namespace if preferred) — required by `Lockspire.Protocol.Registration` (Pitfall 2 in RESEARCH.md) | self (lines 384-386 idiom: `"ls_" <> generate_token(@client_id_bytes)`) |
| `lib/lockspire/storage/ecto/repository.ex` | storage (Ecto) | DB transaction / lookup | (1) NEW `redeem_initial_access_token/2` mirroring `mark_authorization_code_redeemed/2` (lines 534-557) verbatim with `InitialAccessTokenRecord` + 4-axis freshness check; (2) NEW `get_client_by_registration_access_token_hash/1` mirroring `fetch_client_by_id/1` (lines 65-72) with `:registration_access_token_hash` predicate | self (lines 534-557) for atomic redemption; self (lines 65-72) for hash-equality lookup |
| `test/lockspire/admin/clients_test.exs` | test (audit chokepoint) | DB-backed unit | extend with new test cases asserting `actor_from_attrs/1` raises `ArgumentError` on missing actor type; verify existing cases pass `actor: %{type: :operator, ...}` explicitly (lines 57-61 already do — sweep through `update_client`, `rotate_client_secret`, `disable_client`, `enable_client` callers in `test/` and add `actor:` if missing) | self (lines 50-83) for explicit-actor convention |

---

## Pattern Assignments

### `lib/lockspire/protocol/registration.ex` (orchestrator, request-response)

**Analog:** `lib/lockspire/protocol/pushed_authorization_request.ex` (verbatim structural template)

**Module + alias + Success/Error substructs pattern** (`pushed_authorization_request.ex` lines 1-39):

```elixir
defmodule Lockspire.Protocol.PushedAuthorizationRequest do
  @moduledoc """
  Accepts pushed authorization requests and returns opaque PAR references.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.PushedAuthorizationRequest, as: PushedAuthorizationRequestState
  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.RequestObject
  alias Lockspire.Storage.Ecto.Repository

  defmodule Success do
    @moduledoc """
    Successful PAR response payload.
    """

    @type t :: %__MODULE__{
            request_uri: String.t(),
            expires_in: pos_integer()
          }

    defstruct [:request_uri, :expires_in]
  end

  defmodule Error do
    @moduledoc """
    PAR error payload safe for JSON responses.
    """

    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom()
          }

    defstruct [:status, :error, :error_description, :reason_code]
  end

  @type result :: {:ok, Success.t()} | {:error, Error.t()}
```

Phase 26 adapts the substructs to the D-12 / D-14 shape:

```elixir
defmodule Success do
  @type t :: %__MODULE__{
          client: Lockspire.Domain.Client.t(),
          client_secret_plaintext: String.t() | nil,
          registration_access_token_plaintext: String.t()
        }
  defstruct [:client, :client_secret_plaintext, :registration_access_token_plaintext]
end

defmodule Error do
  @type t :: %__MODULE__{
          code: atom(),         # :invalid_client_metadata | :invalid_token | ...
          field: atom() | nil,  # offending RFC 7591 field
          reason: atom() | nil, # discriminator (e.g. :unsupported_in_slice)
          allowed: list() | nil # allowlist returned by DcrPolicy.resolve/3
        }
  defstruct [:code, :field, :reason, :allowed]
end
```

**Public entry + `with` pipeline pattern** (`pushed_authorization_request.ex` lines 43-64):

```elixir
@spec push(map()) :: result()
def push(request) when is_map(request) do
  params = Map.get(request, :params, Map.get(request, "params", request))
  authorization = Map.get(request, :authorization, Map.get(request, "authorization"))
  now = now(request)

  with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
       {:ok, post_jar_params} <- maybe_consume_request_object(params, client),
       {:ok, %AuthorizationRequest.Validated{} = validated} <-
         validate_request(post_jar_params, client),
       {:ok, %PushedAuthorizationRequestState{} = pushed_request} <-
          persist_pushed_request(validated, request, now) do
    {:ok,
     %Success{
       request_uri: pushed_request.request_uri,
       expires_in: DateTime.diff(pushed_request.expires_at, now, :second)
     }}
  else
    {:error, %Error{} = error} ->
      {:error, error}
  end
end
```

Phase 26 application — pipeline order from D-13 (IAT redemption → DcrPolicy → intake validator → credential gen → persist → emit post-commit):

```elixir
@spec register(map()) :: result()
def register(request) when is_map(request) do
  with {:ok, iat_record} <- maybe_redeem_iat(request),
       {:ok, %Resolved{} = resolved} <-
         resolve_dcr_policy(request, iat_record),
       :ok <- validate_intake(request.metadata),
       {:ok, credentials} <- generate_credentials(),
       {:ok, %Client{} = client} <-
         persist_client(request, resolved, iat_record, credentials) do
    emit_dcr_registration_succeeded(client, iat_record, request.source)

    {:ok,
     %Success{
       client: client,
       client_secret_plaintext: credentials.client_secret,
       registration_access_token_plaintext: credentials.rat
     }}
  else
    {:error, %Error{} = error} ->
      emit_dcr_registration_rejected(error, request.source)
      {:error, error}
  end
end
```

**Private validator + error-mapping pattern** (`pushed_authorization_request.ex` lines 66-74):

```elixir
defp validate_request(params, %Client{} = client) do
  case AuthorizationRequest.validate_pushed(params, client) do
    {:ok, %AuthorizationRequest.Validated{} = validated} ->
      {:ok, validated}

    {:error, %AuthorizationRequest.Error{} = error} ->
      {:error, oauth_error(400, error.error, error.error_description, error.reason_code)}
  end
end
```

Phase 26 application — D-14 intake validator returns `:ok | {:error, %Error{}}`:

```elixir
defp validate_intake(metadata) when is_map(metadata) do
  with :ok <- validate_jwks(metadata),
       :ok <- validate_grant_response_coherence(metadata),
       :ok <- validate_redirect_uris_via_clients(metadata),
       :ok <- validate_pkce_floor(metadata) do
    :ok
  end
end

# D-14: jwks_uri rejected — see RESEARCH.md §"jwks_uri rejection"
defp validate_jwks(metadata) do
  cond do
    Map.has_key?(metadata, "jwks_uri") ->
      {:error,
       %Error{
         code: :invalid_client_metadata,
         field: :jwks_uri,
         reason: :unsupported_in_slice
       }}

    # D-14a: explicit even though gated by the branch above (spec compliance)
    Map.has_key?(metadata, "jwks") and Map.has_key?(metadata, "jwks_uri") ->
      {:error,
       %Error{
         code: :invalid_client_metadata,
         field: :jwks,
         reason: :mutually_exclusive_with_jwks_uri
       }}

    true ->
      :ok
  end
end
```

**Error-collapsing pattern (D-11 IAT and D-19 RAT)** — verbatim from `pushed_authorization_request.ex` lines 76-90 + 177-179:

```elixir
defp maybe_consume_request_object(%{"request" => req} = params, %Client{} = client)
     when is_binary(req) and req != "" do
  case RequestObject.consume(params, client, []) do
    {:ok, projected_params} ->
      {:ok, projected_params}

    {:browser_error, %AuthorizationRequest.Error{} = error} ->
      {:error, wrap_jar_error(error)}

    {:redirect_error, %AuthorizationRequest.Error{} = error} ->
      {:error, wrap_jar_error(error)}
  end
end

defp wrap_jar_error(%AuthorizationRequest.Error{} = error) do
  oauth_error(400, error.error, error.error_description, error.reason_code)
end
```

Phase 26 collapse for IAT (in `Lockspire.Protocol.InitialAccessToken.redeem/1`):

```elixir
def redeem(plaintext) when is_binary(plaintext) do
  hash = Lockspire.Security.Policy.hash_token(plaintext)

  case Repository.redeem_initial_access_token(hash, DateTime.utc_now()) do
    {:ok, %Lockspire.Domain.InitialAccessToken{} = iat} ->
      Observability.emit(:iat_redeemed, %{count: 1}, %{iat_id: iat.id})
      {:ok, iat}

    {:error, reason} when reason in [:not_found, :revoked, :expired, :already_used] ->
      Observability.emit(
        :iat_redemption_failed,
        %{count: 1, failure_reason: reason},
        %{}
      )
      {:error, :invalid_token}

    {:error, other} ->
      Observability.emit(
        :iat_redemption_failed,
        %{count: 1, failure_reason: :unexpected},
        %{detail: inspect(other)}
      )
      {:error, :invalid_token}
  end
end
```

---

### `lib/lockspire/protocol/registration_management.ex` (orchestrator, CRUD on Domain.Client)

**Analog (shape):** `lib/lockspire/protocol/pushed_authorization_request.ex` (same Success/Error substructs and `with` pipeline)

**Analog (delete delegation):** `lib/lockspire/admin/clients.ex` (lines 125-148, public `disable_client/2`)

**Public delete delegation pattern** (`admin/clients.ex` lines 125-148) — Phase 26 calls this from `RegistrationManagement.delete/2` instead of the **private** `disable_client_with_audit/4` (Pitfall 1 in RESEARCH.md):

```elixir
@spec disable_client(String.t(), map() | keyword()) ::
        {:ok, Client.t()} | {:error, :not_found | term()}
def disable_client(client_id, attrs \\ %{})

def disable_client(client_id, attrs) when is_list(attrs) do
  disable_client(client_id, Enum.into(attrs, %{}))
end

def disable_client(client_id, attrs) when is_binary(client_id) and is_map(attrs) do
  actor = actor_from_attrs(attrs)
  disabled_by = normalize_string(Map.get(attrs, :disabled_by))
  disabled_at = Map.get(attrs, :disabled_at, DateTime.utc_now())

  with {:ok, %Client{} = client} <- get_client(client_id) do
    case disable_client_with_audit(client, disabled_at, disabled_by, actor) do
      {:ok, %Client{} = updated_client} ->
        emit(:client_disabled, updated_client, actor, %{disabled_at: disabled_at})
        {:ok, updated_client}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

**Phase 26 application** — D-21 `RegistrationManagement.delete/2` calls `Admin.Clients.disable_client/2`, NOT the private helper. The `attrs` map carries `:disabled_by`, `:disabled_at`, and `:actor`:

```elixir
def delete(client_id_from_url, %Client{} = client) do
  if client_id_from_url == client.client_id do
    case Admin.Clients.disable_client(client.client_id, %{
           disabled_by: "dcr_self_delete",
           disabled_at: DateTime.utc_now(),
           actor: %{
             type: :self_registered_client,
             id: client.client_id
           }
         }) do
      {:ok, %Client{}} ->
        Observability.emit(:dcr_management_deleted, %{count: 1}, %{
          actor_type: :self_registered_client,
          actor_id: client.client_id,
          client_id: client.client_id
        })
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  else
    Observability.emit(:dcr_management_unauthorized, %{count: 1}, %{
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id_from_url: client_id_from_url
    })
    {:error, :invalid_token}
  end
end
```

**URL `client_id` ⊕ RAT-bound `client.client_id` mismatch collapse** (D-19) — same pattern as IAT collapse: never differentiate "no row found by RAT" vs "wrong client". Both axes return `{:error, :invalid_token}`.

---

### `lib/lockspire/protocol/initial_access_token.ex` (atomic redemption + collapse)

**Analog (collapse):** `lib/lockspire/protocol/pushed_authorization_request.ex` (lines 76-90, 177-179)

**Analog (Repository delegation):** `lib/lockspire/storage/ecto/repository.ex` (lines 534-557)

See the collapse pattern excerpt under `Registration` above.

The corresponding repository helper is the canonical "find by hash + lock + check + update in same tx" pattern — full body assigned below.

---

### `lib/lockspire/protocol/registration_access_token.ex` (generate / hash / verify primitives)

**Analog (generation):** `lib/lockspire/clients.ex` (lines 388-392)

```elixir
defp generate_token(size) do
  size
  |> :crypto.strong_rand_bytes()
  |> Base.url_encode64(padding: false)
end
```

**Analog (hash):** `lib/lockspire/security/policy.ex` (lines 84-89)

```elixir
@spec hash_token(String.t()) :: String.t()
def hash_token(secret) when is_binary(secret) do
  :sha256
  |> :crypto.hash(secret)
  |> Base.encode16(case: :lower)
end
```

**Analog (timing-safe compare for verify):** `lib/lockspire/security/policy.ex` (lines 116-127):

```elixir
defp secure_compare(left, right)
     when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
  Plug.Crypto.secure_compare(left, right)
end

defp secure_compare(_left, _right), do: false
```

**Phase 26 application** (D-06, D-16):

```elixir
defmodule Lockspire.Protocol.RegistrationAccessToken do
  @moduledoc """
  Registration access token (RAT) primitives — generate, hash, verify, rotate.
  Hashing uses `Lockspire.Security.Policy.hash_token/1` (deterministic SHA-256
  lowercase hex) per D-06, required for hash-equality lookup at RFC 7592 management
  calls (`Repository.get_client_by_registration_access_token_hash/1`).
  """

  alias Lockspire.Security.Policy

  @rat_bytes 32

  @spec generate() :: {plaintext :: String.t(), hash :: String.t()}
  def generate do
    plaintext =
      @rat_bytes
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    {plaintext, Policy.hash_token(plaintext)}
  end

  @spec hash(String.t()) :: String.t()
  def hash(plaintext) when is_binary(plaintext), do: Policy.hash_token(plaintext)

  # Hash-equality lookup is the actual verify path (rows are looked up by
  # registration_access_token_hash). This helper is provided for callers that
  # already have a stored hash and want a timing-safe equality check.
  @spec verify(String.t(), String.t()) :: boolean()
  def verify(stored_hash, candidate_plaintext)
      when is_binary(stored_hash) and is_binary(candidate_plaintext) do
    Plug.Crypto.secure_compare(stored_hash, Policy.hash_token(candidate_plaintext))
  end
end
```

---

### `lib/lockspire/storage/ecto/repository.ex` (NEW `redeem_initial_access_token/2`)

**Analog:** `lib/lockspire/storage/ecto/repository.ex` (lines 534-557, `mark_authorization_code_redeemed/2` — verbatim template per D-09)

**Full canonical pattern** (verbatim from `repository.ex:534-557`):

```elixir
@impl TokenStore
def mark_authorization_code_redeemed(token_hash, redeemed_at)
    when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
  transact(fn ->
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :authorization_code)
    |> lock("FOR UPDATE")
    |> repo_one(sensitive: true)
    |> case do
      nil ->
        repo().rollback(:not_found)

      %TokenRecord{redeemed_at: %DateTime{}} ->
        repo().rollback(:already_redeemed)

      %TokenRecord{} = record ->
        record
        |> Ecto.Changeset.change(redeemed_at: redeemed_at, updated_at: DateTime.utc_now())
        |> repo_update(sensitive: true)
        |> map_one(&TokenRecord.to_domain/1)
        |> unwrap_or_rollback()
    end
  end)
end
```

**Phase 26 application** — D-10 4-axis freshness ladder (the public `Repository.redeem_initial_access_token/2`):

```elixir
@spec redeem_initial_access_token(String.t(), DateTime.t()) ::
        {:ok, Lockspire.Domain.InitialAccessToken.t()}
        | {:error, :not_found | :revoked | :expired | :already_used | term()}
def redeem_initial_access_token(token_hash, redeemed_at)
    when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
  transact(fn ->
    InitialAccessTokenRecord
    |> where([iat], iat.token_hash == ^token_hash)
    |> lock("FOR UPDATE")
    |> repo_one(sensitive: true)
    |> case do
      nil ->
        repo().rollback(:not_found)

      %InitialAccessTokenRecord{revoked_at: %DateTime{}} ->
        repo().rollback(:revoked)

      %InitialAccessTokenRecord{expires_at: expires_at}
      when not is_nil(expires_at) and expires_at <= redeemed_at ->
        repo().rollback(:expired)

      %InitialAccessTokenRecord{single_use: true, used_at: %DateTime{}} ->
        repo().rollback(:already_used)

      %InitialAccessTokenRecord{} = record ->
        record
        |> Ecto.Changeset.change(used_at: redeemed_at, updated_at: DateTime.utc_now())
        |> repo_update(sensitive: true)
        |> map_one(&InitialAccessTokenRecord.to_domain/1)
        |> unwrap_or_rollback()
    end
  end)
end
```

The four `repo().rollback/1` reasons map to D-11's discriminator (emitted to telemetry by `Lockspire.Protocol.InitialAccessToken.redeem/1`, NEVER returned publicly).

---

### `lib/lockspire/storage/ecto/repository.ex` (NEW `get_client_by_registration_access_token_hash/1`)

**Analog:** `lib/lockspire/storage/ecto/repository.ex` (lines 64-72, `fetch_client_by_id/1`)

```elixir
@impl ClientStore
def fetch_client_by_id(client_id) when is_binary(client_id) do
  ClientRecord
  |> where([client], client.client_id == ^client_id)
  |> repo_one()
  |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
rescue
  error -> {:error, error}
end
```

**Phase 26 application** (D-19):

```elixir
@spec get_client_by_registration_access_token_hash(String.t()) ::
        {:ok, Lockspire.Domain.Client.t() | nil} | {:error, term()}
def get_client_by_registration_access_token_hash(rat_hash) when is_binary(rat_hash) do
  ClientRecord
  |> where([client], client.registration_access_token_hash == ^rat_hash)
  |> repo_one(sensitive: true)
  |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
rescue
  error -> {:error, error}
end
```

Note: use `repo_one(sensitive: true)` (the project's "do not log this query parameter" toggle, used by every other hash-equality lookup — see `repository.ex:251, 268, 514, 528, 540`).

---

### `lib/lockspire/admin/clients.ex` (MODIFIED — D-22 tighten in place)

**Analog:** `lib/lockspire/admin/clients.ex` itself (lines 397-419 — self-pattern, three silent fallbacks become loud raises)

**Before** (`admin/clients.ex:397-419`, verbatim):

```elixir
defp actor_from_attrs(attrs) when is_map(attrs) do
  actor = Map.get(attrs, :actor) || Map.get(attrs, "actor") || %{}

  %{
    type: normalize_actor_type(Map.get(actor, :type) || Map.get(actor, "type")),
    id: normalize_string(Map.get(actor, :id) || Map.get(actor, "id")),
    display: normalize_string(Map.get(actor, :display) || Map.get(actor, "display"))
  }
end

defp normalize_actor_type(nil), do: :operator
defp normalize_actor_type(value) when is_atom(value), do: value

defp normalize_actor_type(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "" -> :operator
    normalized -> normalized
  end
end

defp normalize_actor_type(_value), do: :operator
```

**After** (D-22 — `nil`, blank string, and other-type all raise; pass-through for atoms and non-blank strings unchanged):

```elixir
defp normalize_actor_type(nil) do
  raise ArgumentError,
        "actor.type is required; pass attrs[:actor][:type] explicitly. " <>
          "Allowed: :operator | :system | :host_app | :dcr | :self_registered_client"
end

defp normalize_actor_type(value) when is_atom(value), do: value

defp normalize_actor_type(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "" -> raise ArgumentError, "actor.type cannot be blank"
    normalized -> normalized
  end
end

defp normalize_actor_type(other) do
  raise ArgumentError,
        "actor.type must be an atom or non-blank string, got: #{inspect(other)}"
end
```

**Operator-caller audit (Pitfall 6 in RESEARCH.md):** `grep -rn "Admin.Clients\.\(create_client\|update_client\|rotate_client_secret\|disable_client\|enable_client\)" lib test` and confirm `attrs[:actor][:type]` is set explicitly at every callsite. Existing tests at `test/lockspire/admin/clients_test.exs:50-83` already pass `actor: %{type: :operator, ...}` — verified.

**DCR caller wiring** (D-23):

- `Lockspire.Protocol.Registration.register/1` constructs `attrs[:actor] = %{type: :dcr, id: iat_id_or_"anonymous", display: source.ip}`.
- `Lockspire.Protocol.RegistrationManagement.{read,update,delete}/2` constructs `attrs[:actor] = %{type: :self_registered_client, id: client.client_id}`.

---

### `lib/lockspire/clients.ex` (MODIFIED — promote `generate_client_id/0` to public)

**Analog:** `lib/lockspire/clients.ex` itself (lines 384-386, self-pattern; just visibility change + `@spec`)

**Before** (`clients.ex:384-386`, verbatim — currently `defp`):

```elixir
defp generate_client_id do
  "ls_" <> generate_token(@client_id_bytes)
end
```

**After** (Pitfall 2 in RESEARCH.md — Open Question 2 recommendation: promote rather than duplicate the idiom inline):

```elixir
@spec generate_client_id() :: String.t()
def generate_client_id do
  "ls_" <> generate_token(@client_id_bytes)
end
```

`generate_token/1` (lines 388-392) and `@client_id_bytes` (line 15) remain as-is. The single existing caller at `clients.ex:99` still works unchanged.

**Note:** alternative is to wrap in a tiny `Lockspire.Clients.Identifiers` namespace; D-16's "via the existing `Lockspire.Clients.generate_client_id/0` helper" wording strongly implies the simpler in-place promotion.

---

### `test/support/fixtures/dcr_fixtures.ex` (NEW)

**Analog:** `test/support/fixtures/initial_access_token_fixtures.ex` (lines 1-44, verbatim shape)

```elixir
defmodule Lockspire.Test.Fixtures.InitialAccessTokenFixtures do
  @moduledoc """
  Test fixtures for `Lockspire.Domain.InitialAccessToken`.

  Hashes plaintext via `Lockspire.Security.Policy.hash_token/1` (D-14) — NEVER a hand-rolled
  hash. Drift here would silently break Phase 26's atomic redemption (Pitfall — shared
  pattern §"Hash-at-rest via `Lockspire.Security.Policy.hash_token/1`" in 25-PATTERNS.md).
  """

  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Security.Policy

  @default_lifetime_seconds 3600

  @doc """
  Build an `InitialAccessToken` struct. Pass `:plaintext` in `attrs` to deterministically
  set `token_hash`; otherwise a random 32-byte token is generated and hashed.
  """
  @spec initial_access_token(map()) :: InitialAccessToken.t()
  def initial_access_token(attrs \\ %{}) when is_map(attrs) do
    {plaintext, attrs} = Map.pop(attrs, :plaintext, default_plaintext())

    base = %InitialAccessToken{
      token_hash: Policy.hash_token(plaintext),
      expires_at: DateTime.add(DateTime.utc_now(), @default_lifetime_seconds, :second),
      single_use: true
    }

    struct!(base, attrs)
  end

  @spec default_plaintext() :: String.t()
  def default_plaintext do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
```

**Phase 26 application** — `dcr_fixtures.ex` exposes:

- `Lockspire.Test.Fixtures.DcrFixtures.valid_metadata/0` — minimal RFC 7591 intake map (PKCE-required confidential client; no `jwks_uri`).
- `Lockspire.Test.Fixtures.DcrFixtures.invalid_jwks_uri_metadata/0` — D-14 `:jwks_uri` rejection trigger.
- `Lockspire.Test.Fixtures.DcrFixtures.invalid_grant_response_metadata/0` — D-14 coherence trigger.
- `Lockspire.Test.Fixtures.DcrFixtures.invalid_pkce_required_false_metadata/0` — D-15 PKCE-floor trigger.
- `Lockspire.Test.Fixtures.DcrFixtures.register_request/1` — request-tuple builder (`%{metadata, iat, server_policy, source}`).
- An extension to `InitialAccessTokenFixtures` is also needed: `persist/1` that takes `{plaintext, attrs}` and inserts the row (current fixture builds the struct only; redemption tests need the row present).

---

### `test/lockspire/protocol/registration_test.exs` (NEW)

**Analog:** `test/lockspire/protocol/pushed_authorization_request_test.exs` (lines 1-100, verbatim setup template)

**Setup pattern** (lines 1-63, verbatim):

```elixir
defmodule Lockspire.Protocol.PushedAuthorizationRequestTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.PushedAuthorizationRequest
  alias Lockspire.Domain.Client
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.PushedAuthorizationRequest, as: PushedAuthorizationRequestProtocol
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "openid"])

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "par-public",
        client_secret_hash: nil,
        client_type: :public,
        # ... etc.
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{public_client: public_client, ...}
  end
```

Phase 26 application uses the **same setup boilerplate**, but the per-test arrange step builds an inbound RFC 7591 metadata map via `DcrFixtures.valid_metadata/0` and constructs a `%ServerPolicy{}` with `registration_policy: :initial_access_token` (or `:open` for the no-IAT branch).

---

### `test/lockspire/protocol/initial_access_token_test.exs` (NEW)

**Analog (setup):** `test/lockspire/protocol/pushed_authorization_request_test.exs` (lines 12-23)

**Analog (concurrency assertion):** none in repo — research §"Concurrency Test Pattern (DCR-11 atomicity)" provides the canonical shape:

```elixir
test "concurrent redemption — exactly one task wins, the rest get :invalid_token" do
  iat_plaintext = "iat_concurrent_test"
  {:ok, _row} = Lockspire.Test.Fixtures.InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})

  parent = self()
  tasks =
    for _ <- 1..10 do
      Task.async(fn ->
        Ecto.Adapters.SQL.Sandbox.allow(Lockspire.TestRepo, parent, self())
        Lockspire.Protocol.InitialAccessToken.redeem(iat_plaintext)
      end)
    end

  results = Task.await_many(tasks, 5_000)

  successes = Enum.count(results, &match?({:ok, _}, &1))
  failures = Enum.count(results, &match?({:error, :invalid_token}, &1))
  assert successes == 1
  assert failures == 9
end
```

The `Ecto.Adapters.SQL.Sandbox.allow(Lockspire.TestRepo, parent, self())` line is mandatory for any `Task.async` test path that hits the DB in `:manual` sandbox mode.

---

### `test/lockspire/protocol/dcr_audit_attribution_test.exs` (NEW — D-24 regression)

**Analog (audit-row query):** `test/lockspire/admin/clients_test.exs` (lines 232-240) — note: this is `one!/1` for a single row by `action`; Phase 26 needs an `all/1` variant filtered by `like(action, "dcr_%")` since `Repository.list_audit_events/1` does NOT exist.

**Analog excerpt** (lines 232-240, verbatim):

```elixir
defp latest_audit!(action) do
  Lockspire.TestRepo.one!(
    from(audit in AuditEventRecord,
      where: audit.action == ^to_string(action),
      order_by: [desc: audit.id],
      limit: 1
    )
  )
end
```

**Phase 26 application** (D-24, Pitfall 3 in RESEARCH.md — direct `from(...)` query, not a non-existent Repository helper):

```elixir
defmodule Lockspire.Protocol.DcrAuditAttributionTest do
  use ExUnit.Case, async: false
  import Ecto.Query

  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Test.Fixtures.DcrFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  test "no DCR audit row is attributed to :operator" do
    # Exercise every DCR write path: intake success/failure, RFC 7592 read/update/delete,
    # RAT rotation, IAT redemption-failure paths.
    exercise_dcr_paths()

    rows =
      Lockspire.TestRepo.all(
        from(audit in AuditEventRecord,
          where: like(audit.action, "dcr_%"),
          order_by: [desc: audit.id]
        )
      )

    # IMPORTANT: Audit.Event.normalize/1 stringifies actor_type at audit/event.ex:94.
    # The assertion compares against "operator" (string), NOT :operator (atom).
    assert Enum.all?(rows, fn row -> row.actor_type != "operator" end),
           "found DCR audit row attributed to :operator: #{inspect(Enum.find(rows, &(&1.actor_type == "operator")))}"
  end
end
```

The `actor_type` stringification happens at `lib/lockspire/audit/event.ex:94` (`defp normalize_optional_value(value) when is_atom(value), do: Atom.to_string(value)`) — this is why the regression assertion compares against `"operator"`, not `:operator`.

---

### `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` (NEW — D-27 single-sweep)

**Analog (telemetry handler):** `test/lockspire/admin/clients_test.exs` (lines 207-230, `attach_events/1` + `handle_event/4`)

**Analog excerpt** (lines 207-230, verbatim):

```elixir
def handle_event(event, _measurements, metadata, pid) do
  send(pid, {:telemetry_event, event, metadata})
end

defp attach_events(pid) do
  handler_id = "admin-clients-test-#{System.unique_integer([:positive])}"

  :ok =
    :telemetry.attach_many(
      handler_id,
      [
        [:lockspire, :client_created],
        [:lockspire, :audit, :client_created],
        [:lockspire, :client_secret_rotated],
        [:lockspire, :audit, :client_secret_rotated],
        [:lockspire, :client_disabled],
        [:lockspire, :audit, :client_disabled]
      ],
      &__MODULE__.handle_event/4,
      pid
    )

  handler_id
end
```

**Phase 26 application** (D-27 — replace `assert_received` with a `drain_events/0` accumulator + `String.contains?` sweep — full template in RESEARCH.md §"Telemetry redaction sweep test (D-27)"):

```elixir
defp drain_events(acc \\ []) do
  receive do
    {:telemetry_event, e, m, md} -> drain_events([{e, m, md} | acc])
  after
    50 -> Enum.reverse(acc)
  end
end
```

The handler must capture **measurements** as well (the IAT failure path puts the discriminator in measurements via `failure_reason`); update `handle_event/4` to send `{:telemetry_event, event, measurements, metadata}` (4-tuple, not the 3-tuple from the analog).

The 16 event paths that must be attached (DCR x 7 events x 2 paths + IAT x 2 events x 2 paths) are listed verbatim in RESEARCH.md lines 671-688.

---

## Shared Patterns

These patterns apply to **every** Phase 26 module that emits telemetry, persists data, or generates credentials. The planner should reference these once per pattern in each plan's "Cross-cutting" section rather than duplicating per-file.

### Hash-at-rest (`client_secret`, salted)
**Source:** `lib/lockspire/security/policy.ex` (lines 91-96)
**Apply to:** `Registration.register/1` credential generation step (D-04).

```elixir
@spec hash_client_secret(String.t()) :: String.t()
def hash_client_secret(secret) when is_binary(secret) do
  salt = generate_token(16)
  hash = :crypto.hash(:sha256, salt <> secret) |> Base.encode64()
  "sha256:#{salt}:#{hash}"
end
```

Wrapper already exists at `lib/lockspire/clients.ex` lines 52-56 — Phase 26 calls `Lockspire.Clients.rotate_secret_hash/0` and gets back `{hash, plaintext}`:

```elixir
@spec rotate_secret_hash() :: {String.t(), String.t()}
def rotate_secret_hash do
  secret = generate_token(@secret_bytes)
  {Policy.hash_client_secret(secret), secret}
end
```

### Hash-at-rest (RAT, IAT — deterministic, unsalted)
**Source:** `lib/lockspire/security/policy.ex` (lines 84-89)
**Apply to:** `Lockspire.Protocol.RegistrationAccessToken.hash/1` (D-06), `Lockspire.Protocol.InitialAccessToken.redeem/1` internal hash (D-05, D-08), `Repository.get_client_by_registration_access_token_hash/1` lookup key (D-19).

```elixir
@spec hash_token(String.t()) :: String.t()
def hash_token(secret) when is_binary(secret) do
  :sha256
  |> :crypto.hash(secret)
  |> Base.encode16(case: :lower)
end
```

### Telemetry emission (with automatic redaction + audit mirror)
**Source:** `lib/lockspire/observability.ex` (lines 15-29)
**Apply to:** every Phase 26 module emitting any of the D-26 event names.

```elixir
@spec emit(event_name(), measurements(), metadata()) :: :ok
def emit(event_name, measurements \\ %{}, metadata \\ %{}) when is_atom(event_name) do
  redacted_metadata = redact(metadata)
  normalized_measurements = Map.put_new(measurements, :count, 1)

  :telemetry.execute(@audit_prefix ++ [event_name], normalized_measurements, redacted_metadata)
  :telemetry.execute(@telemetry_prefix ++ [event_name], normalized_measurements, redacted_metadata)
  :ok
end
```

Phase 26 caller convention (D-25):

```elixir
Observability.emit(:dcr_registration_succeeded, %{}, %{
  actor_type: :dcr,
  actor_id: iat_id_or_anonymous,
  client_id: client.client_id,
  iat_id: iat_record && iat_record.id,
  source_ip: source.ip,
  reason_code: :dcr_registration_succeeded
})
```

**Anti-pattern (RESEARCH.md Pitfall 5):** the `Lockspire.Redaction.for_telemetry/1` drop list at `redaction.ex:8-53` does NOT include `:registration_access_token`, `:initial_access_token`, `:rat`, or `:iat`. Phase 26 callers MUST emit only `*_id`/`*_hash` fields, never plaintext, into telemetry metadata. The D-27 sweep test is the safety net.

### Atomic single-use redemption (find by hash + lock + freshness check + update in one tx)
**Source:** `lib/lockspire/storage/ecto/repository.ex` (lines 534-557, `mark_authorization_code_redeemed/2`)
**Apply to:** new `Repository.redeem_initial_access_token/2` (D-09, D-10) — verbatim mirror with 4-axis ladder substituted for the 2-axis ladder.

(Full body shown above under §`Repository`.)

### Audit attribution chokepoint
**Source:** `lib/lockspire/admin/clients.ex` (lines 397-419, post-D-22 tightening)
**Apply to:** every DCR write path. Each of `Registration.register/1`, `RegistrationManagement.{read,update,delete}/2`, and any RAT-rotation path must construct `attrs[:actor]` with explicit `type:` (D-23):

- Intake (`:dcr` actor): `%{type: :dcr, id: iat_record.id || "anonymous", display: source.ip}`
- Management (`:self_registered_client` actor): `%{type: :self_registered_client, id: client.client_id}`

Missing `type:` raises `ArgumentError` (D-22, post-tightening).

### Plug.Conn-free orchestrator shape
**Source:** `lib/lockspire/protocol/pushed_authorization_request.ex` (lines 1-180)
**Apply to:** all four new protocol modules (D-03).

- Public entry function takes a single map argument (or the (`client_id_from_url`, `%Domain.Client{}`) pair for `RegistrationManagement`).
- Returns `{:ok, %Success{}} | {:error, %Error{}}` substructs (or domain structs / `:ok` / `{:error, :invalid_token}` for collapsed cases).
- No `Plug.Conn` import, no conn parameters, no JSON encoding, no HTTP status mapping. Phase 27's HTTP adapter owns those concerns.

### Error-axis collapsing for security
**Source:** `lib/lockspire/protocol/pushed_authorization_request.ex` (lines 76-90, 177-179, `wrap_jar_error/1`)
**Apply to:**
- `Lockspire.Protocol.InitialAccessToken.redeem/1` — collapses `{:not_found, :revoked, :expired, :already_used}` to `{:error, :invalid_token}` (D-11).
- `Lockspire.Protocol.RegistrationManagement.{read,update,delete}/2` — collapses "no row found by RAT hash" and "URL `client_id` doesn't match RAT-bound client" both to `{:error, :invalid_token}` (D-19).

Discriminator preserved in **telemetry only** as a `failure_reason` measurement; never returned out the public boundary.

---

## Three Code-Correctness Findings (must be planned BEFORE protocol modules)

These are the three concrete issues the researcher flagged in RESEARCH.md (lines 15-18, 769-782, Pitfalls 1-3). The planner MUST schedule the resolutions as the first plans in Phase 26, before authoring the four protocol modules — otherwise compile errors block all downstream work.

### Finding 1: `Admin.Clients.disable_client_with_audit/4` is `defp`

**Location:** `lib/lockspire/admin/clients.ex:348` (verified — `defp disable_client_with_audit(client, disabled_at, disabled_by, actor)`).

**Problem:** D-21 specifies that `RegistrationManagement.delete/2` calls `Admin.Clients.disable_client_with_audit/4`. The function is private; the call would fail with `(UndefinedFunctionError) function Lockspire.Admin.Clients.disable_client_with_audit/4 is undefined or private`.

**Resolution (RESEARCH.md Open Question 1 recommendation):** Use the **public** `Admin.Clients.disable_client/2` (`admin/clients.ex:127-148`), which already wraps `disable_client_with_audit/4`. Pass `attrs = %{disabled_by: "dcr_self_delete", disabled_at: ..., actor: %{type: :self_registered_client, id: client.client_id}}`. This requires no changes to `admin/clients.ex` beyond the D-22 tightening.

**Plan implication:** No Phase 26 change to `admin/clients.ex` for this finding. The fix lives entirely in `RegistrationManagement.delete/2` (use the public wrapper). Note `disable_client/2` returns `{:ok, %Client{}} | {:error, :not_found | term()}` — `RegistrationManagement.delete/2` should return `:ok` on success per D-21, so wrap with `case ... do {:ok, %Client{}} -> :ok end`.

### Finding 2: `Lockspire.Clients.generate_client_id/0` is `defp`

**Location:** `lib/lockspire/clients.ex:384-386` (verified — `defp generate_client_id do "ls_" <> generate_token(@client_id_bytes) end`).

**Problem:** D-16 specifies that `Registration.register/1` generates `client_id` via `Lockspire.Clients.generate_client_id/0`. The function is private; the call would fail with `(UndefinedFunctionError)`.

**Resolution (RESEARCH.md Open Question 2 recommendation):** **Promote to public** with `@spec generate_client_id() :: String.t()`. The 2-line body and `@client_id_bytes` module attribute remain unchanged. Existing single caller at `clients.ex:99` continues to work.

**Plan implication:** First plan in Phase 26 should include this single-line promotion in `lib/lockspire/clients.ex` (`defp` → `def` + `@spec`).

### Finding 3: `Repository.list_audit_events/1` does not exist

**Location:** D-24 references this function name; `grep -n "list_audit_events" lib/lockspire/storage/ecto/repository.ex` returns no matches.

**Problem:** D-24's regression test at `test/lockspire/protocol/dcr_audit_attribution_test.exs` cannot use a non-existent helper. The test would fail at compile load.

**Resolution (RESEARCH.md Open Question 3 recommendation):** **Stay with the in-test direct-query pattern** (per `test/lockspire/admin/clients_test.exs:232-240`). Use `import Ecto.Query` and `Lockspire.TestRepo.all(from(audit in AuditEventRecord, where: like(audit.action, "dcr_%"), order_by: [desc: audit.id]))`. Phase 26's regression test is the only Phase 26 caller; adding a public Repository helper for one test is over-investment.

**Plan implication:** No new Repository function. The full-test body excerpt is shown in §`dcr_audit_attribution_test.exs` above. The assertion compares `actor_type` against `"operator"` (string, not atom) per `audit/event.ex:94`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | — | — | Every Phase 26 file has at least a role-match analog in the codebase. The four-module split (`Registration`, `RegistrationManagement`, `InitialAccessToken`, `RegistrationAccessToken`) all share `pushed_authorization_request.ex` as a structural template; the new repository helpers mirror existing `mark_authorization_code_redeemed/2` and `fetch_client_by_id/1`; the test files mirror existing protocol-test setup; the new `dcr_fixtures.ex` mirrors the existing `initial_access_token_fixtures.ex`. The audit-attribution and telemetry-redaction tests use a mix-and-match of existing test helpers (lines 207-240 of `test/lockspire/admin/clients_test.exs`) — not a perfect 1:1 match but every primitive needed is in the precedent. |

---

## Metadata

**Analog search scope:**
- `lib/lockspire/protocol/` (full directory — 21 files)
- `lib/lockspire/storage/ecto/` (selective — `repository.ex` lines 1-100, 220-340, 510-620; `audit_event_record.ex`)
- `lib/lockspire/admin/` (full read of `clients.ex`)
- `lib/lockspire/clients.ex`, `lib/lockspire/security/policy.ex`, `lib/lockspire/observability.ex`, `lib/lockspire/redaction.ex`, `lib/lockspire/audit/event.ex`
- `test/lockspire/protocol/` (existing test shapes)
- `test/lockspire/admin/clients_test.exs` (lines 50-83, 200-241 — telemetry handler + audit-row query patterns)
- `test/support/fixtures/` (existing fixture shapes)

**Files scanned (analog candidates):** 16 source files, 4 test files, 1 fixture file.

**Pattern extraction date:** 2026-04-26
**Phase 25 PATTERNS.md cross-reference:** `.planning/phases/25-dcr-storage-skeleton-domain-types-and-policy-resolver/25-PATTERNS.md` — the resolver-shape and hash-at-rest patterns established there are inherited verbatim by Phase 26.

---

*Phase: 26-protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co*
*Pattern mapping: 2026-04-26*
