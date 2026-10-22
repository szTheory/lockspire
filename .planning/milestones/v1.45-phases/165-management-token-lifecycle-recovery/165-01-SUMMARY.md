---
phase: 165-management-token-lifecycle-recovery
plan: "01"
subsystem: auth
tags: [oauth, oidc, phoenix, ecto, postgres, bearer-tokens]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Management lifetime and HTTP error semantics
  - phase: 163-app-lifetime-compatible-host-storage
    provides: Compatible app lifetime storage
  - phase: 164-client-secret-expiry-atomic-rotation
    provides: Existing client lifecycle and deadline patterns
provides:
  - Current-row, post-lock decision-time validation for management-token GET/PUT/DELETE
  - Server-derived registration lifetime extensions and non-disclosing GET output
  - Distinct missing-token, invalid-token, and server-error HTTP responses
affects: [management-token-lifecycle, dynamic-client-registration, oauth-errors]
actuals:
  tokens: 11919
  tasks: 3
  commits: 7
  plan_head_before: ee7f8d2cebe45558de67acbd8ce6abde9dd625ba
  plan_head_after: c99bbc9ad1e1e4100118d0bc108f1d41555d7735
tech-stack:
  added: []
  patterns:
    - Deferred UTC-second decision clocks sampled only after the current client row is locked
    - Server-owned JSON extension fields derived from persisted effective deadlines
key-files:
  created:
    - test/integration/management_token_lifetime_access_test.exs
    - .planning/phases/165-management-token-lifecycle-recovery/165-01-01-red-evidence.json
    - .planning/phases/165-management-token-lifecycle-recovery/165-01-02-update-red-evidence.json
    - .planning/phases/165-management-token-lifecycle-recovery/165-01-02-delete-red-evidence.json
    - .planning/phases/165-management-token-lifecycle-recovery/165-01-03-red-evidence.json
    - .planning/phases/165-management-token-lifecycle-recovery/165-01-missing-row-red-evidence.json
  modified:
    - lib/lockspire/client_lifecycle.ex
    - lib/lockspire/domain/client.ex
    - lib/lockspire/protocol/registration_management.ex
    - lib/lockspire/web/controllers/registration_controller.ex
    - lib/lockspire/web/registration_json.ex
    - test/integration/app_lifetime_management_test.exs
    - test/lockspire/protocol/registration_management_test.exs
    - test/lockspire/web/controllers/registration_controller_test.exs
key-decisions:
  - "Sample one UTC-second management decision time after locking and reloading the current client row."
  - "Validate management-token eligibility before allowing GET/DELETE on naturally expired enabled apps."
  - "Keep durable-state and persistence failures as redacted server errors; only supplied invalid credentials map to invalid_token."
patterns-established:
  - "Management API operations validate URL, client identity, active status, and token hash against the locked row."
  - "Server-owned credential and lifetime fields override or remove metadata aliases during JSON serialization."
requirements-completed: [DCR-11]
coverage:
  - id: D1
    description: Finite management-token GET validates persisted expiry and returns no credential material.
    requirement: DCR-11
    verification:
      - kind: integration
        ref: test/integration/management_token_lifetime_access_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: GET, PUT, and DELETE enforce current locked-row authority and one final decision time.
    requirement: DCR-11
    verification:
      - kind: integration
        ref: test/lockspire/protocol/registration_management_test.exs; test/integration/app_lifetime_management_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Management endpoints distinguish absent credentials, invalid credentials, and server failures.
    requirement: DCR-11
    verification:
      - kind: unit
        ref: test/lockspire/web/controllers/registration_controller_test.exs
        status: pass
      - kind: integration
        ref: test/integration/app_lifetime_management_test.exs
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-10-21
status: complete
---

# Phase 165 Plan 01: Management Token Lifecycle Recovery Summary

**Finite management-token access now uses locked current-row authority and a single post-lock decision time, with safe OAuth errors and server-derived lifetime fields.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-10-21T17:40:00Z
- **Completed:** 2026-10-21T17:53:15Z
- **Tasks:** 3
- **Files modified:** 14 (9 source/test files and 5 RED-evidence records)

## Accomplishments

- Proved finite-token GET through the real controller, protocol, locked TestRepo row, and JSON serializer, including expiry equality, non-renewal, numeric effective lifetime extensions, and credential/hash disclosure checks.
- Applied current locked-row identity, URL, active-state, token-hash, and finite-lifetime checks consistently to GET, PUT, and DELETE; expiry and audit writes share one post-lock decision time.
- Made absent Bearer credentials, invalid supplied credentials, and repository/configuration/durable-state errors produce distinct, non-disclosing HTTP responses.

