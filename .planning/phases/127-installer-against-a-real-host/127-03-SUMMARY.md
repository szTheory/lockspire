---
phase: 127-installer-against-a-real-host
plan: 03
subsystem: installer
tags: [mix-task, ecto-migrator, oauth-client-registration, tdd]

# Dependency graph
requires:
  - phase: 127-installer-against-a-real-host
    provides: "127-01's priv/test_fixtures/phx_new_host/ real host snapshot and its committed pattern of proving installer/CLI behavior against a real, unstarted-app host"
provides:
  - "mix lockspire.client.create reaches a started repo from an app.config-only Mix task via Ecto.Migrator.with_repo/2, closing ADOPT-D08"
  - "test/mix/tasks/lockspire_client_create_test.exs -- integration proof (success, confidential-secret-once, validation-failure, unknown-switch paths) that the task registers a client without app.start"
affects: [adopter-path-guardrail, documented-wiring-truth]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mix task DB-touching test cleanup via on_exit + a fresh Ecto.Migrator.with_repo call, since rows written by a task-owned with_repo call are real commits outside any Ecto.Adapters.SQL.Sandbox ownership the test process holds."

key-files:
  created:
    - test/mix/tasks/lockspire_client_create_test.exs
  modified:
    - lib/mix/tasks/lockspire.client.create.ex

key-decisions:
  - "Confirmed empirically (not assumed) that the pre-fix task fails inside the test suite with the exact production error -- \"could not lookup Ecto repo Lockspire.TestRepo because it was not started or it does not exist\" -- by toggling the implementation file between pre-fix and post-fix content via the Edit tool (never via git) and running the test both ways. This reproduces ADOPT-D08 directly rather than trusting the plan's description of the defect."
  - "Rows the test's task invocation persists via Ecto.Migrator.with_repo/2 are genuine commits, not sandboxed -- with_repo starts an independent connection pool the test process's Sandbox ownership never touches. Every test that registers a client explicitly deletes its own row via on_exit (wrapped in its own with_repo call) so the shared lockspire_test database stays clean for the rest of mix test.integration. Verified this was necessary: without cleanup, 3 unrelated Lockspire.Storage.RepositoryTest tests failed from leaked rows; with cleanup, the full 294-test integration suite passes."

requirements-completed: [INSTALL-01]

coverage:
  - id: D1
    description: "mix lockspire.client.create registers a client against a started repo from an app.config-only task, closing the ADOPT-D08 repo-not-started defect, without escalating @requirements to app.start"
    requirement: "INSTALL-01"
    verification:
      - kind: integration
        ref: "test/mix/tasks/lockspire_client_create_test.exs#registers a public client against a started repo and reaches app.config only"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/lockspire_client_create_test.exs#raises a Mix.Error carrying the field:reason(detail) summary when registration fails"
        status: pass
    human_judgment: false
  - id: D2
    description: "A generated client_secret is emitted exactly once on stdout for confidential clients and no file is written by the task"
    requirement: "INSTALL-01"
    verification:
      - kind: integration
        ref: "test/mix/tasks/lockspire_client_create_test.exs#registers a confidential client and prints exactly one secret line, writing no file"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 03: Installer Against A Real Host Summary

