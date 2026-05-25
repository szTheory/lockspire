---
phase: 90
slug: support-truth-and-milestone-closure
status: completed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 90 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + `mix docs.verify` |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix docs.verify && mix test test/lockspire/release_readiness_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix docs.verify && mix test test/lockspire/release_readiness_contract_test.exs`
- **After every plan wave:** Run `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 90-01-01 | 01 | 1 | META-02 | T-90-01 | Canonical support docs describe the shipped slice narrowly and truthfully | docs | `mix docs.verify` | ✅ | ✅ green |
| 90-01-02 | 01 | 1 | META-02 | T-90-02 | Dedicated guide states scope, denials, and host-owned responsibilities without widening claims | docs | `mix docs.verify && rg -n "client_secret_jwt|HS256|POST /par|FAPI" docs/client-secret-jwt-host-guide.md` | ✅ | ✅ green |
| 90-02-01 | 02 | 2 | PROOF-01 | T-90-03 | Release/docs contract tests pin semantic support facts across docs | unit | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ✅ green |
| 90-02-02 | 02 | 2 | PROOF-01 | T-90-04 | Discovery and runtime proof still match the documented support contract | unit | `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ | ✅ green |
| 90-03-01 | 03 | 3 | META-02 | T-90-05 | Maintainer and adjacent guidance defer to the canonical support contract and record deferred work explicitly | docs | `mix docs.verify && mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `docs/client-secret-jwt-host-guide.md` — create the new sibling guide before plan 01 verification
- [x] `test/support/client_secret_jwt_support_truth.ex` or equivalent — add the shared semantic helper before plan 02 verification

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** completed on 2026-05-25
