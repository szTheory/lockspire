---
phase: 107
slug: admin-journey-contract-ia-audit
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
---

# Phase 107 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveView tests |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | quick: ~5-15 seconds; full: project-dependent |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/web/live/admin/design_system_contract_test.exs`
- **After every plan wave:** Run `mix test test/lockspire/web/live/admin`
- **Before `$gsd-verify-work`:** `mix test` must be green
- **Max feedback latency:** one task

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 107-01-01 | 01 | 1 | JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-05, JOURNEY-06 | T-107-01 | Admin route contract preserves embedded-library boundary and does not add protocol/auth scope | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 107-02-01 | 02 | 1 | JOURNEY-04, JOURNEY-05, JOURNEY-06, PROOF-01 | T-107-02 | Docs keep host-owned operator auth boundary and distinguish browser redirects from RP cleanup endpoints | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 107-03-01 | 03 | 1 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | T-107-03 | Tests fail if route additions/removals are not reflected in the journey contract | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |

*Status: pending, green, red, or flaky.*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Audit classifications reflect screenshot/browser evidence quality | JOURNEY-02, JOURNEY-03 | The strong/adequate/weak labels require human judgment over screenshots and route copy | Review the route contract against `tmp/admin-ui-polish/` and route modules before execution sign-off |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or existing test infrastructure
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency is bounded to each task
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution verification
