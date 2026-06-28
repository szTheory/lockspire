---
phase: 121
slug: route-scorecards-judgment-contract
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-28
---

# Phase 121 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix, with Phoenix LiveViewTest and LazyHTML-backed helpers |
| **Config file** | Standard project test setup; no new config required |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` |
| **Full suite command** | `MIX_ENV=test mix test.fast` |
| **Estimated runtime** | Quick command under 30 seconds expected; full suite depends on local DB state |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`
- **After every plan wave:** Run `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1`
- **Before `/gsd:verify-work`:** `MIX_ENV=test mix test.fast` must be green unless the phase remains docs/test-contract-only and the executor records why a focused command is sufficient
- **Max feedback latency:** 30 seconds for the focused contract command

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 121-01-01 | 01 | 1 | IA-01 | T-121-01 | Scorecard artifact exists and covers every `AdminRouter` route plus the single logout-propagation query workflow | source/markdown | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | W0 | pending |
| 121-01-02 | 01 | 1 | IA-02 | T-121-02 | Scorecards expose required judgment fields and reject generic, unsupported, unearned, or unsafe affordance drift | source/markdown/rendered helper | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | W0 | pending |
| 121-01-03 | 01 | 1 | IA-03 | T-121-03 | Scorecards and docs preserve internal-lab, no-public-theming, no-Storybook, and no-browser-product boundaries | source/docs/package boundary | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` - required artifact for IA-01
- [ ] `test/lockspire/web/live/admin/design_system_contract_test.exs` scorecard parser/guardrail coverage, or a small test-support helper if parser logic would make the contract test unreadable
- [ ] Existing `test/support/lockspire/web/admin_proof/html_assertions.ex` reused for rendered checks where applicable; no parallel HTML assertion vocabulary

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final scorecard judgment quality | IA-01, IA-02 | The "earned-place" and operator-psychology judgments are deterministic artifact content but still need maintainer reading | Review `121-ROUTE-SCORECARDS.md` by journey and verify the scorecards read as operator tasks, not backend inventory |
| Optional browser or AI persona review | IA-02, IA-03 | Explicitly deferred from Phase 121 as maintainer-only evidence | Do not add browser package/config artifacts or runtime routes in Phase 121; record any future manual notes outside public support truth |

---

## Threat References

| Ref | Threat | Mitigation |
|-----|--------|------------|
| T-121-01 | Route scorecards drift from mounted admin routes or treat query workflow as a router route | Source-derived route extraction from `Lockspire.Web.AdminRouter` plus one explicit workflow exception |
| T-121-02 | Scorecards bless unsupported actions, generic CTAs, unearned sections, or backend leakage | Required scorecard fields, denial checks, follow-up route validation, and rendered helper reuse |
| T-121-03 | Lab, theming, Storybook, browser proof, or screenshot evidence becomes public support surface | Support-boundary fields, forbidden expansion denylists, package/doc/router checks |
| T-121-04 | Dirty Docker/demo changes pollute v1.32 admin IA truth | Baseline candidate classification and explicit non-Phase-121 file category exclusion |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target under 30 seconds for focused command
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
