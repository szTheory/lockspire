---
phase: 84
slug: host-plug-pipeline-docs-and-milestone-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
---

# Phase 84 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.ConnTest |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs`
- **After every plan wave:** Run `MIX_ENV=test mix test test/lockspire/web/userinfo_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/lockspire/release_readiness_contract_test.exs`
- **Before `$gsd-verify-work`:** `mix ci` must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 84-01-01 | 01 | 1 | NONCE-RS-01 | T-84-01 | Host-route nonce failures render `401`, `WWW-Authenticate: DPoP ... error=\"use_dpop_nonce\"`, `DPoP-Nonce`, and exposed nonce header via the strict plug boundary. | unit | `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs` | ✅ | ⬜ pending |
| 84-01-02 | 01 | 1 | NONCE-RS-03 | T-84-02 | Existing bearer, missing-proof, MTLS, replay, and `401`/`403` semantics stay unchanged while shared rendering is introduced. | unit | `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs test/lockspire/web/userinfo_controller_test.exs` | ✅ | ⬜ pending |
| 84-02-01 | 02 | 1 | NONCE-TRUTH-01 | T-84-03 | Supported-surface and protected-route docs describe only the shipped nonce-backed Phoenix plug surface. | release contract | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 84-02-02 | 02 | 1 | NONCE-TRUTH-02 | T-84-03 | Install/onboard and protected-route docs keep host-policy ownership and the narrow shipped-pipeline phrase explicit. | release contract | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 84-03-01 | 03 | 2 | NONCE-RS-02 | T-84-04 | Generated-host protected-route retry succeeds when the client retries with the issued resource-server nonce. | integration | `MIX_ENV=test mix test test/integration/phase81_generated_host_route_protection_e2e_test.exs` | ✅ | ⬜ pending |
| 84-03-02 | 03 | 2 | NONCE-TRUTH-03 | T-84-05 | `/token`, `/userinfo`, and generated-host protected-route nonce proof all remain present and green in repo-native tests. | integration + release contract | `MIX_ENV=test mix test test/lockspire/web/token_controller_test.exs test/lockspire/web/userinfo_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
