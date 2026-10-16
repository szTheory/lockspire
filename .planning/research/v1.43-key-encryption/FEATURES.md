# Feature Research

**Domain:** Operator-facing encryption-at-rest of private signing keys in an embedded OAuth/OIDC library (Phoenix)
**Researched:** 2026-10-15
**Confidence:** MEDIUM. Comparator behavior is from training knowledge of each project's documented design (Hydra, Rails, Cloak, Keycloak, node-oidc-provider, OpenIddict, Doorkeeper), not re-verified live. Repo findings are HIGH (read directly).

## Comparator Takeaways (what operators actually get)

| System | At-rest model for signing/secret material | Operator-facing shape | Lesson for Lockspire |
|--------|-------------------------------------------|-----------------------|----------------------|
| Ory Hydra | `secrets.system` is a list; first entry encrypts, the rest only decrypt. Signing JWKs stored encrypted with it. | Config list; rotation = prepend new, keep old. Rotation story is documented, with no rich UI. Weakness: no first-class "re-wrap all rows" and no visibility into which secret wrote what. | Closest analog. Copy the "first encrypts, all decrypt" list semantics. Beat it by shipping a re-wrap task and per-row key-id visibility. |
| Rails ActiveRecord::Encryption | `primary_key` accepts a list, so old keys still decrypt. `support_unencrypted_data` is the migration switch. Ciphertext carries a header with key reference. Filtered from logs. | Config plus an explicit `encrypt`/re-save loop. Strict mode is the default once the migration switch is off. | Validates the "legacy plaintext read allowed, then strict" pattern and a self-describing ciphertext. |
| Cloak / cloak_ecto (Elixir) | Vault with ordered ciphers. First encrypts, others decrypt. Ciphertext is tagged with the cipher tag. | Library docs describe migration as "load and re-save every row". No dry-run, counts, or admin visibility. | Elixir-idiomatic baseline. A Phoenix team will expect this shape. The gaps (no dry-run, no counts, no strict mode) are our differentiators. |
| Keycloak | Realm keys live in the DB as component config. Provider priority and active/passive/disabled states. A Vault SPI is available for secrets. | Rich admin console. Encryption of key material relies on DB/infra and the Vault SPI, not a first-class KEK. | Key-state UI is already ours. Do not copy the pluggable-SPI breadth. |
| node-oidc-provider | Host supplies `jwks` in config. The library does not persist private keys. | None. The host owns it. | The "host owns the secret" ethos fits. The KEK stays a host-supplied value. |
| OpenIddict | Host supplies signing certificates, which are protected by the platform cert store. | None in-library. | Same as above. |
| Doorkeeper | No signing-key storage. Client secrets are hashed with a configurable strategy. | A migration helper for hashing secrets. | Only analogy: a legacy-data migration path for secrets. |

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| AES-256-GCM envelope encryption on write, decrypt on read, at the two existing seams | This is the CR-01 fix. Without it, nothing else matters. | MEDIUM | Write seam is `Admin.Keys.generate_key/1` (`lib/lockspire/admin/keys.ex`, currently `Jason.encode!`). Read seam is `Protocol.PrivateJwk.decode/1`. The `private_jwk_encrypted` column already exists, so no schema change is needed unless a wrapping-key-id column is added for queryability. Seven consumers go through `PrivateJwk` (id_token, jar, jarm, introspection_jwt, logout_token, token_issuer, access_token_signer). |
| Versioned, self-describing ciphertext carrying a wrapping-key id | Rails and Cloak both tag ciphertext. Needed for rotation and for telling ciphertext from legacy JSON. | LOW | Format like `lsk1.<kid>.<nonce+ct+tag b64url>`. Bind AAD to key `kid`, to prevent row-swap attacks. Detecting plaintext vs ciphertext by prefix keeps `decode/1`'s existing JSON path as the legacy branch. |
| Host-supplied KEK list (first encrypts, all decrypt) | Hydra `secrets.system` and Rails `primary_key` list. Required for rotation. | LOW | Config key is dedicated and never derived from `secret_key_base`. Accept `{id, 32-byte key}` entries. Allow `{:system, "ENV"}` or an MFA/function in `runtime.exs` so the secret is not a compile-time constant. |
| Fail-fast validation on boot | Operators expect misconfig to fail at startup, not on first token request. | LOW | Check at application start: list non-empty, ids unique, keys decode to 32 bytes, and a self-test encrypt/decrypt round trip. Error messages must name the config key and the problem, never the value. |
| Legacy plaintext migration task | Existing installs already hold plaintext rows, and the upgrade must be safe. | MEDIUM | `mix lockspire.keys.encrypt` (name TBD). Must be idempotent (skip rows already ciphertext), transactional per row, and verify by decrypting before commit. Print counts: scanned, encrypted, already-encrypted, failed. Add `--dry-run`. Follows existing `lockspire.upgrade --dry_run` precedent. Exit non-zero on any failure. |
| Legacy plaintext read tolerance during transition | Rails `support_unencrypted_data`. Without it the library cannot boot between deploy and migration. | LOW | `decode/1` already accepts JSON, so keep that branch behind a flag/default-on for 1.43. |
| Strict mode (reject plaintext on read) | Rails equivalent. The end state that actually closes CR-01 for an install. | LOW | Config flag. When on, plaintext rows fail closed with a redacted error. Recommend default off in 1.43 and on in the next major, or default on for fresh installs via generator output. |
| KEK rotation with re-wrap, no key reissue | Hydra/Rails support rotation. Reissuing signing keys would break RPs and is explicitly out of scope. | MEDIUM | Task decrypts with any listed KEK and re-encrypts with the primary. Idempotent, with dry-run and counts. Only the ciphertext changes, so `kid` and the JWKS stay the same. A row that cannot be decrypted by any listed KEK is reported and skipped, never deleted. |
| Redaction of KEK and private JWK material | AGENTS.md security default, "strong redaction in logs and operator surfaces". | LOW-MEDIUM | Extend `Lockspire.Redaction` for KEK config values and the ciphertext. Ensure `inspect/1` on `SigningKey` and the config struct hides them. Make error tuples carry atoms, not payloads. Add a test that greps logs/telemetry/admin HTML. |
| Install generator and docs guidance | Install DX is product priority 1. A missing KEK must not surprise adopters. | MEDIUM | Generator emits a `runtime.exs` snippet reading an env var and a comment on how to generate a key (`:crypto.strong_rand_bytes(32) \|> Base.encode64()`). Never writes a real key into a committed file. Docs cover upgrade, rotation, and backup/restore. |
| End-to-end signing proof plus a CI assertion of no plaintext at rest | Milestone requirement. Catches regression of the single seam. | MEDIUM | Cover id_token, JARM, introspection JWT, token exchange. A CI query asserts no `private_jwk_encrypted` value parses as JSON. |
| Audit events and telemetry for the new lifecycle operations | The repo already emits audit and telemetry for key events. Operators expect migration and rotation to leave a trail. | LOW | New events such as `key_encrypted` / `kek_rewrapped`, carrying the key id and wrapping-key id only. Metadata is counts and ids, never material. |
| Upgrade documentation | Reference for the "deploy, set KEK, run task, enable strict" sequence. | LOW | Slot into `guides/` and `docs/`. Executable-docs convention: a doc test or contract test where feasible. |
| Backup/restore guidance | KEK loss means signing keys are unrecoverable. Operators need to know. | LOW | Docs only. Say that DB backups are now useless without the KEK, so back the KEK up separately. A lost KEK recovery is "generate new signing keys and rotate", which breaks nothing already issued only if old keys are republished. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Doctor subcommand for encryption posture | `mix lockspire.doctor key_encryption` reports KEK count, primary id, rows by wrapping-key id, and plaintext count, without printing material. Cloak and Hydra have nothing like it. | LOW-MEDIUM | `lockspire.doctor` is already a dispatcher. Reuses the same scan the migration task uses. Doubles as the "can I turn on strict yet?" check. Strong candidate for v1.43. |
| Admin Keys page shows per-key "Encrypted with <wrapping-key id>" or "Not yet encrypted" | Nobody exposes this. Security reviewer persona gets proof without a shell. | MEDIUM | Touches `keys_live/index.ex` and `show.ex` plus `Admin.Keys` views (`to_view`/`to_detail_view`). Needs the wrapping-key id derivable from the ciphertext prefix without decrypting. Copy must follow the PRODUCT.md vocabulary. Add a new term (for example "Key protection") to the vocabulary map in the same change. Read-only. No actions from the UI. |
| Overview/Security posture warning when plaintext rows remain or strict is off | Turns a silent risk into a calm, visible nudge. | LOW-MEDIUM | Depends on the same scan. Keep it a single line item, not an alert flood. |
| Rotation task that also supports "retire old KEK safely" check | The task tells you when no row still uses the old KEK id, so removing it from config is safe. | LOW | A by-product of per-id counts. Cheap if the scan exists. |
| Progress output and machine-readable summary (`--format json`) | CI and deploy pipelines can gate on it. | LOW | Optional. Keep human output first. |
| Test helpers for host apps (KEK fixture in `mix lockspire.test.setup`) | Host test suites do not break on fail-fast. | LOW | Dependency on the existing test-setup task. Likely required in practice to avoid breaking adopters' CI, so it may be table stakes in disguise. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Deriving the KEK from `secret_key_base` | Zero config. | Couples session-secret rotation to signing key availability, and `secret_key_base` is widely shared and rotated. It would also silently make a leaked cookie secret a signing-key leak. | A dedicated KEK with a generator-provided env var. |
| Auto-generating and persisting a KEK in the DB or a file | Easier onboarding. | Stores the lock beside the key. That reproduces CR-01 with extra steps. | Fail fast with clear guidance. |
| Admin UI to view, paste, or rotate the KEK | Calm operator workflows. | The KEK is host infrastructure, not product data. Putting it behind a web form puts it in HTTP logs, browser history, and the DB. | Config-only. The UI shows status only. |
| Re-wrap or migrate from an admin button | Convenience. | Long-running bulk crypto against live signing keys in a request cycle, with no dry-run discipline. | Mix task, with the UI pointing to the command. |
| Silent auto-migration at boot | "It just works." | Surprise writes to a security table on deploy, hard to roll back, races across multiple nodes. | Explicit task, with a doctor and a UI nudge. |
| Auto-deleting rows that cannot be decrypted | Cleanup. | Destroys the signing key and can invalidate issued tokens. | Report and skip. Operator decides. |
| KMS/HSM/Vault callback behaviour (pluggable wrap/unwrap) | Enterprise ask. Keycloak has a Vault SPI. | Broadens the host seam, adds latency on the hot signing path, and demands caching and failure semantics. Out of scope for v1.43. | Keep the cipher module internal but narrow so a v2 behaviour can wrap it. Document KMS as a deferred seam. |
| Per-key unique data-encryption keys (DEK) stored separately | "True" envelope encryption. | Extra column and rotation surface for little gain at this scale, where the KEK already wraps a few rows. | A single KEK layer with a per-row random nonce and AAD. Revisit if KMS lands. |
| Deterministic or searchable encryption | Rails offers it. | Nothing to search by here. `kid` and public JWK are already plaintext by design. | Skip. |
| Encrypting the public JWK or `kid` | Thoroughness. | Public by definition. Breaks JWKS publishing. | Leave plaintext. |
| Reissuing signing keys as part of KEK rotation | Seems cleaner. | Breaks relying parties and tokens already in flight. | Re-wrap in place. Signing key rotation stays a separate existing workflow. |

