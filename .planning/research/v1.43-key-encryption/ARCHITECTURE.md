# Architecture: Signing Key Encryption at Rest (v1.43)

**Domain:** Envelope encryption of private signing JWKs in an embedded Phoenix OAuth/OIDC library
**Researched:** 2026-10-15
**Confidence:** HIGH for integration points (read directly from code); MEDIUM for the exact envelope layout (design recommendation, not yet prototyped)

## Recommendation in one paragraph

Add one new pure module, `Lockspire.Security.KeyEncryption` (seal/open, AES-256-GCM, versioned envelope with the KEK id in a binary header). Encrypt at the single production write seam (`Lockspire.Admin.Keys.generate_key/1`, `lib/lockspire/admin/keys.ex:62`). Decrypt at the single protocol read seam (`Lockspire.Protocol.PrivateJwk.decode`, `lib/lockspire/protocol/private_jwk.ex:5`), not in storage load. **No schema migration**: the column is already `:binary` (`priv/repo/migrations/20260422000100_create_lockspire_core_tables.exs:104`), the KEK id lives in the ciphertext header, and the misleading field name `private_jwk_encrypted` becomes true instead of being renamed. Re-encryption is a public function (`Lockspire.Admin.Keys.reencrypt/1`) with a thin mix task wrapper, so release `eval` works. No decrypted-key cache.

## 1. Complete inventory of `private_jwk_encrypted` paths

Excluded: `.claude/worktrees/agent-p2-*` (stale agent worktree copies of tests; ignore, ensure they are not counted in greps).

### 1a. Production code (lib/)

| Role | Location | Notes |
|------|----------|-------|
| **WRITE (only prod writer)** | `lib/lockspire/admin/keys.ex:62` | `Jason.encode!(private_jwk_map)` in `generate_key/1`. Becomes `KeyEncryption.seal/3`. |
| Writer plumbing | `lib/lockspire/storage/ecto/repository/signing_key_store.ex:12-22` `publish_key` | Upsert `replace_all_except [:id, :inserted_at]` on `kid`; treats value as an opaque binary. Unchanged. |
| Schema | `lib/lockspire/storage/ecto/signing_key_record.ex:18` field, `:38` cast, `:71` `to_domain` | Opaque binary, no change. |
| Domain | `lib/lockspire/domain/signing_key.ex:17,36` | Type `binary() \| nil`. No change (document that it is ciphertext). |
| Behaviour | `lib/lockspire/storage/key_store.ex:11-17` | Callbacks return `SigningKey`; one new callback needed for re-encryption (see 5). |
| Strip for views | `signing_key_store.ex:253-254` (used at `:29`, `:55`); `admin/keys.ex:242-247` | Nils the field for `list_active_keys` / `list_publishable_keys` / admin views. Keep as is; this is defense in depth that ciphertext never reaches UI/KeyCache. |
| Raw loaders (carry ciphertext) | `signing_key_store.ex:35` `list_signing_keys`, `:62-71` `list_decryption_keys` (use `:enc`), `:89-100` `fetch_active_signing_key`, `:104-110` `fetch_signing_key_by_id` | Return ciphertext to callers. No change. |
| **READ: `PrivateJwk.decode/1`** | `jar.ex:43` (JAR request-object decryption with `:enc` keys), `jarm.ex:55`, `introspection_jwt.ex:36`, `id_token.ex:36`, `logout_token.ex:35`, `token_exchange/internal/access_token_signer.ex:208` | All six call the decoder. `id_token`/`logout_token`/`access_token_signer` receive the key as a `%{kid, alg, private_jwk_encrypted}` map (`id_token.ex:26`, `logout_token.ex:19`, `access_token_signer.ex:206`), so `kid` is always in hand for AAD binding. |
| Fetch only (shape guard, no decode) | `token_exchange/internal/token_issuer.ex:224-227`, `access_token_signer.ex:236-239` | Guard `is_binary(private_jwk)`; ciphertext is still a binary, so guards pass. |
| Key fetchers | `jarm.ex:70`, `introspection_jwt.ex:49`, `workers/backchannel_logout_delivery_worker.ex:121-125`, `protocol/request_object.ex:89` | Call `fetch_active_signing_key` / `list_decryption_keys`. No change. |
| Non-readers (confirmed) | `protocol/jwks.ex:25`, `protocol/end_session.ex:196`, `key_cache.ex:70-72` | Use `public_jwk` only. `KeyCache` ETS table is `:public` (`key_cache.ex:38`); never place private material there. |
| Decoder | `lib/lockspire/protocol/private_jwk.ex` | Currently accepts JSON or `non_executable_binary_to_term [:safe]` (legacy). This is the read seam. |

