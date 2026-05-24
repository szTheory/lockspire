# Phase 33: DPoP Proof Validation and Replay State - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/dpop.ex` | protocol/service | request-response | `lib/lockspire/protocol/jar.ex` | role-match |
| `lib/lockspire/storage/dpop_replay_store.ex` | behavior | CRUD | `lib/lockspire/storage/device_authorization_store.ex` | role-match |
| `lib/lockspire/storage/ecto/dpop_replay_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/token_record.ex` | role-match |
| `priv/repo/migrations/*_add_lockspire_dpop_replay_state*.exs` | migration | transform | `priv/repo/migrations/20260428130000_extend_lockspire_device_authorizations_polling_state.exs` | role-match |
| `lib/lockspire/storage/ecto/repository.ex` | service | CRUD | `lib/lockspire/storage/ecto/repository.ex` | exact |
| `lib/lockspire/domain/client.ex` | model | transform | `lib/lockspire/domain/client.ex` | exact |
| `lib/lockspire/storage/ecto/client_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/client_record.ex` | exact |
| `lib/lockspire/domain/server_policy.ex` | model | transform | `lib/lockspire/domain/server_policy.ex` | exact |
| `lib/lockspire/storage/ecto/server_policy_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/server_policy_record.ex` | exact |
| `lib/lockspire/admin/server_policy.ex` and/or `lib/lockspire/admin/clients.ex` | service | request-response | `lib/lockspire/admin/server_policy.ex` and `lib/lockspire/admin/clients.ex` | exact |
| `lib/lockspire/protocol/dpop_policy.ex` | protocol/service | transform | `lib/lockspire/protocol/par_policy.ex` | role-match |
| `lib/lockspire/web/controllers/token_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/token_controller.ex` | exact |
| `test/lockspire/protocol/*`, `test/lockspire/storage/ecto/*`, `test/lockspire/web/*`, `test/integration/*` | test | request-response / CRUD | existing phase 32 protocol, repository, controller, and integration tests | exact |

## Pattern Assignments

### `lib/lockspire/protocol/dpop.ex`

**Analog:** `lib/lockspire/protocol/jar.ex`

**JOSE decode + verify shape** ([lib/lockspire/protocol/jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:39)):
```elixir
@spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_jwt}
def decode(jwt) when is_binary(jwt) do
  try do
    payload_struct = JOSE.JWT.peek_payload(jwt)
    protected_struct = JOSE.JWT.peek_protected(jwt)
    {_modules, claims} = JOSE.JWT.to_map(payload_struct)
    {_modules, header} = JOSE.JWS.to_map(protected_struct)
    {:ok, %__MODULE__{claims: claims, header: header}}
  rescue
    _ -> {:error, :invalid_jwt}
  end
end
```

**Allowed-algorithm and explicit `alg=none` rejection pattern** ([lib/lockspire/protocol/jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:32)):
```elixir
@allowed_algorithms ~w(RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 EdDSA)
```

**Per-key JOSE verification loop** ([lib/lockspire/protocol/jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:141)):
```elixir
defp verify_against_keys(jwt, public_keys) do
  Enum.reduce_while(public_keys, {:error, :invalid_signature}, fn jwk, _acc ->
    case verify_with_single_jwk(jwt, jwk) do
      {:ok, _} = ok -> {:halt, ok}
      {:error, :invalid_typ} = err -> {:halt, err}
      {:error, :invalid_signature} -> {:cont, {:error, :invalid_signature}}
    end
  end)
end
```

**Claims-validation pipeline shape** ([lib/lockspire/protocol/jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:217)):
```elixir
def validate_claims(%__MODULE__{claims: claims}, opts) when is_map(claims) and is_list(opts) do
  with {:ok, expected_client_id, expected_audience, now, leeway, max_age} <- parse_opts(opts),
       :ok <- check_issuer(claims, expected_client_id),
       :ok <- check_audience(claims, expected_audience),
       :ok <- check_expiration(claims, now, leeway, max_age),
       :ok <- check_not_before(claims, now, leeway),
       :ok <- check_issued_at(claims, now, leeway) do
    :ok
  end
end
```

**Why this is the best analog:** DPoP proof validation has the same Lockspire-owned shape as JAR: parse compact JWT, verify JOSE signature against client-controlled keys, then run explicit protocol claim validation with typed failure reasons. Reuse this discipline for `htm`, `htu`, `iat`, and `jti`.

