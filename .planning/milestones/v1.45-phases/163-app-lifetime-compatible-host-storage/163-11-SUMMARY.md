---
phase: 163-app-lifetime-compatible-host-storage
plan: "11"
subsystem: auth
tags: [elixir, oauth, dcr, client-lifetime, postgres]
requires:
  - phase: 163-01
    provides: Client lifetime fields and app eligibility semantics
  - phase: 163-02
    provides: Typed lifetime adapter and transaction-scoped current-row locks
provides:
  - Current-credential DCR management gates for expired and disabled apps
  - Atomic legacy promotion for management and secret replacement
affects: [163-12, 163-13, 163-14, phase-164-secret-lifetime, phase-165-management-lifetime]
tech-stack:
  added: []
  patterns: [locked-current-client mutations, credential-specific legacy lifetime promotion]
key-files:
  created:
    - test/integration/app_lifetime_management_test.exs
    - test/lockspire/storage/client_lifetime_promotion_test.exs
  modified:
    - lib/lockspire/protocol/registration_management.ex
    - lib/lockspire/web/controllers/registration_controller.ex
    - lib/lockspire/client_lifecycle.ex
    - lib/lockspire/storage/ecto/repository/client_store.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/domain/client.ex
key-decisions:
  - "Expired enabled apps may be read or deleted with the current management credential; PUT returns registration_expired."
  - "A credential replacement promotes v0 from the locked row and applies only intended metadata and credential changes."
  - "Management intake policy gates registration creation only; it does not disable existing management."
actuals:
  tokens: 7663
  tasks: 2
  commits: 0 # Parent owns the task and metadata commits; update from the parent plan ledger.
requirements-completed: [] # Phase-level proof pending
duration: 5min
completed: 2026-10-20
status: complete
---

# Phase 163 Plan 11: App Management and Legacy Promotion Summary

**DCR management now checks the locked current credential and app state, while credential replacement promotes v0 without restoring stale credentials or lifecycle state.**

## Accomplishments

- Expired enabled apps allow current-credential GET and DELETE; PUT returns HTTP 403 with `registration_expired` and leaves the row unchanged.
- Disabled apps, stale credentials, and unknown credentials return the existing non-disclosing 401 behavior. Closed registration intake affects creation only.
- Management and secret replacement promote legacy clients atomically, clear advisory unrelated deadlines, preserve unrelated current credential and active state, and include required audit writes in rollback.
- Ordinary metadata edits and enablement preserve v0 and historical secret timestamp bytes.

## Files Created or Modified

- `lib/lockspire/protocol/registration_management.ex` — current-row credential, URL, active-state, and app-lifetime checks for management operations.
- `lib/lockspire/web/controllers/registration_controller.ex` — intake gate scoped to registration creation and `registration_expired` HTTP mapping.
- `lib/lockspire/storage/ecto/repository/client_store.ex` — locked-row delta writes, credential checks, and atomic v0 promotion.
- `lib/lockspire/storage/ecto/client_record.ex` — purpose-limited changesets for DCR metadata/RAT and secret rotation.
- `lib/lockspire/domain/client.ex` — explicit credential lifetime promotion rules.
- `test/integration/app_lifetime_management_test.exs` — HTTP operation/state matrix, intake closure, stale and missing credential behavior, and rejected-PUT state proof.
- `test/lockspire/storage/client_lifetime_promotion_test.exs` — management/secret promotion, non-promotion, stale snapshot preservation, and audit rollback.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_management_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs --max-failures 1` — passed, 38 tests, 0 failures.
- `git diff --check` — passed.
- `mix format` ran on the seven assigned source/test files.

## Deviations and Boundaries

- The task used `tdd="true"`, but implementation edits preceded creation of the two new test files; a contract-specific RED/GREEN sequence was not recorded. The focused suite passed after tests were added.
- Finite registration access token expiry and recovery remain Phase 165 work. This plan sets replacement management-token deadlines to unlimited under the currently selected policy and does not extend app deadlines.
- Parent agent owns task commits and project state updates; no commits or state files were changed by this subtask.

## Self-Check: PASSED

- Summary file created at the plan output path.
- Focused automated verification passed after the final source edit.
- All source and test changes are limited to Plan 163-11's assigned files.

Parent implementation commit: `89b2815e2c52570b2cc250dc1f6c94dd5bbe17b5`; fresh parentverification38tests0failures.