### 1b. Tests (about 60 files, all raw-write fixtures)

Fixtures write plaintext in three shapes: `Jason.encode!(...)`, `:erlang.term_to_binary(...)`, and placeholder bytes (`<<1>>`, `<<1,2,3>>`).

- Shared helpers (convert these to the new sealing helper): `test/support/seeding_helpers.ex:27`, `test/support/token_exchange_case.ex:290`.
- Integration e2e (raw writes, 18 sites): `test/integration/phase{3,6,15,29,36,37,38,39,41,62,81,100}_*`, `milestone_v1_3_verification_test.exs:234`.
- Controller/protocol tests that sign for real: `jarm_test.exs:42`, `id_token_test.exs:137`, `logout_token_test.exs:103`, `introspection_jwt_test.exs:31,137`, `jar_test.exs:27,44`, `request_object_test.exs:35`, `authorization_flow_test.exs:927`, `end_session_controller_test.exs:319`, `authorize_controller_test.exs:751`, `token_controller_test.exs:1004`, `introspection_controller_test.exs:545`, `backchannel_logout_delivery_worker_test.exs:325`.
- Fakes injecting `private_jwk_encrypted: jwk` through a stubbed key store: `rfc8693_exchange_test.exs:37`, `refresh_exchange_test.exs:19`, `access_token_signer_test.exs:29,42`. Unaffected because they bypass storage; they exercise `decode`, so they stay legacy-format until the decoder changes.
- Placeholder rows (`<<1>>`, never decoded): about 25 sites across `repository_test.exs`, `jwks_controller_test.exs`, admin LiveView tests, `server_policy_test.exs`, `clients_test.exs`, `registration*_test.exs`, `repository_atomicity_test.exs`, `message_signing_profile_test.exs`. Zero change needed.
- Decoder unit test: `test/lockspire/protocol/private_jwk_test.exs:7-13`. Must keep legacy cases (permissive mode) and gain envelope, wrong-kid AAD, unknown-KEK, tamper, strict-mode cases.
- Redaction/strip assertions naming the field: `keys_test.exs:53,82`, `repository_test.exs:884`, `keys_live_test.exs:643`, `overview_live_test.exs:655`, `policies_live/{par,dpop,index,security_profile}_test.exs`, `adoption_demo_docker_contract_test.exs:781`. Unchanged and still valid.
- `test/lockspire/audit/audit_writer_test.exs:449` calls `PrivateJwk.decode(active_key.private_jwk_encrypted)` on an admin-generated key; this one MUST switch to `decode/2` (it now holds an envelope).

### 1c. priv/, generators, demo, clean-room hosts

- `priv/repo/migrations/20260422000100_create_lockspire_core_tables.exs:104` (column definition only; no other migration touches it).
- Generator templates `priv/templates/lockspire.install/*` contain **no** reference to the field. They do own `config.exs` (the host config template, line 7 `config :lockspire`) which is where KEK config guidance goes.
- `examples/adoption_demo/priv/repo/seeds.exs:93` writes a **plaintext** signing key (`:erlang.term_to_binary`); lines `225,235,248` are `<<1>>` placeholders. `conformance_seeds.exs` only builds client JWKS (no signing-key row).
- `test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex:5` uses `Lockspire.Admin.generate_key(:sig)`; it will start failing at boot until that host's config carries a KEK. The confidential_client host does not touch the table.
- Docs: `docs/code-walkthrough.md:32,465-467`, `docs/architecture.md:83` describe the PrivateJwk decoder and must be updated.
- No scripts/tools/CI files reference the column.

## 2. Where encrypt/decrypt lives

```
Lockspire.Security.KeyEncryption   (NEW, pure, no Repo, no Application reads except via Config)
  seal(plain_jwk_map, kid, opts)        -> binary envelope
  open(binary, kid, opts)               -> {:ok, map} | {:error, reason}
  envelope?(binary)                     -> boolean
  kek_id(binary)                        -> {:ok, id} | :legacy
Lockspire.Config.key_encryption!/0      (NEW) validated KEK set + mode
Lockspire.Protocol.PrivateJwk           (MODIFIED) decode/2 = envelope-aware, decode/1 retained for legacy
Lockspire.Admin.Keys                    (MODIFIED) seals on write; hosts reencrypt/1 + encryption_status/0
```

Placement rationale: `lib/lockspire/security/` already holds `Policy` (`policy.ex`) and `DeviceCode` and already seals secrets via `Plug.Crypto.encrypt` (`policy.ex:181-192`); a crypto primitive module belongs there, not in `protocol/` or `storage/`.

