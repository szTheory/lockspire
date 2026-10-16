---
phase: "156"
slug: "legacy-migration-kek-rotation-plaintext-refusal"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: true) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-16"
---

# Phase 156 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `156-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5-otp-28 in CI; StreamData already in deps) |
| **Config file** | `config/test.exs` (KEK ids `test-1`/`test-2`, `legacy_plaintext: :allow`, Sandbox pool) |
| **Env** | `export HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1` |
| **Quick run command** | `mix test <touched test files>` |
| **Integration command** | `mix test --only integration <path>` |
| **Full suite command** | `MIX_ENV=test mix test.fast` plus `mix test --only integration` on the new integration files, then `mix qa` |
| **Estimated runtime** | ~30 s per task file; full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run `mix test <the task's test files>`
- **After every plan wave:** Run `MIX_ENV=test mix test.fast`, `mix test --only integration` on the three new integration files, and `mix qa`
- **Before `/gsd-verify-work`:** `mix qa`, `mix qa.dialyzer`, `MIX_ENV=test mix test.fast`, `MIX_ENV=test mix test.integration`, `mix test.clean-room.e2e`, all green on 1.19.5-otp-28
- **Max feedback latency:** 60 seconds per task

---

## Per-Task Verification Map

Requirement → test map (audited 2026-10-16 on 1.19.5-otp-28: 817 unit tests and 18 integration tests, 0 failures; SAFE-01 diff vs `v1.42` touches only `mix.exs` docs extras added in Phase 157):

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| MIG-01 | Migration/rotation matrix, idempotent rerun, dry-run writes nothing | unit | `mix test test/lockspire/admin/keys_reencrypt_test.exs` | ✅ | ✅ green |
| MIG-01 | Overlapped runs + contender barrier, CAS `{0,_}`, no double wrap | integration | `mix test --only integration test/lockspire/storage/reencrypt_concurrency_test.exs` | ✅ | ✅ green |
| MIG-01 | Mix task e2e with repo not started; exit codes; arg rejection | unit + integration | `mix test --only integration test/mix/tasks/lockspire_keys_reencrypt_test.exs` | ✅ | ✅ green |
| MIG-02 | `encryption_status/0` counts, deep open, `ready?` | unit | `mix test test/lockspire/admin/keys_encryption_status_test.exs` | ✅ | ✅ green |
| MIG-02 | `--check`/doctor/Verify agreement; Verify `:key_storage` broken-now semantics; widened `safely/1` | unit + integration | `mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_doctor_key_encryption_test.exs` | ✅ extended | ✅ green |
| MIG-03 | `:reject` refuses before parsers; envelope still signs; `:enc` refused; external shapes unchanged; engine recovery under `:reject` | unit (non-async) | `mix test test/lockspire/protocol/private_jwk_test.exs test/lockspire/protocol` | ✅ extended | ✅ green |
| OPS-01 | Rotation matrix k1/k2/legacy × current k1/k2, same kids still sign; five-step help text | unit | `mix test test/lockspire/admin/keys_reencrypt_test.exs test/mix/tasks/lockspire_keys_reencrypt_test.exs` | ✅ | ✅ green |
| OPS-02 | Exact metadata key sets per event; hot path has no audit mirror/row; durable `key_encrypted`/`key_rewrapped` in row txn | unit | `mix test test/lockspire/security/key_encryption_telemetry_test.exs test/lockspire/admin/keys_reencrypt_test.exs` | ✅ | ✅ green |
| OPS-02 / C8 | Sentinel leak test across telemetry, audit, logs, task output; CAS write uses `sensitive: true` (no query-log leak) | unit | `mix test test/lockspire/security/key_material_leak_test.exs` | ✅ | ✅ green |
| Architecture | `read_stored` callers restricted; Repository delegates; no Ecto constructs in `repository.ex` | structural | `mix test test/lockspire/architecture_fitness_test.exs test/lockspire/readability_contract_test.exs` | ✅ extended | ✅ green |
| SAFE-01 | No dep/migration/column change | structural | `git diff --exit-code <phase-base> -- mix.exs mix.lock priv/repo/migrations` | n/a | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/lockspire/admin/keys_reencrypt_test.exs`: MIG-01, OPS-01, MIG-03 recovery, audit rows
- [x] `test/lockspire/admin/keys_encryption_status_test.exs`: MIG-02
- [x] `test/lockspire/storage/reencrypt_concurrency_test.exs`: `@moduletag :integration`
- [x] `test/mix/tasks/lockspire_keys_reencrypt_test.exs`: arg validation (unit) + e2e (integration)
- [x] `test/lockspire/security/key_encryption_telemetry_test.exs`
- [x] `test/lockspire/security/key_material_leak_test.exs`
- [x] `test/support/key_encryption_helpers.ex`: `reset_decode_warnings/0`, row seeding helpers using `config/test.exs` KEK material
- [x] Extend `private_jwk_test.exs`, `verify_test.exs`, `lockspire_doctor_key_encryption_test.exs`, `architecture_fitness_test.exs`

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-10-16

## Validation Audit 2026-10-16

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
