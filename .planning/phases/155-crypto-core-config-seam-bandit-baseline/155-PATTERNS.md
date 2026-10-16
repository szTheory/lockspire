# Phase 155: Crypto Core, Config Seam & Bandit Baseline - Pattern Map

**Mapped:** 2026-10-15
**Files analyzed:** 27 (new + modified)
**Analogs found:** 22 / 27 (5 are pure-new patterns; see No Analog Found)

All analog paths verified git-tracked (spot-checked `git ls-files`; all under `lib/`, `test/`, `scripts/`, `examples/`).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `examples/adoption_demo/mix.exs` (+lock) | config | n/a | itself (line 33 `{:bandit, "~> 1.11"}`) | exact |
| `test/clean_room/{provider_host,confidential_client}/mix.exs` (+locks) | config | n/a | themselves (line 22 `== 1.12.5`) | exact |
| `compatibility/phoenix_1_8_live_view_1_1/mix.lock` | config | n/a | itself (unlock only, D-17) | exact |
| `lib/lockspire/security/key_encryption.ex` (new) | utility (pure cipher) | transform | `lib/lockspire/protocol/private_jwk.ex` (decode style) + RESEARCH seal/open skeleton | partial |
| `lib/lockspire/security/key_encryption/key_set.ex` (new) | model (struct + redacting Inspect) | transform | `lib/lockspire/domain/signing_key.ex` (defstruct) | role-match |
| `lib/lockspire/config.ex` (mod: `key_encryption!/0`, cached accessor) | config | request-response | `Config.mount_path/0` / `logout_path/0` (config.ex:60-100) | role-match |
| `lib/lockspire/application.ex` (mod) | provider (boot) | event-driven | itself (lines 9-19) | exact |
| `lib/lockspire/protocol/private_jwk.ex` (mod: map clause) | utility | transform | itself (lines 1-24) | exact |
| 5 signers: `id_token.ex:36`, `logout_token.ex:35`, `jarm.ex:55`, `introspection_jwt.ex:36`, `token_exchange/internal/access_token_signer.ex:208` (mod) | service | request-response | `id_token.ex` | exact |
| `lib/lockspire/protocol/jar.ex:43` (mod) | service | request-response | itself | exact |
| `lib/lockspire/admin/keys.ex` `generate_key/1` (mod) | service | CRUD | itself (lines 37-79) | exact |
| `lib/lockspire/domain/signing_key.ex`, `storage/ecto/signing_key_record.ex` (mod: `@derive Inspect`) | model | n/a | none in lib/ | no analog |
| `lib/lockspire/install/verify.ex` (mod: `:key_encryption` check) | service | request-response | `config_checks/0` (verify.ex:48-76) | exact |
| `lib/mix/tasks/lockspire.doctor.key_encryption.ex` (new) | mix task | request-response | `lib/mix/tasks/lockspire.doctor.token_format.ex` | exact |
| `lib/mix/tasks/lockspire.doctor.ex` (mod: dispatcher+help) | mix task | request-response | itself (lines 10-27) | exact |
| `config/test.exs` (mod) | config | n/a | itself (lines 29-34) | exact |
| `scripts/acceptance/clean_room/build_provider.py` (mod, lines 63-72) | config | file-I/O | itself | exact |
| `test/support/seeding_helpers.ex:27`, `test/support/token_exchange_case.ex:290` (mod: seal) | test helper | CRUD | themselves | exact |
| `test/support/key_encryption_helpers.ex` (new) | test helper | n/a | `test/support/seeding_helpers.ex` | role-match |
| `test/lockspire/protocol/private_jwk_test.exs`, `audit/audit_writer_test.exs:449` (rewrite) | test | n/a | themselves | exact |
| `test/lockspire/security/key_encryption_test.exs` (new, first StreamData use) | test | transform | `private_jwk_test.exs` (async unit style) | partial |
| `test/lockspire/config_key_encryption_test.exs`, `application_key_encryption_test.exs` (new) | test | n/a | `test/lockspire/install/verify_test.exs` (env capture/restore) | role-match |
| `test/mix/tasks/lockspire_doctor_key_encryption_test.exs` (new) | test | n/a | `test/mix/tasks/lockspire_doctor_token_format_test.exs` | exact |
| `test/lockspire/domain/signing_key_inspect_test.exs` (new) | test | n/a | none | no analog |
| `test/lockspire/install/verify_test.exs` (mod: id list line 258, restore list ~185-196) | test | n/a | itself | exact |

## Pattern Assignments

### Bandit bump (155-01, standalone, lands first)

