# Phase 158: Mix Task Repo Start - Pattern Map

**Mapped:** 2026-10-18
**Files analyzed:** 17 (new/modified)
**Analogs found:** 16 / 17

All analog paths below are git-tracked (verified with `git ls-files`).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/lockspire.client.create.ex` (mod) | mix task | request-response, write | `lib/mix/tasks/lockspire.doctor.key_encryption.ex:140-149` (RepoRunner caller) + `lockspire.keys.reencrypt.ex:108-159` (compute-then-print) | role-match |
| `lib/mix/tasks/lockspire.doctor.token_format.ex` (mod) | mix task | read, request-response | same two | role-match |
| `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` (mod) | mix task | read, request-response | same two | role-match |
| `lib/lockspire/install/task_error.ex` (new, name is discretion) | utility | transform (exception to fixed phrase) | `lib/lockspire/install/repo_runner.ex` (location and style) | partial |
| `lib/lockspire/install/repo_runner.ex` (mod, comment block only) | utility | request-response | itself | exact |
| `lib/lockspire/clients/registration_result.ex` (mod) | model | transform | `lib/lockspire/domain/signing_key.ex:29` | exact |
| `test/support/mix_repo_helpers.ex` (new) | test helper | batch | local `run_task/1`, `with_repo/1`, `cleanup/0` in `test/mix/tasks/lockspire_keys_reencrypt_test.exs:391-445` | role-match |
| `test/mix/tasks/lockspire_client_create_cold_test.exs` (new) | test | cold-repo integration | `Mix.Tasks.Lockspire.Keys.ReencryptE2ETest` in `test/mix/tasks/lockspire_keys_reencrypt_test.exs:65-124` | exact |
| `test/mix/tasks/lockspire_doctor_token_format_cold_test.exs` (new) | test | cold-repo integration | same, plus `test/integration/signing_key_upgrade_journey_test.exs:25-44` | exact |
| `test/mix/tasks/lockspire_doctor_remote_jwks_cold_test.exs` (new) | test | cold-repo integration | same | exact |
| `test/lockspire/install/task_error_test.exs` (new) | test | unit | `test/lockspire/install/repo_runner_test.exs` | role-match |
| `test/lockspire/install/repo_runner_test.exs` (mod) | test | unit | itself | exact |
| `test/mix/tasks/lockspire_doctor_token_format_test.exs`, `..._remote_jwks_test.exs` (mod: drop put_env, add pool check) | test | unit | themselves | exact |
| `test/lockspire/clients_test.exs` (mod: Inspect assertion) | test | unit | itself (:299-324) | exact |
| `scripts/acceptance/clean_room/build_provider.py` (mod) | harness | subprocess | `run_child_command` at :279-292 | exact |
| `scripts/acceptance/clean_room_saas_journey.py` (mod) | harness | sequential steps | steps at ~:915-925, `register_secret` at :63 | exact |
| `lib/mix/tasks/lockspire.keys.reencrypt.ex` | (unchanged, reference only) | | | |

## Pattern Assignments

### The three mix tasks (shared shape)

**Primary analog (RepoRunner caller):** `lib/mix/tasks/lockspire.doctor.key_encryption.ex:140-149`

```elixir
defp fetch_status do
  repo = Lockspire.Config.repo!()

  case RepoRunner.run(repo, fn _repo -> Keys.encryption_status() end) do
    {:ok, {:ok, status}} -> {:ok, status}
    _unavailable -> :error
  end
rescue
  _error -> :error
end
```

Take from it: `Lockspire.Config.repo!()` resolved outside the runner, and the `{:ok, {:ok, x}}` double-tuple match. Do NOT copy the swallow-everything `rescue` or `_unavailable` catch-all. Phase 158 must keep distinct branches.

**Compute-then-print analog:** `lib/mix/tasks/lockspire.keys.reencrypt.ex:108-141, 157-159`

```elixir
defp execute(mode) do
  {:ok, _} = Application.ensure_all_started(:ecto_sql)

  result =
    case Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _repo -> work(mode) end, mode: :temporary) do
      {:ok, result, _apps} -> result
      {:error, _reason} -> Mix.raise(repo_failure())
    end

  finish(mode, result)
