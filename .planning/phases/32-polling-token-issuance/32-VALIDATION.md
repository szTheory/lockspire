---
phase: 32
slug: polling-token-issuance
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
updated: 2026-04-28T14:30:00Z
---

# Phase 32 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/web/token_controller_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test` |
| **Estimated runtime** | ~20-40 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs test/lockspire/protocol/token_exchange_test.exs`
- **After every plan wave:** Run `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/web/token_controller_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 40 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | DEV-09 | T-32-01 / T-32-02 | durable poll interval state and single-winner consume are row-locked and replay-safe | integration | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs` | ✅ | ✅ green |
| 32-02-01 | 02 | 2 | DEV-07 | T-32-03 | `TokenExchange.exchange/1` accepts the device grant and reuses shared issuance/auth helpers | integration | `MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs` | ✅ | ✅ green |
| 32-02-02 | 02 | 2 | DEV-08 | T-32-01 / T-32-04 | pending, slow_down, denied, expired, and replay outcomes map to RFC-shaped public errors | integration | `MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/web/token_controller_test.exs` | ✅ | ✅ green |
| 32-03-01 | 03 | 3 | DEV-08 | T-32-05 | approved `openid` requests can still receive `id_token` and normal token JSON | integration | `MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/web/token_controller_test.exs` | ✅ | ✅ green |
| 32-03-02 | 03 | 3 | D-24 | T-32-06 | discovery truth advertises the device grant only when `/token` support is actually shipped | unit/controller | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ | ✅ green |
| 32-03-03 | 03 | 3 | DEV-07 / DEV-08 / DEV-09 | T-32-01 through T-32-05 | end-to-end `/device/code` -> host approval -> `/token` success and replay-failure proof exists | integration | `MIX_ENV=test mix test test/integration/phase31_generated_host_verification_e2e_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/lockspire/storage/ecto/repository_device_authorization_test.exs` — add poll timing, device-code lookup, and consume/replay cases
- [x] `test/lockspire/protocol/token_exchange_test.exs` — add device grant protocol cases for pending, slow_down, denied, expired, invalid_grant, success, and optional `id_token`
- [x] `test/lockspire/web/token_controller_test.exs` — add HTTP response proof for device polling
- [x] `test/lockspire/protocol/discovery_test.exs` — add device grant metadata assertions
- [x] `test/lockspire/web/discovery_controller_test.exs` — add device grant publication assertions
- [x] `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` or equivalent extension to existing Phase 31 E2E proof

---

## Manual-Only Verifications

All phase behaviors should be automatable inside the Lockspire repo. No manual-only validation is expected for Phase 32.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 40s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
