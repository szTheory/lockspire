# Phase 157: Host Surfaces, Redaction Sweep & Release Proof - Pattern Map

**Mapped:** 2026-10-16
**Files analyzed:** 32 (6 new, 26 modified)
**Analogs found:** 31 / 32 (all analog paths verified git-tracked; no mirror paths)

CONTEXT D-xx and RESEARCH F-numbers are not repeated. This file points the planner at concrete excerpts. Reuse `.planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-PATTERNS.md` for: the Mix task skeleton, `Ecto.Migrator.with_repo` lifecycle, `Support` `sensitive: true` semantics, hot-path telemetry (`:telemetry.execute` direct, not `Observability.emit`), Keys audit/emit helpers, and the fitness-test constraints. Those are not re-excerpted below.

Reminder carried from 156: `ReadabilityContractTest` forbids planning markers (`Phase N`, `D-NN`, `WR-NN`) in `lib/**` text including `@moduledoc`, comments and Mix task help. Plain-English comments only in `lib/`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/storage/ecto/repository/signing_key_store.ex` (add `sensitive: true` to 9 paths) | store | CRUD | same file `sensitive_locked_key/2` (245-250), `replace_material/5` (219-231) | exact |
| `lib/lockspire/storage/ecto/signing_key_record.ex` (`redact: true`, `put_change`) | schema | CRUD | same file; Ecto `redact:` per RESEARCH F2 | exact |
| `lib/lockspire/redaction.ex` (9 drop keys x 2 sets x 2 forms, LSK value guard) | utility | transform | same file `sanitize_value/2` clauses (195-224) | exact |
| `lib/lockspire/protocol/private_jwk.ex` (+`to_jwk/1`) | utility | transform | same file `read_row/2` rescue/catch (125-136) | exact |
| `lib/lockspire/protocol/id_token.ex` | service | request-response | the helper's own call site (36-50) | exact |
| `lib/lockspire/protocol/logout_token.ex` | service | request-response | `id_token.ex` | exact |
| `lib/lockspire/protocol/jarm.ex` | service | request-response | `id_token.ex` | exact |
| `lib/lockspire/protocol/introspection_jwt.ex` | service | request-response | `id_token.ex` (plus its own `sign_compact_jwt` rescue, 98-106) | exact |
| `lib/lockspire/protocol/jar.ex` (`decrypt/2`) | service | request-response | same file try/with/rescue (42-56) | exact |
| `lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex` | service | request-response | same file `sign_jwt/2` (204-225) | exact |
| `lib/lockspire/generators/install.ex` (`instructions/1` step 9) | generator | transform (print) | same file `instructions/1` (124-137) | exact |
| `lib/lockspire/config.ex` (`fail_key_encryption!/2` text) | config | validation | same function (283-289) | exact |
| `test/support/key_material_matcher.ex` (new) | test support | transform | `test/support/telemetry_capture.ex` (shape); matcher logic from RESEARCH F4 | partial |
| `test/lockspire/security/key_material_leak_test.exs` (extend) | test | event-driven | itself (whole file read) | exact |
| `test/lockspire/redaction/redaction_test.exs` (extend) | test | transform | itself (1-40) | exact |
| `test/lockspire/protocol/private_jwk_test.exs` (extend, `to_jwk/1`) | test | transform | itself + `envelope_signing_consumers_test.exs` | exact |
| `test/lockspire/protocol/envelope_signing_consumers_test.exs` (extend, malformed OKP) | test | request-response | itself | exact |
| `test/lockspire/workers/backchannel_logout_delivery_worker_test.exs` (extend) | test | event-driven | itself (`perform/1` describe, 60-110) | exact |
| `test/lockspire/storage/ecto/signing_key_record_test.exs` (new, changeset inspect) | test | CRUD | `key_material_leak_test.exs` setup shape | role-match |
| `test/integration/install_generator_test.exs` (extend) | test | request-response | itself (292-297) | exact |
| `test/lockspire/config_key_encryption_test.exs`, `test/lockspire/install/verify_test.exs` (substring check) | test | n/a | themselves | exact |
| `examples/adoption_demo/config/config.exs` | config | n/a | same file `SECRET_KEY_BASE` fallback (60-80) | exact |
| `examples/adoption_demo/priv/repo/seeds.exs` | seed | CRUD | `test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex:4-7` | exact |
| `examples/adoption_demo/docker-compose.yml` | config | n/a | same file `web.environment` (19-29) | exact |
| `docs/oauth-oidc-for-phoenix-adopters.md:332` (kid prose) | docs | n/a | n/a | n/a |
| `.github/workflows/ci.yml` (`adoption-demo` job, +2 steps) | CI | batch | same job "Prepare adoption demo database" step (~467-470) | exact |
| `scripts/acceptance/clean_room/build_provider.py` | harness | transform | same file `write_host_runtime` / `check_bootstrap` | exact |
| `scripts/acceptance/clean_room_saas_journey.py` | harness | batch | same file `main()` (865, 917-918) + `register_secret` (63) | exact |
| `test/integration/signing_key_upgrade_journey_test.exs` (new) | test | batch / CLI | `Mix.Tasks.Lockspire.Keys.ReencryptE2ETest` in `test/mix/tasks/lockspire_keys_reencrypt_test.exs` (70-130) | exact |
| `test/support/` six-consumer drivers (new, extracted) | test support | request-response | `test/lockspire/protocol/envelope_signing_consumers_test.exs` | role-match |
| `docs/upgrading/signing-key-encryption.md` (new) | docs | n/a | `docs/upgrading/storage-prefix.md` | role-match |
| `mix.exs` (extras + `groups_for_extras`), `docs/architecture.md`, `docs/code-walkthrough.md`, `docs/telemetry.md`, `SECURITY.md`, `docs/install-and-onboard.md` | docs/config | n/a | themselves | exact |
| `157-RELEASE-NOTES.md` (new, phase dir) | docs | n/a | none in repo (v1.42 squash `1cfafd03` body for shape) | none |

## Pattern Assignments

### `lib/lockspire/storage/ecto/repository/signing_key_store.ex` (store, CRUD) - 157-01

**Analog:** same file. The switch is `Support` option `sensitive: true` (`support.ex:32-49`: `Keyword.drop([:sensitive])` then `log: false`, `telemetry_event: nil`). Existing in-repo usage to copy verbatim:

```elixir
# signing_key_store.ex:245-250
defp sensitive_locked_key(repo, id),
  do:
    SigningKeyRecord
    |> where([key], key.id == ^id)
    |> lock("FOR UPDATE")
    |> then(&Support.one(repo, &1, sensitive: true))

