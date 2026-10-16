# Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal - Context

**Gathered:** 2026-10-16 (assumptions mode, research fan-out: codebase, Postgres/Ecto concurrency, operator CLI/DX, refusal/telemetry/audit)
**Status:** Ready for planning

<domain>
## Phase Boundary

An operator can move an existing install from plaintext signing-key rows to fully encrypted storage, rotate the KEK without reissuing signing keys, prove readiness, and turn on `legacy_plaintext: :reject` without stranding a key. Every step is observable through ids, counts and reason atoms only. Requirements: MIG-01, MIG-02, MIG-03, OPS-01, OPS-02.

Not in this phase: generator output and `:reject` default for fresh installs, demo seeds, the full `Lockspire.Redaction` sweep (RED-01), repo-wide docs and upgrade/rotation runbooks, release-eval docs, end-to-end release proof (all Phase 157). Only task `@moduledoc`/help text is written here.
</domain>

<decisions>
## Implementation Decisions

### Binding upstream design
- **D-00:** Research R1–R8 and "Other resolutions" in `.planning/research/v1.43-key-encryption/SUMMARY.md` and Phase 155 decisions D-00..D-20 stay locked. SAFE-01 applies: no new deps, no migration, no column rename, no `kek_id` column, no decrypted-key caching, no protocol behavior change, no new admin UI copy.

### Re-encryption engine (156-01)
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

### Public API (156-01 / 156-02)
- **D-10:** `Lockspire.Admin.Keys.reencrypt(opts \\ [])`, with opts `dry_run: boolean()` and `actor: map()` (existing `actor_from_attrs` shape). It returns:
  - `{:ok, report}` when it ran. The report is a plain typed map: `dry_run`, `current_kek_id`, `scanned`, `encrypted`, `rewrapped`, `already_current`, `no_private_key`, `conflicted`, `by_source_kek` (`%{"legacy" | kek_id => count}`) and `failed: [%{kid, reason, kek_id}]`.
  - `{:error, reason}` only when it could not run: `:key_encryption_not_configured`, invalid config, or `:repo_not_started`.

  Per-row failures stay inside `{:ok, report}`, because successful rows are committed. It assumes the repo is already started, like every other `Admin.Keys` function.
- **D-11:** `Lockspire.Admin.Keys.encryption_status/0` returns `{:ok, status}` with: `configured`, `current_kek_id`, `configured_kek_ids`, `legacy_plaintext`, `total`, `no_private_key`, `legacy`, `by_kek_id`, `unknown_kek` (`%{kek_id => count}`), `undecryptable` (rows on a configured id that fail to open: wrong material for that id, tamper, `kid_mismatch`), `pending: [%{kid, state}]` and `ready?`.
  - It reads rows via the existing `list_signing_keys/1`, so it needs no new storage method.
  - It **opens every envelope and discards the plaintext**, so it catches same-id/wrong-material (C4), which header-only counts cannot. Tens of rows make the cost trivial; nothing is cached.
  - `ready?` requires: configured, `legacy == 0`, every material row on current, `unknown_kek` and `undecryptable` empty.
- **D-11a (resolved during plan check, 2026-10-16):** Readiness is gated on rows that signing or decryption can reach: statuses `upcoming|active|retiring`.
  - **Stranded retired rows.** A `retired` row the engine cannot seal (unreadable legacy, legacy `kid_mismatch`, malformed or undecryptable envelope, unknown KEK) is reported as a visible `stranded_retired` count with its kids. It does not block `ready?`, `--check`, doctor or Verify, because no consumer reads retired material.
  - **Operator route** for an unsealable row that is still reachable: retire it and generate a replacement, after which it moves to `stranded_retired`.
  - **Wording.** Fix lines and `--check` output state that the row's bytes remain stored, and that deleting them is the host's database decision, because Lockspire adds no key-deletion path in this phase.
  - **Empty table.** With a KEK configured and zero material rows, `ready?` is true.
  - **Why.** Lockspire-generated keys have always carried a matching `"kid"` (since 2026-04-23). Unsealable rows therefore come only from host-inserted or corrupted data, and a new destructive delete API would widen this security milestone.
