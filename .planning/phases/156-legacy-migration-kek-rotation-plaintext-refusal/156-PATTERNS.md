# Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal - Pattern Map

**Mapped:** 2026-10-16
**Files analyzed:** 20 (7 new, 13 modified/extended)
**Analogs found:** 19 / 20 (all analog paths verified git-tracked; no mirror paths)

CONTEXT D-xx and RESEARCH pattern numbers are not repeated here. This file only points the planner at concrete excerpts. Reminder: `ReadabilityContractTest` forbids planning markers (`Phase N`, `D-NN`, `WR-NN`) in any `lib/**` text, including `@moduledoc` and Mix task help.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/storage/key_store.ex` (+2 callbacks) | storage behaviour | CRUD | same file, `activate_signing_key/2` callback | exact |
| `lib/lockspire/storage/ecto/repository.ex` (+2 delegates) | facade | request-response | same file lines 482-532 | exact |
| `lib/lockspire/storage/ecto/repository/signing_key_store.ex` (+impl) | store | CRUD, row-lock txn | same file `activate_signing_key/3` + `locked_key/2` | exact |
| `lib/lockspire/admin/keys.ex` (+`reencrypt/1`, `encryption_status/0`) | service | batch / transform | same file `transact_with_audit` + `key_audit_event` + `emit` | exact |
| `lib/lockspire/admin/keys/reencrypt.ex` (new, optional helper, `@moduledoc false`) | service helper | batch / transform | `lib/lockspire/protocol/private_jwk.ex` (classify/open style) | role-match |
| `lib/lockspire/admin.ex` (+2 `defdelegate`) | facade | request-response | same file lines 193-231 | exact |
| `lib/lockspire/protocol/private_jwk.ex` (refusal, `read_stored/2`, hot-path telemetry) | utility | transform / event-driven | same file; telemetry from `plug/verify_token.ex:478-496` | exact |
| `lib/mix/tasks/lockspire.keys.reencrypt.ex` (new) | mix task | batch, CLI | `lib/mix/tasks/lockspire.upgrade.ex` (+ `ecto.migrate` for `with_repo`) | role-match |
| `lib/mix/tasks/lockspire.doctor.key_encryption.ex` (+counts, `with_repo`) | mix task | request-response | same file; `Install.Verify.migration_status/2` for `with_repo` | exact |
| `lib/lockspire/install/verify.ex` (+`:key_storage` check, widen `safely/1`) | service | request-response | same file `key_encryption_check/0` (62-88), `migrations_check/2` (312-334) | exact |
| `test/support/key_encryption_helpers.ex` (+`reset_decode_warnings/0`, seed helpers) | test support | n/a | same file | exact |
| `test/lockspire/admin/keys_reencrypt_test.exs` (new) | test | batch | `test/lockspire/protocol/private_jwk_test.exs` + `key_encryption_helpers.ex` | role-match |
| `test/lockspire/admin/keys_encryption_status_test.exs` (new) | test | transform | same as above | role-match |
| `test/lockspire/storage/reencrypt_concurrency_test.exs` (new, `:integration`) | test | concurrency | `test/lockspire/storage/repository_concurrency_test.exs` | exact |
| `test/mix/tasks/lockspire_keys_reencrypt_test.exs` (new) | test | CLI | `test/mix/tasks/lockspire_doctor_key_encryption_test.exs` | exact |
| `test/lockspire/security/key_encryption_telemetry_test.exs` (new) | test | event-driven | `test/support/telemetry_capture.ex` consumers | role-match |
| `test/lockspire/security/key_material_leak_test.exs` (new) | test | event-driven | none exact (compose CaptureLog + TelemetryCapture) | partial |
| extend `private_jwk_test.exs`, `verify_test.exs`, `lockspire_doctor_key_encryption_test.exs`, `architecture_fitness_test.exs` | test | n/a | themselves | exact |
| `.planning/ROADMAP.md` criterion 5 / `.planning/REQUIREMENTS.md` OPS-02 wording edit | docs | n/a | n/a | n/a |

## Pattern Assignments

### `lib/lockspire/storage/ecto/repository/signing_key_store.ex` (store, row-lock txn)

**Analog:** same file, `activate_signing_key/3` (lines 134-151) and `locked_key/2` (190-195). Already imports `Ecto.Query`, aliases `Support`, `TransactionStore`, `SigningKeyRecord` (lines 4-10).

**Lock + transaction pattern** (lines 134-151, 190-195):
```elixir
def activate_signing_key(repo, id, activated_at)
    when is_integer(id) and is_struct(activated_at, DateTime) do
  TransactionStore.transact(repo, fn ->
    case locked_key(repo, id) do
      nil -> TransactionStore.rollback(repo, :not_found)
      ...
    end
  end)
