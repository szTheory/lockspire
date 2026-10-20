# Phase 159: Key-Encryption Key Setup DX - Pattern Map

**Mapped:** 2026-10-19
**Files analyzed:** 20 (6 new, 14 modified)
**Analogs found:** 20 / 20 (cold-test harness is a partial match; see Cold Test Verdict)

All analog paths verified git-tracked (`git ls-files`) for the support/test/script files checked; all `lib/`, `docs/`, `test/` paths below are ordinary tracked source.

## Cold Test Verdict (direct answer)

The Phase 158 `*_cold_test.exs` files (`test/mix/tasks/lockspire_client_create_cold_test.exs`, `..._doctor_token_format_cold_test.exs`, `..._doctor_remote_jwks_cold_test.exs`) and `test/support/mix_repo_helpers.ex` are NOT a subprocess harness. "Cold" there means the Ecto repo process is stopped (`assert_repo_stopped!/1`) while the task runs IN the test VM via `Mix.Task.run/2` wrapped in `capture_io` (`run_task/2,3`, helpers lines 66-87). `grep System.cmd` over `test/mix` and `mix_repo_helpers.ex` returns nothing. All helpers are repo-centric (`with_temp_repo`, `assert_pool_untouched!`, `sweep_stale_cold_clients!`, `cleanup_clients_by_prefix!`, `RaisingRepo`) and DB-bound (`@moduletag :integration`).

Consequences for `gen.kek`:
- It CANNOT host the "host runtime.exs raises" case. In-VM `Mix.Task.run` never evaluates `config/runtime.exs` for any task, so it proves nothing about loadconfig/app.config behavior. `run_task/2` is still useful for the in-VM unit tests (it captures output and converts `Mix.Error` into `{:error, e}`), and `with_temp_repo` / sweeps are irrelevant to `gen.kek` (no repo).
- A real cold test needs a subprocess. The only `System.cmd` precedents are the Python clean-room tests: `test/integration/phase133_provider_install_test.exs:11-16` (`System.cmd("python3", [@builder, "--self-test"], stderr_to_stdout: true)`, `@moduletag :integration`, `@moduletag :package_clean`, `@tag timeout: 180_000`) driving `scripts/acceptance/clean_room/build_provider.py`. That builder already writes a child host `config/runtime.exs` with `System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY") || raise(...)` (lines 83-93) and a child project that depends on Lockspire.
- Recommendation: (a) mechanism is already proven by the research fixture (loadconfig only; `app.config` loads runtime.exs); (b) Lockspire-specific proof = a new clean-room step in `build_provider.py` (child has runtime.exs that raises when `LOCKSPIRE_KEY_ENCRYPTION_KEY` unset; run `mix lockspire.gen.kek --raw` with that env var UNSET, assert exit 0 and one 44-char line, assert `mix lockspire.verify`/`app.config` still fails closed), asserted via a new case in `phase133_provider_install_test.exs` style (e.g. a `--check-gen-kek` flag, mirroring `--check-bootstrap`), OR (c) a small self-contained ExUnit test that builds a throwaway Mix project in `System.tmp_dir!()` with `{:lockspire, path: File.cwd!()}` and runs `System.cmd("mix", ["lockspire.gen.kek", "--raw"], cd: tmp, env: [{"MIX_ENV","dev"}])` -- no existing helper does this, so it is new code (name it `test/mix/tasks/lockspire_gen_kek_cold_test.exs`, tag `:integration`, `async: false`, long timeout, do not reuse `Lockspire.MixRepoHelpers`). Note CI Elixir 1.19.5-otp-28 and `System.cmd` env/`MIX_ENV` isolation (child must not inherit test `_build`). Option (b) reuses the existing child-host builder and is the lowest-new-code route; the clean-room child's runtime.exs is gated only by a missing env var, which is exactly the failure case.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/lockspire.gen.kek.ex` (new) | mix task | request-response (print) | `lib/mix/tasks/lockspire.keys.reencrypt.ex` (OptionParser/validate!/help) | role-match (minus `@requirements`) |
| `lib/lockspire/generators/kek_snippet.ex` (new) | utility (`@moduledoc false`) | transform | `lib/lockspire/generators/install.ex:124-162` (`instructions/1`) | exact (extraction source) |
| `lib/lockspire/generators/install.ex` (mod) | generator | transform | itself | exact |
| `lib/lockspire/security/key_encryption/key_set.ex` (mod: `valid_id?/1`) | model/validator | transform | `check_id/1` lines 99-101 | exact |
| `lib/lockspire/config.ex` (mod: resolve `{:system,var}`, new error path, msg) | config | transform | `key_encryption!/0` 254-266, `fail_key_encryption!` 282-290 | exact |
| `lib/lockspire/application.ex` (mod: msg) | boot | event-driven | itself 29-45 | exact |
| `lib/lockspire/install/verify.ex` (mod: msg ~96-98) | service | request-response | itself | exact |
| `lib/mix/tasks/lockspire.keys.reencrypt.ex` (mod: msg 144-148) | mix task | request-response | itself | exact |
| `lib/mix/tasks/lockspire.doctor.key_encryption.ex` (mod: msg 79-82) | mix task | request-response | itself | exact |
| `docs/upgrading/signing-key-encryption.md`, `docs/install-and-onboard.md` (mod) | docs | n/a | themselves | exact |
| `scripts/acceptance/clean_room/build_provider.py:89` (mod) | script | batch | itself | exact |
| `test/mix/tasks/lockspire_gen_kek_test.exs` (new) | test | request-response | `test/mix/tasks/lockspire_keys_reencrypt_test.exs` (args test, lines 1-20) | role-match |
| `test/mix/tasks/lockspire_gen_kek_cold_test.exs` or clean-room step (new) | test | subprocess | `test/integration/phase133_provider_install_test.exs` | partial (see verdict) |
| `test/lockspire/kek_guidance_contract_test.exs` (new) | contract test | file-I/O | `test/lockspire/upgrade_guide_contract_test.exs` | role-match |
| `test/lockspire/config_key_encryption_test.exs` (mod) | test | CRUD | itself 1-26, 83-87 | exact |
| `test/lockspire/install/verify_test.exs:339`, `upgrade_guide_contract_test.exs:14`, `test/integration/install_generator_test.exs:313` (mod) | test | n/a | themselves | exact |

