# Phase 76: MTLS Client Authentication - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/domain/client.ex` | model | CRUD | `lib/lockspire/domain/client.ex` | exact |
| `lib/lockspire/storage/ecto/client_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/client_record.ex` | exact |
| `lib/lockspire/security/policy.ex` | config | validation | `lib/lockspire/security/policy.ex` | exact |
| `lib/lockspire/mtls/certificate.ex` | utility | transform | `lib/lockspire/protocol/jwks.ex` | partial |
| `lib/lockspire/protocol/client_auth.ex` | component | request-response | `lib/lockspire/protocol/client_auth.ex` | exact |
| `lib/lockspire/protocol/client_auth/mtls.ex` | component | request-response | `lib/lockspire/protocol/client_auth/private_key_jwt.ex` | role-match |
| `lib/lockspire/web/controllers/token_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/token_controller.ex` | exact |

## Pattern Assignments

### `lib/lockspire/domain/client.ex` (model, CRUD)

**Analog:** `lib/lockspire/domain/client.ex`

**Enum Type Pattern** (lines 6-8):
```elixir
  @type token_endpoint_auth_method ::
          :client_secret_basic | :client_secret_post | :private_key_jwt | :none
```
*Note: Extend this type and the `@type t` definition with the 5 new PKI attributes (`tls_client_auth_subject_dn`, etc).*

---

### `lib/lockspire/storage/ecto/client_record.ex` (model, CRUD)

**Analog:** `lib/lockspire/storage/ecto/client_record.ex`

**Enum Field Pattern** (lines 20-24):
```elixir
    field(
      :token_endpoint_auth_method,
      Ecto.Enum,
      values: [:client_secret_basic, :client_secret_post, :private_key_jwt, :none]
    )
```

**Changeset Cast Pattern** (lines 72-123):
```elixir
  def changeset(record, %Client{} = client) do
    record
    |> cast(Map.from_struct(client), [
      :client_id,
      :client_secret_hash,
      # ... add new tls_client_auth attributes here
    ])
```

---

### `lib/lockspire/security/policy.ex` (config, validation)

**Analog:** `lib/lockspire/security/policy.ex`

**Config List Pattern** (lines 8-13):
```elixir
  @supported_token_endpoint_auth_methods [
    :none,
    :client_secret_basic,
    :client_secret_post,
    :private_key_jwt
  ]
```
*Note: Add `:tls_client_auth` and `:self_signed_tls_client_auth` to this module attribute.*

---

### `lib/lockspire/mtls/certificate.ex` (utility, transform)

**Analog:** `lib/lockspire/protocol/jwks.ex`

**Facade Structure Pattern** (lines 1-7):
```elixir
defmodule Lockspire.Protocol.Jwks do
  @moduledoc """
  Builds a public JWK set from publishable durable signing keys.
  """

  alias Lockspire.Domain.SigningKey
```
*Note: Create a new module `Lockspire.MTLS.Certificate` that acts as a clean facade over `:public_key.pkix_decode_cert/2` returning an Elixir struct (`%{subject_dn: string, sans: %{...}, public_key: binary}`).*

---

### `lib/lockspire/protocol/client_auth.ex` (component, request-response)

**Analog:** `lib/lockspire/protocol/client_auth.ex`

**Auth Evaluation Pattern** (lines 53-56):
```elixir
  defp evaluate_client_credentials(%{body_client_id: id}) when not is_nil(id) do
    {:ok, :none, id, nil}
  end
```
*Note: Update this to return a unified `{:ok, :implicit_client_id, id, nil}` so that MTLS fallback can apply when standard credentials are intentionally omitted, but MTLS is configured.*

**Validation Dispatch Pattern** (lines 151-160):
```elixir
  defp validate_client_secret(%Client{} = client, :private_key_jwt, client_assertion, opts) do
    case PrivateKeyJwt.verify(client, client_assertion, opts) do
      :ok ->
        :ok

      {:error, reason_code} ->
        {:error, invalid_client("Client authentication failed", reason_code)}
    end
  end
```
*Note: Add dispatch clauses for `:tls_client_auth` and `:self_signed_tls_client_auth` that pass `opts[:mtls_cert]` into the new evaluator.*

---

### `lib/lockspire/protocol/client_auth/mtls.ex` (component, request-response)

**Analog:** `lib/lockspire/protocol/client_auth/private_key_jwt.ex`

**Auth Verifier Pattern** (lines 13-23):
```elixir
  @spec verify(Client.t(), String.t(), keyword()) :: :ok | {:error, atom()}
  def verify(%Client{} = client, assertion, opts)
      when is_binary(assertion) and is_list(opts) do
    case resolve_keys(client, opts) do
      {:ok, verified_client, jwks_source} ->
        # ... validation pipeline ...
      {:error, reason} = error ->
        record_failure(reason, client, jwks_source_for_failure(client, nil), opts)
        error
    end
  end
```
*Note: Build a similar pipelined validator `Lockspire.Protocol.ClientAuth.MTLS.verify(client, mtls_cert, method)` ensuring failure states are cleanly handled and recorded.*

**Telemetry Pattern** (lines 228-232):
```elixir
  defp record_failure(reason, %Client{} = client, jwks_source, opts) do
    metadata = failure_metadata(client, reason, jwks_source)
    action = telemetry_action(reason)

    Observability.emit(:client_auth, action, %{}, metadata)
```

---

### `lib/lockspire/web/controllers/token_controller.ex` (controller, request-response)

**Analog:** `lib/lockspire/web/controllers/token_controller.ex`

**Context Passing Pattern** (lines 15-18):
```elixir
    case TokenExchange.exchange(%{
           params: params,
           authorization: authorization,
           dpop: List.first(get_req_header(conn, "dpop")),
           method: conn.method,
```
*Note: Update the params map passed to `TokenExchange.exchange` (and others like Introspection) to include `opts: [... mtls_cert: conn.private[:lockspire_mtls_cert]]` so the core receives the out-of-band certificate.*

## Shared Patterns

### Error Handling
**Source:** `lib/lockspire/protocol/client_auth.ex`
**Apply to:** `Lockspire.Protocol.ClientAuth.MTLS`
```elixir
  defp invalid_client(description, reason_code) do
    oauth_error(401, "invalid_client", description, reason_code)
  end
```

## Metadata

**Analog search scope:** `lib/**/*.ex`
**Files scanned:** ~60
**Pattern extraction date:** 2024-05-24