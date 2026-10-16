---
phase: 156-legacy-migration-kek-rotation-plaintext-refusal
verified: 2026-10-16T00:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-01-PLAN.md"
  - ".planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-01-SUMMARY.md"
  - ".planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-02-PLAN.md"
  - ".planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-02-SUMMARY.md"
  - ".planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-03-PLAN.md"
  - ".planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-03-SUMMARY.md"
  - "lib/lockspire/admin/keys.ex"
  - "lib/lockspire/admin/keys/encryption_status.ex"
  - "lib/lockspire/admin/keys/reencrypt.ex"
  - "lib/lockspire/install/verify.ex"
  - "lib/lockspire/protocol/private_jwk.ex"
  - "lib/lockspire/storage/ecto/repository/signing_key_store.ex"
  - "lib/lockspire/storage/ecto/repository/support.ex"
  - "lib/mix/tasks/lockspire.doctor.key_encryption.ex"
  - "lib/mix/tasks/lockspire.keys.reencrypt.ex"
covered_digest: "v3:sha256:969e2259ef7522a811e61fde3ba7eab467e23b3763305225e391321d279963e1"
behavior_unverified: 0
---

# Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal Verification Report

**Phase Goal:** An operator can move an existing install from plaintext rows to fully encrypted storage, rotate the KEK without reissuing signing keys, prove readiness, and turn on plaintext refusal without stranding a key, with every step audited and observable through ids and counts only.
**Verified:** 2026-10-16
**Status:** passed
**Re-verification:** No, initial verification

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Mix task and `Admin.Keys.reencrypt/1` encrypt every legacy row (all statuses, `:sig` and `:enc`); `--dry-run` writes nothing; report has scanned/encrypted/already_current/failed-by-kid; rerun and concurrent runs do not double-wrap | VERIFIED | `Reencrypt.run/3` walks id-keyset pages, one `reencrypt_signing_key` transaction per row (`signing_key_store.ex:187`: `FOR UPDATE` lock, decide, CAS `update_all` on `private_jwk_encrypted` + `updated_at`, audit append, rollback on audit failure). Dry-run path lists with `sensitive: true` and never calls the writer. Task uses `Ecto.Migrator.with_repo`. `reencrypt_concurrency_test.exs` (integration) passed. |
| 2 | `--check` exits non-zero while a legacy or old-KEK row remains, zero once none; retired unsealable keys are stranded and do not block; doctor reports counts per KEK id | VERIFIED | `EncryptionStatus.build/2` classifies via the engine's own `Reencrypt.assess/2`. Sealable retired rows block through `by_kek_id`/`legacy`, and unsealable retired rows go to `stranded_retired` only. `ready?/1` is as specified. Doctor and Verify share `broken_now?/1`. Task, doctor and Verify tests pass. |
| 3 | Under `:reject`, non-envelope rows fail with `:invalid_signing_key` (internally `:plaintext_key_refused`) without running legacy parsers; envelope rows keep signing | VERIFIED | `private_jwk.ex` `decode_stored/2` short-circuits on `classify(bin) == :legacy` before `read_stored`. External shape is unchanged (`decode/1` maps all errors to `:invalid_signing_key`). Consumer tests (ID token, logout, JARM, introspection, exchange, JAR) pass, and the log output confirms `plaintext_key_refused` paths. |
| 4 | Add new current KEK, re-encrypt, zero rows on the old id, remove old key, same kids still sign; legacy/old-KEK/new-KEK matrix passes | VERIFIED | `decide/3` re-wraps `{:envelope, previous}` under the current id with round-trip verification (`seal_and_open`), same kid. Matrix and adjacency tests in `keys_reencrypt_test.exs` pass. |
| 5 | Encrypt and re-wrap write durable audit and telemetry; legacy-read, refusal and decrypt failure are telemetry only; only kid/KEK id/counts/reasons | VERIFIED | Audit event built in `Reencrypt.audit_event/4` with an allowlisted metadata set, appended inside the row transaction. Hot-path events use direct `:telemetry.execute` with `Redaction.for_telemetry`, so there is no audit mirror and no DB write. Telemetry and sentinel leak tests pass. |

**Score:** 5/5 truths verified (0 present, behavior-unverified).

The plan-level behavior-dependent invariants (CAS conflict, no double-wrap, lock ordering) have passing behavioral tests, including the real concurrency integration test. They are not left at presence-only.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|-------------|--------------|--------|----------|
| MIG-01 | 156-01, 156-02, 156-03 | SATISFIED | Engine, task, dry-run, idempotency and concurrency tests |
| MIG-02 | 156-02, 156-03 | SATISFIED | `--check`, `encryption_status/0`, doctor counts, Verify `:key_storage` |
| MIG-03 | 156-03 | SATISFIED | `:reject` refusal before parsers |
| OPS-01 | 156-01, 156-02 | SATISFIED | Rotation matrix, re-wrap keeps kid |
| OPS-02 | 156-01, 156-03 | SATISFIED | Durable audit for encrypt/re-wrap, telemetry-only hot path, leak test |

All five IDs appear in plan frontmatter and are marked Complete in REQUIREMENTS.md. There are no orphaned requirements.

### Review Fixes (72fd022a..04fab11d)

CR-01: `Support.repo_options` now maps `sensitive: true` to `log: false` and `telemetry_event: nil`, and the locked read, CAS, status listing and dry-run listing all use it. WR-01, WR-03, IN-01 and IN-02 are present in the code (`broken_now?/1`, stranded failures, `page_size` validation, `after_lock` narrowed to `%{kid: kid}`).

### Behavioral Spot-Checks

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Phase test files, including integration | `mix test <phase files> --include integration` | 169 tests, 2 properties, 0 failures | PASS |
| Full suite | `mix test --include integration` | 2042 tests, 0 failures, 6 skipped | PASS |

Probe execution: no probe scripts are declared by the phase. Dialyzer and `--warnings-as-errors` compile were not rerun by the verifier.

### SAFE-01

`git diff 32355619..HEAD` over `mix.exs`, `mix.lock` and `priv` is empty, so there is no new dependency or migration. The signing path (`PrivateJwk.decode/1`) performs no DB writes.

### Anti-Patterns

No TBD/FIXME/XXX markers or stubs found in the covered `lib/` files. The files were read in full and are substantive.

### Residual (accepted, deferred)

Protocol signing-path reads and admin `Keys.list_keys/1` still read the key column through non-sensitive queries, so Ecto query telemetry `result` can carry the stored bytes (ciphertext after migration, plaintext before it). This is documented in the review disposition as deferred to Phase 157 RED-01. It does not block the phase goal, which concerns the new migration, status, doctor and verify surfaces, and those are covered.

### Human Verification Required

None.

### Gaps Summary

No gaps. The phase goal is achieved in the codebase.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
