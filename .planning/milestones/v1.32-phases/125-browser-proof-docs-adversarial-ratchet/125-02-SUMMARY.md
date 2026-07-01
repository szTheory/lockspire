---
phase: 125-browser-proof-docs-adversarial-ratchet
plan: "02"
subsystem: testing
tags: [exunit, lazyhtml, admin-proof, css-contracts, redaction]

requires:
  - phase: 121-route-scorecards-judgment-contract
    provides: AdminRouter-derived route scorecards and support-promise contract
  - phase: 125-browser-proof-docs-adversarial-ratchet
    provides: Plan 01 shared fixture and component stress proof
provides:
  - PROOF-02 global deterministic guardrail contracts
  - Rendered HTML assertions for disabled link semantics and token-like text denial
  - Source/docs/package/CSS boundary tests for route parity, redaction, browser-tooling, public support, theme, motion, and responsive contracts
affects: [phase-125-wave-2, admin-proof, operator-admin-boundary]

tech-stack:
  added: []
  patterns:
    - Existing ExUnit plus LazyHTML AdminProof helpers remain the blocking proof path
    - Phase 125 global guardrails live in design_system_contract_test.exs, not browser tooling

key-files:
  created:
    - .planning/phases/125-browser-proof-docs-adversarial-ratchet/125-02-SUMMARY.md
  modified:
    - test/support/lockspire/web/admin_proof/html_assertions.ex
    - test/lockspire/web/live/admin/design_system_contract_test.exs

key-decisions:
  - "Phase 125 Plan 02 kept PROOF-02 guardrails deterministic in ExUnit/LazyHTML/source contracts with no browser, Node, package, route, schema, or public support-surface expansion."
  - "Rendered HTML redaction and disabled-link semantics were centralized in test-only AdminProof helpers so later route proof can reuse them without creating runtime API."
  - "Global contracts derive route truth from RouteScorecards.expected_routes/0 and keep browser/manual evidence subordinate to repo-native proof."

patterns-established:
  - "Rendered HTML helpers return the original HTML on success and fail with specific drift messages."
  - "Public support/package fences scan canonical public support docs, AdminRouter, mix package metadata, and operator docs separately to avoid treating bounded internal-proof wording as a public claim."

requirements-completed: [PROOF-02]

duration: 8 min
completed: 2026-06-30
status: complete
---

# Phase 125 Plan 02: Global Deterministic Guardrail Contracts Summary

**PROOF-02 now has deterministic rendered HTML, route scorecard, source/docs/package, CSS theme/motion, redaction, and responsive guardrails without browser tooling.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-30T15:49:37Z
- **Completed:** 2026-06-30T15:57:53Z
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments

- Added `HtmlAssertions.assert_disabled_links_have_semantics/1` for disabled link/action semantics and `HtmlAssertions.assert_no_token_like_text/1` for JWT-looking, live-key-looking, cookie/auth-code-like, and private-key-like rendered text denial.
- Added Phase 125 PROOF-02 global contracts for route scorecard parity, evidence class/support promise stability, public/package/browser-tooling fences, generic CTA and unsupported action drift, redaction drift, long-value wrapping, focus-visible, theme aliases, reduced motion, and responsive source claims.
- Preserved the embedded-library and maintainer-only proof boundaries: no runtime modules, public APIs, public routes, schemas, packages, browser binaries, Playwright/axe, screenshots, reports, traces, or docs support-surface expansion were added.

## Task Commits

1. **Task 125-02-01 RED:** `19b1693` test(125-02): add failing html assertion helper contracts
2. **Task 125-02-01 GREEN:** `de6eb5d` feat(125-02): implement rendered html assertion helpers
3. **Task 125-02-02 RED:** `bd8b06b` test(125-02): add failing global guardrail contracts
4. **Task 125-02-02 GREEN:** `ba3264b` feat(125-02): implement global proof guardrail contracts

## Files Created/Modified

- `test/support/lockspire/web/admin_proof/html_assertions.ex` - Added rendered disabled-link semantics and token-like text denial helpers.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - Added helper-level tests and Phase 125 PROOF-02 global guardrail contract section.
- `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-02-SUMMARY.md` - Plan closeout summary.

## Decisions Made

- Kept all new guardrails test-only under existing AdminProof and design-system contract surfaces.
- Reused `RouteScorecards.expected_routes/0` as route truth, including exactly one logout-propagation workflow exception.
- Split public support-surface checks from maintainer-facing operator-doc boundary wording so internal proof notes stay allowed only when explicitly bounded.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None blocking. During GREEN calibration, an overbroad draft check was narrowed so scorecard denial text can mention forbidden concepts, such as developer portals, when explicitly rejecting them. The final checks still block unsupported labels in rendered/admin source surfaces.

## Verification

- `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - PASS, 65 tests, 0 failures.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` - PASS, 75 tests, 0 failures.
- `mix format --check-formatted test/support/lockspire/web/admin_proof/html_assertions.ex test/lockspire/web/live/admin/design_system_contract_test.exs` - PASS.

Note: the focused test runs emitted an existing KeyCache log line about `Lockspire.TestRepo` not being started, but ExUnit completed successfully with zero failures.

## Known Stubs

None. Stub-pattern scan only found existing forbidden-value denylist constants (`placeholder`, `coming soon`) in the contract test; these are guardrail inputs, not UI stubs.

## Threat Flags

None. Changes are test/support and test-contract only and add redaction/support-surface mitigations rather than new trust-boundary surface.

## Authentication Gates

None.

## TDD Gate Compliance

PASS. Both TDD tasks have RED `test(125-02)` commits followed by GREEN `feat(125-02)` commits.

## Self-Check: PASSED

- Found `test/support/lockspire/web/admin_proof/html_assertions.ex`.
- Found `test/lockspire/web/live/admin/design_system_contract_test.exs`.
- Found task commits `19b1693`, `de6eb5d`, `bd8b06b`, and `ba3264b`.
- Summary file created at `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-02-SUMMARY.md`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Phase 125 Plan 03. The global PROOF-02 layer is green and can be reused by Wave 2 route proof plans.

---
*Phase: 125-browser-proof-docs-adversarial-ratchet*
*Completed: 2026-06-30*
