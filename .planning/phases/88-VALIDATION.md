---
phase: 88
slug: shared-client-secret-jwt-runtime
status: completed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 88 — Validation Strategy

> Per-phase validation contract for runtime-only `client_secret_jwt` routing, sealed verifier material, and representative shared direct-client proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/audit/event_test.exs test/lockspire/protocol/discovery_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60-150 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command above or the task-local command from the verification map.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** under 3 minutes for the quick path.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 88-01-01 | 01 | 1 | AUTH-01, AUTH-02 | T-88-01 | Runtime JWT method resolution is explicit while discovery publication stays unchanged. | unit/regression | `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/discovery_test.exs` | ✅ | ✅ green |
| 88-01-02 | 01 | 1 | AUTH-01, AUTH-02 | T-88-02 | Shared auth dispatches to `ClientSecretJwt.verify/3` only for registered `client_secret_jwt` clients and never falls back. | unit | `mix test test/lockspire/protocol/client_auth_test.exs` | ✅ | ✅ green |
| 88-01-03 | 01 | 1 | AUTH-02 | T-88-03 | Routing and mismatch tests prove fail-closed `invalid_client` behavior without assertion leakage. | unit | `mix test test/lockspire/protocol/client_auth_test.exs` | ✅ | ✅ green |
| 88-02-01 | 02 | 2 | AUTH-01 | T-88-06 | Secret issuance and rotation persist sealed verifier material without exposing raw secrets at rest. | unit/integration | `mix test test/lockspire/storage/ecto/client_record_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |
| 88-02-02 | 02 | 2 | AUTH-01, AUTH-02 | T-88-04, T-88-05 | The symmetric verifier accepts valid HS256 assertions only and rejects disallowed algorithms and FAPI-effective profiles. | unit | `mix test test/lockspire/protocol/client_auth_test.exs` | ✅ | ✅ green |
| 88-02-03 | 02 | 2 | AUTH-02 | T-88-06 | Audit and telemetry metadata stay redacted for symmetric verifier failures. | unit | `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/audit/event_test.exs` | ✅ | ✅ green |
| 88-03-01 | 03 | 3 | AUTH-01 | T-88-07 | Representative shared direct-client surfaces accept valid `client_secret_jwt` callers via the one shared runtime path. | integration | `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` | ✅ | ✅ green |
| 88-03-02 | 03 | 3 | AUTH-02 | T-88-08 | Invalid signature, audience, replay, algorithm, and method-mismatch cases fail consistently as `invalid_client`. | integration | `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` | ✅ | ✅ green |
| 88-03-03 | 03 | 3 | AUTH-02 | T-88-09 | Audit normalization stays runtime-only and does not depend on Phase 89 or 90 truth changes. | unit | `mix test test/lockspire/audit/event_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing ExUnit infrastructure covers the phase. No browser-only or manual verification gate is required.

---

## Manual-Only Verifications

None expected. Phase 88 should be provable through repo-native unit and integration tests only.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage.
- [x] Sampling continuity: no three consecutive tasks without an automated check.
- [x] Wave 0 coverage is already present.
- [x] No watch-mode flags.
- [x] Feedback latency stays within the quick-run target.
- [x] `nyquist_compliant: true` can be set after execution proof is complete.

**Approval:** completed on 2026-05-25
