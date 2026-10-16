# Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal - Research

**Researched:** 2026-10-16
**Domain:** Elixir/Ecto operator tooling for in-place re-encryption of signing-key rows (AES-256-GCM envelopes), Postgres row locking, Mix task DX, telemetry/audit discipline
**Confidence:** HIGH (every integration point was opened and read this session; the Ecto/Postgres behaviours were exercised against the local test database)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

(Copied from `156-CONTEXT.md` `## Implementation Decisions`. D-00..D-31 are locked. Do not re-litigate.)

**Binding upstream design**
- **D-00:** Research R1–R8 and "Other resolutions" in `.planning/research/v1.43-key-encryption/SUMMARY.md` and Phase 155 decisions D-00..D-20 stay locked. SAFE-01 applies: no new deps, no migration, no column rename, no `kek_id` column, no decrypted-key caching, no protocol behavior change, no new admin UI copy.

**Re-encryption engine (156-01)**
- **D-01:** **One short transaction per row** (corrects the roadmap's "locked-batch" wording). Read candidate ids in keyset pages (`where id > ^cursor order by id limit ^page`). For each id: `TransactionStore.transact` → `SELECT … WHERE id = ? FOR UPDATE` (plain blocking, default READ COMMITTED) → classify **after** the lock → seal/re-wrap → round-trip verify → CAS `update_all` → per-row audit append, all in that transaction. Reason: `activate_signing_key` locks the selected row then all active rows of the same `use` (`signing_key_store.ex:134-202`), not in `id` order, so multi-row batch locks can deadlock with it; a transaction holding one row lock cannot be in a cycle. No `SKIP LOCKED` (undercounts and can exit 0 with rows unconverted), no `NOWAIT`, no advisory lock, no isolation change.
- **D-02:** Classification happens in Elixir, never in the SQL `WHERE`. A run that waited on a lock receives the other run's committed row (EvalPlanQual) and counts it `already_current`; both concurrent runs report the same `scanned`, and no row is double-wrapped.
- **D-03:** The CAS stays as a guard even though `FOR UPDATE` makes it redundant: `update_all(where id == ^id and private_jwk_encrypted == ^old, set: [private_jwk_encrypted: new, updated_at: DateTime.utc_now()])`. `{1, _}` → ok; `{0, _}` → counted `:conflict`, not a batch rollback. `update_changeset/2` is not widened to cast the column. All queries go through `Repository.Support` so storage prefixes apply.
- **D-04:** Storage seam: one new `Lockspire.Storage.KeyStore` callback (name is Claude's discretion, e.g. `reencrypt_signing_key(id, fun)`) whose Ecto implementation in `SigningKeyStore` owns the lock, re-read and CAS. `Repository` gets a one-line `@impl KeyStore` delegate (`architecture_fitness_test.exs:84-91`). The callback receives a function from `Admin.Keys` that does all classification/crypto; storage never decrypts.
- **D-05:** The engine takes an explicitly resolved `KeySet` (`Config.key_encryption!/0`, fresh) and passes it down; seal, open and round-trip verify all use that same key set, never the `:persistent_term` cache. Aborts before touching rows only on global preconditions: no KEK configured or invalid config.
- **D-06:** Row classification and actions:
  - nil material → `no_private_key` (counted, skipped).
  - envelope on current KEK → `already_current` (opened to prove decryptable, not rewritten).
  - envelope on another configured KEK → open → re-seal under current → `rewrapped`.
  - envelope on an unconfigured KEK, or open fails → `failed` with reason (`:unknown_kek`, `:decryption_failed`, `:malformed_envelope`, `:kid_mismatch`).
  - legacy → decode JSON, else `Plug.Crypto.non_executable_binary_to_term(bin, [:safe])`; require a map whose `"kid"` equals the row `kid` (else `failed`, `:kid_mismatch` or an unreadable-legacy reason) → re-serialize with `Jason.encode!/1` (ETF becomes JSON) → seal → `encrypted`. The JWK is never repaired or mutated (no kid injection).
  - Round-trip verify: open the new envelope with the same key set, JSON-decode, `kid` equals row `kid`; else `failed` with a round-trip reason and nothing written.
- **D-07:** Scope: every row with private material, all statuses (`upcoming|active|retiring|retired`) and both `use: :sig` and `use: :enc`. Never touches `status` or other lifecycle columns.
- **D-08:** The engine is not blocked by `:reject`. It uses an internal legacy-tolerant decode entry callable only from `Admin.Keys` (e.g. `decode_with_reason(row, legacy_plaintext: :allow)`), which emits no `legacy_read` telemetry. That gives a no-config-change recovery when a pre-migration backup is restored or `:reject` was set too early. Under `:reject` the task prints a warning line, and each converted row is audited normally.
- **D-09:** Dry-run takes no locks and writes nothing (no ciphertext, no audit rows). It runs the same classify → seal → verify path in memory, so it is the **deep** check that proves every envelope opens with the current key set. Its counts read "would encrypt / would re-wrap".

**Public API (156-01 / 156-02)**
- **D-10:** `Lockspire.Admin.Keys.reencrypt(opts \\ [])`, with opts `dry_run: boolean()` and `actor: map()` (existing `actor_from_attrs` shape). It returns:
  - `{:ok, report}` when it ran. The report is a plain typed map: `dry_run`, `current_kek_id`, `scanned`, `encrypted`, `rewrapped`, `already_current`, `no_private_key`, `conflicted`, `by_source_kek` (`%{"legacy" | kek_id => count}`) and `failed: [%{kid, reason, kek_id}]`.
  - `{:error, reason}` only when it could not run: `:key_encryption_not_configured`, invalid config, or `:repo_not_started`.

  Per-row failures stay inside `{:ok, report}`, because successful rows are committed. It assumes the repo is already started, like every other `Admin.Keys` function.
- **D-11:** `Lockspire.Admin.Keys.encryption_status/0` returns `{:ok, status}` with: `configured`, `current_kek_id`, `configured_kek_ids`, `legacy_plaintext`, `total`, `no_private_key`, `legacy`, `by_kek_id`, `unknown_kek` (`%{kek_id => count}`), `undecryptable` (rows on a configured id that fail to open: wrong material for that id, tamper, `kid_mismatch`), `pending: [%{kid, state}]` and `ready?`.
  - It reads rows via the existing `list_signing_keys/1`, so it needs no new storage method.
  - It **opens every envelope and discards the plaintext**, so it catches same-id/wrong-material (C4), which header-only counts cannot. Tens of rows make the cost trivial; nothing is cached.
  - `ready?` requires: configured, `legacy == 0`, every material row on current, `unknown_kek` and `undecryptable` empty.
- **D-12:** Both functions get `@doc` + `@spec` + `defdelegate` in `Lockspire.Admin` (`admin.ex:193-231` pattern). Any new `Lockspire.Config` export must be added to `test/support/architecture/public_compatibility_manifest.ex`.
- **D-13:** No `Lockspire.Release` module. A running node uses `bin/app rpc '…Lockspire.Admin.Keys.reencrypt()…'`. The fresh-VM `MyApp.Release` snippet (`load_app` + `Ecto.Migrator.with_repo`) is documented in Phase 157, which must state that a bare `bin/app eval "Lockspire.Admin.Keys.reencrypt()"` does not start the repo.

**Mix task (156-01)**
- **D-14:** `mix lockspire.keys.reencrypt [--dry-run | --check]` follows `ecto.migrate`:
  - `@requirements ["app.config"]` → `Application.ensure_all_started(:ecto_sql)` → `Ecto.Migrator.with_repo(Config.repo!(), fun, mode: :temporary)`. Not `app.start`, which would boot the host endpoint and Oban.
  - Parsing: `OptionParser.parse(strict: [dry_run: :boolean, check: :boolean, help: :boolean])`. Unknown options and **any positional argument** fail with `Mix.raise`, so a typo like `check` never triggers a write.
  - `--check` + `--dry-run` together fail with `Mix.raise("--check and --dry-run cannot be combined; --check never writes")`.
  - No `--repo`, `--batch-size`, `--json` or parallelism.
  - Mix actor: `%{type: :operator, id: "mix lockspire.keys.reencrypt"}`.
- **D-15:** Exit codes, always via `Mix.raise` (exit 1), never `System.halt`:
  - real run: exits 1 if any row failed or conflicted; the message says the other rows were saved and a rerun is safe.
  - `--dry-run`: exits 0 even with pending rows; exits 1 only if a row would fail.
  - `--check`: exits 1 unless `ready?`; it fails when no KEK is configured, and does not require `:reject` to be set (it is the gate before setting it).
- **D-16:** `--check` is a mode of this task that reads `encryption_status/0`: it takes no locks and writes nothing. It answers "can I set `:reject` now / remove the old KEK?"
- **D-17:** Output is human `key=value` lines in the doctor style:
  - a header line: `current_kek=… legacy_plaintext=…`
  - one summary line of counts
  - `failed  key=<kid> reason=<atom> kek=<id>` lines, each followed by one fix line per reason; under `--dry-run`, "would encrypt / would re-wrap" row lines
  - a `Next:` line.

  Rows show the raw `kid`, which is public in JWKS and matches audit/telemetry. Never print ciphertext, JWK members, or KEK values or lengths. Example outputs from the CLI research are the target shape (see DISCUSSION-LOG).
- **D-18:** Help text states the four-step upgrade order (deploy code+KEK everywhere → reencrypt → `--check` → `:reject`) and the **five-step KEK rotation order**:
  1. Add the new key to `:keys` without changing `current`, and deploy everywhere.
  2. Switch `current` and deploy everywhere.
  3. Run `reencrypt`.
  4. Run `--check`.
  5. Remove the old id.

  Step 1 prevents a node with the new `current` writing envelopes that nodes not yet updated cannot open (C5). It also says to run only after every node runs this release with the same config.

**Doctor and Verify (156-02)**
- **D-19:** One source of truth: `--check`, doctor and verify all read `encryption_status/0` and differ only in what they gate on.
  - `reencrypt --check`: is everything ready?
  - `mix lockspire.doctor key_encryption`: wraps `with_repo`, prints the existing config line plus row counts per KEK id, legacy, unknown and undecryptable, and a hint such as "N rows still need re-encryption: run …". It exits 1 only if config is invalid/missing, the database is unreadable, or something is broken now. With no KEK it still shows the legacy count.
  - `Install.Verify`: adds one DB-backed check that is `:error` only when something is **broken now** (any `unknown_kek` or `undecryptable` row, or `:reject` with legacy rows remaining). Legacy rows under `:allow` stay `:ok`, with counts in `details`; this keeps the KEK-02 non-breaking promise, and the D-08/155 missing-KEK error already supplies the loud nudge. If the DB cannot be read or migrations are pending, report the check as skipped/non-duplicating rather than double-failing with the migrations check, and catch DB errors, which `safely/1` currently does not.

**Plaintext refusal (156-02)**
- **D-20:** In `PrivateJwk.decode_with_reason/1`, read the key set once. A `:legacy` classification with `legacy_plaintext: :reject` returns `{:error, :plaintext_key_refused}` **before** `Jason.decode` or the ETF parser runs. A nil key set or `:allow` keeps today's path. Add `:plaintext_key_refused` to `@type reason`. The external collapse is unchanged: `:invalid_signing_key` at five sites, `:decryption_failed` for JAR (155 D-02).
- **D-21:** `:reject` applies to `use: :enc` keys as well. JAR continues to the next key. A JOSE `block_decrypt` failure (JWE not addressed to that key) is not a key-storage fault and emits no `decode_failed`.
- **D-22:** The mode is read from the boot-cached key set, so a change takes effect on each node's next boot (existing WR-02 decision). Rolling restarts briefly mixing modes are safe only because the flip is gated on `--check`. Document this in help text now and in the 157 runbook.

**Telemetry and audit (156-02) — corrects ROADMAP criterion 5 and OPS-02**
- **D-23 (user-confirmed 2026-10-16):** Encrypt and re-wrap write **durable audit records and telemetry**. Legacy-read, refusal and decryption-failure emit **telemetry only**: no durable write on the signing path and no `[:lockspire, :audit, …]` mirror. All carry only `kid`, KEK id, counts and reason atoms. Reasons:
  - Signing deliberately has no durable side effects (`token_exchange/internal/token_issuer.ex:21-24`).
  - A DB insert per token would amplify load during a key outage.
  - Grant transactions may roll the audit row back.
  - The audit mirror flood risk is documented at `plug/verify_token.ex:478-496`.

  The planner should apply this wording to ROADMAP success criterion 5 and REQUIREMENTS OPS-02.
- **D-24:** Hot-path events use direct `:telemetry.execute/3` (the `verify_token.ex` precedent), with fixed allowlisted metadata passed through `Redaction.for_telemetry/1`:
  - `[:lockspire, :key, :legacy_read]`: `%{count: 1}`, `%{kid, legacy_plaintext: :allow}`. Fires on each successful legacy read under `:allow`.
  - `[:lockspire, :key, :decode_failed]`: `%{count: 1}`, `%{kid, reason}`, plus `kek_id` only when `KeyEncryption.envelope_kek_id/1` parses it (omit rather than nil). Covers refusal and every decode failure reason; a single alarm event, with the reason atom carrying the distinction.
  - Successful envelope reads emit nothing.
  - Emit in `decode/1` around `decode_with_reason`, keeping `decode_with_reason` side-effect free so the engine and tests do not inflate counts.
- **D-25:** Operator-path events go through `Observability.emit(:key, …)` after commit, matching the existing `:generated/:published/:activated/:retired`:
  - `:encrypted`: `actor_type, actor_id, key_id, kid, status, kek_id`.
  - `:rewrapped`: the same plus `previous_kek_id`.
  - `:reencrypt_failed`: `kid, key_id, reason`.
  - `:reencrypt_completed`: measurements are the counts plus `duration`; metadata `mode: :apply | :dry_run | :check, current_kek_id, actor_type, actor_id`.

  No `:telemetry.span`: exception metadata carries stacktraces that may contain key binaries.
- **D-26:** Durable audit records `:key_encrypted` / `:key_rewrapped` are written in the row transaction via the existing `key_audit_event` shape:
  - `outcome: :succeeded`, `reason_code: action`, `resource: %{type: :signing_key, id: key.id}`
  - metadata `key_id, kid, status, use, kek_id`, plus `previous_kek_id` for re-wrap.

  Dry-run, `--check` and failed rows write no audit records. There is no run-level summary audit record (no natural `resource_id`). Actor defaults to `:operator`, not `"system"`, because re-encryption is an operator decision.
- **D-27:** Logger: one line per node per `{kid, reason}`, deduplicated via a `:persistent_term` flag `{Lockspire, :key_decode_warned, kid, reason}` (public kid + atom, no key material; say so in a code comment for SAFE-01 reviewers).
  - `Logger.warning` on the first legacy read when a KEK is configured: names the kid and says to run `mix lockspire.keys.reencrypt`. Silent with no KEK, which the boot warning already covers.
  - `Logger.error` on the first refusal or decode failure: reason atom and kid only.

  Never `inspect` inputs or exceptions in the decoder. Tests need a reset helper; reject-mode tests are already non-async.
- **D-28:** Phase 156 adds no `Lockspire.Redaction` drop-list changes (RED-01 sweep is 157, which must not drop `kid`/`kek_id`). Safety comes from explicit allowlisted metadata builders; never place `SigningKey`, `KeySet`, decoded JWK maps or raw binaries in metadata. Tests assert the exact metadata key set per new event, plus a sentinel leak test: a known `d` value and KEK across legacy read, refusal, each decode failure, re-encrypt and re-wrap, checked in telemetry (both paths), audit rows and captured logs, with no `d`, KEK base64, `"LSK"` bytes or raw column value.

**Tests**
- **D-29:** Real concurrency tests follow `test/lockspire/storage/repository_concurrency_test.exs`: `async: false`, `@moduletag :integration`, `Sandbox.mode(:manual)`, `Sandbox.unboxed_run`, cleanup by `kid` in `on_exit`.
  - An internal test-only after-lock hook option makes the overlap deterministic: run A locks and waits; run B is asserted blocked; A is released; then A `encrypted = N` and B `already_current = N`, both with equal `scanned`.
  - A 5–10-contender barrier test asserts the sum of `encrypted + rewrapped` equals the initial stale rows.
  - The CAS `{0, _}` branch is tested directly.
  - Every row opens exactly once to JSON with a matching `kid` (no double wrap).
- **D-30:** Rotation matrix: legacy, old-KEK and new-KEK rows × current = k1 / k2, using `put_key_encryption/1` or the `config/test.exs` material (`test-1`/`test-2`), not `test_keyset/1`'s different material. Plus a legacy row with missing or mismatched `"kid"` (reported, untouched), an ETF row (becomes JSON), a nil-material row, and an unknown-KEK row. Also cover `:reject` recovery via the engine, and `--check`/doctor/verify agreement on the same fixture set.
- **D-31:** Mix task tests: `Mix.Task.reenable` + `capture_io`, `assert_raise Mix.Error` for exit 1, and the positional-argument and flag-combination rejections. Tests must not rely on an already-started `TestRepo` to hide a missing `with_repo`; cover the not-started path.

### Claude's Discretion
- Module names: engine location (in `Admin.Keys` or a private `Admin.Keys.Reencrypt` helper), the store callback name, the page size (default ~100), and the internal hook option name.
- Exact unreadable-legacy and round-trip failure reason atoms.
- Exact help/output wording within D-17/D-18 (no admin UI copy is involved).
- Whether `TransactionStore.transact` moves to `repo.transact/2` (Ecto 3.14 deprecates `transaction/2`). Only if trivial; otherwise leave it.

### Deferred Ideas (OUT OF SCOPE)
- `Lockspire.Release` helper module: revisit only if UAT shows release-eval friction.
- `--json` output, `--repo`, `--batch-size`, `--from-kek` filter: not needed for tens of rows.
- Time-bucketed log throttle instead of once-per-node dedupe.
- New todo: `lockspire.client.create`, `doctor token_format` and `doctor remote-jwks` use `app.config` without starting the repo and likely fail in a real host (`.planning/todos/pending/2026-10-16-mix-tasks-start-repo.md`).
- Reviewed todo not folded: `2026-10-13-audit-dcr-default-lifetime-semantics.md` (DCR-01, a later protocol milestone).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MIG-01 | `Admin.Keys.reencrypt/1` and `mix lockspire.keys.reencrypt` with `--dry-run`, counts, idempotent re-runs, concurrency safety (row lock + CAS on the ciphertext column only) | Per-row `FOR UPDATE` transaction pattern already in `signing_key_store.ex` (`locked_key/2`); CAS verified live against the test DB (`{1, nil}` then `{0, nil}`); `Support.update_all(..., sensitive: true)`; `with_repo` semantics verified; concurrency test pattern in `repository_concurrency_test.exs` |
| MIG-02 | `--check` (non-zero while any legacy row remains) and doctor `key_encryption` row counts per KEK id and legacy | `Admin.Keys.encryption_status/0` over `list_signing_keys/1` (returns full rows incl. `private_jwk_encrypted`); doctor wraps `with_repo`; Verify DB check design with injectable status |
| MIG-03 | Under `:reject`, non-envelope rows refused at read with `:plaintext_key_refused` internally, before legacy parsers run | `PrivateJwk.decode_with_reason/1` branch order (`classify` then `decode_legacy`); single keyset read; `@type reason` extension |
| OPS-01 | KEK rotation without reissuing keys; matrix legacy/old/new rows × each current | Engine re-wrap path; fixture materials `test-1`/`test-2` from `config/test.exs`; five-step order in help text |
| OPS-02 | Encrypt/re-wrap/legacy-read/refusal/decrypt-failure events with ids, counts, reasons only | `Observability.emit/4` (operator path), direct `:telemetry.execute/3` (hot path), durable `key_audit_event`; apply D-23 wording correction to ROADMAP criterion 5 and REQUIREMENTS OPS-02 |
</phase_requirements>

## Summary

Phase 156 needs no new dependency, migration, or protocol behaviour change. Everything it needs already exists in the repo: the `FOR UPDATE` row lock helper, `Support.update_all` with `sensitive: true`, the `transact_with_audit`/`key_audit_event` audit shape, `Observability.emit/4`, `Ecto.Migrator.with_repo/3`, the `ecto.migrate`-style task pattern, and the sandbox `unboxed_run` concurrency test pattern. All integration points named in CONTEXT `<code_context>` were opened and verified this session; the only drift is cosmetic: the signing-key store lives at `lib/lockspire/storage/ecto/repository/signing_key_store.ex` (CONTEXT cites it without the directory), and the audit-append / metadata helpers in `Admin.Keys` are private `defp`s (see Integration Point Ledger).

Four findings the planner must act on that CONTEXT does not state explicitly:
1. **Ecto query logging would leak plaintext keys.** The CAS `where private_jwk_encrypted == ^old` puts the *legacy plaintext JWK* in a query parameter. `Support.repo_options/1` turns `sensitive: true` into `log: false`; every engine `update_all` must pass `sensitive: true`.
2. **`Ecto.Migrator.with_repo/3` restarts an already-running repo.** When the repo is already started it returns `{:ok, :restart}` and, after the function, calls `Supervisor.restart_child` on the pool child. `Install.Verify`'s DB check and any code that may run inside a live node must guard with a "repo running?" check and call directly when running.
3. **`Install.Verify.migration_status/2` can crash today.** It pattern-matches `{:ok, statuses, _apps} = Ecto.Migrator.with_repo(...)`, and `safely/1` only rescues `ArgumentError | RuntimeError | UndefinedFunctionError | FunctionClauseError`; a `DBConnection.ConnectionError`, `Postgrex.Error` or `MatchError` escapes. The `Check` struct has only `:ok | :error` statuses, so "skipped" must be an `:ok` check with explanatory details.
4. **D-01 pages candidate ids but no storage method lists ids.** `list_signing_keys/1` returns whole rows. Either add a tiny second `KeyStore` callback (recommended, honours D-01 literally) or accept `list_signing_keys/0` + `Enum.map(& &1.id)` (tens of rows; open question OQ-1).

**Primary recommendation:** Build the engine as one pure-Elixir classify/seal/verify function inside `Admin.Keys` (private helper module `Lockspire.Admin.Keys.Reencrypt` is fine) driven by two new `KeyStore` callbacks (`list_signing_key_ids/2`, `reencrypt_signing_key/3`); expose one shared `PrivateJwk.read_stored/2` (explicit keyset, mode-agnostic, no telemetry, `@doc false`) so legacy parsing exists in exactly one place; make `encryption_status/0` the single source of truth for `--check`, doctor and Verify; test the Mix task end to end with committed rows and `with_repo`-only repo lifecycle.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Row lock, re-read, CAS, audit append (atomic per row) | Database / Storage (`SigningKeyStore`) | — | Only storage owns Ecto queries/locks; `Repository` must stay a pure facade (fitness test) |
| Classify / seal / re-wrap / round-trip verify | API / Backend domain (`Admin.Keys`) | Security (`KeyEncryption`) | Crypto and policy decisions stay out of storage ("storage never decrypts", D-04) |
| Legacy parse (JSON, safe ETF) and plaintext refusal | Protocol (`PrivateJwk`) | — | Single read seam used by six signing consumers; refusal must precede the parsers |
| Hot-path telemetry / dedupe log | Protocol (`PrivateJwk.decode/1`) | — | Only place that sees every signing-path decode; direct `:telemetry.execute` per `verify_token.ex` precedent |
| Operator telemetry + durable audit | `Admin.Keys` via `Observability.emit/4` and `Repository.append_audit_event` | — | Matches existing `:generated/:published/:activated/:retired` |
| Readiness truth (`encryption_status/0`) | `Admin.Keys` | — | One function consumed by task `--check`, doctor, Verify |
| Operator CLI (`reencrypt`, doctor counts) | Mix task layer | — | Owns repo lifecycle (`with_repo`), arg parsing, output, exit codes; contains no business logic |
| Install diagnostic (broken-now check) | `Install.Verify` | `Admin.Keys` | Maps status to `Check` result; DB errors caught here |

## Standard Stack

### Core (all already in the repo; no additions)
| Library | Version (locked) | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ecto | 3.13.6 [VERIFIED: mix.lock] | Query, `update_all`, `Repo.transact/2` exists | Existing store layer |
| ecto_sql | 3.13.5 [VERIFIED: mix.lock] | `Ecto.Migrator.with_repo/3`, Sandbox `unboxed_run` | `ecto.migrate` pattern (D-14) |
| postgrex | 0.22.4 [VERIFIED: mix.lock] | Driver; `Postgrex.Error` for DB-error rescue | Existing |
| jason | existing | `Jason.encode!/1` for ETF→JSON re-serialization | Already used by `generate_key` |
| plug_crypto | existing | `Plug.Crypto.non_executable_binary_to_term/2` with `[:safe]` | Already used in `PrivateJwk` |
| :crypto (OTP) | OTP 28/29 | AES-256-GCM via existing `KeyEncryption` | SAFE-01: no new deps |
| :telemetry | existing | Direct `:telemetry.execute/3` hot path | `verify_token.ex` precedent |

### Supporting (test)
| Library | Purpose | When to Use |
|---------|---------|-------------|
| ExUnit `CaptureIO` / `CaptureLog` | Mix task output, Logger leak assertions | D-31, D-28 |
| `Lockspire.TestSupport.TelemetryCapture` | `attach_many/2` sends `{:telemetry_event, event, measurements, metadata}` | telemetry exact-key-set tests |
| `Lockspire.KeyEncryptionHelpers` | `put_key_encryption/1`, `seal_private_jwk/2` (cached keyset only) | rotation matrix, reject tests |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `list_signing_key_ids/2` new callback | `list_signing_keys/0` + map ids | Skips one callback + delegate; loads all rows once (tens). Deviates from D-01 wording; OQ-1 |
| `Repo.transaction` in `TransactionStore` | `repo.transact/2` | Exists in Ecto 3.13.6 [VERIFIED: deps/ecto/lib/ecto/repo.ex:327] but requires `{:ok,_}|{:error,_}` returns; `TransactionStore.run/2` passes bare values through. Not trivial; **leave as is** (CONTEXT discretion) |

**Installation:** none. `mix.exs`/`mix.lock` stay unchanged (SAFE-01); a plan acceptance check should be `git diff --exit-code -- mix.exs mix.lock`.

**Version verification:** ecto 3.13.6, ecto_sql 3.13.5, postgrex 0.22.4, oban 2.21.1, phoenix 1.8.13 read from `mix.lock` this session. No registry lookups were needed because no package is added.

## Package Legitimacy Audit

No external packages are installed by this phase (SAFE-01: no new deps). The `package-legitimacy` gate is not applicable.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | n/a | No install |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Integration Point Ledger (verified this session)

All line numbers below were read with `Read` this session. Drift from CONTEXT is called out.

| Item | Location | Verified fact | Drift vs CONTEXT |
|------|----------|---------------|------------------|
| `KeyStore` behaviour | `lib/lockspire/storage/key_store.ex:10-25` | 10 callbacks, last is `retire_signing_key/2`; module ends line 26 | none |
| `Repository` KeyStore delegates | `lib/lockspire/storage/ecto/repository.ex:482-532` | `@impl KeyStore` one-liners calling `EctoSigningKeyStore.*(repo(), …)`; `defp repo, do: Config.repo!()` at line 587 | none |
| `Repository.transact/1`, `append_audit_event/1` | `repository.ex:187-189`, `:324-332` | `transact(fun)` → `EctoTransactionStore.transact(repo(), fun)`; `append_audit_event/1` accepts `%Event{}` or a map | new info (needed by engine) |
| SigningKeyStore | `lib/lockspire/storage/ecto/repository/signing_key_store.ex` | `activate_signing_key` 134-151, `activate_selected` 174-188, `locked_key/2` 190-195, `active_keys_for_update/2` 197-202, `update_one/2` 221-226 | **path** lacks `repository/` dir in CONTEXT |
| `TransactionStore.transact/2` | `lib/lockspire/storage/ecto/repository/transaction_store.ex:4-12` (behaviour: `lib/lockspire/storage/transaction_store.ex`) | `repo.transaction(fn -> run(repo, fun) end)`; `{:ok, r}`→commit, `{:error, r}` from fun → rollback; `rescue error -> {:error, error}` returns the exception struct | none |
| `Support.update_all/5` | `lib/lockspire/storage/ecto/repository/support.ex:21-24` | `update_all(repo, query, updates, opts \\ [], keyword_opts \\ [])`; `repo_options/1` 32-38 drops `:sensitive` and sets `log: false` | none |
| `Admin.Keys` helpers | `lib/lockspire/admin/keys.ex:275-336` | `transact_with_audit/2` 275-286 (uses `Repository.transact`), `append_audit_event/2` 288-293, `emit/4` 295-303, `key_audit_event/4` 305-314, `actor_from_attrs/1` 316-324, all `defp` | helpers are **private**; the engine must live in `Admin.Keys` or a helper module that re-implements/relocates them |
| `Admin` facade | `lib/lockspire/admin.ex:195-231` | `defdelegate retire_key(key_id, attrs \\ %{}), to: Keys` is the last (line 231); file ends line 232 | none |
| `PrivateJwk` | `lib/lockspire/protocol/private_jwk.ex` | `@type reason` 7-13, `decode/1` 15-23, `decode_with_reason/1` 25-40 (with `rescue`/`catch`), `decode_envelope/2` 42-50, `decode_legacy/1` 52-57, `decode_safe_term/1` 59-64 | none |
| `KeyEncryption` | `lib/lockspire/security/key_encryption.ex` | `classify/1` 15-18, `seal/3` 20-48, `open/3` 50-63, `envelope_kek_id/1` 65-73 | none |
| `KeySet` | `lib/lockspire/security/key_encryption/key_set.ex` | struct 4-11, `current/1` 13-14, `fetch_key/2` 16-24, `new/1` 26-45 | none |
| `Config` key-encryption | `lib/lockspire/config.ex:246-289` | `key_encryption!/0` 254-266, `key_encryption_keyset/0` 271-278, `key_encryption_cache_key/0` 281-282, `repo!/0` 15 | none |
| `Install.Verify` | `lib/lockspire/install/verify.ex` | `run/1` 32-46, `config_checks/0` 48-58, `key_encryption_check/0` 62-88, `migrations_check/2` 312-334, `migration_status/2` 368-375, `safely/1` 377-382 | none |
| `Check` | `lib/lockspire/install/verify/check.ex` | `status: :ok | :error` only; `ok/4`, `error/4` | none; **no `:skipped` status exists** |
| Doctor dispatcher | `lib/mix/tasks/lockspire.doctor.ex:11-31` | `run(["key_encryption" | rest])` → `Mix.Task.run("lockspire.doctor.key_encryption", rest)` | none |
| Doctor key_encryption | `lib/mix/tasks/lockspire.doctor.key_encryption.ex:49-74` | `@requirements ["app.config"]`; config-only `report/0`; `Mix.raise` when nil/invalid | none |
| `Observability.emit/4` | `lib/lockspire/observability.ex:26-44` | Redacts via `Redaction.for_telemetry/1`, `Map.put_new(measurements, :count, 1)`, emits **both** `[:lockspire, :audit, entity, action]` and `[:lockspire, entity, action]` | none |
| `TelemetryCapture` | `test/support/telemetry_capture.ex` | `attach/2`, `attach_many/2` → `send(pid, {:telemetry_event, event, measurements, metadata})`; auto-detach on exit | none |
| `KeyEncryptionHelpers` | `test/support/key_encryption_helpers.ex` | `put_key_encryption/1` swaps env **and** refreshes `:persistent_term` (restored on exit); `seal_private_jwk/2` uses `Config.key_encryption_keyset()` (cached) | none |
| Concurrency test pattern | `test/lockspire/storage/repository_concurrency_test.exs:1-30,121` | `use ExUnit.Case, async: false`; `@moduletag :integration`; `setup_all` starts TestRepo if `Process.whereis` nil and sets `Sandbox.mode(:manual)`; `defp unboxed(fun), do: Ecto.Adapters.SQL.Sandbox.unboxed_run(Lockspire.TestRepo, fun)` | none |
| Architecture fitness | `test/lockspire/architecture_fitness_test.exs:84-100` (Repository facade), `:50-69` (JWKS/discovery/KeyCache never decrypt), `:294` (`protocol_outer_reference?` rejects `Lockspire.Admin`/`Lockspire.Web` aliases in protocol files) | `repository_aggregate_ownership?` flags `import Ecto.Query`, `*Record` aliases, `Ecto.Changeset` calls and `lock` in `repository.ex`; Repository must export every behaviour callback | none |
| Public compatibility manifest | `test/support/architecture/public_compatibility_manifest.ex:55-81` | Exact-equality check (`compatibility_baseline_contract_test.exs`) on **listed modules only**: `Lockspire.Config` is listed; `Lockspire.Admin`, `Lockspire.Admin.Keys` are **not** | 156 adds no `Config` exports, so no manifest edit is needed |
| `ReadabilityContractTest` | `test/lockspire/readability_contract_test.exs` | Regex `\b(?:Phase\|Plan)\s+\d+\|…\|\b(?:D\|WR\|…)-\d+\b` over **all** `lib/**/*.{ex,exs}` including `@moduledoc` and Mix task help text | confirms: no `D-08`/`Phase 157` in lib text; say "a later release runbook" |

### Verbatim in-repo values the code samples rely on

`PrivateJwk` reason type (private_jwk.ex:7-13):
```elixir
  @type reason ::
          :invalid_signing_key
          | :kek_not_configured
          | :unknown_kek
          | :malformed_envelope
          | :decryption_failed
          | :kid_mismatch
```
`KeyEncryption.classify/1` (key_encryption.ex:15-18): `:envelope | :legacy | :invalid`. `KeyEncryption.open/3` errors (50-53): `:kek_not_configured | :malformed_envelope | :unknown_kek | :decryption_failed`. `KeySet` struct (key_set.ex:11): `defstruct [:current_id, ids: [], keys: %{}, legacy_plaintext: :allow]`.

Lock helper (signing_key_store.ex:190-195):
```elixir
  defp locked_key(repo, id),
    do:
      SigningKeyRecord
      |> where([key], key.id == ^id)
      |> lock("FOR UPDATE")
      |> then(&Support.one(repo, &1))
```
`update_all` call shape with sensitivity (token_store.ex:344-350, same module family):
```elixir
Support.update_all(repo, &1, [set: [revoked_at: at, updated_at: updated]], sensitive: true)
```
Audit event shape (keys.ex:305-314):
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
`Check.result` (check.ex): `%{id: atom(), status: :ok | :error, summary: String.t(), details: String.t(), fix: String.t()}`.

`SigningKeyRecord` statuses and uses (signing_key_record.ex): `field(:use, Ecto.Enum, values: [:sig, :enc])`, `field(:status, Ecto.Enum, values: [:upcoming, :active, :retiring, :retired])`, `field(:private_jwk_encrypted, :binary)`; record and domain struct both `@derive {Inspect, except: [:private_jwk_encrypted]}`.

## Architecture Patterns

### System Architecture Diagram

```
 operator ──> mix lockspire.keys.reencrypt [--dry-run|--check]
                 │ OptionParser strict; positional/unknown/combined flags -> Mix.raise (no repo touched)
                 │ @requirements app.config ; ensure_all_started(:ecto_sql)
                 v
          Ecto.Migrator.with_repo(Config.repo!(), fun, mode: :temporary)   <- starts + later stops repo
                 │
   ┌─────────────┼───────────────────────────────┐
   │ --check     │ default / --dry-run           │ (also: bin/app rpc ... Admin.Keys.reencrypt())
   v             v                               v
 Admin.Keys.encryption_status/0      Admin.Keys.reencrypt(opts)
   │  Repository.list_signing_keys()    │ preconditions: repo running? (Process.whereis) ; Config.key_encryption!/0
   │  open every envelope (fresh keyset) │ keyset resolved ONCE, passed down
   │  discard plaintext                  │
   v                                     ├─ dry_run: list_signing_keys -> classify/seal/verify in memory (no locks, no writes)
 status map -> exit gate                 └─ apply: loop ids (list_signing_key_ids(after, limit))
 (also read by doctor, Install.Verify)        for each id -> Repository.reencrypt_signing_key(id, classify_fun, opts)
                                                │
                                                v   [ONE txn per row: TransactionStore.transact]
                                       SigningKeyStore: SELECT .. WHERE id FOR UPDATE
                                                │ classify_fun.(%SigningKey{}) (Admin.Keys, runs inside txn)
                                                │    PrivateJwk.read_stored(row, keyset)  | KeyEncryption.open/seal
                                                │    round-trip verify with same keyset
                                                v
                                       {:replace, new, audit_event, info} | {:keep, info} | {:error, reason, info}
                                                │ replace: update_all CAS (sensitive: true) -> {1,_} ok | {0,_} conflict
                                                │ ok: append :key_encrypted/:key_rewrapped audit row (same txn)
                                                v
                                       commit -> Observability.emit(:key, :encrypted|:rewrapped|...) after commit
 report map  ──> task prints key=value lines, Mix.raise on failed/conflicted

 signing path (six consumers) ──> PrivateJwk.decode/1 ──> decode_with_reason/1 (pure, cached keyset, refuses legacy under :reject)
                                         │ on {:ok, legacy}: :telemetry.execute [:lockspire,:key,:legacy_read] + dedupe warning
                                         └ on {:error, r}  : :telemetry.execute [:lockspire,:key,:decode_failed] + dedupe error
```

### Recommended Project Structure
```
lib/lockspire/
├── admin/keys.ex                      # + reencrypt/1, encryption_status/0 (delegating to helper)
├── admin/keys/reencrypt.ex            # NEW private helper (@moduledoc false): classify, report, row fun (discretion)
├── admin.ex                           # + @doc/@spec/defdelegate for both
├── protocol/private_jwk.ex            # + read_stored/2, refusal, hot-path telemetry in decode/1
├── storage/key_store.ex               # + list_signing_key_ids/2, reencrypt_signing_key/3 callbacks
├── storage/ecto/repository.ex         # + two @impl KeyStore one-line delegates
├── storage/ecto/repository/signing_key_store.ex   # + implementations
├── install/verify.ex                  # + :key_storage check; widen safely/1 rescue list
mix/tasks/
├── lockspire.keys.reencrypt.ex        # NEW
└── lockspire.doctor.key_encryption.ex # + with_repo + counts
test/support/key_encryption_helpers.ex # + reset_decode_warnings/0, seed helpers (legacy/ETF/old-KEK rows)
```

### Pattern 1: Storage callback owns lock + CAS + audit, Admin owns crypto (D-04)

Suggested callback contract (names are discretion; shapes are [ASSUMED] recommendations):
```elixir
# key_store.ex
@callback list_signing_key_ids(after_id :: integer(), limit :: pos_integer()) ::
            {:ok, [integer()]} | {:error, store_error()}
@callback reencrypt_signing_key(integer(), (SigningKey.t() -> reencrypt_decision()), keyword()) ::
            {:ok, reencrypt_outcome()} | {:error, store_error()}

# decision returned by the Admin.Keys-supplied function (runs INSIDE the row transaction, after the lock)
#   {:replace, new_binary, audit_event_map, info}  -> storage runs CAS then appends the audit event
#   {:keep, info}                                  -> no write (already current / no material)
#   {:fail, reason, info}                          -> no write, row counted failed
# outcome returned to Admin.Keys
#   {:replaced, info} | {:kept, info} | {:failed, reason, info} | :conflict | :not_found
```
Storage implementation sketch (inside `SigningKeyStore`, which already aliases `Support` and `TransactionStore`; call `AuditStore.append_audit_event/2` directly, an aggregate-to-aggregate call that keeps `Repository` free of Ecto constructs):
```elixir
def reencrypt_signing_key(repo, id, decide, _opts) when is_integer(id) and is_function(decide, 1) do
  TransactionStore.transact(repo, fn ->
    case locked_key(repo, id) do
      nil -> {:ok, :not_found}
      %SigningKeyRecord{} = record ->
        key = SigningKeyRecord.to_domain(record)
        case decide.(key) do
          {:keep, info} -> {:ok, {:kept, info}}
          {:fail, reason, info} -> {:ok, {:failed, reason, info}}
          {:replace, new, audit_event, info} -> cas_and_audit(repo, record, new, audit_event, info)
        end
    end
  end)
end

defp cas_and_audit(repo, record, new, audit_event, info) do
  query = from(k in SigningKeyRecord, where: k.id == ^record.id and k.private_jwk_encrypted == ^record.private_jwk_encrypted)
  case Support.update_all(repo, query, [set: [private_jwk_encrypted: new, updated_at: DateTime.utc_now()]], sensitive: true) do
    {1, _} ->
      case AuditStore.append_audit_event(repo, audit_event) do
        {:ok, _} -> {:ok, {:replaced, info}}
        {:error, reason} -> TransactionStore.rollback(repo, reason)
      end
    {0, _} -> {:ok, :conflict}
  end
end
```
CAS behaviour was exercised live: first `update_all` returned `{1, nil}`, a second identical CAS returned `{0, nil}`; `repo.transact(fn -> {:ok, 1} end)` returned `{:ok, 1}` [VERIFIED: local probe against `lockspire_test`, Ecto 3.13.6]. `TransactionStore.transact/2` returns `{:ok, result}` with `result` being whatever the inner fun returned (it unwraps `{:ok, result}` once via `run/2`), so return `{:ok, {:replaced, info}}` from the inner fun and match `{:ok, {:replaced, info}}` outside.

Note `info` and decisions carry only kid, ids, atoms. Never carry the new binary outside the callback result.

### Pattern 2: One shared stored-key reader (answers question 5, D-08)

Add to `PrivateJwk` a `@doc false` function that takes an **explicit** keyset and ignores mode and telemetry; make `decode_with_reason/1` a thin wrapper around it so legacy parsing exists once:
```elixir
@doc false
@spec read_stored(term(), KeySet.t() | nil) ::
        {:ok, map(), :legacy | {:envelope, String.t()}} | {:error, reason() | :unreadable_legacy}
def read_stored(%{kid: kid, private_jwk_encrypted: bin}, keyset) when is_binary(kid) and is_binary(bin) do
  case KeyEncryption.classify(bin) do
    :envelope -> read_envelope(kid, bin, keyset)      # {:ok, jwk, {:envelope, kek_id}}
    :legacy   -> read_legacy(bin)                     # {:ok, jwk, :legacy} | {:error, :unreadable_legacy}
    :invalid  -> {:error, :invalid_signing_key}
  end
rescue
  _ -> {:error, :invalid_signing_key}
end
```
`decode_with_reason/1` then becomes: read `keyset = Config.key_encryption_keyset()` **once**; if `classify == :legacy` and `match?(%KeySet{legacy_plaintext: :reject}, keyset)` return `{:error, :plaintext_key_refused}` before calling `read_stored`; otherwise `read_stored(row, keyset)` and drop the third tuple element. This keeps today's behaviour (legacy path has **no** kid check: `private_jwk_test.exs:10-11` decodes `%{kty: :RSA}` ETF with no `"kid"`).

Why this shape satisfies the architecture rules:
- `PrivateJwk` stays in `lib/lockspire/protocol/` and references no `Lockspire.Admin`/`Lockspire.Web` alias (`protocol_outer_reference?`, architecture_fitness_test.exs:294) [VERIFIED].
- `read_stored/2` takes the keyset as an argument, so it never reads the `:persistent_term` cache (D-05) and cannot emit hot-path telemetry (telemetry lives only in `decode/1`, D-24).
- "Only Admin.Keys calls it" cannot be enforced by visibility in Elixir. Enforce structurally: add a fitness test that greps `lib/**/*.ex` for `read_stored(` and asserts the only callers are `protocol/private_jwk.ex` and `admin/keys*.ex` (new test, in the style of `forbidden_decrypt_tokens`).
- The engine still needs the kid check for legacy rows (D-06). `read_stored/2` returns the raw map; the engine does `Map.get(jwk, "kid") == row.kid` itself.

### Pattern 3: Hot-path emission in `decode/1` only (D-24, D-27)

```elixir
def decode(%{kid: kid, private_jwk_encrypted: bin} = row) when is_binary(kid) and is_binary(bin) do
  case decode_with_reason(%{kid: kid, private_jwk_encrypted: bin}) do
    {:ok, jwk} -> note_read(kid, bin); {:ok, jwk}      # emits legacy_read only when classify(bin) == :legacy
    {:error, reason} -> note_failure(kid, bin, reason); {:error, :invalid_signing_key}
  end
end
```
- `legacy_read` metadata exactly `%{kid: kid, legacy_plaintext: :allow}`; `decode_failed` metadata exactly `%{kid: kid, reason: reason}` plus `kek_id` only when `KeyEncryption.envelope_kek_id(bin)` returns `{:ok, id}`.
- Pass metadata through `Redaction.for_telemetry/1` [VERIFIED: it drops `nil` values, hashes only `family_id`, and its drop list does not contain `:kid`, `:kek_id`, `:reason`, `:legacy_plaintext`; it **does** drop `:state` and `:token` keys, so never name a metadata key `state`] (redaction.ex).
- Dedupe flag: `:persistent_term.get({Lockspire, :key_decode_warned, kid, reason}, nil)`; only `put` when absent (a `put` over an existing key triggers a global GC scan; at tens of keys this is moot but keep it write-once).
- `decode/1` is also used for `use: :enc` keys in JAR (`jar.ex:43`, a `with` inside a reduce). JAR's own JOSE `block_decrypt` failure is outside `PrivateJwk`, so it never emits `decode_failed` (D-21 satisfied by construction) [VERIFIED: jar.ex:41-53].

### Pattern 4: Engine classification (inside the row fun, after lock)

For one locked `%SigningKey{kid, private_jwk_encrypted}` and `keyset` (fresh from `Config.key_encryption!/0`):
1. `nil` → `{:keep, %{class: :no_private_key}}`.
2. `KeyEncryption.classify/1`:
   - `:envelope` → `KeyEncryption.envelope_kek_id/1` then `KeyEncryption.open(keyset, kid, bin)` (which fetches by the header id), JSON-decode, require `"kid" == row kid`. If the kek id == `keyset.current_id` → `{:keep, :already_current}`; if another configured id → seal with `KeyEncryption.seal(keyset, kid, plaintext)` (seals under current), round-trip verify, `{:replace, …}`; unknown id or open failure → `{:fail, reason, %{kek_id: id}}` with `:unknown_kek | :decryption_failed | :malformed_envelope | :kid_mismatch`.
   - `:legacy` → `PrivateJwk.read_stored/2` → map; require `"kid"` equals row kid; `Jason.encode!/1` (rescue encode errors → `:unreadable_legacy`); seal; round-trip verify; `{:replace, …}`.
   - `:invalid` → `{:fail, :malformed_envelope, …}` is not reachable (non-binary column); treat as `:unreadable_legacy`.
3. Round-trip verify: `KeyEncryption.open(keyset, kid, new)`, `Jason.decode`, `"kid"` equals row kid; mismatch → `{:fail, :roundtrip_failed, …}` (atom names are discretion; [ASSUMED]).
4. Test-only after-lock hook: read `Keyword.get(opts, :after_lock)` (or similar internal key) inside the row fun, **after** the lock and **before** classification (so B's classification sees A's commit). `@doc false`, undocumented in `@doc` for `reencrypt/1`.

`encryption_status/0` reuses the same primitives but never writes and never takes a lock (D-11).

### Pattern 5: Repo lifecycle detection for `{:error, :repo_not_started}` (question 2)

`Ecto.Repo.all_running/0` exists [VERIFIED: deps/ecto/lib/ecto/repo.ex:246-247, delegates to `Ecto.Repo.Registry.all_running/0`] and returned `[]` with no repo started [VERIFIED: local probe]. `Process.whereis(repo)` works for a normally named repo (`Lockspire.TestRepo` returned `nil` before `with_repo`, a pid-less registry afterward). Recommend `Process.whereis(Config.repo!()) == nil` (cheap, no dependency on Ecto internals). Repo name is the module for repos started the standard way; dynamic repos with `name:` overrides are out of scope [ASSUMED].

### Pattern 6: Mix task skeleton (D-14, D-15)

```elixir
defmodule Mix.Tasks.Lockspire.Keys.Reencrypt do
  use Mix.Task
  @shortdoc "Re-encrypts stored signing keys under the current key-encryption key"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: [dry_run: :boolean, check: :boolean, help: :boolean])
    validate!(opts, argv, invalid)                      # Mix.raise BEFORE any repo access
    if opts[:help], do: Mix.shell().info(help()), else: execute(opts)
  end

  defp execute(opts) do
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    case Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _repo -> work(opts) end, mode: :temporary) do
      {:ok, result, _apps} -> finish(result)           # print + Mix.raise OUTSIDE with_repo so the repo is stopped first
      {:error, _term} -> Mix.raise("could not start the repo; check database connectivity")
    end
  end
end
```
Verified: `ecto.migrate` itself uses `{:ok, _} = Application.ensure_all_started(:ecto_sql)` and `Ecto.Migrator.with_repo(repo, fun, [mode: :temporary] ++ opts)` [VERIFIED: deps/ecto_sql/lib/mix/tasks/ecto.migrate.ex:137,151]. `with_repo/3` returns `{:ok, fun_return, apps}` or `{:error, term}`; default `pool_size` is 2; `:mode` defaults to `:permanent` [VERIFIED: deps/ecto_sql/lib/ecto/migrator.ex:131-148]. Keep the default pool size (the engine is sequential).

### Anti-Patterns to Avoid
- **Raising `Mix.raise` inside the `with_repo` fun** for per-row failures: compute the report, return from `with_repo` (repo stopped in its `after`), then print and raise.
- **`Logger`/`inspect` of any exception or row** in decode or engine paths (D-27, D-28). Map storage exceptions to an atom (`:storage_error`) in the engine; the `TransactionStore.transact/2` `rescue` hands back the raw exception struct, which must never be printed or placed in telemetry.
- **Using the `:persistent_term` keyset in the engine** (D-05). `KeyEncryptionHelpers.seal_private_jwk/2` deliberately uses the cached set; do not reuse it for engine assertions about fresh-config behaviour.
- **`Check` statuses beyond `:ok | :error`** for the Verify "skipped" case.
- **`with_repo` when the repo is already running** (restart side effect). Guard it.
- **Comments with planning vocabulary** (`D-08`, `Phase 157`, `WR-02`): fail `ReadabilityContractTest` for every `lib/**` file including Mix task help text.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Row exclusion between concurrent runs and `activate` | Advisory locks, `SKIP LOCKED`, retry loops | `lock("FOR UPDATE")` on a single row per transaction (existing `locked_key/2`) | One lock held per txn cannot deadlock; READ COMMITTED re-reads the committed row after the wait (D-01/D-02) |
| Concurrent-write guard | Version column / `kek_id` column | `update_all … where private_jwk_encrypted == ^old` | SAFE-01 forbids a migration; verified `{1,_}`/`{0,_}` behaviour |
| Starting the repo in a Mix task | `app.start`, manual `Repo.start_link` | `Ecto.Migrator.with_repo/3` with `mode: :temporary` | Mirrors `ecto.migrate`; stops the repo; avoids booting Endpoint/Oban |
| Envelope crypto, kid-bound AAD | New AEAD code | `KeyEncryption.seal/3`, `open/3`, `envelope_kek_id/1` | Phase 155 owns the format; AAD binds header and kid |
| Audit persistence and redaction | Direct inserts | `Repository.append_audit_event/1` + `Event.normalize` (runs `Redaction.for_audit`) | Existing durable audit contract |
| Operator telemetry + audit mirror | `:telemetry.execute` for operator events | `Observability.emit(:key, action, measurements, metadata)` | Existing naming/redaction (D-25) |
| Safe ETF decode | `:erlang.binary_to_term/1` | `Plug.Crypto.non_executable_binary_to_term(bin, [:safe])` (already in `PrivateJwk`) | Prevents atom/exec injection from stored rows |
| CLI parsing | Manual argv matching | `OptionParser.parse(strict: …)` + reject `argv != []` | Typo `check` must never trigger a write (D-14) |

**Key insight:** every dangerous primitive (lock, CAS, AEAD, safe ETF, redaction) already exists. The phase's risk is in composition: logging params, repo lifecycle, lock ordering, and leak surfaces, not in new algorithms.

## Runtime State Inventory

Not a rename phase, but it migrates stored data, so the relevant categories are answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `lockspire_signing_keys.private_jwk_encrypted` (bytea): legacy JSON, legacy ETF, `LSK\x01` envelopes under old/current/unknown KEK ids, `NULL`. No `kek_id` column exists and none may be added | Engine rewrites only this column + `updated_at` (data migration, not a code edit). Dry-run/`--check` are read-only |
| Live service config | None — verified: no external service stores key rows; JWKS/discovery serve public members only and never decrypt (architecture_fitness_test.exs:50-69) | None |
| OS-registered state | None — the task is invoked on demand (no scheduler, no pm2/systemd registration) | None |
| Secrets / env vars | `config :lockspire, :key_encryption` (`keys`, `current`, `legacy_plaintext`) read at boot into `:persistent_term` (application.ex `validate_key_encryption!/0`); mode changes need a restart of every node (D-22) | No env var rename. Help text must state rotation/rollout order |
| Build artifacts | Boot-cached keyset in each running node: a node started before a config change keeps the old set until restart; `publish_key` upserts `ON CONFLICT (kid)` replacing all columns, so a stale seed script can re-plant plaintext after migration | `--check`/doctor/Verify detect re-planted plaintext; no artifact to reinstall |

## Common Pitfalls

### Pitfall 1: Ecto query log leaks plaintext/ciphertext params
**What goes wrong:** `update_all(… where private_jwk_encrypted == ^old …)` logs `old` (legacy plaintext JWK, including `d`) at debug level in any host with repo logging on.
**Why:** Ecto logs query parameters; only `Support.repo_options` with `sensitive: true` sets `log: false` (support.ex:32-41).
**Avoid:** pass `sensitive: true` on the CAS `update_all` and the locked read (`Support.one(repo, q, sensitive: true)`); add a test that attaches a Logger/telemetry handler for `[:lockspire, :test_repo, :query]`-style events or asserts `log: false` by capturing log at `:debug` in a repo-enabled test.
**Warning sign:** a captured log containing `"d"` or raw bytes after a re-encrypt run.

### Pitfall 2: `with_repo/3` restarts an already-running repo
**What goes wrong:** Calling `with_repo` from Verify/doctor while the repo is up returns `{:ok, :restart}` internally and runs `Supervisor.restart_child` afterward, dropping pooled connections (and sandbox ownership in tests).
**Avoid:** `if Process.whereis(repo), do: fun.(repo), else: with_repo(…)` in a shared private helper for doctor and Verify. The Mix task itself is only ever run on a cold VM, so it uses `with_repo` unconditionally (and the not-started test path proves it) [VERIFIED: migrator.ex:817-828, 847-852; local probe confirmed `with_repo` while running executes the function and leaves the repo running].

### Pitfall 3: Verify crashes on a DB error and cannot express "skipped"
See summary item 3. `migration_status/2` raises `MatchError` on `{:error, _}` and DB exceptions escape `safely/1`. **Avoid:** widen `safely/1` to also rescue `MatchError`, `DBConnection.ConnectionError`, `Postgrex.Error` (benefits the existing migrations check); the new check rescues **everything** (`rescue _ -> :unreadable`) and reports `Check.ok(:key_storage, "Stored key encryption was not inspected", "skipped: database unreadable or migrations pending; see the migrations check", fix)`, so `ok?` is decided by the migrations check alone (non-duplicating).

### Pitfall 4: `list_signing_keys/1` stores errors as values
`SigningKeyStore.list_signing_keys/2` has `rescue error -> {:error, error}`, so a `DBConnection.ConnectionError` or an `undefined_table` `Postgrex.Error` arrives as `{:error, exception}`, not a raise. `encryption_status/0` must map any `{:error, _}` to `{:error, :storage_unavailable}` (atom only) and doctor/Verify print a fixed sentence, never `Exception.message/1` of a storage exception.

### Pitfall 5: Legacy `:enc` rows without `"kid"` cannot be migrated
`request_object_test.exs:35` seeds a legacy `use: :enc` row whose ETF map comes straight from `JOSE.JWK.to_map` (no `"kid"`). D-06 requires `"kid"` equal to the row kid and forbids kid injection, so such rows are reported `failed` (`:kid_mismatch`) and stay legacy; under `:reject` they are refused at read. The fix line must tell the operator to retire the key and generate a replacement (`Admin.generate_key(:enc)`). Not a bug; surface it in fix text and in the test matrix (D-30 already includes "missing or mismatched kid").

### Pitfall 6: Atom-keyed ETF legacy maps
`private_jwk_test.exs:11` shows `%{kty: :RSA}` decodes today. The engine's `Map.get(jwk, "kid")` is `nil` for atom-keyed maps, so they classify as `:kid_mismatch`. Consistent with D-06; mention in help/fix text only as "stored key cannot be read; retire it and generate a replacement".

### Pitfall 7: Hot-path telemetry and logs inflate in tests and fail leak checks
Existing `private_jwk_test.exs` "fails closed" cases (lines 46-60) will now emit `decode_failed` and `Logger.error` once per `{kid, reason}`. Because the dedupe flag is a `:persistent_term`, behaviour depends on test order. **Avoid:** add `reset_decode_warnings/0` to `KeyEncryptionHelpers` (`for {{Lockspire, :key_decode_warned, _, _} = k, _} <- :persistent_term.get(), do: :persistent_term.erase(k)`), call it in `setup` of every test that asserts on logs/telemetry, and wrap noisy existing tests in `ExUnit.CaptureLog.capture_log/1`.

### Pitfall 8: Redaction side effects on new metadata
`Redaction.for_telemetry/1` drops `nil` values (so `previous_kek_id: nil` disappears: desired for `:encrypted`), drops keys named `state`, `token`, `params`, etc. Use `status`, never `state`. `pending: [%{kid, state}]` in the status map is not telemetry; do not forward it. `:reencrypt_completed` count measurements: `Observability.emit/4` does `Map.put_new(:count, 1)`, so a report with its own `count` key must not be passed or the `count` semantics clash; use `scanned/encrypted/rewrapped/…` names plus `duration`.

### Pitfall 9: Atoms and exception structs in `{:error, exception}` from the transaction
`TransactionStore.transact/2` rescues and returns `{:error, %SomeException{}}`. The engine must translate any non-atom error into `:storage_error` before it reaches `failed: [%{kid, reason, kek_id}]`, output, or events.

### Pitfall 10: Non-integration tests pass through committed state
The unit-suite `Install.Verify` test "returns a passing result set for a wired host router" (verify_test.exs:222-233) asserts `Enum.all?(result.checks, &(&1.status == :ok))` against the **real, committed** DB via `with_repo`. A new DB-backed check will read whatever committed rows exist (e.g. leftovers from integration tests that don't clean up). **Avoid:** give `Verify.run/1` an injectable status source (`opts[:key_storage_status]`, a zero-arity fun, default = real call) so unit tests use fabricated status maps; one integration test covers the real DB.

### Pitfall 11: Sequential `scanned` across concurrent runs
`scanned` must count ids visited (including `already_current`/`no_private_key`), not rows changed, so both concurrent runs report equal `scanned` (D-02/D-29). A row deleted between id listing and lock yields `:not_found`; recommend counting it into `conflicted` (OQ-2).

## Code Examples

### `encryption_status/0` skeleton
```elixir
@spec encryption_status() :: {:ok, map()} | {:error, :storage_unavailable | {:invalid_config, String.t()}}
def encryption_status do
  with {:ok, keyset} <- fresh_keyset(),                 # Config.key_encryption!/0, rescue ArgumentError -> {:invalid_config, message}
       {:ok, rows} <- Repository.list_signing_keys() do # returns full rows incl. private_jwk_encrypted
    {:ok, build_status(keyset, rows)}
  else
    {:error, %{__exception__: true}} -> {:error, :storage_unavailable}
    {:error, _} = error -> error
  end
end
```
`ArgumentError` messages from `Config.key_encryption!/0` name config keys only, never values [VERIFIED: config.ex:284-289, so including the message is safe].

Status semantics to implement (all from D-11):
- No KEK configured: `configured: false`, `ready?: false`; envelope rows counted in `unknown_kek` by header id (`KeyEncryption.envelope_kek_id/1`); legacy counted in `legacy`.
- Envelope, id configured: `open/3`; ok + kid match → `by_kek_id[id] += 1`; failure (incl. `:kid_mismatch`) → `undecryptable += 1` (pending state `:undecryptable`).
- Envelope, id not configured → `unknown_kek[id] += 1`.
- `ready?` = `configured and legacy == 0 and unknown_kek == %{} and undecryptable == 0 and every material row on current_kek_id`.
- `pending` lists `%{kid, state}` where state ∈ `:legacy | :other_kek | :unknown_kek | :undecryptable` (atoms [ASSUMED]).

### Telemetry exact-key-set assertion (test)
```elixir
TelemetryCapture.attach_many([[:lockspire, :key, :decode_failed]])
assert {:error, :invalid_signing_key} = PrivateJwk.decode(row)
assert_receive {:telemetry_event, [:lockspire, :key, :decode_failed], %{count: 1}, meta}
assert Enum.sort(Map.keys(meta)) == [:kek_id, :kid, :reason]
```

### Mix task e2e without a pre-started repo (question 3)

The test app boots `Lockspire.Application` only; **TestRepo is not started by the app**. Each DB test starts it itself (`start_supervised!(Lockspire.TestRepo)` in `setup_all`, e.g. `repository_concurrency_test.exs:15-19`; `data_case.ex` assumes it is already running), and the unit-suite verify tests rely on `with_repo`. I verified that `Ecto.Migrator.with_repo(TestRepo, fun, mode: :temporary)` **commits** (insert in one `with_repo`, read back in a second one) even though `config/test.exs` sets `pool: Ecto.Adapters.SQL.Sandbox`, because a freshly started sandbox pool is in `:auto` mode [VERIFIED: local probe: `rows after restart: [[1]]`].

Proposed approach for `test/mix/tasks/lockspire_keys_reencrypt_test.exs`:
1. Argument-validation tests (no DB): `Mix.Task.reenable("lockspire.keys.reencrypt")`; `assert_raise Mix.Error, ~r/…/, fn -> Mix.Task.run("lockspire.keys.reencrypt", ["check"]) end` (positional), `["--bogus"]`, `["--check", "--dry-run"]`. These raise before `with_repo`, so they run in the default unit suite.
2. `describe "end to end" ` tagged `@moduletag :integration`, `async: false`, in a **separate module** so no `setup_all` starts TestRepo:
   ```elixir
   setup do
     refute Process.whereis(Lockspire.TestRepo), "repo must be stopped so the task must start it itself"
     kids = seed_rows()   # via Ecto.Migrator.with_repo(TestRepo, fn repo -> ... Repository.publish_key ... end, mode: :temporary)
     on_exit(fn -> cleanup(kids) end)  # again via with_repo; delete signing rows + audit rows by kid/resource ids
     Mix.Task.reenable("lockspire.keys.reencrypt")
     :ok
   end
   ```
   Then `output = capture_io(fn -> Mix.Task.run("lockspire.keys.reencrypt", []) end)`, assert key=value lines and `refute Process.whereis(TestRepo)` afterwards (proves `with_repo` stopped it), and read-back the rows through a second `with_repo` to assert envelopes. For exit-1: seed an unknown-KEK row, `assert_raise Mix.Error`, then read-back proves the other rows were saved.
3. Run this module alone (`mix test --only integration test/mix/tasks/lockspire_keys_reencrypt_test.exs`). Because `test_helper.exs` excludes `:integration` unless a `.exs` path argument or `--include integration` is passed, it also runs when a file path is given [VERIFIED: test/test_helper.exs].
4. Optional second not-started test at the API layer in the default suite: `Process.whereis(TestRepo) == nil` ⇒ `assert {:error, :repo_not_started} = Lockspire.Admin.Keys.reencrypt()` (needs no DB).

Caveat: committed rows pollute shared state; clean by `kid` prefix (e.g. `"mig-task-" <> suffix`) plus audit rows (`action in ["key_encrypted","key_rewrapped"]` and `resource_id` in the row ids). Never `delete_all(SigningKeyRecord)` (that is what `SeedingHelpers.seed_signing_key/1` does and would race other modules).

### Concurrency test determinism (D-29)
Use `unboxed_run` for each contender; the hook inside the row fun sends `{:locked, self()}` and blocks on `receive do :release -> :ok end`. To assert "B is blocked" without sleeps, poll `pg_stat_activity` via an unboxed query for a backend with `wait_event_type = 'Lock'` (retry up to ~2s) before releasing A [ASSUMED: standard Postgres view; not exercised here]. After release: A `encrypted == N`, B `already_current == N`, equal `scanned`, and re-read each row: `KeyEncryption.open` then `Jason.decode` gives a map with `"kid" == row.kid` and the envelope header has exactly one `LSK` prefix (no double wrap).

## Verify, doctor and PrivateJwk answers (questions 4, 5, 6)

**Verify DB check (question 4).** Add `key_storage_check(opts)` to `config_checks`/`run/1` (new id `:key_storage`; update the id enumeration at verify_test.exs:271-282). Flow: obtain status via `Keyword.get(opts, :key_storage_status, &default_status/0)`. `default_status/0` runs `Admin.Keys.encryption_status/0`, wrapped by the "repo running?" guard from Pitfall 2 and `rescue _ -> {:error, :unreadable}`. Mapping:
- `{:error, _}` (unreadable DB, pending migrations, invalid config) → `Check.ok` "not inspected", details `"skipped: …"` (the migrations/key_encryption checks already own those errors).
- status with any `unknown_kek` entry or `undecryptable > 0` → `Check.error` (details: counts and kek ids only).
- `legacy_plaintext == :reject and legacy > 0` → `Check.error`.
- otherwise `Check.ok` with counts in details (legacy rows under `:allow` stay ok).
No new rescue list for `safely/1` is strictly needed for the new check, but widening `safely/1` (add `MatchError`, `DBConnection.ConnectionError`, `Postgrex.Error`) fixes the pre-existing crash in the migrations check, which D-19 explicitly calls out. Recommend doing both; update/add a test asserting a bogus repo yields an error result instead of a raise.

**Doctor.** Keep the existing first line (`key_encryption: configured current=… ids=… legacy_plaintext=…`, asserted by `lockspire_doctor_key_encryption_test.exs`). After it, run status inside `with_repo` (guarded as above), print `rows: total=… legacy=… no_private_key=… on_current=… other_kek=… unknown_kek=… undecryptable=…` plus per-id `kek=<id> rows=<n>` lines and a hint when `legacy + other_kek > 0`. Exit 1 only for invalid/missing config (existing), unreadable DB, any `unknown_kek` or `undecryptable`. With no KEK it must still print the legacy count **before** raising (`Mix.raise` after the output). Update the existing tests (they currently run with no repo started and expect clean output): either set `put_key_encryption` and seed nothing (empty table), or tag DB-backed doctor cases `:integration`. The existing "reports the configured key set" test will start doing a `with_repo` DB read in the default suite; that is acceptable because verify_test already does it, but flag it.

**telemetry docs (question 6).** `docs/telemetry.md` has no `[:lockspire, :key, …]` section today (grep found none) yet calls itself exhaustive, and the file is in `mix.exs` docs extras. CONTEXT says touch it only if 156 touches it. Recommendation: **do not touch `docs/telemetry.md` in 156**; the Phase 157 docs sweep adds the whole `:key` family at once (legacy_read, decode_failed, encrypted, rewrapped, reencrypt_failed, reencrypt_completed plus the existing four). Record the six new event names in the 156 SUMMARY so 157 has the list. [ASSUMED: no docs-contract test currently diffs emitted events against `docs/telemetry.md`; `grep` for `telemetry.md` in test/lib/scripts only matched `mix.exs`.]

**ROADMAP/REQUIREMENTS wording (D-23).** Plans should include a docs task editing `.planning/ROADMAP.md` Phase 156 criterion 5 (line ~102) and `.planning/REQUIREMENTS.md` OPS-02 (line 31): "Encrypt and re-wrap emit durable audit records and telemetry; legacy-read, refusal and decryption-failure emit telemetry only, all carrying only `kid`, KEK id, counts and reason atoms." Also criterion 1's "locked-batch" in the 156-01 plan bullet (ROADMAP line ~110) should read "per-row locked transaction".

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Repo.transaction/2` | `Repo.transact/2` (3.13+), `transaction/2` deprecated in 3.14 per Ecto docs | Ecto 3.13/3.14 | `transact/2` already exists in the locked 3.13.6; migrating `TransactionStore` is optional and non-trivial (return shape); leave |
| Brute-force re-encryption (Cloak) | Classify + per-row lock + CAS + report | n/a | This phase's design (see DISCUSSION-LOG precedents) |

**Deprecated/outdated:** none relevant to the locked stack.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Storage callback names/shapes (`list_signing_key_ids/2`, `reencrypt_signing_key/3`, decision tuples) | Pattern 1 | Cosmetic; discretion per CONTEXT |
| A2 | Failure reason atoms `:unreadable_legacy`, `:roundtrip_failed`, `:storage_error`, pending state atoms | Patterns 2/4, Pitfalls | Cosmetic; discretion per CONTEXT; fix lines depend on final names |
| A3 | `Process.whereis(repo)` is a sufficient "repo running" test (no dynamic `name:` repos) | Pattern 5 | A host with a renamed repo would see a false `:repo_not_started`; mitigate by also accepting `repo in Ecto.Repo.all_running()` |
| A4 | `pg_stat_activity.wait_event_type = 'Lock'` poll gives a deterministic "B is blocked" assertion | Concurrency test | If flaky, fall back to a bounded `Task.yield/2` assertion plus the after-lock hook ordering |
| A5 | No test diffs emitted telemetry events against `docs/telemetry.md` | Telemetry docs | If one exists, 156 must add the docs section |
| A6 | Unit-suite `Install.Verify` and doctor tests tolerate a DB read against committed state | Pitfall 10 | Spurious red tests if integration leftovers exist; mitigated by injectable status for Verify |
| A7 | Page size ~100 is irrelevant at tens of rows | Engine | None functionally |

## Open Questions

1. **OQ-1: Second `KeyStore` callback for id paging.**
   - Known: D-01 says candidate ids are read in keyset pages; no existing store method returns ids; `list_signing_keys/1` returns whole rows.
   - Unclear: whether to add a trivial `list_signing_key_ids/2` callback (+ delegate) or list rows once.
   - Recommendation: add the callback (honours D-01, costs ~10 lines, covered automatically by the architecture "behavior-complete facade" test). If the planner prefers fewer moving parts, `list_signing_keys/0` + `Enum.map(& &1.id)` is functionally equivalent at tens of rows; note it as a deliberate D-01 simplification.
2. **OQ-2: Count for a row that vanishes between id listing and the lock (`:not_found`).**
   - Recommendation: count it in `conflicted` (rerun is safe, row is gone or changed).
3. **OQ-3: `Lockspire.Admin` doctests/`@spec` for `reencrypt/1` report type.**
   - Recommendation: define `@type reencrypt_report` and `@type encryption_status` in `Admin.Keys` and reference them from `Admin` defdelegate specs.
4. **OQ-4: Whether to also fix the same `with_repo` restart behaviour in `migration_status/2`.**
   - Recommendation: yes, reuse the shared guard in the same plan (same function being touched for `safely/1`).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | integration tests, `with_repo` probes | ✓ | accepting connections at `/tmp:5432` [VERIFIED: `pg_isready`] | — |
| `lockspire_test` database | all DB tests | ✓ | migrated (concurrency integration test passed this session) | `mix test.setup` |
| asdf Elixir 1.19.5-otp-28 + Erlang 28.4.1 | CI-equivalent local runs | ✓ | `asdf list elixir` shows 1.19.5-otp-28; `mix test` of 12 tests + the concurrency integration test passed this session | 1.20.4-otp-29 (see note) |
| asdf Elixir 1.20.4-otp-29 + Erlang 29.1.1 | Phase 155 local runs | ✓ | listed by asdf | — |
| `HEX_HOME=/private/tmp/lockspire-hex` | offline-safe deps | ✓ | `cache.ets`, `packages` present | — |

**Missing dependencies with no fallback:** none.

**Note on toolchain:** Phase 155 used `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1` (155-VALIDATION.md). Project memory says CI runs qa/e2e on 1.19.5-otp-28 because local 1.20.4 type warnings fail `--warnings-as-errors`. This session compiled and ran tests on 1.19.5-otp-28 successfully (first run recompiled deps for that toolchain, about 2 minutes). Use 1.19.5-otp-28 for `mix qa`, `mix qa.dialyzer`, `mix test.clean-room.e2e`; 1.20.4-otp-29 is fine for plain `mix test` but switching toolchains triggers a full recompile of `_build/test`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5/OTP 28 in CI) + StreamData already in deps |
| Config file | `config/test.exs` (KEK ids `test-1`/`test-2`, `legacy_plaintext: :allow`, Sandbox pool) |
| Env | `export HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1` |
| Quick run command | `mix test <touched test files>` (a `.exs` path argument also un-excludes `:integration` tests in that file) |
| Integration command | `mix test --only integration <path>` (CI partition runs `mix do test.setup + test --only integration` across all of `test/`) |
| Full suite command | `MIX_ENV=test mix test.fast` (alias: `test.setup` then `test test/lockspire test/mix test/integration`) |
| Gates | `mix qa` (format, `compile --warnings-as-errors`, `qa.architecture`, credo `--strict`, sobelow), `mix qa.dialyzer` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MIG-01 | Rotation/migration matrix: legacy JSON, legacy ETF→JSON, old-KEK, new-KEK, nil, unknown-KEK, kid-less legacy, all statuses and both `use` values; idempotent second run; dry-run writes nothing (rows byte-identical, zero audit rows) | unit (sandbox, single process) | `mix test test/lockspire/admin/keys_reencrypt_test.exs` | ❌ Wave 0 |
| MIG-01 | CAS `{0,_}` branch; same-row double-run no double wrap | unit/integration | `mix test --only integration test/lockspire/storage/reencrypt_concurrency_test.exs` | ❌ Wave 0 |
| MIG-01 | Two overlapped runs (after-lock hook) and 5–10 contender barrier: `encrypted+rewrapped == initial stale`, equal `scanned`, one `LSK` layer | integration | same file as above | ❌ Wave 0 |
| MIG-01 | Task end to end with repo not started: output lines, exit codes (real/dry-run), persisted rows, repo stopped afterwards; arg rejection | unit + integration | `mix test --only integration test/mix/tasks/lockspire_keys_reencrypt_test.exs` | ❌ Wave 0 |
| MIG-02 | `encryption_status/0` counts, deep open (same-id wrong material, tamper, kid_mismatch → `undecryptable`), no-KEK shape, `ready?` | unit | `mix test test/lockspire/admin/keys_encryption_status_test.exs` | ❌ Wave 0 |
| MIG-02 | `--check` exit 1 until ready; agreement `--check`/doctor/Verify on the same fixture set | integration | `mix test --only integration test/mix/tasks/lockspire_keys_reencrypt_test.exs test/mix/tasks/lockspire_doctor_key_encryption_test.exs` | ❌ Wave 0 / extend |
| MIG-02 | Verify `:key_storage`: ok under `:allow` with legacy; error on unknown/undecryptable or `:reject` with legacy; "skipped ok" on DB error; `safely/1` widened | unit (injected status) + one integration | `mix test test/lockspire/install/verify_test.exs` | extend |
| MIG-03 | Under `:reject`, legacy refused with `:plaintext_key_refused` **before** `Jason.decode`/ETF parser (use a legacy payload that would raise/emit if parsed, e.g. invalid JSON + invalid ETF: result is `:plaintext_key_refused`, not `:invalid_signing_key`); envelope still signs; `:enc` rows refused; nil keyset keeps legacy path; external collapse unchanged | unit (non-async) | `mix test test/lockspire/protocol/private_jwk_test.exs` | extend |
| MIG-03 | All six consumers still return their documented error shape under `:reject` | unit | `mix test test/lockspire/protocol` | extend |
| MIG-03 | Engine recovers a legacy row under `:reject` (no config change) | unit | keys_reencrypt_test.exs | ❌ Wave 0 |
| OPS-01 | Rotation matrix: rows on k1/k2/legacy × current k1/k2 → all rows end on current, same `kid`s, still sign (`PrivateJwk.decode` ok); five-step order help text present | unit | keys_reencrypt_test.exs; `mix test test/mix/tasks/lockspire_keys_reencrypt_test.exs` | ❌ Wave 0 |
| OPS-02 | Exact metadata key sets per event (`legacy_read`, `decode_failed`, `encrypted`, `rewrapped`, `reencrypt_failed`, `reencrypt_completed`); both `[:lockspire,…]` and `[:lockspire,:audit,…]` paths for operator events; hot-path events have **no** audit mirror and **no** audit row | unit | `mix test test/lockspire/security/key_encryption_telemetry_test.exs` | ❌ Wave 0 |
| OPS-02 | Durable audit rows `key_encrypted`/`key_rewrapped` with exact metadata, written in the row txn (rolled back with it); none for dry-run/check/failed rows | unit | keys_reencrypt_test.exs | ❌ Wave 0 |
| OPS-02 / C8 | Sentinel leak test: known `d` value + KEK across legacy read, refusal, each failure reason, encrypt, re-wrap; assert absent from telemetry (both paths), audit rows, captured logs (`capture_log` at `:debug`), task output | unit | `mix test test/lockspire/security/key_material_leak_test.exs` | ❌ Wave 0 |
| D-27 | Logger once per node per `{kid, reason}`; warning only when KEK configured; reset helper | unit | private_jwk_test.exs / telemetry test | extend |
| Architecture | `read_stored` callers restricted; Repository delegates both new callbacks; protocol files still reference no `Admin`; no Ecto constructs in `repository.ex` | structural | `mix test test/lockspire/architecture_fitness_test.exs` | extend |
| SAFE-01 | No dep/migration/column change | structural | `git diff --exit-code -- mix.exs mix.lock priv/repo/migrations` in the plan's acceptance step | n/a |
| Readability | No planning markers in new `lib/` text | structural | `mix test test/lockspire/readability_contract_test.exs` | existing |

### Sampling Rate
- **Per task commit:** `mix test <the task's test files>` (target under 30 s each; the integration files add a few seconds).
- **Per wave merge:** `MIX_ENV=test mix test.fast` plus `mix test --only integration` on the three new integration files; `mix qa`.
- **Phase gate:** `mix qa`, `mix qa.dialyzer`, `MIX_ENV=test mix test.fast`, `MIX_ENV=test mix test.integration`, and `mix test.clean-room.e2e` (unchanged-behaviour guard for signing paths) green on 1.19.5-otp-28 before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/lockspire/admin/keys_reencrypt_test.exs` (MIG-01, OPS-01, MIG-03 recovery, audit rows)
- [ ] `test/lockspire/admin/keys_encryption_status_test.exs` (MIG-02)
- [ ] `test/lockspire/storage/reencrypt_concurrency_test.exs` (`@moduletag :integration`, D-29)
- [ ] `test/mix/tasks/lockspire_keys_reencrypt_test.exs` (arg validation unit; e2e integration, D-31)
- [ ] `test/lockspire/security/key_encryption_telemetry_test.exs` (exact key sets, no audit mirror on hot path)
- [ ] `test/lockspire/security/key_material_leak_test.exs` (sentinel, D-28)
- [ ] `test/support/key_encryption_helpers.ex`: add `reset_decode_warnings/0`, a `seed_row/…` helper for legacy-JSON, legacy-ETF, old-KEK envelope (build with `KeyEncryption.seal(test_keyset…)` using the **same** `test-1`/`test-2` material as `config/test.exs`, i.e. `:crypto.hash(:sha256, "lockspire-test-kek-1") |> Base.encode64()`, not `test_keyset/1`'s `"helper-kek-…"` material, D-30)
- [ ] Extend: `private_jwk_test.exs`, `verify_test.exs`, `lockspire_doctor_key_encryption_test.exs`, `architecture_fitness_test.exs`
- No framework install needed.

## Security Domain

`security_enforcement` is not set to `false` in `.planning/config.json` (key absent), so it is enabled. ASVS Level 1; block on high.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (no auth surface added; operator invocation is host/OS access) | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (limited) | Operator-only entry points (Mix task / release rpc / `Lockspire.Admin`); no HTTP route, no admin UI (SAFE-01). Hot path has no write side effects |
| V5 Input Validation | yes | Strict `OptionParser`, positional/unknown rejection; stored-row parsing via `Plug.Crypto.non_executable_binary_to_term(…, [:safe])`; row `kid` equality before sealing |
| V6 Cryptography | yes | Existing AES-256-GCM `KeyEncryption` (kid-bound AAD, fresh IV per seal); no new crypto; round-trip verify before write; never hand-roll |
| V7 Error Handling and Logging | yes | Allowlisted metadata, `sensitive: true` DB calls, atom-only reasons, no `inspect` of rows/exceptions, deduped single log line |
| V8 Data Protection | yes | Private JWK plaintext eliminated at rest; refusal mode; no decrypted-key cache |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation | Decision / Check |
|---------|--------|---------------------|------------------|
| Plaintext JWK/`d` leaks via telemetry or Logger | Information disclosure | Fixed allowlisted metadata through `Redaction.for_telemetry/1`; Logger prints kid + reason atom only; never place `SigningKey`/`KeySet`/decoded JWK in metadata | D-24, D-27, D-28; sentinel leak test (key_material_leak_test.exs) |
| Plaintext/ciphertext in Ecto query logs (CAS `where` param) | Information disclosure | `Support.update_all(…, sensitive: true)` (`log: false`) on engine writes and locked reads | Pitfall 1; assert via captured debug log |
| Plaintext/KEK in CLI output or audit rows | Information disclosure | Print raw `kid` (public in JWKS), KEK **id** only, never values/lengths/ciphertext; audit metadata allowlist (`key_id, kid, status, use, kek_id, previous_kek_id`) passes `Redaction.for_audit` | D-17, D-26; task output leak assertions |
| Exception structs leaking binaries (`TransactionStore` rescue, telemetry spans) | Information disclosure | Map any exception to `:storage_error`; no `:telemetry.span`; no `inspect` | D-25, Pitfall 9 |
| Double-wrap (re-encrypting an envelope as if it were JSON) | Tampering / DoS | Classify after lock in Elixir; envelope on current KEK is `already_current` and never rewritten; round-trip opens to JSON with matching kid | D-01, D-02, D-06; concurrency + barrier tests |
| Lost row / lost update (concurrent run, `activate`, `publish_key` upsert) | Tampering / Repudiation | Per-row `FOR UPDATE`; CAS on `private_jwk_encrypted`; only that column + `updated_at` written; status columns never touched | D-01, D-03, D-07; CAS branch test |
| Stranded key (KEK id removed or wrong material while rows depend on it) | DoS | Deep `encryption_status` opens every envelope; `--check` gate before removing the old id; five-step rotation order; `failed` reported with `unknown_kek` fix line | D-11, D-16, D-18 |
| Refusal bypass (parser runs before refusal; `:enc` keys exempt; mode read twice) | Elevation / Tampering | Refuse before `Jason.decode`/ETF; apply to both `use` values; read keyset once; mode honours boot-cached set (documented) | D-20, D-21, D-22; private_jwk tests with unparsable legacy payload |
| Premature `:reject` locks out signing | DoS | `--check` gate; engine bypasses `:reject` (internal `read_stored/2`) so recovery needs no config change | D-08, D-16 |
| Deadlock / lock-wait DoS during `activate` | DoS | One lock per transaction (no cycle possible); no batch locks, no `SKIP LOCKED`; short transactions | D-01 |
| Dry-run or `--check` writing / locking | Tampering | Both read-only (no `FOR UPDATE`, no audit); tests compare row bytes and audit counts before/after | D-09, D-16 |
| Typo triggers a write (`check` vs `--check`) | Tampering | Strict parser; any positional arg → `Mix.raise` before repo start | D-14 |
| Alarm flood / amplification on key outage | DoS | Hot path telemetry only (no DB write, no audit mirror), one log line per node per `{kid, reason}` via write-once `persistent_term` flag | D-23, D-27 |
| Mixed-mode rolling restart (some nodes `:allow`, others `:reject`) | Availability | Flip gated by `--check`; documented in help text | D-22 |
| Hosting a repo restart from Verify/doctor | Availability | Guard `with_repo` with `Process.whereis` | Pitfall 2 |

## Sources

### Primary (HIGH confidence)
- Repo files read this session (paths in the Integration Point Ledger): `lib/lockspire/storage/key_store.ex`, `.../repository.ex`, `.../repository/{signing_key_store,transaction_store,support,audit_store,token_store}.ex`, `lib/lockspire/protocol/private_jwk.ex`, `lib/lockspire/security/key_encryption.ex`, `.../key_encryption/key_set.ex`, `lib/lockspire/config.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/admin.ex`, `lib/lockspire/observability.ex`, `lib/lockspire/redaction.ex`, `lib/lockspire/install/verify.ex`, `lib/lockspire/install/verify/check.ex`, `lib/lockspire/application.ex`, `lib/mix/tasks/lockspire.{doctor,doctor.key_encryption,test.setup,upgrade}.ex`, `test/support/{key_encryption_helpers,telemetry_capture,data_case,seeding_helpers}.ex`, `test/test_helper.exs`, `test/lockspire/{architecture_fitness,readability_contract,compatibility_baseline_contract}_test.exs`, `test/lockspire/storage/repository_concurrency_test.exs`, `test/lockspire/install/verify_test.exs`, `config/test.exs`, `mix.exs`, `mix.lock`.
- `deps/ecto_sql/lib/ecto/migrator.ex` (`with_repo/3`, `ensure_repo_started/2`, `after_action/2`), `deps/ecto_sql/lib/mix/tasks/ecto.migrate.ex`, `deps/ecto/lib/ecto/repo.ex` (`transact/2`, `all_running/0`), `deps/ecto/lib/ecto/repo/registry.ex`.
- Live probes against `lockspire_test` on Elixir 1.19.5-otp-28 (with_repo commit/restart behaviour, `all_running/0`, CAS `{1,nil}`/`{0,nil}`, `repo.transact/1`).
- `156-CONTEXT.md`, `156-DISCUSSION-LOG.md`, `155-VALIDATION.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`.

### Secondary (MEDIUM confidence)
- External references listed in CONTEXT/DISCUSSION-LOG (PostgreSQL transaction-isolation and locking docs, Ecto.Migrator docs, Mix.Task docs, Kubernetes encryption-at-rest rotation) were already researched during discuss; not re-fetched this session.

### Tertiary (LOW confidence)
- `pg_stat_activity` blocked-backend polling for the concurrency test (A4): standard Postgres view, not exercised here.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, no additions; versions read from `mix.lock`.
- Architecture: HIGH, every integration point opened; Ecto/with_repo/CAS behaviours exercised live.
- Pitfalls: HIGH for 1-4, 8-10 (verified against source or probes); MEDIUM for 5-7 and 11 (derived from reading test fixtures and decisions).
- Test approach for the Mix task: MEDIUM-HIGH (commit semantics verified; full task not yet written).

**Research date:** 2026-10-16
**Valid until:** 2026-11-15 (stable stack; revalidate if `mix.lock` Ecto/ecto_sql versions change)
