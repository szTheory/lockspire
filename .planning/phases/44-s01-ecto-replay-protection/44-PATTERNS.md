# Phase 44: Ecto Replay Protection & Client Config Strategy - Pattern Map

**Mapped:** 2024-05-03
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/client_auth.ex` | protocol/utility | request-response | `lib/lockspire/protocol/client_auth.ex` (self) | exact |
| `lib/lockspire/domain/used_jti.ex` | schema | CRUD | `lib/lockspire/domain/dpop_replay.ex` | exact |
| `lib/lockspire/storage/ecto/used_jti_record.ex` | schema | CRUD | `lib/lockspire/storage/ecto/dpop_replay_record.ex` | exact |
| `priv/repo/migrations/*_create_lockspire_used_jtis.exs` | migration | N/A | `priv/repo/migrations/20260428150000_add_lockspire_dpop_replay_state.exs` | exact |
| `lib/lockspire/workers/pruner.ex` | worker/job | batch | `lib/lockspire/workers/pruner.ex` (self) | exact |
| `lib/lockspire/protocol/registration.ex` | protocol/utility | request-response | `lib/lockspire/protocol/registration.ex` (self) | exact |

## Pattern Assignments

### `lib/lockspire/protocol/client_auth.ex` (protocol/utility, request-response)

**Analog:** `lib/lockspire/protocol/client_auth.ex`

**Core Pattern (Parsing Credentials)** (lines 40-58):
```elixir
    cond do
      has_header? and present?(body_client_secret) ->
        {:error,
         invalid_client("Token endpoint authentication methods must not be mixed", :mixed_auth)}

      has_header? ->
        parse_basic_authorization(authorization)

      present?(body_client_secret) and present?(body_client_id) ->
        {:ok, :client_secret_post, body_client_id, body_client_secret}

      present?(body_client_id) ->
        {:ok, :none, body_client_id, nil}

      true ->
        {:error, invalid_client("Missing client authentication", :missing_client_auth)}
    end
```
*Note for planner: Add a branch here to parse `client_assertion` and `client_assertion_type` (for `private_key_jwt`). Also enforce 10-minute maximum lifetime on the JWT.*

**Error Handling Pattern** (lines 115-127):
```elixir
  defp invalid_client(description, reason_code) do
    oauth_error(401, "invalid_client", description, reason_code)
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

### `lib/lockspire/domain/used_jti.ex` & `lib/lockspire/storage/ecto/used_jti_record.ex` (schema, CRUD)

**Analog:** `lib/lockspire/domain/dpop_replay.ex` & `lib/lockspire/storage/ecto/dpop_replay_record.ex`

**Domain Struct Pattern** (`lib/lockspire/domain/dpop_replay.ex` lines 1-10):
```elixir
defmodule Lockspire.Domain.DpopReplay do
  @moduledoc """
  Durable DPoP proof replay state for the supported acceptance window.
  """

  @enforce_keys [:replay_key, :jti, :htm, :htu, :jkt, :seen_at, :expires_at]
  defstruct [
    :id,
...
```
*Note for planner: Adapt for `:client_id`, `:jti`, `:expires_at`.*

**Ecto Schema Pattern** (`lib/lockspire/storage/ecto/dpop_replay_record.ex` lines 12-29):
```elixir
  schema "lockspire_dpop_replay" do
    field(:replay_key, :string)
    field(:jti, :string)
    field(:htm, :string)
    field(:htu, :string)
    field(:jkt, :string)
    field(:seen_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(record, %DpopReplay{} = replay) do
    record
    |> cast(Map.from_struct(replay), [:replay_key, :jti, :htm, :htu, :jkt, :seen_at, :expires_at])
    |> validate_required([:replay_key, :jti, :htm, :htu, :jkt, :seen_at, :expires_at])
    |> unique_constraint(:replay_key)
  end
```
*Note for planner: Use standard auto-incrementing `id`. Ensure `expires_at` is included for the pruner. Add `unique_constraint([:client_id, :jti])`.*

### `priv/repo/migrations/*_create_lockspire_used_jtis.exs` (migration, N/A)

**Analog:** `priv/repo/migrations/20260428150000_add_lockspire_dpop_replay_state.exs`

**Migration Pattern** (lines 4-18):
```elixir
  def change do
    create table(:lockspire_dpop_replay) do
      add :replay_key, :string, null: false
      add :jti, :string, null: false
      add :htm, :string, null: false
      add :htu, :text, null: false
      add :jkt, :string, null: false
      add :seen_at, :utc_datetime_usec, null: false
      add :expires_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_dpop_replay, [:replay_key])
    create index(:lockspire_dpop_replay, [:expires_at])
  end
```
*Note for planner: Create `lockspire_used_jtis` with `client_id`, `jti`, `expires_at`. Create `unique_index(:lockspire_used_jtis, [:client_id, :jti])` and `index(:lockspire_used_jtis, [:expires_at])`.*

### `lib/lockspire/workers/pruner.ex` (worker/job, batch)

**Analog:** `lib/lockspire/workers/pruner.ex`

**Pruner Schemas Pattern** (lines 17-26):
```elixir
  @schemas [
    TokenRecord,
    DpopReplayRecord,
    PushedAuthorizationRequestRecord,
    InteractionRecord,
    DeviceAuthorizationRecord,
    InitialAccessTokenRecord
  ]
```
*Note for planner: Add `Lockspire.Storage.Ecto.UsedJtiRecord` to the `@schemas` list. The pruner automatically finds `expires_at` columns.*

### `lib/lockspire/protocol/registration.ex` (protocol/utility, request-response)

**Analog:** `lib/lockspire/protocol/registration.ex`

**Validation Pattern (DCR Metadata Coherence)** (lines 183-200):
```elixir
  # D-14: jwks_uri rejected first (mutual-exclusion check is shadowed when both present
  # because jwks_uri rule fires first; we still keep the explicit rule for spec clarity).
  defp validate_jwks(metadata) do
    cond do
      Map.has_key?(metadata, "jwks_uri") ->
        {:error,
         %Error{code: :invalid_client_metadata, field: :jwks_uri, reason: :unsupported_in_slice}}

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
*Note for planner: Modify `validate_jwks(metadata)` to check if `metadata["token_endpoint_auth_method"] == "private_key_jwt"`. If so, ensure exactly one of `jwks` or `jwks_uri` is present. Remove the blanket `:unsupported_in_slice` error for `jwks_uri`.*

## Metadata

**Analog search scope:** `lib/`, `priv/repo/migrations/`
**Files scanned:** 5
**Pattern extraction date:** 2024-05-03
