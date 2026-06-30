---
phase: 125
slug: browser-proof-docs-adversarial-ratchet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 125 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Phoenix LiveViewTest, LazyHTML, source-contract assertions |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | TBD by executor before Wave 1 |

---

## Sampling Rate

- **After every task commit:** Run the task-specific `mix test ...` command named in PLAN.md.
- **After every plan wave:** Run the focused Phase 125 admin proof suite plus any touched route tests.
- **Before `/gsd:verify-work`:** `mix test` must be green or the phase proof must document any unrelated pre-existing failures.
- **Max feedback latency:** Prefer focused commands under 60 seconds; fall back to full suite before closeout.

---

## Per-Task Verification Map

Plans have not been generated yet. The planner must replace this section with task-level rows or require each PLAN.md task to name automated commands covering:

| Requirement | Required Validation Coverage |
|-------------|------------------------------|
| PROOF-01 | Redaction-safe fixture matrix for ugly Support, Operate, Configure, Orient, and internal-lab states. |
| PROOF-02 | Deterministic route, HTML, accessibility, redaction, token/theme, long-value, unsupported-action, and no-overflow guardrails. |
| PROOF-03 | Maintainer-only browser/manual proof artifact, bounded operator docs, and adversarial support-surface review. |

---

## Wave 0 Requirements

- [ ] Confirm whether reusable Phase 125 test helpers are needed under `test/support/lockspire/web/admin_proof/`.
- [ ] Confirm focused admin route tests affected by Support, Operate, and Configure proof.
- [ ] Confirm `125-V1.32-PROOF.md` row schema before closeout tasks depend on it.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Representative browser/manual no-page-overflow rows | PROOF-03 | Browser evidence is supplemental maintainer proof and must not become CI/package/runtime surface. | Record route, viewport, theme, motion, focus mode, `scrollWidth`, `clientWidth`, pass/fail, and scrubbed notes in `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md`. |
| Final adversarial review | PROOF-03 | Requires human judgment about support-surface creep, overfit, accessibility regressions, and evidence boundaries. | Complete the adversarial checklist in the proof artifact after deterministic guardrails pass. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing validation references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is recorded for focused commands.
- [ ] `nyquist_compliant: true` set in frontmatter once plans provide task-level coverage.

**Approval:** pending