# signing_key_store.ex:35-41 (the only existing opt-driven default; flip false -> true)
|> then(&Support.all(repo, &1, sensitive: Keyword.get(opts, :sensitive, false)))
```

Apply per call site (current lines):

| Function | Current line | Change |
|---|---|---|
| `publish_key` insert | 16-19 | add `sensitive: true` alongside `on_conflict:`/`conflict_target:` (opts are forwarded; `:sensitive` dropped before repo call) |
| `list_signing_keys` | 39 | `Keyword.get(opts, :sensitive, true)` |
| `fetch_active_signing_key` | 94 | `Support.all(repo, &1, sensitive: true)` |
| `fetch_signing_key_by_id` | 107 | `Support.one(repo, &1, sensitive: true)` |
| `list_decryption_keys` | 67 | `Support.all(repo, &1, sensitive: true)` |
| `locked_key` | 273 | `Support.one(repo, &1, sensitive: true)` (or reuse `sensitive_locked_key`) |
| `active_keys_for_update` | 280 | `Support.all(repo, &1, sensitive: true)` |
| `list_active_keys` (JWKS hot path) | 28 | per D-18: add `select` that omits `private_jwk_encrypted` instead of `sensitive`, keeping Ecto logs |
| `list_publishable_keys` (JWKS hot path) | 54 | same as above |

For D-18 `select`, the style analog in the same file is `list_signing_key_refs` (176-181): `|> select([key], {key.id, key.kid})`. A column-omitting select needs a struct-preserving form, e.g. `select([key], %{key | private_jwk_encrypted: nil})` (Ecto struct-update select) so `SigningKeyRecord.to_domain/1` and the existing `strip_private_key_material/1` (331-332) keep working. Planner: verify with the sweep test that `result`/`params` of the `[:repo, :query]` event no longer carry the column; fall back to `sensitive: true` if a caller needs it (D-18). `list_signing_key_refs` is already clean.

Constraint: all access to the key table stays inside this file (`repository.ex` may not hold Ecto constructs, 156-PATTERNS fitness note).

---

### `lib/lockspire/storage/ecto/signing_key_record.ex` (schema, CRUD) - 157-01

**Analog:** same file (read in full). Current leak and fix:

```elixir
# signing_key_record.ex:12-19 (current)
@derive {Inspect, except: [:private_jwk_encrypted]}
schema "lockspire_signing_keys" do
  ...
  field(:private_jwk_encrypted, :binary)

