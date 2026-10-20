# Phase 159: Key-Encryption Key Setup DX - Context

**Gathered:** 2026-10-19 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

A host developer can generate and wire up a key-encryption key without openssl and without risking a silent unencrypted fallback. Requirements: KEK-03 (`mix lockspire.gen.kek`), KEK-05 (`{:system, "VAR"}` runtime resolution, fail-closed), KEK-06 (no key bytes in inspect/logs; all key-generation guidance points to `gen.kek`). SAFE-02 constrains the phase: no protocol, security-default, schema, or dependency change; key material never appears in output except `gen.kek`'s own generated key.

Out of scope: admin Keys page "Key protection" line and missing-KEK admin error (Phase 160), DOC-02 guide completeness and release (Phase 161), moving `keys.reencrypt` onto RepoRunner/TaskError, `gen.kek --rotate`, `--format json`, KMS/Vault providers.
</domain>

<decisions>
## Implementation Decisions

### Shared snippet builder and `mix lockspire.gen.kek`
- **D-01:** Extract the KEK generation and prod `runtime.exs` snippet from `Lockspire.Generators.Install.instructions/1` (`lib/lockspire/generators/install.ex:124-157`) into a new `@moduledoc false` module `Lockspire.Generators.KekSnippet`. It owns: key generation (`Base.encode64(:crypto.strong_rand_bytes(32))`, padded, 44 chars), default id (`Calendar.strftime(DateTime.utc_now(), "%Y-%m")`, UTC), and the prod `runtime.exs` block. The installer and `gen.kek` both call it — one builder, no drift.
- **D-02:** `gen.kek` default output: (1) the generated value once, as `LOCKSPIRE_KEY_ENCRYPTION_KEY=<value>` with a "store it in your secret manager" line; (2) the shared prod `runtime.exs` block (references the env var name only); (3) a one-line note that dev/test should use the installer's throwaway literal key. It does NOT print the dev/test block with the generated key embedded (would push a real key toward a committed `dev.exs`). `--raw` prints only the value, exactly one line.
- **D-03:** The prod snippet keeps `System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY") || raise(...)`; only the raise text changes from `openssl rand -base64 32` to `mix lockspire.gen.kek`. `{:system, "VAR"}` is documented as an alternative form, not the installer default.
- **D-04:** `gen.kek` is a plain `use Mix.Task` (no Igniter, no `@requirements`, no `app.config`), so it works even when host `runtime.exs` raises for a missing key. No repo, no Logger, no telemetry, no file writes; output via `Mix.shell().info/1` only. Strict `OptionParser` switches (`--id`, `--raw`, `--help`), unknown options/args → `Mix.raise`, matching `lockspire.install.ex` / `keys.reencrypt.ex` style.
- **D-05:** `--id` validates with the existing `KeySet` id rule (`~r/\A[A-Za-z0-9._-]{1,32}\z/`, `key_set.ex:48`) exposed via a small public predicate (e.g. `KeySet.valid_id?/1`) — no copied regex. The rule also prevents quote injection into the printed snippet. Tests round-trip printed value + id through `KeySet.new(keys: [{id, value}], current: id)`.

### `{:system, "VAR"}` resolution and fail-closed boot
- **D-06:** Resolve env-var entries inside `Lockspire.Config.key_encryption!/0` (`config.ex:253-266`), between `Application.get_env` and `KeySet.new/1`. `KeySet` stays a pure validator. Entry form: `{id, {:system, var}}` with `var` a binary. Read with `System.fetch_env/1`; empty string is treated as missing; no default-value form. Runtime only — never `compile_env`, never `Application.put_env` back. Boot caching in `:persistent_term` (`application.ex:29-45`) is unchanged.
- **D-07:** Unset/empty variable raises `ArgumentError` via `fail_key_encryption!` with the existing `invalid config :key_encryption` prefix (load-bearing for `TaskError` classification at `task_error.ex:21-26`, and for `verify`/doctor which already surface the message). Message names the variable, never a value, and points to `mix lockspire.gen.kek`. Add a new reason (e.g. `{:keys, :missing_env}`) consistent with the existing tuple contract. Never returns `nil` / "not configured" for a configured block — boot aborts in `Application.start/2`.

