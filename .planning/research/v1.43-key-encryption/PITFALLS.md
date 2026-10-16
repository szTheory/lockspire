# Domain Pitfalls: Signing Key Encryption at Rest (v1.43)

**Domain:** Retrofitting AES-256-GCM envelope encryption onto private signing JWKs in an embedded Phoenix OAuth/OIDC library
**Researched:** 2026-10-15
**Overall confidence:** HIGH for repo-specific findings (read from code); MEDIUM-HIGH for crypto/ops guidance (established practice, OTP :crypto semantics)

Phase names below are suggested ownership labels; map to roadmap numbering later:
**P-CRYPTO** (format + encrypt/decrypt seam), **P-CONFIG** (KEK config, fail-fast, installer), **P-MIGRATE** (re-encrypt task, strict mode), **P-ROTATE** (KEK rotation), **P-REDACT** (leak surfaces), **P-PROOF** (tests/e2e), **P-DOCS** (upgrade docs, backups), **P-DEPS** (Bandit).

## Repo facts verified (drive the pitfalls below)

- Write seam: `lib/lockspire/admin/keys.ex:62` does `Jason.encode!(private_jwk_map)` into `private_jwk_encrypted`. Read seam: `PrivateJwk.decode/1` is called from 6 sites (`id_token`, `jar`, `logout_token`, `introspection_jwt`, `jarm`, `access_token_signer`), some passing the raw column, some passing a `private_jwk` variable.
- `PrivateJwk.decode/1` tries `Jason.decode` first, then `Plug.Crypto.non_executable_binary_to_term`, and wraps everything in `rescue`/`catch` returning a single `:invalid_signing_key`. A decryption failure folded into that error is indistinguishable from "corrupt row".
- Legacy tests write plaintext directly: `test/support/seeding_helpers.ex:27` (JSON), `test/support/token_exchange_case.ex:290` and 8 integration tests (`phase3`, `phase6`, `phase15`, `phase29`, `phase36`, `phase62`, `phase81`, `phase100`, `milestone_v1_3`) using `:erlang.term_to_binary`. About 45 test files reference `private_jwk_encrypted`/`PrivateJwk`; `repository_test.exs` has 12 hits.
- `SigningKeyRecord.changeset/2` `cast`s `private_jwk_encrypted` and `unique_constraint(:kid)`. `SigningKey` and the record have no `@derive {Inspect, except: ...}`.
- `signing_key_store.ex:253` already has `strip_private_key_material/1` (nil-ing the column) for public paths: good precedent, must be preserved.
- No `Application.compile_env` in `lib/`. `config/test.exs` sets a fixed `secret_key_base` of 64 `a`s.
- Demo host pins `{:bandit, "~> 1.11"}` in `examples/adoption_demo/mix.exs`; Bandit is not a Lockspire dep. An `erl_crash.dump` sits in the repo root (git-ignored, but proves dumps land on dev disks).

---

## Critical Pitfalls

### C1: Ambiguous format detection (ciphertext vs JSON vs ETF)
**What goes wrong:** Decoder sniffs "does it look like JSON / does Jason succeed" and falls through. Random ciphertext bytes can begin with `{` (0x7B) or `0x83` (ETF magic), or a legacy row is mis-routed into the decrypt path and fails; worse, a tampered/truncated ciphertext falls through to `non_executable_binary_to_term`, which parses attacker-influenced bytes.
**Why it happens:** Current decode order is JSON-then-term with a blanket rescue; adding "also try decrypt" at the end keeps that fall-through shape.
**Consequences:** Intermittent (1/256 per leading-byte) mis-detection; silent downgrade to plaintext path; confusing `:invalid_signing_key`.
**Prevention:** Choose an ASCII magic prefix that cannot start valid JSON or ETF, e.g. `"lsk1:"` (or `"$lsk$v1$<kek_id>$"`), then base64url payload. Dispatch strictly on prefix: prefix present => decrypt only, never fall back to legacy parsers; no prefix => legacy path only (JSON object must begin `{`, ETF must begin `<<131>>`), else error. Make the legacy path an explicit `classify/1` returning `:encrypted | :legacy_json | :legacy_term | :unknown`. Property test: random 0..64-byte binaries never classify as `:encrypted`, and every encrypted value never classifies as legacy.
**Detection:** Flaky decode in property tests; `:invalid_signing_key` on freshly generated keys.
**Owner:** P-CRYPTO.