# signing_key_record.ex:31-50 (current changeset/2): cast list includes :private_jwk_encrypted (line 39)
```

Target (RESEARCH F2, verified compile-clean): keep the derive, add `redact: true` to the field, drop `:private_jwk_encrypted` from the `cast` list, then pipe `|> put_change(:private_jwk_encrypted, key.private_jwk_encrypted)` after `cast`. `put_change` is already available via `import Ecto.Changeset` (line 6). Keep `update_changeset/2` (52-62) unchanged: it casts no key column. Note `validate_required`/`unique_constraint(:kid)` stay after.

Proof test (D-19): call `SigningKeyRecord.changeset(%SigningKeyRecord{}, %SigningKey{kid: nil, private_jwk_encrypted: sentinel})` (a `validate_required` failure); `refute inspect(cs) =~ sentinel`, `refute inspect(cs.params) =~ sentinel`. Do NOT drive via `generate_key/1` (it upserts on a random kid, `unique_constraint` unreachable).

---

### `lib/lockspire/redaction.ex` (utility, transform) - 157-01

**Analog:** same file. The two drop sets are `MapSet.new([...])` literals listing atoms then strings in the same order (`@telemetry_drop_keys` 8-83, `@audit_drop_keys` 85-160); both are maintained as full duplicates, so add the 9 names to BOTH, atom block and string block each:

```elixir
:private_jwk_encrypted, :private_jwk, :private_key, :jwk, :kek,
:key_encryption, :key_encryption_key, :envelope, :ciphertext,
"private_jwk_encrypted", "private_jwk", "private_key", "jwk", "kek",
"key_encryption", "key_encryption_key", "envelope", "ciphertext",
```

Never add `kid`, `kek_id`, `previous_kek_id`, `key_id` (156 operator contract; `private_jwk.ex:72,88` emit `kid`, `reason`, `kek_id`).

Value-level guard goes before the catch-all `defp sanitize_value(value, _surface), do: value` (line 224) and before the struct clause (201) is irrelevant because binaries do not match it:

```elixir
# existing clauses to slot beside (redaction.ex:195-203, 224)
defp sanitize_value(nil, _surface), do: :drop
defp sanitize_value(%DateTime{} = value, _surface), do: value
defp sanitize_value(%_{} = value, _surface) do
  inspect(value)
end
...
defp sanitize_value(value, _surface), do: value
```
Add: `defp sanitize_value(<<"LSK", 1, _rest::binary>>, _surface), do: :drop`.

Caveat for planner: the struct clause returns `inspect(value)`, which for a struct holding an envelope would re-render bytes as `<<76, 83, 75, 1, ...>>`; consider whether the matcher sweep needs a byte-list guard there too (D-20).

Test analog: `test/lockspire/redaction/redaction_test.exs:6-60`, a single map with `refute Map.has_key?(redacted, :key)` per dropped key plus `assert redacted.client_id == ...` for kept keys. Add one `test` that passes atom and string forms, asserts all 9 dropped on both `for_telemetry/1` and `for_audit/1`, asserts `kid`, `kek_id`, `previous_kek_id`, `key_id` survive, and that a nested `%{"x" => <<"LSK", 1, 2>>}` value is dropped.

---

### `lib/lockspire/protocol/private_jwk.ex` (+ `to_jwk/1`) (utility, transform) - 157-01

**Analog:** `read_row/2` in the same file (125-138) already has the exact no-args rescue/catch shape:

```elixir
defp read_row(%{kid: kid, private_jwk_encrypted: bin}, keyset)
     when is_binary(kid) and is_binary(bin) do
  ...
rescue
  _exception -> {:error, :invalid_signing_key}
catch
  _kind, _reason -> {:error, :invalid_signing_key}
end
```

Add next to `decode/1` (line 39) the helper verified in RESEARCH F3 (never bind the exception, never reraise or log):

```elixir
@spec to_jwk(term()) :: {:ok, JOSE.JWK.t()} | {:error, :invalid_signing_key}
def to_jwk(%{} = map) do
  jwk = JOSE.JWK.from_map(map)
  _public = JOSE.JWK.to_public(jwk)
  {:ok, jwk}
rescue
  _ -> {:error, :invalid_signing_key}
catch
  _kind, _reason -> {:error, :invalid_signing_key}
end

def to_jwk(_other), do: {:error, :invalid_signing_key}
```
`to_public/1` is the structural probe (from_map alone returns a struct for malformed EC/RSA). Pitfall: `keys: :undefined` is normal for valid keys, do not use it as a validity check.

---

### The six signing consumers (service, request-response) - 157-01

**Analog:** each file's existing `with` chain; the change is the same one-line swap in each. Existing shape (`id_token.ex:36-56`):

```elixir
with :ok <- ensure_allowed_alg(alg, allowed_algs),
     ...
     {:ok, jwk_map} <- PrivateJwk.decode(signing_key),
     claims <- build_claims(...),
     {_, compact} <-
       JOSE.JWT.sign(
         JOSE.JWK.from_map(jwk_map),
         %{"alg" => alg, "kid" => kid, "typ" => "JWT"},
         claims
       )
       |> JOSE.JWS.compact() do
  {:ok, compact}
else
  {:error, reason} -> {:error, reason}
