---
phase: S02
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/lockspire/config.ex
  - lib/lockspire/oban.ex
  - lib/lockspire/storage/ecto/repository.ex
  - lib/lockspire/workers/pruner.ex
  - test/lockspire/storage/repository_test.exs
  - test/lockspire/workers/pruner_test.exs
autonomous: true
requirements: [S02-PRUNING]

must_haves:
  truths:
    - "Expired records across 6 targeted schemas are periodically deleted automatically."
    - "Deletions are processed in chunks of 1000, avoiding long-running transaction locks."
    - "Telemetry events are emitted recording the number of deleted rows per model."
    - "The pruning schedule is configurable via the host application, defaulting to hourly."
  artifacts:
    - path: "lib/lockspire/workers/pruner.ex"
      provides: "Oban worker for scheduling pruning jobs"
    - path: "lib/lockspire/storage/ecto/repository.ex"
      provides: "Tail-recursive chunked deletion logic"
  key_links:
    - from: "lib/lockspire/oban.ex"
      to: "Oban.Plugins.Cron"
      via: "runtime_config/0 plugin setup"
    - from: "lib/lockspire/workers/pruner.ex"
      to: "lib/lockspire/storage/ecto/repository.ex"
      via: "calls chunked delete function"
---

<objective>
Implement background pruning for expired tokens, nonces, device codes, and pushed authorization requests.

Purpose: Prevent database bloat and maintain performance without blocking requests or causing lock contention on busy tables.
Output: Configurable Oban Cron setup, recursive chunked deletion logic in Ecto, a Pruner Oban Worker, and telemetry emission.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/S02-automated-token-and-nonce-pruning/S02-CONTEXT.md
@.planning/phases/S02-automated-token-and-nonce-pruning/RESEARCH.md
@.planning/phases/S02-automated-token-and-nonce-pruning/PATTERNS.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Add Pruner Configuration and Oban Setup</name>
  <files>lib/lockspire/config.ex, lib/lockspire/oban.ex</files>
  <action>
    - Use analog references `lib/lockspire/config.ex` and `lib/lockspire/oban.ex` from PATTERNS.md.
    - In `Lockspire.Config`, add a `pruner_schedule/0` function that reads `:pruner_schedule` from application env, defaulting to `"@hourly"`. It can be set to `false` to disable.
    - In `Lockspire.Oban.runtime_config!/0`, dynamically construct the `:plugins` configuration. If `Lockspire.Config.pruner_schedule()` is truthy, append `{Oban.Plugins.Cron, crontab: [{schedule, Lockspire.Workers.Pruner}]}` to the plugins list (taking care not to conflict with `Keyword.put_new(:plugins, false)`).
  </action>
  <verify>
    <automated>mix test</automated>
  </verify>
  <done>Config exposes `pruner_schedule/0` and Oban dynamically loads the Cron plugin.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Implement Chunked Recursive Deletion</name>
  <files>lib/lockspire/storage/ecto/repository.ex, test/lockspire/storage/repository_test.exs</files>
  <action>
    - Note: No direct analog exists in PATTERNS.md for chunked recursive deletion; implement from scratch.
    - In `Lockspire.Storage.Ecto.Repository`, implement a tail-recursive function `prune_expired_records(schema, now \\ DateTime.utc_now(), count \\ 0)`.
    - Using `Ecto.Query.limit/2`, fetch up to 1000 IDs where `expires_at < ^now`.
    - If 0 IDs are returned, return the total `count`.
    - If IDs exist, use `Repo.delete_all(where: id in ^ids)`, add the deleted count to the total, and recurse.
    - Add unit tests in `test/lockspire/storage/repository_test.exs` to ensure correct behavior of chunked deletion logic.
  </action>
  <verify>
    <automated>mix test</automated>
  </verify>
  <done>Repository provides a tail-recursive function that safely chunks deletions of expired records, verified by unit tests.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Create Pruner Worker and Emit Telemetry</name>
  <files>lib/lockspire/workers/pruner.ex, test/lockspire/workers/pruner_test.exs</files>
  <action>
    - Reference analog `lib/lockspire/workers/backchannel_logout_delivery_worker.ex` from PATTERNS.md for the Oban worker and telemetry pattern.
    - Define `Lockspire.Workers.Pruner` using `use Oban.Worker, queue: :pruner, max_attempts: 1, unique: [period: 60]`.
    - In `perform/1`, define the 6 target Ecto schemas: `TokenRecord`, `DpopReplayRecord`, `PushedAuthorizationRequestRecord`, `InteractionRecord`, `DeviceAuthorizationRecord`, `InitialAccessTokenRecord` (under `Lockspire.Storage.Ecto`).
    - Loop over each schema, passing it to `Repository.prune_expired_records/1`.
    - For each schema, call `Lockspire.Observability.emit(:pruner, :completed, %{count: deleted_count}, %{model: schema_name})` with the returned deleted count.
    - Add unit tests in `test/lockspire/workers/pruner_test.exs` to ensure correct worker execution and telemetry emission.
  </action>
  <verify>
    <automated>mix test</automated>
  </verify>
  <done>Worker executes chunked deletion across all 6 models and correctly emits telemetry metrics, verified by unit tests.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Oban Worker -> Database | Deletion operates on internal model properties, unaffected by user input. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-S02-01 | Denial of Service | Ecto Database | mitigate | Implement chunked batching (`LIMIT 1000`) instead of unbounded `delete_all` to avoid table lock escalation during high load. |
</threat_model>

<verification>
Ensure all code compiles and standard tests pass. The exact mechanism (cron behavior) may be difficult to test end-to-end synchronously, but unit tests or typical CI execution is sufficient for this scope.
</verification>

<success_criteria>
Expired record pruning is automated and runs in the background. Database tables for the targeted domains are kept clean from bloated expired data. No table locking issues occur under typical use cases. Unit tests verify the logic.
</success_criteria>

<output>
After completion, create `.planning/phases/S02-automated-token-and-nonce-pruning/S02-01-SUMMARY.md`
</output>