---
phase: 124
slug: configure-onboarding-propagation-pass
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-29
---

# Phase 124 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest and LazyHTML-backed `HtmlAssertions` |
| **Config file** | `.formatter.exs`; test setup through Mix aliases and `test/support/lockspire/web/admin_proof/*` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs --max-failures 1` |
| **Full suite command** | `MIX_ENV=test mix test.fast --max-failures 5` |
| **Estimated runtime** | Focused Configure slice under 90 seconds; full fast suite environment-dependent |

---

## Sampling Rate

- **After every task commit:** Run the focused route test(s) for the touched Configure LiveView plus `mix format --check-formatted` for touched `.ex` and `.exs` files.
- **After every plan wave:** Run the focused Configure route slice plus `test/lockspire/web/live/admin/design_system_contract_test.exs`.
- **Before `/gsd:verify-work`:** Run `MIX_ENV=test mix test.fast --max-failures 5` and document any pre-existing unrelated failure with exact failing test names.
- **Max feedback latency:** 90 seconds for focused route checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 124-01-01 | 01 | 1 | CONFIG-01, CONFIG-02, CONFIG-03 | T-124-01..04 | Client tests define hierarchy, copy-once handoff, redaction, and destructive confirmation before source changes. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` | yes | pending |
| 124-01-02 | 01 | 1 | CONFIG-01, CONFIG-02, CONFIG-03 | T-124-01..04 | Client implementation preserves existing Admin APIs while adding posture, route labels, copy-once, and confirmation semantics. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` | yes | pending |
| 124-02-01 | 02 | 1 | CONFIG-01, CONFIG-02, CONFIG-03 | T-124-05..08 | DCR/IAT tests define onboarding posture, IAT copy-once clearing, and inline revoke confirmation before source changes. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/iat_live_test.exs --max-failures 1` | yes | pending |
| 124-02-02 | 02 | 1 | CONFIG-01, CONFIG-02, CONFIG-03 | T-124-05..08 | DCR/IAT implementation preserves existing routes/Admin behavior while adding decision spine and checkbox-backed revoke. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/iat_live_test.exs --max-failures 1` | yes | pending |
| 124-03-01 | 03 | 1 | CONFIG-01, CONFIG-03 | T-124-09..12 | Key tests define lifecycle posture, public metadata only, and confirmation-backed key transitions before source changes. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/keys_live_test.exs --max-failures 1` | yes | pending |
| 124-03-02 | 03 | 1 | CONFIG-01, CONFIG-03 | T-124-09..12 | Key implementation preserves existing lifecycle handlers while adding posture, safe labels, and destructive retirement confirmation. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/keys_live_test.exs --max-failures 1` | yes | pending |
| 124-04-01 | 04 | 1 | CONFIG-01, CONFIG-03 | T-124-13..16 | Policy overview/DCR tests define route-specific review labels, DCR posture, global scope, and unsupported-control denial. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/index_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs --max-failures 1` | new + yes | pending |
| 124-04-02 | 04 | 1 | CONFIG-01, CONFIG-03 | T-124-13..16 | Policy overview/DCR implementation preserves existing policy save path and denies credential/client/host-owned controls. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/index_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs --max-failures 1` | yes | pending |
| 124-05-01 | 05 | 1 | CONFIG-01, CONFIG-03 | T-124-17..20 | PAR/DPoP/security-profile tests define posture summaries, scope copy, validation behavior, and no host-owned claims. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs --max-failures 1` | yes | pending |
| 124-05-02 | 05 | 1 | CONFIG-01, CONFIG-03 | T-124-17..20 | PAR/DPoP/security-profile implementation preserves existing save handlers and avoids route/API/schema/package expansion. | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs --max-failures 1` | yes | pending |
| 124-06-01 | 06 | 2 | CONFIG-01, CONFIG-02, CONFIG-03 | T-124-21..24 | Source contracts prove route/API boundary, required primitives, copy-once, unsupported-control denial, and sensitive-internal denial. | source/contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |
| 124-06-02 | 06 | 2 | CONFIG-01, CONFIG-02, CONFIG-03 | T-124-21..25 | Component stress proof covers Configure primitives, UI-SPEC palette/typography/no-icon-only constraints, and public-boundary denial. | stress/contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes | pending |
| 124-06-03 | 06 | 2 | CONFIG-01, CONFIG-02, CONFIG-03 | T-124-21..25 | Focused Configure wave gate and full fast-suite caveat recording prove final phase scope and dirty-worktree preservation. | regression/gate | `MIX_ENV=test mix test.fast --max-failures 5` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave Mapping And Dependency Gates

- **Wave 1:** Plans 124-01, 124-02, 124-03, 124-04, and 124-05 run independently because their `files_modified` sets do not overlap. Each plan creates or strengthens route-local RED proof before its source implementation task.
- **Wave 2:** Plan 124-06 depends on 124-01 through 124-05 and runs only after route-local Configure changes land. It updates design-system contract/stress tests and runs the focused Configure gate.
- **No separate Wave 0 plan exists:** Missing proof identified by research is distributed into the first task of each route-local plan and into Plan 124-06 source/stress contracts.
- **Dirty-worktree guard:** Tasks that touch dirty files include `git diff -- <file>` read-first instructions and Phase-124-only staging criteria; Plan 124-06-02 forbids edits outside `design_system_component_stress_test.exs`.

---

## Manual-Only Verifications

All Phase 124 behaviors must have automated verification. Manual browser review can supplement responsive polish, but it cannot replace rendered/source/event assertions for CONFIG-01, CONFIG-02, or CONFIG-03.

---

## Validation Sign-Off

- [x] All planned requirements have automated verify commands.
- [x] Sampling continuity: no three consecutive tasks may skip automated verification.
- [x] Wave 1 route-local RED tasks and Wave 2 source/stress contracts cover all missing references from the research validation architecture.
- [x] No watch-mode flags.
- [x] Focused feedback latency target is under 90 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-29