end
```
Swap: insert `{:ok, jwk} <- PrivateJwk.to_jwk(jwk_map),` after the `decode` clause and pass `jwk` to `JOSE.JWT.sign`. The existing `else {:error, reason} -> {:error, reason}` already forwards `:invalid_signing_key`, so the response contract is unchanged.

| File | `from_map` site to replace | Notes |
|---|---|---|
| `lib/lockspire/protocol/id_token.ex` | 50 | as above |
| `lib/lockspire/protocol/logout_token.ex` | 39 | `with` 34-47; worker maps `{:error, :invalid_signing_key}` to discard (`backchannel_logout_delivery_worker.ex:43-80`) |
| `lib/lockspire/protocol/jarm.ex` | 60 | `JOSE.JWT.sign(JOSE.JWK.from_map(jwk_map), protected_header, claims)` becomes `jwk` after a new `{:ok, jwk} <- PrivateJwk.to_jwk(jwk_map)` |
| `lib/lockspire/protocol/introspection_jwt.ex` | 100 (`sign_compact_jwt/3`) | add `{:ok, jwk} <- PrivateJwk.to_jwk(jwk_map)` in the `with` at 36; change `sign_compact_jwt(jwk, ...)`; keep its `rescue ErlangError -> {:error, :unsupported_signing_algorithm}` (98-106) untouched (unchanged behaviour for alg/key mismatch) |
| `lib/lockspire/protocol/jar.ex` | 44 (`decrypt/2`) | `with {:ok, jwk_map} <- PrivateJwk.decode(key), jwk <- JOSE.JWK.from_map(jwk_map), ...` becomes `{:ok, jwk} <- PrivateJwk.to_jwk(jwk_map)`; the existing `rescue _`/`catch _, _` (49-54) stays. Do NOT touch `jar.ex:148` (client public JWKS, not a stored private key) |
| `lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex` | 211 (`sign_jwt/2`, 204-225) | `with` at 205 already has `else {:error, reason}` mapping to a 500 `server_error` `%Error{}`; add `{:ok, jwk} <- PrivateJwk.to_jwk(jwk_map)` before the `{_, compact} = JOSE.JWT.sign(...)` body. Note: the `Logger.error("Failed to sign access token: #{inspect(reason)}")` logs a reason atom only; `:invalid_signing_key` is safe |

Existing tests: `test/lockspire/protocol/envelope_signing_consumers_test.exs` (driver shapes: `id_token_params/1` at ~76-90, `sealed_key(keys, kid)` helper, "legacy JSON row still signs" at ~104). Extend each describe with a sealed OKP wrong-length-`d` row expecting `{:error, :invalid_signing_key}` (or the access-token signer `server_error`) and no raise.

---

### `lib/lockspire/generators/install.ex` (generator, print) - 157-02

**Analog:** `instructions/1` (124-137). Append step 9; keep 1-8 verbatim (tests assert substrings: `install_generator_test.exs:292-297`). Style: heredoc with `#{assigns.*}` interpolation, two-space-indented numbered steps. The generator prints; it never edits host files (`run/1` line 18 `Mix.shell().info(instructions(assigns))`).

```elixir
defp instructions(assigns) do
  """

  Lockspire canonical onboarding next steps:
    1. Import `config/lockspire.exs` from your main config files.
    ...
    8. If you explicitly operate a FAPI 2.0 security profile, ...
  """
end
```
Compute `kek_id = Calendar.strftime(Date.utc_today(), "%Y-%m")` and `dev_literal = Base.encode64(:crypto.strong_rand_bytes(32))` inside `instructions/1` (print-time, not in a template, so nothing enters `.lockspire/install_manifest.json` and reruns stay idempotent). Print the prod `config/runtime.exs` block from CONTEXT D-07 and a dev/test block for `config/dev.exs`/`config/test.exs` (compile-time files, like Phoenix `secret_key_base`), with `# dev/test only - never reuse in prod` and a one-line comment about `:allow` for upgraders pointing at `docs/upgrading/signing-key-encryption.md`. KEK id must match `~r/\A[A-Za-z0-9._-]{1,32}\z/` (`key_set.ex:48`).

Test analog: `install_generator_test.exs` asserts `output =~ "..."` against `capture_io` output (lines ~292-297, rerun ~609). Add: `output =~ "LOCKSPIRE_KEY_ENCRYPTION_KEY"`, `output =~ "legacy_plaintext: :reject"`, `output =~ ~r/\d{4}-\d{2}/`, and two `capture_io` runs yielding different 44-char base64 literals (regex `~r/[A-Za-z0-9+\/]{43}=/`). Test module is `use Lockspire.DataCase, async: false` with `import ExUnit.CaptureIO`.

---

### `lib/lockspire/config.ex` (config, validation) - 157-02