### `lib/lockspire/storage/dpop_replay_store.ex` and `lib/lockspire/storage/ecto/repository.ex`

**Analog:** `lib/lockspire/storage/device_authorization_store.ex` + repository row-lock consumers

**Behavior-surface pattern:** expose a narrow contract that returns typed outcomes, not raw repo tuples. Device polling already does this through a dedicated store behavior and repository-backed implementation. Mirror that for `put_proof_jti/4` or `record_proof_use/4`.

**Durable single-use / replay gate** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:339)):
```elixir
def record_device_poll(device_code_hash, client_id, now)
    when is_binary(device_code_hash) and is_binary(client_id) and is_struct(now, DateTime) do
  transact(fn ->
    device_code_hash
    |> locked_device_authorization_by_device_code_query()
    |> repo_one(sensitive: true)
    |> evaluate_device_poll(client_id, now)
  end)
end
```

**Replay-safe consume under `FOR UPDATE`** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:350)):
```elixir
def consume_device_authorization(verification_handle, client_id, now)
    when is_binary(verification_handle) and is_binary(client_id) and is_struct(now, DateTime) do
  transact(fn ->
    verification_handle
    |> locked_device_authorization_query()
    |> repo().one()
    |> consume_device_authorization_record(client_id, now)
  end)
end
```

**Deterministic replay / terminal-state mapping** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1179)):
```elixir
record.status == :pending and DateTime.compare(now, record.next_poll_allowed_at) == :lt ->
  next_interval = record.effective_poll_interval_seconds + 5
  next_poll_allowed_at = DateTime.add(record.next_poll_allowed_at, next_interval, :second)
```

**Single-winner transition pattern** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1223)):
```elixir
defp consume_device_authorization_record(
       %DeviceAuthorizationRecord{status: :approved} = record,
       _client_id,
       now
     ) do
  if DateTime.compare(record.expires_at, now) == :gt do
    record
    |> DeviceAuthorizationRecord.update_changeset(%{
      status: :consumed,
      consumed_at: now,
      updated_at: DateTime.utc_now()
    })
```

**Authorization-code single-use analog** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:852)):
```elixir
def redeem_authorization_code(token_hash, redeemed_at, %Token{} = access_token)
    when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
  transact(fn ->
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :authorization_code)
    |> lock("FOR UPDATE")
```

**Guidance:** DPoP replay storage should copy the `transact -> lock -> classify -> update -> typed outcome` shape. Avoid process-local ETS-style assumptions; Phase 33 explicitly wants repo-proven cross-node durability.

### `lib/lockspire/storage/ecto/dpop_replay_record.ex`

**Analog:** `lib/lockspire/storage/ecto/token_record.ex`

**Schema + changeset pattern** ([lib/lockspire/storage/ecto/token_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/token_record.ex:12)):
```elixir
schema "lockspire_tokens" do
  field(:token_hash, :string)
  field(:token_type, Ecto.Enum, values: [:authorization_code, :access_token, :refresh_token])
  field(:jti, :string)
  field(:cnf, :map)
  field(:issued_at, :utc_datetime_usec)
  field(:expires_at, :utc_datetime_usec)
  timestamps()
end
```

**Map-from-domain cast discipline** ([lib/lockspire/storage/ecto/token_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/token_record.ex:37)):
```elixir
def changeset(record, %Token{} = token) do
  record
  |> cast(Map.from_struct(token), [...])
  |> validate_required([:token_hash, :token_type, :client_id, :expires_at])
  |> unique_constraint(:token_hash)
end
```

**Round-trip back into a domain struct** ([lib/lockspire/storage/ecto/token_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/token_record.ex:65)):
```elixir
def to_domain(%__MODULE__{} = record) do
  %Token{
    id: record.id,
    token_hash: record.token_hash,
    jti: record.jti,
    cnf: record.cnf,
    ...
  }
end
```

**Guidance:** For DPoP replay state, stay additive and explicit: hashed replay key, thumbprint, `jti`, `htu`, `htm`, `expires_at`, timestamps. Keep it a first-class schema with a first-class domain mapper if the replay state is read outside one repository helper.

