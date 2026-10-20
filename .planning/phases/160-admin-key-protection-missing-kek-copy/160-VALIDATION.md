---
phase: "160"
slug: "admin-key-protection-missing-kek-copy"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| TBD (filled after planning) | — | — | KEY-UI-01 | — | Could-not-check never healthy; only current KEK id shown | unit + LiveView | `MIX_ENV=test mix test test/lockspire/web/live/admin/keys_live/protection_test.exs test/lockspire/web/live/admin/keys_live_test.exs` | ❌ W0 | ⬜ pending |
| TBD | — | — | KEY-UI-02 | — | Missing-KEK error names no secrets; catch-all unchanged | LiveView | `MIX_ENV=test mix test test/lockspire/web/live/admin/keys_live_test.exs` | ✅ (extended) | ⬜ pending |
| TBD | — | — | KEY-UI-03 | — | N/A | contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/vocabulary_contract_test.exs` | ✅ | ⬜ pending |
| TBD | — | — | SAFE-02 | — | No key material, KEK id list, or counts on page | LiveView + existing | `MIX_ENV=test mix test test/lockspire/security/key_material_leak_test.exs test/lockspire/admin/keys_encryption_status_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/web/live/admin/keys_live/protection_test.exs` — presenter table tests (KEY-UI-01)
- [ ] New "key protection" describe block in `test/lockspire/web/live/admin/keys_live_test.exs` — seven-state matrix, failure isolation, disclosure, generation error

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Copy reads calmly for least technical persona | KEY-UI-03 | tone judgment | Review rendered strings against PRODUCT.md personas |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
