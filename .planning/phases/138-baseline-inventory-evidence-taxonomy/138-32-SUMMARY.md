---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "32"
subsystem: release-maintenance
tags: [lifecycle-finalizer, immutable-ledger, host-receipt, recovery, tdd]
requires:
  - phase: 138-31
    provides: Conservative credential redaction across every evidence and diagnostic sink.
provides:
  - A pre-verifier relation binding the fixed ledger publication to exact review bytes and recorded worktree state.
  - A post-transition relation binding authorization to GSD's mode-0600 pending receipt, writer descriptors, transformation digest, hook envelope, and current bytes.
  - A two-mode finalizer that publishes once before verification and performs validation only after transition.
affects: [138-33, phase-139, execute-phase, repository-reconciliation]
actuals:
  tokens: 18400
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [pre-verifier-publication, host-receipt-attestation, validation-only-recovery, double-observation]
key-files:
  created:
    - scripts/maintainer/finalize_phase_138_inventory.sh
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-32-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
key-decisions:
  - "Trust post-transition state only when the host-emitted writer, transformation, hooks, before/after identities, current worktree digest, and lifecycle semantics all agree."
  - "Keep failed post-transition validation read-only so GSD retains the pending receipt for same-phase recovery."
patterns-established:
  - "Two-boundary proof: publish a current ledger before verification, then authorize later bookkeeping through the host's sealed transaction rather than recollection."
  - "Single writer: pre-verify owns publication; post-transition can only validate."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: "The fixed pre-verifier publication is a one-parent, one-path ledger commit bound to a valid phase review receipt and exact recorded worktree projection."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_preverify_relation_gap"
        status: pass
      - kind: other
        ref: "gsd-tools check tdd-red-evidence /tmp/lockspire-138-32-task1-red.json --raw"
        status: pass
    human_judgment: false
  - id: D2
    description: "The post-transition relation rejects forged receipts, writer descriptors, transformation digests, allowed-path order, hook hashes, phases, statuses, and extra dirt."
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_posttransition_relation_gap"
        status: pass
    human_judgment: false
  - id: D3
    description: "Two independent complete pre-verify observations must agree before the finalizer stages and commits only the canonical ledger."
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_finalizer_gap"
        status: pass
      - kind: other
        ref: "gsd-tools check tdd-red-evidence /tmp/lockspire-138-32-task2-red.json --raw"
        status: pass
    human_judgment: false
  - id: D4
    description: "Post-transition failure preserves the exact host pending receipt and a later validation-only retry succeeds without another commit."
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_finalizer_recovery_gap"
        status: pass
    human_judgment: false
  - id: D5
    description: "Review provenance and receipt diagnostics remain bounded and credential-redacted while maintained evidence stays proposal-only."
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_redaction_gap"
        status: pass
    human_judgment: false
duration: 20 min
completed: 2026-09-11
status: complete
---

# Phase 138 Plan 32: Lifecycle-Bound Inventory Publication Summary

**One canonical inventory can now be published at the truthful pre-verifier boundary and remain authoritative through only the exact GSD-sealed completion transition.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-11T15:34:36Z
- **Completed:** 2026-09-11T15:54:23Z
- **Tasks:** 2
- **Files modified:** 5 implementation/test/evidence files plus this summary

## Accomplishments

- Added explicit pre-verifier and post-transition relation modes without broadening the legacy snapshot relation.
- Bound valid review bytes into every new full ledger and rejected missing, malformed, changed, or symlinked review evidence.
- Revalidated GSD's pending receipt from the absolute Git common directory, including exact writer artifacts, ordered allowed paths, transformation digest, hooks, before/after identities, and current worktree bytes.
- Added a two-mode finalizer with double observation, ledger-only publication, idempotent retry, and validation-only pending recovery.
- Proved the closeout forgery and credential-redaction matrices remain intact.

## Task Commits

Each task used a RED-to-GREEN sequence:

1. **Task 1: Prove one ledger stays current across both lifecycle boundaries**
   - `eccf9543` — RED lifecycle-boundary contracts
   - `37f9b5c5` — pre-verifier and host-receipt relation implementation
