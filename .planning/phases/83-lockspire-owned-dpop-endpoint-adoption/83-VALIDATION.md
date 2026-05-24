---
phase: 83
slug: lockspire-owned-dpop-endpoint-adoption
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-24
---

# Phase 83 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick `/token` run command** | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/web/token_controller_test.exs` |
| **Quick `/userinfo` run command** | `mix test test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/web/userinfo_controller_test.exs` |
| **Full phase run command** | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/web/token_controller_test.exs test/lockspire/web/userinfo_controller_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run the directly affected protocol/controller suite
- **After every plan wave:** Run the full phase-targeted suite
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 83-01-01 | 01 | 1 | NONCE-AS-01 / NONCE-AS-02 | T-83-01 | Supported Lockspire-owned `/token` grant paths return `use_dpop_nonce` only for missing/invalid authorization-server nonce and succeed on retry with the supplied nonce | integration | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs` | ✅ | ⬜ pending |
| 83-01-02 | 01 | 1 | NONCE-AS-01 / NONCE-AS-02 | T-83-02 | `/token` emits exact `400`, JSON error, `DPoP-Nonce`, and exposed header semantics for retryable nonce failures | integration | `mix test test/lockspire/web/token_controller_test.exs` | ✅ | ⬜ pending |
| 83-02-01 | 02 | 2 | NONCE-RS-01 / NONCE-RS-02 | T-83-03 | Protected-resource nonce failures remain protocol-owned and retry succeeds only with a valid resource-server nonce | unit | `mix test test/lockspire/protocol/protected_resource_dpop_test.exs` | ✅ | ⬜ pending |
| 83-02-02 | 02 | 2 | NONCE-RS-01 / NONCE-RS-02 | T-83-04 | `/userinfo` emits exact `401`, DPoP challenge, `DPoP-Nonce`, exposed headers, and retry success semantics | integration | `mix test test/lockspire/web/userinfo_controller_test.exs` | ✅ | ⬜ pending |
| 83-03-01 | 03 | 3 | NONCE-AS-03 / NONCE-RS-03 | T-83-02 / T-83-03 / T-83-04 | Replay, `ath`, binding, MTLS, wrong-scheme, and bearer paths keep their pre-nonce reason codes and status semantics when nonce support is active | unit + integration | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/web/token_controller_test.exs test/lockspire/web/userinfo_controller_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

None. The core protocol/controller test files already exist; this phase extends them.

---

## Manual-Only Verifications

All Phase 83 behaviors should be automation-friendly at the protocol and controller layers.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify coverage
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
