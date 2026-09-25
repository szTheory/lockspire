---
phase: 139-required-truth-reconciliation
plan: "06"
subsystem: post-transition-acceptance
tags: [git, github-actions, exact-sha, release-evidence, lifecycle-receipt, tdd]

requires:
  - phase: 139-required-truth-reconciliation
    plan: "01"
    provides: Exact-SHA CI, Release no-publish, hygiene, WARN, and supplemental OIDF receipt schema
  - phase: 139-required-truth-reconciliation
    plan: "05"
    provides: Host-sealed Phase 139 transition and synchronized-main inventory relation
provides:
  - Strict post-transition command that lands only the host-sealed candidate by compare-and-swap fast-forward
  - Exact post-landing acceptance joined across local gate, hygiene, CI, Release no-publish, inventory, and shipped history
  - Atomic mode-0600 acceptance receipt under the Git common directory with safe idempotent retry
affects: [139-07, phase-140, phase-141]

actuals:
  tokens: 10380
  tasks: 2
  commits: 5
plan_head_before: b60d924df4ee1331f737abcc42a4114d70f99ecf

tech-stack:
  added: []
  patterns: [sealed-candidate compare-and-swap, exact-SHA evidence join, safe external receipt, hermetic fake remote and API]

key-files:
  created:
    - scripts/maintainer/finalize_phase_139_acceptance.sh
  modified:
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex

key-decisions:
  - "Final main authority comes only from the pending host-sealed candidate, two ancestor proofs, a compare-and-swap local update, and a normal non-force exact-ref push followed by re-fetch."
  - "The durable acceptance receipt joins current exact-SHA proof with separately corroborated immutable 1.5.0 history, while supplemental OIDF remains explicitly non-certifying."

patterns-established:
  - "The finalizer exposes exactly post-transition --phase 139 and rejects linked worktrees, unexpected transition paths, stale receipts, non-fast-forward refs, races, and unsafe receipt targets."
  - "Long-running live checks are followed by a fresh receipt, relation, HEAD, local-main, and origin-main observation before any external receipt is written."

requirements-completed: [CI-06, CI-07, CI-08, QUAL-05, HYGIENE-05, TRUTH-04]

coverage:
  - id: D1
    description: The sealed Phase 139 candidate is the only commit permitted to advance local and origin main, and every failure keeps the host receipt pending for retry.
    requirement: TRUTH-04
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs#sealed candidate advances main through one exact fast-forward"
        status: pass
    human_judgment: false
  - id: D2
    description: Current local, hygiene, required CI, and Release no-publish truth is bound to the synchronized candidate in one allowlisted receipt.
    requirement: CI-06
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs#sealed candidate records exact live acceptance outside the worktree"
        status: pass
    human_judgment: false
  - id: D3
    description: Shipped 1.5.0 source, run, tag, version, and checksum history is independently corroborated without publication or workflow dispatch.
    requirement: CI-08
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs#sealed candidate records exact live acceptance outside the worktree"
        status: pass
    human_judgment: false

duration: 13 min
completed: 2026-09-11
status: complete
---

# Phase 139 Plan 06: Sealed Post-Transition Acceptance Summary

**A single guarded command now advances only the host-sealed Phase 139 candidate to synchronized main, revalidates every required current and historical evidence join, and writes one private external acceptance receipt.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-09-12T00:15:11Z
- **Completed:** 2026-09-12T00:28:04Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added a closed `post-transition --phase 139` maintainer command that requires the primary checkout, validates the sealed host receipt and exact transition bytes, acquires a Git-common-dir lock, and allows only ancestry-proven compare-and-swap movement.
- Advanced local main and origin main using an exact non-force refspec, then re-fetched and required HEAD/local-main/origin-main equality before invoking the Phase 139 posttransition inventory relation.
- Reused the Plan 139-01 exact-SHA hygiene receipt to require the local gate, zero-block hygiene, canonical CI graph, Release push/no-publish graph, WARN dispositions, and supplemental non-certifying OIDF classification.
- Corroborated the immutable Lockspire 1.5.0 source, CI run, protected Release run, tag, public version, and checksum against maintained prose plus read-only GitHub and Hex evidence.
- Persisted only allowlisted fields in an atomic mode-0600 receipt under the resolved Git common directory, preserving a valid same-SHA receipt byte-for-byte on retry.

## Task Commits

1. **Task 1: Land the host-sealed Phase 139 candidate through an exact fast-forward**
   - `d7db228c` — `test(139-06): specify sealed main acceptance`
   - `d4e06c17` — `feat(139-06): land sealed candidate on main`
2. **Task 2: Join live and historical evidence into one durable receipt**
   - `d774a71e` — `test(139-06): specify live acceptance receipt`
   - `85b38f80` — `feat(139-06): seal exact acceptance evidence`