end

defp locked_key(repo, id),
  do:
    SigningKeyRecord
    |> where([key], key.id == ^id)
    |> lock("FOR UPDATE")
    |> then(&Support.one(repo, &1))
```
New `reencrypt_signing_key/4` copies this shape. Differences: (1) pass `sensitive: true` on the locked read and on the CAS `update_all` (query params include legacy plaintext; see RESEARCH Pitfall 1); (2) return `{:ok, outcome}` rather than rolling back for `:not_found`/`:conflict`, since those are counted, not aborts; (3) rollback only on audit append failure via `TransactionStore.rollback(repo, reason)` (as in `update_one/2`, lines 221-226).

**CAS update_all call shape** (RESEARCH quotes `token_store.ex:344-350`):
```elixir
Support.update_all(repo, query, [set: [private_jwk_encrypted: new, updated_at: DateTime.utc_now()]], sensitive: true)
```
`{1, _}` ok, `{0, _}` conflict. Do not widen `SigningKeyRecord.update_changeset/2`.

**Id paging**: copy the `where`/`order_by` + `Support.all` style of `list_active_keys/1` (lines 24-30), with `where key.id > ^after_id, order_by: key.id, limit: ^limit, select: key.id`.

---

### `lib/lockspire/storage/key_store.ex` and `lib/lockspire/storage/ecto/repository.ex` (behaviour + one-line delegates)

**Analog:** same files.

Behaviour callback style (key_store.ex:21-25):
```elixir
@callback activate_signing_key(integer(), DateTime.t()) ::
            {:ok, %{activated_key: SigningKey.t(), retiring_key: SigningKey.t() | nil}}
            | {:error, store_error()}
```
Delegate style (repository.ex:524-527); `defp repo, do: Config.repo!()` at ~587:
```elixir
@impl KeyStore
def activate_signing_key(id, activated_at)
    when is_integer(id) and is_struct(activated_at, DateTime),
    do: EctoSigningKeyStore.activate_signing_key(repo(), id, activated_at)
```
Constraint: `repository.ex` must contain no Ecto query constructs, no `lock`, no `*Record` aliases (`architecture_fitness_test.exs:84-100`). If `SigningKeyStore` appends audit via `AuditStore.append_audit_event(repo, event)` directly, keep that call inside the store, not the facade.

---

### `lib/lockspire/admin/keys.ex` (service: `reencrypt/1`, `encryption_status/0`)

**Analog:** same file. Imports/aliases already present (lines 6-12: `Config`, `SigningKey`, `Observability`, `Redaction`, `KeyEncryption`, `Repository`).

**Audit event shape** (lines 305-314); engine reuses it, adding `use`, `kek_id`, and `previous_kek_id` to metadata and making `reason_code`/`action` `:key_encrypted | :key_rewrapped`:
```elixir
defp key_audit_event(action, %SigningKey{} = key, actor, metadata) do
  %{
    action: action,
    outcome: :succeeded,
    reason_code: action,
    actor: actor,
    resource: %{type: :signing_key, id: key.id || key.kid},
    metadata: Map.merge(%{key_id: key.id, kid: key.kid, status: key.status}, metadata)
  }
end
```

**Post-commit operator telemetry** (lines 295-303); copy for `:encrypted`, `:rewrapped` (add `kek_id`, `previous_kek_id`). Emit after the row transaction commits:
```elixir
defp emit(entity, action, %SigningKey{} = key, actor) do
  Observability.emit(entity, action, %{}, %{
    actor_type: actor[:type], actor_id: actor[:id],
    key_id: key.id, kid: key.kid, status: key.status
  })