### `lib/lockspire/domain/token.ex` and `lib/lockspire/storage/ecto/token_record.ex`

**Analog:** same files

**`cnf` persistence seam already exists** ([lib/lockspire/domain/token.ex](/Users/jon/projects/lockspire/lib/lockspire/domain/token.ex:8)):
```elixir
@type t :: %__MODULE__{
        ...
        audience: [String.t()],
        cnf: map() | nil,
        code_challenge: String.t() | nil,
        ...
      }
```

**Default struct field is explicit, not hidden in metadata** ([lib/lockspire/domain/token.ex](/Users/jon/projects/lockspire/lib/lockspire/domain/token.ex:47)):
```elixir
scopes: [],
audience: [],
cnf: nil,
code_challenge: nil,
```

**Ecto schema already persists `cnf` verbatim** ([lib/lockspire/storage/ecto/token_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/token_record.ex:23)):
```elixir
field(:audience, {:array, :string}, default: [])
field(:cnf, :map)
field(:code_challenge, :string)
```

**Guidance:** Phase 33 should not invent a separate DPoP binding store for issued tokens. The existing `Token.cnf` seam is the right place to persist `jkt` for later userinfo/introspection enforcement in later phases.

### `lib/lockspire/domain/client.ex`, `lib/lockspire/storage/ecto/client_record.ex`, and `lib/lockspire/admin/clients.ex`

**Analog:** same files

**Client struct surface for explicit operator policy** ([lib/lockspire/domain/client.ex](/Users/jon/projects/lockspire/lib/lockspire/domain/client.ex:25)):
```elixir
token_endpoint_auth_method: token_endpoint_auth_method(),
pkce_required: boolean(),
par_policy: par_policy(),
subject_type: subject_type(),
...
metadata: map(),
```

**Ecto enum field for client-level policy, plus update allowlist** ([lib/lockspire/storage/ecto/client_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/client_record.ex:29)):
```elixir
field(:pkce_required, :boolean, default: true)
field(:par_policy, Ecto.Enum, values: [:inherit, :required, :optional], default: :inherit)
```

**Safe mutable-field gate** ([lib/lockspire/storage/ecto/client_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/client_record.ex:131)):
```elixir
def update_changeset(record, attrs) do
  record
  |> cast(attrs, [
    :name,
    :redirect_uris,
    :allowed_scopes,
    :logo_uri,
    :tos_uri,
    :policy_uri,
    :contacts,
    :par_policy,
    :metadata,
```

**Admin command boundary for explicit client overrides** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:111)):
```elixir
with {:ok, %Client{} = client} <- get_client(client_id),
     :ok <- reject_immutable_changes(attrs),
     :ok <- validate_safe_update(attrs) do
  Repository.update_client(client, normalize_update_attrs(attrs))
end
```

**Enum normalization pattern** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:316)):
```elixir
defp normalize_par_policy(:inherit), do: {:ok, :inherit}
defp normalize_par_policy(:required), do: {:ok, :required}
defp normalize_par_policy(:optional), do: {:ok, :optional}
```

**Test analog for client-surface validation** ([test/lockspire/admin/clients_test.exs](/Users/jon/projects/lockspire/test/lockspire/admin/clients_test.exs:228)):
```elixir
test "update_client/2 accepts only inherit, required, and optional for par_policy" do
  ...
  assert {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: "strict"}]} =
           Clients.update_client("admin-client", %{par_policy: "strict"})
end
```

**Guidance:** DPoP mode should follow this exact Lockspire pattern: explicit enum-like client field, explicit admin normalization, explicit mutable-field allowlist, and repo-backed tests for accepted/rejected values.

### `lib/lockspire/domain/server_policy.ex`, `lib/lockspire/storage/ecto/server_policy_record.ex`, `lib/lockspire/admin/server_policy.ex`, and `lib/lockspire/protocol/dpop_policy.ex`

**Analog:** server policy + PAR policy

**Server-wide default shape** ([lib/lockspire/domain/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/domain/server_policy.ex:9)):
```elixir
@type t :: %__MODULE__{
        id: integer() | nil,
        par_policy: par_policy(),
        registration_policy: registration_policy(),
        ...
      }
```

