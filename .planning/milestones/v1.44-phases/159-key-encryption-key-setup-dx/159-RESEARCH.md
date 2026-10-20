# Phase 159: Key-Encryption Key Setup DX - Research

**Researched:** 2026-10-19
**Domain:** Elixir Mix task + runtime config resolution + guidance-string sweep (no new deps, no schema, no protocol change)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
D-01..D-10 are locked (see `159-CONTEXT.md` `<decisions>`; planner must read it verbatim). Summary of each, unchanged:
- D-01 New `@moduledoc false` `Lockspire.Generators.KekSnippet` owns key generation (`Base.encode64(:crypto.strong_rand_bytes(32))`), default id (`Calendar.strftime(DateTime.utc_now(), "%Y-%m")`) and the prod `runtime.exs` block; installer and `gen.kek` both call it.
- D-02 `gen.kek` default output = `LOCKSPIRE_KEY_ENCRYPTION_KEY=<value>` + secret-manager line, shared prod block, one-line dev/test note (no dev block with the real key). `--raw` prints exactly one line, the value.
- D-03 Prod snippet keeps `System.get_env(...) || raise(...)`; only raise text changes to `mix lockspire.gen.kek`. `{:system, "VAR"}` documented as alternative.
- D-04 Plain `use Mix.Task`, no Igniter/`@requirements`/`app.config`; no repo, Logger, telemetry, file writes; output via `Mix.shell().info/1`; strict `OptionParser` (`--id`, `--raw`, `--help`); unknown opts/args -> `Mix.raise`.
- D-05 `--id` validated by public `KeySet.valid_id?/1` reusing the existing regex.
- D-06 Resolve `{id, {:system, var}}` inside `Config.key_encryption!/0` before `KeySet.new/1`; `System.fetch_env/1`; empty = missing; runtime only; no `compile_env`; no `put_env`.
- D-07 Unset/empty var raises `ArgumentError` through `fail_key_encryption!` with the `invalid config :key_encryption` prefix; names the var, never a value; new reason (e.g. `{:keys, :missing_env}`); never `nil`.
- D-08 No change to `key_set_inspect.ex`; add proof tests.
- D-09 Guidance sweep (file list in CONTEXT) + pinned-test updates in the same commit.
- D-10 Contract test failing on `openssl rand` without `gen.kek` in `lib/` or `docs/`; `elixir -e` one-liner allowed only in the upgrade guide as release-only fallback.

### Claude's Discretion
Exact `gen.kek` wording and `--help` text; exact reason atom for missing env; optionally switching clean-room harness to consume `gen.kek --raw`.

### Deferred Ideas (OUT OF SCOPE)
`gen.kek --rotate`, `--format json`, KMS/Vault, admin Keys page "Key protection" line (Phase 160), DOC-02 guide completeness/release (Phase 161), moving `keys.reencrypt` onto RepoRunner/TaskError.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KEK-03 | `mix lockspire.gen.kek` prints fresh key + shared fail-closed snippet; `--id`, `--raw`; no files/repo/logs/telemetry | Mix loadconfig finding (task runs even if `runtime.exs` raises); KekSnippet extraction; task patterns from `keys.reencrypt` |
| KEK-05 | `{:system, "VAR"}` resolved at runtime in `Lockspire.Config`, fail-closed | `Config.key_encryption!/0` is the only reader of the env block; `KeySet.decode_entry` rejects non-binaries so resolution must precede it |
| KEK-06 | No key bytes in inspect/logs; guidance points to `gen.kek` | `KeySetInspect` verified; full openssl-string inventory below |
| SAFE-02 (constraint) | No protocol/security-default/schema/dep change | All changes are config resolution, new task, strings, docs |
</phase_requirements>

## Summary