### C2: Missing AAD lets ciphertexts be swapped between rows
**What goes wrong:** Without AAD, an attacker (or buggy migration/restore) with DB write access can copy key A's ciphertext into key B's row; it decrypts fine, so `kid=B` in JWKS now signs with A's material, or an `:enc` key row holds a `:sig` key.
**Why it happens:** `crypto_one_time_aead` accepts empty AAD; "encrypted" feels sufficient.
**Consequences:** Public/private mismatch (tokens fail verification at clients) or silent cross-key substitution. The `kid` is also inside the plaintext JWK, but that is only checked if the code checks it.
**Prevention:** AAD = canonical bytes of `format_version || kek_id || kid || use || alg` (fixed field order, length-prefixed or `\0`-delimited, never JSON map order). Pass identical AAD on decrypt, derived from the row, not from the ciphertext. After decrypt also assert plaintext `"kid"` equals row `kid` (cheap defense in depth). Include `kek_id` in AAD so the header cannot be rewritten to point at a different wrapping key. Note: `tenant_id` is nullable; include it only if it can never change post-write, otherwise omit and document.
**Detection:** Swap-ciphertext test (row A -> row B) must raise `:decryption_failed`, not succeed.
**Owner:** P-CRYPTO. Test in P-PROOF.

### C3: GCM nonce mistakes
**What goes wrong:** Reusing an IV under one key destroys confidentiality and authentication (leaks XOR of plaintexts, enables forgery). Mistakes: deterministic IV from `kid`, counter reset, IV length other than 12, or truncated tag.
**Why it happens:** Re-encrypting the same key under the same KEK (idempotent migration) with a derived IV looks "convenient".
**Prevention:** Fresh 12-byte `:crypto.strong_rand_bytes(12)` per encryption, always, including re-encrypt and rotation. Random 96-bit nonces are safe to ~2^32 messages per key; Lockspire encrypts perhaps tens to thousands of values per KEK lifetime, so no counter is needed, but note the limit in a comment and rotate the KEK on a schedule anyway. Full 16-byte tag; verify `:crypto.crypto_one_time_aead/7` returns `:error` handling (it returns `:error`, not raise, on tag mismatch in older OTP; some versions raise `ErlangError`), and never use the `:aes_gcm` legacy `block_encrypt` API. Pin AES-256 (32-byte key) and validate KEK size at config load.
**Detection:** Test asserts two encryptions of the same input differ; grep for any IV not from `strong_rand_bytes`.
**Owner:** P-CRYPTO.

### C4: KEK lost, rotated away, or mismatched => all tokens unsignable (outage)
**What goes wrong:** Host removes the old KEK from the list before all rows are re-encrypted, or deploys a typo'd/changed env var. Every `PrivateJwk.decode` fails; token, id_token, logout, introspection-JWT, JAR/JARM endpoints all fail at once, often presenting as generic 500/`server_error`. Lost KEK with no backup is unrecoverable (keys must be regenerated, all RPs must re-fetch JWKS, outstanding tokens invalid on rotation).
**Why it happens:** Blanket `rescue` in `decode/1` collapses "no such kek_id" / "tag mismatch" / "corrupt" to `:invalid_signing_key`.
**Consequences:** Total signing outage with no actionable signal.
**Prevention:**
- Distinct error atoms: `:kek_not_configured` (header kek_id not in list), `:decryption_failed` (tag mismatch), `:malformed_ciphertext`, `:invalid_signing_key` (legacy garbage). Do not blanket-rescue crypto errors into one atom.
- Boot-time verification, not just config-shape validation: at application start (and in `mix lockspire.doctor`), scan distinct `kek_id`s present in `lockspire_signing_keys` and fail fast (or at least log at error + telemetry) if any non-retired row references an unconfigured kek_id. Optionally decrypt-probe the active signing key.
- Rotation docs: add new KEK at list head, deploy everywhere, run re-encrypt, verify via doctor "0 rows on old kek_id", only then remove old KEK. Make the re-encrypt task print remaining rows per kek_id.
- Prefer failing closed and loudly over silently skipping keys: if the active signing key cannot decrypt, do not fall back to another key silently; emit `[:lockspire, :key, :decrypt_failed]` telemetry with `kid` and `reason` (no key material).
- Docs: back up the KEK separately from DB backups (a DB backup alone must not equal key access; KEK alone must not either).
**Detection:** Spike in `:invalid_signing_key`/`decrypt_failed`; doctor reports orphan kek_ids; admin keys page banner "key cannot be unlocked".
**Owner:** P-CONFIG (boot check, errors), P-ROTATE (ordering, task output), P-DOCS (runbook).

