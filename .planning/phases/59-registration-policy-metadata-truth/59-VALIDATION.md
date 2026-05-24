---
phase: 59
slug: registration-policy-metadata-truth
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 59 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/discovery_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` |
| **Estimated runtime** | ~45 seconds |

## Sampling Rate

- **After every task commit:** Run the task-local ExUnit command from the owning plan.
- **After every plan wave:** Run the full Phase 59 suite above.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 60 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 1 | REG-01, REG-02 | T-59-01, T-59-02 | `jwks_uri` is admitted only for the narrow `private_key_jwt` slice and remains xor with inline `jwks`. | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs` | ✅ | ⬜ pending |
| 59-02-01 | 02 | 1 | REG-03 | T-59-03 | Operator surfaces expose derived policy truth without editable crypto sprawl. | unit/liveview | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/admin/server_policy_test.exs` | ✅ | ⬜ pending |
| 59-03-01 | 03 | 2 | META-01, META-02 | T-59-05, T-59-06 | Discovery and endpoint auth metadata reflect actual endpoint capability and publish signing algs only when JWT auth is published. | unit/controller | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-06
