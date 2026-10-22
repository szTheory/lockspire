---
phase: 165-management-token-lifecycle-recovery
plan: "05"
subsystem: auth
tags: [oauth, dcr, management-token, ecto, postgres, concurrency]
requires:
  - phase: 165-04
    provides: Current-row management replacement, host recovery, legacy promotion, and rollback contracts
provides:
  - PostgreSQL blocker evidence for management expiry and stale GET/PUT/DELETE requests
  - One-winner race evidence for competing PUT and host-recovery replacements
  - Contended preservation and rollback evidence for secret rotation, disablement, writes, and audits
affects: [dynamic-client-registration, management-token-lifecycle, postgres-concurrency]
actuals:
  tokens: 11160
  tasks: 3
  commits: 3
  plan_head_before: 1ef5d2d2759e96dfead043fd1d880b280546c796
  plan_head_after: 183e04932baae61674e478ddca1587c86a87a969
tech-stack:
  added: []
  patterns:
    - Independent Sandbox.unboxed_run sessions identify backend PIDs and assert exact pg_blocking_pids relationships before release.
    - Barrier clocks advance only after a real PostgreSQL row-lock wait is observed.
    - Contended lifecycle and audit failures are injected with temporary PostgreSQL triggers and removed after each schedule.
key-files:
  created:
    - test/lockspire/storage/management_token_client_wait_test.exs
    - test/lockspire/storage/management_token_replacement_race_test.exs
    - test/lockspire/storage/management_token_mutation_race_test.exs
  modified: []
key-decisions:
  - "Exercise the production management and operator-recovery entry points from independent PostgreSQL sessions; assert durable hashes, deadlines, metadata, enabled state, and audit outcomes after each schedule."
  - "Keep this plan test-only; the production behavior under contention was delivered in plans 165-01 through 165-04."
requirements-completed: [DCR-11, DCR-12]
coverage:
  - id: D1
    description: Management requests re-evaluate expiry and token authority after a verified row-lock wait, while completed reads retain their earlier linearization point.
    requirement: DCR-11
    verification:
      - kind: integration
        ref: test/lockspire/storage/management_token_client_wait_test.exs — 3 tests, including 10 verified blocker schedules
        status: pass
    human_judgment: false
  - id: D2
    description: Competing replacements have one winner, stale retries cannot restore authority, and refreshed recovery can replace the current token.
    requirement: DCR-12
    verification:
      - kind: integration
        ref: test/lockspire/storage/management_token_replacement_race_test.exs — 2 tests, including 5 verified blocker schedules
        status: pass
    human_judgment: false
  - id: D3
    description: Committed secret and disabled state survive management contention, and write/audit failures roll back legacy promotion without disclosing a token.
    requirement: DCR-12
    verification:
      - kind: integration
        ref: test/lockspire/storage/management_token_mutation_race_test.exs — 5 tests, including 9 verified blocker schedules
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-10-21
status: complete
---

# Phase 165 Plan 05: Management Token PostgreSQL Race Proof Summary

**Independent PostgreSQL sessions prove management expiry, one-winner replacement, current-state preservation, and atomic rollback under real client-row contention.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-21T18:28:19Z
- **Completed:** 2026-10-21T18:34:41Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added expiry-at-equality and expiry-after schedules for GET, PUT, and DELETE. Each contender was confirmed blocked by the expected holder backend before the barrier clock advanced; stale replacement snapshots were separately rejected after a committed PUT.
- Added the completed-read control: a GET that acquired current-row authority completed while the replacement waited, after which the old token could no longer replace the new one.
- Added same-fingerprint PUT/PUT, PUT/recovery, recovery/PUT, and recovery/recovery competitions, plus legacy promotion contention. Each schedule recorded one successful replacement, one stale rejection, the winning stored hash, and one replacement audit. Refreshed host recovery succeeded after stale retries failed.
- Added races against shared-secret rotation and disablement, plus contended client-write and required-audit failures. Durable unrelated state survived, failed operations returned no replacement plaintext, v0 lifecycle fields rolled back together, and refreshed retries succeeded after fault removal.

## Task Commits

1. **Task 1: Observe expiry and replacement during blocked management requests** — `64395c8d` (test)
2. **Task 2: Prove one winner across competing replacements** — `7bd2be62` (test)
3. **Task 3: Preserve concurrent secret, disabled state and failed audits** — `183e0493` (test)

**Measured task commits:** 3, from `1ef5d2d2759e96dfead043fd1d880b280546c796` through `183e04932baae61674e478ddca1587c86a87a969`.

## Files Created

- `test/lockspire/storage/management_token_client_wait_test.exs` — expiry after waits, stale GET/PUT/DELETE, and completed-read linearization.
- `test/lockspire/storage/management_token_replacement_race_test.exs` — one-winner replacement schedules, stale retries, refreshed recovery, and legacy promotion.
- `test/lockspire/storage/management_token_mutation_race_test.exs` — secret and disablement preservation, and contended write/audit rollback.

## Verification

- Client wait suite: **3 tests, 0 failures**; 10 blocker observations across expiry, replacement, and read-linearization schedules.
- Replacement suite: **2 tests, 0 failures**; 5 blocker observations across competing replacements and legacy promotion.
- Mutation suite: **5 tests, 0 failures**; 9 blocker observations across secret, disablement, and rollback schedules.
- Total: **10 ExUnit tests, 0 failures, 24 verified blocker relationships**. Every suite ran with `--include postgres_race` against `lockspire_phase165_validation`.
- `mix format` and `git diff --check` passed for the three added files.
- All three successful replacement tokens were checked against their stored hashes; expiry and rollback cases compared durable client and audit state.

## TDD Gate Compliance

All three tasks are test-only: their `<files>` declarations name only new regression suites, and the production behavior being exercised was implemented in plans 165-01 through 165-04. These tests were added against that implementation and the planned focused suites passed. No production implementation step existed in this plan, so no RED/GREEN cycle or separate RED/GREEN commits were produced. The ExUnit output was used as execution evidence; no machine-classified RED evidence is claimed. This is a test-only TDD exemption, not a claim that the RED/GREEN gates passed.

## Deviations from Plan

None. The three declared test files were added; no production files or shared helpers were changed.

## Issues Encountered

- The read-linearization schedule initially waited for the replacement clock before releasing the GET that held the row. The test was corrected to first observe the replacement blocked, then release the completed GET, and finally observe the replacement clock.
- The first commit attempt was denied because the workspace sandbox treats `.git` as read-only. The task commits were made after escalating only the required git operations; no files outside the declared task scope were staged.

## User Setup Required

None. The suites use the dedicated PostgreSQL validation database named in the plan.

## Next Phase Readiness

Plan 165-06 can build event attribution and redaction checks on proven current-row, replacement, and recovery schedules. The validation database's shared server-policy row remains sequentially owned by this lane.

## Self-Check: PASSED

- All three created test files exist.
- Task commits `64395c8d`, `7bd2be62`, and `183e0493` are ancestors of the plan head.
- The persisted plan ledger measured 3 task commits; the `.planning/state.json` bytes still match `/private/tmp/lockspire-phase165-original-state.json` and remain unstaged.
- No placeholder, TODO, or FIXME stubs were found in the added test files; no new production trust boundary was introduced.

---
*Phase: 165-management-token-lifecycle-recovery*
*Completed: 2026-10-21*
