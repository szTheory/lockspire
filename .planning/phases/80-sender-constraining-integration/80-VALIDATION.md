---
phase: 80
slug: sender-constraining-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 80 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test` against the touched plug/protocol test file
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 80-01-01 | 01 | 1 | VAL-BIND-01 | T-80-01 / T-80-02 | DPoP-bound tokens carry normalized binding metadata and generic DPoP validation accepts only matching proof material | unit | `mix test test/lockspire/protocol/protected_resource_dpop_test.exs` | ✅ | ⬜ pending |
| 80-02-01 | 02 | 2 | VAL-BIND-01 | T-80-01 / T-80-03 / T-80-04 | `EnforceSenderConstraints` rejects missing, malformed, replayed, wrong-`ath`, and wrong-`jkt` DPoP proofs | unit | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs` | ❌ W0 | ⬜ pending |
| 80-03-01 | 03 | 3 | VAL-BIND-02 | T-80-05 | MTLS-bound tokens reject missing or mismatched client certificates | unit | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs` | ❌ W0 | ⬜ pending |
| 80-03-02 | 03 | 3 | VAL-BIND-03 / VAL-DX-02 / VAL-DX-03 | T-80-03 / T-80-04 / T-80-05 | `RequireToken` emits correct `Bearer` vs `DPoP` challenge headers and preserves differentiated failure reasons | unit | `mix test test/lockspire/plug/require_token_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/plug/enforce_sender_constraints_test.exs` — core sender-constraint plug coverage for DPoP and MTLS paths

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
