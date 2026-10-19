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

Filled by the planner per task; see 159-RESEARCH.md "Phase Requirements -> Test Map" for the requirement-to-test mapping (KEK-03 gen.kek unit + cold test, KEK-05 config_key_encryption_test extensions, KEK-06 redaction proof + guidance contract test).

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