**Analog:** `fail_key_encryption!/2` (283-289):
```elixir
raise ArgumentError,
      "invalid config :key_encryption (#{inspect(config_key)}: #{reason}) for :lockspire. " <>
        "Each key must be base64 of 32 random bytes; generate one with " <>
        "`openssl rand -base64 32` and set it in config/runtime.exs."
```
Extend the string with `` or `elixir -e 'IO.puts(Base.encode64(:crypto.strong_rand_bytes(32)))'`; `mix phx.gen.secret` output is not 32 bytes. `` Keep the `` `openssl rand -base64 32` `` substring exactly: `test/lockspire/install/verify_test.exs:339` asserts it, and `application.ex:40`, `install/verify.ex:97`, `lockspire.keys.reencrypt.ex:147`, `lockspire.doctor.key_encryption.ex:81` repeat it.

---

### `examples/adoption_demo/config/config.exs` (config) - 157-02

**Analog:** same file, the `SECRET_KEY_BASE` literal-fallback idiom (60-80):
```elixir
secret_key_base:
  System.get_env("SECRET_KEY_BASE") ||
    "a3e20c7a13116f2415ef29e0714cc5901d0d0ed48390b78781625d0ef4dbfd328ed05f017f89cc3c0eb579d9fb3af16b",
```
Add to the `config :lockspire` block (88-100 region) `key_encryption: [keys: [{"demo-1", System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY", "<fixed base64 of 32 non-repeating bytes>")}], current: "demo-1", legacy_plaintext: :reject]` with a comment `# demo-only literal; never reuse`. The literal must pass the weak-material check (not a repeated-byte key). Also add a commented `LOCKSPIRE_KEY_ENCRYPTION_KEY: "..."` line, marked demo-only, under `web.environment` in `docker-compose.yml` (19-29, same quoting style `KEY: "${VAR:-default}"`).

### `examples/adoption_demo/priv/repo/seeds.exs` (seed, CRUD) - 157-02

**Analog:** `test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex:4-7` (public API only):
```elixir
{:ok, %{key: key}} = Lockspire.Admin.generate_key(:sig)
{:ok, _} = Lockspire.Admin.publish_key(key.id)
{:ok, _} = Lockspire.Admin.activate_key(key.id)
```
Delete the raw `Repository.publish_key(%SigningKey{kid: "adoption-demo-rs256", ... :erlang.term_to_binary(...)})` (about 78-98) and the `Enum.each([%SigningKey{kid: "adoption-demo-es256-upcoming", ... "x" => "demo-x"}...])` placeholder block (about 209-258). State-machine recipe (RESEARCH F8): K1 generate/publish/activate; K2 same (K1 becomes `:retiring`); `retire_key(K1.id)`; K3 generate/publish/activate (K2 retiring); K4 `generate_key(:sig)` only (upcoming). Server policy must exist first (it does, seeds create it ~line 60). `:sig` keys are ES256 (`keys.ex:333-334`); `docs/oauth-oidc-for-phoenix-adopters.md:332` names `adoption-demo-rs256` and must be reworded. `conformance_seeds.exs:68` is an ephemeral client key (`JOSE.JWK.generate_key({:rsa, 2048})`): nothing to change, record the audit.

### `.github/workflows/ci.yml` (`adoption-demo` job) - 157-02

**Analog:** the "Prepare adoption demo database" step pattern (ci.yml ~467-470):
```yaml
      - name: Prepare adoption demo database
        working-directory: examples/adoption_demo
        run: mix ecto.setup
```
Append two steps in this style (`working-directory: examples/adoption_demo`) after the smoke step: `mix lockspire.keys.reencrypt --check` and `mix lockspire.doctor key_encryption`.

### `scripts/acceptance/clean_room/build_provider.py` and `scripts/acceptance/clean_room_saas_journey.py` (harness) - 157-02

**Analog:** the files themselves. Literal to remove (`build_provider.py:74-78`, inside the `write_host_runtime` f-string/triple-quoted text, config.exs with `\"` escaped quotes):
```python
  key_encryption: [
    keys: [{\"clean-room-1\", \"j/nnbOESQTiY8IQZNzKyN8nhCngcI5f1GboKyJoePfQ=\"}],
    current: \"clean-room-1\",
    legacy_plaintext: :allow
  ]
```
Replace with `System.fetch_env!(\"LOCKSPIRE_KEY_ENCRYPTION_KEY\")`, an id such as `clean-room-1` is fine to keep as a KEK id (id is not secret) but the spec removes the literal key only; `legacy_plaintext: :reject`. Update `check_bootstrap` (`build_provider.py:~369`):
```python
host_runtime_source = inspect.getsource(write_host_runtime)
if "key_encryption:" not in host_runtime_source or "clean-room-1" not in host_runtime_source:
    raise PackageInputError("provider host config is missing the clean-room key_encryption KEK")
```
to assert `"LOCKSPIRE_KEY_ENCRYPTION_KEY" in source` and the base64 literal `j/nnbOES...` is absent. `test/integration/phase133_provider_install_test.exs:23` runs `python3 build_provider.py --check-bootstrap`.