### Redaction and guidance sweep (KEK-06)
- **D-08:** `key_set_inspect.ex` redaction is already correct; no structural change, no `@derive`. Add proof tests: a key set resolved from `{:system, VAR}` shows no key bytes and no env value in `inspect`/Logger output; the missing-var boot error contains the var name and not any value.
- **D-09:** Replace openssl-based key-generation guidance with `mix lockspire.gen.kek` in: `lib/lockspire/config.ex:282-290` (keep the `phx.gen.secret` warning), `lib/lockspire/application.ex:37-41`, `lib/lockspire/install/verify.ex:96-98`, `lib/mix/tasks/lockspire.keys.reencrypt.ex:144-148`, `lib/mix/tasks/lockspire.doctor.key_encryption.ex:79-82`, `lib/lockspire/generators/install.ex:146` (via KekSnippet), `docs/upgrading/signing-key-encryption.md:9-21` (also align its Step 1 `System.fetch_env!` example with the installer form), `docs/install-and-onboard.md:145,155`, `scripts/acceptance/clean_room/build_provider.py:89`. Update pinned tests in the same commit: `test/lockspire/config_key_encryption_test.exs:83-87`, `test/lockspire/install/verify_test.exs:339`, `test/lockspire/upgrade_guide_contract_test.exs:14`, `test/integration/install_generator_test.exs:313`.
- **D-10:** Add a contract test failing if any `lib/` or `docs/` string recommends `openssl rand` without `gen.kek`. The upgrade guide may keep the `elixir -e` one-liner as a fallback for release-only hosts without Mix (the only allowed non-`gen.kek` recipe).

### Claude's Discretion
- Exact wording of `gen.kek` output lines and `--help` text (plain, concise; follow existing task tone).
- Exact reason atom name for the missing-env case.
- Whether the clean-room harness additionally switches to consuming `gen.kek --raw` output (optional; not required by success criteria).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 159 section and success criteria
- `.planning/REQUIREMENTS.md` — KEK-03, KEK-05, KEK-06, SAFE-02
- `.planning/research/v1.44-adopter-polish/SUMMARY.md`, `ARCHITECTURE.md` (Items 2-3), `FEATURES.md`, `PITFALLS.md`, `STACK.md`
- `.planning/phases/158-mix-task-repo-start/158-CONTEXT.md` — compute-then-print rule, deferred reencrypt item
- `lib/lockspire/config.ex`, `lib/lockspire/application.ex`
- `lib/lockspire/security/key_encryption/key_set.ex`, `lib/lockspire/security/key_encryption/key_set_inspect.ex`, `lib/lockspire/redaction.ex`
- `lib/lockspire/generators/install.ex`, `lib/mix/tasks/lockspire.install.ex`
- `lib/lockspire/install/verify.ex`, `lib/lockspire/install/task_error.ex`
- `lib/mix/tasks/lockspire.keys.reencrypt.ex`, `lib/mix/tasks/lockspire.doctor.key_encryption.ex`
- `docs/upgrading/signing-key-encryption.md`, `docs/install-and-onboard.md`
- `scripts/acceptance/clean_room/build_provider.py`
- Tests: `test/lockspire/config_key_encryption_test.exs`, `test/lockspire/security/key_encryption_test.exs`, `test/lockspire/upgrade_guide_contract_test.exs`, `test/lockspire/install/verify_test.exs`, `test/integration/install_generator_test.exs`, `test/support/key_encryption_helpers.ex`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `KeySet.new/1` and id regex: `lib/lockspire/security/key_encryption/key_set.ex:26-48`, `check_id/1` at :99-101
- Existing key-generation recipe: `lib/lockspire/generators/install.ex:125-126`
- `TaskError` config-message passthrough: `lib/lockspire/install/task_error.ex:21-26,79-81`
- `put_key_encryption/1` test helper (swaps env, refreshes `:persistent_term` cache): `test/support/key_encryption_helpers.ex:18-37`

### Established Patterns
- Strict `OptionParser` → `validate!` → `Mix.raise` for bad flags (`lockspire.keys.reencrypt.ex:28-99`); `--help` text in-module; output via `Mix.shell().info`.
- `capture_io` testing of installer output (`install_generator_test.exs:299-330`).
- Env-var config tests are `async: false` with restore-on-exit and a `@sentinel` value (`config_key_encryption_test.exs:1-26`).
- `gen.kek` tests can be `async: true`: assert 32 decoded bytes, `KeySet.new` passes, value differs across runs, `--raw` is one line, snippet parses via `Code.string_to_quoted`.

### Integration Points
- `Config.key_encryption!/0` is the single resolution point; all callers (boot, hot path, Verify, doctor, Admin.Keys) funnel through it.
- `Application.validate_key_encryption!/0` provides fail-closed boot; its `nil` branch only warns and must never be reached for a configured block.
- `verify`/doctor surface `ArgumentError` messages unchanged.
- Docs already packaged in `mix.exs:221,252`; run `mix docs.verify` on CI Elixir 1.19.5-otp-28.
</code_context>

<specifics>
## Specific Ideas

- Planner should empirically confirm (clean-room or a dep fixture) that a dependency's Mix task with no `@requirements` runs from the host project when host config/`runtime.exs` would raise.
</specifics>

<deferred>
## Deferred Ideas

- `gen.kek --rotate` two-entry snippet; `--format json` output (future requirements).

### Reviewed Todos (not folded)
- `2026-10-19-keys-reencrypt-via-repo-runner.md` — DB-path behavior change needing Phase 158's cold-start harness; better as a quick task or in Phase 161. Phase 159 only changes its guidance string.
- `2026-10-13-audit-dcr-default-lifetime-semantics.md` — protocol work; stays in its own later milestone (DCR-01).
</deferred>