end
```
For `:reencrypt_completed`, never include a `count` key in measurements (Observability does `Map.put_new(:count, 1)`); use `scanned/encrypted/rewrapped/...` plus `duration`.

**Actor normalization** (lines 316-336): reuse `actor_from_attrs/1` by passing `%{actor: opts[:actor]}`; default type `:operator`.

**Error handling:** `list_keys/1` style `with {:ok, ...} <- Repository.list_signing_keys(opts)` (lines 25-30) is the template for `encryption_status/0`. Map any `{:error, %{__exception__: true}}` to `{:error, :storage_unavailable}`; never forward exception structs (the store `rescue` returns them as values).

Note: the audit helpers are `defp`. If the engine lives in `Admin.Keys.Reencrypt`, either keep audit-event construction in `Admin.Keys` and pass the built event to the helper, or relocate `key_audit_event/4` and `actor_from_attrs/1` to be callable (`@doc false def`).

---

### `lib/lockspire/admin.ex` (facade)

**Analog:** lines 193-231, e.g.:
```elixir
@doc """
Retires a key so it is no longer used for signing.
"""
@spec retire_key(integer(), map() | keyword()) ::
        {:ok, Lockspire.Admin.Keys.key_view()} | {:error, term()}
defdelegate retire_key(key_id, attrs \\ %{}), to: Keys
```
Add `reencrypt(opts \\ [])` and `encryption_status()` the same way, with `@type reencrypt_report` / `@type encryption_status` defined in `Admin.Keys` and referenced as `Lockspire.Admin.Keys.reencrypt_report()`. `Lockspire.Admin` and `Admin.Keys` are not in the compatibility manifest; no manifest edit is needed unless a `Lockspire.Config` export is added.

---

### `lib/lockspire/protocol/private_jwk.ex` (refusal, `read_stored/2`, hot-path telemetry)

**Analog:** the file itself (65 lines, read in full). Current core to refactor:
```elixir
def decode_with_reason(%{kid: kid, private_jwk_encrypted: bin}) when is_binary(kid) and is_binary(bin) do
  case KeyEncryption.classify(bin) do
    :envelope -> decode_envelope(kid, bin)
    :legacy -> decode_legacy(bin)
    :invalid -> {:error, :invalid_signing_key}
  end
rescue
  _exception -> {:error, :invalid_signing_key}
catch
  _kind, _reason -> {:error, :invalid_signing_key}
end
```
- Keep `decode_envelope/2` (lines 42-50) logic but parameterize the keyset (currently `Config.key_encryption_keyset()` inline at line 43) so `read_stored/2` can take an explicit keyset.
- Legacy path (lines 52-64) has no kid check; `private_jwk_test.exs` decodes kid-less ETF, so keep that behavior in `decode_with_reason`; the engine does its own kid check.
- Refusal branch goes in the `:legacy ->` arm before `decode_legacy/1`, reading `%KeySet{legacy_plaintext: :reject}` from a single `Config.key_encryption_keyset()` call.
- Add `| :plaintext_key_refused` to `@type reason` (lines 7-13).
- `decode/1` (lines 15-23) is the only place that emits hot-path events; keep `decode_with_reason/1` pure.
- Must not alias `Lockspire.Admin`/`Lockspire.Web` (protocol outer-reference rule, `architecture_fitness_test.exs:294`).

**Hot-path telemetry analog:** `lib/lockspire/plug/verify_token.ex:478-496`:
```elixir
# This MUST NOT route through Lockspire.Observability.emit/4: ... double-emits a [:lockspire, :audit, ...] copy ...
defp emit_token_format(metadata) do
  :telemetry.execute([:lockspire, :rs, :token_format], %{count: 1}, metadata)
end
```
Copy: direct `:telemetry.execute([:lockspire, :key, :legacy_read | :decode_failed], %{count: 1}, Redaction.for_telemetry(metadata))` with fixed allowlisted maps. Never name a metadata key `state` or `token` (Redaction drops them). Use plain-English comments in lib (no D-NN markers).

---

### `lib/mix/tasks/lockspire.keys.reencrypt.ex` (new Mix task)

**Analog:** `lib/mix/tasks/lockspire.upgrade.ex` (structure and `--dry-run`), with `Ecto.Migrator.with_repo` taken from `ecto.migrate` / `Install.Verify.migration_status/2`.

**Skeleton to copy** (upgrade.ex:6-41):
```elixir
@shortdoc "..."
use Mix.Task
@requirements ["app.config"]
@switches [dry_run: :boolean, help: :boolean]