- **D-12:** Both functions get `@doc` + `@spec` + `defdelegate` in `Lockspire.Admin` (`admin.ex:193-231` pattern). Any new `Lockspire.Config` export must be added to `test/support/architecture/public_compatibility_manifest.ex`.
- **D-13:** No `Lockspire.Release` module. A running node uses `bin/app rpc '…Lockspire.Admin.Keys.reencrypt()…'`. The fresh-VM `MyApp.Release` snippet (`load_app` + `Ecto.Migrator.with_repo`) is documented in Phase 157, which must state that a bare `bin/app eval "Lockspire.Admin.Keys.reencrypt()"` does not start the repo.

### Mix task (156-01)
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

### Doctor and Verify (156-02)
- **D-19:** One source of truth: `--check`, doctor and verify all read `encryption_status/0` and differ only in what they gate on.
  - `reencrypt --check`: is everything ready?
  - `mix lockspire.doctor key_encryption`: wraps `with_repo`, prints the existing config line plus row counts per KEK id, legacy, unknown and undecryptable, and a hint such as "N rows still need re-encryption: run …". It exits 1 only if config is invalid/missing, the database is unreadable, or something is broken now. With no KEK it still shows the legacy count.
  - `Install.Verify`: adds one DB-backed check that is `:error` only when something is **broken now** (any `unknown_kek` or `undecryptable` row, or `:reject` with legacy rows remaining). Legacy rows under `:allow` stay `:ok`, with counts in `details`; this keeps the KEK-02 non-breaking promise, and the D-08/155 missing-KEK error already supplies the loud nudge. If the DB cannot be read or migrations are pending, report the check as skipped/non-duplicating rather than double-failing with the migrations check, and catch DB errors, which `safely/1` currently does not.

### Plaintext refusal (156-02)
- **D-20:** In `PrivateJwk.decode_with_reason/1`, read the key set once. A `:legacy` classification with `legacy_plaintext: :reject` returns `{:error, :plaintext_key_refused}` **before** `Jason.decode` or the ETF parser runs. A nil key set or `:allow` keeps today's path. Add `:plaintext_key_refused` to `@type reason`. The external collapse is unchanged: `:invalid_signing_key` at five sites, `:decryption_failed` for JAR (155 D-02).
- **D-21:** `:reject` applies to `use: :enc` keys as well. JAR continues to the next key. A JOSE `block_decrypt` failure (JWE not addressed to that key) is not a key-storage fault and emits no `decode_failed`.
- **D-22:** The mode is read from the boot-cached key set, so a change takes effect on each node's next boot (existing WR-02 decision). Rolling restarts briefly mixing modes are safe only because the flip is gated on `--check`. Document this in help text now and in the 157 runbook.

### Telemetry and audit (156-02) — corrects ROADMAP criterion 5 and OPS-02
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

### Tests
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
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.43-key-encryption/SUMMARY.md`: binding R1–R8 and Other resolutions
- `.planning/research/v1.43-key-encryption/PITFALLS.md`: C4, C5, C6, C7 owned here; C8 for leak tests
- `.planning/research/v1.43-key-encryption/ARCHITECTURE.md`, `FEATURES.md`
- `.planning/phases/155-crypto-core-config-seam-bandit-baseline/155-CONTEXT.md` (D-00..D-20), `155-REVIEW-DISPOSITION.md` (WR-01, WR-02, IN-01 carry into 156), `155-*-SUMMARY.md`
- `.planning/REQUIREMENTS.md`: MIG-01..03, OPS-01, OPS-02 (apply D-23 wording), SAFE-01
- `.planning/ROADMAP.md`: Phase 156 section (corrections D-01 and D-23 above)
- `.planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-DISCUSSION-LOG.md`: research findings, CLI output examples and sources (audit trail)
- External: PostgreSQL docs on transaction isolation (EvalPlanQual), explicit locking, and SELECT locking clauses; `Ecto.Migrator.with_repo/3`; `ecto.migrate` source; `Ecto.Adapters.SQL.Sandbox` (`unboxed_run`); Kubernetes encrypt-data-at-rest rotation steps
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/lockspire/security/key_encryption.ex`: `classify/1` (`:envelope | :legacy | :invalid`), `seal/3`, `open/3`, `envelope_kek_id/1` (header-only).
- `lib/lockspire/security/key_encryption/key_set.ex`: `current/1`, `fetch_key/2`, `legacy_plaintext` field (defaults to `:allow`).
- `lib/lockspire/config.ex:246-289`: `key_encryption!/0` (fresh, nil when absent) and `key_encryption_keyset/0` (cache with fresh fallback).
- `lib/lockspire/protocol/private_jwk.ex`: `decode/1` (collapsing), `decode_with_reason/1` (`@doc false`), legacy path `:52-64` with no mode check yet.
- `lib/lockspire/admin/keys.ex:275-336`: `transact_with_audit`, `key_audit_event`, telemetry metadata builder, `actor_from_attrs`.
- `lib/lockspire/observability.ex:14-44`: `emit/4` (plus audit mirror, adds `count: 1`, redacts).
- `test/support/key_encryption_helpers.ex`: `put_key_encryption/1` (async: false), `seal_private_jwk/2`.
- `test/support/telemetry_capture.ex`; `test/lockspire/storage/repository_concurrency_test.exs` (unboxed pattern).
- `lib/lockspire/install/verify.ex:312-372`: `with_repo` precedent; `lib/mix/tasks/lockspire.test.setup.ex:37`.
- `lib/mix/tasks/lockspire.upgrade.ex`: `--dry-run` precedent.