## Feature Dependencies

```
Cipher module (AES-GCM, versioned format, AAD)
    └──requires──> KEK config + fail-fast validation
                       └──requires──> install generator / docs snippet

Write seam (Admin.Keys.generate_key) ──requires──> Cipher module
Read seam (PrivateJwk.decode)        ──requires──> Cipher module + legacy-plaintext branch

Legacy migration task ──requires──> Cipher module, scan of signing_keys
    └──enables──> Strict mode (safe to enable only when plaintext count = 0)
KEK rotation re-wrap task ──requires──> KEK list + per-row wrapping-key id
    └──shares scan code with──> Migration task, Doctor subcommand

Doctor subcommand ──enhances──> Migration and rotation (readiness checks)
Admin Keys "protected with" display ──requires──> wrapping-key id readable from ciphertext prefix (no decrypt)
Overview/Security posture nudge ──requires──> same scan

Redaction ──applies to──> cipher errors, config inspect, audit/telemetry, admin HTML
E2E signing proof ──requires──> Write + read seams working for all 7 consumers
Test setup KEK fixture ──requires──> KEK config (otherwise host CI breaks on fail-fast)

KMS/HSM seam ──conflicts──> v1.43 scope (defer)
Admin-UI KEK entry ──conflicts──> redaction and host-owned-secret boundary
```

