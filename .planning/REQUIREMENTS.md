# Requirements: Lockspire v1.43 Signing Key Encryption at Rest

**Defined:** 2026-10-15
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.
**Closes:** CR-01 (private signing JWKs stored in plaintext in `private_jwk_encrypted`).
**Research:** [.planning/research/v1.43-key-encryption/SUMMARY.md](research/v1.43-key-encryption/SUMMARY.md) — resolved decisions R1–R8 are binding design input for planning.

## v1.43 Requirements

### Host dependency

- [x] **DEP-01**: The adoption demo and both clean-room hosts run Bandit 1.13.1 (CVE fix; `mix deps.update bandit thousand_island hpax`) and their end-to-end checks pass, landed before any encryption change.

### Key-encryption config

- [x] **KEK-01**: A host configures `config :lockspire, :key_encryption, keys: [{id, base64_32_bytes}, ...], current: id, legacy_plaintext: :allow | :reject` in runtime config. Invalid config (bad base64, wrong length, duplicate ids or material, unknown `current`, unknown mode, `:reject` without keys) fails boot with an error naming the config key and never the value. No `secret_key_base` fallback and no compile-time config.
- [x] **KEK-02**: With the config absent, the app boots and existing keys keep signing; generating a key returns `{:error, :key_encryption_not_configured}` and never writes plaintext; a boot warning, the doctor check and `Install.Verify` report the gap loudly. The upgrade stays non-breaking for existing 1.x installs (user decision 2026-10-15).

### Encryption

- [x] **ENC-01**: Every newly generated private signing key is stored as an AES-256-GCM envelope (`<<"LSK", 1, kek_id_len, kek_id, iv, tag, ct>>`) sealed with the current key, a fresh random IV, and AAD binding the header and the key's `kid`. Plaintext key material is never written.
- [x] **ENC-02**: Every signing or decrypting consumer (ID token, logout token, JARM, introspection JWT, token exchange, JAR) reads envelopes and, under `:allow`, legacy JSON/ETF rows through the map-form `PrivateJwk.decode`. Distinct internal failure reasons collapse to the existing `:invalid_signing_key`, so protocol behavior is unchanged; JWKS and discovery never decrypt.
- [x] **ENC-03**: Tests prove rejection of tampered ciphertext, ciphertext swapped between rows (AAD plus post-decrypt `kid` check), an unconfigured KEK id, and a truncated tag, and that random binaries and legacy formats never classify as envelopes.

### Migration and operations

- [x] **MIG-01**: An operator encrypts existing legacy rows with `Lockspire.Admin.Keys.reencrypt/1` (callable on a running node via `bin/app rpc`) or `mix lockspire.keys.reencrypt`, with `--dry-run`, counts (scanned, encrypted, already current, failed by `kid`), idempotent re-runs, and safety under concurrent runs (row lock plus compare-and-swap on only the ciphertext column).
- [x] **MIG-02**: An operator verifies readiness with `--check` (non-zero exit while any row the task can re-encrypt is not yet on the current key-encryption key, whatever its status, or while an upcoming, active or retiring key cannot be re-encrypted; retired keys that cannot be re-encrypted are listed as stranded and do not block it) and a doctor `key_encryption` check that reports row counts per KEK id and legacy rows.
- [x] **MIG-03**: With `legacy_plaintext: :reject`, any non-envelope row is refused at read (`:plaintext_key_refused` internally) without trying the legacy parsers.
- [x] **OPS-01**: An operator rotates the key-encryption key by adding a new `current`, re-encrypting, confirming zero rows remain on the old id, and removing it, without reissuing signing keys; a test matrix covers legacy, old-KEK and new-KEK rows against each current key.
- [x] **OPS-02**: Encrypt and re-wrap write durable audit records and telemetry; legacy-read, refusal and decryption-failure emit telemetry only; all carry only ids, counts and reasons.

### Redaction, host surfaces, proof and docs