All integration points in CONTEXT.md were re-read this session and match (line numbers verified, minor drift noted below). The one open empirical question - whether a dependency Mix task without `@requirements` runs when the host's `config/runtime.exs` would raise - is answered YES, by both Elixir source and a fixture run on the CI Elixir (1.19.5-otp-28). `Mix.CLI.run_task` only does `Mix.Task.run("loadconfig")` before the task; `config/runtime.exs` is only loaded by `app.config` (which every other Lockspire task requests via `@requirements ["app.config"]`).

Resolution of `{:system, var}` is a small, local change to `Config.key_encryption!/0`. The only place the `:key_encryption` app env is read is `config.ex:255` (grep over `lib/` found no other `get_env`/`fetch_env` of that key), so Verify, doctor, Admin.Keys, boot and the hot path all inherit it. `KeySet` needs only a `valid_id?/1` predicate. The guidance sweep touches 9 source/doc files and 4 pinned tests; a new contract test locks it.

**Primary recommendation:** Implement in three plans: (1) `KeySet.valid_id?/1` + `KekSnippet` + installer refactor + `gen.kek` task + tests; (2) `{:system, var}` resolution + missing-env error + boot/redaction proof tests; (3) guidance sweep + pinned-test updates + openssl contract test + docs. Run everything on CI Elixir.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| KEK generation + snippet text | Generators (pure, no I/O) | Mix task (printing) | Shared builder prevents installer/task drift |
| `gen.kek` CLI | Mix task layer | — | Prints only; must not need app/config/repo |
| `{:system, var}` resolution | `Lockspire.Config` | — | Single resolution point; `KeySet` stays a pure validator |
| Fail-closed boot | `Lockspire.Application.validate_key_encryption!/0` | `Config` | Raise in `Config`, boot aborts in `start/2` |
| Redaction | `KeySetInspect` / `Redaction` | — | Already correct; tests only |
| Guidance strings | Config/Application/Verify/Mix tasks/docs | — | Sweep |

## Standard Stack

No new packages. Uses stdlib only: `:crypto`, `Base`, `Calendar`, `OptionParser`, `Mix.Task`, `System.fetch_env/1`, `ExUnit.CaptureIO`, `Code.string_to_quoted/1`. [VERIFIED: lib/lockspire/generators/install.ex:125-126 already uses `Base.encode64(:crypto.strong_rand_bytes(32))`]

Package Legitimacy Audit: no external packages installed in this phase - not applicable.

## Architecture Patterns

### Flow
```
mix lockspire.gen.kek [--id X] [--raw] [--help]
  -> Mix loads config.exs only (no runtime.exs, no app start)
  -> OptionParser strict -> validate (KeySet.valid_id?/1, no positional args)
  -> KekSnippet.generate_key/0, default_id/0, prod_block(id)
  -> Mix.shell().info(...)            (no files, no Logger, no telemetry)

app boot: Application.start -> validate_key_encryption!
  -> Config.key_encryption!
       get_env(:key_encryption)
         nil -> nil (warn path, unchanged)
         list -> resolve_system_entries (fetch_env, empty=missing)
                   missing -> raise ArgumentError "invalid config :key_encryption ... NAME ..."
               -> KeySet.new -> %KeySet{} -> :persistent_term
```

### Pattern: task shape
Copy `lockspire.keys.reencrypt.ex`: `use Mix.Task`, `@shortdoc`, `@switches`, `OptionParser.parse(args, strict: ...)`, `validate!` raising `Mix.raise`, in-module `help/0`. [VERIFIED: lib/mix/tasks/lockspire.keys.reencrypt.ex:11-33]. Differences: NO `@requirements`.

### Anti-Patterns
- Calling `Mix.Task.run("app.config")` or listing `@requirements` (defeats the cold-run guarantee).
- Logging or `IO.inspect`-ing the generated value; printing it more than once (D-02: once).
- Copying the id regex into the task.
- Writing the resolved value back with `Application.put_env` (CONTEXT D-06 forbids).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Key validation of resolved env value | A second validator | Existing `KeySet.new/1` (length/strength/dup checks run after resolution) |
| Id validation | New regex in the task | `KeySet.valid_id?/1` over `@id_pattern` |
| Snippet text | Two copies | `KekSnippet` |
| Config-error classification in tasks | New error type | Keep `invalid config :key_encryption` prefix (`task_error.ex` classification) |