### C5: Multi-node / Oban / release deploy with mismatched KEK config
**What goes wrong:** During rolling deploy, node A (new code, new KEK, has re-encrypted rows) and node B (old code, no KEK knowledge) share a DB. Old code reads encrypted rows with `Jason.decode`/term parse => `:invalid_signing_key` on B. Separately, Oban workers (e.g. `BackchannelLogoutDeliveryWorker` signs logout tokens) may run in a different release/node role with different env, and fail only on logout traffic.
**Why it happens:** Encryption is a one-way DB format change; old code cannot read it. Workers often run in separate deployment with fewer env vars.
**Prevention:**
- Ordering rule (docs + `mix lockspire.upgrade` output): (1) deploy v1.43 code with KEK configured everywhere (web, workers, release tasks, console) while data is still plaintext; new code reads both; (2) only then run re-encrypt; (3) only then consider strict mode. Never run re-encrypt before 100% of nodes run new code.
- Newly generated keys: write encrypted only after fleet is on new code. Consider a flag/config gate (`encrypt_on_write: true` default after config present) or document that the first deploy including a KEK is the cutover; during rolling deploy new keys generated by admin on a new node would be unreadable by old nodes. Mitigate by recommending key generation not be done mid-deploy.
- Fail-fast must run in every role that starts Lockspire (including worker-only nodes); validate in a shared `Lockspire.Config` called from application start, not only from the Phoenix endpoint boot.
- Rollback caveat: once rows are encrypted, rolling back to pre-1.43 code breaks signing. Document, and ship a `mix lockspire.keys.decrypt`-style escape hatch? (Recommend NO shipped decrypt-to-plaintext task: it re-creates the vulnerability; document manual rollback via restoring a backup instead.)
**Detection:** Decrypt failures concentrated on one node/host (include `node()` in log metadata); worker-only failures.
**Owner:** P-CONFIG + P-DOCS (ordering), P-MIGRATE (gating).

### C6: Concurrent re-encryption racing with key rotation/status changes
**What goes wrong:** Re-encrypt task does read-modify-write per row while admin `activate_key`/`retire_key` or another `reencrypt` run (two nodes) updates the same row. Last-writer-wins can (a) overwrite a status change with a stale struct (if the task writes the whole record), (b) double-encrypt (encrypt an already-encrypted value, wrapping ciphertext as "plaintext"), (c) write old-KEK ciphertext after a KEK rotation pass.
**Why it happens:** `Repository` functions in `signing_key_store.ex` operate on whole `SigningKey` structs; naive task does `get -> decode -> encrypt -> update(struct)`.
**Prevention:**
- Per row, in a transaction: `SELECT ... FOR UPDATE` the row (or `Repo.update_all` with `where: r.id == ^id and r.private_jwk_encrypted == ^old_value` compare-and-swap), update ONLY the `private_jwk_encrypted` column (+ `updated_at`), never the whole struct. If CAS affects 0 rows, re-read and re-evaluate.
- Classify before encrypting: if already `:encrypted` under the target (head) KEK id, skip (idempotent); if encrypted under older kek, decrypt+re-wrap (rotation); if legacy, encrypt. Never encrypt a value classified `:encrypted`.
- Use a PostgreSQL advisory lock (`pg_try_advisory_lock`) for the whole task so two operators/nodes cannot run it concurrently; print "another run in progress".
- Batch by id with small transactions; resumable and safe to Ctrl-C.
- Emit an audit event (existing `transact_with_audit` pattern) per batch/count, not per-key material.
**Detection:** Test with two concurrent task invocations plus an `activate_key` in between; assert final state has no double-wrapped values and status preserved.
**Owner:** P-MIGRATE (legacy), P-ROTATE (KEK rotation, same machinery).

