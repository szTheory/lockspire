# Phase 48: Protocol Foundation & Storage (OAuth 2.0 Token Exchange - RFC 8693) - Pattern Map

**Mapped:** 2024-05-05
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/token_exchange.ex` | protocol | request-response | `lib/lockspire/protocol/token_exchange.ex` | exact |
| `lib/lockspire/protocol/rfc8693_exchange.ex` (or similar new handler) | protocol | transform | `lib/lockspire/protocol/refresh_exchange.ex` | role-match |
| `lib/lockspire/storage/ecto/repository.ex` | storage | CRUD | `lib/lockspire/storage/ecto/repository.ex` | exact |

## Pattern Assignments

### `lib/lockspire/protocol/token_exchange.ex` (protocol, request-response)

**Analog:** `lib/lockspire/protocol/token_exchange.ex`

**Pattern for routing new grant type** (lines 48-69):
```elixir
  @spec exchange(map()) :: result()
  def exchange(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))

    case normalize_optional_string(params["grant_type"]) do
      "authorization_code" ->
        exchange_authorization_code(request)

      "refresh_token" ->
        exchange_refresh_token(request)

      "urn:ietf:params:oauth:grant-type:device_code" ->
        exchange_device_code(request)

      "urn:ietf:params:oauth:grant-type:token-exchange" ->
        # NEW PATTERN
        exchange_rfc8693(request)

      _other ->
        # ...
```

---

### `lib/lockspire/protocol/rfc8693_exchange.ex` (protocol, transform)

**Analog:** `lib/lockspire/protocol/refresh_exchange.ex`

**Imports pattern** (lines 5-11):
```elixir
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.TokenEndpointDPoP
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Protocol.TokenFormatter
```

**Core Token Exchange handler pattern** (lines 17-38):
```elixir
  @spec exchange_refresh_token(Client.t(), map()) :: {:ok, Success.t()} | {:error, Error.t()}
  def exchange_refresh_token(%Client{} = client, request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))

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
    else
      {:error, %Error{} = error} ->
        emit_failure(client, error)
        {:error, error}
    end
  end
```

**Token lineage inheritance & issuance pattern** (lines 174-188):
```elixir
  defp build_rotated_access_token(
         %Client{} = client,
         formatted_access_token,
         rotated_at,
         context,
         %Token{} = source_token
       ) do
    %Token{
      token_hash: formatted_access_token.token_hash,
      token_type: :access_token,
      client_id: client.client_id,
      account_id: source_token.account_id,
      sid: source_token.sid,
      cnf: context.cnf,
      expires_at: DateTime.add(rotated_at, @access_token_ttl, :second)
      # NEW: Lineage Tracking
      # parent_token_id: source_token.id
      # family_id: source_token.family_id || source_token.token_hash
      # NEW: Enforce scope downscoping from source_token.scopes
    }
  end
```

---

### `lib/lockspire/storage/ecto/repository.ex` (storage, CRUD)

**Analog:** `lib/lockspire/protocol/token_exchange.ex` and `lib/lockspire/storage/ecto/repository.ex`

**Storage transaction pattern** (`lib/lockspire/protocol/token_exchange.ex` lines 799-817):
```elixir
    transact_with_audit_event(token_store(request), audit_event, fn ->
      with {:ok, %{access_token: %Token{} = persisted_access_token}} <-
             token_store(request).redeem_authorization_code(code_hash, issued_at, access_token),
           {:ok, %Token{} = persisted_refresh_token} <-
             token_store(request).store_token(refresh_token) do
        %{
          access_token: persisted_access_token,
          refresh_token: persisted_refresh_token,
          refresh_token_raw: formatted_refresh_token.token
        }
      else
        {:error, reason} -> {:error, reason}
      end
    end)
```

## Shared Patterns

### Error Handling
**Source:** `lib/lockspire/protocol/token_exchange.ex`
**Apply to:** New protocol handler
```elixir
  defp invalid_grant(description, reason_code) do
    oauth_error(400, "invalid_grant", description, reason_code)
  end

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
**Apply to:** Token Exchange audit events
```elixir
  defp audit_event(action, outcome, reason_code, actor, %Token{} = authorization_code) do
    %{
      action: action,
      outcome: outcome,
      reason_code: reason_code,
      actor: actor,
      resource: %{
        type: :authorization_code,
        id: to_string(authorization_code.id || authorization_code.interaction_id)
      },
      metadata: %{
        client_id: authorization_code.client_id,
        interaction_id: authorization_code.interaction_id,
        subject_id: authorization_code.account_id
      }
    }
  end
```

## Metadata

**Analog search scope:** `lib/lockspire/protocol/`, `lib/lockspire/storage/ecto/`, `lib/lockspire/domain/`
**Files scanned:** 5
**Pattern extraction date:** 2024-05-05