### Envelope format (recommended)

`<<"LSK", 1, kid_len::8, kek_id::binary, iv::12-bytes, tag::16-bytes, ciphertext::binary>>`

- Plaintext = JSON of the private JWK (same bytes as today's `Jason.encode!`).
- Cipher: `:crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plain, aad, tag_len, true)`; random 96-bit IV per seal.
- **AAD = magic+version+kek_id header ++ `"signing_key:" <> kid`**. Binds ciphertext to its header and its row identity so a DB-level row swap or header downgrade fails authentication. This is why the read seam needs `kid` (`decode/2`).
- Prefix is unambiguous against legacy forms: JSON starts with `{` (0x7B), `term_to_binary` starts with 131, envelope starts with `"LSK"`.

### Decrypt at the protocol read seam, not at storage load

| Option | Verdict |
|--------|---------|
| Decrypt in `SigningKeyRecord.to_domain` / store | Rejected. Every loader (`list_signing_keys`, admin `get_key`, audit paths) would then carry plaintext JWKs in `%SigningKey{}` structs that flow into LiveView assigns, logs, crash reports and `inspect`. Violates the "strong redaction" default and the strip pattern at `signing_key_store.ex:253`. Also forces storage to depend on Config/KEK. |
| Decrypt in `PrivateJwk.decode/2` (the six callers) | **Chosen.** Plaintext exists only in a local variable between decode and `JOSE.JWT.sign`. Matches PROJECT.md's stated single-seam design. Test fakes that inject a key map keep working. Storage stays a dumb binary store. |

Add one defense: `%SigningKey{}` should get `@derive {Inspect, except: [:private_jwk_encrypted]}` (verify it is not already redacted) so ciphertext never prints either.

## 3. Schema migration: not needed

| Question | Decision | Why |
|----------|----------|-----|
| Column type change | No. `:binary` (bytea) already holds the envelope. | `core_tables.exs:104` |
| Separate `kek_id` column vs header | **Header.** | Row and KEK id can never disagree (AAD binds them); no packaged migration ships to hosts; no `mix ecto.migrate` step in the upgrade; rewrite is a single-column update. A column would only help SQL `WHERE kek_id <> $primary`, but the table has single/double-digit rows, so scan-and-parse is free. |
| Rename `private_jwk_encrypted` | **Do not rename in v1.43.** | About 60 test files, the domain struct, record, behaviour, admin strip, redaction assertions and the docker contract test reference it (section 1). A rename needs a host-shipped migration (`rename column`, locks table, breaks rolling deploys running old+new code) and touches public-ish struct shape. Benefit is cosmetic once the value is actually encrypted. Revisit only if a later major version already forces a breaking schema change. |
| Legacy rows | Remain valid bytes in the same column; decoder discriminates by prefix. | Zero-downtime upgrade. |

How host migrations ship (for reference, none added this milestone): `priv/repo/migrations/*.exs` use `Lockspire.Storage.Ecto.Migration` (`lib/lockspire/storage/ecto/migration.ex`, e.g. `lockspire_table/1`), are copied into the host by `Lockspire.Install.Migrations` (`lib/lockspire/install/migrations.ex:44,83`) via `mix lockspire.install` / `mix lockspire.upgrade`, and checked by `Install.Verify.migrations_check` (`verify.ex:277-296`). If the roadmapper later decides to add a `kek_id` column anyway, that is the pipeline; latest migration is `20260528150000_add_access_token_format.exs`.

## 4. Config shape and boot validation

```elixir
# config/runtime.exs (host)
config :lockspire, :key_encryption,
  # first entry = primary KEK used for all new writes; the rest only decrypt
  keys: [
    {"2026-10", System.fetch_env!("LOCKSPIRE_KEK_2026_10")},   # base64, decodes to exactly 32 bytes
    {"2026-04", System.get_env("LOCKSPIRE_KEK_2026_04")}       # optional; nil entries are dropped
  ],
  mode: :permissive   # :permissive (read legacy plaintext) | :strict (refuse it)
```

- Rotatable list, ids are host-chosen short strings (`^[A-Za-z0-9._-]{1,32}$`), stored in the envelope header. Not derived from `secret_key_base` (`config.ex:85-92`, which is the inferred, shared secret and rotates with sessions).
- `Lockspire.Config.key_encryption!/0` follows the existing pattern (`config.ex:14-18`, `fetch_required!` -> `Policy.fetch_required_config!`, `config.ex:244-246`): returns `%{primary: {id, key}, keys: %{id => key}, mode: mode}` or raises with a copy-pasteable message (generate with `:crypto.strong_rand_bytes(32) |> Base.encode64()`). Validate: present, list non-empty, unique ids, each base64 decodes to exactly 32 bytes, mode in the allowed set.
- **Boot fail-fast location:** `Lockspire.Application.start/2` (`lib/lockspire/application.ex:9-18`). Call `Lockspire.Config.key_encryption!()` before building `children`. Precedent: `Lockspire.Oban.runtime_config!()` is already evaluated eagerly in the child list (`application.ex:13`), and `Config.issuer!` validates through `Policy` (`config.ex:50-60`). Do not validate in compile-time config.
- Also add a `config_check(:key_encryption, ...)` to `Install.Verify` (`verify.ex:50-55`) and a doctor check (`lib/mix/tasks/lockspire.doctor.ex`) that reports encrypted/legacy counts via `Keys.encryption_status/0`.
- Test env: set a fixed test KEK in `config/test.exs` with `mode: :permissive` so the ~60 raw-fixture tests stay green; strict-mode tests override via `Application.put_env` in a non-async module.
- Never log or inspect the keys list. Config validation errors must name the env var/id, never the value (reuse `Lockspire.Redaction`).
- Rollout default decision for the roadmapper: ship `:permissive` default with a doctor warning while legacy rows exist; hosts flip to `:strict` after migration. Missing KEK config is a hard boot failure (per PROJECT.md), which makes this a deliberate minor-version upgrade requiring release notes plus `mix lockspire.upgrade` guidance.

## 5. Re-encryption (migration and KEK rotation) design

One operation serves both "encrypt legacy plaintext" and "rewrap from old KEK to primary".

- **Public API (NEW):** `Lockspire.Admin.Keys.reencrypt(opts)` with `dry_run: boolean`, `batch_size: 50` returning `{:ok, %{scanned, rewritten, skipped, failed}}`. Also `Keys.encryption_status/0` returning counts by `:legacy | kek_id`.
- **Mix task (NEW, thin):** `mix lockspire.keys.reencrypt [--dry-run]` in `lib/mix/tasks/` next to `lockspire.install.ex` (use `@requirements ["app.config"]` like `lockspire.upgrade.ex:11`; start the repo). Release hosts have no Mix, so document `bin/my_app eval "Lockspire.Admin.Keys.reencrypt()"` (and `rpc`); that is why the logic must be a public function, not task-only. Lockspire does not own the host's release module, so only document the eval line.
- **Storage boundary:** add `SigningKeyStore.rewrite_private_material(repo, after_id, limit, fun)` (+ behaviour callback in `key_store.ex` + `repository.ex` delegate near `:483-517`). Inside one `repo.transaction` per batch: select rows `id > after_id ORDER BY id LIMIT n`, `lock("FOR UPDATE")` (same idiom as `locked_key/2`, `signing_key_store.ex:~190`), call `fun.(ciphertext, kid)` which returns `{:ok, new_binary} | :skip | {:error, reason}`, and update only `private_jwk_encrypted` + `updated_at`. Crypto stays outside storage; storage only gives locked row iteration.
- **Per-row logic (in `Admin.Keys`):** `open` with any configured KEK or legacy decode -> if already envelope under the primary id, `:skip` (idempotent) -> `seal` under primary -> **round-trip `open` and compare the JWK map before returning** -> storage writes. Skip rows with `nil` private material. Include `:retired` and `use: :enc` rows (sensitive too).
- **Failure semantics:** a row failing to open aborts only its batch transaction (rolled back, previous ciphertext intact) and is reported by redacted handle (`Redaction.handle(:kid, kid)`, `keys.ex:259`), never material. Re-running resumes safely. A wrong/missing old KEK yields a clear `{:error, {:unknown_kek, id}}`, never partial overwrite.
- **Concurrency:** `FOR UPDATE` row locks interlock with `activate_signing_key`/`retire` (which lock the same rows) and with `publish_key` upserts (which replace ciphertext wholesale with a fresh sealed value, so last-writer-wins is safe).
- **Audit/telemetry:** one audit event per run using `key_audit_event/4` (`keys.ex:294`) and `emit/4` (`keys.ex:284`) with counts only.
- **Strict mode** is purely a decoder behavior: with `mode: :strict`, `decode/2` returns `{:error, :plaintext_key_refused}` for non-envelope input (log a redacted warning once). Provide `encryption_status` as the pre-flip check.

## 6. Caching and rotation

Findings that simplify the design:
- Private keys are **not cached today.** Every signing call does a DB fetch (`fetch_active_signing_key`, `signing_key_store.ex:89`) and a JSON decode. `KeyCache` caches **public** JWKs only (`key_cache.ex:70-72`; loader is the stripped `list_active_keys`, `signing_key_store.ex:29`) in a `:public` ETS table.
- AES-256-GCM on about 2 KB is microseconds; the DB round-trip dominates. **Recommendation: no decrypted-key cache in v1.43.**
- Never put plaintext private JWKs in `KeyCache`'s ETS table or any process-global cache (public table, crash dumps, `erl_crash.dump` is already present in repo root).
- If a cache is later needed, key it by `{kid, sha256(ciphertext)}` so re-encryption and signing-key rotation invalidate it for free, with a short TTL and a per-process (not ETS-public) scope.
- Interaction with signing-key rotation (activate/retire, `signing_key_store.ex:134-168`): status transitions do not touch ciphertext, so nothing to invalidate. Interaction with KEK rotation: decrypt selects the KEK by header id, so old and new ciphertext coexist during a rotation window; the only requirement is that old KEKs stay in the `keys` list until `encryption_status` shows zero rows under them.

## 7. Suggested build order and phases

Dependency chain: KeyEncryption + Config -> decoder/writer wiring -> storage rewrite API -> re-encrypt/strict -> host/demo/docs -> proof.

1. **Phase A: Crypto core and seams (permissive).**
   NEW: `Security.KeyEncryption`, `Config.key_encryption!/0`, boot validation in `application.ex`, test-env KEK. MODIFIED: `PrivateJwk.decode/2` (+ keep `/1`), the six read call sites to pass `kid`, `Admin.Keys.generate_key` seals, `config/test.exs`, `audit_writer_test.exs:449`, shared test helpers, Inspect redaction on `SigningKey`. Exit: newly generated keys are envelope-encrypted; legacy rows still sign; unit tests for tamper/AAD/unknown-KEK.
2. **Phase B: Upgrade path and rotation.**
   NEW: store `rewrite_private_material` + behaviour callback + repository delegate, `Keys.reencrypt/1`, `Keys.encryption_status/0`, `mix lockspire.keys.reencrypt`, strict mode in decoder. MODIFIED: `Install.Verify` and doctor checks. Exit: legacy -> encrypted idempotently, KEK rotation proven (add new primary, re-encrypt, drop old).
3. **Phase C: Host surfaces and hygiene.**
   MODIFIED: install template `config.exs` / runtime guidance, `lockspire.upgrade` messaging, `examples/adoption_demo/priv/repo/seeds.exs:93` (seal via public API instead of raw write), demo and clean-room provider_host config (bootstrap.ex:5), docs (`code-walkthrough.md`, `architecture.md`, new KEK/rotation guide, SECURITY.md). **Bandit 1.13.1 bump goes here as its own first plan**: it touches the same hosts (demo `mix.lock`, `test/clean_room/provider_host/mix.exs:22` + lock, `test/clean_room/confidential_client/mix.exs:22` + lock, and the `compatibility/phoenix_1_8_live_view_1_1/mix.lock:2` lock). It has no dependency on the crypto work, so it can also be sequenced first as a standalone CVE-fix plan if urgency matters; do not interleave it inside Phases A/B, where a host-dependency failure would block crypto verification. Root `mix.exs` does not depend on Bandit.
4. **Phase D: Proof and release gate.**
   E2E signing across ID token, JARM, introspection JWT, token exchange, JAR decrypt, logout token with encrypted rows; redaction sweep (logs, telemetry, admin pages, error terms never contain JWK members or KEK); CI test that reads raw column and asserts no row decodes as JSON/term; strict-mode flip test; upgrade test starting from a plaintext fixture DB. Phase D can fold into C if the roadmap wants 3 phases.

## Anti-patterns to avoid

- Decrypting in storage/`to_domain` (plaintext spreads into structs, assigns, logs).
- Embedding the KEK or deriving it from `secret_key_base`.
- Writing a new raw `Jason.encode!` anywhere (add a test that greps `lib/` for it).
- Re-encrypting without round-trip verification or without row locks.
- Renaming the column in this milestone.
- Caching plaintext in the public KeyCache ETS table.

## Open items for phase-level research

- Prototype the envelope and confirm AAD choice against `:crypto.crypto_one_time_aead` on the OTP versions in CI (low risk).
- Check `priv/templates/lockspire.install/config.exs` and whether the generator should also emit a `runtime.exs` snippet (generator conventions in `lib/lockspire/generators/install.ex`).
- Confirm Bandit 1.13.1 lock bump in `examples/adoption_demo/mix.lock` (not read here) and that all three pins plus the compatibility lock resolve.
- Decide permissive vs strict as the shipped default (recommended: permissive + doctor warning).
