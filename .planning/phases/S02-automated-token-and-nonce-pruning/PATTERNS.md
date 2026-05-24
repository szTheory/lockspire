# Phase S02: Automated Token & Nonce Pruning - Pattern Map

**Mapped:** 2024-05-03
**Files analyzed:** 9
**Analogs found:** 3 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/workers/pruner.ex` | worker | batch | `lib/lockspire/workers/backchannel_logout_delivery_worker.ex` | role-match |
| `lib/lockspire/oban.ex` | config | sync | `lib/lockspire/oban.ex` | exact |
| `lib/lockspire/config.ex` | config | sync | `lib/lockspire/config.ex` | exact |
| `lib/lockspire/storage/ecto/repository.ex` | repository | chunked-delete | N/A | none |

## Pattern Assignments

### `lib/lockspire/workers/pruner.ex` (worker, batch)

**Analog:** `lib/lockspire/workers/backchannel_logout_delivery_worker.ex`

**Imports pattern** (lines 14-22):
```elixir
  import Ecto.Query

  alias Ecto.Changeset
  alias Lockspire.Config
  alias Lockspire.Observability
  alias Lockspire.Storage.Ecto.Repository
```

**Worker Definition pattern** (lines 6-15):
```elixir
  use Oban.Worker,
    queue: :pruner,
    max_attempts: 1,
    unique: [
      period: 60
    ]
```

**Core Perform Pattern** (lines 26-28):
```elixir
  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # ... call Repository chunk functions
    :ok
  end
```

**Telemetry emission pattern** (lines 247-248):
```elixir
    Observability.emit(entity, action, %{count: deleted_count}, %{model: model_name})
```

---

### `lib/lockspire/oban.ex` (config, sync)

**Analog:** `lib/lockspire/oban.ex`

**Oban config build pattern** (lines 12-18):
```elixir
    config =
      :lockspire
      |> Application.get_env(:oban, [])
      |> Keyword.merge(name: __MODULE__)
      |> Keyword.put_new(:repo, repo!())
      |> Keyword.put_new(:plugins, false)
      |> Keyword.put_new(:queues, @default_queues)
```

---

### `lib/lockspire/config.ex` (config, sync)

**Analog:** `lib/lockspire/config.ex`

**Environment lookup pattern with default** (lines 75-77):
```elixir
  def pruner_schedule do
    Application.get_env(@app, :pruner_schedule, "@hourly")
  end
```

---

## Shared Patterns

### Observability
**Source:** `lib/lockspire/observability.ex`
**Apply to:** `Pruner` worker or `Repository` deletion functions
```elixir
  def emit(entity, action, measurements \\ %{}, metadata \\ %{}) when is_atom(entity) and is_atom(action)
```
Emits standard telemetry and audit logs. Recommended: `Observability.emit(:pruner, :completed, %{count: count}, %{model: :token})`

### Target Models for Deletion
All target schemas have a common `expires_at` column matching `DateTime.utc_now()`.
- `Lockspire.Storage.Ecto.TokenRecord`
- `Lockspire.Storage.Ecto.DpopReplayRecord`
- `Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord`
- `Lockspire.Storage.Ecto.InteractionRecord`
- `Lockspire.Storage.Ecto.DeviceAuthorizationRecord`
- `Lockspire.Storage.Ecto.InitialAccessTokenRecord`

Pattern found in `token_record.ex` (line 29):
```elixir
    field(:expires_at, :utc_datetime_usec)
```

## No Analog Found

Files with no close match in the codebase (planner should use CONTEXT.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/lockspire/storage/ecto/repository.ex` | repository | chunked-delete | No chunked recursive delete query pattern exists. The existing `prune_expired_dpop_replay_records/1` uses an un-chunked `delete_all` directly. The planner must create the `LIMIT 1000 -> delete_all(where: id in ^ids)` recursive loop. |

## Metadata

**Analog search scope:** `lib/lockspire/workers/`, `lib/lockspire/storage/ecto/`, `lib/lockspire/`
**Files scanned:** 16
**Pattern extraction date:** 2024-05-03