### C7: Partial migration and strict mode enabled too early
**What goes wrong:** Strict mode (reject legacy plaintext) is switched on while some rows remain legacy (task failed midway, a replica/tenant missed, a restored backup reintroduced old rows, or a code path inserts plaintext). Result: those keys become unsignable, possibly the active one.
**Why it happens:** Strict is a config flag independent of data state.
**Prevention:**
- Strict-mode boot check: when `strict: true`, query for non-encrypted rows (`NOT LIKE 'lsk1:%'`, excluding nil/retired as decided) and refuse to start with a clear count and remedy command. Strict mode is only enabled by the host after `mix lockspire.keys.encrypt --check` exits 0 (give the task a `--check`/dry-run exit-code mode for CI/deploy gating).
- Default non-strict with loud periodic warning (boot log + doctor + admin banner) while legacy rows exist; legacy-read telemetry counter so hosts see when it reaches zero.
- Decide what `retired` rows do: re-encrypt them too (they still hold private keys) or delete private material once retired. Recommend: re-encrypt all, and offer scrub of retired private material as a follow-up, not a v1.43 requirement.
- Task must report per-status counts and fail non-zero if any row could not be processed (e.g. nil `private_jwk_encrypted` for `:enc` keys, unparseable legacy rows). Unparseable legacy rows must be listed by id/kid, never silently skipped, and never echoed.
- Plan a future release that removes the ETF fallback entirely (it is a risk surface: `non_executable_binary_to_term` on DB bytes). Mark deprecated in v1.43.
**Detection:** `--check` nonzero; strict boot refusal; legacy-read counter > 0.
**Owner:** P-MIGRATE.

### C8: Leakage of plaintext JWK or KEK via Inspect, logs, telemetry, exceptions, dumps, changesets, LiveView
**What goes wrong:** Specific leak vectors in this codebase:
1. `%SigningKey{}` and `SigningKeyRecord` have no Inspect protection: any `inspect/1`, `Logger.error(inspect(key))`, ExUnit failure output, or crash report prints the column. After this change the column is ciphertext (lower risk) but the decrypted `jwk_map` in process state is plaintext: a `FunctionClauseError` or `MatchError` in `id_token.ex`/`jar.ex` etc. includes the failing term in the exception message and process crash report (stack args), and in Sentry-style reporters.
2. `SigningKeyRecord.changeset/2` casts the field; Ecto's changeset `Inspect` prints `changes`, and `unique_constraint(:kid)` failures return `{:error, changeset}` that flows to callers/LiveView flash/logs. Also `Repository.publish_key` errors.
3. The new KEK config is a plain string in `Application.get_env`: `Application.get_all_env(:lockspire)` dumps, `:sys.get_state`, `Logger` of config on boot, `mix lockspire.doctor` output, and admin Overview pages could print it. `Phoenix.LiveDashboard` environment page shows application env verbatim.
4. Telemetry metadata/audit events (`key_audit_event` merges `metadata`) must never get ciphertext, kek bytes, or decrypted JWK; `kid`, `kek_id`, counts only.
5. `erl_crash.dump` (one already exists in repo root) contains full heap incl. decrypted keys and KEK; hosts' crash dumps ship to object storage.
6. Raw `Jason.decode` of plaintext JWK followed by `rescue _exception` in `PrivateJwk.decode` is fine, but do not add `Logger.error("decode failed: #{inspect(exception)}")`; Jason/`:crypto` errors can include input binaries.
**Prevention:**
- `@derive {Inspect, except: [:private_jwk_encrypted]}` on `SigningKey` and `SigningKeyRecord`; write Inspect-redaction tests that assert `inspect(key)` contains neither ciphertext prefix nor a known test JWK `d` value.
- Represent the KEK in a wrapper struct (`%Lockspire.Crypto.Kek{id, key}` with custom `Inspect` -> `#Kek<id: "k1">`), resolved at boot into `:persistent_term` or a supervised Agent; the raw bytes never sit in `Application.get_env` after load. Support host config as `{:system, ...}`/MFA/function (`runtime.exs` reads env) so nothing secret is in compiled config.
- Remove `private_jwk_encrypted` from changeset errors: build the changeset with the field set via `put_change` after validation, or `Ecto.Changeset` `Inspect` can't be controlled, so instead wrap repo calls and map `{:error, %Ecto.Changeset{}}` to sanitized error before it leaves the storage layer (strip `changes`/`data` of the field).
- Decoded JWK maps: keep scope tiny; decode -> sign -> drop. Do not store in assigns, GenServer state, caches, or ETS. Admin LiveViews already use `to_view`; add a contract test that no admin view/assign struct has `private_jwk_encrypted` or `d`/`p`/`q`/`dp`/`dq`/`qi`/`k` keys (property: render keys LiveView, assert HTML and `socket.assigns` inspect output free of known private values).
- Document `:erl_crash.dump` / core dump hygiene (set `ERL_CRASH_DUMP` off or to restricted dir, `ERL_CRASH_DUMP_BYTES=0`); consider `Process.flag(:sensitive, true)` in the signing helper process or the calling process around decode+sign: this suppresses heap/stack in crash reports and tracing. Recommend as cheap defense (note it affects debugging).
- Existing strong redaction in logs is an AGENTS.md invariant; add the KEK, ciphertext, and decrypted JWK fields to the redaction list/tests.
**Detection:** grep CI: forbid `inspect(` of key structs in `lib/`; redaction tests; `Logger` capture assertions in decrypt-failure tests.
**Owner:** P-REDACT (struct/config/changeset), P-CRYPTO (no logging in decode), P-DOCS (crash dumps).

