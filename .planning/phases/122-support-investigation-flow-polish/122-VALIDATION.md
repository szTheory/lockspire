---
phase: 122
slug: support-investigation-flow-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-28
---

# Phase 122 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Seeded from 122-RESEARCH.md `## Validation Architecture` section.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest and LazyHTML support |
| **Config file** | `test/test_helper.exs`, `config/test.exs`, `mix.exs` aliases (`test.fast`) |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test.fast` |
| **Estimated runtime** | ~10-30 seconds for focused LiveView files; longer for `mix test.fast` |

---

## Sampling Rate

- **After every task commit:** `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs`
- **After every plan wave:** `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs`
- **Before `/gsd:verify-work`:** `MIX_ENV=test mix test.fast`
- **Max feedback latency:** ~30 seconds for focused LiveView files

---

## Per-Task Verification Map

> Pre-plan scaffold. Task IDs are filled in by the planner; rows below anchor phase requirements to the validation seed in 122-RESEARCH.md.

| Req ID | Behavior | Threat Ref | Test Type | Automated Command | File Exists | Status |
|--------|----------|------------|-----------|-------------------|-------------|--------|
| SUPPORT-01 | Token index/detail show selected filters, token health, family lineage, reuse pressure, smallest safe action, safe long values, exact actions, and no plaintext secrets | T-122-01 / T-122-03 | LiveView render/event tests plus HTML assertions | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs` | yes | pending |
| SUPPORT-02 | Consent index/detail show selected filters, grant status, scope context, client/account pivots, revocation consequences, and no secret material | T-122-01 / T-122-02 | LiveView render/event tests plus HTML assertions | `MIX_ENV=test mix test test/lockspire/web/live/admin/consents_live_test.exs` | yes | pending |
| SUPPORT-03 | Empty, no-match, revoked, expired, reuse-detected, long identifier, dense result, validation-error, and already-revoked states render concise consequence copy | T-122-02 / T-122-04 | LiveView state fixtures, component stress, and design contract tests | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Extend `test/lockspire/web/live/admin/tokens_live_test.exs` for exact token decision summary labels, dense row selectors, redacted selected-filter summaries, exact missing-checkbox errors, already-revoked copy, no-family copy, disabled/de-emphasized closed controls, reuse-detected plus revoked predicate coverage, and family count wording.
- [ ] Extend `test/lockspire/web/live/admin/consents_live_test.exs` for exact consent decision summary labels, dense row selectors, redacted pivots/scopes, exact missing-checkbox error, exact already-revoked copy, disabled/de-emphasized closed controls, and non-final backend failure copy where failure can be simulated.
- [ ] Add or update design contract assertions only if CSS changes touch dense rows, long values, confirmation panels, focus/error states, or page-level overflow protections.

No framework install needed. Existing LiveView/design contract test infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser-level narrow-width feel after dense support rows are implemented | SUPPORT-01, SUPPORT-02, SUPPORT-03 | Existing tests can assert structure and CSS contracts, but the final support workflow density should still be inspected once in a browser if markup/CSS changes are broad. | Open token and consent index/detail pages with dense fixtures at narrow width and verify no page-level horizontal overflow, overlapping controls, or color-only state. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for focused LiveView files
- [ ] `nyquist_compliant: true` set in frontmatter when all rows have automated commands

**Approval:** pending
