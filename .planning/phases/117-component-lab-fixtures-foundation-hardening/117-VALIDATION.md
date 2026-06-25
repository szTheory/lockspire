---
phase: 117
slug: component-lab-fixtures-foundation-hardening
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-25
---

# Phase 117 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveViewTest |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix test.fast` |
| **Estimated runtime** | ~15-60 seconds for targeted tests; full suite depends on local services |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`.
- **After every plan wave:** Run `mix test.fast`.
- **Before `/gsd:verify-work`:** Targeted design-system tests and `mix test.fast` must be green.
- **Max feedback latency:** 60 seconds for targeted design-system feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 117-01-01 | 01 | 1 | LAB-02 | T-117-01 | Lab remains internal/unmounted while rendering real admin components | render contract | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes | pending |
| 117-01-02 | 01 | 1 | PROOF-01 | T-117-02 | Fixtures expose only fake/redacted/handle-only values, never plaintext secrets | render/source contract | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes | pending |
| 117-02-01 | 02 | 1 | DS-01 | T-117-03 | CSS preserves semantic light/dark/system behavior without unsupported public surface | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |
| 117-02-02 | 02 | 1 | DS-05 | T-117-04 | Motion uses explicit properties and reduced-motion-safe active states | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/support/lockspire/web/admin_lab/fixtures.ex` or equivalent internal/test-support fixture module for fake scenario data.
- [ ] `test/support/lockspire/web/admin_lab/stress_surface.ex` or equivalent internal/test-support renderer extracted from the existing stress test.
- [ ] Extended `test/lockspire/web/live/admin/design_system_component_stress_test.exs` coverage for required lab states and redaction bans.
- [ ] Extended `test/lockspire/web/live/admin/design_system_contract_test.exs` coverage for DS-01, DS-05, route boundary, docs boundary, and optional tooling boundary.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional Playwright + axe package adoption | PROOF-01 | Latest npm package releases were flagged suspicious by the research package-legitimacy seam | If the plan installs npm browser tooling, pause at `checkpoint:human-verify`, verify package provenance, then run the documented browser proof command. |

---

## Validation Sign-Off

- [x] All planned task areas have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers missing reusable lab fixture/surface references.
- [x] No watch-mode flags.
- [x] Feedback latency target is under 60 seconds for targeted design-system tests.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