### C9: KEK in compile-time config baked into releases
**What goes wrong:** If any code reads the KEK with `Application.compile_env` or module attributes (`@kek Application.get_env(...)`), the secret is compiled into `.beam` files in the release/Docker image layers, never changes at runtime, and `runtime.exs` values are ignored (or Mix warns about mismatch and boot fails). `config/config.exs`/`prod.exs` containing the KEK commit it to VCS.
**Why it happens:** Convenience pattern; Lockspire has no existing `compile_env`, so no precedent protects it.
**Prevention:** Read only at runtime via `Application.fetch_env!/2` in a function called at boot (validated once), documented for `config/runtime.exs` + `System.fetch_env!/1`. Add a test/credo-ish grep guard forbidding `compile_env` and module attributes for key config in `lib/`. Installer generator must emit `runtime.exs` snippet (env var `LOCKSPIRE_KEY_ENCRYPTION_KEYS`, format e.g. `kek_id:base64key,kek_id2:base64key2`, first entry is write key) and never write a real key into repo files; it may print a freshly generated example key once to stdout (and `.gitignore`/docs warn). Generator command `mix lockspire.gen.kek` printing a key + id.
**Detection:** `strings _build/prod/rel/... | grep` on a canary KEK in a release smoke test; CI check.
**Owner:** P-CONFIG.

### C10: Tests/fixtures rely on plaintext; strict mode and fail-fast break the suite
**What goes wrong:** Repo-verified: `test/support/seeding_helpers.ex:27` (JSON), `test/support/token_exchange_case.ex:290`, and 9 integration tests insert `:erlang.term_to_binary` blobs directly into `SigningKey`/Repo, ~45 files touch the column. Once fail-fast config is on in `config/test.exs` they still work only while legacy read remains; once strict mode or a prod-like test config is used, or the ETF fallback is deleted later, dozens of tests break at once. Conversely, if tests keep inserting legacy plaintext, they never exercise the encrypted path (false confidence), and the "end-to-end signing proof" can pass on plaintext.
**Prevention:**
- Introduce one test factory `Lockspire.Test.SigningKeys.insert!/1` (or fix `SeedingHelpers`) that encrypts via the production seam (`PrivateJwk.encrypt/2`); migrate the 9 integration tests + `TokenExchangeCase` to it in one mechanical change early (sed-able: the 9 lines share an identical shape `private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid))`).
- Set a fixed test KEK in `config/test.exs` (static 32-byte base64 in the test env only); a distinct second KEK for rotation tests.
- Keep a small, explicit set of legacy-format tests (`private_jwk_test.exs` + migration tests) that deliberately construct JSON and ETF rows; label them `@moduletag :legacy_key_format`.
- E2E proof: assert in the DB that the stored column starts with the prefix and does NOT contain the base64url of the JWK `d`/`k` value, then sign and verify an ID token and access token against JWKS using that row.
- Beware the ordering: change factories in the same phase that makes encrypt-on-write the default, otherwise half the suite flips at once. Land factory conversion BEFORE flipping strict-by-default in any test config.
- `repository_test.exs` (12 hits) and `jwks_controller_test.exs` assert on literal column values; expect to rewrite assertions to "starts with prefix"/round-trip.
**Detection:** Count of `term_to_binary` in `test/` trends to 0 outside legacy tests; CI grep.
**Owner:** P-PROOF (factory and conversion), but sequence it first inside P-CRYPTO since all later phases depend on it.

---

## Moderate Pitfalls

