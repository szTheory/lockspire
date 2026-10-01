---
phase: 140-bounded-operational-loose-end-triage
plan: "08"
subsystem: testing
tags: [mix-ci, release-hygiene, fixture-isolation, oauth-tests]
requires:
  - phase: 140-05
    provides: Initial loose-end inventory and scoped disposition work.
  - phase: 140-06
    provides: Prior bounded repair and repository-hygiene evidence.
  - phase: 140-07
    provides: Pre-final-acceptance candidate and supporting findings.
provides:
  - Complete redacted census of all 45 intermediate local CI failures and the initial formatter findings.
  - Focused root dispositions tied to a clean full local mix ci result.
  - Final CI evidence reconciled into the Phase 140 disposition record.
affects: [phase-140-final-acceptance, local-ci, release-hygiene]
actuals:
  tokens: 17448
  tasks: 2
  commits: 17
  plan_head_before: a6d6dcfd4abb589650f7dd46be44de7a877b3ff0
tech-stack:
  added: []
  patterns: [Full local CI logs stored mode 0600 in private temporary storage; fixture isolation via per-test sandbox owners]
key-files:
  created: [.planning/phases/140-bounded-operational-loose-end-triage/140-08-SUMMARY.md]
  modified:
    - .planning/phases/140-bounded-operational-loose-end-triage/140-CI-FAILURES.md
    - .planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md
    - test/support/lockspire/release_proof/workflow_assertions.ex
    - test/lockspire/protocol/authorization_request_test.exs
    - test/lockspire/protocol/pushed_authorization_request_test.exs
    - test/lockspire/admin/keys_test.exs
    - test/lockspire/web/authorize_controller_test.exs
    - test/lockspire/web/live/admin/clients_live_test.exs
    - test/lockspire/web/live/admin/policies_live/dpop_test.exs
    - test/lockspire/web/live/admin/policies_live/par_test.exs
    - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/lockspire/release_readiness_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Preserved every observed failure identity and distinguished historical failures from the final passing candidate."
  - "Closed findings outside Plan 140-08 files through exact-scope gap plans before accepting the full CI result."
  - "Recorded Hex cache and .git/FETCH_HEAD diagnostics as non-blocking only because the audit summaries and later CI gates completed."
requirements-completed: [LOOSE-02, LOOSE-03, CI-06]
coverage:
  - id: D1
    description: Complete redacted census with exact test identities, source locations, root groups, and final dispositions.
    requirement: LOOSE-02
    verification:
      - kind: other
        ref: "python census check: 45 exact rows; both raw CI logs mode 0600"
        status: pass
    human_judgment: false
  - id: D2
    description: Bounded CI and fixture roots repaired and verified by the complete local CI pipeline.
    requirement: CI-06
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' HEX_HOME=/private/tmp/lockspire-hex-cache mix ci; final log /private/tmp/lockspire-140-08-ci-final.RVOcF5"
        status: pass
    human_judgment: false
  - id: D3
    description: Current candidate failure dispositions reconciled in the authoritative Phase 140 record.
    requirement: LOOSE-03
    verification:
      - kind: other
        ref: ".planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md; git diff --check"
        status: pass
    human_judgment: false
duration: 4h
completed: 2026-10-01
status: complete
---

# Phase 140 Plan 08: Local CI Failure Census Summary

**All 45 intermediate local CI failures were assigned exact source identities and reconciled to a final clean run of 1,440 tests plus 102 integration tests.**

## Performance

- **Duration:** About 4 hours from the first plan commit through final census reconciliation; execution began earlier.
- **Started:** 2026-09-30T20:31:35-04:00 (first verifiable plan commit)
- **Completed:** 2026-10-01T00:30:25-04:00
- **Tasks:** 2
- **Files modified:** 20 across Plan 140-08 and the exact-scope gap plans it required.

## Accomplishments

