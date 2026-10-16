---
phase: "155"
slug: "crypto-core-config-seam-bandit-baseline"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-15"
---

# Phase 155 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `155-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData 1.4.0 (test-only, already in deps) |
| **Config file** | `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test <touched test paths>` |
| **Full suite command** | `MIX_ENV=test mix test.fast`; gates `mix qa`, `mix qa.dialyzer`; phase gate `mix ci` + `mix test.clean-room.e2e` |
| **Estimated runtime** | quick < 30 s; full suite several minutes |

Env: `export HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1`

---

## Sampling Rate

- **After every task commit:** touched test files via the quick command (155-01: per-host `mix deps.get --check-locked && mix compile --warnings-as-errors`)
- **After every plan wave:** `MIX_ENV=test mix test.fast`, `mix qa`, `mix qa.dialyzer`
- **Before `/gsd-verify-work`:** `mix ci` and `mix test.clean-room.e2e` green
- **Max feedback latency:** 30 seconds per task

---

## Per-Task Verification Map

Filled by the planner/executor per task. Requirement → test anchors:

| Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|-----------------|-----------|-------------------|-------------|--------|
| DEP-01 | Hosts on bandit 1.13.1 / thousand_island 1.6.x / hpax 1.1.x, mint 1.11.0; e2e green | e2e + lock | `mix test.clean-room.e2e`; per-host `mix deps.get --check-locked` | existing CI | ⬜ pending |
| KEK-01 | Invalid config raises naming key only (sentinel absent) | unit | `MIX_ENV=test mix test test/lockspire/config_key_encryption_test.exs` | ❌ W0 | ⬜ pending |
| KEK-01 | Boot validates + caches; invalid raises | unit (non-async) | `MIX_ENV=test mix test test/lockspire/application_key_encryption_test.exs` | ❌ W0 | ⬜ pending |
| KEK-02 | Absent KEK: generate refuses, no row, legacy still signs, boot warning | integration | `MIX_ENV=test mix test test/lockspire/admin/keys_test.exs` | extend | ⬜ pending |
| KEK-02 | Verify `:key_encryption` check ok/absent/invalid | unit | `MIX_ENV=test mix test test/lockspire/install/verify_test.exs` | extend | ⬜ pending |
| KEK-02 | Doctor `key_encryption` subcommand | mix task | `MIX_ENV=test mix test test/mix/tasks/lockspire_doctor_key_encryption_test.exs` | ❌ W0 | ⬜ pending |
| ENC-01 | New row is `LSK\x01` envelope for current KEK id; fresh IV | unit + integration | `MIX_ENV=test mix test test/lockspire/security/key_encryption_test.exs test/lockspire/admin/keys_test.exs` | ❌ W0 + extend | ⬜ pending |
| ENC-02 | All six consumers read envelope + legacy; per-consumer error shape | unit/integration | `MIX_ENV=test mix test test/lockspire/protocol` | extend | ⬜ pending |
| ENC-02 | JWKS/discovery/KeyCache never decrypt | structural | `MIX_ENV=test mix test test/lockspire/architecture_fitness_test.exs` | extend | ⬜ pending |
| ENC-03 | Tamper/swap/forged kid/unknown KEK/truncated tag rejected; classify property | unit + property | `MIX_ENV=test mix test test/lockspire/security/key_encryption_test.exs` | ❌ W0 | ⬜ pending |
| D-10 | `inspect` omits `private_jwk_encrypted` and KEK bytes | unit | `MIX_ENV=test mix test test/lockspire/domain/signing_key_inspect_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/security/key_encryption_test.exs` — ENC-01/03 incl. first `ExUnitProperties` use
- [ ] `test/lockspire/config_key_encryption_test.exs` — KEK-01 matrix with sentinel-leak assertions
- [ ] `test/lockspire/application_key_encryption_test.exs` — boot raise/warn/cache seam
- [ ] `test/mix/tasks/lockspire_doctor_key_encryption_test.exs` — D-07
- [ ] `test/lockspire/domain/signing_key_inspect_test.exs` — D-10
- [ ] `test/support/key_encryption_helpers.ex` — `put_key_encryption/1` (env + persistent_term + on_exit restore) and sealing helper for shared seeders

No framework install needed.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