### M1: Demo, clean-room hosts, and CI have no KEK
**What goes wrong:** Fail-fast start now crashes `examples/adoption_demo`, clean-room generated hosts, Docker contract test (`adoption_demo_docker_contract_test.exs`), `make` targets, and GitHub Actions jobs lacking the env var; or the opposite, someone disables fail-fast in those to "make it pass", normalizing insecurity.
**Prevention:** Installer generator writes a dev/test-only KEK into the generated host's `config/dev.exs`/`test.exs` (clearly labeled, fixed value is acceptable in those envs) and a `runtime.exs` prod stanza that requires the env var. Demo Dockerfile/compose gets a documented demo KEK env var. CI workflow env sets a test KEK. Have fail-fast produce an actionable message with the exact generator command. Add a clean-room test that boots a fresh generated host with no manual steps.
**Owner:** P-CONFIG (generator), P-PROOF (clean-room), P-DEPS touches same files.

### M2: Fail-fast config error ergonomics and false positives
**What goes wrong:** Validation accepts a 31-byte or hex-vs-base64 mismatch; a KEK list with duplicate ids; empty list treated as "encryption off"; `kek_id` containing `:`/`$` that corrupts the header delimiter; changing which entry is first silently changes the write key.
**Prevention:** Validate: list non-empty, ids match `~r/^[A-Za-z0-9_-]{1,32}$/` and unique, decoded key exactly 32 bytes, first = write key, rest = read-only. Never allow "disabled" as a valid production state (a dev/test-only explicit opt-out would be a smell; prefer none). Generate ids not derived from key bytes in a leaky way (a truncated SHA-256 of key is acceptable but a raw key prefix is not).
**Owner:** P-CONFIG.

### M3: Mix tasks / migrations running without app config
**What goes wrong:** `mix lockspire.keys.encrypt` run via `mix` without `app.config`/`app.start` lacks runtime.exs-derived KEK in `MIX_ENV=prod` releases (release has no Mix; need `bin/app eval`). Host without Mix in release cannot run the task.
**Prevention:** Provide a callable module `Lockspire.Release.encrypt_keys/0` (eval-able: `bin/my_app eval "Lockspire.Release.encrypt_keys()"`) plus the Mix task wrapper; ensure the task requires `Mix.Task.run("app.config")` and starts only the Repo, not Oban or endpoints (avoid background jobs signing mid-migration). Do NOT put the re-encryption inside an Ecto migration: migrations run before app runtime config in some pipelines, lock tables, and are not re-runnable; keep it an explicit task (already the plan).
**Owner:** P-MIGRATE, P-DOCS.

### M4: KEK rotation edge cases
**What goes wrong:** Rotating while a legacy row exists; removing old KEK before re-wrap complete (see C4); header kek_id points to retired id but still configured read-only forever; re-wrap non-atomic across a crash leaves mixed ids (acceptable, must be tolerated).
**Prevention:** Read path accepts any configured id; write path always head; the same task handles legacy->head and old->head. Test matrix: (legacy, k1, k2) x (head=k1, head=k2). Doctor prints counts per kek_id. Rotation also should remind: rotating the KEK does NOT rotate signing keys; if KEK compromise is suspected, generate new signing keys (existing key rotation workflow), since attacker with old KEK + old DB copy has old private keys.
**Owner:** P-ROTATE.

### M5: Performance regression from decrypting on every sign
**What goes wrong:** AES-GCM is cheap (microseconds), but parsing JSON + decrypt per token is already the case; the risk is accidentally adding a DB round trip or KEK parse (base64 decode, validation) per request, or caching decrypted JWKs in ETS/process dictionary to "optimize" (increases leakage surface).
**Prevention:** KEK parsed once at boot into a struct; no caching of plaintext JWKs. Benchmark one sign path before/after only if the change touches hot loops.
**Owner:** P-CRYPTO.

### M6: Telemetry/audit gaps
**What goes wrong:** No signal for: legacy-read happened, strict refusal, decrypt failure, re-encrypt completed. Operators discover issues via 500s.
**Prevention:** Events `[:lockspire, :key, :decrypt_failed | :legacy_read | :reencrypted]` with metadata `kid`, `kek_id`, `reason`, counts. Audit event on each re-encrypt batch and on strict-mode toggles seen at boot. Subject to the existing redaction contract tests.
**Owner:** P-REDACT / P-MIGRATE.

