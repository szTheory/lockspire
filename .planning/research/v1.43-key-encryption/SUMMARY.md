# Project Research Summary: v1.43 Signing Key Encryption at Rest

**Milestone:** v1.43 (closes CR-01: private signing JWKs stored in plaintext)
**Inputs:** [STACK.md](STACK.md) · [FEATURES.md](FEATURES.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [PITFALLS.md](PITFALLS.md)
**Confidence:** HIGH for the design and integration points; MEDIUM for comparator details and the Bandit 1.13.1 step (released 2026-10-15, not soaked).

> Persisted by the orchestrator: the synthesizer returned this document inline because subagent report writes were blocked (#222 self-heal). Section R8 was added by the orchestrator after checking the key-generation call sites.

## Executive Summary

Lockspire generates and persists its own signing keys, so it owns an at-rest obligation. `private_jwk_encrypted` (an existing `:binary` column) holds plaintext JSON today. The established pattern (Rails ActiveRecord::Encryption, Cloak, Ory Hydra `secrets.system`) is an ordered key list, a key id carried in the ciphertext, the current key encrypting while all configured keys decrypt, and a switch that tolerates legacy plaintext during migration. Build exactly that on OTP `:crypto` AES-256-GCM, with zero new Hex dependencies, a fixed-layout binary envelope, and no schema migration.

Three moving parts:

1. A pure module `Lockspire.Security.KeyEncryption` (seal / open / classify).
2. Encryption at the single write seam (`Admin.Keys.generate_key/1`) and decryption at the single read seam (`Protocol.PrivateJwk`), so plaintext exists only between decode and sign.
3. One re-encryption engine (public function plus a thin Mix task) serving both legacy migration and key-encryption-key (KEK) rotation, guarded by row locks and compare-and-swap.

Config is an explicit `:key_encryption` block in `runtime.exs`, validated at boot.

The risks are operational, not cryptographic: a missing or wrong KEK turns signing into an outage; a rolling deploy can write envelopes old nodes cannot read; enabling strict mode before migration makes legacy keys unsignable. Mitigations: fail-closed decoder errors with distinct internal reasons, a doctor and `--check` gate instead of a boot-time DB scan, a four-step rollout order (deploy code and KEK everywhere → re-encrypt → verify → reject plaintext), and an explicit warning that rolling back to pre-1.43 code breaks signing once rows are encrypted.

## Key Findings

**Stack:** `:crypto.crypto_one_time_aead/7` with `:aes_256_gcm`; 32-byte KEK used directly (no KDF); random 12-byte IV per seal; 16-byte tag, always pattern-matched exactly (decrypt returns `:error` rather than raising, and does not check tag length itself). Plaintext stays the `Jason.encode!/1` JWK bytes. Rejected: cloak, `Plug.Crypto.encrypt` (PBKDF2 from `secret_key_base`, no key id), HKDF for an already random KEK, JWE via JOSE (stored `alg` header widens the algorithm-confusion surface), per-record data keys, a custom Ecto type.

**Features:** Table stakes are envelope encryption on write and read across every signing consumer; a dedicated KEK list with fail-fast validation; an idempotent migration with dry-run and counts; legacy-read tolerance plus a plaintext-refusal mode; rotation by re-wrap; audit and telemetry carrying ids and counts only; generator snippet, test KEK fixture and docs; end-to-end signing proof and a CI no-plaintext assertion; the Bandit bump in demo and clean-room hosts. Differentiator in scope: a doctor `key_encryption` check. Deferred: admin "Key protection" line, KMS/Vault behaviour, overview banner, default-reject.

**Architecture:** New pure `Security.KeyEncryption`; `Config.key_encryption!/0` validated and cached at boot; `PrivateJwk.decode` becomes envelope-aware and takes the signing-key map so `kid` is always paired; `Admin.Keys.reencrypt/1` and `encryption_status/0`; storage stays an opaque binary store plus one locked-batch method. No decryption in storage loaders or `to_domain` (that would spread plaintext into structs, assigns and logs). No decrypted-key cache; `KeyCache` holds only public JWKs in a `:public` ETS table and must stay that way. Key generation is operator-initiated only (Admin API / admin Keys page); there is no scheduled automatic generation.

**Pitfalls:** C1 prefix ambiguity (dispatch strictly on the prefix, never fall through); C2 row swap (AAD binds header and `kid`, plus a post-decrypt `kid` check); C3 nonce reuse (fresh random IV on every seal, including re-wrap); C4 KEK loss or mismatch → outage (distinct error reasons, doctor counts per KEK id); C5 rolling-deploy ordering; C6 concurrent re-encrypt races; C7 strict mode too early (`--check` gate); C8 leakage via `Inspect`, changesets, logs, telemetry, crash dumps; C9 KEK in compile-time config; C10 plaintext test fixtures.

## Resolved Decisions

**R1. Config name and shape.**

```elixir
config :lockspire, :key_encryption,
  keys: [{"2026-10", kek_new_b64}, {"2026-04", kek_old_b64}],
  current: "2026-10",
  legacy_plaintext: :allow
```

`:key_encryption` matches the module and `Config.key_encryption!/0`. `legacy_plaintext: :allow | :reject` names exactly what it governs ("strict" overpromises). An explicit `current:` beats first-entry-is-primary because reordering must never silently change the write key. Library default is `:allow` so upgrades do not strand legacy rows; the fresh-install generator emits `:reject`.

**R2. Envelope and AAD.** Binary layout:

```
<<"LSK", 1, kek_id_len::8, kek_id::binary-size(kek_id_len),
  iv::binary-size(12), tag::binary-size(16), ciphertext::binary>>
```

Leading bytes are disjoint from the legacy forms (`{` 0x7B for JSON, 131 for ETF, `L` 0x4C for the envelope), so dispatch is a strict match with no fall-through. The column is bytea, so there is no base64 overhead. AAD = `"lockspire.signing_key.v1" <> <<0>> <> header_through_kek_id <> <<0>> <> kid`: binding the header defeats KEK-id/version downgrade, and binding `kid` (unique, known before insert) defeats row swaps. After decrypt, require the JSON `"kid"` to equal the row's `kid`, else `:kid_mismatch`. `PrivateJwk.decode` becomes map-form only (`%{kid: kid, private_jwk_encrypted: bin}`); remove the binary-only `decode/1` so no caller can omit `kid`.

**R3. Plaintext-refusal enforcement point.** Decoder refusal plus doctor and `--check` gate; no DB query at boot. With `legacy_plaintext: :reject`, decode returns `{:error, :plaintext_key_refused}` for any non-envelope value, emits redacted telemetry and never tries the legacy parsers. The pre-flip gate is `mix lockspire.keys.reencrypt --check` (non-zero exit while any legacy row remains) and the doctor check. Rationale: `Application.start/2` runs in every role and before repo readiness is guaranteed; a boot scan couples boot to schema state.

**R4. KMS/provider seam.** Defer. `KeyEncryption` takes an already-resolved key set as an argument and never reads app env, so a later provider behaviour can resolve keys and pass them in.

**R5. Helpers and UI.** Doctor `key_encryption` check: in scope (reuses `encryption_status/0`; it is the reject-mode gate). Admin "Key protection" line: deferred (needs a PRODUCT.md vocabulary entry and contract updates; widens a security milestone). `mix lockspire.gen.kek`: deferred (errors and docs print `openssl rand -base64 32`).

**R6. Bandit 1.13.1 placement.** First plan of the first phase, landed green before any crypto commit, so host regressions cannot be confused with crypto regressions. Pin `== 1.13.1` in `examples/adoption_demo/mix.exs` (currently `~> 1.11`), `test/clean_room/provider_host/mix.exs:22` and `test/clean_room/confidential_client/mix.exs:22` (currently `== 1.12.5`); refresh `compatibility/phoenix_1_8_live_view_1_1/mix.lock`. Run `mix deps.update bandit thousand_island hpax` in each host (1.13.1 needs `thousand_island ~> 1.6` and `hpax ~> 1.1`; updating only bandit will not resolve). Not 1.13.0, which 1.13.1 partially reverts. Library `mix.exs` is unchanged.

**R7. Phase count.** Three phases (155–157). A fourth would split docs from proof without reducing risk; Phase 157 is the split candidate if planning overruns.

**R8. Missing vs invalid KEK config (orchestrator addendum).** The research's literal "fail-fast when missing" makes every existing 1.x install fail to boot after a routine upgrade, which is a semver-breaking change. Because key generation is operator-initiated only, a narrower rule closes CR-01 without that break:

- **Invalid config** (bad base64, wrong length, duplicate ids/material, `current` not in `keys`, unknown `legacy_plaintext` value): fail fast at boot, naming the config key, never the value.
- **Absent config:** boot normally; existing legacy keys keep signing; `generate_key` refuses with `{:error, :key_encryption_not_configured}` (never writes plaintext); a boot warning, doctor and `Install.Verify` fail loudly. `legacy_plaintext: :reject` without keys is invalid config.

This keeps the upgrade non-breaking while guaranteeing no new plaintext is ever written. It is the one decision with a user-visible compatibility consequence and should be confirmed with the user when requirements are approved.

**Other resolutions:**

- Migration entry point: public `Lockspire.Admin.Keys.reencrypt/1` (callable from release `eval`), plus a thin `mix lockspire.keys.reencrypt` with `--dry-run` and `--check`. Not an Ecto migration.
- Concurrency: per-batch `SELECT … FOR UPDATE` plus compare-and-swap on the ciphertext, re-classifying after the lock; concurrent runs stay idempotent without an advisory lock.
- Scope of rows: re-encrypt every row with private material, including retired and `use: :enc` rows. Scrubbing retired material is out of scope.
- Audit: one event per row (`key_encrypted` / `key_rewrapped`) carrying `kid` and KEK id only.
- No orphan-KEK boot scan (per R3): decoder returns `:unknown_kek`; doctor reports rows per KEK id, so an old KEK is removed only at zero rows.
- `Process.flag(:sensitive, true)`: not adopted (process-wide side effects); document crash-dump hygiene instead.
- KEK in memory: validated once at boot into a struct with redacted `Inspect`, held in `:persistent_term`. Residual: the raw value remains in app env as configured; `{:system, "ENV"}` resolution is a follow-up.
- Key id: `\A[A-Za-z0-9._-]{1,32}\z`, unique. Key material: standard or URL-safe base64 decoding to exactly 32 bytes; reject all-identical bytes and duplicate material under different ids.
- Decode failure reasons: `:kek_not_configured`, `:unknown_kek`, `:decryption_failed`, `:malformed_envelope`, `:kid_mismatch`, `:plaintext_key_refused`; all collapse to `:invalid_signing_key` at the protocol edge (no protocol behaviour change). JWKS and discovery never decrypt, so they stay up during a KEK outage.
- Test config: fixed test KEK in `config/test.exs` with `legacy_plaintext: :allow`; a second KEK for rotation tests; reject-mode tests toggle via a helper that re-puts `:persistent_term` and run non-async.
- Fixture count: sources disagree (≈45 vs ≈60 files; 9–18 integration sites). Use a fresh grep at plan time. Only `test/support/seeding_helpers.ex:27` and `test/support/token_exchange_case.ex:290` are shared helpers that must seal; most integration fixtures can stay legacy under `:allow`.

## Constraints

- No new Hex dependencies (OTP `:crypto` and stdlib only).
- No rename of `private_jwk_encrypted`; no schema migration (KEK id lives in the header).
- No decrypted-key caching (no ETS, process dictionary, or `KeyCache` change).
- No OAuth/OIDC protocol behaviour change; plaintext refusal is opt-in.
- Preserve security defaults (PKCE S256, exact redirect matching, hashed client secrets, single-use short codes, refresh rotation with family revocation, no implicit flow, no `alg=none`) and strong redaction across logs, telemetry, changesets and admin surfaces. Add KEK and envelope fields to `Lockspire.Redaction`.
- No KEK in compile-time config or `compile_env`; no `secret_key_base` fallback; never write plaintext when the KEK is absent.
- Any admin copy follows the PRODUCT.md vocabulary and retired-wording table (this milestone adds none, per R5).
- The `client_secret_jwt` verifier sealing (`Security.Policy`, `Plug.Crypto.encrypt` from `secret_key_base`) is out of scope; follow-up candidate.

## Implications for Roadmap

### Phase 155: Crypto core, config seam and Bandit baseline (DEP, KEK, ENC)

- 155-01: Bandit 1.13.1 bump (standalone; demo and clean-room green before crypto commits).
- 155-02: `Security.KeyEncryption` (seal, open, classify); `Config.key_encryption!/0` KEK-set struct; boot validation in `Application.start/2` per R8; fixed test KEK. Tests: tamper, AAD swap, unknown KEK, short tag, property test that random/legacy binaries never classify as envelopes.
- 155-03: `generate_key/1` seals (refuses when unconfigured); `decode` envelope-aware under `:allow`; the six read sites plus fetch-only guards pass the map; `audit_writer_test.exs:449` to map form; shared seeding helpers seal before any reject-mode test exists; `@derive {Inspect, except: [:private_jwk_encrypted]}` on `SigningKey` and `SigningKeyRecord`.
- Avoids C1, C2, C3, C9, C10. Why first: later phases depend on these seams and the factory.

### Phase 156: Legacy migration, KEK rotation and plaintext refusal (MIG, OPS)

- 156-01: `Keys.reencrypt/1` engine (lock, re-classify, round-trip verify, CAS update of only the column and `updated_at`); `SigningKeyStore` locked-batch method plus behaviour callback and repository delegate; `mix lockspire.keys.reencrypt` wrapper; KEK rotation uses the same engine.
- 156-02: `legacy_plaintext: :reject` refusal; `Keys.encryption_status/0`; doctor and `Install.Verify` checks; per-row audit; telemetry for legacy reads, refusals and decrypt failures (ids and reasons only).
- Delivers: idempotent migration; rotation proven (add new current key, re-encrypt, confirm zero rows on old id, remove old key); reject mode safe to enable.
- Avoids C4, C5, C6, C7 (test matrix over legacy / k1 / k2 rows × current k1 / k2).
- Research flag: lock and CAS semantics against existing `signing_key_store` transactions (activate, retire, `publish_key` upserts).

### Phase 157: Host surfaces, redaction sweep and release proof (RED, HOST, PROOF, DOC)

- Redaction: redacted KEK `Inspect`; `Lockspire.Redaction` additions (atom and string forms); sweep across logs, telemetry, admin HTML and LiveView assigns; changeset errors sanitized before leaving storage.
- Hosts: generator `runtime.exs` snippet with fresh-install `:reject`; demo `priv/repo/seeds.exs:93` seals via the public API; clean-room provider host gets a test KEK for `bootstrap.ex:5`; demo Docker/compose documents a demo-only KEK.
- Proof: end-to-end signing with encrypted rows across ID token, JARM, introspection JWT, token exchange, logout token and JAR decrypt (`:enc`); DB assertion that every stored value starts with the envelope prefix and contains no plaintext `d`/`k`; upgrade test from plaintext rows (reencrypt → check → reject); rotation matrix end to end.
- Docs: four-step upgrade order; rotation runbook; backup remanence note (pre-migration backups, WAL, replicas still hold usable keys; recommend rotating signing keys after migration if exposure is possible); rollback warning (pre-1.43 code cannot read envelopes; no decrypt-to-plaintext task); back up the KEK separately from DB backups; do not generate keys mid-rollout; update `docs/code-walkthrough.md`, `docs/architecture.md`, SECURITY.md and guides.
- Release: the squash-merge title becomes the changelog entry, so it must state the new key-encryption config and upgrade steps.

**Ordering rationale:** Bandit first for a clean host baseline; seams and factory before migration; migration and gate before host docs; the `Inspect` derive lands with the structs in 155 and the full redaction sweep runs last.

**Research flags:** 155-01 (read the Bandit 1.12.x → 1.13.1 changelog and deprecated endpoint options); 155-02 (prototype `crypto_one_time_aead/7` tag-mismatch and wrong-size behaviour on the CI OTP); 156-01 (lock/CAS semantics). Standard patterns: 156-02, 157.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack | HIGH | OTP `:crypto` semantics from erlang.org docs |
| Features | MEDIUM | Comparators recalled, not re-fetched; repo read directly |
| Architecture | HIGH | Integration points inspected; envelope not yet prototyped |
| Pitfalls | HIGH | Repo facts verified; OTP error behaviour across versions MEDIUM |
| Bandit 1.13.1 | MEDIUM | Requirements verified on hex.pm; released 2026-10-15; breaking list unverified |

**Gaps to close at plan time:** existing telemetry/audit naming conventions (155-02, 156-02); confirm `KeyCache` holds no private material (155-03); fresh fixture grep; residual app-env exposure of the raw KEK (document; follow-up); whether LiveDashboard's environment page could display app env.

## Out of Scope

Admin "Key protection" UI; `mix lockspire.gen.kek`; KMS/Vault behaviour; scrubbing retired material; re-sealing the `client_secret_jwt` verifier; renaming the column; a `kek_id` column; per-row data keys; reissuing signing keys on KEK rotation; the DCR default-lifetime semantics todo.

## Sources

erlang.org `crypto` docs (`crypto_one_time_aead/6,7`); hex.pm Bandit package and CHANGELOG; repo files `lib/lockspire/admin/keys.ex`, `lib/lockspire/protocol/private_jwk.ex`, `lib/lockspire/storage/ecto/signing_key_record.ex`, `lib/lockspire/storage/ecto/repository/signing_key_store.ex`, `lib/lockspire/config.ex`, `lib/lockspire/application.ex`, `lib/lockspire/security/policy.ex`, `lib/lockspire/redaction.ex`, `lib/lockspire/key_cache.ex`, the core-tables migration, the three Bandit pins, `test/support/seeding_helpers.ex`, `test/support/token_exchange_case.ex`, `examples/adoption_demo/priv/repo/seeds.exs`, `test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex`. Comparator designs (Hydra, Rails, Cloak, Keycloak, node-oidc-provider, OpenIddict, Doorkeeper) are MEDIUM confidence, from prior knowledge.