### Established Patterns
- Store transactions: `TransactionStore.transact` + `locked_key/2` (`FOR UPDATE` by id) in `signing_key_store.ex:113-226`; `update_all` with manual `updated_at` in `token_store.ex:344,359`.
- `publish_key` upserts `ON CONFLICT (kid)` replacing all columns: a direct seed re-run can re-plant plaintext, which `--check`/doctor detect.
- Task style: `@requirements ["app.config"]`, strict `OptionParser`, `Mix.shell().info`, `Mix.raise` for failure. Doctor dispatcher at `lib/mix/tasks/lockspire.doctor.ex:11-31`; `lockspire.doctor.key_encryption.ex:49-74` is config-only today.
- `ReadabilityContractTest` forbids planning markers (`Phase N`, `D-NN`) in runtime source comments.
- `architecture_fitness_test.exs`: Repository has no Ecto query constructs; JWKS, discovery and KeyCache never mention `PrivateJwk`/`KeyEncryption`; protocol modules never reference `Admin`/`Web`.
- Integration-tagged tests are excluded by default and run in the CI integration partition (`scripts/ci/run_test_matrix.sh:125`).

### Integration Points
- `lib/lockspire/storage/key_store.ex:10-25` (new callback), `lib/lockspire/storage/ecto/repository.ex:482-532` (delegate), `signing_key_store.ex` (implementation).
- `lib/lockspire/admin.ex:193-231` (facade delegates).
- `lib/lockspire/protocol/private_jwk.ex` (refusal + hot-path telemetry).
- `lib/mix/tasks/lockspire.keys.reencrypt.ex` (new), `lib/mix/tasks/lockspire.doctor.key_encryption.ex` (counts + `with_repo`), `lib/lockspire/install/verify.ex` (broken-now check).
- `docs/telemetry.md`: add a `[:lockspire, :key, …]` section only if 156 touches the file; otherwise the full update lands in 157 (it is already stale and claims to be exhaustive).
</code_context>

<specifics>
## Specific Ideas

- User confirmed (2026-10-16) the hot-path telemetry-only correction (D-23).
- Target CLI output shapes (normal, `--dry-run`, `--check` pass/fail, failure with fix lines) are recorded in the discussion log; follow them closely.
- Precedent lessons: Cloak migrates by brute force with no "already current" detection, no dry-run or report, silently dropped errors and `app.start`, so avoid all of those. Hydra never re-encrypts, so old secrets can never be removed; the engine plus `--check` closes that gap. Kubernetes gives the add-as-non-current-first rotation step.
</specifics>

<deferred>
## Deferred Ideas

- `Lockspire.Release` helper module: revisit only if UAT shows release-eval friction.
- `--json` output, `--repo`, `--batch-size`, `--from-kek` filter: not needed for tens of rows.
- Time-bucketed log throttle instead of once-per-node dedupe.
- New todo: `lockspire.client.create`, `doctor token_format` and `doctor remote-jwks` use `app.config` without starting the repo and likely fail in a real host (`.planning/todos/pending/2026-10-16-mix-tasks-start-repo.md`).

### Reviewed Todos (not folded)
- `2026-10-13-audit-dcr-default-lifetime-semantics.md`: protocol, unrelated to key storage; stays deferred to a later protocol milestone (DCR-01).
</deferred>