Env propagation (RESEARCH F9): in `main()` right after `redactor = Redactor(SentinelSet.for_run())` (`clean_room_saas_journey.py:865`) do `kek = base64.b64encode(os.urandom(32)).decode()`, `os.environ["LOCKSPIRE_KEY_ENCRYPTION_KEY"] = kek`, `register_secret(kek)` (`register_secret` defined at line 63; `scan_evidence` at 367). Every child env derives from `os.environ.copy()` via `locked_environment` (`package_input.py:273-288`). Optionally `environment.setdefault(...)` in `prepare_provider`.

Add the two checks after `Bootstrap.provision!` (line 918) so an envelope exists, in the same call style as line 917:
```python
run_child_command(provider_child, provider_environment, "lockspire.verify")
run_child_command(provider_child, provider_environment, "run", "-e", f'CleanRoomProvider.Bootstrap.provision!("{handoff}")')
# add:
run_child_command(provider_child, provider_environment, "lockspire.keys.reencrypt", "--check")
run_child_command(provider_child, provider_environment, "lockspire.doctor", "key_encryption")
```

---

### `test/support/key_material_matcher.ex` (new) and `test/lockspire/security/key_material_leak_test.exs` (extend) - 157-01

**Analog:** the leak test (read in full). Reuse its scaffolding verbatim: `setup_all` starts `Lockspire.TestRepo` with `log: :debug` (lines 23-31), per-test `Sandbox.start_owner!(shared: true)` and `Logger.configure(level: :debug)` (33-45), `configure/2` over `Helpers.put_key_encryption(keys: [{"leak-1", @kek_one}, {"leak-2", @kek_two}], ...)` (47-53), `sentinel_row/2` (62-66, overwrites `"d"` with `@sentinel_d`), `sealed_sentinel_row/3` (68-72), `drain/1` over `{:telemetry_event, event, m, md}` (80-87), attach list including `repo_query = (TestRepo.config()[:telemetry_prefix] || []) ++ [:query]` (107, 114), vacuity guard (211-212):

```elixir
assert log =~ ~r/QUERY (OK|ERROR)/,
       "repo query logging is not active, so the leak check would be vacuous"
refute log =~ "private_jwk_encrypted", "key column queries reached the query log"
refute Enum.any?(repo_events, fn {_e, _m, md} ->
         String.contains?(to_string(md[:query]), "private_jwk_encrypted")
       end)
```
The current assertions `refute key_event_text =~ "LSK"` (207-208, 235) are vacuous for inspected bytes (`inspect` renders `<<76, 83, 75, 1, ...>>`); the new matcher module replaces them. Implement the matcher per RESEARCH F4: a `forbidden` list expanded to raw, `Base.encode64` (padded and unpadded), `Base.url_encode64` (padded and unpadded), lowercase hex, plus envelope markers `"LSK" <> <<1>>`, `"<<76, 83, 75, 1"`, `"TFNLAQ"`, `"4c534b01"`; `scan_text/2` and a structural `scan_term/2` that walks maps, structs, lists, tuples and `:binary.match`es every binary leaf; keep a "canary of the canary" test that a deliberately leaky term is flagged. Use `@moduletag`-free `ExUnit.Case, async: false`; one public entry (e.g. `KeyMaterialMatcher.refute_leak!(label, term_or_text)`) so CI cites one proof point. Place under `test/support/` (compiled via `elixirc_paths`, as `key_encryption_helpers.ex` and `telemetry_capture.ex` already are).

New sweep cases to add in the same file: every key store read path (`list_active_keys`, `list_publishable_keys`, `list_signing_keys`, `list_decryption_keys`, `fetch_active_signing_key`, `fetch_signing_key_by_id`, `publish_key`) asserting zero `[:repo, :query]` events touching the column; malformed sealed OKP key through each consumer; rescued exception text via `Exception.message/1` and `Exception.format/3`; Oban worker via `BackchannelLogoutDeliveryWorker.perform(%Oban.Job{args: %{"logout_delivery_id" => id}})` (perform shape from `backchannel_logout_delivery_worker_test.exs:~77-80`; expect `{:discard, :invalid_signing_key}`-style outcome, no raise, and run `Oban.Job.format_attempt/1` text through the matcher); KeysLive/OverviewLive rendered HTML and `socket.assigns` (pattern: `keys_live_test.exs:78` `rendered_to_string(Index.render(socket.assigns))` and `socket.assigns.keys`).