## Verified Integration Points (read this session)

| Item | Location | Verbatim / finding |
|------|----------|--------------------|
| Env read | `lib/lockspire/config.ex:254-266` | `def key_encryption! do case Application.get_env(@app, :key_encryption) do nil -> nil; config -> case KeySet.new(config) do {:ok, %KeySet{} = keyset} -> keyset; {:error, {config_key, reason}} -> fail_key_encryption!(config_key, reason)` (CONTEXT said 253-266; actual `def` line 254) |
| Error fn | `config.ex:282-290` | `defp fail_key_encryption!(config_key, reason) when is_atom(config_key) and is_atom(reason)`; message begins `"invalid config :key_encryption (#{inspect(config_key)}: #{reason}) for :lockspire. "`, mentions `` `openssl rand -base64 32` `` and `` `elixir -e 'IO.puts(Base.encode64(:crypto.strong_rand_bytes(32)))'` `` and the `mix phx.gen.secret` warning |
| Id rule | `key_set.ex:48` | `@id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/`; `check_id/1` at 99-101 |
| Entry shape | `key_set.ex` `decode_entry({id, b64}) when is_binary(id) and is_binary(b64)`; fallback `decode_entry(_entry, _acc)` -> `{:error, {:keys, :invalid_key_entry}}` | A `{id, {:system, v}}` entry is rejected today -> resolution MUST happen before `KeySet.new` |
| Boot | `application.ex:29-45` | `validate_key_encryption!/0`; `nil ->` branch logs `"... (create a key with \`openssl rand -base64 32\`)."` (lines 37-41) |
| Inspect | `key_set_inspect.ex` | prints only `current: keyset.current_id, ids: keyset.ids, legacy_plaintext: ...` inside `"#Lockspire.KeyEncryption.KeySet<"` - no key bytes |
| TaskError | `task_error.ex:21-26` | `@config_message_prefixes [... "invalid config :key_encryption"]` |
| Installer | `generators/install.ex:124-157` | `defp instructions(assigns)`; line 146 `raise("LOCKSPIRE_KEY_ENCRYPTION_KEY is missing. Generate one with: openssl rand -base64 32")}`; dev block line ~152 uses `System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY", "#{dev_kek}")`; called at `install.ex:18` via `Mix.shell().info(instructions(assigns))` |
| Redaction list | `lib/lockspire/redaction.ex` lines 13-15, 59-61, 108-110, 154 | already contain `:kek`, `:key_encryption`, `:key_encryption_key` / string forms - no change needed |

### Complete openssl inventory (grep this session; D-09 list is complete plus one extra)
`lib/`: `config.ex:286`, `application.ex:40`, `install/verify.ex:97`, `generators/install.ex:146`, `mix/tasks/lockspire.keys.reencrypt.ex:147`, `mix/tasks/lockspire.doctor.key_encryption.ex:81`. `docs/`: `install-and-onboard.md:145,155`, `upgrading/signing-key-encryption.md:12`. `scripts/`: `acceptance/clean_room/build_provider.py:89`. Tests pinning the string: `config_key_encryption_test.exs:85`, `install/verify_test.exs:339`, `upgrade_guide_contract_test.exs:14`, `integration/install_generator_test.exs:313`. No other hits in `README.md`/`guides`/`test` beyond these. [VERIFIED: grep -rn openssl lib docs scripts test README.md]

Also stale: the upgrade guide Step 1 uses `System.fetch_env!("LOCKSPIRE_KEY_ENCRYPTION_KEY")` (line ~31); D-09 says align to installer form.

