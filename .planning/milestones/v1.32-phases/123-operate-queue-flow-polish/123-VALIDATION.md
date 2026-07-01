---
phase: 123
slug: operate-queue-flow-polish
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-29
---

# Phase 123 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix, with Phoenix.LiveViewTest and LazyHTML-backed assertions |
| **Config file** | `config/test.exs` with `Lockspire.TestRepo` and Ecto SQL sandbox |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` |
| **Full suite command** | `MIX_ENV=test mix test.fast` |
| **Estimated runtime** | Focused Operate command under 30 seconds expected; full suite depends on local DB state |

---

## Sampling Rate

- **After every task commit:** Run the focused Operate LiveView command.
- **After every plan wave:** Run the focused Operate command plus `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` when shared components, CSS, AdminLab fixtures, or stress surfaces change.
- **Before `/gsd:verify-work`:** `MIX_ENV=test mix test.fast` must be green, with any local infrastructure caveat recorded in the phase summary.
- **Max feedback latency:** 30 seconds for the focused Operate command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 123-01-01 | 01 | 1 | OPERATE-01, OPERATE-03 | T-123-01, T-123-04, T-123-05 | Interactions expose status pressure, prompt/channel, client, subject, age/expiry/activity, durable non-secret identifiers, long values, and empty/dense/expired/completed/denied states without table squashing | LiveView render/source | `MIX_ENV=test mix test test/lockspire/web/live/admin/interactions_live_test.exs --max-failures 1` | yes | pending |
| 123-02-01 | 02 | 1 | OPERATE-01, OPERATE-02, OPERATE-03 | T-123-01, T-123-02, T-123-04 | Device authorizations expose prompt/channel, status pressure, poll/next-poll/activity context, subject/client context, approved/denied/expired/consumed states, and no raw code/hash/verification-handle or unsupported approve/deny controls | LiveView render/source | `MIX_ENV=test mix test test/lockspire/web/live/admin/device_authorizations_live_test.exs --max-failures 1` | yes | pending |
| 123-03-01 | 03 | 1 | OPERATE-01, OPERATE-02, OPERATE-03 | T-123-02, T-123-03, T-123-04 | Logout deliveries keep the strongest existing pattern while adding discarded, skipped, rendered, completed, retryable incident, endpoint, attempts, support note, long URL, and no worker/internal/control leakage proof | LiveView render/source | `MIX_ENV=test mix test test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` | yes | pending |
| 123-04-01 | 04 | 2 | OPERATE-02, OPERATE-03 | T-123-02, T-123-04, T-123-05 | Shared admin queue primitives or CSS preserve read-only boundaries, mobile wrapping, keyboard focus, reduced motion, dark/light/system themes, and forbidden action labels across all Operate surfaces | Design-system/source contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes | pending |
| 123-05-01 | 05 | 2 | OPERATE-01, OPERATE-02, OPERATE-03 | T-123-01, T-123-02, T-123-03 | Phase-wide proof covers no table regressions, no new Operate mutation delegates, no `handle_event`/`phx-click`/`phx-submit` command surface, no secret/raw backend internals, and all three focused route suites green together | Integration/source guard | `MIX_ENV=test mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Extend `test/lockspire/web/live/admin/interactions_live_test.exs` for pressure subtitles, prompt/channel, subject/client redaction, age/expiry/activity context, expired/completed/denied states, long values, no table, and no unsupported controls.
- [ ] Extend `test/lockspire/web/live/admin/device_authorizations_live_test.exs` for pressure subtitles, poll interval/next-poll or activity context, approved/denied/expired/consumed states, raw code/hash/verification-handle absence, long values, no table, and no unsupported controls.
- [ ] Extend `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` for discarded, skipped, rendered, completed/succeeded, retryable incident, long endpoint URL, support note, no worker/internal leaks, no table, and no unsupported controls.
- [ ] Add a source/API fence for new Operate mutation delegates or queue command controls if rendered tests do not fully cover the final implementation surface.
- [ ] Extend `test/support/lockspire/web/admin_lab/fixtures.ex`, `test/support/lockspire/web/admin_lab/stress_surface.ex`, `test/lockspire/web/live/admin/design_system_contract_test.exs`, and `test/lockspire/web/live/admin/design_system_component_stress_test.exs` only if shared primitives, CSS, or stress fixtures change.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final support-note wording | OPERATE-01, OPERATE-03 | Operator copy needs maintainer judgment beyond source assertions | Review each Operate surface and confirm copy explains status pressure without promising retry, discard, approve, deny, logout-now, worker-control, or mutation behavior |
| Mobile density scan | OPERATE-03 | Source/rendered tests can prove structure, but final scanability benefits from a narrow viewport review | Inspect interactions, device authorizations, and logout deliveries at mobile width after implementation; record screenshot/browser proof if layout files changed |

---

## Threat References

| Ref | Threat | Mitigation |
|-----|--------|------------|
| T-123-01 | Raw OAuth/OIDC, device-flow, logout token, or backend identifier material appears in queue rows | Allowed field lists, existing redaction helpers, long-value wrappers, and forbidden-text assertions |
| T-123-02 | Read-only support pages appear to authorize retry, discard, approve, deny, logout-now, worker, or queue mutation actions | No `handle_event`, `phx-click`, `phx-submit`, command labels, mutation delegates, or new routes unless explicitly backed by existing domain APIs and scope |
| T-123-03 | Worker internals, Oban details, SQL state, raw response bodies, or raw failure payloads become support concepts | Show endpoint/channel/attempt/status pressure and calm support notes instead of backend internals |
| T-123-04 | Long endpoints, subjects, clients, or identifiers overflow mobile layouts and hide incident context | Use existing wrapping/long-value patterns, dense row stacking below 720px, and design-system stress proof |
| T-123-05 | Status is conveyed only by badge color or theme-dependent styling | Keep visible text labels, semantic status badges, focus states, reduced-motion behavior, and light/dark/system coverage |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target under 30 seconds for focused command
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
