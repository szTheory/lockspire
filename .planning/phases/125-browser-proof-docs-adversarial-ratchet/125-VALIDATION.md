---
phase: 125
slug: browser-proof-docs-adversarial-ratchet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 125 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix, Phoenix.LiveViewTest, and LazyHTML-backed helpers |
| **Config file** | `test/test_helper.exs`; Mix aliases in `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` |
| **Focused route proof command** | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/index_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` |
| **Full suite command** | `MIX_ENV=test mix test.fast --max-failures 5` |
| **Estimated runtime** | Quick proof: under 60 seconds; focused route proof: under 180 seconds; full suite depends on local DB setup |

---

## Sampling Rate

- **After every task commit:** Run the focused test file affected by the task plus `design_system_contract_test.exs` or `design_system_component_stress_test.exs` when global proof changes.
- **After every plan wave:** Run the focused route proof command.
- **Before `/gsd:verify-work`:** Run the focused route proof command, inspect `125-V1.32-PROOF.md` for redaction-safe evidence rows, then run `MIX_ENV=test mix test.fast --max-failures 5`.
- **Max feedback latency:** Keep per-task validation below 180 seconds by using focused file commands before broader gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 125-01-01 | TBD | 1 | PROOF-01 | T-125-01 | Redaction-safe fixture states cover cardinality, long values, missing optionals, lifecycle/security, visual/accessibility, and journey states without public lab surface. | component/rendered | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | Existing, may require Phase 125 assertions | pending |
| 125-02-01 | TBD | 1 | PROOF-02 | T-125-02 | Guardrails catch route-scorecard drift, unsupported/generic action drift, redaction drift, duplicate IDs, ARIA/label refs, link hrefs, long values, theme tokens, reduced motion, and public-surface fences. | source/rendered contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | Existing, may require Phase 125 assertions | pending |
| 125-03-01 | TBD | 2 | PROOF-01, PROOF-02 | T-125-03 | Focused Support, Operate, Configure, and Orient route tests prove changed representative pages with route-local ugly states and no unsupported actions. | LiveView route proof | Focused route proof command above | Existing route test files, exact additions TBD | pending |
| 125-04-01 | TBD | 2 | PROOF-03 | T-125-04 | Maintainer evidence and docs stay redaction-safe, supplemental, and non-public; no browser tooling, screenshots, lab artifacts, or AI judges become runtime/package/support surface. | docs/source/manual artifact | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` plus manual review of `125-V1.32-PROOF.md` | `docs/operator-admin.md` exists; proof artifact missing | pending |

*Status values: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md` - maintainer-only proof artifact for PROOF-03.
- [ ] `test/support/lockspire/web/admin_proof/sensitive_values.ex` - optional; add only if redaction deny lists duplicate across fixtures, source scans, rendered route tests, and proof artifact parsing.
- [ ] `test/support/lockspire/web/admin_proof/browser_evidence.ex` - optional; add only if parsing/scrubbing `125-V1.32-PROOF.md` rows reduces duplicate validation logic.
- [ ] Focused assertions in Support, Operate, Configure, and Orient route tests where changed representative pages need more PROOF-01/PROOF-02 coverage.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Representative browser/manual no-page-overflow rows at 320px, 390px, 768px, 1024px, and 1440px | PROOF-02, PROOF-03 | Browser/manual evidence is supplemental maintainer proof and intentionally not a CI/browser-tooling gate in Phase 125. | Record route, journey, viewport, theme, motion, focus path, `scrollWidth`, `clientWidth`, result, and scrubbed notes in `125-V1.32-PROOF.md`; do not commit screenshots, traces, cookies, token-looking strings, private keys, verifier material, production hostnames, or copy-once plaintext. |
| Final adversarial signoff | PROOF-03 | The signoff is a maintainer judgment ratchet over proof artifacts, docs, and support boundary, not a standalone automated test. | Review for aesthetic overfit, inaccessible custom behavior, generic admin-template drift, backend implementation leakage, host integration weight, screenshot-only quality, theme/motion/focus regressions, redaction failures, unsupported action creep, stale route evidence, package/runtime creep, and accidental support-surface expansion. |

---

## Validation Sign-Off

- [ ] All tasks have automated verification or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing proof artifacts and optional helpers are justified by duplication.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays under 180 seconds for per-task checks.
- [ ] `nyquist_compliant: true` set in frontmatter after the final plan maps concrete task IDs to the verification rows above.

**Approval:** pending