- Captured a complete intermediate failure run, enumerating all 45 failed ExUnit identities and source locations in `140-CI-FAILURES.md`.
- Repaired the bounded ReleaseAutomation current-state and JAR fixture identity assertions; routed out-of-scope roots into completed 140-10, 140-11, and 140-12 plans.
- Re-ran full local CI on candidate `93e85d11cbb491d619e391acabec2641b14ae015`: 1,440 tests, 0 failures, 6 skipped; then 102 integration tests, 0 failures.
- Reconciled the two initial formatter findings, all intermediate test failures, and non-ExUnit cache/fetch diagnostics in the disposition register.

## Task Commits

1. **Task 1: Capture the complete local CI failure set and assign exact roots** — `e974a097` (initial complete formatter-gate census; final 45-test census was committed with Task 2).
2. **Task 2: Repair bounded roots and prove a clean full local CI run** — `00c280ca` (TDD regression assertion), `562adeea` (active Phase 140 truth), `0cfc65eb` (unique JAR test client), `31bd9df8` (final complete census and disposition).

The required outside-scope repairs were completed in separate plans: 140-10 (`134951a7`, `79ecea2e`, `ba5e5432`, `8ecbca7b`), 140-11 (`2b6696d0`, `a8d5ba3e`, `54293d1d`, `eab70732`), and 140-12 (`e7823657`, `02a3ecc8`, `550d5ad4`, `93e85d11`). These scoped commits are included in the measured 17-commit actuals.

## Files Created/Modified

- `140-CI-FAILURES.md` — Full 45-identity census, source roots, focused evidence, final CI receipt, and non-ExUnit diagnostic reconciliation.
- `140-DISPOSITIONS.md` — Terminal dispositions for formatter findings, intermediate test failures, and the non-blocking audit diagnostics.
- `test/support/lockspire/release_proof/workflow_assertions.ex` — Asserts current Phase 140 execution truth while retaining historical release assertions.
- `test/lockspire/protocol/authorization_request_test.exs` — Gives request-object cases unique client fixture identities without weakening uniqueness behavior.
- Other listed test and release-proof fixture files — Per-test sandbox ownership, exact release-proof history, and normal formatted source, closed through their scoped gap plans.

## Decisions Made

- Kept the complete raw logs in private temporary storage at mode `0600`; the durable census excludes token/assertion payloads.
- Kept non-blocking Hex cache and `.git/FETCH_HEAD` diagnostics explicit, with a trigger to investigate if a later audit gate cannot report its result.
- Preserved test and product constraints; fixes isolate fixture ownership or align contract fixtures with repository truth.

## Deviations from Plan

None — plan executed as written. The plan explicitly required separate exact-scope gap plans for reproducible roots outside its `files_modified` list; Plans 140-10, 140-11, and 140-12 were completed before final acceptance.

**Total deviations:** 0 auto-fixed. **Impact:** No scope was silently widened; exact-scope prerequisite repairs were closed before the full CI rerun.

## Issues Encountered

- A focused release-proof selector run under `umask 077` could not read mode-sensitive temporary receipts. Re-running with the normal process umask passed; no test process umask was changed.
- The local Mix test database needed recreation after prior fixture contamination. Only the explicitly configured `lockspire_test` database was dropped, recreated, and migrated.
- The final run logged a Hex cache `:badfile` and a `.git/FETCH_HEAD` permission diagnostic, followed by successful audit summaries and all remaining CI gates.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The local CI candidate and exact intermediate failure census are ready for the orchestrator's phase-level acceptance and worktree merge.
- The diagnostics remain visible with an explicit investigation trigger if a future dependency-audit result is unavailable.
- `STATE.md` and `ROADMAP.md` were not modified; their updates belong to the orchestrator after merge.

## Self-Check

PASSED — summary, census, and disposition files exist; required task commits are present; all 45 census rows reconcile; `git diff --check` passes.

---
*Phase: 140-bounded-operational-loose-end-triage*
*Completed: 2026-10-01*