Edit lines: demo `mix.exs:33` `{:bandit, "~> 1.11"}` -> `{:bandit, "== 1.13.1"}`; provider/confidential `mix.exs:22` `{:bandit, "== 1.12.5"}` -> `"== 1.13.1"`. Per host: `mix deps.update bandit thousand_island hpax mint`. Compat fixture: `mix deps.unlock bandit thousand_island` only (D-17). Verify per host: `mix deps.get --check-locked && mix compile --warnings-as-errors && mix hex.audit`. No hex option keys change (`adapter: Bandit.PhoenixAdapter, http: [ip:, port:]`).

---

### `lib/lockspire/protocol/private_jwk.ex` (utility, transform)

**Analog:** itself, lines 1-24. Keep rescue/catch shape and the legacy parsers; replace the binary clause with the map clause.

```elixir
def decode(binary) when is_binary(binary) do
  case Jason.decode(binary) do
    {:ok, %{} = jwk} -> {:ok, jwk}
    _other -> decode_safe_term(binary)
  end
rescue
  _exception -> {:error, :invalid_signing_key}
catch
  _kind, _reason -> {:error, :invalid_signing_key}
end
def decode(_value), do: {:error, :invalid_signing_key}

defp decode_safe_term(binary) do
  case Plug.Crypto.non_executable_binary_to_term(binary, [:safe]) do
    %{} = jwk -> {:ok, jwk}
    _other -> {:error, :invalid_signing_key}
  end
end
```
Target: `def decode(%{kid: kid, private_jwk_encrypted: bin}) when is_binary(kid) and is_binary(bin)` -> `KeyEncryption.classify/1`; `:envelope` -> open + `Jason.decode` + kid equality; `:legacy` -> the two existing parsers moved to private `decode_legacy/1`. Keep `def decode(_), do: {:error, :invalid_signing_key}` and the broad rescue/catch. Keep the `@spec`.

### Six consumers (service, request-response)

**Analog:** `lib/lockspire/protocol/id_token.ex:28-60`. Head currently destructures `signing_key: %{kid:, alg:, private_jwk_encrypted: private_jwk}`; change to bind the whole map and pass it:
```elixir
{:ok, jwk_map} <- PrivateJwk.decode(private_jwk),     # today
{:ok, jwk_map} <- PrivateJwk.decode(signing_key),     # target (signing_key: %{kid: kid} = signing_key)
```
Same change at logout_token.ex:35, jarm.ex:55 (whole `signing_key` already in scope), introspection_jwt.ex:36, access_token_signer.ex:206-208 (head pattern `{:ok, %{kid:, alg:, private_jwk_encrypted:}}` -> bind whole map). Keep `else {:error, reason} -> {:error, reason}`; signer's `Logger.error(inspect(reason))` must stay atom-only.

**JAR** `lib/lockspire/protocol/jar.ex:38-55` — keep reduce_while + try/rescue/catch collapse to `:decryption_failed`; change only the decode argument:
```elixir
with {:ok, jwk_map} <- PrivateJwk.decode(key.private_jwk_encrypted),   # -> PrivateJwk.decode(key)
     jwk <- JOSE.JWK.from_map(jwk_map),
     {plain_text, %JOSE.JWE{}} <- JOSE.JWK.block_decrypt(jwt, jwk) do
  {:halt, {:ok, plain_text}}
else
  _ -> {:cont, {:error, :decryption_failed}}
end
```

### `lib/lockspire/admin/keys.ex` `generate_key/1` (service, CRUD)

**Analog:** itself, lines 37-79 (file line numbers 37-79 of the file; excerpt):
```elixir
def generate_key(use \\ :sig) do
  with {:ok, server_policy} <- Repository.get_server_policy() do
    {jwk, kty, alg} = signing_key_defaults(server_policy.security_profile, use)
    ...
    kid = Base.encode16(:crypto.strong_rand_bytes(8))
    private_jwk_map = Map.put(private_jwk_map, "kid", kid)
    key = %SigningKey{ ..., private_jwk_encrypted: Jason.encode!(private_jwk_map), status: :upcoming, ...}
    with {:ok, published_key} <-
           transact_with_audit(fn -> Repository.publish_key(key) end,
             fn %SigningKey{} = k -> key_audit_event(:key_generated, k, actor_from_attrs(%{}), %{use: use}) end) do
      emit(:key, :generated, published_key, actor_from_attrs(%{}))
      {:ok, to_view(published_key)}
    end
```
Target: resolve `Config.key_encryption_keyset/0` first (nil -> `{:error, :key_encryption_not_configured}` before any DB write, ideally before generating the JWK); replace the `Jason.encode!` line with `{:ok, sealed} = KeyEncryption.seal(keyset, kid, Jason.encode!(private_jwk_map))` (use a `with` clause, non-matching).

### `lib/lockspire/security/key_encryption.ex` + `key_set.ex` (new)

