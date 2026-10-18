# Requirements: Lockspire v1.44 Adopter Polish & Verified 1.6.0

**Defined:** 2026-10-18
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.
**Research:** [v1.44-adopter-polish/SUMMARY.md](research/v1.44-adopter-polish/SUMMARY.md)

## v1.44 Requirements

### Mix Tasks

- [ ] **TASK-01**: A host developer can run `mix lockspire.client.create`, `mix lockspire.doctor.token_format`, and `mix lockspire.doctor.remote_jwks` in a host app whose repo is not already running, and each task starts and stops the host repo itself. The failure is first reproduced in the clean-room harness, and the fix routes through `Lockspire.Install.RepoRunner` (not raw `Ecto.Migrator.with_repo`, not `app.start`), so an already-running repo pool is left untouched.
- [ ] **TASK-02**: When `mix lockspire.client.create` fails validation or a write, the developer sees the real reason (not "repo unavailable"), and a client secret is printed at most once, only after a successful write. Doctor tasks keep their existing exit semantics.
- [ ] **TASK-03**: Each of the three tasks has a test that runs it with no pre-started repo (and a check that an already-started repo's pool is not restarted), and the clean-room SaaS journey invokes all three against a real host.

### Key-Encryption Key Setup

- [ ] **KEK-03**: A host developer can run `mix lockspire.gen.kek` to print a freshly generated key-encryption key (32 random bytes, base64) and the same fail-closed `runtime.exs` snippet the installer prints. `--id` sets a validated key ID (default `YYYY-MM` UTC) and `--raw` prints only the key value. The task writes no files, needs no repo, and emits no logs or telemetry. Its output passes `KeySet` validation, and the installer and task share one snippet builder.
- [ ] **KEK-05**: A host can configure a key-encryption key entry as `{:system, "VAR"}`; Lockspire resolves it at runtime in `Lockspire.Config` (never at compile time and never written back to app env). An unset or empty variable in a configured key list fails boot with an error naming the variable but never a value. It never falls back to "not configured".
- [ ] **KEK-06**: Inspecting or logging a key set never shows key bytes, and every existing guidance message that recommends generating a key (config errors, `mix lockspire.verify`, `mix lockspire.keys.reencrypt`, the upgrade guide) points to `mix lockspire.gen.kek`.

### Admin Keys

- [ ] **KEY-UI-01**: An operator on the admin Keys page sees a read-only "Key protection" line stating whether signing keys are encrypted and under which current encryption key ID. Older-key, unencrypted, unreadable, not-set-up, invalid-config, and could-not-check states each get distinct calm wording, and "could not check" never reads as healthy. A failed check does not hide the key list. It shows no counts per encryption key and no key material, and adds no controls.
- [ ] **KEY-UI-02**: When an operator tries to generate a signing key and no key-encryption key is configured, the page says that no encryption key is set up, that Lockspire will not store signing keys unencrypted, and how to set one up. Other generation errors keep their existing copy.
- [ ] **KEY-UI-03**: New admin wording comes from the PRODUCT.md vocabulary map; new terms are added to the map, and replaced phrases to the retired-wording table, in the same change.

### Docs & Release

- [ ] **DOC-02**: The install, upgrade, and operator guides describe `mix lockspire.gen.kek`, the `{:system, "VAR"}` option, and the Key protection line, and `mix docs.verify` passes on CI Elixir 1.19.5 / OTP 28.
- [ ] **REL-01**: After all v1.44 work is on `main` with CI green, the maintainer re-reads the regenerated Release Please PR #121, confirms its version and changelog cover v1.40–v1.44, and squash-merges it.
- [ ] **REL-02**: lockspire 1.6.0 is published through the protected exact-ref release lane and independently verified: the Hex API checksum matches the manifest and the downloaded tarball, HexDocs serve 1.6.0, the `lockspire-v1.6.0` tag and GitHub release point at the published source SHA, the tarball includes the new Mix tasks, and a clean-room host installs `{:lockspire, "== 1.6.0"}` from Hex in a fresh `HEX_HOME`. The result is recorded in `.planning/RELEASE-TRAIN.md`.

### Safety

- [ ] **SAFE-02**: No protocol behavior, security default, schema, or dependency changes. Private key material and key-encryption keys never appear in task output (except `gen.kek`'s own generated key), logs, telemetry, admin pages, or errors.

## Future Requirements

- **KEK-04**: KMS/Vault key-set provider.
- **SEC-01**: Re-seal the `client_secret_jwt` verifier with a dedicated key.
- **DCR-01**: Enforce DCR default lifetimes (own protocol milestone).
- **OPS-03**: Paged `keys.reencrypt --dry-run`.
- `gen.kek --rotate` two-entry snippet; per-key protection line on the key Show page; `--format json` task output; remaining legacy-plaintext test fixtures.

## Out of Scope

| Feature | Reason |
|---------|--------|
| `gen.kek` writing or editing config files | Secrets must not be written by a generator; print-only matches Rails `db:encryption:init` |
| `{:system, "VAR", "default"}` form | A default would silently weaken the fail-closed KEK contract |
| Per-call env resolution | Env drift mid-run and hot-path cost; resolve at boot / config read |
| Admin buttons to generate, rotate, or re-encrypt a KEK, or to generate unencrypted keys | KEK lifecycle is host-owned and operational; admin stays read-only for it |
| Overview-level key-posture banner | Alarmist for a calm operator surface; the Keys page line is enough |
| Separate 1.6.0 release before the polish | User chose one publish cycle carrying v1.43 + v1.44 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TASK-01 | Phase 158 | Pending |
| TASK-02 | Phase 158 | Pending |
| TASK-03 | Phase 158 | Pending |
| KEK-03 | Phase 159 | Pending |
| KEK-05 | Phase 159 | Pending |
| KEK-06 | Phase 159 | Pending |
| KEY-UI-01 | Phase 160 | Pending |
| KEY-UI-02 | Phase 160 | Pending |
| KEY-UI-03 | Phase 160 | Pending |
| DOC-02 | Phase 161 | Pending |
| REL-01 | Phase 161 | Pending |
| REL-02 | Phase 161 | Pending |
| SAFE-02 | Phase 161 | Pending |

**Coverage:**
- v1.44 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0
- SAFE-02 is owned by Phase 161 (final proof) and constrains Phases 158–160

---
*Requirements defined: 2026-10-18*
*Last updated: 2026-10-18 after v1.44 roadmap creation (Phases 158–161)*
