---
phase: 82
slug: shared-dpop-nonce-primitive
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 82 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/lockspire/protocol/dpop_nonce_test.exs test/lockspire/protocol/dpop_test.exs` |
| **Protocol run command** | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run the directly affected protocol test file
- **After every plan wave:** Run the phase-targeted protocol suite
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 82-01-01 | 01 | 1 | NONCE-CORE-01 / NONCE-CORE-04 | T-82-01 / T-82-02 | Shared primitive issues unpredictable purpose-tagged nonces and validates them against the expected surface class | unit | `mix test test/lockspire/protocol/dpop_nonce_test.exs` | ❌ W0 | ⬜ pending |
| 82-01-02 | 01 | 1 | NONCE-CORE-02 / NONCE-CORE-03 | T-82-03 | `DPoP.validate_proof/2` returns typed missing/invalid nonce failures only when nonce enforcement is requested | unit | `mix test test/lockspire/protocol/dpop_test.exs` | ✅ | ⬜ pending |
| 82-02-01 | 02 | 2 | NONCE-AS-01 / NONCE-RS-01 | T-82-03 | Token and protected-resource DPoP adapters preserve nonce-specific failure mapping inputs without collapsing them into generic proof errors | unit | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/protocol/dpop_nonce_test.exs` — dedicated primitive proof for issuance, purpose separation, and expiry behavior

---

## Manual-Only Verifications

All Phase 82 behaviors should be automation-friendly at the protocol/unit layer.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