---

### `test/integration/signing_key_upgrade_journey_test.exs` (new, integration) - 157-03

**Analog:** `Mix.Tasks.Lockspire.Keys.ReencryptE2ETest` in `test/mix/tasks/lockspire_keys_reencrypt_test.exs` (70-130). Copy its shape exactly: `use ExUnit.Case, async: false`, `@moduletag :integration`, no sandbox owner, `refute Process.whereis(Lockspire.TestRepo)` at setup start, a foreign-key count guard with `where: not like(k.kid, "<prefix>-%")`, a random kid prefix per test, `on_exit(&cleanup/0)` (keys and their audit rows), `Mix.Task.reenable(@task)`. Seeding and reads go through `with_repo(fn -> ... end)` (Ecto.Migrator.with_repo). Task invocation: `run_task(["--check"])` returns `{output, :ok | {:error, _}}`, failures are `Mix.Error` (not exit codes). Assertions: `Keys.encryption_status()` per-KEK-id counts for "zero rows on k1"; `KeyEncryption.envelope_kek_id(row.private_jwk_encrypted)` returns `{:ok, "test-1"}`; byte checks `String.starts_with?(bin, "LSK" <> <<1>>)`, `refute String.contains?(bin, "\"d\"")`, `refute String.contains?(bin, Base.url_encode64(d_bytes, padding: false))`. Rotation via `Helpers.put_key_encryption(keys: [...], current: "k2", legacy_plaintext: :allow)` (updates env and the persistent_term cache); `Helpers.config_keys/1`, `legacy_json_row/2`, `legacy_etf_row/2`, `sealed_row/3` from `test/support/key_encryption_helpers.ex`. Test selection: file under `test/integration/` runs by path; the CI partition is `--only integration` (`run_test_matrix.sh:124-127`).

Six-consumer drivers: extract from `test/lockspire/protocol/envelope_signing_consumers_test.exs` into `test/support/` rather than copying (IdToken params ~76-90, LogoutToken ~140-160, Jarm via a `KeyStore` stub, IntrospectionJwt, `AccessTokenSigner.issue`, Jar via `jar_fixture`), but feed them the stored row from `Repository.fetch_signing_key_by_id/1` so the stored bytes sign. Keep the existing consumer test assertions unchanged (SAFE-01); extracting drivers into a support module must not alter that file's assertions.

---

### `docs/upgrading/signing-key-encryption.md` (new) and doc updates - 157-04

**Analog:** `docs/upgrading/storage-prefix.md`: H1 `# ... Upgrade Note`, short prose, fenced `elixir` block of exact config, bullet lists of "safe choices", no `.planning/` paths, no version-specific claim (D-21: say "the release that adds signing-key encryption" and link the CHANGELOG).

`mix.exs` registration (same commit, `documentation_contract_test.exs:11-51` enforces exactly-once across extras and groups): add `"docs/upgrading/signing-key-encryption.md"` after `"docs/upgrading/storage-prefix.md"` in BOTH lists:
```elixir
# mix.exs extras (~line 219-220)
"docs/upgrading/v1.27.md",
"docs/upgrading/storage-prefix.md",
# mix.exs groups_for_extras Upgrade (~line 249-250)
Upgrade: [
  "docs/upgrading/v1.27.md",
  "docs/upgrading/storage-prefix.md"
],
```
`package_files` includes `Path.wildcard("docs/**/*.md")`, so packaging is automatic.

Constraints from the contract test: `docs/architecture.md` keep 13 `##` headings in order and exactly 4 mermaid blocks with `accTitle:`/`accDescr:`; `docs/code-walkthrough.md` keep 18 (cap) `elixir` blocks, each parseable by `Code.string_to_quoted/1`, rewrite the stale `sign_jwt/2` excerpt (`:463-490`) in place to the `PrivateJwk.decode(signing_key)` shape, keep anchored excerpts; `docs/install-and-onboard.md` keep order `mix lockspire.install` then `mix ecto.migrate` then `mix lockspire.verify` and phrases `does not prove`, `staff access policy`, `host app`, `host request tests`, `supported-surface.md`; guides must not contain `.planning/`, `/Users/`, `file://`, GitHub `blob` links, `](lib/`, `](test/`, `#L12`.

`docs/telemetry.md`: existing claim at line 9 "Every event emitted by Lockspire produces two paths" and the audit mirror at 14. Add a `[:lockspire, :key, ...]` section: operator emits (`generated`, `published`, `activated`, `retired`, `encrypted`, `rewrapped`, `reencrypt_failed`, `reencrypt_completed`) have audit mirrors; `legacy_read` and `decode_failed` (`private_jwk.ex:68-101`, direct `:telemetry.execute`) do not.