end

# Only computes. Printing and raising happen after the repo has been stopped again.
defp work(:apply), do: Keys.reencrypt(actor: @actor)
...
defp raise_error(_reason), do: Mix.raise(repo_failure())
defp repo_failure, do: "could not start the repo; check database connectivity and config"
```

Swap raw `with_repo` for `RepoRunner.run(repo, fun)` (D-01). Wording: reuse `repo_failure` text and append ` :lockspire, :repo` per D-06. Keep `@requirements ["app.config"]` (already present in all three tasks) and the `OptionParser.parse(args, strict: @switches)` + `Mix.raise("Unknown options: ...")` preamble as is.

**RepoRunner contract (`lib/lockspire/install/repo_runner.ex:11-32`):** `run/2` returns `{:ok, fun_result} | {:error, :repo_unavailable}`, and its `rescue`/`catch` (lines 19-22) turns anything raised in the fun, including `Mix.Error`, into `:repo_unavailable`. So:

```elixir
def run(repo, fun) when is_atom(repo) and is_function(fun, 1) do
  if is_pid(Process.whereis(repo)) do
    {:ok, fun.(repo)}
  else
    start_and_run(repo, fun)
  end
rescue
  _error -> {:error, :repo_unavailable}
catch
  _kind, _reason -> {:error, :repo_unavailable}
end
```

Only the `#` comment block changes (lines 4-9 under `@moduledoc false`; line 4 says "read-only diagnostics"). Update it because `client.create` writes. No behavior change.

**Target body for `client.create` (from RESEARCH.md code example, D-02/D-11):**

```elixir
repo = Lockspire.Config.repo!()

outcome =
  RepoRunner.run(repo, fn _repo ->
    prev = Logger.get_process_level(self())
    Logger.put_process_level(self(), :info)
    try do
      attrs |> Clients.register_client()
    rescue
      error -> {:error, {:db, TaskError.classify(error)}}
    after
      if prev, do: Logger.put_process_level(self(), prev), else: Logger.delete_process_level(self())
    end
  end)

case outcome do
  {:ok, {:ok, result}}                         -> print_success(result)
  {:ok, {:error, errors}} when is_list(errors) -> Mix.raise(format_domain_errors(errors))
  {:ok, {:error, {:db, phrase}}}               -> Mix.raise("client registration failed: " <> phrase)
  {:error, :repo_unavailable}                  -> Mix.raise(repo_failure())
end
```

**Current `client.create` code to modify** (`lib/mix/tasks/lockspire.client.create.ex`):
- `run/1` pipeline at :37-40 (`opts |> build_attrs() |> Clients.register_client() |> print_result()`): split so the register call is inside the runner fun.
- Keep the success printer at :81-103 verbatim, including the secret guard at :89-91:
  ```elixir
  if result.client_secret do
    Mix.shell().info("client_secret=#{result.client_secret}")
  end
  ```
- Replace the error printer at :105-112 (`"#{error.field}:#{error.reason}(#{error.detail})"` joined by `"; "`) with the D-07 multi-line format. Render `:base` / `:persistence_failed` through the classifier or a fixed phrase, never raw `detail`, because `clients.ex:184-185` puts `inspect(error)` in it.
- Add the crash-after-write note (D-12) to `help/0` at :44-60.

**`doctor.token_format`** (`lib/mix/tasks/lockspire.doctor.token_format.ex:58-66`): the whole `with` goes into one fun. Reads return `{:error, exception}` as values, so classify the returned exception rather than relying on rescue:

```elixir
with {:ok, policy} <- ServerPolicy.get_server_policy(),
     {:ok, clients} <- Clients.list_clients() do
  print_report(policy, clients)
else
  {:error, reason} ->
    Mix.shell().info("Could not inspect token formats: #{inspect(reason)}")   # replace inspect(reason)
end
```

Compute `{:ok, {policy, clients}} | {:error, reason}` inside the fun; call `print_report/2` after the runner returns. Exit-0 semantics stay: every failure is `Mix.shell().info("Could not inspect token formats: <phrase>")`. Never `Mix.raise` in this task. Update the moduledoc claim that it is purely read-only only if wording needs it (it is still read-only).

