---
phase: 165-management-token-lifecycle-recovery
plan: "03"
subsystem: auth
tags: [oauth, oidc, dcr, management-token, ecto, postgres]
requires:
  - phase: 165-01
    provides: Current-row management access and response deadline extensions
  - phase: 165-02
    provides: Management lifetime policy and issuance snapshots
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: PUT identity, replacement, deadline, and legacy promotion contract
provides:
  - RFC 7592 PUT body identity and immutable-field validation
  - Current-policy management token replacement with atomic hash, deadline, metadata, and audit
  - Server-owned lifecycle extensions rejected at new registration intake
affects: [dynamic-client-registration, management-token-lifecycle, client-lifecycle]
tech-stack:
  added: []
  patterns:
    - Prepare replacement policy and metadata from the locked current row before sampling decision time
    - Carry only the intended management deadline and decision timestamp through the existing replacement Client callback
    - Merge full-replacement metadata and whole-row lifetime changes into the locked repository row
key-files:
  created:
    - test/integration/management_token_lifetime_update_test.exs
    - test/lockspire/protocol/management_token_request_contract_test.exs
    - .planning/phases/165-management-token-lifecycle-recovery/165-03-01-red-evidence.json
    - .planning/phases/165-management-token-lifecycle-recovery/165-03-02-red-evidence.json
  modified:
    - lib/lockspire/protocol/registration_management.ex
    - lib/lockspire/client_lifecycle.ex
    - lib/lockspire/storage/ecto/repository/client_store.ex
    - lib/lockspire/web/controllers/registration_controller.ex
    - lib/lockspire/protocol/registration.ex
    - test/integration/app_lifetime_management_test.exs
    - test/lockspire/protocol/registration_management_test.exs
    - test/lockspire/web/controllers/registration_controller_test.exs
decisions:
  - "Keep the existing replace_client_registration/4 callback and carry intended deadline/time on its replacement Client."
  - "Resolve current server policy and validate current-row request echoes after locking, then sample one decision instant for authorization, deadline, and audit."
  - "On v0 management replacement, use Client.credential_lifetime_changes/3 to clear advisory unrelated dates and promote the complete current row."
metrics:
  duration: 10min
  completed: 2026-10-21
  tasks: 2
  files: 12
  commits: 5
  plan_head_before: 7a5916a8af87bb82a1d58aee32b1ac0ed98ef3e9
  plan_head_after: d4a478fd78a9fe663cd31031263d51a51bf02bcc
actuals:
  tokens: 13550
  tasks: 2
  commits: 5
status: complete
---

# Phase 165 Plan 03: Atomic Management-Token PUT Summary

**A registration PUT now validates its body independently of the URL and atomically replaces mutable metadata, the management-token hash and deadline, and the required audit record using current locked-row state.**

## Performance

- **Duration:** 10 min
- **Tasks:** 2
- **Files changed:** 12, including two machine-validated TDD evidence records

## Accomplishments

- The controller passes `path_params` identity separately from untouched `body_params`. PUT requires an unchanged body `client_id`; it rejects forbidden standard fields and verifies any included `client_secret` against current stored material without rotating it.
- Management lifecycle extensions preserve current server values when omitted, accept identical integer echoes, and reject changed or wrongly typed echoes. New registration intake rejects either client-supplied lifecycle extension.
- After locking and reloading the current row, PUT resolves current server policy, validates current identity, secret, and extension state, then samples one UTC-second decision time. That instant sets the replacement deadline, `updated_at`, and audit `rotated_at`.
- The existing `replace_client_registration/4` callback remains unchanged. Its replacement Client carries the intended management deadline and decision time; the repository merges approved metadata and canonical lifetime changes into the locked row, then commits them with the new hash and audit.
- Integration proof covers current-policy rotation, old-deadline echoes, stale-token rejection, audit time, v0 whole-row promotion, preserved v1 app/secret deadlines, and no second write on replay. Existing successful PUT fixtures now include body identity.

## Task Commits

1. **Task 1 RED:** `dd2d0feb` — prove PUT replacement deadline and independent body identity.
2. **Task 1 GREEN:** `542f70ee` — rotate the management token under current policy.
3. **Task 2 RED:** `8a4413b9` — add request-contract tests and validated intake RED evidence.
4. **Task 2 GREEN:** `9493e154` — reject client-supplied lifecycle extensions at intake.
5. **Additional planned edge-case proof:** `d4a478fd` — assert old-deadline echoes, audit decision time, and v0 promotion.

## TDD Gate Compliance

| Task | RED evidence | GREEN evidence |
| --- | --- | --- |
| 165-03-01 | `165-03-01-red-evidence.json` returned `RED_EVIDENCE_OK`; the successful PUT persisted no management deadline. | The focused integration suite passed with 3 tests and 0 failures, including v0 promotion and audit-time checks. |
| 165-03-02 | `165-03-02-red-evidence.json` returned `RED_EVIDENCE_OK`; registration intake accepted a server-owned lifecycle extension. | The complete focused suite passed with 62 tests and 0 failures. |

The default ExUnit CLI report is not one of the RED-evidence parser formats. A temporary local TAP formatter was configured for each RED run and removed afterward; the saved TAP output came directly from ExUnit during the named test run. No dependency or persistent test-runner configuration was added.

## Verification

- `mix test test/integration/management_token_lifetime_update_test.exs --max-failures 1 --timeout 55000` — **3 tests, 0 failures**.
- `mix test test/lockspire/protocol/management_token_request_contract_test.exs test/lockspire/web/controllers/registration_controller_test.exs test/lockspire/protocol/registration_management_test.exs test/integration/app_lifetime_management_test.exs test/integration/management_token_lifetime_update_test.exs --max-failures 1 --timeout 55000` — **62 tests, 0 failures**.
- `mix format` passed for the changed Elixir files; `git diff --check` passed.
- TDD evidence checks returned `RED_EVIDENCE_OK` for both tasks.

## Deviations from Plan

None. The extra integration assertions cover the plan's stated audit-time and legacy-v0 success criteria.

## Issues Encountered

- The TDD evidence classifier does not parse ExUnit's default text report. A temporary ExUnit TAP formatter provided a supported report from the actual test run; the temporary test-helper edits were reverted before commits.
- DateTime structural equality differs after database round-trip precision normalization. Tests compare instants with `DateTime.compare/2` instead.

## User Setup Required

None.

## Next Phase Readiness

Plans 165-04 and 165-05 can build on the current-policy PUT path, intended replacement transport, current-row lifetime promotion, and body-field contract. Independent PostgreSQL contended-write proof and rollback coverage remain assigned to later plans.

## Self-Check: PASSED

- The ten plan source/test files and both RED-evidence records exist.
- All five measured plan commits are ancestors of the recorded plan head.
- Both focused verification commands passed with nonzero test counts; no stubs or placeholders were found in changed source and test files.
- `.planning/state.json` still matches `/private/tmp/lockspire-phase165-original-state.json` and remains unstaged.

---
*Phase: 165-management-token-lifecycle-recovery*
*Completed: 2026-10-21*