No close codebase analog; use RESEARCH.md "Seal / open skeleton" (lines 314-343) and "Pattern 1" parse (lines 204-224) verbatim: exact `binary-size(12)`/`binary-size(16)` parse, `try/rescue` around `:crypto.crypto_one_time_aead`, AAD `"lockspire.signing_key.v1" <> <<0>> <> header <> <<0>> <> kid`, fresh `:crypto.strong_rand_bytes(12)`. Struct style from `lib/lockspire/domain/signing_key.ex` (`@type t`, `defstruct`). KeyEncryption must NOT alias `Lockspire.Config` (topology cycle check, `scripts/ci/check_architecture_topology.sh`). KeySet gets a hand-written `defimpl Inspect` that omits key bytes.

### `lib/lockspire/config.ex` (config, request-response)

**Analog:** `mount_path/0`, `logout_path/0` (config.ex ~60-100) and `fetch_required!/1` (~238):
```elixir
case Application.get_env(@app, :logout_path) do
  value when is_binary(value) and value != "" -> value
  _missing -> raise ArgumentError, "missing required config :logout_path for :lockspire. " <> "Set it in config/runtime.exs or config/*.exs."
end
```
Copy the message style (key name only) but build errors via a `fail!(config_key, reason_atom)` helper; validators return `{:ok,_}|{:error,_}`, non-bang `Base.decode64/2`. Do NOT touch `secret_key_base/0` (config.ex:85). Add `key_encryption!/0` (fresh; nil when absent) and `key_encryption_keyset/0` (`:persistent_term.get({Lockspire, :key_encryption}, :miss)`, fresh fallback without caching).

### `lib/lockspire/application.ex` (provider, event-driven)

**Analog:** itself:
```elixir
def start(_type, _args) do
  Lockspire.DiscoveryRoutes.install_default_capability()
  children = [ {Lockspire.Oban, Lockspire.Oban.runtime_config!()}, Cachex.child_spec(name: :lockspire_jwks_cache), {Lockspire.KeyCache, ...} ]
  Supervisor.start_link(children, strategy: :one_for_one, name: Lockspire.Supervisor)
end
```
Target: before `children`, call a public testable `validate_key_encryption!/0` (raise on invalid; `Logger.warning` naming the `:key_encryption` setting when nil; else `:persistent_term.put`). `Oban.runtime_config!()` in the same function is the precedent for raising at boot.

### `lib/lockspire/install/verify.ex` (service, request-response)

**Analog:** itself `config_checks/0` + `config_check/3` (lines ~48-76):
```elixir
config_check(:oban, "oban", &Lockspire.Oban.runtime_config!/0)
...
defp config_check(id, key, fetch) do
  case safely(fetch) do
    {:ok, value} -> Check.ok(id, "Runtime config :#{key} is present", config_details(id, value), "...")
    {:error, message} -> Check.error(id, "Runtime config :#{key} is missing or invalid", message, "Add a valid :#{key} entry ...")
  end
end
defp config_details(:oban, oban), do: "oban_repo=#{inspect(Keyword.get(oban, :repo))}"
```
Add `config_check(:key_encryption, "key_encryption", &key_encryption_value/0)` where the fetch raises an `ArgumentError` naming `:key_encryption` when `Config.key_encryption!/0` returns nil (so missing -> `:error`), and a `config_details(:key_encryption, ks)` clause emitting key ids/count only (no `inspect` of config). The existing `issuer_value/0` (verify.ex:42-50) is the precedent for a local raising fetch. Update `verify_test.exs` id list (line 258) and the restore list (~185-196).

### `lib/mix/tasks/lockspire.doctor.key_encryption.ex` (new) + dispatcher

**Analog:** `lib/mix/tasks/lockspire.doctor.token_format.ex` (1-50): `use Mix.Task`, `@shortdoc`, `@requirements ["app.config"]`, `OptionParser.parse(args, strict: @switches)`, `--help` -> `Mix.shell().info(help())`, otherwise `report()`; read-only, never exits non-zero on absent. Dispatcher clause in `lockspire.doctor.ex`:
```elixir
def run(["token_format" | rest]) do
  Mix.Task.run("lockspire.doctor.token_format", rest)
end
```
Add `run(["key_encryption" | rest])` and a help line `mix lockspire.doctor key_encryption`. Report must call `Config.key_encryption!/0` (fresh), rescue the name-only `ArgumentError` for display, print key ids only. Test analog: `test/mix/tasks/lockspire_doctor_token_format_test.exs` (`Mix.Task.reenable("lockspire.doctor")` + `...key_encryption`, `capture_io`, `async: false`; DB setup not needed here).

### `@derive {Inspect, except: [:private_jwk_encrypted]}` (model)

