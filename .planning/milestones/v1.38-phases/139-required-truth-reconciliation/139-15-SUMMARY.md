---
phase: 139-required-truth-reconciliation
plan: "15"
subsystem: testing
tags: [planning, release-hygiene, github-actions, node-test, mix-ci]

requires:
  - phase: 139-required-truth-reconciliation
    provides: "Plan 139-16 historical fixture identities and Phase 140 boundary records."
provides:
  - "Historical Phase 140/141 completion and Phase 139 gap-plan cardinality are checked without pinning a stale global phase pointer."
  - "The CI contract protects the combined portable router/lifecycle command and immutable action pins."
affects: [phase-139-verification, milestone-audit]
actuals:
  tokens: 1700
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns:
    - "Keep public package truth separate from Release Please metadata and current phase position."
    - "Build simulated historical commits from the exact pinned historical source."
key-files:
  created: []
  modified:
    - test/lockspire/quality/phase_139_planning_consistency_test.exs
    - test/lockspire/workflow_supply_chain_contract_test.exs
    - test/support/lockspire/release_proof/workflow_assertions.ex
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Assert latest public package 1.5.0 independently from Release Please metadata 1.5.1."
  - "Keep the release-lineage fixture bound to its recorded historical commit."
requirements-completed: [QUAL-05, TRUTH-03, TRUTH-05, HYGIENE-06]
coverage:
  - id: D1
    description: "Phase 139 planning checks retain historical Phase 140/141 completion and validate gap-plan summary rules."
    requirement: TRUTH-03
    verification:
      - kind: unit
        ref: "test/lockspire/quality/phase_139_planning_consistency_test.exs#maintained Phase 139 records expose one lifecycle posture across gap closure and historical completion"
        status: pass
      - kind: unit
        ref: "test/lockspire/quality/phase_139_planning_consistency_test.exs#all completed-plan prohibitions have tracked executable owners"
        status: pass
    human_judgment: false
  - id: D2
    description: "The recurring local and CI contracts protect release truth, exact-SHA hygiene, and the combined portable router/lifecycle test command."
    requirement: QUAL-05
    verification:
      - kind: unit
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs test/lockspire/quality/phase_139_planning_consistency_test.exs test/lockspire/workflow_supply_chain_contract_test.exs --only phase139_gap_closure"
        status: pass
      - kind: integration
        ref: "LOCKSPIRE_SKIP_BEAM_INTEGRATION=1 LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs"
        status: pass
      - kind: integration
        ref: "HEX_HOME=/private/tmp/lockspire-gsd-ci-hex ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix ci"
        status: pass
    human_judgment: false
  - id: D3
    description: "Release assertions and the synthetic merged-lineage fixture remain valid as current planning and release records advance."
    requirement: TRUTH-05
    verification:
      - kind: unit
        ref: "test/lockspire/release/release_automation_contract_test.exs"
        status: pass
      - kind: unit
        ref: "test/lockspire/release/repository_hygiene_contract_test.exs#phase 139 accepts the sealed candidate while local main lags and the merged release branch is deleted"
        status: pass
    human_judgment: false

duration: "325min"
completed: 2026-10-06
status: complete
---

# Phase 139 Plan 15: Planning and CI contracts follow the retained baseline

**Planning, release, and portable CI checks now reflect the active Phase 139 gap closure while preserving Phase 140/141 and public-release history.**

## Performance

- **Duration:** About 5 hours 25 minutes across the resumed work and full CI reruns.
- **Started:** 2026-10-06T02:11:22Z (saved Plan 139-16 handoff; Plan 139-15 resumed immediately afterward).
- **Completed:** 2026-10-06 09:07:29 UTC.
- **Tasks:** 2 planned tasks.
- **Files modified:** 4.

## Accomplishments

- Updated planning consistency checks to preserve Phase 140/141 historical completion, require the original 13 Phase 139 plan-summary pairs and 19 prohibition owners, and allow only explicitly marked gap plans to await summaries.
- Protected the exact combined portable router/lifecycle command and retained the full-SHA action-pin scan.
- Kept public package 1.5.0 separate from unpublished Release Please metadata 1.5.1.
- Made the synthetic merged-release fixture read its helper file from the pinned historical commit rather than the mutable current checkout.

## Task Commits

1. **Task 1: Check historical Phase 141 closure and pending gap-plan cardinality** — `6f538ba1`
2. **Task 2: Protect the combined CI router/lifecycle command and run local gates** — `f3de94ca`
3. **Verification-driven test repairs** — `859e6b5d`

## Files Created/Modified

- `test/lockspire/quality/phase_139_planning_consistency_test.exs` — historical baseline, plan cardinality, and prohibition-owner checks.
- `test/lockspire/workflow_supply_chain_contract_test.exs` — combined portable CI command and immutable-action checks.
- `test/support/lockspire/release_proof/workflow_assertions.ex` — release truth checks follow the public package and metadata independently of phase position.
- `test/support/lockspire/release_proof/package_assertions.ex` — historical lineage fixture uses the pinned source commit.

## Decisions Made

- Kept release assertions focused on release truth instead of a fixed active phase number.
- Kept synthetic historical records tied to their exact recorded source.

## Deviations from Plan

1. The prohibition-owner test checks that each documented owner label appears in its executable test file. Updated the planning test name to retain the exact existing label.
2. Full CI exposed stale release assertions tied to an earlier Phase 140 pointer and the old release-train field. Updated the contract to assert public package 1.5.0 separately from Release Please metadata 1.5.1.
3. A full-suite rerun showed that a synthetic historical PR copied the current helper file. Changed it to read the helper from the exact historical lineage commit, keeping the fixture stable when current assertions change.

**Total deviations:** 3, all limited to test contracts and fixture inputs.
**Impact on plan:** These repairs were required for the documented checks to pass; no runtime, protocol, workflow, or release metadata changed.

## Issues Encountered

- The first `mix ci` attempt could not write Hex cache files under `/Users/jon/.hex`. Reruns used the writable temp cache at `/private/tmp/lockspire-gsd-ci-hex`.
- The hygiene/package checks printed a non-blocking `.git/FETCH_HEAD` permission message. The completed local CI alias exited successfully.
- Final full local CI result: 1,447 tests passed with 0 failures (6 skipped), followed by 102 integration tests with 0 failures.

## User Setup Required

None.

## Next Phase Readiness

All 16 Phase 139 plans now have summaries. Phase 139 remains in progress until its verifier passes. Next: run the unfiltered `$gsd-execute-phase 139` to refresh Phase 139 verification; no manual UAT is needed for the automated properties proven above.

---
*Phase: 139-required-truth-reconciliation*
*Completed: 2026-10-06*
