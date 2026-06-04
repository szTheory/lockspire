---
phase: 108
slug: design-system-token-component-upgrade
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 108 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveView component/render tests |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` |
| **Full suite command** | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/*_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/web/live/admin/design_system_contract_test.exs`
- **After every plan wave:** Run `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/*_test.exs`
- **Before `$gsd-verify-work`:** Full suite plus `mix compile --warnings-as-errors` must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 108-01-01 | 01 | 1 | DESIGN-01/DESIGN-03/DESIGN-05/DESIGN-06 | T-108-01 | CSS remains namespaced, semantic, reduced-motion-aware, and free of one-off raw color drift outside tokens | static contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 108-02-01 | 02 | 1 | DESIGN-02/DESIGN-04 | T-108-02 | Shared components render structural primitives without exposing secrets or creating unnamespaced markup | component/static contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 108-03-01 | 03 | 1 | DESIGN-01/DESIGN-02/DESIGN-04 | T-108-03 | Migrated routes preserve URL state, copy-once handling, and admin route behavior while using shared primitives | LiveView regression | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs` | yes | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final browser screenshot inventory and route-wide mobile no-overflow proof | PROOF-02/PROOF-04 | Deferred to Phase 110 by Phase 108 scope | Not required for Phase 108. Run in Phase 110. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