2. **Task 2: Implement pre-verify publication and post-transition validation-only modes**
   - `ece33375` — RED finalizer and recovery contracts
   - `4a22cecc` — two-mode finalizer implementation
   - `42d1a08f` — non-main primary-branch normalization and refreshed non-authoritative candidate

**Plan metadata:** final plan metadata commit

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — Adds review provenance, two explicit lifecycle relation modes, receipt validation, and primary-branch normalization.
- `scripts/maintainer/finalize_phase_138_inventory.sh` — Implements strict pre-verify publication and post-transition validation-only commands.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — Adds focused boundary, finalizer, and recovery selectors.
- `test/support/lockspire/release_proof/package_assertions.ex` — Adds real-repository positive, forgery, idempotence, and pending-retry fixtures.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — Holds the latest candidate bytes; Plan 33's installed execute:post hook performs the sole authoritative fixed-subject publication.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-32-SUMMARY.md` — Records implementation, verification, deviations, and traceability.

## Decisions Made

- The host receipt is authority only as a complete attestation: live hashes cannot substitute for a missing or forged begin-time writer or seal-time transformation record.
- Post-transition never removes the host receipt, stages files, commits, amends, repairs, or recollects; GSD alone owns receipt completion and retry routing.
- A pre-existing dirty Phase 138 verification report is authorized only when the exact porcelain-v2 projection was already captured in the immutable ledger; no other dirty path is admitted.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized the actual primary branch after ledger publication**

- **Found during:** Task 2 live double-observation exercise.
- **Issue:** Git receipt revalidation normalized `main` but not a different checked-out primary branch, so the ledger commit's own branch advance appeared as external topology drift.
- **Fix:** Resolve the exact symbolic branch and normalize its ledger-descendant tip only when it is also an ancestor of the requested relation HEAD.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`
- **Verification:** The complete six-selector Plan 32 gate passed after the correction.
- **Committed in:** `42d1a08f`

**2. [Rule 1 - Bug] Kept the early live candidate non-authoritative**

- **Found during:** Task 2 live double-observation exercise.
- **Issue:** The first live candidate correctly failed closed before Plan 33 had installed the execute:post hook.
- **Fix:** Relabeled the just-created tip as a normal Plan 32 correction and retained no fixed-subject authoritative publication; Plan 33's fresh execute:post hook remains the single publication boundary.
- **Files modified:** canonical ledger and relation implementation
- **Verification:** Git history contains no `docs(phase-138): publish pre-verification baseline inventory` commit after the correction.
- **Committed in:** `42d1a08f`

**Total deviations:** 2 auto-fixed lifecycle bugs.
**Impact on plan:** The changes preserve the planned single authoritative publication and make non-main primary checkouts truthful.

## Issues Encountered

- Independent candidate comparison required normalizing the provenance window and snapshot-boundary timestamps in addition to their frontmatter fields; no source timestamps are normalized.
- The live exercise demonstrated why the fixed publication must occur only after Plan 33 installs the capability and execute-phase freshly renders execute:post.

## User Setup Required

None - Plan 33 installs the project-scoped capability through GSD's supported consented lifecycle.

## Evidence

- Both TDD records returned `RED_EVIDENCE_OK` for their intended missing production behavior.
- The final Plan 32 command completed with 6 tests, 0 failures, and 31 excluded tests in 124.6 seconds.
- Both Bash scripts pass `bash -n`.
- Receipt-forgery, same-cardinality closeout, and credential-redaction adversarial matrices all remained fail-closed.
- Post-transition recovery leaves the mode-0600 pending receipt byte-for-byte unchanged.

## Next Phase Readiness

- Plan 138-33 can install the tracked capability, prove fresh hook discovery and durable recovery, and trigger the sole authoritative pre-verifier publication.
- The ordinary verifier will then observe the fixed-subject ledger commit at the actual relation HEAD.

## Self-Check: PASSED

- All five scoped task commits exist after the recorded pre-plan HEAD.
- Every declared source, test, finalizer, ledger, and summary file exists.
- The exact plan-level verification command passed after the last relation correction.
- No private receipt, provisional verification state, second authoritative publication, or product API was introduced.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-11*
