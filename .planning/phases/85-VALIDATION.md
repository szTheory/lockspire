---
phase: 85
slug: dcr-intake-and-representation
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-24
---

# Phase 85 — Validation Strategy

> Per-phase validation contract for DCR logout metadata intake, persistence, and readback truth.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/web/registration_json_test.exs test/lockspire/web/controllers/registration_controller_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command above.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** under 2 minutes for the quick path.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 85-01-01 | 01 | 1 | DCR-01, DCR-02, DCR-03, DCR-04, DCR-05 | T-85-01 | Only supported absolute logout URIs and real boolean semantics are accepted; malformed input fails as `invalid_client_metadata`. | unit | `mix test test/lockspire/protocol/registration_test.exs` | ✅ | ⬜ pending |
| 85-02-01 | 02 | 1 | DCR-01, DCR-02, DCR-03, DCR-04 | T-85-02 | Accepted logout metadata persists onto the self-registered client without mutating unrelated DCR state. | unit | `mix test test/lockspire/protocol/registration_test.exs test/lockspire/storage/ecto/client_record_test.exs` | ✅ | ⬜ pending |
| 85-03-01 | 03 | 2 | DCRM-01, DCR-05 | T-85-03 | DCR create/read JSON reflects persisted logout metadata truthfully and does not leak unsupported semantics. | unit/integration | `mix test test/lockspire/web/registration_json_test.exs test/lockspire/web/controllers/registration_controller_test.exs test/lockspire/protocol/registration_management_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have automated verification coverage.
- [ ] Sampling continuity: no three consecutive tasks without an automated check.
- [ ] Wave 0 coverage is already present.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays within the quick-run target.
- [ ] `nyquist_compliant: true` is set when execution proof is complete.

**Approval:** pending