No analog (none in lib/). Add directly above `defstruct` in `lib/lockspire/domain/signing_key.ex`, and above `schema ...` in `lib/lockspire/storage/ecto/signing_key_record.ex` (place after `use Ecto.Schema`; `@derive` must precede the schema macro).

### Test config and hosts

`config/test.exs` after the `config :lockspire, ... logout_path: "/sign-out"` block (lines 29-34): add `config :lockspire, :key_encryption, keys: [{"test-1", kek("lockspire-test-kek-1")}, {"test-2", ...}], current: "test-1", legacy_plaintext: :allow` with `:crypto.hash(:sha256, "...") |> Base.encode64()` (RESEARCH line 386).

`scripts/acceptance/clean_room/build_provider.py:63-72`: inside the `config :lockspire,` literal, add a `key_encryption: [keys: [{\"clean-room-1\", \"<fixed base64 32 distinct bytes>\"}], current: \"clean-room-1\", legacy_plaintext: :allow],` entry; the file uses `\"` escapes. Land with/before the `generate_key` refusal (D-11). Consider extending `check_bootstrap()` (~line 351) to assert `:key_encryption` in the literal.

### Test helpers sealing (test helper, CRUD)

**Analog:** `test/support/seeding_helpers.ex:27` and `token_exchange_case.ex:290`:
```elixir
private_jwk_encrypted: Jason.encode!(Map.put(jwk, "kid", kid)),          # seeding_helpers
private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)), # token_exchange_case
```
Replace with `KeyEncryptionHelpers.seal_private_jwk(kid, Map.put(jwk, "kid", kid))`. Also `token_exchange_case.ex ~300` `assert_active_signing_key_fixture`: `PrivateJwk.decode(active_key.private_jwk_encrypted)` -> `PrivateJwk.decode(active_key)`.

### Tests

- `private_jwk_test.exs` (async unit): keep the "never raises" `for value <- [...]` matrix, now with `%{}`, `nil`, `42`, bare binaries (binary clause gone -> all `{:error, :invalid_signing_key}`); positive cases pass `%{kid: "k", private_jwk_encrypted: ~s({"kty":"RSA","kid":"k"})}` and `:erlang.term_to_binary(...)`.
- New cipher test: `use ExUnit.Case, async: true` + `use ExUnitProperties` (first use in repo); cases per RESEARCH Validation map (tamper ct/tag, row swap, forged kid JSON, unknown KEK, cut inside tag -> `:malformed_envelope`, 31-byte forged key returns error).
- Config/boot tests: `async: false`, `Application.put_env` + restore in `on_exit`; sentinel `"SENTINEL-KEK-VALUE"` asserted absent from `Exception.message/1` and `Exception.format(:error, e, st)`.

## Shared Patterns

### Name-only errors (D-06/D-20)
**Source:** `lib/lockspire/security/policy.ex:68-79` (`fetch_required_config!` raises `ArgumentError` with a literal `:#{key}` message, never the value).
**Apply to:** `Config.key_encryption!/0`, `Application.validate_key_encryption!/0`, `Install.Verify`, doctor. Never `inspect/1` config, never `{:ok,_} = ...`, never `Keyword.fetch!`.

### Fail-closed decode with broad rescue
**Source:** `private_jwk.ex:10-14` (`rescue _exception` + `catch _kind, _reason`).
**Apply to:** `PrivateJwk.decode/1`, `KeyEncryption.open/3` (rescue `ErlangError`/anything -> tagged error).

### Per-consumer external error shape (D-02)
**Source:** `id_token.ex` `else {:error, reason} -> {:error, reason}`; `jar.ex` collapse to `:decryption_failed`.
**Apply to:** all six sites; internal reasons collapse to `:invalid_signing_key` inside `PrivateJwk`.

### Read-only diagnostics under `@requirements ["app.config"]`
**Source:** `lockspire.doctor.token_format.ex:18`.
**Apply to:** doctor task and Verify: must call fresh `Config.key_encryption!/0`, never `:persistent_term`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/lockspire/security/key_encryption.ex` | utility | transform | No AEAD code in repo; use RESEARCH prototype skeleton |
| `.../key_encryption/key_set.ex` Inspect impl | model | transform | No custom `Inspect` impls in lib/ |
| `@derive Inspect` on SigningKey/Record | model | n/a | None exist in lib/ |
| `:persistent_term` cache in Application | provider | event-driven | None in lib/ (new pattern) |
| `ExUnitProperties` property test | test | transform | StreamData is a test dep but unused so far |

## Metadata

**Analog search scope:** `lib/lockspire/{protocol,admin,install,security,domain,storage}`, `lib/mix/tasks`, `test/support`, `test/mix/tasks`, `config/`, `scripts/acceptance/clean_room`
**Pattern extraction date:** 2026-10-15
