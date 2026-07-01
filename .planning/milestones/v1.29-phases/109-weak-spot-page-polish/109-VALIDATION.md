---
phase: 109
slug: weak-spot-page-polish
status: draft
nyquist_compliant: true
nyquist_latency_floor: accepted
wave_0_complete: false
created: 2026-06-04
---

# Phase 109 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus Phoenix.LiveViewTest |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90 seconds focused, full suite variable; accepted as the current project floor for Phoenix LiveView focused checks |

---

## Sampling Rate

- **After every task commit:** Run the focused route test for the touched surface plus `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`
- **After every plan wave:** Run all touched admin LiveView tests listed in the map below
- **Before `$gsd-verify-work`:** `mix test` must be green
- **Max feedback latency:** 120 seconds for focused feedback
- **Nyquist warning threshold:** 30 seconds is explicitly accepted as below the current project floor for meaningful Phase 109 ExUnit/LiveView feedback; split commands remain surface-focused where practical.

## Nyquist Latency Exception

Phase 109 accepts a focused-feedback floor of approximately 90 seconds because the fastest meaningful checks still boot the Phoenix/LiveView test harness and exercise route/component contracts. The 30-second Nyquist warning threshold is not achievable without replacing meaningful route proof with weaker source-only checks, so the execution rule is: keep every task command limited to the touched route test plus `design_system_contract_test.exs`, and treat 120 seconds as the maximum focused feedback latency for this phase.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 109-TBD-OPS-01 | TBD | TBD | OPS-01 | T-109-redaction | Support token/consent pages expose investigation context without client secrets, token plaintext, RAT plaintext, IAT plaintext, user codes, or verifier material | LiveView integration | `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs --max-failures 1` | yes | pending |
| 109-TBD-OPS-02 | TBD | TBD | OPS-02 | T-109-queue-action | Operations pages expose status buckets and existing safe actions without inventing protocol operations | LiveView integration | `mix test test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs --max-failures 1` | yes | pending |
| 109-TBD-OPS-03 | TBD | TBD | OPS-03 | T-109-mobile-overflow | Long identifiers, URLs, timestamps, statuses, and counts wrap through shared primitives/classes without page-level horizontal-scroll regressions in primary rows | Source contract plus LiveView assertions | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes | pending |
| 109-TBD-OPS-04 | TBD | TBD | OPS-04 | T-109-risky-action | Risky actions remain confirmation-backed, visually distinct, and consequence-specific | LiveView integration | `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/iat_live_test.exs --max-failures 1` | yes | pending |
| 109-TBD-OPS-05 | TBD | TBD | OPS-05 | T-109-pivot-context | Support and operations pages show non-secret pivot context by client, account/subject, token family, consent, session, or delivery identifier when available | Focused route tests | `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs --max-failures 1` | yes | pending |
| 109-TBD-CONFIG-01 | TBD | TBD | CONFIG-01 | T-109-action-group | Client detail actions are grouped by routine configuration, credentials/RAT, DCR context, endpoint/logout, security posture, and lifecycle/destructive action type | LiveView integration plus source contract | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` | yes | pending |
| 109-TBD-CONFIG-02 | TBD | TBD | CONFIG-02 | T-109-posture | DCR, IAT, and key lifecycle pages expose posture, exception pressure, and next actions without secret leakage | LiveView integration | `mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs --max-failures 1` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/web/live/admin/design_system_contract_test.exs` — Phase 109 source-contract checks for generic CTA labels, primitive usage, `long_value`, action groups, and no inline layout styles
- [ ] Focused route tests — assertions for Phase 109 labels, summaries, redaction, action grouping, confirmation copy, and pivot context
- [ ] Deterministic no-overflow proxy assertions — verify `lockspire-admin-long-value`, responsive resource rows, and stacked action-group usage on target routes

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Focused 390px mobile no-page-overflow proof if shared CSS layout primitives change | OPS-03 | ExUnit/source assertions can prove class and component use, but not every rendered browser width condition | Open touched routes at 390px width and confirm primary support/operations rows, filters, long values, and action groups do not cause page-level horizontal scrolling |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s for focused commands; 30s Nyquist warning threshold explicitly accepted as the current project floor
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
