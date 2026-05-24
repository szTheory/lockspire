# Phase 34: Token Issuance and Refresh/Device Binding - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/web/controllers/token_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/token_controller.ex` | exact |
| `lib/lockspire/web/controllers/token_json.ex` | utility | transform | `lib/lockspire/web/controllers/token_json.ex` | exact |
| `lib/lockspire/protocol/token_exchange.ex` | service | request-response | `lib/lockspire/protocol/token_exchange.ex` | exact |
| `lib/lockspire/protocol/refresh_exchange.ex` | service | request-response | `lib/lockspire/protocol/refresh_exchange.ex` | exact |
| `lib/lockspire/domain/token.ex` | model | CRUD | `lib/lockspire/domain/token.ex` | exact |
| `lib/lockspire/storage/token_store.ex` | service | CRUD | `lib/lockspire/storage/token_store.ex` | exact |
| `lib/lockspire/storage/ecto/token_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/token_record.ex` | exact |
| `lib/lockspire/storage/ecto/repository.ex` | service | CRUD | `lib/lockspire/storage/ecto/repository.ex` | exact |
| `test/lockspire/protocol/token_exchange_test.exs` | test | request-response | `test/lockspire/protocol/token_exchange_test.exs` | exact |
| `test/lockspire/protocol/refresh_exchange_test.exs` | test | request-response | `test/lockspire/protocol/refresh_exchange_test.exs` | exact |
| `test/lockspire/web/token_controller_test.exs` | test | request-response | `test/lockspire/web/token_controller_test.exs` | exact |
| `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | test | request-response | `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/web/controllers/token_controller.ex` (controller, request-response)

**Analog:** `lib/lockspire/web/controllers/token_controller.ex`

**Thin adapter pattern** ([lines 14-25](../../../lib/lockspire/web/controllers/token_controller.ex#L14)):
```elixir
def create(conn, params) do
  authorization = List.first(get_req_header(conn, "authorization"))

  case TokenExchange.exchange(%{
         params: params,
         authorization: authorization,
         opts:
           [client_store: Repository, token_store: Repository]
           |> Keyword.put(:device_authorization_store, Repository)
           |> Keyword.put(:interaction_store, Repository)
           |> Keyword.put(:key_store, Repository)
       }) do
```

**Response/error shaping pattern** ([lines 26-37](../../../lib/lockspire/web/controllers/token_controller.ex#L26)):
```elixir
{:ok, %Success{} = success} ->
  conn
  |> put_cache_headers()
  |> put_status(:ok)
  |> json(TokenJSON.access_token_response(success))

{:error, %Error{} = error} ->
  conn
  |> put_cache_headers()
  |> maybe_put_www_authenticate(error)
  |> put_status(error.status)
  |> json(TokenJSON.error_response(error))
```

Copy this shape when adding DPoP request context: gather headers/method/URI in the controller, pass them inward, keep policy/binding decisions in protocol code.

---

### `lib/lockspire/web/controllers/token_json.ex` (utility, transform)

**Analog:** `lib/lockspire/web/controllers/token_json.ex`

**Canonical token JSON contract** ([lines 7-17](../../../lib/lockspire/web/controllers/token_json.ex#L7)):
```elixir
def access_token_response(%Success{} = success) do
  %{
    access_token: success.access_token,
    token_type: success.token_type,
    expires_in: success.expires_in,
    scope: success.scope
  }
  |> maybe_put_refresh_token(success.refresh_token)
  |> maybe_put_id_token(success.id_token)
end
```

**Canonical error JSON contract** ([lines 19-25](../../../lib/lockspire/web/controllers/token_json.ex#L19)):
```elixir
def error_response(%Error{} = error) do
  %{
    error: error.error,
    error_description: error.error_description
  }
