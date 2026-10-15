---
phase: 154-responsive-theme-route-proof
plan: "03"
subsystem: admin-ui-test-proof
tags: [accessibility, liveview, test-contract]
requires: []
provides:
  - HtmlAssertions.assert_page_contract!/2
affects: [154-04, 154-05]
key-files:
  created: []
  modified:
    - test/support/lockspire/web/admin_proof/html_assertions.ex
    - test/lockspire/web/live/admin/overview_live_test.exs
    - test/lockspire/web/live/admin/clients_live_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
    - lib/lockspire/web/components/admin_components.ex
key-decisions:
  - "Page contract strips Phoenix-signed data-phx-session/static attributes before the token-like text scan (framework plumbing, not secrets)."
  - "Label check recognizes controls wrapped in a label (confirmation checkboxes) in addition to label[for]."
requirements-completed: [UI-07, PROOF-01]
status: complete
commits: 3
plan_head_before: 6653f970af5560fd0db838da5e0f8961f3a6cdd8
plan_head_after: 6d49a28900468725dad8ada7e29cae8ba75904b7
actuals:
  tokens: 9000
  tasks: 3
  commits: 3
completed: 2026-10-15
---

# Phase 154 Plan 03: Bundled page contract on Orient and client-task routes Summary

`assert_page_contract!/2` (unique IDs, ARIA targets, link hrefs, token-like text, exactly one h1, label wiring) now runs inside existing render tests for all 13 Orient and client-task paths.

## Commits
- 267aff90: helper plus /admin and /admin/overview (includes RED-style raise cases for 0 and 2 h1, and `labels: :required`)
- 069c5870: client inventory, /new, /edit, logout-propagation workflow, plus component fix
- 6d49a289: client detail, redirects, logout-uris, par-policy, security-profile, rotate-secret, rotate-registration-access-token

## Coverage notes
- The nine-route table test in `clients_live/show_test.exs` covers detail, edit, logout-propagation, logout-uris, par-policy, redirects, rotate-registration-access-token, rotate-secret, security-profile (form routes use `labels: :required`). rotate-registration-access-token is also asserted in its dedicated test in `show_test.exs`.
- Rotate pages are checked only on the initial confirmation render, never after submit (copy-once value never scanned or removed from assertions).

## Deviations from Plan

**1. [Rule 1 - Bug] Empty aria-describedby on radio options**
- Found during: Task 2 (/admin/clients/new)
- Issue: `radio_group` rendered `aria-describedby=""` when no description or help existed.
- Fix: new private `radio_option_described_by/3` returns nil (attribute omitted) when empty. No visible text change.
- Files: lib/lockspire/web/components/admin_components.ex
- Commit: 069c5870

**2. [Rule 3 - Blocking] Helper adjustments**
- LiveView root `data-phx-session` tokens tripped the token regex; stripped before scan. Wrapped-label checkboxes (confirm toggles) were reported unlabeled; helper now recognizes controls nested in `label`. No markup changed.
- Commits: 267aff90, 6d49a289

**3. Diff-gate note:** `clients_live_test.exs` shows 1 deleted line vs ef6043ec: the `{:ok, view, _html}` binding in the logout-propagation test was renamed to `workflow_html` so the contract could run. No assertion removed.

**Total deviations:** 3 (1 bug fix, 1 helper adjustment, 1 line rename). **Impact:** none on security assertions.

## Verification
`mix test.fast`: 1554 passed, 6 skipped. Targeted overview, clients, show, design_system, adoption demo suites: 132 passed. `mix format --check-formatted` clean.

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