Release note (`157-RELEASE-NOTES.md`): no repo analog. Use `{VERSION}` placeholder (D-21), title `feat(keys): encrypt private signing keys at rest under a host-held key (v1.43)`, lead "Upgrade notes - action required". Pre-merge check (D-22): `git log origin/main..HEAD --format=%B | grep -E "BREAKING|^[a-z]+(\(.*\))?!:"` must be empty; also `grep -i breaking` the note file. Squash settings: title `COMMIT_OR_PR_TITLE`, body `COMMIT_MESSAGES` (PR description is not parsed). Open PR #121 and auto-merge hazard: add a `checkpoint:human-action` task before the squash merge (RESEARCH Open Question 1).

## Shared Patterns

### Query-channel suppression (sensitive reads)
**Source:** `lib/lockspire/storage/ecto/repository/support.ex:32-49` and `signing_key_store.ex:245-250`
**Apply to:** every `SigningKeyStore` path that selects or binds `private_jwk_encrypted` (9 paths above); never call `repo.*` directly for this table.

### No-args exception handling at the key boundary
**Source:** `lib/lockspire/protocol/private_jwk.ex:132-136` (`rescue _exception -> ... catch _kind, _reason -> ...`)
**Apply to:** `PrivateJwk.to_jwk/1` and nothing else; consumers call the helper and add no `rescue` of their own. Never `inspect(reason)` a decoded map; never reraise with the map.

### Telemetry that bypasses audit mirror
**Source:** `private_jwk.ex:68-73`
```elixir
:telemetry.execute(
  [:lockspire, :key, :legacy_read],
  %{count: 1},
  Redaction.for_telemetry(%{kid: kid, legacy_plaintext: :allow})
)
```
**Apply to:** documentation only this phase (telemetry.md); no new emits.

### Test KEK and legacy-row fixtures
**Source:** `test/support/key_encryption_helpers.ex`: `put_key_encryption/1` (async: false; restores on exit), `config_keys/1`, `config_keyset/1`, `legacy_json_row/2`, `legacy_etf_row/2`, `sealed_row/3`, `insert_signing_key_row!/1`, `reset_decode_warnings/0`. Note `test_keyset/1` uses different material from `config/test.exs` (`test-1`/`test-2`); old-KEK fixtures must use `config_material/2`.
**Apply to:** the leak sweep, the upgrade journey, any new consumer tests.

### Telemetry capture in tests
**Source:** `test/support/telemetry_capture.ex` `attach_many/2` sends `{:telemetry_event, event, measurements, metadata}` and auto-detaches in `on_exit`.
**Apply to:** the sweep (attach `repo_query` and key events), as in `key_material_leak_test.exs:107-114`.

### Fitness and contract guards that must stay green
**Source:** `test/lockspire/architecture_fitness_test.exs` (line 45 no decrypt in JWKS/KeyCache; 67 single stored-key reader; protocol files never alias `Admin`/`Web`); `test/lockspire/config_key_encryption_test.exs:130` (`refute source =~ ~r/compile_env\(\s*:lockspire,\s*:key_encryption/`); `test/lockspire/documentation_contract_test.exs`.
**Apply to:** all plans; `PrivateJwk.to_jwk/1` lives in `protocol/` and must not reference `Lockspire.Admin`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `157-RELEASE-NOTES.md` | docs | n/a | No release-note/PR-body file exists in the repo; use CONTEXT D-16/D-21 content and the v1.42 squash `1cfafd03` body only for commit-message shape |

(`test/support/key_material_matcher.ex` is a partial match: shape from `telemetry_capture.ex`, logic from RESEARCH F4.)

## Metadata

**Analog search scope:** `lib/lockspire/{storage,protocol,generators,admin}`, `lib/lockspire/{redaction,config}.ex`, `test/support`, `test/lockspire/{security,redaction,protocol,workers}`, `test/mix/tasks`, `test/integration`, `examples/adoption_demo`, `scripts/acceptance`, `.github/workflows/ci.yml`, `docs/upgrading`, `mix.exs`
**Files read directly:** about 22 (signing_key_store, signing_key_record, redaction, private_jwk, support, install generator, leak test, key_encryption_helpers, telemetry_capture, consumer excerpts, adoption demo config/seeds/compose, build_provider.py and journey excerpts, storage-prefix.md, mix.exs excerpt, 156-PATTERNS)
**Tracked-source gate:** `git ls-files` confirmed tracked for all 15 spot-checked analog paths (redaction.ex, jar.ex, access_token_signer.ex, redaction_test, private_jwk_test, backchannel worker test, keys_live_test, overview_live_test, install_generator_test, reencrypt task test, journey script, ci.yml, docker-compose.yml, config.ex, telemetry.md); no gitignored mirror paths used.
**Pattern extraction date:** 2026-10-16

## PATTERN MAPPING COMPLETE