**`doctor.remote_jwks`** (`lib/mix/tasks/lockspire.doctor.remote_jwks.ex:34-38, 58-81`): wrap only `Clients.get_client/1` in the runner. Keep `print_result({:ok, client})` (pure `Clients.remote_jwks_summary/1`) outside. Keep `print_result({:error, :not_found})` -> `Mix.raise("Client not found.")`. Replace line 80 `Mix.raise("Could not inspect client: #{inspect(reason)}")` with the classified phrase.

### `lib/lockspire/install/task_error.ex` (utility, transform)

No exact analog. Style and location copy `repo_runner.ex` (`@moduledoc false`, small pure module under `Lockspire.Install`). Fixed-phrase mapping (D-06):

```elixir
def classify(%Postgrex.Error{postgres: %{code: :undefined_table}}),
  do: "the Lockspire tables are missing; run mix ecto.migrate, then rerun"
def classify(%Postgrex.Error{postgres: %{code: code}}), do: "database error (#{code})..."  # code NAME only
def classify(%DBConnection.ConnectionError{}),
  do: "could not reach the database; check database connectivity and config :lockspire, :repo"
def classify(%ArgumentError{message: m}), do: m   # client.create only; names config keys, not values
def classify(_other), do: "<fixed generic phrase>"
```

It must accept both a returned `{:error, exception}` payload and a rescued exception. Never call `inspect/1` or `Exception.message/1` on DB exceptions (the Postgrex message embeds SQL). A `run/2` wrapper (rescue plus process-level set/restore) can live here as well.

### `lib/lockspire/clients/registration_result.ex` (model)

**Analog:** `lib/lockspire/domain/signing_key.ex:29` (also `lib/lockspire/storage/ecto/signing_key_record.ex:12`):

```elixir
@derive {Inspect, except: [:private_jwk_encrypted]}
```

Add `@derive {Inspect, except: [:client_secret]}` immediately before `defstruct [:client, :client_secret]` (line 13 currently). It must precede `defstruct`.

### `test/support/mix_repo_helpers.ex` (test helper)

`test/support` is compiled in test (`elixirc_paths(:test)` includes it); `test/support/*.ex` helpers are tracked. Lift these from `test/mix/tasks/lockspire_keys_reencrypt_test.exs`:

`run_task` (:391-410):
```elixir
defp run_task(args) do
  Mix.Task.reenable(@task)
  test_pid = self()
  output =
    capture_io(fn ->
      result =
        try do
          Mix.Task.run(@task, args)
          :ok
        rescue
          error in Mix.Error -> {:error, error}
        end
      send(test_pid, {:task_result, result})
    end)
  assert_received {:task_result, result}
  {output, result}
end
```

`with_repo` (:434-439), which is allowed in test setup and cleanup only, never in task code:
```elixir
defp with_repo(fun) do
  {:ok, result, _apps} =
    Ecto.Migrator.with_repo(Lockspire.TestRepo, fn _ -> fun.() end, mode: :temporary)
  result
end
```

Add the new pieces from RESEARCH.md: `pool_fingerprint(repo)` returning `%{name_pid: Process.whereis(repo), pool_pid: Ecto.Adapter.lookup_meta(repo).pid}`, `assert_pool_untouched!/2` (compare fingerprints, assert no `:DOWN` from a monitor taken earlier, assert a row inserted before is still visible), and `assert_repo_stopped!/0` (`refute Process.whereis(Lockspire.TestRepo)`). Cleanup by prefix follows `cleanup/0` (:441-450; `like(k.kid, "mig-task-%")` and delete by ids).

### Cold-path test modules (3 new)

**Analog:** `test/mix/tasks/lockspire_keys_reencrypt_test.exs:65-124` and `test/integration/signing_key_upgrade_journey_test.exs:25-44`:

```elixir
use ExUnit.Case, async: false
import Ecto.Query
import ExUnit.CaptureIO
@moduletag :integration

setup do
  refute Process.whereis(Lockspire.TestRepo),
         "the task must start the repo itself, so this test must begin with it stopped"

  foreign =
    with_repo(fn ->
      Lockspire.TestRepo.aggregate(
        from(k in SigningKeyRecord, where: not like(k.kid, ^(@prefix_root <> "%"))), :count)
    end)

  assert foreign == 0, "the committed test database holds #{foreign} ... reset the committed test database before running it"

  on_exit(&cleanup/0)
  Mix.Task.reenable(@task)
  on_exit(fn -> Mix.Task.reenable(@task) end)

  %{prefix: @prefix_root <> Base.url_encode64(:crypto.strong_rand_bytes(6), padding: false)}
end
```

Adapt to the clients table (`Lockspire.Storage.Ecto.ClientRecord`, guard on `client_id` not like prefix). Never `start_supervised!` the repo. After the task, assert `refute Process.whereis(Lockspire.TestRepo)` (as at reencrypt_test :115-124).

- Reenable both `"lockspire.doctor"` and the leaf for doctor modules (precedent `test/mix/tasks/lockspire_doctor_key_encryption_test.exs:10-15`):
  ```elixir
  for name <- ["lockspire.doctor", "lockspire.doctor.key_encryption"] do
    Mix.Task.reenable(name)
    on_exit(fn -> Mix.Task.reenable(name) end)
  end
  ```
- Seeded doctor tests: assert `=~` on seeded random ids, since token_format lists every client.
- client.create log-safety test: `config/test.exs` sets `log: false`, so the test must `Application.put_env(:lockspire, Lockspire.TestRepo, Keyword.put(cfg, :log, :debug))` before the cold start, restore in `on_exit`, and use `capture_log([level: :debug], fn -> ... end)`.
- Count the secret line with `length(String.split(output, "client_secret=")) - 1 == 1`. The warning text says `client_secret now` with no `=`.

### `repo_runner_test.exs` hardening (D-14)

**Current** (`test/lockspire/install/repo_runner_test.exs:12-23`):
```elixir
start_supervised!(Lockspire.TestRepo)
pid = Process.whereis(Lockspire.TestRepo)
assert {:ok, :ran} = RepoRunner.run(Lockspire.TestRepo, fn repo -> ... :ran end)
assert Process.whereis(Lockspire.TestRepo) == pid
```
`whereis` equality cannot detect a `with_repo` `:restart`. Replace the final assert with `assert_pool_untouched!` (before/after `pool_fingerprint`, monitor with no `:DOWN`, pre-inserted sandbox row still visible).

Unavailable-repo double for the "could not start the repo" path (lines 6-10):
```elixir
defmodule RaisingRepo do
  def config, do: []
  def __adapter__, do: Ecto.Adapters.Postgres
  def start_link(_opts), do: raise(DBConnection.ConnectionError, "connection refused")
end
```
Use `Application.put_env(:lockspire, :repo, RaisingRepo)` with restore in `on_exit`. Prefer it over an unreachable port (about 4 s and unsuppressible log noise). Either move it to the helper or define a copy in the cold test.

### Existing doctor tests (modify)

`test/mix/tasks/lockspire_doctor_token_format_test.exs:10-18`: `setup_all` runs `Application.put_env(:lockspire, :repo, Lockspire.TestRepo)` (redundant, `config/test.exs:31` sets it, drop it), then `start_supervised!(Lockspire.TestRepo)` plus `Sandbox.mode(..., :manual)`, and per-test `Sandbox.checkout`. Add `assert_pool_untouched!` around a task run here and in the remote_jwks test. The task runs in the test process, so sandbox ownership holds through RepoRunner's direct path. `test/lockspire/clients_test.exs:299-324` already calls `Mix.Tasks.Lockspire.Client.Create.run/1` directly and should keep passing; add `refute inspect(result) =~ secret` there.

### Clean-room harness