### M7: Bandit bump (to 1.13.1) breakage in demo / clean-room hosts
**What goes wrong:** Demo pins `~> 1.11`; the bump to 1.13.1 can change: Plug/Thousand Island/WebSock minimum versions (lockfile conflicts with Phoenix 1.8.5 / Plug pins), default HTTP/2 or header-limit behaviors, stricter header/URI size and request-line limits (affecting long `request`/JAR query strings, large DPoP/`Authorization` headers, long PAR/redirect URIs), and changes to `Plug.Conn.Adapter` behavior (e.g. `read_req_body` semantics, `send_file`, chunked handling) that could affect the token endpoint's form parsing, DPoP `htu` URL reconstruction (scheme/port/host derived from conn), and `Plug.Conn.get_peer_data`. Changelog items must be read, not assumed. Because Bandit is not a Lockspire dependency, the bump touches only demo/clean-room `mix.exs` + lockfiles + Docker images; but generated clean-room hosts may resolve a different version if the constraint stays `~> 1.11`.
**Prevention:** Treat as independent, last, low-risk phase (P-DEPS): bump constraint in all host `mix.exs` templates (installer generator template, demo, clean-room fixtures) in one commit; regenerate lockfiles; run full demo e2e + clean-room + DPoP/JAR/PAR e2e (these exercise header/URL-sensitive paths). Read Bandit 1.12/1.13 changelogs for removed options (`:thousand_island_options`, `http_1_options`, `http_2_options`, `http_options`) deprecations in the demo's endpoint config. Verify the 1.13.1 target exists and has no known advisories right before the bump (version number comes from the milestone brief; unverified here). Keep it out of the encryption phases so a regression is bisectable.
**Detection:** Demo boot warnings about unknown options; DPoP `htu` mismatches; 431/414 on large requests.
**Owner:** P-DEPS (final phase; independent of crypto).

### M8: Docs/upgrade ordering that people skip
**What goes wrong:** Hosts upgrade the dep and `mix lockspire.upgrade` but skip KEK setup; fail-fast then takes prod down at deploy. Or they enable strict before migrating (C7).
**Prevention:** `mix lockspire.upgrade` and `lockspire.doctor` print the ordered checklist and detect current state (KEK configured? legacy rows? strict?). CHANGELOG/Release Please entry marked as a breaking-behavior note (new required config) even if API-compatible; consider whether fail-fast for existing installs should be a warning for one minor with a clear removal date vs. hard fail. Recommend: hard fail when ANY key row would be written (generate/rotate) without a KEK, but allow boot with warning if no KEK and only legacy rows? Trade-off: the milestone says fail-fast; choose it, but ensure the error message is the runbook. Executable docs (project priority 5): the docs example should be a tested snippet.
**Owner:** P-DOCS (with P-CONFIG for messages).

---

## Minor Pitfalls

### m1: Column name lies
`private_jwk_encrypted` previously held plaintext; code or ops scripts may assume "encrypted means safe". Keep the name (avoids a migration), but document the format and treat any unprefixed value as legacy. No DDL change needed; column type `bytea` fits. Do not introduce a schema change unless a `kek_id` index is wanted for the doctor scan (a prefix `LIKE` scan on a table of a handful of rows needs no index).

### m2: Base64 variant and padding
Use `Base.url_encode64(padding: false)` consistently; decode with `Base.url_decode64(padding: false)` and treat `:error` as malformed ciphertext. Add a version byte/segment so format v2 (e.g. new algorithm) is possible without ambiguity.

### m3: Duplicate/derived key confusion with `secret_key_base`
Do not fall back to `secret_key_base` "if KEK missing" (explicitly out of scope): `config/test.exs` uses a constant `aaaa...` base, and fallback would create a silent weak path. Fail-fast must not have an escape hatch.

### m4: Decrypt errors turn into 500s with no JWKS impact
JWKS endpoint serves public JWKs and never decrypts: that is good (keeps discovery up during KEK outage). Preserve: do not make JWKS or admin listing decrypt keys. A KEK outage should degrade only signing, and the admin Keys page should show "cannot unlock" per row rather than crash (decode per row, not in list rendering).

### m5: Backups and data remanence
**What goes wrong:** Re-encrypting does not scrub old plaintext in: pg_dump files, WAL archives, PITR snapshots, replicas, dev/staging DB copies, logical dumps in CI, dead tuples/TOAST until vacuum. The CR-01 exposure window includes all of those.
**Prevention:** Docs must state plainly: encryption at rest protects future writes and the live heap; any backup/snapshot taken before migration still holds usable private keys. Therefore after migration, hosts that consider the DB or any backup possibly exposed should rotate signing keys (existing generate -> publish -> activate -> retire flow), not just KEK, and then expire old backups per retention policy. Provide a "rotate signing keys after migration" step as recommended (not mandatory) in the runbook, and a doctor note listing the age of the oldest active key. Optionally run `VACUUM` (full not required) after migration to drop dead tuples; mention WAL cannot be scrubbed. Never claim the migration "removes exposure".
**Owner:** P-DOCS (primary), P-MIGRATE (task completion message).

