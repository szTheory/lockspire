---
phase: 118
slug: primitive-meta-component-upgrade
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-25
updated: 2026-06-26
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
| 118-01-01 | 01 | 1 | DS-02 | T-118-02 / T-118-05 | DS-02 contract tests preserve existing component APIs, enumerate new primitives/classes, and keep lab-only surfaces out of router/docs/package files | source contract + rendered component | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | green |
| 118-01-02 | 01 | 1 | DS-02 | T-118-02 / T-118-05 | Additive structural primitives and token-backed CSS compile without LiveComponents, public routes, package installs, schema changes, or legacy API removals | source contract + rendered component | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | green |
| 118-01-03 | 01 | 1 | DS-02 | T-118-01 / T-118-05 | Internal lab fixtures and stress surface prove dense rows, long values, disabled links, destructive groups, secondary navigation, and empty table/list alternatives without secret leakage | rendered component + redaction assertion | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | green |
| 118-02-01 | 02 | 2 | DS-03 | T-118-03 / T-118-04 | Status semantic tests enumerate every real Configure, Support, and Operate status and isolate unknown-only disabled fallback | source contract + rendered component | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | green |
| 118-02-02 | 02 | 2 | DS-03 | T-118-03 / T-118-04 | `status_badge/1` preserves old `status={...}` calls, uses `domain` for ambiguity, and maps labels/tones through one metadata helper plus semantic CSS aliases | source contract + rendered component | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | green |
| 118-02-03 | 02 | 2 | DS-03 | T-118-01 / T-118-03 / T-118-04 | Internal stress surface renders the domain-grouped status matrix in `status_cluster` with visible labels, non-color cue classes, and redaction-safe fixture values | rendered component + redaction assertion | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | green |
| 118-03-01 | 03 | 3 | DS-04 | T-118-01 / T-118-06 | DS-04 contract tests require representative form adoption, explicit Phoenix controls, named tested exceptions, and field help/error accessibility hooks | source contract + rendered component | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | green |
| 118-03-02 | 03 | 3 | DS-04 | T-118-02 / T-118-04 / T-118-06 | Form/workflow primitives preserve existing attrs/slots, expose deterministic help/error IDs, keep disabled link semantics, and separate destructive actions | rendered component + source contract | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | green |
| 118-03-03 | 03 | 3 | DS-04 | T-118-01 / T-118-06 | Representative production forms/filters use shared field chrome while complex confirmation, lifecycle, and copy-once workflows remain documented/tested exceptions | source contract + focused LiveView/source assertions | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | green |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `test/lockspire/web/live/admin/design_system_contract_test.exs` - add contract coverage for Phase 118 component names/classes, status metadata, and documented exception inventory.
- [x] `test/support/lockspire/web/admin_lab/fixtures.ex` - add all real Configure/Support/Operate status atoms plus generated long IDs, URLs, dense scopes, empty data, disabled action, destructive action, and redacted value fixtures.
- [x] `test/support/lockspire/web/admin_lab/stress_surface.ex` - render panes, entity headers, workflow shells, status clusters, lifecycle rows, dense rows, responsive table/list alternatives, disabled links, destructive groups, dense filters, secondary navigation, empty states, repeated badges, long values, and form/workflow primitives.
- [x] `test/lockspire/web/live/admin/design_system_component_stress_test.exs` - assert visible labels, stable `lockspire-admin-*` classes, accessibility hooks, redaction boundaries, and hostile fixture coverage without brittle full snapshots.

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

**Approval:** verified 2026-06-26

## Validation Audit 2026-06-26

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Evidence:

- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` - 49 tests, 0 failures.
- `mix test.fast` - 1143 tests, 0 failures, 287 excluded.