### Dependency Notes

- **Strict mode requires migration:** turning it on before the task has run bricks signing. The doctor/posture check is the guard.
- **Admin visibility requires a readable header:** the ciphertext format must expose the wrapping-key id unencrypted (and bind it via AAD). Decide this in the cipher design phase, because retrofitting would need a second migration.
- **Fail-fast breaks host test suites and the demo/clean-room hosts:** these need KEK fixtures, which makes the test-setup and generator work a prerequisite for the Bandit-bump/demo-host proof, not an afterthought.
- **Existing surfaces that must change:** `lib/lockspire/admin/keys.ex` (write seam, views), `lib/lockspire/protocol/private_jwk.ex` (read seam), `lib/lockspire/storage/ecto/signing_key_record.ex` and `signing_key_store.ex` (scan/update helpers), `lib/lockspire/config.ex` (KEK accessor and validation), `lib/lockspire/application.ex` (boot check), `lib/lockspire/redaction.ex`, `lib/lockspire/web/live/admin/keys_live/{index,show}.ex`, `lib/mix/tasks/lockspire.doctor.ex` (new subcommand), `lib/lockspire/install/` plus generator templates (runtime.exs snippet and manifest), `lib/mix/tasks/lockspire.test.setup.ex`, `PRODUCT.md` vocabulary map plus `vocabulary_contract_test.exs`, and `docs/`, `guides/`.

