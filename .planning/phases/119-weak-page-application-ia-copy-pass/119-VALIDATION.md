---
phase: 119
slug: weak-page-application-ia-copy-pass
status: ready
nyquist_compliant: true
wave_0_complete: true
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
| **Estimated runtime** | Focused per-task commands target <30 seconds where practical; the all-route Phase 119 quick set remains ~120 seconds. |

---

## Sampling Rate

- **After every task commit:** Run the touched route test plus `test/lockspire/web/live/admin/design_system_contract_test.exs`; these focused commands are the primary Nyquist feedback loop.
- **After every plan wave:** Run the quick command above across all touched Phase 119 surfaces.
- **Before `/gsd:verify-work`:** `mix test.fast` must be green.
- **Max feedback latency:** Target <30 seconds for focused per-task commands where practical. The ~120 second all-route quick set is an intentional project exception for Phase 119 because the final guardrail spans nine LiveView route test files plus the design-system contract test; it is a wave/phase gate, not the per-task feedback loop.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 119-01-01 | 01 | 1 | FLOW-01, FLOW-05 | T-119-01, T-119-02, T-119-03 | Client detail preserves existing patch destinations, mutation events, endpoint/logout vocabulary, and redaction while regrouping identity, posture, credentials/assertion keys, endpoints/logout, DCR/RAT context, support pivots, and lifecycle actions. | LiveView + source contract | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 119-02-01 | 02 | 1 | FLOW-02, FLOW-05 | T-119-02, T-119-04, T-119-06 | DCR policy remains one `save_policy` form with unchanged `policy[...]` field names while visual groups separate gate, allowlist, lifetime defaults, auth methods, and risk/posture decisions without changing persistence semantics. | LiveView form test | `mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 119-03-01 | 03 | 2 | FLOW-03, FLOW-05 | T-119-03 | IAT index/new preserve DCR onboarding, metrics, copy-once reveal/acknowledge, `single_use`, `expires_in_days`, `phx-submit="mint"`, revocation behavior, and plaintext-negative assertions while improving grouped inventory and mint workflow scanability. | LiveView rendered tests | `mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 119-03-02 | 03 | 2 | FLOW-03, FLOW-05 | T-119-04, T-119-05 | Token and consent details keep incident hierarchy, destructive confirmation panels, existing revoke APIs/events, checkbox confirmation params, redaction helpers, and missing-record behavior while improving support-detail hierarchy only where useful. | LiveView rendered tests + event tests | `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 119-04-01 | 04 | 3 | FLOW-03, FLOW-04, FLOW-05 | T-119-04, T-119-05 | Device authorization and interaction queues remain read-only, avoid code/hash/plaintext exposure, remove non-table table-wrapper drift, and do not introduce unsupported queue controls, events, or forms. | Negative rendered assertions + source contract | `mix test test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 119-04-02 | 04 | 3 | FLOW-03, FLOW-04, FLOW-05 | T-119-04, T-119-05 | Logout delivery queue preserves waiting/retrying/failed/discarded/completed metric semantics, remains non-mutating, avoids worker-control copy, and removes non-table table-wrapper drift. | Negative rendered assertions + source contract | `mix test test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes | pending |
| 119-04-03 | 04 | 3 | FLOW-01, FLOW-02, FLOW-03, FLOW-04, FLOW-05 | T-119-06, T-119-07 | Final source/copy/redaction guardrails cover D-01 through D-16, primitive adoption, DCR one-form semantics, vocabulary splits, read-only queue truth, redaction/copy fences, and Phase 120 browser-proof boundary preservation. | Source contract + focused rendered tests | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | yes | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Coverage

No separate Wave 0 implementation plan is required. The missing validation references are folded into the actual task sequence as test-first work:

- [x] `119-01-01` extends `test/lockspire/web/live/admin/clients_live/show_test.exs` before changing client detail markup.
- [x] `119-02-01` extends `test/lockspire/web/live/admin/policies_live/dcr_test.exs` before changing DCR policy markup.
- [x] `119-03-01` extends `test/lockspire/web/live/admin/iat_live_test.exs` before changing IAT index/new markup.
- [x] `119-03-02` extends `test/lockspire/web/live/admin/tokens_live_test.exs` and `test/lockspire/web/live/admin/consents_live_test.exs` before changing support detail markup.
- [x] `119-04-01` extends `test/lockspire/web/live/admin/device_authorizations_live_test.exs` and `test/lockspire/web/live/admin/interactions_live_test.exs` before changing read-only queue markup.
- [x] `119-04-02` extends `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` before changing logout delivery queue markup.
- [x] `119-04-03` extends `test/lockspire/web/live/admin/design_system_contract_test.exs` with the final Phase 119 source/copy/redaction guardrails.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final viewport/theme/reduced-motion regression proof | FLOW-01, FLOW-02, FLOW-03, FLOW-05 | Explicitly deferred to Phase 120 by context. | Do not require in Phase 119; keep deterministic source and LiveView tests as the Phase 119 gate. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 references are folded into test-first task actions and mapped above.
- [x] No watch-mode flags.
- [x] Focused per-task feedback targets <30 seconds where practical; the ~120 second all-route quick set is an intentional Phase 119 exception for wave/phase gating.
- [x] `nyquist_compliant: true` set in frontmatter after stale map gaps were closed.

**Approval:** ready for execution
