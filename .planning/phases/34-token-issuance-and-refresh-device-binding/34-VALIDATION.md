---
phase: 34
slug: token-issuance-and-refresh-device-binding
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix on Elixir `1.19.5` |
| **Config file** | `mix.exs` aliases and `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/protocol/token_endpoint_dpop_test.exs -x` |
| **Full suite command** | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` |
| **Estimated runtime** | ~25 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest task-local command from the per-task verification map; default smoke command is `MIX_ENV=test mix test test/lockspire/protocol/token_endpoint_dpop_test.exs -x`
- **After every plan wave:** Run `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/web/token_controller_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | DPoP-05 | T-34-01 | Shared token-endpoint DPoP context resolves bearer vs DPoP issuance, records replay use, and collapses proof failures to `invalid_dpop_proof` | protocol seam | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_endpoint_dpop_test.exs -x` | ✅ | ⬜ pending |
| 34-01-02 | 01 | 1 | DPoP-06 | T-34-02 | Auth-code issuance returns truthful `token_type` and persists identical durable `cnf.jkt` on access and refresh tokens | protocol + controller | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/web/token_controller_test.exs -x` | ✅ | ⬜ pending |
| 34-02-01 | 02 | 2 | DPoP-07 | T-34-05 | Refresh rotation storage compares `expected_cnf` atomically, preserves child-token binding on match, and avoids mutation on mismatch | protocol + repository | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/refresh_exchange_test.exs -x` | ✅ | ⬜ pending |
| 34-02-02 | 02 | 2 | DPoP-07 | T-34-04 | Refresh exchange requires the correct proof key for DPoP-bound families, collapses proof-key failures to `invalid_grant`, and keeps bearer rotation unchanged | protocol + repository | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/refresh_exchange_test.exs -x` | ✅ | ⬜ pending |
| 34-03-01 | 03 | 2 | DPoP-08 | T-34-08 | Device-code redemption reuses the shared issuance context at `/token`, persists DPoP binding on success, and preserves bearer/error paths | protocol | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs -x` | ✅ | ⬜ pending |
| 34-03-02 | 03 | 2 | DPoP-08 | T-34-07 | End-to-end device flow proves DPoP binding happens only at `/lockspire/token` while `/verify` stays unchanged and replay still collapses to `invalid_grant` | integration | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/integration/phase32_device_flow_token_exchange_e2e_test.exs -x` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
