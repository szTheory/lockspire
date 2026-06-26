---
phase: 119
slug: weak-page-application-ia-copy-pass
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-26
---

# Phase 119 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus `Phoenix.LiveViewTest` |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` |
| **Full suite command** | `mix test.fast` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the touched route test plus `test/lockspire/web/live/admin/design_system_contract_test.exs`.
- **After every plan wave:** Run the quick command above across all touched Phase 119 surfaces.
- **Before `/gsd:verify-work`:** `mix test.fast` must be green.
- **Max feedback latency:** 120 seconds for the focused quick set.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 119-01-01 | 01 | 1 | FLOW-01 | T-119-01 | Client detail preserves existing actions/events and redaction while regrouping identity, posture, credentials, endpoints, DCR/RAT, support pivots, and lifecycle actions. | LiveView + source contract | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 119-02-01 | 02 | 1 | FLOW-02 | T-119-02 | DCR policy remains one `save_policy` form with unchanged `policy[...]` field names while visual groups separate gate, allowlist, lifetime, auth method, and risk decisions. | LiveView form test | `mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 119-03-01 | 03 | 2 | FLOW-03 | T-119-03 | IAT, token detail, consent detail, and operate queues expose page job, primary decision, empty/risk state, next safe action, and redacted material only. | LiveView rendered tests | `mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | yes | pending |
| 119-03-02 | 03 | 2 | FLOW-04 | T-119-04 | Device authorization, interaction, and logout delivery queues do not render unsupported retry, discard, approval, logout, or worker-control UI. | Negative rendered assertions | `mix test test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | yes | pending |
| 119-04-01 | 04 | 3 | FLOW-05 | T-119-05 | Touched copy is concise, domain-accurate, calm, consequence-oriented, and avoids generic/fear wording or sensitive value exposure. | Source contract + focused rendered tests | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `test/lockspire/web/live/admin/design_system_contract_test.exs` - extend Phase 119 source fences for `pane`, `entity_header`, `workflow_shell`, no non-table `lockspire-admin-table-wrap` drift, and copy/redaction guardrails on touched pages.
- [ ] `test/lockspire/web/live/admin/clients_live/show_test.exs` - extend client detail assertions for pane/group hierarchy and support-pivot copy while preserving route/event contract.
- [ ] `test/lockspire/web/live/admin/policies_live/dcr_test.exs` - extend DCR policy assertions for one-form grouped decisions and unchanged `save_policy` behavior.
- [ ] IAT/support/operate route tests - extend empty state, risk state, next safe action, read-only truth, and redaction assertions as pages are touched.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final viewport/theme/reduced-motion regression proof | FLOW-01, FLOW-02, FLOW-03, FLOW-05 | Explicitly deferred to Phase 120 by context. | Do not require in Phase 119; keep deterministic source and LiveView tests as the Phase 119 gate. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 120s.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 gaps are closed.

**Approval:** pending
