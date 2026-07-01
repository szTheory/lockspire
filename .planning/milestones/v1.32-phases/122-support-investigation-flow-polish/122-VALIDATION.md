---
phase: 122
slug: support-investigation-flow-polish
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-28
audited: 2026-06-28
audit_status: green
gaps_found: 0
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

> Audited execution map. Each requirement is covered by executable route/source/component tests that pass in the current tree.

| Req ID | Behavior | Threat Ref | Test Type | Automated Command | File Exists | Status |
|--------|----------|------------|-----------|-------------------|-------------|--------|
| SUPPORT-01 | Token index/detail show selected filters, token health, family lineage, reuse pressure, smallest safe action, safe long values, exact actions, and no plaintext secrets | T-122-01 / T-122-03 | LiveView render/event tests plus HTML assertions | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs` | yes | green |
| SUPPORT-02 | Consent index/detail show selected filters, grant status, scope context, client/account pivots, revocation consequences, and no secret material | T-122-01 / T-122-02 | LiveView render/event tests plus HTML assertions | `MIX_ENV=test mix test test/lockspire/web/live/admin/consents_live_test.exs` | yes | green |
| SUPPORT-03 | Empty, no-match, revoked, expired, reuse-detected, long identifier, dense result, validation-error, and already-revoked states render concise consequence copy | T-122-02 / T-122-04 | LiveView state fixtures, component stress, and design contract tests | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes | green |

*Status: planned / green / red / flaky*

## Requirement-to-Test Cross-Reference

| Requirement | Covered By | Evidence |
|-------------|------------|----------|
| SUPPORT-01 | `test/lockspire/web/live/admin/tokens_live_test.exs` | Token index/detail assertions cover selected filters, token health, family pressure/lineage, reuse pressure, smallest safe action, dense rows, disabled closed states, exact confirmation/failure copy, and no-secret rendering. |
| SUPPORT-02 | `test/lockspire/web/live/admin/consents_live_test.exs` | Consent index/detail assertions cover selected filters, grant status, scope context, client/account pivots, revocation consequence, dense rows, disabled already-revoked state, exact confirmation/failure copy, and no-secret rendering. |
| SUPPORT-03 | `test/lockspire/web/live/admin/tokens_live_test.exs`, `test/lockspire/web/live/admin/consents_live_test.exs`, `test/lockspire/web/live/admin/design_system_contract_test.exs`, `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | Empty/no-match states, dense/long-value rendering, validation errors, revoked/expired/no-family/reuse-detected/already-revoked states, dense-row source contracts, and component stress states are covered by executable tests. |

---

## Wave 0 Requirements

- [x] Plan 122-01 Task 1 extends `test/lockspire/web/live/admin/tokens_live_test.exs` for exact token index decision summary labels, dense row selectors, redacted selected-filter summaries, and no-secret rendered output.
- [x] Plan 122-02 Task 1 extends `test/lockspire/web/live/admin/tokens_live_test.exs` for exact token detail labels, exact missing-checkbox errors, already-revoked copy, expired-token fixture/consequence copy, no-family copy, disabled/de-emphasized closed controls, reuse-detected plus revoked predicate coverage, and family count wording.
- [x] Plan 122-01 Task 1 and Plan 122-03 Task 1 extend `test/lockspire/web/live/admin/consents_live_test.exs` for exact consent decision summary labels, dense row selectors, redacted pivots/scopes, exact missing-checkbox error, exact already-revoked copy, disabled/de-emphasized closed controls, and non-final backend failure copy where failure can be simulated.
- [x] Plan 122-01 Task 1 updates design contract assertions for dense rows; CSS/component stress checks remain in the wave gate if implementation touches dense rows, long values, confirmation panels, focus/error states, or page-level overflow protections.

No framework install needed. Existing LiveView/design contract test infrastructure covers all phase requirements.

---

## Manual-Only Verifications

These checks are supplemental operator feel checks, not Nyquist requirement gaps; the requirement behaviors above have automated coverage.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser-level narrow-width feel after dense support rows are implemented | SUPPORT-01, SUPPORT-02, SUPPORT-03 | Existing tests can assert structure and CSS contracts, but the final support workflow density should still be inspected once in a browser if markup/CSS changes are broad. | Open token and consent index/detail pages with dense fixtures at narrow width and verify no page-level horizontal overflow, overlapping controls, or color-only state. |

---

## Validation Audit 2026-06-28

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

| Check | Result |
|-------|--------|
| Nyquist hook gate | PASS - active `verify:post` hook includes `validate-phase` with `onError: halt`. |
| Input state | PASS - State A, existing `122-VALIDATION.md` audited. |
| Requirement map | PASS - SUPPORT-01, SUPPORT-02, and SUPPORT-03 all map to phase plans, summaries, and executable tests. |
| Phase-scoped tests | PASS - `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` returned 64 tests, 0 failures. |
| Format check | PASS - `mix format --check-formatted` passed for the four phase LiveViews and four phase test files. |

No new test files were generated during this audit because no missing or partial requirement coverage was found.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused LiveView files
- [x] `nyquist_compliant: true` set in frontmatter because all plan tasks have automated commands and the audited phase gate is green

**Approval:** Nyquist coverage audited and approved. Phase 122 is compliant with 0 validation gaps.
