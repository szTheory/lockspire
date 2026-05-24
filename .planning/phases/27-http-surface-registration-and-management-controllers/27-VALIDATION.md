---
phase: 27
slug: http-surface-registration-and-management-controllers
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-26
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | none |
| **Quick run command** | `mix test test/lockspire/web/controllers/registration_controller_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/web/controllers/registration_controller_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | DCR-05 | T-27-01 | JSON shape | unit | `mix test test/lockspire/web/registration_json_test.exs` | ❌ W0 | ⬜ pending |
| 27-02-01 | 02 | 2 | DCR-01 | T-27-02 | Gated by policy | integration | `mix test test/lockspire/web/controllers/registration_controller_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/web/registration_json_test.exs` — stubs for DCR-05
- [ ] `test/lockspire/web/controllers/registration_controller_test.exs` — stubs for DCR-01, DCR-13, DCR-14, DCR-15

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