## Pattern Assignments

### `lib/mix/tasks/lockspire.gen.kek.ex` (mix task, print-only)

**Analog:** `lib/mix/tasks/lockspire.keys.reencrypt.ex`

Copy structure (lines 11-38, 81-98), DROP `@requirements ["app.config"]` (line 16) and everything repo-related (lines 108-159):

```elixir
use Mix.Task
@shortdoc "..."
@switches [dry_run: :boolean, check: :boolean, help: :boolean]   # -> id: :string, raw: :boolean, help: :boolean

@impl Mix.Task
def run(args) do
  {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
  validate!(opts, argv, invalid)
  if Keyword.get(opts, :help, false), do: Mix.shell().info(help()), else: ...
end

defp validate!(opts, argv, invalid) do
  cond do
    invalid != [] -> Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    argv != [] -> Mix.raise("Unexpected argument: #{Enum.join(argv, " ")}. " <>
        "Options start with dashes, for example --#{List.first(argv)}.")
    true -> :ok
  end
end
```
Add a clause: `--id` present and `not KeySet.valid_id?(id)` -> `Mix.raise`. Output via `Mix.shell().info/1` only. Help text must avoid planning vocabulary (`@forbidden ~r/\b(phase|plan|wave|D-\d+|MIG-\d+|OPS-\d+|SAFE-\d+)\b/i`, see reencrypt args test).

### `lib/lockspire/generators/kek_snippet.ex` (new, `@moduledoc false`, leaf module)

**Analog:** `lib/lockspire/generators/install.ex:124-162`. Extract exactly:
```elixir
kek_id = Calendar.strftime(DateTime.utc_now(), "%Y-%m")
dev_kek = Base.encode64(:crypto.strong_rand_bytes(32))
...
           if config_env() == :prod do
             config :lockspire, :key_encryption,
               keys: [
                 {"#{kek_id}",
                  System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY") ||
                    raise("LOCKSPIRE_KEY_ENCRYPTION_KEY is missing. Generate one with: openssl rand -base64 32")}   # line 146: change text to `mix lockspire.gen.kek`
               ],
               current: "#{kek_id}",
               legacy_plaintext: :reject
           end
```
Expose `generate_key/0`, `default_id/0`, `prod_block(id)`. Must not alias `Install` (xref cycle check). The dev/test block (lines 152-158) stays in `Install.instructions/1` using `KekSnippet.generate_key/0` for its throwaway literal; `gen.kek` never prints it.

