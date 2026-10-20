---
phase: "160"
slug: "admin-key-protection-missing-kek-copy"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-19"
---

# Phase 160 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5-otp-28), Phoenix LiveViewTest, LazyHTML via `HtmlAssertions` |
| **Config file** | `config/test.exs` (KEK ids `test-1` current, `test-2`), `test/test_helper.exs` |
| **Quick run command** | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; cd /Users/jon/projects/lockspire && MIX_ENV=test mix test test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/keys_live/protection_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs` |
| **Full suite command** | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; cd /Users/jon/projects/lockspire && mix ci` |
| **Estimated runtime** | ~20 seconds quick; several minutes full |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** `MIX_ENV=test mix test test/lockspire/web test/lockspire/admin test/lockspire/security`
- **Before `/gsd-verify-work`:** `mix ci` green on 1.19.5-otp-28
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 160-01-01 (tracer) | 01 | 1 | KEY-UI-01, KEY-UI-03 | T-160-02, T-160-03 | Presenter maps all 7 states; unknown term/raise/exit -> could-not-check (neutral, "Unknown"); invalid-config message discarded; PRODUCT.md rows added | unit + LiveView + contract | `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test test/lockspire/web/live/admin/keys_live/protection_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs` | ❌ W0 (protection_test.exs created in this task) | ✅ green |
| 160-01-02 | 01 | 1 | KEY-UI-01, SAFE-02 | T-160-01, T-160-03, T-160-04 | Seven-state page matrix; failed check keeps key list; loaded line renders above an inventory read error; only current KEK id shown; no counts, controls, material; refresh after generate | LiveView | `MIX_ENV=test mix test test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/keys_live/protection_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs test/lockspire/admin/keys_encryption_status_test.exs` | ✅ (extended) | ✅ green |
| 160-02-01 | 02 | 2 | KEY-UI-02, KEY-UI-03 | T-160-06, T-160-07 | Missing-KEK error for sig and enc names no secrets; catch-all byte-identical; buttons stay enabled; repeated refusal stores nothing | LiveView | `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/keys_live/protection_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs` | ✅ (extended) | ✅ green |
| 160-02-02 | 02 | 2 | SAFE-02, KEY-UI-03 | T-160-08 | Stress, leak, status, vocabulary suites green; `mix ci` green; SAFE-02 diff vs dda81e8d empty; PRODUCT.md rows present | contract + full suite + diff | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/security/key_material_leak_test.exs test/lockspire/admin/keys_encryption_status_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/keys_live/protection_test.exs` then `mix ci`, then `git diff --quiet dda81e8d -- mix.exs mix.lock priv lib/lockspire/protocol lib/lockspire/storage lib/lockspire/admin/keys.ex lib/lockspire/admin/keys lib/lockspire/config.ex lib/lockspire/application.ex lib/lockspire/web/components/admin_components.ex lib/lockspire/web/admin_css.ex` | ✅ | ✅ green |

All commands run with `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; cd /Users/jon/projects/lockspire &&` prefixed.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/lockspire/web/live/admin/keys_live/protection_test.exs` — presenter table tests (KEY-UI-01), created in task 160-01-01
- [x] New "key protection" describe block in `test/lockspire/web/live/admin/keys_live_test.exs` — seven-state matrix, failure isolation, disclosure (160-01-01, 160-01-02); describe "missing key-encryption key" generation error (160-02-01)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Copy reads calmly for least technical persona | KEY-UI-03 | tone judgment | Review rendered strings against PRODUCT.md personas |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-19

## Validation Audit 2026-10-20

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