## MVP Definition

### Launch With (v1.43)

- [ ] AES-256-GCM cipher with versioned, key-id-tagged, AAD-bound ciphertext, wired into both seams. This is the CR-01 fix.
- [ ] Dedicated KEK list config, with fail-fast boot validation and redaction.
- [ ] Legacy plaintext read tolerance plus the idempotent migration task (`--dry-run`, counts, non-zero exit on failure), and strict mode.
- [ ] KEK rotation re-wrap task (same engine as migration, so low marginal cost).
- [ ] Audit and telemetry events (ids and counts only).
- [ ] Generator `runtime.exs` snippet, test-setup KEK fixture, upgrade/rotation/backup docs.
- [ ] End-to-end signing proof and the CI "no plaintext at rest" assertion.
- [ ] Bandit 1.13.1 bump in demo and clean-room hosts.

### Add If Cheap Within v1.43 (recommended)

- [ ] `mix lockspire.doctor key_encryption`. It is the same scan, and it gives operators and CI a readiness gate for strict mode.
- [ ] Read-only "Key protection" line on the admin Keys index and show pages, showing the wrapping-key id or "Not yet encrypted". It needs a PRODUCT.md vocabulary entry. Defer the Overview posture banner if the phase gets tight.

### Future Consideration (v2+)

- [ ] KMS/HSM/Vault wrap-unwrap behaviour (host callback seam). Needs failure and caching semantics.
- [ ] Per-row DEK layer, if KMS arrives.
- [ ] Overview posture banner and JSON summary output, if adopters ask.
- [ ] Making strict mode the default for all installs, which is a breaking change for the next major.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Cipher and both seams | HIGH | MEDIUM | P1 |
| KEK list and fail-fast boot | HIGH | LOW | P1 |
| Migration task (dry-run, idempotent, counts) | HIGH | MEDIUM | P1 |
| Strict mode | HIGH | LOW | P1 |
| KEK rotation re-wrap | HIGH | MEDIUM | P1 |
| Redaction and no-plaintext CI proof | HIGH | MEDIUM | P1 |
| Generator snippet, test-setup fixture, docs | HIGH | MEDIUM | P1 |
| Audit and telemetry events | MEDIUM | LOW | P1 |
| Doctor subcommand | MEDIUM-HIGH | LOW-MEDIUM | P2 |
| Admin "Key protection" display | MEDIUM | MEDIUM | P2 |
| Overview posture nudge | LOW-MEDIUM | LOW-MEDIUM | P3 |
| KMS/HSM seam | MEDIUM | HIGH | P3 (v2) |

## Competitor Feature Analysis

| Feature | Hydra | Rails AR Encryption / Cloak | Our Approach |
|---------|-------|------------------------------|--------------|
| Multi-key rotation | Ordered list, first encrypts | Ordered list (primary + previous / ciphers) | Same, with explicit key ids |
| Self-describing ciphertext | Not exposed | Header / tag | Versioned prefix with the key id |
| Legacy migration | Manual | `support_unencrypted_data` (Rails), manual re-save (Cloak) | Dry-run task with counts and strict mode |
| Re-wrap tooling | None built in | Manual loop | Task shared with migration |
| Posture visibility | None | None | Doctor plus read-only admin display |
| KMS | Via infra | Cloak custom cipher | Deferred behaviour seam |

## Sources

- Repo (HIGH): `lib/lockspire/admin/keys.ex`, `lib/lockspire/protocol/private_jwk.ex`, `lib/mix/tasks/lockspire.doctor.ex`, `lib/mix/tasks/lockspire.upgrade.ex`, `lib/lockspire/web/live/admin/keys_live/`, `PRODUCT.md`, `.planning/PROJECT.md`, `AGENTS.md`.
- Ory Hydra `secrets.system` docs, Rails Active Record Encryption guide (`support_unencrypted_data`, key lists), Cloak / cloak_ecto docs, Keycloak server admin guide (realm keys, Vault SPI), node-oidc-provider README (`jwks`), OpenIddict docs (credentials). MEDIUM confidence: recalled, not re-fetched this session.

---
*Feature research for: key-at-rest encryption in an embedded OAuth/OIDC library*
*Researched: 2026-10-15*
