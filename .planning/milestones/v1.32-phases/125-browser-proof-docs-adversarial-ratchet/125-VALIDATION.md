---
phase: 125
slug: browser-proof-docs-adversarial-ratchet
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-30
updated: 2026-06-30
---

# Phase 125 - Validation Strategy

Per-phase validation contract for feedback sampling during execution. This file is ready because every actual plan task, `125-01-01` through `125-06-03`, is mapped to a concrete plan, wave, requirement, threat reference, and automated command.

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
- **Before `/gsd:verify-work`:** Run the focused route proof command, inspect `125-V1.32-PROOF.md` for required non-gap browser/manual evidence rows, then run `MIX_ENV=test mix test.fast --max-failures 5`.
- **Max feedback latency:** Keep per-task validation below 180 seconds by using focused file commands before broader gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 125-01-01 | 125-01 | 1 | PROOF-01 | T-125-01, T-125-03, T-125-04, T-125-SC | Redaction-safe shared fixture states cover cardinality, long values, missing optionals, lifecycle/security, visual/accessibility, and journey states without public lab surface, package creep, or evidence-secret preservation. | component/rendered | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | Existing fixture and component stress files; assertions added by task | ready |
| 125-01-02 | 125-01 | 1 | PROOF-01, PROOF-02 | T-125-01, T-125-02, T-125-03, T-125-04, T-125-SC | Internal stress rendering remains test-only, redaction-safe, accessible, long-value safe, and blocked against public/runtime/package support-surface creep. | component/rendered contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | Existing stress surface and tests | ready |
| 125-02-01 | 125-02 | 1 | PROOF-02 | T-125-05, T-125-08, T-125-SC | Rendered HTML helpers reject token-like text, disabled-link semantic drift, accessibility drift, and package/tooling creep. | source/rendered contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | Existing `HtmlAssertions` and contract test | ready |
| 125-02-02 | 125-02 | 1 | PROOF-02 | T-125-06, T-125-07, T-125-08, T-125-SC | Global guardrails catch route-scorecard drift, unsupported/generic action drift, redaction drift, theme/motion/source drift, public/runtime/package support-surface creep, and browser-tooling creep. | source/rendered contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | Existing global contract test | ready |
| 125-03-01 | 125-03 | 2 | PROOF-01, PROOF-02 | T-125-09, T-125-11, T-125-12 | Support route proof covers redaction-safe ugly investigation states, long values, closed-state copy, no generic CTA drift, and no unsupported recovery/reveal/export controls. | LiveView route proof | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs --max-failures 1` | Existing Support route tests | ready |
| 125-03-02 | 125-03 | 2 | PROOF-01, PROOF-02 | T-125-09, T-125-10, T-125-11, T-125-12 | Operate route proof covers read-only queue states, incident/expired/long-data cases, redaction, and high-severity unsupported-control blockers. | LiveView route proof | `MIX_ENV=test mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` | Existing Operate route tests | ready |
| 125-04-01 | 125-04 | 2 | PROOF-01, PROOF-02 | T-125-13, T-125-14, T-125-15, T-125-16 | Client Configure proof covers copy-once, long redirect/logout URLs, lifecycle confirmation, durable redaction, host-owned seam denial, and unsupported credential controls. | LiveView route proof | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` | Existing client route tests | ready |
| 125-04-02 | 125-04 | 2 | PROOF-01, PROOF-02 | T-125-13, T-125-14, T-125-15, T-125-16 | DCR/IAT, key, and DCR policy proof covers copy-once/durable redaction, public key metadata only, future-request policy scope, and unsupported host/export/token debug controls. | LiveView route proof | `MIX_ENV=test mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs --max-failures 1` | Existing Configure route tests | ready |
| 125-05-01 | 125-05 | 2 | PROOF-01, PROOF-02 | T-125-17, T-125-18, T-125-19, T-125-20 | Orient and policy overview proof uses source-derived route truth, denies backend leakage/public support overclaiming, and checks focus/link/long-value boundaries. | LiveView route proof | `MIX_ENV=test mix test test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/policies_live/index_test.exs --max-failures 1` | Existing Orient and policy overview tests | ready |
| 125-05-02 | 125-05 | 2 | PROOF-01, PROOF-02 | T-125-18, T-125-19, T-125-20 | PAR, DPoP, and security-profile proof denies raw proof material, host-owned seams, public theming, AI gate claims, and unsupported policy controls. | LiveView route proof | `MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs --max-failures 1` | Existing policy route tests | ready |
| 125-06-01 | 125-06 | 3 | PROOF-02, PROOF-03 | T-125-21, T-125-25, T-125-SC | Proof artifact parser rejects malformed rows, invalid result values, nonnumeric width cells, redaction leakage, evidence-secret preservation, and browser/package surface creep. | source/artifact contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | New helper created by task; existing contract test | ready |
| 125-06-02 | 125-06 | 3 | PROOF-03 | T-125-21, T-125-22, T-125-24, T-125-25, T-125-SC | Maintainer proof artifact records deterministic outcomes and required representative browser/manual rows; any required row that is missing, `gap`, `blocked`, `fail`, or unsafe blocks Phase 125 closeout/signoff. | docs/source/manual artifact contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/index_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | Proof artifact created by task | ready; required evidence rows are closeout-blocking |
| 125-06-03 | 125-06 | 3 | PROOF-03 | T-125-21, T-125-23, T-125-SC | Operator docs explain the proof loop while blocking public support expansion for lab, browser proof, screenshots, public design-system, public theming, AI judges, package/browser tooling, and evidence-secret preservation. | docs/source contract | `mix docs.verify` and `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | Existing operator docs and contract test | ready |

*Status values: ready, green, red, flaky, blocked. `ready` means Nyquist mapping is complete before execution; it does not claim the task has already passed.*

---

## Wave 0 Readiness

- [x] Every actual task from `125-01-01` through `125-06-03` has an automated verification command.
- [x] No Wave 0 scaffold task is required; new proof artifacts/helpers are owned by concrete Wave 3 tasks.
- [x] Optional helper extraction is not required before execution; `BrowserEvidence` is planned in Task 125-06-01, and a separate sensitive-values helper remains unplanned unless implementation discovers duplicated logic.
- [x] Required representative browser/manual evidence rows are a Phase 125 closeout blocker in Task 125-06-02. Optional supplemental rows may be deferred with rationale, but they cannot satisfy PROOF-03.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Blocking Rule | Test Instructions |
|----------|-------------|------------|---------------|-------------------|
| Required representative browser/manual no-page-overflow rows at 320px, 390px, 768px, 1024px, and 1440px | PROOF-02, PROOF-03 | Browser/manual evidence is supplemental maintainer proof and intentionally not a CI/browser-tooling gate in Phase 125. | Required rows are closeout-blocking: missing, `gap`, `blocked`, `fail`, nonnumeric width, or unsafe evidence blocks Phase 125 signoff. | Record route, journey, viewport, theme, motion, focus path, `scrollWidth`, `clientWidth`, result `pass`, and scrubbed notes in `125-V1.32-PROOF.md`; do not commit screenshots, traces, cookies, token-looking strings, private keys, verifier material, production hostnames, or copy-once plaintext. |
| Optional supplemental browser/manual rows | PROOF-03 | Additional evidence may help maintainers but is not required to prove the representative matrix. | Optional rows may be deferred with rationale and cannot replace required rows. | Put optional rows in a separate supplemental or deferred section with explicit rationale and no pass claim. |
| Final adversarial signoff | PROOF-03 | The signoff is a maintainer judgment ratchet over proof artifacts, docs, and support boundary, not a standalone automated test. | A `blocked`, `gap`, or `fail` outcome on required concerns blocks Phase 125 closeout/signoff until resolved or explicitly replanned. | Review for aesthetic overfit, inaccessible custom behavior, generic admin-template drift, backend implementation leakage, host integration weight, screenshot-only quality, theme/motion/focus regressions, redaction failures, unsupported action creep, stale route evidence, package/runtime creep, and accidental support-surface expansion. |

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit closeout-blocking manual evidence rules.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 mapping covers every actual plan task and contains no TBD plan ownership.
- [x] No watch-mode flags.
- [x] Feedback latency stays under 180 seconds for per-task checks.
- [x] `nyquist_compliant: true` is set in frontmatter because every concrete task ID maps to plan, wave, requirement, threat reference, command, and status.

**Approval:** ready
