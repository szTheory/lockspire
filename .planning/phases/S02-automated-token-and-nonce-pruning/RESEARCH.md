# Phase S02: Automated Token & Nonce Pruning - Research

**Researched:** 2024-05-24
**Domain:** Background Jobs & Ecto Batching
**Confidence:** HIGH

## Summary
To prevent database bloat, we will implement an Oban Cron job (`Lockspire.Workers.Pruner`) that runs periodically to delete expired records across 6 domain models (`Token`, `DpopReplay`, `PushedAuthorizationRequest`, `Interaction`, `DeviceAuthorization`, `InitialAccessToken`). To avoid table locks, deletions will be processed recursively in chunks of 1000 using `Ecto.Query.limit/2` and `Ecto.Repo.delete_all/2`. The host application will be able to override the cron schedule via a `:pruner_schedule` configuration option.

**Primary recommendation:** Implement chunked deletions recursively within a single Oban worker triggered by `Oban.Plugins.Cron`, and emit telemetry using `Lockspire.Observability.emit/4` for each pruned schema.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cron Scheduling | Embedded Oban | — | Ensures single-node execution in a clustered deployment. |
| Chunked Deletions | Database / Storage | — | Batching Ecto deletes limits transaction scope and avoids lock escalation on busy tables. |
| Telemetry | Backend | — | Emitted to standard `:telemetry` and audit logs via existing Observability module. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Oban.Plugins.Cron` | (existing) | Scheduling | Native, embedded job scheduling ensuring exactly-once execution. |
| `Ecto.Query` | (existing) | Chunking | Standard `limit` and `in` operators safely chunk operations. |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Scheduling exactly-once | GenServer timer | `Oban.Plugins.Cron` | GenServer timers duplicate execution across clustered nodes, causing lock contention or redundant deletes. |
| Big deletes | `Repo.delete_all(where: s.expires_at < ^now)` | Recursive batch chunking | Large `delete_all` commands block inserts and cause Postgres lock escalation. |

## Common Pitfalls

### Pitfall 1: Long-Running Transaction Locking
**What goes wrong:** Calling `Repo.delete_all/2` directly on all expired records.
**Why it happens:** The number of expired records can be in the millions over time.
**How to avoid:** Query a fixed number of IDs (`LIMIT 1000`) and delete only those IDs. Use a tail-recursive function to exhaust the expired pool.

### Pitfall 2: Oban Plugin Collision
**What goes wrong:** Defining `plugins: [...]` directly in `Lockspire.Oban` overrides or conflicts with host-injected plugins.
**Why it happens:** Keyword list overrides in `Lockspire.Oban.runtime_config!/0` (`Keyword.put_new(:plugins, false)`).
**How to avoid:** Dynamically build the default plugins list in `Lockspire.Oban.runtime_config!/0` based on the configured schedule, and merge gracefully or update the `Keyword.put_new` logic.

## Relevant Project Files

1. **Target Ecto Schemas**:
   - `Lockspire.Storage.Ecto.TokenRecord`
   - `Lockspire.Storage.Ecto.DpopReplayRecord`
   - `Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord`
   - `Lockspire.Storage.Ecto.InteractionRecord`
   - `Lockspire.Storage.Ecto.DeviceAuthorizationRecord`
   - `Lockspire.Storage.Ecto.InitialAccessTokenRecord`
   *(All define `expires_at: :utc_datetime_usec` and possess an implicit Ecto `:id` PK which can be reliably queried).*
   
2. **Configuration**:
   - `Lockspire.Config` — Should expose a new `pruner_schedule/0` function defaulting to `"@hourly"` (or `false` to disable).
   - `Lockspire.Oban` — Should conditionally load the `Oban.Plugins.Cron` plugin with the configured schedule.
   
3. **Observability**:
   - `Lockspire.Observability` — Provides `emit/4` to emit telemetry for `[:lockspire, :pruner, :run]` metrics reliably.

## Code Examples

### Chunked Ecto Deletions
```elixir
def prune_schema(schema, now, count \\ 0) do
  import Ecto.Query

  # 1. Fetch chunk of expired IDs
  query = from(s in schema, where: s.expires_at < ^now, select: s.id, limit: 1000)
  
  case Lockspire.Config.repo!().all(query) do
    [] ->
      count
    ids ->
      # 2. Delete chunk
      {deleted, nil} = Lockspire.Config.repo!().delete_all(from(s in schema, where: s.id in ^ids))
      
      # 3. Recurse
      prune_schema(schema, now, count + deleted)
  end
end
```

### Telemetry Emission
```elixir
Lockspire.Observability.emit(
  :pruner,
  :pruned,
  %{count: total_deleted},
  %{schema: inspect(schema)}
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unbounded `delete_all` | Batched tail-recursion | Phase S02 | Eliminates DB transaction lock escalation risk. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None - All facts strictly verified. | - | - |

## Open Questions (RESOLVED)

None - The path is fully verified.

## Sources

### Primary (HIGH confidence)
- `Lockspire.Oban` - Verified current `Keyword.put_new(:plugins, false)` mechanism.
- Schema definitions in `lib/lockspire/storage/ecto/*_record.ex` - Verified presence of `id` and `expires_at` on all targets.
- `Lockspire.Observability` - Verified `emit/4` telemetry and audit log structure.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using native Oban logic.
- Architecture: HIGH - Recursive chunking is an Ecto standard practice.
- Pitfalls: HIGH - Schema validation ensures lock avoidance.

**Research date:** 2024-05-24
**Valid until:** 2025-05-24