@impl Mix.Task
def run(args) do
  {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
  if invalid != [] do
    Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
  end
  if Keyword.get(opts, :help, false), do: Mix.shell().info(help()), else: do_run(opts)
end

def help do
  """
  mix lockspire.upgrade [...]
  ...
  """
end
```
Differences required: bind `argv` and `Mix.raise` on any positional argument; add `check: :boolean`; reject `--check` with `--dry-run`; all validation raises before any repo access. Failure style: `Mix.shell().info` lines then `Mix.raise` (upgrade.ex:104-115 `refuse!/1` prints per-item lines and a fix line, then raises). Compute the report inside `with_repo`, return it, then print and `Mix.raise` outside so the repo stops first:
```elixir
{:ok, _} = Application.ensure_all_started(:ecto_sql)
case Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _repo -> work(opts) end, mode: :temporary) do
  {:ok, result, _apps} -> finish(result)
  {:error, _term} -> Mix.raise("could not start the repo; check database connectivity")
end
```
Help text must carry the upgrade and five-step rotation order and contain no "Phase"/"D-NN" tokens.

---

### `lib/mix/tasks/lockspire.doctor.key_encryption.ex` (add counts)

**Analog:** the file itself (read in full). Preserve the existing first line exactly (asserted by existing tests):
```elixir
Mix.shell().info(
  "key_encryption: configured current=#{keyset.current_id} " <>
    "ids=#{Enum.join(keyset.ids, ",")} legacy_plaintext=#{keyset.legacy_plaintext}"
)
```
`fetch/0` (lines 70-74) already rescues `ArgumentError` into `{:error, message}`; reuse it. For the not-configured branch (lines 57-63), print the legacy count before `Mix.raise`. Add the repo guard (`Process.whereis(repo)` then call directly, else `with_repo`) in one private helper shared with Verify. Never print `Exception.message/1` of storage errors; use a fixed sentence.

---

### `lib/lockspire/install/verify.ex` (new `:key_storage` check, widen `safely/1`)

**Analog:** same file. `migration_status/2` and `safely/1` (lines 368-382):
```elixir
defp migration_status(repo, migration_path) do
  {:ok, statuses, _apps} =
    Ecto.Migrator.with_repo(repo, fn started_repo ->
      Ecto.Migrator.migrations(started_repo, migration_path, skip_table_creation: true)
    end)
  statuses
end

defp safely(fun) do
  {:ok, fun.()}
rescue
  error in [ArgumentError, RuntimeError, UndefinedFunctionError, FunctionClauseError] ->
    {:error, Exception.message(error)}
end
```
Widen the rescue list with `MatchError`, `DBConnection.ConnectionError`, `Postgrex.Error`. Check results use `Check.ok(id, summary, details, fix)` / `Check.error(...)` as in `migrations_check/2` (lines 312-334); only `:ok | :error` statuses exist, so "skipped" is a `Check.ok` with a "skipped: ..." details string. Also model on `key_encryption_check/0` (verify.ex:62-88) and register in `config_checks/0` (48-58). Give `run/1` an injectable `opts[:key_storage_status]` zero-arity fun so unit tests use fabricated maps (verify_test.exs:222-233 uses the real committed DB).

---

### `test/lockspire/storage/reencrypt_concurrency_test.exs` (integration)

**Analog:** `test/lockspire/storage/repository_concurrency_test.exs` lines 1-60.
```elixir
use ExUnit.Case, async: false
@moduletag :integration

setup_all do
  unless Process.whereis(Lockspire.TestRepo) do
    start_supervised!(Lockspire.TestRepo)
  end
  Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
  :ok
