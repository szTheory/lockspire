# Phase 41: FAPI 2.0 Profile Configuration - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/domain/server_policy.ex` | model | CRUD | `lib/lockspire/domain/server_policy.ex` | exact |
| `lib/lockspire/domain/client.ex` | model | CRUD | `lib/lockspire/domain/client.ex` | exact |
| `priv/repo/migrations/*_add_fapi_2_0_security_profile.exs` | migration | schema-change | `priv/repo/migrations/20260428153000_add_dpop_policy_fields.exs` | exact |
| `lib/lockspire/protocol/fapi_2_0_enforcer_plug.ex` | middleware | request-response | `lib/lockspire/web/controllers/registration_controller.ex` | partial |

## Pattern Assignments

### `lib/lockspire/domain/server_policy.ex` (model, CRUD)

**Analog:** `lib/lockspire/domain/server_policy.ex`

**Enum Type Pattern** (lines 6-9):
```elixir
  @type par_policy :: :optional | :required
  @type dpop_policy :: :bearer | :dpop
  @type registration_policy :: :disabled | :initial_access_token | :open
```

**Struct Field Pattern** (lines 14-25):
```elixir
  @type t :: %__MODULE__{
          id: integer() | nil,
          par_policy: par_policy(),
          dpop_policy: dpop_policy(),
```

**Default Value Pattern** (lines 31-45):
```elixir
  defstruct id: nil,
            par_policy: :optional,
            dpop_policy: :bearer,
```

---

### `lib/lockspire/domain/client.ex` (model, CRUD)

**Analog:** `lib/lockspire/domain/client.ex`

**Enum Type Pattern** (lines 10-14):
```elixir
  @type par_policy :: :inherit | :required | :optional
  @type dpop_policy :: :inherit | :bearer | :dpop
```

**Struct Field Pattern** (lines 33-35):
```elixir
          par_policy: par_policy(),
          dpop_policy: dpop_policy(),
```

**Default Value Pattern** (lines 72-74):
```elixir
    par_policy: :inherit,
    dpop_policy: :inherit,
```

---

### `priv/repo/migrations/*_add_fapi_2_0_security_profile.exs` (migration, schema-change)

**Analog:** `priv/repo/migrations/20260428153000_add_dpop_policy_fields.exs`

**Migration Pattern** (lines 1-13):
```elixir
defmodule Lockspire.TestRepo.Migrations.AddDpopPolicyFields do
  use Ecto.Migration

  def change do
    alter table(:lockspire_server_policies) do
      add :dpop_policy, :text, null: false, default: "bearer"
    end

    alter table(:lockspire_clients) do
      add :dpop_policy, :text, null: false, default: "inherit"
    end
  end
end
```

---

### `lib/lockspire/protocol/fapi_2_0_enforcer_plug.ex` (middleware, request-response)

**Analog:** `lib/lockspire/web/controllers/registration_controller.ex` (and `ParPolicy`)

**Plug Halting Pattern** (from `RegistrationController` lines 86-95):
```elixir
  defp ensure_dcr_enabled(conn, _opts) do
    {:ok, server_policy} = Repository.get_server_policy()

    if server_policy.registration_policy == :disabled do
      conn
      |> send_resp(404, "")
      |> halt()
    else
      conn
    end
  end
```

**Policy Resolution Pattern** (from `Lockspire.Protocol.ParPolicy` lines 34-40):
```elixir
  defp normalize_client_policy(nil), do: :inherit

  defp normalize_client_policy(client) do
    case Map.get(client, :par_policy, :inherit) do
      :required -> :required
      :optional -> :optional
      _other -> :inherit
    end
  end
```

## Shared Patterns

### Missing Standalone Plug Module
**Source:** N/A
**Note:** There are no standalone `Plug` modules implementing the `@behaviour Plug` in `lib/lockspire/protocol/` or `lib/lockspire/web/`. The typical convention is either inline private plugs in controllers (like `ensure_dcr_enabled` in `registration_controller.ex`) or resolving via a policy module (like `ParPolicy.resolve_effective_policy`). The planner should create `Lockspire.Protocol.FAPI20EnforcerPlug` as a standard standard plug struct (`init/1` and `call/2`) and ensure it's placed appropriately (perhaps in the Router or individual controller pipelines).

## Metadata

**Analog search scope:** `lib/lockspire/domain`, `priv/repo/migrations/`, `lib/lockspire/protocol/`, `lib/lockspire/web/`
**Files scanned:** ~50
**Pattern extraction date:** 2024-05-18
