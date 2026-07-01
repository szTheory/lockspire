---
phase: 125-browser-proof-docs-adversarial-ratchet
plan: "03"
subsystem: testing
tags: [phoenix-liveview, exunit, admin-proof, support, operate, redaction]

requires:
  - phase: 122-support-investigation-flow-polish
    provides: Support token and consent page-first route behavior
  - phase: 123-operate-queue-flow-polish
    provides: Read-only Operate queue route behavior
  - phase: 125-browser-proof-docs-adversarial-ratchet
    provides: Plan 01 fixture matrix and Plan 02 rendered HTML guardrails
provides:
  - Support route proof for token and consent ugly states, redaction, long values, closed-state copy, and unsupported-control denial
  - Operate route proof for interactions, device authorizations, and logout deliveries under read-only, incident, long-value, missing-field, and completed states
  - Reuse of HtmlAssertions for duplicate IDs, ARIA references, link semantics, disabled-link semantics, generic CTA denial, and token-like text denial
affects: [phase-125-wave-2, support-proof, operate-proof, admin-proof]

tech-stack:
  added: []
  patterns:
    - Route-local hostile fixtures stay in focused LiveView tests.
    - Rendered proof helpers are applied to page HTML rather than browser/session harness wrappers.

key-files:
  created:
    - .planning/phases/125-browser-proof-docs-adversarial-ratchet/125-03-SUMMARY.md
  modified:
    - test/lockspire/web/live/admin/tokens_live_test.exs
    - test/lockspire/web/live/admin/consents_live_test.exs
    - test/lockspire/web/live/admin/interactions_live_test.exs
    - test/lockspire/web/live/admin/device_authorizations_live_test.exs
    - test/lockspire/web/live/admin/logout_deliveries_live_test.exs

key-decisions:
  - "Kept Plan 03 proof test-only in focused LiveView route tests with no runtime, route, schema, CSS, package, browser-tooling, or public docs changes."
  - "Applied HtmlAssertions to rendered page fragments and direct LiveView renders so token-like denial targets route content, not Phoenix test harness session attributes."

patterns-established:
  - "Support proof denies secrets in full rendered HTML while checking raw filter values only inside summaries and rows, preserving editable URL filter behavior."
  - "Operate proof ratchets each route locally against read-only no-table/no-command boundaries and page-specific denied sensitive values."

requirements-completed: [PROOF-01, PROOF-02]

duration: 8 min
completed: 2026-06-30
status: complete
---

# Phase 125 Plan 03: Support and Operate Route Proof Ratchet Summary

**Focused Support and Operate LiveView route proof now covers ugly states, redaction boundaries, long data, and unsupported-control denial without runtime surface changes.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-30T16:04:26Z
- **Completed:** 2026-06-30T16:11:58Z
- **Tasks:** 2 completed
- **Files modified:** 5 test files plus this summary

## Accomplishments

- Added Support route proof for token dense, long-scope, missing-account, expired, revoked, reuse-detected, and closed-state behavior, plus consent dense, sparse, long-scope, revoked, missing optional revocation field, and closed-state behavior.
- Added Operate route proof for interactions, device authorizations, and logout deliveries across waiting/pending, approved, denied, expired, retryable, discarded, skipped, rendered, completed, incident, long-value, and missing-field states.
- Reused Plan 125-02 `HtmlAssertions` for duplicate IDs, ARIA references, hrefs, disabled-link semantics, generic CTA denial, token-like text denial, and denied sensitive/control text.

## Task Commits

1. **Task 125-03-01: Add Support route ugly-state proof** - `89f5781` (test)
2. **Task 125-03-02: Add Operate queue proof ratchet** - `7f00b3e` (test)

## Files Created/Modified

- `test/lockspire/web/live/admin/tokens_live_test.exs` - Adds route-local token proof for dense, long, expired, revoked, reuse-detected, missing-field, and redaction-safe Support states.
- `test/lockspire/web/live/admin/consents_live_test.exs` - Adds route-local consent proof for dense, sparse, long-scope, revoked, closed, and redaction-safe Support states.
- `test/lockspire/web/live/admin/interactions_live_test.exs` - Adds Phase 125 read-only interactions queue proof with rendered guardrails and sensitive-value denial.
- `test/lockspire/web/live/admin/device_authorizations_live_test.exs` - Adds Phase 125 device authorization queue proof for raw code/hash denial, redacted handles, missing subject, and read-only state coverage.
- `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` - Adds Phase 125 logout delivery proof for sanitized incident review, long endpoint wrapping, terminal states, and worker/backend leakage denial.
- `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-03-SUMMARY.md` - Plan closeout summary.

## Verification

- PASS: `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs --max-failures 1` - 10 tests, 0 failures.
- PASS: `MIX_ENV=test mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` - 12 tests, 0 failures.
- PASS: `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` - 22 tests, 0 failures.
- PASS: `mix format --check-formatted test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs`.
- DEFERRED BY PLAN CONDITION: Full focused route proof from `125-VALIDATION.md` is for Wave 2 completion; Plans 125-04 and 125-05 are still pending.

The Mix runs emitted the existing non-fatal KeyCache startup log before `Lockspire.TestRepo` was started, but ExUnit completed successfully.

## Decisions Made

- Kept Support and Operate proof route-local instead of adding new shared runtime components, public helpers, CSS, routes, schemas, packages, or browser tooling.
- Preserved raw URL filter editability on Support index pages while asserting redaction in summaries, rows, and detail panes.
- Used direct LiveView rendering for the new device authorization content proof so token-like text denial checks the route HTML rather than Phoenix LiveView test wrapper session attributes.

## Deviations from Plan

None - plan executed within the planned test files and boundary.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- Initial device authorization proof calibration used `live/2`, whose wrapper includes Phoenix `data-phx-session` attributes that intentionally look session-like. The test was adjusted before commit to render the LiveView content directly, matching the other focused route proofs.
- The working tree contained unrelated user-owned dirty files before execution. They remain unstaged and uncommitted.

## Known Stubs

None. Stub scan of the five modified test files found no TODO/FIXME/placeholder/coming-soon/not-available patterns or hardcoded empty UI data stubs introduced by this plan.

## Threat Flags

None. Changes are focused test-only route proof and add mitigations for redaction leakage, unsupported controls, long-value handling, and stale rendered proof rather than introducing a new trust-boundary surface.

## Authentication Gates

None.

## Self-Check: PASSED

- Found key files: all five modified focused route test files exist.
- Found task commits: `89f5781` and `7f00b3e`.
- No tracked file deletions were introduced by task commits.
- No runtime module, route, schema, CSS, public docs surface, package file, browser config, screenshot, report, or external dependency was added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plans 125-04 and 125-05 to complete Wave 2 Configure, Orient, and policy route proof before the full focused route proof command is run.

---
*Phase: 125-browser-proof-docs-adversarial-ratchet*
*Completed: 2026-06-30*
