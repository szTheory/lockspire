---
phase: 116
slug: inventory-rubric-lab-contract
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-25
---

# Phase 116 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir/Mix |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds for the focused contract test; full suite runtime varies |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`
- **After every plan wave:** Run `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`
- **Before `/gsd:verify-work`:** Run `mix test`
- **Max feedback latency:** 30 seconds for focused feedback

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 116-01-01 | 01 | 1 | LAB-03 | T-116-01, T-116-02, T-116-03, T-116-05 | Route inventory assertions are scoped to source-derived routes, query workflow exception, Phase 107 fields, surface classification, and no unbacked operation actions. | source scaffold | `rg -n "phase_116_route_inventory|116-ROUTE-WORKFLOW-INVENTORY.md|mounted_admin_routes|workflow=logout-propagation|Surface classification" test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 116-01-02 | 01 | 1 | LAB-03 | T-116-01, T-116-02, T-116-03, T-116-05 | Route inventory derives from `Lockspire.Web.AdminRouter`, includes logout-propagation as query workflow truth, and records read-only queue support without unsupported actions. | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --only phase_116_route_inventory --max-failures 1` | yes | pending |
| 116-01-03 | 01 | 1 | LAB-03 | T-116-04 | Visual/UX rubric uses brandbook truth and includes redaction, focus, reduced-motion, contrast, responsive, and no-secret gates before later UI work consumes it. | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --only phase_116_visual_rubric --max-failures 1` | yes | pending |
| 116-02-01 | 02 | 2 | LAB-01 | T-116-06, T-116-10 | Component inventory assertions are scoped to canonical function components, production usage, exceptions, missing states, DS-03 status pressure, DS-04 form pressure, and Phoenix attrs/slots boundaries. | source scaffold | `rg -n "phase_116_component_inventory|116-COMPONENT-GROUP-INVENTORY.md|status_badge|Phase 118 candidates|form primitive" test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 116-02-02 | 02 | 2 | LAB-01 | T-116-06, T-116-10 | Component inventory names primitives, usage points, missing states, exceptions, and Phase 118 candidates without implementing component changes. | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --only phase_116_component_inventory --max-failures 1` | yes | pending |
| 116-02-03 | 02 | 2 | LAB-01 | T-116-07, T-116-08, T-116-09 | Lab remains internal/demo/test-only, unmounted, unsupported as public API, and bans sensitive plaintext evidence. | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --only phase_116_lab_contract --max-failures 1` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/web/live/admin/design_system_contract_test.exs` — extend contract coverage for Phase 116 artifact existence, required headings, source-derived route rows, query workflow row, surface classifications, brand rubric gates, and lab non-support language.
- [ ] `test/lockspire/web/live/admin/design_system_contract_test.exs` — add a source/static assertion that no component lab route is mounted in `Lockspire.Web.AdminRouter` if the contract names a future lab module or path.
- [ ] Phase 116 plan must include either status inventory proof or an explicit TODO list for DS-03 status fallback pressure.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Brand rubric judgment | LAB-01 | Qualitative rubric language still needs maintainer review for brand fit | Read the generated rubric and confirm it names architectural structure, restrained Signal Cyan, calm operator hierarchy, light/dark/system parity, and avoids generic security tropes. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused feedback
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
