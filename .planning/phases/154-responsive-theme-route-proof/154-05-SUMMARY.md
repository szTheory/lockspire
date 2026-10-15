---
phase: 154-responsive-theme-route-proof
plan: "05"
subsystem: admin-ui-test-proof
tags: [accessibility, liveview, test-contract, compile-warning]
requires: ["154-03"]
provides:
  - page contract on 7 Support and Operate routes
  - warning-free device_authorizations_live/index.ex
affects: [154-06]
key-files:
  created: []
  modified:
    - test/lockspire/web/live/admin/consents_live_test.exs
    - test/lockspire/web/live/admin/tokens_live_test.exs
    - test/lockspire/web/live/admin/interactions_live_test.exs
    - test/lockspire/web/live/admin/device_authorizations_live_test.exs
    - test/lockspire/web/live/admin/logout_deliveries_live_test.exs
    - lib/lockspire/web/live/admin/device_authorizations_live/index.ex
key-decisions:
  - "Pure clause move of filter_device_authorizations(:all) next to :pending; no logic change."
requirements-completed: [UI-07, PROOF-01, SAFE-01]
status: complete
commits: 3
plan_head_before: 263dfae26cd616f2c20c29dc182ef8239a7b5b06
plan_head_after: 5e44fe5d0c8f5259b8089538a875e885370057f2
actuals:
  tokens: 1500
  tasks: 3
  commits: 3
completed: 2026-10-15
---

# Phase 154 Plan 05: Page contract on Support and Operate routes Summary

`assert_page_contract!` now runs in existing render tests for /admin/consents, /admin/consents/:id, /admin/tokens, /admin/tokens/:id, /admin/interactions, /admin/device_authorizations and /admin/logouts, and the split `filter_device_authorizations/2` clauses that caused a compile warning are grouped.

## Commits
- a10002ab: consent and token list/detail pages (index pages use `labels: :required`)
- 68da9ab8: interactions, device authorizations, logouts queues (default labels)
- 5e44fe5d: move `:all` filter clause next to `:pending` (numstat 2/2)

## Verification
- Five page suites plus route_contract_test: 67 passed. `mix test.fast`: 1554 passed, 6 skipped.
- Forced recompile log contains no mention of device_authorizations_live/index.ex.
- Zero deleted lines in all five edited test files versus ef6043ec. `mix format --check-formatted` clean.
- No markup, handler, or form added to queues; revocation-scope tests untouched.

## Deviations from Plan

None - plan executed exactly as written. The contract surfaced no page defects.

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
