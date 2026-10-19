---
phase: "159"
slug: "key-encryption-key-setup-dx"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-19"
---

# Phase 159 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5-otp-28) |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; cd /Users/jon/projects/lockspire && MIX_ENV=test mix test test/mix/tasks/lockspire_gen_kek_test.exs test/lockspire/config_key_encryption_test.exs test/lockspire/upgrade_guide_contract_test.exs test/lockspire/install/verify_test.exs test/lockspire/kek_guidance_contract_test.exs` |
| **Full suite command** | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; cd /Users/jon/projects/lockspire && mix ci` |
| **Estimated runtime** | ~30 seconds quick; several minutes full |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** `MIX_ENV=test mix test test/lockspire test/mix test/integration/install_generator_test.exs`
- **Before `/gsd-verify-work`:** `mix ci` green on 1.19.5-otp-28 (includes `mix docs.verify`, format, credo, topology)
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

All commands run with `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; cd /Users/jon/projects/lockspire &&` prefixed.

| Task | Plan | Wave | Requirement | Threat Ref | Test Type | Automated Command | File Exists | Status |
|------|------|------|-------------|------------|-----------|-------------------|-------------|--------|
| 159-01-T1 (tracer) | 01 | 1 | KEK-03 | T-159-01, T-159-04 | e2e CLI + unit | `MIX_ENV=test mix compile --warnings-as-errors >/dev/null && MIX_ENV=test mix lockspire.gen.kek --raw \| python3 -c ...` (44 chars, 32 bytes) and `MIX_ENV=test mix test test/mix/tasks/lockspire_gen_kek_test.exs test/lockspire/security/key_encryption_test.exs` | W0 (gen_kek_test new) | ⬜ pending |
| 159-01-T2 | 01 | 1 | KEK-03, KEK-06 | T-159-02 | unit | `MIX_ENV=test mix test test/mix/tasks/lockspire_gen_kek_test.exs test/integration/install_generator_test.exs` + grep gate (no Logger/telemetry/File/Repo in task and builder) | yes after T1 | ⬜ pending |
| 159-01-T3 | 01 | 1 | KEK-03 | T-159-03, T-159-05 | cold subprocess (clean room) | `MIX_ENV=test mix test test/integration/phase133_provider_install_test.exs --only gen_kek`; `python3 scripts/acceptance/clean_room/build_provider.py --check-bootstrap`; journey `--only happy_path` | yes (extended) | ⬜ pending |
| 159-02-T1 | 02 | 1 | KEK-05 | T-159-06, T-159-07, T-159-08 | unit (async: false) | `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test test/lockspire/config_key_encryption_test.exs` + grep gate (one System.fetch_env, no compile_env/put_env/trim) | yes (extended) | ⬜ pending |
| 159-02-T2 | 02 | 1 | KEK-05, KEK-06 | T-159-06, T-159-09 | unit | `MIX_ENV=test mix test test/lockspire/config_key_encryption_test.exs test/lockspire/install/verify_test.exs test/lockspire/install/task_error_test.exs` | yes (extended) | ⬜ pending |
| 159-03-T1 | 03 | 2 | KEK-06 | T-159-10 | unit | `MIX_ENV=test mix test test/lockspire/config_key_encryption_test.exs test/lockspire/install/verify_test.exs test/lockspire/install/task_error_test.exs` | yes | ⬜ pending |
| 159-03-T2 | 03 | 2 | KEK-06, KEK-05 | T-159-10, T-159-11 | contract + docs build | `MIX_ENV=test mix test test/lockspire/upgrade_guide_contract_test.exs test/lockspire/documentation_contract_test.exs test/mix/tasks/lockspire_keys_reencrypt_test.exs test/mix/tasks/lockspire_doctor_key_encryption_test.exs && mix docs.verify` | yes | ⬜ pending |
| 159-03-T3 | 03 | 2 | KEK-06 (D-10), SAFE-02 | T-159-10, T-159-12 | contract + phase gate | `MIX_ENV=test mix test test/lockspire/kek_guidance_contract_test.exs ...`; `mix ci && MIX_ENV=test mix test --only integration`; `git diff --quiet 0ba2b724 -- mix.exs mix.lock priv lib/lockspire/protocol lib/lockspire/storage lib/lockspire/security/key_encryption/key_set_inspect.ex` | W0 (contract test new) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/lockspire_gen_kek_test.exs` — KEK-03 unit coverage
- [ ] `test/mix/tasks/lockspire_gen_kek_cold_test.exs` — subprocess proof gen.kek runs when host runtime.exs raises (or clean-room step)
- [ ] `test/lockspire/kek_guidance_contract_test.exs` — D-10 contract (no `openssl rand` in lib/docs without gen.kek)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| No new deps/schema/protocol change | SAFE-02 | diff review | `git diff --stat main -- mix.exs mix.lock priv lib/lockspire/protocol` is empty |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
