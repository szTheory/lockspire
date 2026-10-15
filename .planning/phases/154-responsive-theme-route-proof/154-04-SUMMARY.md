---
phase: 154-responsive-theme-route-proof
plan: "04"
subsystem: admin-ui-test-proof
tags: [accessibility, liveview, test-contract, compile-warning]
requires: ["154-03"]
provides:
  - page contract on 10 Configure routes
  - warning-free keys_live/index.ex
affects: [154-05, 154-06]
key-files:
  created: []
  modified:
    - test/lockspire/web/live/admin/policies_live/index_test.exs
    - test/lockspire/web/live/admin/policies_live/par_test.exs
    - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
    - test/lockspire/web/live/admin/policies_live/dpop_test.exs
    - test/lockspire/web/live/admin/policies_live/dcr_test.exs
    - test/lockspire/web/live/admin/dcr_live_test.exs
    - test/lockspire/web/live/admin/iat_live_test.exs
    - test/lockspire/web/live/admin/keys_live_test.exs
    - lib/lockspire/web/live/admin/keys_live/index.ex
key-decisions:
  - "Removed only the unreachable key_next_action_summary empty-list clause; template guard already excludes it, and a new keys_live_test assertion pins next-step text."
requirements-completed: [UI-07, PROOF-01, SAFE-01]
status: complete
commits: 3
plan_head_before: 535aff4f2089808a223689a17116bfb05875a55a
plan_head_after: 518b53b9f4f6178bb265e435102139be6025c297
actuals:
  tokens: 4000
  tasks: 3
  commits: 3
completed: 2026-10-15
---

# Phase 154 Plan 04: Page contract on Configure routes Summary

`assert_page_contract!` now runs in existing render tests for /admin/policies, /par, /security-profile, /dpop, /dcr, /admin/dcr, /admin/iats, /admin/iats/new, /admin/keys and /admin/keys/:id, and the unreachable `key_next_action_summary` clause that caused a compile warning is gone.

## Commits
- 23cb4e06: five policy pages (form pages use `labels: :required`)
- 68fd6273: dcr hub, iats list, iats/new (pre-generate render only, `labels: :required`), keys index and detail
- 518b53b9: remove unreachable clause; add next-step assertion

## Verification
- Policies, dcr, iat, keys suites pass (51 and 35 tests); `mix test.fast`: 1554 passed, 6 skipped.
- Forced compile log contained no mention of keys_live/index.ex (rc 0). `defp key_next_action_summary` count is 3.
- `copy-once` count in iat_live_test.exs: 11 before, 11 after. Zero deleted lines in all edited test files.
- Protected dirs (redaction.ex, protocol, plugs, admin) unchanged.

## Deviations from Plan

**1. [Rule 3 - Blocking] Missing alias** in dcr_live_test.exs: added `alias Lockspire.Web.AdminProof.HtmlAssertions`.

**2. [Rule 2 - Test pin]** keys_live_test had no assertion for the next-step element set; added one (every next-step span has one of the three texts, fewer spans than keys).

No page defects surfaced by the contract; no markup changes.

**Total deviations:** 2 (minor). **Impact:** none.

## Deferred / Out of scope
`mix format --check-formatted` flags `test/support/lockspire/web/admin_proof/browser_evidence.ex` (`@allowed_viewports` long line from plan 154-01). Pre-existing, not touched here; should be formatted in a later plan.

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