**`mix lockspire.client.create` now wraps `Clients.register_client/1` in `Ecto.Migrator.with_repo/2` (mirroring `mix lockspire.verify`'s existing pattern), closing ADOPT-D08 so the task reaches a started repo from an `app.config`-only Mix task instead of exiting 1 against a stock generated host.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-29T13:21:28Z
- **Tasks:** 1 completed (TDD: RED, GREEN)
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Closed ADOPT-D08: `mix lockspire.client.create` previously called `Clients.register_client/1` directly, which crashed with `could not lookup Ecto repo Lockspire.TestRepo because it was not started or it does not exist` under the task's real `@requirements ["app.config"]` declaration (Mix never runs `app.start` for that requirement level, so the host's repo process is never started).
- Fixed by wrapping the registration call in `Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _started_repo -> Clients.register_client(attrs) end)`, destructuring the `{:ok, registration_result, _started_apps}` return shape -- the exact pattern already used by `lib/lockspire/install/verify.ex:202-217` and relied on by `mix lockspire.verify`, which declares the identical `@requirements ["app.config"]`.
- `@requirements ["app.config"]` was left unchanged; the task still never escalates to `app.start` and so never boots the host's full Phoenix endpoint from a CLI invocation (verified via `grep -c 'app.start' lib/mix/tasks/lockspire.client.create.ex` returning 0).
- Added `test/mix/tasks/lockspire_client_create_test.exs` with four integration tests: successful public-client registration (asserting the full `client_id=`/`client_type=`/`redirect_uris=`/`allowed_scopes=`/`allowed_grant_types=`/`token_endpoint_auth_method=` output shape, plus the persisted client readable back through `Lockspire.Admin.Clients.get_client/1`), confidential-client secret-once-and-no-file-written, registration-failure raising `Mix.Error` with the `field:reason(detail)` summary, and unknown-switch rejection before any repo work begins.
- Followed strict TDD: confirmed RED empirically by running the new test against the pre-fix implementation (toggled via the Edit tool, never via git) and observing the exact production defect error, committed the failing test, then implemented the fix and confirmed GREEN.
- Discovered and fixed a real test-isolation gap during verification: rows the task persists via its own `Ecto.Migrator.with_repo/2` call are genuine, non-sandboxed database commits (a separate connection pool outside the test process's `Ecto.Adapters.SQL.Sandbox` ownership). Without explicit cleanup, three unrelated `Lockspire.Storage.RepositoryTest` tests failed from leaked rows when the full integration suite ran. Added `on_exit`-based cleanup (its own `with_repo` + `delete_all` call per registered client) and reverified the full 294-test `mix test.integration` suite passes clean.

## Task Commits

1. **Task 1: Reach a started repo from the app.config task** (TDD):
   - RED - `58da1d6` (test)
   - GREEN - `7e1c9f9` (feat)

## Files Created/Modified

- `lib/mix/tasks/lockspire.client.create.ex` - `run/1` now wraps `Clients.register_client/1` in `Ecto.Migrator.with_repo/2` against `Lockspire.Config.repo!()`; `@requirements ["app.config"]` unchanged
- `test/mix/tasks/lockspire_client_create_test.exs` - `Lockspire.Mix.Tasks.LockspireClientCreateTest`, `@moduletag :integration`, four tests covering success, confidential-secret-once/no-file, validation failure, and unknown-switch rejection, each with `on_exit`-based DB cleanup

## Decisions Made

- Confirmed the pre-fix defect empirically rather than trusting the plan's description: toggled `lib/mix/tasks/lockspire.client.create.ex` between pre-fix and post-fix content with the Edit tool (not git) and ran the new test both ways, observing the exact `could not lookup Ecto repo Lockspire.TestRepo because it was not started or it does not exist` error pre-fix and a clean pass post-fix.
- Added explicit per-test DB cleanup (`on_exit` + a fresh `with_repo` + `delete_all`) because the task's own `Ecto.Migrator.with_repo/2` call starts an independent, non-sandboxed connection pool -- rows it persists are real commits that would otherwise leak into and break other tests sharing `lockspire_test` (verified: without cleanup, 3 `Lockspire.Storage.RepositoryTest` tests failed from leaked `walk-client-create-*` rows; with cleanup, `mix test.integration` is fully green).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added explicit test-database cleanup not specified in the plan's action text**
- **Found during:** Task 1, post-GREEN full-suite verification (`mix test.integration`)
- **Issue:** The plan's action text specified the test should invoke the task and assert output/persistence, but did not anticipate that rows persisted through the task's own `Ecto.Migrator.with_repo/2` call are genuine, non-sandboxed commits. Running the full integration suite after the initial GREEN pass surfaced 3 failing tests in `test/lockspire/storage/repository_test.exs` caused by leaked `walk-client-create-*` rows polluting unrelated `list_clients`/`delete_all` assertions.
- **Fix:** Added an `on_exit`-based cleanup helper (`cleanup_client_on_exit/1`) that deletes each test-registered client via its own `Ecto.Migrator.with_repo/2` + `Ecto.Query` delete, called immediately after each `client_id` is generated in the two client-creating tests.
- **Files modified:** `test/mix/tasks/lockspire_client_create_test.exs`
- **Verification:** Manually deleted the already-leaked `walk-client-create*` rows via `psql`, then reran `mix test.integration` (294 tests, 0 failures) and `mix test.fast` (1285 tests, 0 failures).
- **Committed in:** `58da1d6` (part of the RED test commit -- the cleanup helper was authored before the RED commit was made, so no separate fixup commit was needed)

---

**Total deviations:** 1 auto-fixed (Rule 1 correctness/test-isolation bug)
**Impact on plan:** The fix was necessary to keep the shared integration test database clean and to avoid a hidden ordering dependency between this file and `repository_test.exs`. No scope creep -- the production code change matches the plan's action text exactly.

## Issues Encountered

None beyond the deviation above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `mix lockspire.client.create` now reaches a started repo from an `app.config`-only invocation, matching `mix lockspire.verify`'s existing, proven pattern. Both of the guide's §6 proof-bar commands now work against a stock generated host.
- The `Ecto.Migrator.with_repo/2`-wraps-a-task-owned-repo pattern, and its accompanying `on_exit` + fresh `with_repo` cleanup idiom for Mix-task integration tests that must prove the task starts its own repo, are now established precedent for any remaining `127-0N` plans that touch other `app.config`-only Mix tasks.
- No blockers. `mix test test/mix/tasks/lockspire_client_create_test.exs --include integration`, `mix test.integration`, `mix test.fast`, and `mix qa` are all green with a clean `git status --porcelain`.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*

## Self-Check: PASSED

Both created/modified files confirmed present on disk (`lib/mix/tasks/lockspire.client.create.ex`, `test/mix/tasks/lockspire_client_create_test.exs`); both task commits (`58da1d6`, `7e1c9f9`) confirmed in `git log --oneline --all`.