- [x] **RED-01**: Private key material, envelope ciphertext and KEK values never appear in logs, telemetry, audit records, `inspect` output (`SigningKey`, `SigningKeyRecord`, the KEK set), changeset errors, admin pages or LiveView assigns; `Lockspire.Redaction` covers the new fields.
- [x] **HOST-01**: The install generator emits the `runtime.exs` key-encryption config (fresh installs default to `:reject`, key from an environment variable); the test setup provides fixed test KEKs; the adoption demo seeds and the clean-room provider host are configured and store envelopes.
- [ ] **PROOF-01**: CI proves end-to-end signing from encrypted rows for every token type, asserts no stored row holds a plaintext JWK, and runs an upgrade path from plaintext rows through re-encrypt, `--check` and `:reject`.
- [x] **DOC-01**: Docs give the four-step upgrade order, the KEK rotation runbook, the backup remanence warning (old backups, WAL and replicas still hold usable plaintext keys; rotate signing keys if exposure is possible), the rollback warning (pre-1.43 code cannot read envelopes), separate KEK backup guidance, and the release-note text; `docs/code-walkthrough.md`, `docs/architecture.md` and SECURITY.md reflect the new storage.
- [ ] **SAFE-01**: No new Hex dependencies, no schema migration, no rename of `private_jwk_encrypted`, no decrypted-key caching, no OAuth/OIDC behavior change; PKCE S256, exact redirect matching, hashed client secrets, single-use short-lived codes, refresh rotation with family revocation, no implicit flow, no `alg=none`, and strong redaction are preserved.

## Future Requirements

- **KEY-UI-01**: Admin Keys pages show a read-only "Key protection" line (needs a PRODUCT.md vocabulary entry).
- **KEK-03**: `mix lockspire.gen.kek` helper to generate a key.
- **KEK-04**: KMS/Vault provider behaviour that resolves the key set (the cipher module already takes a resolved key set).
- **KEK-05**: `{:system, "ENV"}` resolution so the raw KEK does not persist in app env.
- **SEC-01**: Re-seal the `client_secret_jwt` verifier with a dedicated key instead of `secret_key_base`.
- **DCR-01**: DCR default lifetime semantics (pending todo `2026-10-13-audit-dcr-default-lifetime-semantics.md`).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Deriving the KEK from `secret_key_base` | Rotating `secret_key_base` would silently strand every signing key |
| Auto-generating or storing the KEK in the DB or a file | Defeats encryption at rest; the host owns secret custody |
| Entering, rotating or migrating keys from the admin UI | Secret custody and bulk rewrites belong to deploy-time operator tooling |
| Silent auto-migration at boot or a boot-time DB scan | Couples boot to schema state in every node role |
| Decrypt-to-plaintext task | Would recreate CR-01 and invite unsafe rollbacks |
| Per-row data keys, JWE envelope, cloak or other new deps | Extra complexity and attack surface without a CR-01 benefit |
| Renaming `private_jwk_encrypted` or adding a `kek_id` column | Host migration cost; the name becomes true and the header carries the id |
| Scrubbing retired key material | Separate lifecycle decision |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEP-01 | Phase 155 | Complete |
| KEK-01 | Phase 155 | Complete |
| KEK-02 | Phase 155 | Complete |
| ENC-01 | Phase 155 | Complete |
| ENC-02 | Phase 155 | Complete |
| ENC-03 | Phase 155 | Complete |
| MIG-01 | Phase 156 | Complete |
| MIG-02 | Phase 156 | Complete |
| MIG-03 | Phase 156 | Complete |
| OPS-01 | Phase 156 | Complete |
| OPS-02 | Phase 156 | Complete |
| RED-01 | Phase 157 | Complete |
| HOST-01 | Phase 157 | Complete |
| PROOF-01 | Phase 157 | Pending |
| DOC-01 | Phase 157 | Complete |
| SAFE-01 | Phase 157 | Pending |

**Coverage:**
- v1.43 requirements: 16 total
- Mapped to phases: 16 (Phase 155: 6, Phase 156: 5, Phase 157: 5)
- Unmapped: 0 ✓
- SAFE-01 is a cross-cutting constraint on every phase; Phase 157 owns its final proof.

---
*Requirements defined: 2026-10-15*
*Last updated: 2026-10-15 after v1.43 roadmap creation (Phases 155–157)*
