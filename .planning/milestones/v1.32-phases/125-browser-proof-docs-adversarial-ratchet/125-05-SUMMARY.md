---
phase: 125-browser-proof-docs-adversarial-ratchet
plan: "05"
subsystem: testing
tags: [phoenix-liveview, admin-proof, accessibility, redaction, route-proof]

requires:
  - phase: 125-browser-proof-docs-adversarial-ratchet
    provides: Shared fixture, global guardrail, Support/Operate, and Configure proof foundations from Plans 01-04.
provides:
  - Orient overview route proof for source-derived route truth, journey pivots, accessibility/link contracts, redaction, and unsupported-control denial.
  - Policy overview route proof for posture cards, route-specific review pivots, zero-count state, redaction, and public-surface boundary denial.
  - PAR, DPoP, and security-profile route proof for global issuer posture, inherited-client impact, validation boundaries, policy nav links, and unsupported-control denial.
affects: [phase-125, proof-ratchet, admin-liveview-tests, v1.32-closeout]

tech-stack:
  added: []
  patterns:
    - Focused LiveView route tests reuse HtmlAssertions for rendered HTML accessibility, link, generic CTA, and denied-text guardrails.
    - Source route truth is asserted through Phoenix.Router.routes rather than screenshots, host mounts, or manual evidence.

key-files:
  created:
    - .planning/phases/125-browser-proof-docs-adversarial-ratchet/125-05-SUMMARY.md
  modified:
    - test/lockspire/web/live/admin/overview_live_test.exs
    - test/lockspire/web/live/admin/policies_live/index_test.exs
    - test/lockspire/web/live/admin/policies_live/par_test.exs
    - test/lockspire/web/live/admin/policies_live/dpop_test.exs
    - test/lockspire/web/live/admin/policies_live/security_profile_test.exs

key-decisions:
  - "Kept Plan 05 proof test-only in focused LiveView route tests; no runtime, route, schema, dependency, browser tooling, public theming, or public support surface changed."
  - "Used explicit rendered deny lists on initial LiveView route HTML where broad token-like regexes would inspect Phoenix test harness session attributes instead of page content."

patterns-established:
  - "Overview route proof asserts source-derived /admin and /admin/overview routes plus real journey links to Configure, Support, Operate, and DCR workflows."
  - "Policy route proof asserts policy-nav hrefs and global-scope copy before save behavior, then denies unsupported host-owned, public-theming, AI-gate, backend, and secret surfaces."

requirements-completed:
  - PROOF-01
  - PROOF-02

duration: 6 min
completed: 2026-06-30
status: complete
---

# Phase 125 Plan 05: Orient And Policy Route Proof Summary

**Rendered LiveView proof now covers Orient overview, policy overview, PAR, DPoP, and security-profile routes with source route truth, posture copy, link/accessibility guardrails, redaction denial, and unsupported-control boundaries.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-30T16:32:04Z
- **Completed:** 2026-06-30T16:38:04Z
- **Tasks:** 2
- **Files modified:** 5 test files plus this summary

## Accomplishments

- Added source-derived overview route assertions for `/admin` and `/admin/overview`, plus rendered Orient proof for journey links, focus/link-safe navigation, secret/backend denial, and no unsupported mutation controls.
- Hardened policy overview proof around route-specific review labels, zero-count posture, policy-card details, and denial of public theming, browser-proof API, AI judge, credential, and host-owned surfaces.
- Hardened PAR, DPoP, and security-profile proof around policy-nav hrefs, global issuer scope, inherited-client copy, validation boundaries, and denial of raw proof, nonce reset, remote key fetch, per-client mutation, tenant policy, AI gate, and backend leakage claims.

## Task Commits

Each task was committed atomically:

1. **Task 125-05-01: Add Orient and policy overview proof** - `1e7a00b` (test)
2. **Task 125-05-02: Add non-DCR policy route proof** - `86b5843` (test)

## Files Created/Modified

- `test/lockspire/web/live/admin/overview_live_test.exs` - Adds source route proof for overview routes and rendered Orient guardrails.
- `test/lockspire/web/live/admin/policies_live/index_test.exs` - Adds policy overview posture, route pivot, redaction, and unsupported-surface proof.
- `test/lockspire/web/live/admin/policies_live/par_test.exs` - Adds policy-nav, global-scope, and unsupported-control proof for PAR.
- `test/lockspire/web/live/admin/policies_live/dpop_test.exs` - Adds policy-nav, sender-constraint scope, and unsupported-control proof for DPoP.
- `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` - Adds policy-nav, strict-readiness, host-boundary, and unsupported-control proof for security profiles.

## Verification

- `MIX_ENV=test mix test test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/policies_live/index_test.exs --max-failures 1` - PASS, 5 tests, 0 failures.
- `mix format --check-formatted test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/policies_live/index_test.exs` - PASS.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs --max-failures 1` - PASS, 15 tests, 0 failures.
- `mix format --check-formatted test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs` - PASS.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/policies_live/index_test.exs test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs --max-failures 1` - PASS, 20 tests, 0 failures.
- Full focused Wave 2 route proof from `125-VALIDATION.md` - PASS, 162 tests, 0 failures.
- `mix format --check-formatted` for all five touched test files - PASS.

## Decisions Made

- Kept all Plan 05 changes in test files. No runtime LiveView, router, schema, CSS, dependency, browser tooling, public docs, public theming, or host-owned support surface changed.
- Used explicit sensitive and unsupported-surface denial lists on initial LiveView route HTML because the broad `assert_no_token_like_text/1` helper can inspect Phoenix LiveView test harness session attributes on initial page renders.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale policy landing copy assertion**
- **Found during:** Task 125-05-01
- **Issue:** `overview_live_test.exs` still expected `Issuer posture`, but the current policy landing page renders `Policy posture`.
- **Fix:** Updated the assertion to match the current rendered route copy while adding the planned policy overview proof.
- **Files modified:** `test/lockspire/web/live/admin/overview_live_test.exs`
- **Verification:** Task 1 focused test command passed with 5 tests, 0 failures.
- **Committed in:** `1e7a00b`

---

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** The fix was limited to a stale assertion in a planned test file and was required for current route proof correctness. No scope expansion.

## Issues Encountered

- Test runs emitted the existing KeyCache startup warning before `Lockspire.TestRepo` was available, but all focused commands completed successfully with zero failures.
- Broad token-like regex checks were not applied to initial LiveView page HTML because Phoenix wrapper session attributes can match those patterns; explicit sensitive-value and unsupported-surface denial lists were used for route content proof.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05 closes the Wave 2 route-proof matrix for Orient and remaining Configure policy routes. Phase 125 is ready for Plan 06 to create maintainer proof artifacts, operator docs closeout, and final adversarial review.

## Self-Check: PASSED

- Found all five modified test files on disk.
- Found task commits `1e7a00b` and `86b5843` in git history.
- Stub scan found no TODO/FIXME/placeholder/empty-data rendering stubs in the five modified test files.
- Threat surface scan found no new network endpoints, auth paths, file access patterns, schema changes, runtime routes, package/browser tooling, or public support-surface changes.

---
*Phase: 125-browser-proof-docs-adversarial-ratchet*
*Completed: 2026-06-30*