### `lib/lockspire/generators/install.ex` (modify)

Replace lines 125-126 and 139-150 with `KekSnippet` calls; keep every needle asserted at `install_generator_test.exs:305-320` (`LOCKSPIRE_KEY_ENCRYPTION_KEY`, `config/runtime.exs`, `if config_env() == :prod`, `legacy_plaintext: :reject`, `config/dev.exs`, `config/test.exs`, `dev/test only`, `"<month>"`) except `openssl rand -base64 32` -> `mix lockspire.gen.kek` (line 313). That test extracts the dev literal (`extract_dev_literal!`) and round-trips it through `KeySet.new` -- the dev block format must stay parseable by it.

### `lib/lockspire/security/key_encryption/key_set.ex` (modify)

**Analog:** `key_set.ex:48,99-101`:
```elixir
@id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/
defp check_id(id) do
  if Regex.match?(@id_pattern, id), do: :ok, else: {:error, {:keys, :invalid_key_id}}
end
```
Add `@spec valid_id?(term()) :: boolean()` public `valid_id?/1` (binary clause + catch-all false) and make `check_id/1` call it. `decode_entry/2` (line ~88: `when is_binary(id) and is_binary(b64)`, fallback `{:error, {:keys, :invalid_key_entry}}`) is unchanged -- a `{id, {:system, v}}` entry is rejected, so resolution MUST precede it.

### `lib/lockspire/config.ex` (modify)

**Analog:** `config.ex:254-266` (note: `def key_encryption!` at 254) and 282-290.
```elixir
def key_encryption! do
  case Application.get_env(@app, :key_encryption) do
    nil -> nil
    config ->
      case KeySet.new(config) do
        {:ok, %KeySet{} = keyset} -> keyset
        {:error, {config_key, reason}} -> fail_key_encryption!(config_key, reason)
      end
  end
end
defp fail_key_encryption!(config_key, reason) when is_atom(config_key) and is_atom(reason) do
  raise ArgumentError,
        "invalid config :key_encryption (#{inspect(config_key)}: #{reason}) for :lockspire. " <> ...
```
Insert `resolve_system_entries(config)` between get_env and `KeySet.new` (only when `Keyword.keyword?(config)` and `:keys` is a non-empty list; map entries `{id, {:system, var}} when is_binary(var)` with `System.fetch_env/1`, `{:ok, v} when v != ""`; use `Enum.reduce_while`, leave other entries untouched so KeySet classifies them). Missing -> add a dedicated `fail_key_encryption!` clause/arity carrying `var` with the same `"invalid config :key_encryption"` prefix (required by `task_error.ex:21-26` `@config_message_prefixes`), message names the var, never a value, points to `mix lockspire.gen.kek`. No `Application.put_env` write-back, no `compile_env`. Message sweep for the generic error: replace `openssl rand -base64 32` (line 286) with `mix lockspire.gen.kek`; keep the `elixir -e` fallback (research A2) and the `phx.gen.secret` warning.

### `lib/lockspire/application.ex` (modify)

Lines 37-41 `nil` branch Logger.warning ends "(create a key with \`openssl rand -base64 32\`)." -> `mix lockspire.gen.kek`. Do not change control flow: a configured block with missing env raises from `Config.key_encryption!/0` before reaching this branch (fail-closed boot, `:persistent_term.put` not reached).

### Other message-only edits (verify.ex:96-98, keys.reencrypt.ex:144-148, doctor.key_encryption.ex:79-82)

Same mechanical swap, `keys.reencrypt.ex:146-147` text:
```elixir
"config :lockspire, :key_encryption is not set. Add keys: [{id, base64 of 32 random bytes}], " <>
  "current: id in config/runtime.exs (create a key with `openssl rand -base64 32`)."
```
Before editing, grep `test/mix/tasks/lockspire_doctor_key_encryption_test.exs` and `lockspire_keys_reencrypt_test.exs` for assertions on this text.

### `test/mix/tasks/lockspire_gen_kek_test.exs` (new)

