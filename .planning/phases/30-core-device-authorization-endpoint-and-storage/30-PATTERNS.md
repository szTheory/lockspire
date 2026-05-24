# Phase 30: Core Device Authorization Endpoint & Storage - Pattern Map

**Mapped:** 2024-05-24 (simulated current date)
**Files analyzed:** 9
**Analogs found:** 7 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/controllers/device_authorization_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/pushed_authorization_request_controller.ex` | exact |
| `lib/lockspire/web/router.ex` | route | request-response | `lib/lockspire/web/router.ex` (PAR routes) | exact |
| `lib/lockspire/protocol/device_authorization.ex` | protocol | request-response | `lib/lockspire/protocol/pushed_authorization_request.ex` | exact |
| `lib/lockspire/web/device_authorization_json.ex` | view | request-response | `lib/lockspire/web/pushed_authorization_request_json.ex` | exact |
| `lib/lockspire/domain/device_authorization.ex` | model | CRUD / domain | `lib/lockspire/domain/pushed_authorization_request.ex` | exact |
| `lib/lockspire/storage/device_authorization_store.ex` | store | CRUD | `lib/lockspire/storage/pushed_authorization_request_store.ex` | exact |
| `lib/lockspire/storage/ecto/device_authorization_record.ex` | schema | CRUD | `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex` | exact |
| `priv/repo/migrations/*_create_lockspire_device_authorizations.exs` | migration | CRUD | (Standard Ecto PAR migration) | exact |
| Base20 Generator | utility | generation | (No exact Base20 analog) | none |

## Pattern Assignments

### `lib/lockspire/web/controllers/device_authorization_controller.ex` (controller, request-response)

**Analog:** `lib/lockspire/web/controllers/pushed_authorization_request_controller.ex`

**Controller Pattern** (lines 14-31):
```elixir
  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case PushedAuthorizationRequest.push(%{
           params: params,
           authorization: authorization,
           opts: [client_store: Repository, pushed_authorization_request_store: Repository]
         }) do
      {:ok, %Success{} = success} ->
        conn
        |> put_cache_headers()
        |> put_status(:created) # NOTE: For Device Auth it's usually 200 OK, follow RFC 8628
        |> json(PushedAuthorizationRequestJSON.success_response(success))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(PushedAuthorizationRequestJSON.error_response(error))
    end
  end
```
**Cache Headers Pattern** (lines 33-37):
```elixir
  defp put_cache_headers(conn) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("pragma", "no-cache")
  end
```

### `lib/lockspire/protocol/device_authorization.ex` (protocol, request-response)

**Analog:** `lib/lockspire/protocol/pushed_authorization_request.ex`

**Struct Definitions Pattern** (lines 13-33):
```elixir
  defmodule Success do
    @type t :: %__MODULE__{
            device_code: String.t(),
            user_code: String.t(),
            verification_uri: String.t(),
            verification_uri_complete: String.t() | nil,
            expires_in: pos_integer(),
            interval: pos_integer()
          }
    defstruct [:device_code, :user_code, :verification_uri, :verification_uri_complete, :expires_in, :interval]
  end

  defmodule Error do
    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom()
          }
    defstruct [:status, :error, :error_description, :reason_code]
  end
```

**Core Protocol Pipeline** (lines 39-53):
```elixir
    with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, validated} <- validate_request(params, client),
         {:ok, %DeviceAuthorizationState{} = device_auth} <-
           persist_device_authorization(validated, request, now) do
      {:ok,
       %Success{
         device_code: device_auth.device_code, # Use plaintext for response
         user_code: device_auth.user_code,
         verification_uri: device_auth.verification_uri,
         expires_in: DateTime.diff(device_auth.expires_at, now, :second)
       }}
    else
      {:error, %Error{} = error} ->
        {:error, error}
    end
```

### `lib/lockspire/domain/device_authorization.ex` (model, CRUD)

**Analog:** `lib/lockspire/domain/pushed_authorization_request.ex`

**Struct and TTL Definition** (lines 11-12 & Issue constructor):
```elixir
  @default_ttl 300 # 5 minutes
  
  def issue(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    
    # Needs generator for device_code and user_code
    
    %__MODULE__{
      device_code: device_code,
      device_code_hash: Policy.hash_token(device_code),
      user_code_hash: Policy.hash_token(user_code), # user_code is also sensitive
      client_id: Map.fetch!(attrs, :client_id),
      scopes: List.wrap(Map.get(attrs, :scopes, [])),
      expires_at: DateTime.add(now, ttl, :second)
    }
  end
```

### `lib/lockspire/storage/ecto/device_authorization_record.ex` (schema, CRUD)

**Analog:** `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex`

**Schema Pattern** (lines 12-25):
```elixir
  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_device_authorizations" do
    field(:device_code_hash, :string)
    field(:user_code_hash, :string)
    field(:client_id, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:expires_at, :utc_datetime_usec)

    timestamps()
  end
```
**Changeset Pattern** (lines 27-46):
```elixir
  def changeset(record, %DeviceAuthorization{} = request) do
    attrs = Map.from_struct(request)

    record
    |> cast(attrs, [
      :device_code_hash,
      :user_code_hash,
      :client_id,
      :scopes,
      :expires_at
    ])
    |> validate_required([
      :device_code_hash,
      :user_code_hash,
      :client_id,
      :expires_at
    ])
    |> unique_constraint(:device_code_hash)
    |> unique_constraint(:user_code_hash) # Must be globally unique across active requests
  end
```

### Code Generation Patterns

**High-Entropy String Generation Pattern** (e.g., `device_code`)
**Source:** `lib/lockspire/domain/pushed_authorization_request.ex` (lines 81-85)
**Apply to:** `device_code` generation
```elixir
    fn ->
      32
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)
    end
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Base20 Generator | utility | generation | The system has high-entropy generators (`:crypto.strong_rand_bytes`), but no collision-resistant Base20 (e.g. `BCDFGHJKLMNPQRSTVWXZ`) low-entropy generator used for `user_code` entry. Needs custom implementation. |

## Metadata

**Analog search scope:** `lib/lockspire/protocol/*.ex`, `lib/lockspire/web/controllers/*.ex`, `lib/lockspire/domain/*.ex`, `lib/lockspire/storage/ecto/*.ex`
**Files scanned:** 9
**Pattern extraction date:** 2024-05-24