### m6: Plaintext remains in memory/DB for `:enc` or nil rows
`private_jwk_encrypted` is nullable and `strip_private_key_material` nils it for public views; the migration task must skip `nil` explicitly (not treat as legacy garbage) and must not encrypt the empty string.

---

## Phase-Specific Warnings

| Phase topic | Likely pitfall | Mitigation |
|-------------|---------------|------------|
| P-CRYPTO: format + seam | Prefix ambiguity (C1), no AAD (C2), IV (C3), blanket rescue (C4) | ASCII prefix dispatch, AAD of kek_id/kid/use/alg, random 12-byte IV, distinct error atoms; property tests |
| P-CRYPTO/P-PROOF: test fixtures | 11+ places insert plaintext/ETF (C10) | One encrypting factory, convert all, keep dedicated legacy tests |
| P-CONFIG: KEK config | compile_env (C9), malformed keys (M2), demo/CI missing KEK (M1), worker nodes (C5) | Runtime-only read, strict validation, KEK struct w/ Inspect, generator + dev/test keys, boot in every role, boot scan for orphan kek_ids |
| P-MIGRATE: re-encrypt + strict | Races (C6), partial migration (C7), release without Mix (M3) | Row lock/CAS single-column update, advisory lock, `--check` exit code, strict boot refusal, eval-able release function |
| P-ROTATE: KEK rotation | Removing old KEK early (C4, M4) | Counts per kek_id, doctor gate, documented 4-step order, matrix tests |
| P-REDACT: leak surfaces | Inspect/changeset/telemetry/crash dumps (C8) | `@derive Inspect except`, sanitized changeset errors, Kek struct, `Process.flag(:sensitive)`, redaction contract tests incl. LiveView assigns |
| P-PROOF: e2e | Passing on plaintext path | Assert DB column prefixed and free of `d`; sign+verify through JWKS |
| P-DOCS: upgrade + backups | Wrong ordering (C5, M8), remanence (m5) | Ordered checklist (deploy code + KEK -> migrate -> verify -> strict), recommend signing key rotation, say backups are not scrubbed |
| P-DEPS: Bandit 1.13.1 | Transitive version/limit changes (M7) | Last phase, isolated commit, full demo + clean-room + DPoP/JAR/PAR e2e |

## Suggested ordering implication
P-CRYPTO (+ test factory) -> P-CONFIG -> P-REDACT (can overlap) -> P-MIGRATE -> P-ROTATE -> P-PROOF/E2E -> P-DOCS -> P-DEPS. Deeper research flags: P-MIGRATE (race semantics with existing `signing_key_store` transactions) and P-DEPS (read Bandit 1.12-1.13 changelogs). Others follow standard patterns.

## Confidence

| Claim area | Confidence | Basis |
|-----------|-----------|-------|
| Repo-specific findings (call sites, fixtures, no Inspect derive, no compile_env) | HIGH | Read directly from repo |
| GCM/AAD/format guidance | HIGH | Standard AEAD practice; OTP `crypto_one_time_aead` semantics |
| Exact `:crypto` error behavior across OTP versions (`:error` vs raise) | MEDIUM | Verify on supported OTP versions in P-CRYPTO |
| Ecto changeset Inspect leaking `changes` | MEDIUM-HIGH | Ecto default Inspect shows changes; verify in a test |
| Bandit 1.12-1.13 breaking items | LOW | Not researched against changelog; flagged for phase research |

## Sources

- Repo: `lib/lockspire/protocol/private_jwk.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/storage/ecto/signing_key_record.ex`, `lib/lockspire/storage/ecto/repository/signing_key_store.ex`, `test/support/seeding_helpers.ex`, `test/support/token_exchange_case.ex`, `examples/adoption_demo/mix.exs`, `config/test.exs`
- OTP `:crypto.crypto_one_time_aead/6,7`, NIST SP 800-38D (random 96-bit IV, 2^32 invocation limit), OWASP Cryptographic Storage guidance (practitioner knowledge, not re-fetched this session)
