# Phase 51: Core Protocol & Poll Mode (CIBA) - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 7
**Analogs found:** 6 / 6 (excluding one modification to an existing file)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/domain/ciba_authorization.ex` | model | CRUD | `lib/lockspire/domain/device_authorization.ex` | exact |
| `lib/lockspire/storage/ecto/ciba_authorization_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/device_authorization_record.ex` | exact |
| `lib/lockspire/storage/ciba_authorization_store.ex` | store | CRUD | `lib/lockspire/storage/device_authorization_store.ex` | exact |
| `lib/lockspire/web/controllers/ciba_authorization_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/device_authorization_controller.ex` | exact |
| `lib/lockspire/web/ciba_authorization_json.ex` | view | transform | `lib/lockspire/web/device_authorization_json.ex` | exact |
| `lib/lockspire/protocol/ciba_authorization.ex` | protocol | request-response | `lib/lockspire/protocol/device_authorization.ex` | exact |
| `lib/lockspire/protocol/token_exchange.ex` | protocol | request-response | `exchange_device_code/1` within the same file | exact |

## Pattern Assignments

### 1. `lib/lockspire/domain/ciba_authorization.ex` (model, CRUD)

**Analog:** `lib/lockspire/domain/device_authorization.ex`

**Model state and struct pattern** (lines 14-36):
```elixir
  @statuses [:pending, :approved, :denied, :consumed, :expired]
  @enforce_keys [
    :auth_req_id_hash,
    :client_id,
    :status,
    :expires_at
  ]
  defstruct [
    :id,
    :auth_req_id_hash,
    :client_id,
    :scopes,
    :status,
    :subject_id,
    :approved_at,
    :denied_at,
    :consumed_at,
    :expired_at,
    :effective_poll_interval_seconds,
    :next_poll_allowed_at,
    :expires_at,
    :binding_message
  ]
```

**Issuance Pattern** (lines 62-84):
```elixir
  def issue(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    auth_req_id = Map.fetch!(attrs, :auth_req_id)

    %__MODULE__{
      auth_req_id_hash: Policy.hash_token(auth_req_id),
      client_id: Map.fetch!(attrs, :client_id),
      scopes: List.wrap(Map.get(attrs, :scopes, [])),
      status: :pending,
      subject_id: Map.get(attrs, :subject_id), # CIBA often defines subject at initiation
      approved_at: nil,
      denied_at: nil,
      consumed_at: nil,
      expired_at: nil,
      effective_poll_interval_seconds: @default_poll_interval_seconds,
      next_poll_allowed_at: initial_next_poll_allowed_at(now),
      expires_at: DateTime.add(now, ttl, :second)
    }
  end
```

---

### 2. `lib/lockspire/storage/ecto/ciba_authorization_record.ex` (model, CRUD)

**Analog:** `lib/lockspire/storage/ecto/device_authorization_record.ex`

**Ecto Schema Mapping** (lines 9-28):
```elixir
  schema "lockspire_ciba_authorizations" do
    field(:auth_req_id_hash, :string)
    field(:client_id, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:status, Ecto.Enum, values: @statuses)
    field(:subject_id, :string)
    field(:approved_at, :utc_datetime_usec)
    # ...
    timestamps()
  end
```

**Changeset Pattern** (lines 29-58):
```elixir
  def changeset(record, %CibaAuthorization{} = request) do
    attrs = Map.from_struct(request)

    record
    |> cast(attrs, [
      :auth_req_id_hash,
      :client_id,
      :scopes,
      :status,
      :effective_poll_interval_seconds,
      :next_poll_allowed_at,
      :expires_at
    ])
    |> validate_required([
      :auth_req_id_hash,
      :client_id,
      :status,
      :effective_poll_interval_seconds,
      :next_poll_allowed_at,
      :expires_at
    ])
    |> unique_constraint(:auth_req_id_hash)
  end
```

---

### 3. `lib/lockspire/web/controllers/ciba_authorization_controller.ex` (controller, request-response)

**Analog:** `lib/lockspire/web/controllers/device_authorization_controller.ex`

**Action implementation and Controller pattern** (lines 14-36):
```elixir
  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case CibaAuthorization.authorize(%{
           params: params,
           authorization: authorization,
           opts: [
             client_store: Repository,
             ciba_authorization_store: Repository
           ]
         }) do
      {:ok, %Success{} = success} ->
        conn
        |> put_cache_headers()
        |> put_status(:ok)
        |> json(CibaAuthorizationJSON.success_response(success))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(CibaAuthorizationJSON.error_response(error))
    end
  end
```

---

### 4. `lib/lockspire/protocol/ciba_authorization.ex` (protocol, request-response)

**Analog:** `lib/lockspire/protocol/device_authorization.ex`

**Protocol structure** (lines 40-62):
```elixir
  def authorize(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", %{}))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))
    now = now(request)

    with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, %CibaAuthorizationState{} = ciba_auth} <-
           persist_ciba_authorization(params, client, request, now) do

      {:ok,
       %Success{
         auth_req_id: ciba_auth.auth_req_id,
         expires_in: DateTime.diff(ciba_auth.expires_at, now, :second),
         interval: ciba_auth.effective_poll_interval_seconds
       }}
    else
      {:error, %Error{} = error} ->
        {:error, error}
    end
  end
```

---

### 5. `lib/lockspire/protocol/token_exchange.ex` (protocol, request-response)

**Analog:** Existing `exchange_device_code/1` within `lib/lockspire/protocol/token_exchange.ex`

**Dispatch Pattern** (lines 75-80):
```elixir
      "urn:openid:params:grant-type:ciba" ->
        exchange_ciba(request)
```

**Exchange Pipeline Pattern** (lines 142-156):
```elixir
  defp exchange_ciba(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, %CibaAuthorizationState{} = ciba_authorization} <-
           fetch_ciba_authorization_for_exchange(params, client, request),
         {:ok, issuance_context} <- TokenEndpointDPoP.resolve_context(client, request),
         {:ok, %Success{} = success} <-
           redeem_ciba_authorization(client, ciba_authorization, issuance_context, request) do
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        emit_failure(error, params, request)
        {:error, error}
    end
  end
```

**Poll Outcome Mapping** (lines 201-301):
*Implement similar pattern handling `:approved_ready`, `:pending`, `:slow_down`, `:denied`, `:expired`, `:client_mismatch`, `:consumed`, and `:invalid_grant` using `map_ciba_poll_outcome/2`.*

---

## Shared Patterns

### Error Handling
**Source:** `lib/lockspire/protocol/token_exchange.ex` and `DeviceAuthorization`
**Apply to:** Protocol layer logic
```elixir
  defp oauth_error(status, error, description, reason_code) do
    %Error{
      status: status,
      error: error,
      error_description: description,
      reason_code: reason_code
    }
  end
```

### Auditing
**Source:** `lib/lockspire/protocol/token_exchange.ex`
**Apply to:** Any store operation modifying grants. Use the `transact_with_audit_event/3` pattern inside `redeem_ciba_authorization`.

## Metadata

**Analog search scope:** `lib/lockspire/domain/`, `lib/lockspire/web/controllers/`, `lib/lockspire/protocol/`, `lib/lockspire/storage/`
**Files scanned:** 7
**Pattern extraction date:** 2024-05-18