end
# contenders: Task.async + send(parent, {:ready_to_redeem, self()}) + receive :redeem -> unboxed(fn -> ... end)
defp unboxed(fun), do: Ecto.Adapters.SQL.Sandbox.unboxed_run(Lockspire.TestRepo, fun)
```
Seed through `unboxed`, `on_exit` cleanup by `kid` prefix (never `delete_all(SigningKeyRecord)`). Deterministic overlap: internal after-lock hook that sends `{:locked, self()}` then blocks on `receive :release`.

---

### `test/mix/tasks/lockspire_keys_reencrypt_test.exs` (new)

**Analog:** `test/mix/tasks/lockspire_doctor_key_encryption_test.exs` (not opened; planner should read it for `capture_io`/`Mix.Task.reenable` and `put_key_encryption` usage). Unit part (arg rejection) runs in default suite. End-to-end part goes in a separate `:integration` module that does not start `TestRepo` (assert `refute Process.whereis(Lockspire.TestRepo)` in setup and after the run). Seeding and read-back via `Ecto.Migrator.with_repo(TestRepo, fn repo -> ... end, mode: :temporary)`.

---

### Rotation/engine test fixtures (`keys_reencrypt_test.exs`, `keys_encryption_status_test.exs`, `key_encryption_helpers.ex`)

**Analog:** `test/support/key_encryption_helpers.ex` (read in full). Use `put_key_encryption/1` (lines 21-37; async: false) and `seal_private_jwk/2` (lines 41-46), but note `seal_private_jwk/2` uses the cached keyset. `test_keyset/1` (lines 50-58) uses `"helper-kek-#{id}"` material, which differs from `config/test.exs`'s `test-1`/`test-2` (`:crypto.hash(:sha256, "lockspire-test-kek-1") |> Base.encode64()`); old-KEK fixtures must use the config material. Add `reset_decode_warnings/0`:
```elixir
for {{Lockspire, :key_decode_warned, _, _} = k, _} <- :persistent_term.get(), do: :persistent_term.erase(k)
```
Seeds for audit/telemetry assertions: `Lockspire.TestSupport.TelemetryCapture.attach_many/2` sends `{:telemetry_event, event, measurements, metadata}`; assert `Enum.sort(Map.keys(meta))` for exact key sets.

## Shared Patterns

### Redaction and leak discipline
**Source:** `lib/lockspire/observability.ex:14-44` (operator path: redaction + `count` + audit mirror), `plug/verify_token.ex:478-496` (hot path direct execute).
**Apply to:** all new telemetry and audit; never place `SigningKey`, `KeySet`, decoded JWK, raw binaries, or exceptions in metadata. Map exceptions to `:storage_error`. No `inspect` in decoder/engine.

### Store queries marked sensitive
**Source:** `lib/lockspire/storage/ecto/repository/support.ex:21-41` (`sensitive: true` becomes `log: false`).
**Apply to:** engine `update_all` and locked reads (CAS `where` binds plaintext JWK).

### Mix task conventions
**Source:** `lib/mix/tasks/lockspire.upgrade.ex:10-41` and `lockspire.doctor.key_encryption.ex:17-34`: `@requirements ["app.config"]`, strict `OptionParser`, `Mix.shell().info`, `Mix.raise` for failure.
**Apply to:** `lockspire.keys.reencrypt`, doctor changes.

### Repo lifecycle guard
**Source:** `Install.Verify.migration_status/2` (verify.ex:368-375) uses `Ecto.Migrator.with_repo`, which restarts an already-running repo. Apply `if Process.whereis(repo), do: fun.(repo), else: Ecto.Migrator.with_repo(repo, fun, mode: :temporary)` in doctor and Verify; the Mix task itself uses `with_repo` unconditionally.

### Architecture fitness constraints
**Source:** `test/lockspire/architecture_fitness_test.exs` (84-100 facade completeness and no Ecto in `repository.ex`; 50-69 JWKS/discovery/KeyCache never mention `PrivateJwk`/`KeyEncryption`; 294 protocol files never reference `Admin`/`Web`). Extend with a test that `read_stored(` callers are limited to `protocol/private_jwk.ex` and `admin/keys*.ex`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/lockspire/security/key_material_leak_test.exs` | test | event-driven | No existing sentinel leak test. Compose `ExUnit.CaptureLog` (at `:debug`), `TelemetryCapture`, and audit-row reads from RESEARCH D-28 and "Validation Architecture". |
| `pg_stat_activity` blocked-backend poll (in concurrency test) | test helper | concurrency | Not exercised anywhere; fallback is a bounded `Task.yield/2` plus hook ordering. |

## Metadata

**Analog search scope:** `lib/lockspire/{storage,admin,protocol,install,plug}`, `lib/mix/tasks`, `test/support`, `test/lockspire/storage`, `test/mix/tasks`
**Files scanned/read:** about 14 read directly; others via RESEARCH ledger line references
**Tracked-source gate:** `git ls-files` confirmed tracked for signing_key_store.ex, admin/keys.ex, lockspire.upgrade.ex, key_encryption_helpers.ex, repository_concurrency_test.exs, verify_token.ex, install/verify.ex.
**Pattern extraction date:** 2026-10-16
