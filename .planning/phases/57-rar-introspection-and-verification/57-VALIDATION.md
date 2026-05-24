---
phase: 57
slug: rar-introspection-and-verification
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix ConnTest and Phoenix LiveViewTest |
| **Config file** | `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/consent_live_test.exs --warnings-as-errors` |
| **Full suite command** | `MIX_ENV=test mix test --include integration test/integration/phase57_rar_introspection_verification_e2e_test.exs test/integration/phase43_fapi_milestone_e2e_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/consent_live_test.exs --warnings-as-errors`
- **After every plan wave:** Run `MIX_ENV=test mix test --include integration test/integration/phase57_rar_introspection_verification_e2e_test.exs test/integration/phase43_fapi_milestone_e2e_test.exs --warnings-as-errors`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | RAR-04 | T-57-01 / T-57-02 / T-57-03 | Active-only introspection enrichment returns normalized grant-backed `authorization_details`; inactive responses remain `active: false` | unit + controller | `MIX_ENV=test mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs --warnings-as-errors` | ✅ existing | ⬜ pending |
| 57-01-02 | 01 | 1 | V-01 | T-57-04 | Consent surface structurally shows normalized RAR data without type-aware rendering expansion | liveview | `MIX_ENV=test mix test test/lockspire/web/live/consent_live_test.exs --warnings-as-errors` | ✅ existing | ⬜ pending |
| 57-01-03 | 01 | 1 | V-01, V-02 | T-57-05 | Golden path proves RAR-scoped consent, targeted token issuance, compact-by-reference storage, and narrow FAPI regressions | integration | `MIX_ENV=test mix test --include integration test/integration/phase57_rar_introspection_verification_e2e_test.exs test/integration/phase43_fapi_milestone_e2e_test.exs --warnings-as-errors` | ⚠️ one new file | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/integration/phase57_rar_introspection_verification_e2e_test.exs` — golden-path proof for `RAR-04`, `V-01`, and narrow `V-02`

*If none: "Existing infrastructure covers all phase requirements."*

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

**Approval:** pending
