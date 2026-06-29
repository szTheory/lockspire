---
phase: 124
slug: configure-onboarding-propagation-pass
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| 124-01-01 | 01 | 1 | CONFIG-01 | T-124-02 | Configure landing and policy surfaces use page-first hierarchy without new routes or APIs | rendered/source | `MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |
| 124-02-01 | 02 | 1 | CONFIG-02 | T-124-01 | DCR/IAT/client-secret/RAT plaintext appears only at create or rotate and clears after acknowledgement or navigation | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs --max-failures 1` | yes | pending |
| 124-03-01 | 03 | 1 | CONFIG-03 | T-124-03 | Risky Configure actions require confirmation form semantics, consequence copy, and visible error states | rendered/event/source | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |
| 124-04-01 | 04 | 2 | CONFIG-01, CONFIG-02, CONFIG-03 | T-124-04 | Cross-route contract forbids broadening AdminRouter/API/schema and sensitive internals in operator copy | contract/regression | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/web/live/admin/iat_live_test.exs` - add or adjust proof for inline IAT revoke confirmation form, missing-confirmation error, successful revoke, and no plaintext leakage.
- [ ] `test/lockspire/web/live/admin/design_system_contract_test.exs` - add Phase 124 source fence for no `data-confirm` on touched Configure destructive actions, no generic Configure CTAs, no unsupported reveal/export/bulk controls, and unchanged route boundary.
- [ ] Policy route tests for `policies_live/index`, `policies_live/par`, `policies_live/dpop`, and `policies_live/security_profile` - add page-first hierarchy and route-specific CTA assertions if those pages are touched.
- [ ] DCR onboarding proof - strengthen `/admin/dcr` assertions for policy posture, intake-token state, self-registered client review, and next safe action if the plan adds `decision_summary`.

---

## Manual-Only Verifications

All Phase 124 behaviors must have automated verification. Manual browser review can supplement responsive polish, but it cannot replace rendered/source/event assertions for CONFIG-01, CONFIG-02, or CONFIG-03.

---

## Validation Sign-Off

- [x] All planned requirements have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks may skip automated verification.
- [x] Wave 0 covers all missing references from the research validation architecture.
- [x] No watch-mode flags.
- [x] Focused feedback latency target is under 90 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-29
