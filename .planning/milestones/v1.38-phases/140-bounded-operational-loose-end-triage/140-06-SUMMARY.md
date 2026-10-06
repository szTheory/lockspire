---
phase: 140-bounded-operational-loose-end-triage
plan: "06"
subsystem: release-testing
tags: [phase-140, recovery, finalizer, receipt-lineage]
requires:
  - phase: 140-05
    provides: bounded operational inventory and recovery-v2 baseline
provides:
  - Exact Phase 140 recovery selector diagnostics with their fixture prerequisites repaired
  - Defined archived transformation path validation for recovery-v2 receipts
  - Regression coverage for valid v2 lineage and tampered archive or overlay rejection
affects: [phase-140, phase-139-acceptance, release-proof]
actuals:
  tokens: 1974
  tasks: 2
  commits: 2
  plan_head_before: a3e96e7203081d2e757fabbf46ba6a9f17159078
tech-stack:
  added: []
  patterns:
    - "Validate archived receipt paths against an explicit expected list before per-record checks."
key-files:
  created:
    - .planning/phases/140-bounded-operational-loose-end-triage/140-06-SUMMARY.md
  modified:
    - test/support/lockspire/release_proof/package_assertions.ex
    - scripts/maintainer/finalize_phase_139_acceptance.sh
    - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs
key-decisions:
  - "Keep the v2 predecessor allowedPaths contract as a local immutable expected list, separate from the later per-record predicate."
requirements-completed: [BASE-03, LOOSE-03]
coverage:
  - id: D1
    description: "The two Phase 140 recovery selectors reach their intended exact diagnostics with valid fixture topology."
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase140_recovery_relation"
        status: pass
    human_judgment: false
  - id: D2
    description: "The acceptance resolver accepts valid v2 lineage and rejects archived-path tampering and overlay drift before publication."
    verification:
      - kind: integration
        ref: "LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs"
        status: pass
      - kind: other
        ref: "bash -n scripts/maintainer/finalize_phase_139_acceptance.sh"
        status: pass
    human_judgment: true
    rationale: "The fixture directly executes the embedded resolver and checks the no-publish barrier contract, but its intentionally incomplete Phase 139 lifecycle chain prevents running the full post-transition entry point through that barrier."
duration: 38 min
completed: 2026-09-30
status: complete
---

# Phase 140 Plan 06: Recovery Diagnostics and Receipt Lineage Summary

**Phase 140 recovery selectors now reach their exact diagnostics, and archived v2 receipts are validated against a defined allowed-path list.**

## Performance

- **Duration:** 38 min
- **Started:** 2026-09-30T22:08:00Z
- **Completed:** 2026-09-30T22:46:23Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Repaired historical fixture inputs so both recovery selectors reach and assert their intended diagnostic boundaries.
- Fixed the recovery-v2 archived receipt validator to compare `allowedPaths` against an explicit expected list instead of an unbound loop variable.
- Extended lifecycle coverage for valid v2 resolution, archived-path tampering, overlay drift, and ref stability.

## Task Commits

1. **Task 1: Restore the two specific Phase 140 recovery diagnostics** - `bfc21d32` (test)
2. **Task 2: Authenticate valid recovery-v2 lineage before the publication stop** - `30068cf1` (fix)

**Plan metadata:** pending summary commit.

## Files Created/Modified

- `test/support/lockspire/release_proof/package_assertions.ex` - Sources the intended historical fixture contents for the entry-repair and preparation-prefix cases.
- `scripts/maintainer/finalize_phase_139_acceptance.sh` - Defines and uses the archived transition's expected path list.
- `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` - Exercises valid v2 resolution and tamper rejection.

## Decisions Made

- Kept the expected archived transformation paths separate from the per-record worktree allowlist.

## Deviations from Plan

The lifecycle fixture intentionally lacks the complete accepted Phase 139 chain, so the full `finalize_phase_139_acceptance.sh post-transition --phase 139` entry point stops in its earlier baseline relation gate. The test executes the exact embedded `resolve_sealed_candidate` implementation against valid v2 and hostile receipts, verifies the no-publish barrier remains present, and confirms refs do not move. It does not claim an end-to-end entry-point run through that barrier.

**Total deviations:** 1 verification limitation (fixture lifecycle chain).
**Impact:** The reported Python name error and the valid/malformed resolver paths are directly covered; end-to-end no-publish sequencing remains unverified by this Node fixture.

## Issues Encountered

- The Node lifecycle suite expects the tracked host-contract fixture in this worktree. It passed when run with `LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json`.
- The v2 fixture does not contain the accepted Phase 139 lifecycle commit chain required by the full finalizer entry point; no test-only bypass was added.
- `requirements.ready-ids` returned 0 of 2 IDs ready because sibling plans still declare them; REQUIREMENTS.md was left unchanged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 140-06 implementation and focused checks are complete.
- End-to-end no-publish entry-point coverage can be added when a valid accepted Phase 139 lifecycle fixture is available.

## Self-Check: PASSED

- Task commits `bfc21d32` and `30068cf1` exist.
- All three modified implementation/test files exist.
- Focused recovery selectors, the full repository-hygiene contract file, shell syntax check, and Node lifecycle suite passed.

---
*Phase: 140-bounded-operational-loose-end-triage*
*Completed: 2026-09-30*
