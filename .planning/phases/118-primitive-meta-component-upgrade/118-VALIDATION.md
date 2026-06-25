---
phase: 118
slug: primitive-meta-component-upgrade
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-25
---

# Phase 118 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` |
| **Full suite command** | `mix test.fast` |
| **Estimated runtime** | ~30-90 seconds for quick component tests; project-dependent for `mix test.fast` |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs`
- **After every plan wave:** Run `mix test.fast`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds for component-contract feedback unless local compilation dominates

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 118-01-01 | 01 | 1 | DS-02 | T-118-02 / T-118-05 | New primitives preserve existing component APIs and do not expose lab-only surfaces | source contract + rendered component | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | pending |
| 118-01-02 | 01 | 1 | DS-02 | T-118-05 | Structural primitives tolerate long values, dense rows, empty alternatives, disabled actions, and destructive groups without unsupported routes | rendered component | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | pending |
| 118-02-01 | 02 | 1 | DS-03 | T-118-03 / T-118-04 | Real Configure, Support, and Operate statuses map to intentional non-color semantics; unknown fallback remains isolated | source contract + rendered component | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | pending |
| 118-03-01 | 03 | 2 | DS-04 | T-118-01 / T-118-06 | Form/help/error/workflow primitives preserve explicit Phoenix input IDs, names, events, redaction, and field associations | rendered component + focused LiveView/source assertions | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/web/live/admin/design_system_contract_test.exs` - add contract coverage for Phase 118 component names/classes, status metadata, and documented exception inventory.
- [ ] `test/support/lockspire/web/admin_lab/fixtures.ex` - add all real Configure/Support/Operate status atoms plus generated long IDs, URLs, dense scopes, empty data, disabled action, destructive action, and redacted value fixtures.
- [ ] `test/support/lockspire/web/admin_lab/stress_surface.ex` - render panes, entity headers, workflow shells, status clusters, lifecycle rows, dense rows, responsive table/list alternatives, disabled links, destructive groups, dense filters, secondary navigation, empty states, repeated badges, long values, and form/workflow primitives.
- [ ] `test/lockspire/web/live/admin/design_system_component_stress_test.exs` - assert visible labels, stable `lockspire-admin-*` classes, accessibility hooks, redaction boundaries, and hostile fixture coverage without brittle full snapshots.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mounted viewport, theme, reduced-motion, axe, and screenshot evidence | DS-02, DS-03, DS-04 | Explicitly deferred to Phase 120 after primitives and page applications stabilize | Confirm Phase 118 plans do not require browser proof and that Phase 120 remains the browser-proof phase. |

---

## Threat References

| Ref | Threat | Required automated proof |
|-----|--------|--------------------------|
| T-118-01 | Plaintext secret/token/key/user-code material leaks through fixtures or rendered component HTML | Forbidden-substring assertions and redacted/copy-once fixture coverage in component stress tests |
| T-118-02 | Existing component APIs are renamed or removed, breaking downstream admin pages | Source contract assertions for legacy primitive function names and call compatibility |
| T-118-03 | Real admin statuses fall through to disabled/unknown semantics | Contract tests enumerate real status atoms and assert intentional tone/class/label coverage |
| T-118-04 | Status meaning relies on color alone | Rendered assertions prove badge text and non-color cue remain present |
| T-118-05 | Test-only lab surface becomes public supported surface | Contract assertions keep lab under `test/support` and out of `Lockspire.Web.AdminRouter`, docs, and package metadata |
| T-118-06 | Field help/error text is not programmatically associated with inputs | Rendered assertions for deterministic help/error IDs, `aria-describedby`, and `aria-invalid` |

---

## Validation Sign-Off

- [x] All planned requirement areas have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references from research
- [x] No watch-mode flags
- [x] Feedback latency target is under 90 seconds for focused component proof
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