**`scripts/acceptance/clean_room/build_provider.py:279-292`** (current):
```python
def run_child_command(child: Path, environment: dict[str, str], *command: str) -> None:
    completed = subprocess.run(
        ("mix", *command), cwd=child, env=environment, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
    )
    if completed.returncode != 0:
        details = completed.stdout.decode(errors="replace").splitlines()[-16:]
        raise PackageInputError(f"provider {' '.join(command)} failed: {' '.join(details)}")
```
Add a sibling (e.g. `run_child_command_output(...) -> str`) with the same call and failure branch that returns `completed.stdout.decode(errors="replace")`. Share the failure code by extracting a private helper, or duplicate it. Exit codes alone miss `token_format`'s exit-0 failure.

**`scripts/acceptance/clean_room_saas_journey.py:921-925`** (insertion point after the `key_encryption` line, before `register_handoff_secrets(handoff)`):
```python
run_child_command(provider_child, provider_environment, "lockspire.keys.reencrypt", "--check")
run_child_command(provider_child, provider_environment, "lockspire.doctor", "key_encryption")
register_handoff_secrets(handoff)
```
Add after `key_encryption`: capture `lockspire.client.create ...` (confidential, `clean-room-cli-<suffix>` id), parse the `client_secret=` line and call `register_secret(value)` (defined at :63) immediately, before any other output or evidence. Then capture `lockspire.doctor token_format` and assert the new client id is in the output and `Could not inspect` is not. Then capture `lockspire.doctor remote-jwks --client <id>` and assert `Status: not_applicable`. Note the dispatcher accepts both `remote-jwks` and `token_format`. D-18: first commit adds these steps with tasks unchanged, then record the failure and SHA in the SUMMARY. D-19: record whether `Observability.emit` telemetry appears under `app.config` only.

## Shared Patterns

### Compute inside, print and raise outside
**Source:** `lib/mix/tasks/lockspire.keys.reencrypt.ex:124`, `lib/lockspire/install/repo_runner.ex:19-22`
**Apply to:** all three tasks. `Mix.raise` or `Mix.shell().info` inside the runner fun is converted to `:repo_unavailable`.

### Fixed-phrase failures, no raw exception text
**Source:** `repo_runner.ex:7-9` (comment block "never expose the underlying exception"), `keys.reencrypt.ex:154-159` (calm "cause; next step" lowercase copy)
**Apply to:** every failure path in the three tasks. Remove `inspect(reason)` at `token_format.ex:64` and `remote_jwks.ex:80`, and the `inspect` detail on the `:base` path.

### Task preamble and `@requirements`
**Source:** `lockspire.keys.reencrypt.ex:11-38`: `use Mix.Task`, `@requirements ["app.config"]`, `OptionParser.parse(args, strict: @switches)`, `--help` branch to `Mix.shell().info(help())`.
**Apply to:** unchanged in all three tasks.

### Sensitive struct Inspect derive
**Source:** `lib/lockspire/domain/signing_key.ex:29`
**Apply to:** `RegistrationResult` only.

### Cold test hygiene
**Source:** `signing_key_upgrade_journey_test.exs:25-44`
**Apply to:** all three cold modules: repo stopped at start, random prefix, foreign-row guard, `on_exit` cleanup through own `with_repo`, `Mix.Task.reenable`.

## No Analog Found

| File | Role | Reason |
|---|---|---|
| `lib/lockspire/install/task_error.ex` classifier | utility | No existing exception-to-fixed-phrase classifier. `keys.reencrypt.ex:143-157` `raise_error/1` clauses are the nearest style reference, and RESEARCH.md "Exception Shapes" supplies the struct patterns. |
| `Logger.put_process_level` set/restore wrapper | utility | No usage in repo. Use the pattern in RESEARCH.md ("Restore pattern"). |
| `pool_fingerprint` / `assert_pool_untouched!` | test helper | Only weak `Process.whereis` equality exists (`repo_runner_test.exs:22`). Use `Ecto.Adapter.lookup_meta(repo).pid` (precedent `deps/ecto_sql/lib/ecto/migrator.ex:848`). |

## Metadata

**Analog search scope:** `lib/mix/tasks`, `lib/lockspire/install`, `lib/lockspire/clients`, `lib/lockspire/domain`, `test/mix/tasks`, `test/integration`, `test/lockspire/install`, `scripts/acceptance`
**Files read:** 12
**Pattern extraction date:** 2026-10-18