### The `config_key_encryption_test.exs:83-87` pin
Test "invalid key error names both generation commands and warns about phx.gen.secret" asserts `openssl rand -base64 32`, `Base.encode64(:crypto.strong_rand_bytes(32))`, `phx.gen.secret`. D-09 says keep the `phx.gen.secret` warning. Decision for planner: replace the openssl assertion with `mix lockspire.gen.kek`; the `elixir -e` fallback in the *config error* may stay (it is not an openssl recipe, D-10 only restricts `openssl rand`) - recommended to keep it so the existing `Base.encode64(...)` assertion stays valid for release-only hosts; rename the test accordingly. [ASSUMED - small wording call, see A2]

## Mix loadconfig / cold-run question - ANSWERED

- Elixir 1.19.5 source: `Mix.CLI.run_task` does `Mix.Task.run("loadconfig")` then `Mix.Task.run(name, args)`. [VERIFIED: /Users/jon/.asdf/installs/elixir/1.19.5-otp-28/lib/mix/lib/mix/cli.ex:128]
- `loadconfig` doc: "`config/config.exs` is always loaded automatically by the Mix CLI when it boots. `config/runtime.exs` is loaded automatically by `mix app.config` before starting the current application." [VERIFIED: .../lib/mix/lib/mix/tasks/loadconfig.ex:21-24]
- `app.config` loads runtime.exs. [VERIFIED: .../tasks/app.config.ex:37-40]
- Empirical fixture (scratchpad `fx/`): host project with a path dependency providing `Mix.Tasks.Dep.Kek` (no `@requirements`) and `config/runtime.exs` containing `System.get_env("MISSING_KEK") || raise("RUNTIME EXS RAISED")`. Result: `mix dep.kek` printed `KEK-TASK-RAN started=false` (task ran, dep app not started, no raise). `mix app.config` in the same host raised from `Config.Reader.read!`. [VERIFIED: fixture run, Elixir 1.19.5/OTP 28]
- Caveats: (a) the dependency must be compiled (normal after `mix deps.get`/`mix compile`); (b) the host's `config/config.exs` (and the `import_config` chain: dev.exs/prod.exs) still evaluate - if the host's compile-time config raises, the task fails; the installer's dev/test block uses `System.get_env(var, default)` so it does not. (c) Because the dep app is not started, `gen.kek` must not touch `Lockspire.Config`, `Logger` handlers it needs started, or telemetry. `Calendar`/`Base`/`:crypto` are fine (`:crypto` is part of OTP, loaded on demand).
- Remaining proof for planner: an in-repo test runs the task inside the Lockspire test VM, which does NOT prove cold behavior. Recommended: add a cold test modeled on existing `test/mix/tasks/lockspire_*_cold_test.exs` (subprocess `mix` run) or a clean-room harness step; the fixture above proves the mechanism, a Lockspire-specific cold test proves no hidden dependency on app start. [ASSUMED: the existing cold tests' harness is reusable; not opened this session]

## Common Pitfalls

### Pitfall 1: Resolution after validation
`KeySet.decode_entry` rejects `{id, {:system, v}}`. Resolve first, in `Config`. Resolution must also cope with the whole block being malformed (non-list, no `:keys`, non-keyword): only map when `config` is a keyword list with a list under `:keys`; otherwise pass through untouched so `KeySet.new/1` yields its normal shape errors.

### Pitfall 2: `fail_key_encryption!` guard and signature
It currently guards `is_atom(config_key) and is_atom(reason)` and has no place for a variable name. Add a separate clause/path for missing env carrying the var name (e.g. internal `{:error, {:keys, :missing_env, var}}` handled before the generic one), keeping the `invalid config :key_encryption` prefix. Do not interpolate the variable's *value* anywhere; naming `var` (a config-supplied name, not a secret) is safe. Message should not use the generic "Each key must be base64..." text.

### Pitfall 3: Never reach the `nil` branch
Missing env inside a configured block must raise, not return `nil`; boot's `nil` branch only warns (`application.ex`). Add a test that starts from a configured block with an unset var and asserts `assert_raise ArgumentError` from both `Config.key_encryption!/0` and `Lockspire.Application.validate_key_encryption!/0`, and that the `:persistent_term` cache is not set to `:unconfigured`.

### Pitfall 4: Test cache isolation
`put_key_encryption/1` swaps env AND calls `validate_key_encryption!/0`, so passing a block with an unset `{:system, _}` var through the helper will raise inside the helper. For the boot-fail test, set env directly (`Application.put_env`) and call `Config.key_encryption!/0` (as `config_key_encryption_test.exs` `message/1` does), with the file's `setup` restoring env/cache. Env-var tests are `async: false`; use `System.put_env`/`System.delete_env` with `on_exit` restore, and a sentinel value. [VERIFIED: test/support/key_encryption_helpers.ex:18-37; config_key_encryption_test.exs:1-26]

### Pitfall 5: Whitespace/newline in env values
A secret file or `echo` may append `\n`; base64 decode then fails with `:invalid_base64` (value never echoed). Do not silently `String.trim` (changes semantics; not in locked decisions). If the planner wants trim, surface as a user question. [ASSUMED, A3]

### Pitfall 6: `inspect` bypass options
`KeySetInspect` protects the default `inspect/1`. `inspect(ks, structs: false)` or `:sys.get_state`/crash dumps of a process holding the struct may bypass the protocol impl. Cache lives in `:persistent_term` (not a process state). Proof tests should cover `inspect/1`, `inspect(..., limit: :infinity, pretty: true)`, `"#{inspect(...)}"` and Logger capture; do not claim coverage of `structs: false`. [ASSUMED: `structs: false` behavior from training, not run - first attempt at a probe hit a compile-context error]

### Pitfall 7: Output hygiene of `gen.kek`
Print the value exactly once in default mode; `--raw` exactly one line (no trailing banner). Use `Mix.shell().info`, which is capturable with `capture_io`. Do not emit via `Logger`. Do not use `Mix.shell().error` for non-errors.

### Pitfall 8: Installer test expectations
`install_generator_test.exs:299-330` asserts needles in installer output (`"LOCKSPIRE_KEY_ENCRYPTION_KEY"`, `"if config_env() == :prod"`, `"legacy_plaintext: :reject"`, `"config/dev.exs"`, `"dev/test only"`, month id). The refactor must keep every needle except `openssl rand -base64 32` -> `mix lockspire.gen.kek`. [VERIFIED: test/integration/install_generator_test.exs:305-320]

### Pitfall 9: Docs build
`mix docs.verify` is `docs --warnings-as-errors` (`mix.exs:141`) and docs files are in extras (`mix.exs:206,230`). A `@moduledoc false` module and a Mix task with a normal `@moduledoc` are fine; avoid backticked references like `` `Lockspire.Generators.KekSnippet` `` inside public docs (hidden-module reference warnings). Run `mix docs.verify` on 1.19.5-otp-28 (dev env per `mix.exs:181`: `"docs.verify": :dev`).

### Pitfall 10: Vocabulary contract test
`test/lockspire/web/live/admin/vocabulary_contract_test.exs` only governs admin UI text; no admin UI is touched. Not relevant. The `@forbidden` regex in `keys.reencrypt` tests (`\b(phase|plan|wave|D-\d+|...)\b`) suggests user-facing task text must not contain planning vocabulary; apply the same to `gen.kek` help/output (add an analogous test).

### Pitfall 11: Architecture topology
CI runs `mix xref graph --format cycles --label compile-connected` (no cycles). `KekSnippet` should be a leaf (stdlib only); `Install` and the task depend on it; `KeySet.valid_id?/1` is a leaf. No cycle risk if `KekSnippet` does not alias `Install`.

## Code Examples (shape only, from verified local patterns)

```elixir
# KeySet - expose the existing rule (no copied regex)
@spec valid_id?(term()) :: boolean()
def valid_id?(id) when is_binary(id), do: Regex.match?(@id_pattern, id)
def valid_id?(_id), do: false
# check_id/1 then becomes: if valid_id?(id), do: :ok, else: {:error, {:keys, :invalid_key_id}}
```

```elixir
# Config - resolution step (runtime only, value never logged)
config -> config |> resolve_system_entries() |> then(&KeySet.new/1) ...
defp resolve_system_entries(config) when is_list(config) do
  case Keyword.keyword?(config) && Keyword.get(config, :keys) do
    [_ | _] = entries -> resolve each {id, {:system, var}} when is_binary(var):
        case System.fetch_env(var) do {:ok, v} when v != "" -> {id, v}; _ -> throw/return {:error, {:keys, :missing_env, var}} end
    _ -> config
  end
end
```
(Planner: implement with `Enum.reduce_while`, not throw; keep non-`{:system, binary}` entries untouched so `KeySet` classifies them.)

```elixir
# Task test shape
output = capture_io(fn -> Mix.Task.run("lockspire.gen.kek", ["--raw"]) end)
[value] = String.split(output, "\n", trim: true)
assert byte_size(Base.decode64!(value)) == 32 and byte_size(value) == 44
assert {:ok, _} = KeySet.new(keys: [{id, value}], current: id)
```
Always `Mix.Task.reenable("lockspire.gen.kek")` in setup/on_exit (pattern in `lockspire_keys_reencrypt_test.exs:1-15`).

## State of the Art
Elixir Mix: `config/runtime.exs` is loaded via `app.config` (since 1.11) - the premise of D-04. No tool changes.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing `*_cold_test.exs` subprocess harness is reusable for a `gen.kek` cold test | Mix loadconfig | Planner may need to write a small `System.cmd("mix", ...)` helper |
| A2 | Keep `elixir -e` one-liner in the config error message (not just the upgrade guide) | openssl inventory | D-10 text says "upgrade guide may keep" it; if user wants it removed from lib/, the pinned test assertion on `Base.encode64(` must go too |
| A3 | Do not trim whitespace from env values | Pitfalls | Hosts feeding values with trailing newline get `:invalid_base64`; may merit a discuss question |
| A4 | `inspect(struct, structs: false)` bypasses custom Inspect impls | Pitfalls | Only affects what the proof test claims |

## Open Questions

1. **Missing-env error shape inside the `{atom, atom}` tuple contract.** `KeySet.new` returns `{:error, {atom, atom}}`; the var name has to travel separately. Recommendation: have `resolve_system_entries` return `{:error, {:keys, :missing_env, var}}` and handle it in a dedicated `fail_key_encryption!/3`-style clause; leave `KeySet` contract unchanged. (Claude's discretion per CONTEXT.)
2. **Should `{:system, var}` in `config/config.exs` (compile-time evaluation) be called out in docs?** Value is read at boot via `Config.key_encryption!/0`, not at compile time, so config.exs storing the tuple is safe. Recommend one sentence in `install-and-onboard.md` and the upgrade guide (Phase 161 owns completeness).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (CI pair) | all verification | yes | 1.19.5 / OTP 28 via asdf | — |
| PostgreSQL | existing test suite subset (key leak tests) | assumed running locally (config_key_encryption tests ran green without DB use) | — | run only non-DB files for quick loop |
| Network | none | — | — | — |

Verified: `MIX_ENV=test mix test test/lockspire/config_key_encryption_test.exs` -> 18 tests, 0 failures on 1.19.5-otp-28.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5-otp-28), StreamData in places |
| Config file | `test/test_helper.exs`, `config/test.exs` |
| Env prefix | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; cd /Users/jon/projects/lockspire` |
| Quick run command | `MIX_ENV=test mix test test/mix/tasks/lockspire_gen_kek_test.exs test/lockspire/config_key_encryption_test.exs test/lockspire/upgrade_guide_contract_test.exs test/lockspire/install/verify_test.exs test/lockspire/kek_guidance_contract_test.exs` |
| Full suite command | `MIX_ENV=test mix test` plus `mix docs.verify` and `sh scripts/ci/check_architecture_topology.sh` (or `mix ci` per mix.exs:146) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| KEK-03 | prints 44-char base64 decoding to 32 bytes; differs between runs | unit | `mix test test/mix/tasks/lockspire_gen_kek_test.exs` | Wave 0 |
| KEK-03 | `--raw` is exactly one line equal to the value; no banner | unit | same | Wave 0 |
| KEK-03 | default output contains value once, `LOCKSPIRE_KEY_ENCRYPTION_KEY=`, the prod block, dev/test note; does NOT contain a dev block with the key | unit | same | Wave 0 |
| KEK-03 | `--id` valid passes; invalid (`a"b`, 33 chars, empty, `bad id`) -> `Mix.Error`; default id = `YYYY-MM` UTC | unit | same | Wave 0 |
| KEK-03 | round trip: `KeySet.new(keys: [{id, value}], current: id)` is `{:ok, _}` | unit | same | Wave 0 |
| KEK-03 | snippet parses (`Code.string_to_quoted/1`) and equals installer's block (shared builder; installer output contains the `KekSnippet` block) | unit | gen_kek test + `test/integration/install_generator_test.exs` | Wave 0 / exists |
| KEK-03 | unknown flag/positional -> `Mix.Error`; `--help` has no planning vocabulary | unit | same | Wave 0 |
| KEK-03 | no files written, no Logger output, no telemetry (`capture_log` empty; telemetry handler gets nothing; `File.ls!` of tmp cwd unchanged) | unit | same | Wave 0 |
| KEK-03 | runs cold when host runtime.exs raises (no `@requirements`) | cold/subprocess | `mix test test/mix/tasks/lockspire_gen_kek_cold_test.exs` (or clean-room step) | Wave 0 |
| KEK-05 | `{id, {:system, "VAR"}}` set -> resolved `%KeySet{}` with correct bytes | unit (async: false) | `mix test test/lockspire/config_key_encryption_test.exs` | exists, extend |
| KEK-05 | resolution at runtime: change env between calls -> new value (not compile-time); app env still holds the tuple after resolve (no write-back) | unit | same | exists, extend |
| KEK-05 | unset var, empty var -> `ArgumentError` with `invalid config :key_encryption`, contains var name, never the value of any other env; mixed list (one literal, one unset system) raises | unit | same | exists, extend |
| KEK-05 | `Lockspire.Application.validate_key_encryption!/0` raises and does not store `:unconfigured` | unit | same | exists, extend |
| KEK-05 | non-binary var / wrong arity tuple -> `:invalid_key_entry` (KeySet) not crash | unit | same | exists, extend |
| KEK-05 | invalid resolved value (31 bytes) -> existing reason error, sentinel absent from message | unit | same | exists, extend |
| KEK-06 | `inspect(keyset)` and `capture_log` of `Logger.info("#{inspect(ks)}")` contain neither key bytes, base64, nor env value (system-resolved set) | unit | `mix test test/lockspire/security/key_material_leak_test.exs` or config test | exists, extend |
| KEK-06 | `verify` with unset `{:system}` var surfaces message with var name, no value | unit | `mix test test/lockspire/install/verify_test.exs` | exists, extend |
| KEK-06 / D-10 | contract: no `openssl rand` in `lib/` or `docs/` (allow-list: none; `elixir -e` only in the upgrade guide); every guidance location mentions `mix lockspire.gen.kek` | contract | `mix test test/lockspire/kek_guidance_contract_test.exs` | Wave 0 |
| SAFE-02 | no new deps in `mix.exs`/`mix.lock` diff; no migration/schema/protocol file in diff | review/manual (git diff --stat) | `git diff --stat main -- mix.exs mix.lock priv lib/lockspire/protocol` | n/a |

### Pinned tests to update in the same commit as the strings
`config_key_encryption_test.exs:83-87`, `install/verify_test.exs:339`, `upgrade_guide_contract_test.exs:14` (`assert_in_order` list: replace `"openssl rand -base64 32"` with `"mix lockspire.gen.kek"` so ordering still holds), `integration/install_generator_test.exs:313`. Also check `test/mix/tasks/lockspire_doctor_key_encryption_test.exs` and `lockspire_keys_reencrypt_test.exs` for assertions on the "not set" message text (not opened; grep before editing).

### Sampling Rate
- **Per task commit:** the Quick run command above (no DB needed except where noted).
- **Per wave merge:** `MIX_ENV=test mix test test/lockspire test/mix test/integration/install_generator_test.exs`
- **Phase gate:** `MIX_ENV=test mix test` full suite, `mix docs.verify`, `mix format --check-formatted`, `mix credo --strict` (per project `scripts/ci/run_credo.sh`), topology script - all on 1.19.5-otp-28 (local 1.20 type warnings fail warnings-as-errors).

### Wave 0 Gaps
- [ ] `test/mix/tasks/lockspire_gen_kek_test.exs` - KEK-03 unit coverage (async: true is safe if no env mutation; cwd/file check uses `File.cd!` in a tmp dir only if serialized - prefer asserting via `File.stat` of `config/` untouched or simply not asserting cwd changes beyond tmp listing)
- [ ] `test/mix/tasks/lockspire_gen_kek_cold_test.exs` - subprocess proof (optional if clean-room covers it)
- [ ] `test/lockspire/kek_guidance_contract_test.exs` - D-10 contract (walk `lib/**/*.{ex,exs}` and `docs/**/*.md`; fail on `openssl rand`; require `gen.kek` in the guidance files)
- [ ] Python harness `build_provider.py:89` string update (python script - not under mix test; covered by `clean_room_release_source_contract_test.exs`? verify by grep before editing)

## Security Domain

Applicable ASVS categories:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3/V4 | no | — |
| V5 Input Validation | yes | `OptionParser` strict + `KeySet.valid_id?/1` (blocks quote/newline injection into printed Elixir snippet); `KeySet.new/1` for resolved values |
| V6 Cryptography | yes | `:crypto.strong_rand_bytes(32)` (CSPRNG); no hand-rolled crypto; no change to AEAD/seal code |
| V7 Error handling & logging | yes | messages name the variable, never values; no Logger in `gen.kek`; `KeySetInspect` unchanged |
| V14 Config | yes | fail-closed on missing env; runtime-only resolution; no compile-time embedding (a `compile_env` would bake the key into beam files) |

Threats:

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Silent fallback to unencrypted when env var unset | Tampering/Info disclosure | Raise from `Config.key_encryption!/0`; never `nil` for a configured block |
| Key leaked in shell history/CI logs via `gen.kek` | Info disclosure | Print once; `--raw` for piping; no echo elsewhere; docs say store in secret manager |
| Key baked into compiled artifact | Info disclosure | Runtime `System.fetch_env/1`; forbid `compile_env`/`put_env` |
| Snippet injection through `--id` | Tampering | Strict id regex before interpolation |
| Dev key copied to prod | Info disclosure | D-02: dev/test block never contains the generated key |

## Sources

### Primary (HIGH)
- Local source files read this session (paths cited inline).
- Elixir 1.19.5 Mix source: `lib/mix/lib/mix/cli.ex`, `tasks/loadconfig.ex`, `tasks/app.config.ex` under `/Users/jon/.asdf/installs/elixir/1.19.5-otp-28`.
- Fixture run (scratchpad) on 1.19.5-otp-28.
- `.planning/research/v1.44-adopter-polish/ARCHITECTURE.md` (Items 2-3, lines 91-127, 257-258).

### Tertiary (LOW)
- Training knowledge on `inspect(structs: false)` (A4).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - stdlib only.
- Architecture: HIGH - single resolution point verified by grep and reading.
- Pitfalls: MEDIUM-HIGH - A1-A4 flagged.

**Research date:** 2026-10-19
**Valid until:** 2026-11-19