**Analog:** `test/mix/tasks/lockspire_keys_reencrypt_test.exs:1-20`:
```elixir
use ExUnit.Case, async: false   # gen.kek tests may be async: true if no env mutation
import ExUnit.CaptureIO
@task "lockspire.keys.reencrypt"
@forbidden ~r/\b(phase|plan|wave|D-\d+|MIG-\d+|OPS-\d+|SAFE-\d+)\b/i
setup do
  Mix.Task.reenable(@task)
  on_exit(fn -> Mix.Task.reenable(@task) end)
  :ok
end
for args <- [["check"], ["--bogus"], ...] do
  test "#{inspect(args)} raises ..." do
    assert_raise Mix.Error, fn -> Mix.Task.run(@task, unquote(args)) end
```
Use `Lockspire.MixRepoHelpers.run_task/2` (helpers 66-87) for `{output, :ok | {:error, e}}` if convenient; it reenables the task and captures IO. Cover: `--raw` one line of 44 chars decoding to 32 bytes, differs across runs, `KeySet.new(keys: [{id, value}], current: id)` round-trip, value printed once, no dev block with the key, bad `--id` (`a"b`, 33 chars, empty, `bad id`), unknown flag/positional, snippet `Code.string_to_quoted/1`, no `@forbidden` in help, `capture_log` empty.

### `test/lockspire/kek_guidance_contract_test.exs` (new, D-10)

**Analog:** `test/lockspire/upgrade_guide_contract_test.exs` (line 14 uses an `assert_in_order` list containing `"openssl rand -base64 32"`; swap to `"mix lockspire.gen.kek"`). Implement as `Path.wildcard("lib/**/*.{ex,exs}") ++ Path.wildcard("docs/**/*.md")`, fail on `openssl rand`; allow `elixir -e` only in `docs/upgrading/signing-key-encryption.md`; assert `gen.kek` appears in each guidance file. (File contents not re-read here; the planner should open the analog before writing.)

### `test/lockspire/config_key_encryption_test.exs` (modify)

**Analog:** itself. Reuse `setup` (lines 12-16: `put_key_encryption(Application.get_env(...))` registers restore), `put/1`, `message/1` (lines 21-26, `assert_raise ArgumentError`), `@sentinel`. Update lines 83-87 test: replace `openssl rand -base64 32` assertion with `mix lockspire.gen.kek`, keep `Base.encode64(:crypto.strong_rand_bytes(32))` and `phx.gen.secret`. For the unset-var boot test do NOT pass through `put_key_encryption/1` (it calls `validate_key_encryption!/0` and would raise in the helper; `test/support/key_encryption_helpers.ex:18-37`); use `Application.put_env` + `Config.key_encryption!/0`, `System.put_env`/`delete_env` with `on_exit` restore, `async: false`.

## Shared Patterns

### Config-error classification
**Source:** `lib/lockspire/install/task_error.ex:21-26` (`"invalid config :key_encryption"` prefix). **Apply to:** the new missing-env error in `Config`; keep the prefix so Verify/doctor surface it unchanged.

### Redaction / no key bytes
**Source:** `lib/lockspire/security/key_encryption/key_set_inspect.ex` (prints only `current`, `ids`, `legacy_plaintext`), `lib/lockspire/redaction.ex`. **Apply to:** proof tests only; no structural change.

### Mix task test hygiene
`Mix.Task.reenable/1` in `setup` and `on_exit`; `capture_io`; `Mix.Error` for bad args; repo untouched assertions use `refute Process.whereis(Lockspire.TestRepo)`.

### Subprocess/clean-room pattern
**Source:** `test/integration/phase133_provider_install_test.exs:6-16` plus `scripts/acceptance/clean_room/build_provider.py:83-93` (child host runtime.exs gated on missing env var; its line 89 also carries the `openssl rand -base64 32` string to update).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Subprocess `mix lockspire.gen.kek` run against a host whose runtime.exs raises (if built as ExUnit test, option c) | test | subprocess | No existing ExUnit helper spawns `mix` in a child project; closest is the Python clean-room builder driven by `System.cmd("python3", ...)` |

## Metadata

**Analog search scope:** `lib/mix/tasks`, `lib/lockspire/{generators,config,application,security}`, `test/mix/tasks`, `test/support`, `test/integration`, `scripts/acceptance/clean_room`
**Files read:** CONTEXT, RESEARCH, `mix_repo_helpers.ex`, `lockspire_doctor_token_format_cold_test.exs`, `lockspire.keys.reencrypt.ex`, `generators/install.ex`, parts of `config.ex`, `key_set.ex`, `application.ex`, config/reencrypt/install-generator tests, `phase133_provider_install_test.exs`, `build_provider.py`
**Pattern extraction date:** 2026-10-19