## Task Commits

1. **Task 1 RED:** `4a9c72e4` (test) — reject expired management-token access.
2. **Task 1 GREEN:** `76e7a3d3` (feat) — enforce finite management-token GET.
3. **Task 2 RED:** `ad14c734` (test) — cover final management decision time.
4. **Task 2 GREEN:** `0e693d48` (feat) — carry final decision time through management.
5. **Task 3 RED:** `0531b108` (test) — distinguish missing Bearer credentials.
6. **Task 3 edge-case RED:** `95c796fc` (test) — reject a missing locked management row.
7. **Task 3 GREEN:** `c99bbc9a` (feat) — map registration management errors safely.

The stale-row edge case was discovered while reviewing the current-row gate. The plan's output is committed separately after state and roadmap updates.

## Files Created/Modified

- `lib/lockspire/domain/client.ex` — effective app/management deadlines and strict management-token eligibility.
- `lib/lockspire/protocol/registration_management.ex` — post-lock deferred time, final current-row checks, and optional time injection for reads/deletes/updates.
- `lib/lockspire/client_lifecycle.ex` — timestamp-aware DCR disable path while retaining the compatible arity.
- `lib/lockspire/web/registration_json.ex` — durable effective deadline extensions and removal of credential/server-field aliases.
- `lib/lockspire/web/controllers/registration_controller.ex` — stable distinction between absent credentials, invalid tokens, and server failures.
- `test/integration/management_token_lifetime_access_test.exs` — real HTTP-to-PostgreSQL tracer and management access matrix.
- `test/integration/app_lifetime_management_test.exs`, `test/lockspire/protocol/registration_management_test.exs`, and `test/lockspire/web/controllers/registration_controller_test.exs` — app-state, protocol, and wire-error cases.
- Five `165-01-*-red-evidence.json` files — recorded RED evidence for the TDD tasks and locked-row edge case.

## Decisions Made

- Resolve and normalize the decision clock only after transaction lock/reload and current URL, identity, and token-hash checks.
- Check management-token eligibility before the expired-enabled-app GET/DELETE allowance; PUT remains rejected for naturally expired apps.
- Keep persistence, unsupported-state, and policy errors as redacted server errors rather than invalid-token responses.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Treat a missing locked client row as an invalid credential**
- **Found during:** Task 3 (Separate absent Bearer, invalid Bearer and server failures)
- **Issue:** The repository could return an empty row set after the candidate row disappeared; the protocol's prior match path converted it into an unexpected server error.
- **Fix:** Map the empty locked-row result to `invalid_token` and add a regression test with RED evidence.
- **Files modified:** `lib/lockspire/protocol/registration_management.ex`, `test/lockspire/protocol/registration_management_test.exs`
- **Verification:** Task 2 protocol/integration suite and Task 3 controller/integration suite passed.
- **Committed in:** `95c796fc` (RED test) and `c99bbc9a` (fix).

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** The correction completes the planned invalid-credential versus server-error distinction; no architectural or scope change.

## Verification

- Dedicated DB setup: the plan's `mix test.setup` command completed successfully for `lockspire_phase165_validation` (“Migrations already up”).
- Task 1: `mix test test/integration/management_token_lifetime_access_test.exs --max-failures 1 --timeout 55000` — **3 tests, 0 failures**.
- Task 2: `mix test test/lockspire/protocol/registration_management_test.exs test/integration/management_token_lifetime_access_test.exs test/integration/app_lifetime_management_test.exs --max-failures 1 --timeout 55000` — **44 tests, 0 failures**.
- Task 3: `mix test test/lockspire/web/controllers/registration_controller_test.exs test/integration/app_lifetime_management_test.exs --max-failures 1 --timeout 55000` — **19 tests, 0 failures**.
- `mix format` passed for all changed source/test files; `git diff --check` passed.
- Each TDD RED suite was checked using `gsd_run check tdd-red-evidence`; all five evidence records classified `RED_EVIDENCE_OK`.

## Issues Encountered

Git metadata writes were sandbox-restricted and required the authorized escalation to perform normal commits with hooks. No hooks were bypassed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The finite management-token access contract is covered for all three management operations and safe wire errors. The next plan can build on the durable deadline semantics and current-row gate.

## Self-Check: PASSED

- Summary file exists.
- All seven task commits are ancestors of the current plan head.
- The five TDD RED-evidence files are present.
- No stub/TODO placeholder patterns were found in the plan's changed source and test files.

---
*Phase: 165-management-token-lifecycle-recovery*
*Completed: 2026-10-21*