end
```

Phase 34 should keep this file as the single truth for public token response shape; only `success.token_type` needs to become truthful for DPoP.

---

### `lib/lockspire/protocol/token_exchange.ex` (service, request-response)

**Analog:** `lib/lockspire/protocol/token_exchange.ex`

**Shared grant routing + DPoP preflight seam** ([lines 57-90](../../../lib/lockspire/protocol/token_exchange.ex#L57), [120-139](../../../lib/lockspire/protocol/token_exchange.ex#L120), [175-219](../../../lib/lockspire/protocol/token_exchange.ex#L175)):
```elixir
def exchange(request) when is_map(request) do
  params = Map.get(request, :params, Map.get(request, "params", request))

  case normalize_optional_string(params["grant_type"]) do
    "authorization_code" -> exchange_authorization_code(request)
    "refresh_token" -> exchange_refresh_token(request)
    "urn:ietf:params:oauth:grant-type:device_code" -> exchange_device_code(request)
```

```elixir
with :ok <- validate_grant_type(params),
     {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
     :ok <- validate_dpop_preflight(request),
     {:ok, %Token{} = authorization_code, code_hash} <-
       fetch_authorization_code(params, request) do
  handle_code_exchange(client, authorization_code, code_hash, params, request)
```

```elixir
defp validate_dpop_preflight(request) do
  required? = Keyword.get(request_options(request), :dpop_required, false)
  validated_proof = Keyword.get(request_options(request), :dpop_proof)

  cond do
    is_nil(validated_proof) and not required? -> :ok
    is_nil(validated_proof) ->
      {:error, invalid_dpop_proof("A valid DPoP proof is required", :missing_dpop_proof)}
    true -> record_dpop_proof_use(validated_proof, request)
  end
end
```

**Shared issuance pipeline pattern** ([lines 524-549](../../../lib/lockspire/protocol/token_exchange.ex#L524), [612-642](../../../lib/lockspire/protocol/token_exchange.ex#L612), [662-681](../../../lib/lockspire/protocol/token_exchange.ex#L662)):
```elixir
issued_at = now(request)
formatted_refresh_token = maybe_format_refresh_token(client, authorization_code, request)

{access_token, raw_access_token} =
  build_access_token(client, authorization_code, issued_at, formatted_refresh_token, request)
```

```elixir
build_success_response(
  client,
  authorization_code,
  persisted_access_token,
  raw_access_token,
  formatted_token_type(),
  issued_at,
  Map.get(persisted_grant, :refresh_token_raw),
  request
)
```

```elixir
%Success{
  access_token: raw_access_token,
  refresh_token: raw_refresh_token,
  id_token: id_token,
  token_type: token_type,
  expires_in: @access_token_ttl,
  scope: Enum.join(persisted_access_token.scopes, " ")
}
```

**Token builders/persistence pattern** ([lines 953-980](../../../lib/lockspire/protocol/token_exchange.ex#L953), [1013-1051](../../../lib/lockspire/protocol/token_exchange.ex#L1013), [1085-1118](../../../lib/lockspire/protocol/token_exchange.ex#L1085)):
```elixir
access_token = %Token{
  token_hash: formatted_access_token.token_hash,
  token_type: :access_token,
  family_id: family_id,
  generation: 0,
  client_id: client.client_id,
  account_id: authorization_code.account_id,
  interaction_id: authorization_code.interaction_id,
  scopes: authorization_code.scopes,
  audience: authorization_code.audience,
  issued_at: issued_at,
  expires_at: DateTime.add(issued_at, @access_token_ttl, :second)
}
```

```elixir
refresh_token = %Token{
  token_hash: formatted_refresh_token.token_hash,
  token_type: :refresh_token,
  family_id: formatted_refresh_token.token_hash,
  generation: 0,
  client_id: authorization_code.client_id,
  account_id: authorization_code.account_id,
  interaction_id: authorization_code.interaction_id,
  scopes: authorization_code.scopes,
  audience: authorization_code.audience,
  issued_at: issued_at,
  expires_at: DateTime.add(issued_at, @refresh_token_ttl, :second)
}
```

**Current bearer-default switch to replace** ([line 1314](../../../lib/lockspire/protocol/token_exchange.ex#L1314)):
```elixir
defp formatted_token_type, do: "Bearer"
```

Phase 34 should extend these existing builders with one issuance context and `cnf` propagation, not fork separate DPoP grant paths.

---

### `lib/lockspire/protocol/refresh_exchange.ex` (service, request-response)

**Analog:** `lib/lockspire/protocol/refresh_exchange.ex`

**Refresh success contract** ([lines 16-32](../../../lib/lockspire/protocol/refresh_exchange.ex#L16)):
```elixir
with {:ok, refresh_token_hash} <- fetch_refresh_token_hash(params),
     {:ok, result} <- rotate_refresh_token(client, refresh_token_hash, request) do
  emit_success(client, result.presented_refresh_token, result.refresh_token)

  {:ok,
   %Success{
     access_token: result.raw_access_token,
     refresh_token: result.raw_refresh_token,
     id_token: nil,
     token_type: result.token_type,
     expires_in: @access_token_ttl,
     scope: Enum.join(result.access_token.scopes, " ")
   }}
end
```

**Rotation orchestration pattern** ([lines 57-109](../../../lib/lockspire/protocol/refresh_exchange.ex#L57)):
```elixir
with {:ok, %Token{} = presented_refresh_token} <-
       fetch_presented_refresh_token(refresh_token_hash, request) do
  rotate_refresh_token_with_audit(
    client,
    refresh_token_hash,
    presented_refresh_token,
    request
  )
end
```

```elixir
{formatted_access_token, formatted_refresh_token} = format_refresh_rotation_tokens(request)
rotated_at = now(request)
access_token = build_rotated_access_token(client, formatted_access_token, rotated_at)
refresh_token = build_rotated_refresh_token(client, formatted_refresh_token, rotated_at)
```

**Error collapse + audit pattern** ([lines 254-287](../../../lib/lockspire/protocol/refresh_exchange.ex#L254), [290-309](../../../lib/lockspire/protocol/refresh_exchange.ex#L290)):
```elixir
case store.rotate_refresh_token(
       refresh_token_hash,
       client.client_id,
       rotated_at,
       refresh_token,
       access_token
     ) do
  {:ok, %{...} = success} ->
    {:ok, success, [refresh_rotation_audit_event(client, presented, persisted_refresh_token)]}

  {:error, :reuse_detected} ->
    {:durable_error,
     invalid_grant(
       "Refresh token reuse detected; the token family has been revoked",
       :refresh_token_reuse_detected
     ), reuse_audit_events(client, presented_refresh_token)}
```

```elixir
defp refresh_rotation_error(:client_mismatch),
  do: invalid_grant("Refresh token was not issued to this client", :client_mismatch)
```

Phase 34 should preserve this public `invalid_grant` collapse while adding private DPoP binding mismatch reasons and a truthful `token_type`.

---

### `lib/lockspire/domain/token.ex` (model, CRUD)

**Analog:** `lib/lockspire/domain/token.ex`

**Durable token state pattern** ([lines 8-32](../../../lib/lockspire/domain/token.ex#L8)):
```elixir
@type t :: %__MODULE__{
        id: integer() | nil,
        token_hash: String.t(),
        token_type: token_type(),
        jti: String.t() | nil,
        family_id: String.t() | nil,
        generation: non_neg_integer(),
        parent_token_id: integer() | nil,
        client_id: String.t(),
        account_id: String.t() | nil,
        interaction_id: String.t() | nil,
        redirect_uri: String.t() | nil,
        scopes: [String.t()],
        audience: [String.t()],
        cnf: map() | nil,
```

**Default struct pattern** ([lines 34-57](../../../lib/lockspire/domain/token.ex#L34)):
```elixir
defstruct [
  :id,
  :token_hash,
  :token_type,
  :client_id,
  :expires_at,
  ...
  cnf: nil,
  ...
]
```

Phase 34 should reuse `cnf` here as the only durable DPoP binding carrier for both access and refresh tokens.

---

### `lib/lockspire/storage/token_store.ex` (service contract, CRUD)

**Analog:** `lib/lockspire/storage/token_store.ex`

**Typed persistence contract pattern** ([lines 11-43](../../../lib/lockspire/storage/token_store.ex#L11)):
```elixir
@callback store_token(Token.t()) :: {:ok, Token.t()} | {:error, store_error()}
@callback fetch_refresh_token(String.t()) ::
            {:ok, Token.t() | nil} | {:error, store_error()}
@callback rotate_refresh_token(String.t(), String.t(), DateTime.t(), Token.t(), Token.t()) ::
            {:ok,
             %{
               presented_refresh_token: Token.t(),
               refresh_token: Token.t(),
               access_token: Token.t()
             }}
            | {:error, store_error()}
```

If planner introduces refresh-binding arguments, this callback is the persistence seam to extend.

---

### `lib/lockspire/storage/ecto/token_record.ex` (model, CRUD)

**Analog:** `lib/lockspire/storage/ecto/token_record.ex`

**Schema pattern** ([lines 12-33](../../../lib/lockspire/storage/ecto/token_record.ex#L12)):
```elixir
schema "lockspire_tokens" do
  field(:token_hash, :string)
  field(:token_type, Ecto.Enum, values: [:authorization_code, :access_token, :refresh_token])
  ...
  field(:cnf, :map)
  ...
end
```

**Cast/validate pattern** ([lines 37-63](../../../lib/lockspire/storage/ecto/token_record.ex#L37)):
```elixir
record
|> cast(Map.from_struct(token), [
  :token_hash,
  :token_type,
  ...
  :cnf,
  ...
])
|> validate_required([:token_hash, :token_type, :client_id, :expires_at])
|> unique_constraint(:token_hash)
```

**Domain mapping pattern** ([lines 65-90](../../../lib/lockspire/storage/ecto/token_record.ex#L65)):
```elixir
%Token{
  ...
  cnf: record.cnf,
  ...
}
```

No new sidecar DPoP schema is needed for Phase 34; keep using this `cnf` field.

---

### `lib/lockspire/storage/ecto/repository.ex` (service, CRUD)

**Analog:** `lib/lockspire/storage/ecto/repository.ex`

**Store/fetch token primitives** ([lines 542-546](../../../lib/lockspire/storage/ecto/repository.ex#L542), [628-633](../../../lib/lockspire/storage/ecto/repository.ex#L628)):
```elixir
def store_token(%Token{} = token) do
  %TokenRecord{}
  |> TokenRecord.changeset(token)
  |> repo_insert(sensitive: true)
  |> map_one(&TokenRecord.to_domain/1)
end
```

```elixir
def fetch_refresh_token(token_hash) when is_binary(token_hash) do
  TokenRecord
  |> where([token], token.token_hash == ^token_hash)
  |> where([token], token.token_type == :refresh_token)
  |> repo_one(sensitive: true)
  |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
end
```

**Atomic refresh rotation entry point** ([lines 922-942](../../../lib/lockspire/storage/ecto/repository.ex#L922)):
```elixir
def rotate_refresh_token(token_hash, client_id, rotated_at, %Token{} = refresh_token, %Token{} = access_token) do
  case repo().transaction(fn ->
         run_rotate_refresh_token(
           token_hash,
           client_id,
           rotated_at,
           refresh_token,
           access_token
         )
       end) do
    {:ok, {:ok, result}} -> {:ok, result}
    {:ok, {:error, reason}} -> {:error, reason}
    {:error, reason} -> {:error, reason}
  end
end
```

**Lock + compare-and-write pattern** ([lines 1139-1144](../../../lib/lockspire/storage/ecto/repository.ex#L1139), [1488-1495](../../../lib/lockspire/storage/ecto/repository.ex#L1488)):
```elixir
defp locked_refresh_token_query(token_hash) do
  TokenRecord
  |> where([token], token.token_hash == ^token_hash)
  |> where([token], token.token_type == :refresh_token)
  |> lock("FOR UPDATE")
end
```

```elixir
defp run_rotate_refresh_token(token_hash, client_id, rotated_at, refresh_token, access_token) do
  case token_hash |> locked_refresh_token_query() |> repo_one(sensitive: true) do
    nil -> {:error, :not_found}
    %TokenRecord{} = record ->
      rotate_refresh_token_record(record, client_id, rotated_at, refresh_token, access_token)
  end
end
```

**Family rotation semantics to preserve** ([lines 1340-1383](../../../lib/lockspire/storage/ecto/repository.ex#L1340), [1498-1568](../../../lib/lockspire/storage/ecto/repository.ex#L1498)):
```elixir
cond do
  record.client_id != client_id -> {:error, :client_mismatch}
  is_nil(record.family_id) -> {:error, :missing_family_id}
  DateTime.compare(record.expires_at, rotated_at) != :gt -> {:error, :expired}

  not is_nil(record.redeemed_at) or not is_nil(record.revoked_at) ->
    with {:ok, _presented} <- mark_refresh_token_reuse(record, rotated_at, now),
         {:ok, _count} <- revoke_token_family_records(record.family_id, rotated_at, now) do
      {:error, :reuse_detected}
    end
```

```elixir
with {:ok, presented_refresh_token} <- revoke_presented_refresh_token(record, rotated_at),
     {:ok, stored_refresh_token} <- store_rotated_refresh_token(record, refresh_token, rotated_at),
     {:ok, stored_access_token} <-
       store_rotated_access_token(record, stored_refresh_token, access_token, rotated_at) do
  {:ok,
   %{
     presented_refresh_token: presented_refresh_token,
     refresh_token: stored_refresh_token,
     access_token: stored_access_token
   }}
end
```

```elixir
%Token{
  refresh_token
  | family_id: record.family_id,
    generation: record.generation + 1,
    parent_token_id: record.id,
    client_id: record.client_id,
    account_id: refresh_token.account_id || record.account_id,
    interaction_id: refresh_token.interaction_id || record.interaction_id,
    scopes: if(refresh_token.scopes == [], do: record.scopes, else: refresh_token.scopes),
    audience:
      if(refresh_token.audience == [], do: record.audience, else: refresh_token.audience),
    issued_at: refresh_token.issued_at || rotated_at
}
```

This is the exact place to add atomic DPoP refresh-binding comparison and `cnf` carry-forward.

---

### `test/lockspire/protocol/token_exchange_test.exs` (test, request-response)

**Analog:** `test/lockspire/protocol/token_exchange_test.exs`

**DPoP preflight proof pattern** ([lines 190-266](../../../test/lockspire/protocol/token_exchange_test.exs#L190)):
```elixir
assert {:error, error} =
         exchange(...,
           authorization: basic_auth(client.client_id, secret),
           dpop_required: true,
           dpop_replay_store: Repository
         )

assert error.error == "invalid_dpop_proof"
assert error.reason_code == :missing_dpop_proof
```

```elixir
assert {:ok, success} =
         exchange(...,
           dpop_required: true,
           dpop_proof: validated_proof,
           dpop_replay_store: Repository
         )

assert success.token_type == "Bearer"
```

That last assertion is a Phase 34 change point: update existing tests from `"Bearer"` to truthful DPoP mode where binding is present.

**Device flow shared-pipeline proof** ([lines 763-920](../../../test/lockspire/protocol/token_exchange_test.exs#L763)):
```elixir
assert {:ok, success} =
         TokenExchange.exchange(%{
           params: %{
             "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
             "device_code" => "device-code-approved"
           },
           authorization: basic_auth(client.client_id, secret),
           opts: [
             client_store: Repository,
             token_store: Repository,
             interaction_store: Repository,
             key_store: Repository,
             device_authorization_store: Repository,
             access_token_generator: fn -> "device-flow-access-token" end
           ]
         })
```

```elixir
assert success.token_type == "Bearer"
assert success.refresh_token == nil
assert success.id_token == nil
```

Use this file as the primary protocol proof surface for auth-code DPoP issuance, device DPoP issuance, and shared success-contract updates.

---

### `test/lockspire/protocol/refresh_exchange_test.exs` (test, request-response)

**Analog:** `test/lockspire/protocol/refresh_exchange_test.exs`

**Seed + rotation test pattern** ([lines 44-83](../../../test/lockspire/protocol/refresh_exchange_test.exs#L44)):
```elixir
{:ok, refresh_token} =
  Repository.store_token(%Token{
    token_hash: TokenFormatter.hash_token("seed-refresh-token"),
    token_type: :refresh_token,
    family_id: "family-refresh-seed",
    generation: 0,
    client_id: client.client_id,
    account_id: "subject-refresh",
    interaction_id: "interaction-refresh",
    scopes: ["email", "offline_access"],
    audience: ["api.example.com"],
    issued_at: now,
    expires_at: DateTime.add(now, 86_400, :second)
  })
```

```elixir
assert {:ok, success} =
         RefreshExchange.exchange_refresh_token(client, %{
           params: %{"refresh_token" => "seed-refresh-token"},
           opts: [
             token_store: Repository,
             access_token_generator: fn -> "rotated-access-token" end,
             refresh_token_generator: fn -> "rotated-refresh-token" end
           ]
         })
```

**Reuse/audit regression pattern** ([lines 85-165](../../../test/lockspire/protocol/refresh_exchange_test.exs#L85)):
```elixir
assert {:error, error} =
         RefreshExchange.exchange_refresh_token(client, %{...})

assert error.error == "invalid_grant"
assert error.reason_code == :refresh_token_reuse_detected
```

Extend this file for same-key success, wrong-key `invalid_grant`, missing-proof `invalid_dpop_proof` when required, and `cnf` carry-forward assertions.

---

### `test/lockspire/web/token_controller_test.exs` (test, request-response)

**Analog:** `test/lockspire/web/token_controller_test.exs`

**HTTP success contract pattern** ([lines 130-148](../../../test/lockspire/web/token_controller_test.exs#L130)):
```elixir
assert conn.status == 200
assert get_resp_header(conn, "cache-control") == ["no-store"]
assert get_resp_header(conn, "pragma") == ["no-cache"]

body = Jason.decode!(conn.resp_body)

assert Map.keys(body) |> Enum.sort() == ["access_token", "expires_in", "scope", "token_type"]
assert body["token_type"] == "Bearer"
```

**Refresh HTTP contract pattern** ([lines 195-248](../../../test/lockspire/web/token_controller_test.exs#L195)):
```elixir
conn =
  build_conn(:post, "/token", %{
    "grant_type" => "refresh_token",
    "refresh_token" => "controller-refresh-token"
  })
  |> put_req_header("authorization", basic_auth(client.client_id, secret))
```

**Device HTTP contract pattern** ([lines 376-415](../../../test/lockspire/web/token_controller_test.exs#L376), [475-515](../../../test/lockspire/web/token_controller_test.exs#L475)):
```elixir
assert Map.keys(body) |> Enum.sort() == [
         "access_token",
         "expires_in",
         "refresh_token",
         "scope",
         "token_type"
       ]
assert body["token_type"] == "Bearer"
```

```elixir
assert replay_conn.status == 400
body = Jason.decode!(replay_conn.resp_body)
assert body["error"] == "invalid_grant"
```

Use this file for end-to-end controller truth once DPoP headers and `token_type: "DPoP"` are exposed.

---

### `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` (test, request-response)

**Analog:** `test/integration/phase32_device_flow_token_exchange_e2e_test.exs`

**Host-seam-preserving device E2E pattern** ([lines 48-113](../../../test/integration/phase32_device_flow_token_exchange_e2e_test.exs#L48)):
```elixir
first_token_conn =
  build_conn()
  |> post("/lockspire/token", %{
    "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
    "client_id" => client.client_id,
    "device_code" => device_code_body["device_code"]
  })
```

```elixir
assert Map.keys(first_token_body) |> Enum.sort() == [
         "access_token",
         "expires_in",
         "scope",
         "token_type"
       ]

assert first_token_body["token_type"] == "Bearer"
```

Phase 34 should add a sibling integration proof rather than mutate the host verification seam: approval still happens at `/verify`, binding happens only at the winning `/token` request.

## Shared Patterns

### DPoP Validation Output
**Source:** `lib/lockspire/protocol/dpop.ex`
**Apply to:** `token_controller.ex`, `token_exchange.ex`, `refresh_exchange.ex`, related tests

**Validated proof carries `jkt`** ([lines 57-70](../../../lib/lockspire/protocol/dpop.ex#L57)):
```elixir
with {:ok, %__MODULE__{} = decoded} <- decode(jwt),
     :ok <- check_typ(decoded.header),
     {:ok, public_jwk} <- header_public_jwk(decoded.header),
     {:ok, %__MODULE__{} = verified} <- verify_signature(jwt, public_jwk),
     :ok <- validate_claims(verified.claims, opts) do
  {:ok,
   %__MODULE__{
     verified
     | public_jwk: public_jwk,
       jkt: public_jwk |> thumbprint!()
   }}
end
```

**Canonical request-context validation** ([lines 95-103](../../../lib/lockspire/protocol/dpop.ex#L95), [157-182](../../../lib/lockspire/protocol/dpop.ex#L157)):
```elixir
with {:ok, method, target_uri, now, max_age, clock_skew} <- parse_validation_opts(opts),
     :ok <- check_htm(claims, method),
     :ok <- check_htu(claims, target_uri),
     :ok <- check_iat(claims, now, max_age, clock_skew),
     :ok <- check_jti(claims) do
  :ok
end
```

Thread this validated proof into issuance; do not recompute thumbprints from raw maps in Phase 34.

### Effective DPoP Policy
**Source:** `lib/lockspire/protocol/dpop_policy.ex`
**Apply to:** `token_exchange.ex`, `refresh_exchange.ex`, related tests

**Resolved policy struct** ([lines 26-39](../../../lib/lockspire/protocol/dpop_policy.ex#L26)):
```elixir
with {:ok, global_policy} <- normalize_server_policy(server_policy.dpop_policy),
     {:ok, client_policy} <- normalize_client_policy(client) do
  effective_policy = effective_policy(global_policy, client_policy)

  {:ok,
   %Resolved{
     global_policy: global_policy,
     client_policy: client_policy,
     effective_policy: effective_policy,
     dpop_required?: effective_policy == :dpop
   }}
end
```

Resolve one effective policy once and feed it into the shared issuance context; do not scatter client/server policy checks through each grant branch.

### Durable `cnf` Persistence
**Source:** `lib/lockspire/domain/token.ex`, `lib/lockspire/storage/ecto/token_record.ex`
**Apply to:** `token_exchange.ex`, `refresh_exchange.ex`, `repository.ex`, tests

```elixir
@type t :: %__MODULE__{ ..., cnf: map() | nil, ... }
```

```elixir
field(:cnf, :map)
...
|> cast(Map.from_struct(token), [..., :cnf, ...])
...
cnf: record.cnf,
```

Persist `cnf` on the same token records that already carry family state; do not invent a second DPoP binding store.

### Atomic Refresh Compare-And-Write
**Source:** `lib/lockspire/storage/ecto/repository.ex`
**Apply to:** `refresh_exchange.ex`, `token_store.ex`, refresh tests

```elixir
TokenRecord
|> where([token], token.token_hash == ^token_hash)
|> where([token], token.token_type == :refresh_token)
|> lock("FOR UPDATE")
```

```elixir
cond do
  record.client_id != client_id -> {:error, :client_mismatch}
  is_nil(record.family_id) -> {:error, :missing_family_id}
  DateTime.compare(record.expires_at, rotated_at) != :gt -> {:error, :expired}
  ...
end
```

Add DPoP refresh-key comparison inside this transaction boundary so binding validation is atomic with rotation/revocation.

### Truthful Token Surface
**Source:** `lib/lockspire/web/controllers/token_json.ex`, `lib/lockspire/protocol/token_exchange.ex`, `lib/lockspire/protocol/refresh_exchange.ex`
**Apply to:** controller/protocol code and all token endpoint tests

```elixir
%{
  access_token: success.access_token,
  token_type: success.token_type,
  expires_in: success.expires_in,
  scope: success.scope
}
```

```elixir
defp formatted_token_type, do: "Bearer"
```

`token_type` is already passed through end to end. Phase 34 only needs to make the protocol return truthful values.

## No Analog Found

None. Every file implied by the phase already has a direct in-repo analog because this phase extends existing token, refresh, device, and persistence seams rather than adding a new subsystem.

## Metadata

**Analog search scope:** `lib/lockspire/web/controllers`, `lib/lockspire/protocol`, `lib/lockspire/domain`, `lib/lockspire/storage`, `test/lockspire`, `test/integration`, `.planning`
**Files scanned:** 24
**Pattern extraction date:** 2026-04-28
