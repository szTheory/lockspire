---
phase: 122
slug: support-investigation-flow-polish
status: finalized
nyquist_compliant: true
wave_0_complete: true
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

> Finalized plan map. Each requirement is covered by executable plan tasks with automated verification commands; status remains planned until execution produces green/red results.

| Req ID | Behavior | Threat Ref | Test Type | Automated Command | File Exists | Status |
|--------|----------|------------|-----------|-------------------|-------------|--------|
| SUPPORT-01 | Token index/detail show selected filters, token health, family lineage, reuse pressure, smallest safe action, safe long values, exact actions, and no plaintext secrets | T-122-01 / T-122-03 | LiveView render/event tests plus HTML assertions | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs` | yes | planned |
| SUPPORT-02 | Consent index/detail show selected filters, grant status, scope context, client/account pivots, revocation consequences, and no secret material | T-122-01 / T-122-02 | LiveView render/event tests plus HTML assertions | `MIX_ENV=test mix test test/lockspire/web/live/admin/consents_live_test.exs` | yes | planned |
| SUPPORT-03 | Empty, no-match, revoked, expired, reuse-detected, long identifier, dense result, validation-error, and already-revoked states render concise consequence copy | T-122-02 / T-122-04 | LiveView state fixtures, component stress, and design contract tests | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes | planned |

*Status: planned / green / red / flaky*

---

## Wave 0 Requirements

- [x] Plan 122-01 Task 1 extends `test/lockspire/web/live/admin/tokens_live_test.exs` for exact token index decision summary labels, dense row selectors, redacted selected-filter summaries, and no-secret rendered output.
- [x] Plan 122-02 Task 1 extends `test/lockspire/web/live/admin/tokens_live_test.exs` for exact token detail labels, exact missing-checkbox errors, already-revoked copy, expired-token fixture/consequence copy, no-family copy, disabled/de-emphasized closed controls, reuse-detected plus revoked predicate coverage, and family count wording.
- [x] Plan 122-01 Task 1 and Plan 122-03 Task 1 extend `test/lockspire/web/live/admin/consents_live_test.exs` for exact consent decision summary labels, dense row selectors, redacted pivots/scopes, exact missing-checkbox error, exact already-revoked copy, disabled/de-emphasized closed controls, and non-final backend failure copy where failure can be simulated.
- [x] Plan 122-01 Task 1 updates design contract assertions for dense rows; CSS/component stress checks remain in the wave gate if implementation touches dense rows, long values, confirmation panels, focus/error states, or page-level overflow protections.

No framework install needed. Existing LiveView/design contract test infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser-level narrow-width feel after dense support rows are implemented | SUPPORT-01, SUPPORT-02, SUPPORT-03 | Existing tests can assert structure and CSS contracts, but the final support workflow density should still be inspected once in a browser if markup/CSS changes are broad. | Open token and consent index/detail pages with dense fixtures at narrow width and verify no page-level horizontal overflow, overlapping controls, or color-only state. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused LiveView files
- [x] `nyquist_compliant: true` set in frontmatter because all plan tasks have automated commands

**Approval:** plan coverage approved; execution results still determine green/red status.
