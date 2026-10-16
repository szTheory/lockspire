# Requirements: Lockspire v1.43 Signing Key Encryption at Rest

**Defined:** 2026-10-15
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.
**Closes:** CR-01 (private signing JWKs stored in plaintext in `private_jwk_encrypted`).
**Research:** [.planning/research/v1.43-key-encryption/SUMMARY.md](research/v1.43-key-encryption/SUMMARY.md) — resolved decisions R1–R8 are binding design input for planning.

## v1.43 Requirements

### Host dependency

- [ ] **DEP-01**: The adoption demo and both clean-room hosts run Bandit 1.13.1 (CVE fix; `mix deps.update bandit thousand_island hpax`) and their end-to-end checks pass, landed before any encryption change.

### Key-encryption config

- [ ] **KEK-01**: A host configures `config :lockspire, :key_encryption, keys: [{id, base64_32_bytes}, ...], current: id, legacy_plaintext: :allow | :reject` in runtime config. Invalid config (bad base64, wrong length, duplicate ids or material, unknown `current`, unknown mode, `:reject` without keys) fails boot with an error naming the config key and never the value. No `secret_key_base` fallback and no compile-time config.
- [ ] **KEK-02**: With the config absent, the app boots and existing keys keep signing; generating a key returns `{:error, :key_encryption_not_configured}` and never writes plaintext; a boot warning, the doctor check and `Install.Verify` report the gap loudly. The upgrade stays non-breaking for existing 1.x installs (user decision 2026-10-15).

### Encryption

- [ ] **ENC-01**: Every newly generated private signing key is stored as an AES-256-GCM envelope (`<<"LSK", 1, kek_id_len, kek_id, iv, tag, ct>>`) sealed with the current key, a fresh random IV, and AAD binding the header and the key's `kid`. Plaintext key material is never written.
- [ ] **ENC-02**: Every signing or decrypting consumer (ID token, logout token, JARM, introspection JWT, token exchange, JAR) reads envelopes and, under `:allow`, legacy JSON/ETF rows through the map-form `PrivateJwk.decode`. Distinct internal failure reasons collapse to the existing `:invalid_signing_key`, so protocol behavior is unchanged; JWKS and discovery never decrypt.
- [ ] **ENC-03**: Tests prove rejection of tampered ciphertext, ciphertext swapped between rows (AAD plus post-decrypt `kid` check), an unconfigured KEK id, and a truncated tag, and that random binaries and legacy formats never classify as envelopes.

### Migration and operations

- [ ] **MIG-01**: An operator encrypts existing legacy rows with `Lockspire.Admin.Keys.reencrypt/1` (release-eval callable) or `mix lockspire.keys.reencrypt`, with `--dry-run`, counts (scanned, encrypted, already current, failed by `kid`), idempotent re-runs, and safety under concurrent runs (row lock plus compare-and-swap on only the ciphertext column).
- [ ] **MIG-02**: An operator verifies readiness with `--check` (non-zero exit while any legacy row remains) and a doctor `key_encryption` check that reports row counts per KEK id and legacy rows.
- [ ] **MIG-03**: With `legacy_plaintext: :reject`, any non-envelope row is refused at read (`:plaintext_key_refused` internally) without trying the legacy parsers.
- [ ] **OPS-01**: An operator rotates the key-encryption key by adding a new `current`, re-encrypting, confirming zero rows remain on the old id, and removing it, without reissuing signing keys; a test matrix covers legacy, old-KEK and new-KEK rows against each current key.
- [ ] **OPS-02**: Encrypt, re-wrap, legacy-read, refusal and decryption-failure events emit audit records and telemetry carrying only ids, counts and reasons.

### Redaction, host surfaces, proof and docs

- [ ] **RED-01**: Private key material, envelope ciphertext and KEK values never appear in logs, telemetry, audit records, `inspect` output (`SigningKey`, `SigningKeyRecord`, the KEK set), changeset errors, admin pages or LiveView assigns; `Lockspire.Redaction` covers the new fields.
- [ ] **HOST-01**: The install generator emits the `runtime.exs` key-encryption config (fresh installs default to `:reject`, key from an environment variable); the test setup provides fixed test KEKs; the adoption demo seeds and the clean-room provider host are configured and store envelopes.
- [ ] **PROOF-01**: CI proves end-to-end signing from encrypted rows for every token type, asserts no stored row holds a plaintext JWK, and runs an upgrade path from plaintext rows through re-encrypt, `--check` and `:reject`.
- [ ] **DOC-01**: Docs give the four-step upgrade order, the KEK rotation runbook, the backup remanence warning (old backups, WAL and replicas still hold usable plaintext keys; rotate signing keys if exposure is possible), the rollback warning (pre-1.43 code cannot read envelopes), separate KEK backup guidance, and the release-note text; `docs/code-walkthrough.md`, `docs/architecture.md` and SECURITY.md reflect the new storage.
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
| DEP-01 | — | Pending |
| KEK-01 | — | Pending |
| KEK-02 | — | Pending |
| ENC-01 | — | Pending |
| ENC-02 | — | Pending |
| ENC-03 | — | Pending |
| MIG-01 | — | Pending |
| MIG-02 | — | Pending |
| MIG-03 | — | Pending |
| OPS-01 | — | Pending |
| OPS-02 | — | Pending |
| RED-01 | — | Pending |
| HOST-01 | — | Pending |
| PROOF-01 | — | Pending |
| DOC-01 | — | Pending |
| SAFE-01 | — | Pending |

**Coverage:**
- v1.43 requirements: 16 total
- Mapped to phases: 0 (filled by roadmap)

---
*Requirements defined: 2026-10-15*
*Last updated: 2026-10-15 after initial definition*