**Singleton-row persistence pattern** ([lib/lockspire/storage/ecto/server_policy_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/server_policy_record.ex:13)):
```elixir
schema "lockspire_server_policies" do
  field(:par_policy, Ecto.Enum, values: [:optional, :required], default: :optional)
  field(:registration_policy, Ecto.Enum,
    values: [:disabled, :initial_access_token, :open],
    default: :disabled
  )
```

**Lost-update protection for policy writes** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:131)):
```elixir
def update_server_policy(mutator) when is_function(mutator, 1) do
  transact(fn ->
    ...
    |> lock("FOR UPDATE")
```

**Admin normalization + merge pattern** ([lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:34)):
```elixir
def put_server_policy(mode) do
  with {:ok, normalized_mode} <- normalize_par_policy(mode) do
    Repository.update_server_policy(fn %ServerPolicy{} = current ->
      %ServerPolicy{current | par_policy: normalized_mode}
    end)
  end
end
```

**Effective-policy resolver analog** ([lib/lockspire/protocol/par_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/par_policy.ex:26)):
```elixir
def resolve_effective_policy(%ServerPolicy{} = server_policy, client) do
  client_policy = normalize_client_policy(client)
  effective_policy = effective_policy(server_policy.par_policy, client_policy)

  %Resolved{
    global_policy: server_policy.par_policy,
    client_policy: client_policy,
    effective_policy: effective_policy,
    par_required?: effective_policy == :required
  }
end
```

**Concurrency proof analog** ([test/lockspire/admin/server_policy_test.exs](/Users/jon/projects/lockspire/test/lockspire/admin/server_policy_test.exs:130)):
```elixir
test "concurrent put_server_policy/1 and put_dcr_policy/1 do not lose updates" do
  ...
  assert final.par_policy == :required
  assert final.registration_policy == :initial_access_token
end
```

**Guidance:** If Phase 33 adds global DPoP defaults, copy this exact `ServerPolicy` + `update_server_policy/1` + pure resolver pattern. Keep resolution logic in a small protocol module, not in controllers or LiveView handlers.

### `lib/lockspire/protocol/token_exchange.ex` and `lib/lockspire/web/controllers/token_controller.ex`

**Analog:** same files

**Grant dispatch stays protocol-owned** ([lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:56)):
```elixir
def exchange(request) when is_map(request) do
  params = Map.get(request, :params, Map.get(request, "params", request))

  case normalize_optional_string(params["grant_type"]) do
    "authorization_code" -> exchange_authorization_code(request)
    "refresh_token" -> exchange_refresh_token(request)
    "urn:ietf:params:oauth:grant-type:device_code" -> exchange_device_code(request)
```

**Client auth conversion to endpoint-safe error struct** ([lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:157)):
```elixir
defp authenticate_client(params, authorization, request) do
  case ClientAuth.authenticate(params, authorization, client_auth_options(request)) do
    {:ok, %Client{} = client} -> {:ok, client}
    {:error, %ClientAuth.Error{} = error} ->
      {:error, %Error{status: error.status, error: error.error, ...}}
  end
end
```

**Success assembly stays centralized** ([lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:528)):
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

**Thin controller pattern** ([lib/lockspire/web/controllers/token_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/token_controller.ex:14)):
```elixir
def create(conn, params) do
  authorization = List.first(get_req_header(conn, "authorization"))

  case TokenExchange.exchange(%{
         params: params,
         authorization: authorization,
         opts: [client_store: Repository, token_store: Repository]
```

**Guidance:** DPoP header parsing may start in the controller only as header extraction, but all proof validation, replay checks, and token-mode decisions belong in protocol modules and repo-backed services. Preserve the thin-controller boundary.

### Test Layout

**Protocol proof analog:** [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:47)
- Use `setup_all` for repo/config boot, `setup` for sandbox checkout and telemetry hooks.
- Assert both returned structs and durable side effects.
- Keep helper functions at the bottom for clients, keys, and request assembly.

**JOSE-focused unit proof analog:** [test/lockspire/protocol/jar_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/jar_test.exs:34)
- Use per-describe key generation with `JOSE.JWK.generate_key/1`.
- Cover happy path, bad signature, invalid key material, tampering, and prohibited header values.
- This is the best analog for DPoP proof parser/validator tests.

