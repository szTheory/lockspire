---
phase: 89
slug: registration-discovery-and-admin-truth
status: completed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 89 - Validation Strategy

> Per-phase validation contract for `client_secret_jwt` registration truth, discovery truth, and admin/operator parity.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90-180 seconds |

---

## Sampling Rate

- **After every task commit:** run the task-local verify command or the quick command above.
- **After every plan wave:** run `mix test`.
- **Before `$gsd-verify-work`:** full suite must be green.
- **Max feedback latency:** under 3 minutes for the quick path.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 89-01-01 | 01 | 1 | REG-01 | T-89-01 | DCR and operator creation accept `client_secret_jwt` only for confidential clients with explicit supported signing-alg metadata. | unit/integration | `mix test test/lockspire/protocol/registration_test.exs test/lockspire/admin/clients_test.exs` | ✅ | ✅ green |
| 89-01-02 | 01 | 1 | REG-01, REG-02 | T-89-02 | RFC 7592 full-replace semantics require the alg when staying on `client_secret_jwt`, clear it when switching away, and never preserve stray JWT metadata. | unit/integration | `mix test test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |
| 89-01-03 | 01 | 1 | REG-01, REG-02 | T-89-03 | Typed persisted client truth round-trips through storage without exposing raw secret or verifier material. | unit | `mix test test/lockspire/storage/ecto/client_record_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/admin/clients_test.exs` | ✅ | ✅ green |
| 89-02-01 | 02 | 2 | META-01 | T-89-04 | Discovery publishes `client_secret_jwt` only on mounted endpoints that actually share the verifier. | unit/http | `mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ | ✅ green |
| 89-02-02 | 02 | 2 | META-01 | T-89-05 | Endpoint signing-alg metadata publishes truthful mixed JWT unions: `HS256` for `client_secret_jwt` plus allowed asymmetric algorithms for `private_key_jwt`. | unit/http | `mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ | ✅ green |
| 89-02-03 | 02 | 2 | META-01 | T-89-06 | FAPI-effective issuer posture suppresses `client_secret_jwt` and `HS256` publication while preserving current asymmetric truth. | unit/http | `mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ | ✅ green |
| 89-03-01 | 03 | 3 | REG-02 | T-89-07 | Admin client creation and detail surfaces show one coherent auth-method and signing-alg story without generic algorithm editing. | integration | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/admin/clients_test.exs` | ✅ | ✅ green |
| 89-03-02 | 03 | 3 | REG-02, META-01 | T-89-08 | Global DCR policy and operator copy describe the narrow `client_secret_jwt` slice truthfully and do not overstate trust posture. | integration | `mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/admin/server_policy_test.exs` | ✅ | ✅ green |
| 89-03-03 | 03 | 3 | REG-02 | T-89-09 | Secret-handling truth remains redacted across admin and DCR surfaces after the metadata changes. | unit/integration | `mix test test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing ExUnit and LiveView test infrastructure covers the phase. No additional harness or external dependency is needed.

---

## Manual-Only Verifications

None expected. The phase should be provable through repo-native protocol, persistence, controller, and LiveView tests only.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage.
- [x] Sampling continuity: no three consecutive tasks without an automated check.
- [x] Wave 0 coverage is already present.
- [x] No watch-mode flags.
- [x] Feedback latency stays within the quick-run target.
- [x] `nyquist_compliant: true` can be set after execution proof is complete.

**Approval:** completed on 2026-05-25
