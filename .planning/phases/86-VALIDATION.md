---
phase: 86
slug: rfc-7592-update-semantics-and-proof
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 86 — Validation Strategy

> Per-phase validation contract for RFC 7592 logout metadata update semantics, lifecycle invariants, and automated proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/protocol/registration_management_test.exs test/lockspire/web/controllers/registration_controller_test.exs` |
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
| 86-01-01 | 01 | 1 | DCRM-02 | T-86-01 | RFC 7592 PUT persists valid logout metadata onto typed client fields. | unit | `mix test test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |
| 86-01-02 | 01 | 1 | DCRM-02 | T-86-02 | Omitted logout metadata clears previous values under full-replace semantics. | unit | `mix test test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |
| 86-02-01 | 02 | 2 | DCRM-02 | T-86-03 | Successful logout metadata updates rotate the RAT and invalidate the prior token immediately. | unit | `mix test test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |
| 86-02-02 | 02 | 2 | DCRM-02, DCRM-03 | T-86-04 | RFC 7592 update responses expose the same persisted logout metadata truth as the stored client. | unit/integration | `mix test test/lockspire/protocol/registration_management_test.exs test/lockspire/web/controllers/registration_controller_test.exs` | ✅ | ✅ green |
| 86-02-03 | 02 | 2 | DCRM-03 | T-86-05 | Self-service updates preserve provenance and append the expected management audit event. | unit | `mix test test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |
| 86-03-01 | 03 | 2 | PROOF-01 | T-86-06 | Negative logout metadata update cases fail as `invalid_client_metadata` with stable field attribution. | unit | `mix test test/lockspire/protocol/registration_management_test.exs` | ✅ | ✅ green |
| 86-03-02 | 03 | 2 | PROOF-01 | T-86-07 | Controller behavior matches the protocol contract for successful and rejected logout metadata updates. | integration | `mix test test/lockspire/web/controllers/registration_controller_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors should be provable through automated protocol and controller tests.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage.
- [x] Sampling continuity: no three consecutive tasks without an automated check.
- [ ] Wave 0 coverage is already present.
- [x] No watch-mode flags.
- [x] Feedback latency stays within the quick-run target.
- [x] `nyquist_compliant: true` is set when execution proof is complete.

**Approval:** complete on 2026-05-24 via `mix test test/lockspire/protocol/registration_management_test.exs test/lockspire/web/controllers/registration_controller_test.exs`
