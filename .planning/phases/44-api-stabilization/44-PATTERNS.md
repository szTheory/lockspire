# Phase 44: API Stabilization - Pattern Map

**Mapped:** 2024-05-04
**Files analyzed:** 5
**Analogs found:** 3 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire.ex` | facade | API / accessors | `lib/lockspire/admin/clients.ex` | role-match |
| `lib/lockspire/admin.ex` | facade | API | `lib/lockspire/admin/clients.ex` | role-match |
| `lib/lockspire/config.ex` | config | transform | `lib/lockspire/admin/clients.ex` | role-match |
| `lib/lockspire/host/account_resolver.ex` | behaviour | callback | `lib/lockspire/storage/token_store.ex` | exact |
| `lib/lockspire/host/context.ex` | type/struct | state | `lib/lockspire/domain/client.ex` | exact |

## Pattern Assignments

### `lib/lockspire.ex`, `lib/lockspire/admin.ex`, `lib/lockspire/config.ex` (facade/config, API)

**Analog:** `lib/lockspire/admin/clients.ex`

**Imports pattern** (lines 5-9):
```elixir
alias Lockspire.Clients
alias Lockspire.Clients.RegistrationResult
alias Lockspire.Domain.Client
alias Lockspire.Observability
alias Lockspire.Storage.Ecto.Repository
```

**Typespec & Delegation pattern** (lines 35-39):
```elixir
@type error_detail :: %{field: atom(), reason: atom(), detail: term()}

@spec list_clients(keyword()) :: {:ok, [Client.t()]} | {:error, term()}
def list_clients(opts \\ []) do
  Repository.list_clients(opts)
end
```
*Note: Apply this pattern to all `defdelegate` declarations in `Lockspire.Admin`. Each `defdelegate` must have a corresponding `@spec` that defines its exact return type.*

---

### `lib/lockspire/host/account_resolver.ex` (behaviour, callback)

**Analog:** `lib/lockspire/storage/token_store.ex`

**Imports pattern** (lines 5-5):
```elixir
alias Lockspire.Domain.Token
```

**Custom Types pattern** (lines 7-8):
```elixir
@type store_error :: term()
@type expected_cnf :: nil | %{optional(String.t()) => binary()}
```

**Callback pattern** (lines 10-13):
```elixir
@optional_callbacks [revoke_by_sid: 1]
@callback store_token(Token.t()) :: {:ok, Token.t()} | {:error, store_error()}
@callback list_lifecycle_tokens(keyword()) ::
            {:ok, [Token.t()]} | {:error, store_error()}
```
*Note: Replace generic `term()` and `map()` with explicit union types (e.g., `Plug.Conn.t() | Phoenix.LiveView.Socket.t() | term()`) and structs like `Lockspire.Host.Context.t()`.*

---

### `lib/lockspire/host/context.ex` (type/struct, state)

**Analog:** `lib/lockspire/domain/client.ex`

**Enum Type pattern** (lines 5-6):
```elixir
@type client_type :: :public | :confidential
@type token_endpoint_auth_method ::
        :client_secret_basic | :client_secret_post | :private_key_jwt | :none
```

**Struct Definition & Type pattern** (lines 14-22, 59-64):
```elixir
@type t :: %__MODULE__{
        id: integer() | nil,
        client_id: String.t(),
        client_secret_hash: String.t() | nil,
        client_type: client_type(),
        # ...
      }

# credo:disable-for-next-line
defstruct [
  :id,
  :client_id,
  :client_secret_hash,
  # ...
]
```
*Note: Build `%Lockspire.Host.Context{}` to explicitly define keys like `:return_to`, `:client_id`, `:scopes`, and `:interaction_type` with strong typing.*

## Shared Patterns

### Typespec Validation
**Source:** `lib/lockspire/admin/clients.ex`
**Apply to:** All public boundary modules (`Lockspire`, `Lockspire.Admin`, `Lockspire.Clients`, `Lockspire.Config`).
Ensure `mix dialyzer` runs without errors. All `@spec` entries must reflect reality, including any custom return tuples.

## Metadata

**Analog search scope:** `lib/lockspire/admin`, `lib/lockspire/domain`, `lib/lockspire/storage`
**Files scanned:** 5
**Pattern extraction date:** 2024-05-04
