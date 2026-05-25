---
phase: 91
slug: jwks-uri-rotation-diagnostics-and-remediation-truth
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 91 - Validation Strategy

> Per-phase validation contract for remote `jwks_uri` rotation truth, diagnostics, and support-surface alignment.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/jarm_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/integration/phase62_private_key_jwt_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~120-240 seconds |

---

## Sampling Rate

- **After every task commit:** run the task-local verify command or the quick command above.
- **After every plan wave:** run `mix test`.
- **Before `$gsd-verify-work`:** run `mix test` and `mix docs.verify`.
- **Max feedback latency:** under 4 minutes for the quick path.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 91-01-01 | 01 | 1 | JWKS-01, JWKS-02 | T-91-01 | Shared remote-JWKS diagnosis preserves fetch, freshness, and unsupported-rollover distinctions instead of flattening them immediately. | unit | `mix test test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/jarm_test.exs` | ✅ | ⬜ pending |
| 91-01-02 | 01 | 1 | JWKS-01 | T-91-02 | Remote rotation succeeds only through the bounded refresh posture Lockspire claims to support. | integration | `mix test test/lockspire/protocol/client_auth_test.exs test/integration/phase62_private_key_jwt_e2e_test.exs` | ✅ | ⬜ pending |
| 91-01-03 | 01 | 1 | JWKS-02 | T-91-03 | Unsupported rollover shapes are classified explicitly and do not masquerade as supported cache-refresh recovery. | unit | `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/jarm_test.exs` | ✅ | ⬜ pending |
| 91-02-01 | 02 | 2 | JWKS-01, JWKS-02 | T-91-04 | Operator/admin surfaces show remote-JWKS posture and remediation without exposing raw JWKS bodies or assertions. | integration | `mix test test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ | ⬜ pending |
| 91-02-02 | 02 | 2 | JWKS-02 | T-91-05 | Doctor or verify-task output distinguishes configuration, transport, payload, freshness, and unsupported-rollover causes. | integration | `mix test test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ | ⬜ pending |
| 91-02-03 | 02 | 2 | JWKS-01 | T-91-06 | Docs and support truth describe the exact bounded refresh posture and explicit non-goals. | docs | `mix docs.verify && mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 91-03-01 | 03 | 3 | JWKS-01, JWKS-02 | T-91-07 | End-to-end proof covers supported rotation recovery, failed refresh with cache preservation, and generic OAuth wire behavior. | integration | `mix test test/integration/phase62_private_key_jwt_e2e_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/jwks_fetcher_test.exs` | ✅ | ⬜ pending |
| 91-03-02 | 03 | 3 | JWKS-02 | T-91-08 | Release-contract or docs-truth assertions fail when runtime diagnostics and published support wording drift apart. | docs/unit | `mix test test/lockspire/release_readiness_contract_test.exs && mix docs.verify` | ✅ | ⬜ pending |
| 91-03-03 | 03 | 3 | JWKS-01, JWKS-02 | T-91-09 | Full regression stays green with the new diagnosis layer integrated across fetcher, verifier, operator surface, and docs. | regression | `mix test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

Existing ExUnit, LiveView, integration, and docs-verification infrastructure cover the phase. No extra harness is required.

---

## Manual-Only Verifications

None expected. This phase should remain fully repo-provable.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage.
- [x] Sampling continuity: no three consecutive tasks without an automated check.
- [x] Wave 0 coverage is already present.
- [x] No watch-mode flags.
- [x] Feedback latency stays within the quick-run target.
- [x] `nyquist_compliant: true` can stay set if execution follows this contract.

**Approval:** planned on 2026-05-25
