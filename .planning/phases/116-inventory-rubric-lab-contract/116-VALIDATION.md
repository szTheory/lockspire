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
| 116-01-01 | 01 | 1 | LAB-01 | T-116-01 | Lab remains internal/test-only and unmounted | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |
| 116-01-02 | 01 | 1 | LAB-03 | T-116-02 | Route inventory derives from `Lockspire.Web.AdminRouter` and includes logout-propagation query workflow | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |
| 116-01-03 | 01 | 1 | LAB-01 | T-116-03 | Component inventory names primitives, usage points, missing states, and exceptions without exposing sensitive values | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |

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