**Repository single-use / replay proof analog:** [test/lockspire/storage/ecto/repository_device_authorization_test.exs](/Users/jon/projects/lockspire/test/lockspire/storage/ecto/repository_device_authorization_test.exs:205)
- Group replay/durability semantics under one `describe`.
- Assert persisted state after each transition, not only return tuples.
- Include “wins only once” proof as the core replay-storage invariant.

**Controller HTTP contract analog:** [test/lockspire/web/token_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/token_controller_test.exs:116)
- Build real `Conn`s against mounted routes.
- Assert cache headers, JSON shape, and public OAuth error surface.
- Mirror protocol cases at the HTTP layer rather than inventing controller-only behavior.

**Policy/admin proof analog:** [test/lockspire/admin/server_policy_test.exs](/Users/jon/projects/lockspire/test/lockspire/admin/server_policy_test.exs:27) and [test/lockspire/admin/clients_test.exs](/Users/jon/projects/lockspire/test/lockspire/admin/clients_test.exs:228)
- Round-trip accepted values through admin boundary and repository fetch.
- Reject invalid enum values with structured `%{field, reason, detail}` errors.
- Include concurrency proof when a singleton or merge-update policy row is involved.

**Integration proof analog:** [test/integration/phase32_device_flow_token_exchange_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase32_device_flow_token_exchange_e2e_test.exs:48)
- Use generated-host endpoint and real mounted routes.
- Prove one successful end-to-end exchange, then immediate replay collapse.
- Phase 36’s browser-style auth-code DPoP and CLI/device DPoP E2E tests should copy this style.

## Shared Patterns

### Protocol Request Validation
**Sources:** [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:56), [lib/lockspire/protocol/jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:217), [lib/lockspire/protocol/registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:123)
**Apply to:** `lib/lockspire/protocol/dpop.ex`, `lib/lockspire/protocol/dpop_policy.ex`

Pattern: parse request inputs early, then use a `with` pipeline that returns typed domain success or typed protocol error. Lockspire prefers explicit `reason_code`/typed atoms over ad hoc exceptions.

### JOSE / JWK Handling
**Sources:** [lib/lockspire/protocol/jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:79), [test/lockspire/protocol/jar_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/jar_test.exs:34)
**Apply to:** DPoP proof parsing, signature verification, and thumbprint derivation tests

Pattern: decode with JOSE, normalize client JWKS into JOSE keys, verify against an explicit algorithm allowlist, and reject malformed/unsupported input with deterministic reasons.

### Durable Replay / Single-Use Storage
**Sources:** [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:339), [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:852), [test/lockspire/storage/ecto/repository_device_authorization_test.exs](/Users/jon/projects/lockspire/test/lockspire/storage/ecto/repository_device_authorization_test.exs:424)
**Apply to:** DPoP replay state repository APIs and tests

Pattern: `transact` + `FOR UPDATE` + typed terminal outcomes + post-write persistence assertions.

### `cnf` Persistence
**Sources:** [lib/lockspire/domain/token.ex](/Users/jon/projects/lockspire/lib/lockspire/domain/token.ex:8), [lib/lockspire/storage/ecto/token_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/token_record.ex:25), [lib/lockspire/protocol/introspection.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/introspection.ex:126)
**Apply to:** later DPoP-bound token issuance and introspection/userinfo truth

Pattern: keep confirmation state on the token domain/schema, not in side metadata or recomputed-only state.

### Explicit Client / Policy Configuration
**Sources:** [lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:111), [lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:34), [lib/lockspire/protocol/par_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/par_policy.ex:26)
**Apply to:** DPoP client mode and any global DPoP default

Pattern: explicit enum field on domain + Ecto.Enum on record + normalized admin write path + pure effective-policy resolver.

### Thin Controller / Protocol-Owned Logic
**Sources:** [lib/lockspire/web/controllers/token_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/token_controller.ex:14), [lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:13)
**Apply to:** token and userinfo DPoP entry points

Pattern: controller extracts headers, injects repository-backed opts, delegates to protocol module, and serializes/cache-headers the result.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | - | - | Lockspire already has strong role-match analogs for JOSE validation, row-locked single-use storage, policy resolution, thin controllers, and phase-shaped tests. |

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/storage`, `lib/lockspire/domain`, `lib/lockspire/admin`, `lib/lockspire/web`, `test/lockspire`, `test/integration`
**Files scanned:** 30+
**Pattern extraction date:** 2026-04-28
