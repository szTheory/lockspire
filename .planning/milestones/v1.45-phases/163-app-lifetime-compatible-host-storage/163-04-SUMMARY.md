---
phase: 163-app-lifetime-compatible-host-storage
plan: "04"
subsystem: authorization
tags: [oauth, authorization, client-lifetime, par, jarm]
dependency-graph:
  requires: [163-01, 163-02, 163-03]
  provides: [current-app-authorization-intake, guarded-authorization-completion, post-commit-jarm]
  affects: [authorization-request, pushed-authorization-request, authorization-flow, interaction-storage]
tech-stack:
  added: []
  patterns: [current-client-lifetime-guard, mutation-callback-after-lock, post-transaction-response-build]
key-files:
  created:
    - test/integration/app_lifetime_authorization_test.exs
  modified:
    - lib/lockspire/protocol/authorization_request.ex
    - lib/lockspire/protocol/pushed_authorization_request.ex
    - lib/lockspire/protocol/authorization_flow.ex
    - lib/lockspire/storage/interaction_store.ex
    - lib/lockspire/storage/ecto/repository/interaction_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/protocol/authorization_flow_test.exs
decisions:
  - Use declared ClientLifetime adapters for browser intake, PAR, and completion guards.
  - Sample completion time only inside the current locked interaction mutation.
  - Build normal and JARM responses after transaction completion.
metrics:
  duration: "bounded execution"
  completed: 2026-10-20
  tasks: 2
  commits: pending-parent
status: complete
actuals:
  tokens: 14000
  tasks: 2
  commits: pending-parent
plan_head_before: pending-parent
plan_head_after: pending-parent
---

# Phase 163 Plan 04: Guard authorization entry and completion Summary

Browser and PAR intake now evaluate current app eligibility before host handoff, while resumed authorization, remembered consent, and approval recheck the durable client after ordered client/interaction locks. Response construction, including remote JARM key resolution, runs after commit.

## Completed Tasks

| Task | Result |
| --- | --- |
| 1. Reject expired authorization and PAR before host work | Added app-lifetime checks at browser intake and PAR create/use, preserving redirect trust, state, and one-time PAR behavior. |
| 2. Guard resumed authorization and finish JARM after releasing locks | Added client-before-interaction guards, final-time mutation callbacks, post-commit response construction, and an independent-session lock probe. |

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_authorization_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/authorization_flow_test.exs test/lockspire/protocol/jarm_test.exs --max-failures 1` — passed, 103 tests, 0 failures.
- `git diff --check` on the Plan 04 source and test files — passed.
- The broader `mix test.fast` wave check was not run; the orchestrator requested bounded Plan 04 work and no full `test.fast` run.

## Deviations from Plan

**1. [Rule 2 - Missing critical adapter support] Exposed guarded interaction transitions through the repository facade.**
- **Found during:** Task 2
- **Issue:** `Repository` did not expose the interaction store's mutation-callback transition contract required to evaluate decision time after acquiring the interaction lock.
- **Fix:** Added the narrow facade delegation so consumers use the configured adapter consistently.
- **Files modified:** `lib/lockspire/storage/ecto/repository.ex`
- **Commit:** pending parent orchestration.

**2. [Rule 3 - Blocking test adapter contract] Updated the authorization-flow fake adapter for the typed lifetime contract.**
- **Found during:** Task 2 focused verification
- **Issue:** The existing test adapter did not declare lifetime support, transaction authority, or callback transitions, so valid flow tests failed closed under the new guard.
- **Fix:** Added explicit v0 client fixtures, current-client lock/fetch callbacks, shared authority declaration, rollback behavior, and callback transition handling.
- **Files modified:** `test/lockspire/protocol/authorization_flow_test.exs`
- **Commit:** pending parent orchestration.

## Remaining Phase Boundaries

Credential lifetime issuance and redemption coverage remains assigned to Plan 06. This plan does not close that later requirement.

## Self-Check: PASSED

The integration test and all listed source/test files exist; parent orchestration will record the final commit metadata.

Parent combined implementation commit: `ff424b48c123d369a77ab2963c935bf8467bc9bd`; fresh combined consumer run296tests0failures.