3. **Proof hardening**
   - `67889878` — `test(139-06): cover linked checkout rejection`

## Files Created/Modified

- `scripts/maintainer/finalize_phase_139_acceptance.sh` — Implements the sealed-candidate resolver, guarded main fast-forward, posttransition relation, bounded exact acceptance, historical release corroboration, final race rechecks, and safe receipt publication.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — Adds focused entry points for main landing and durable acceptance receipt behavior.
- `test/support/lockspire/release_proof/package_assertions.ex` — Exercises real isolated repositories and bare remotes plus fake hygiene, GitHub, and Hex endpoints across success, retry, rejection, stale/dirty state, non-fast-forward movement, races, linked worktrees, lock contention, unsafe targets, and historical mismatches.

## Evidence

- `bash -n scripts/maintainer/finalize_phase_139_acceptance.sh` passed.
- Both focused acceptance tags passed together: 2 tests, 0 failures.
- The semantic phase-label proof and repository workflow/shell lint passed.
- `git diff --check` passed.
- All Git pushes in tests targeted throwaway local bare remotes; all API and Hex evidence was served by fixture commands.
- No live main push, workflow dispatch, package publication, tag creation, or live acceptance receipt was performed.

## TDD Gate Compliance

- Task 1 RED intentionally failed `sealed candidate advances main through one exact fast-forward`; `tdd-red-evidence` returned `RED_EVIDENCE_OK` before the finalizer existed.
- Task 1 GREEN passed the real-repository fast-forward, retry, failure, receipt preservation, and lock cleanup fixture.
- Task 2 RED intentionally failed `sealed candidate records exact live acceptance outside the worktree`; `tdd-red-evidence` returned `RED_EVIDENCE_OK` before live evidence handling was added.
- Task 2 GREEN passed the combined current/historical evidence fixture and the exact external-receipt contract.
- No separate REFACTOR commit was needed; the proof-only hardening commit added the plan-required linked-worktree coverage after GREEN.

## Decisions Made

- The host receipt is candidate authority; caller-provided SHA input is not accepted.
- Local main moves through `git update-ref` compare-and-swap, while origin main moves through an ordinary exact-ref push that naturally rejects non-fast-forward races.
- Current Phase 139 workflow truth and immutable shipped 1.5.0 history remain separate evidence classes inside the final receipt.
- Existing same-candidate receipts must be fully valid and are preserved rather than rewritten, making retries idempotent and auditable.

## Assumption Delta

`no-change` — Plan 139-01's receipt shape, Plan 139-05's sealed host relation, and the shipped 1.5.0 constants supplied all required authority. The command and tests are ready, but the real main landing and live acceptance remain exclusively owned by Plan 139-07's `execute:complete:post` lifecycle.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Proof] Added explicit linked-worktree rejection coverage**
- **Found during:** Overall verification
- **Issue:** The implementation rejected linked worktrees, but the first GREEN fixture asserted the guard only through source structure rather than executing it in a real linked checkout.
- **Fix:** Added a real linked-worktree fixture and pinned signal-driven lock cleanup in the source contract.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Commit:** `67889878`

## Issues Encountered

- The initial Task 1 fixture compared the complete ref snapshot before and after a deliberately authorized main advance. The assertion was corrected during GREEN to hold index, status, worktrees, ledger, and receipt bytes constant while checking the intended ref pair separately.

## Known Stubs

None. No product stub, skipped test, placeholder, incomplete evidence path, or deferred implementation was introduced. Existing TODO strings in the assertion module are intentional hostile fixture inputs for maintained-source classification tests.

## Threat Flags

None beyond the plan threat model. The new ref, network-evidence, and Git-common-dir surfaces implement T-139-25 through T-139-31 with fail-closed checks and hermetic adversarial coverage; no product endpoint, authentication path, schema, or publication capability was added.

## User Setup Required

None.

## Next Phase Readiness

- Plan 139-07 can install this command as the blocking `execute:complete:post` finalizer after the host seals the transition.
- The host pending receipt remains the recovery authority until Plan 139-07 runs the real command and completes the lifecycle.
- Phase 141 can consume the durable Git-common-dir acceptance receipt without requiring a tracked post-acceptance commit.

## Self-Check: PASSED

- The finalizer, both proof files, and this summary exist.
- Task commits `d7db228c`, `d4e06c17`, `d774a71e`, `85b38f80`, and `67889878` resolve in repository history.
- The persisted plan ledger measures five pre-summary commits from `b60d924df4ee1331f737abcc42a4114d70f99ecf` through the task HEAD.
- Fresh combined acceptance verification, semantic phase-label proof, workflow/shell lint, shell syntax, stub scan, and `git diff --check` passed.

---
*Phase: 139-required-truth-reconciliation*
*Completed: 2026-09-11*
