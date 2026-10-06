---
phase: 139-required-truth-reconciliation
plan: "09"
subsystem: testing
tags: [codex-gsd, lifecycle, ci, exact-sha, git-receipts]
requires:
  - phase: 139-required-truth-reconciliation
    provides: Phase 139 gap map and exact-SHA proofs from Plans 139-01 through 139-08
provides:
  - Portable and live-runtime lifecycle coverage for the supported Phase 139 GSD gates
  - Required CI coverage for the portable finalizer lifecycle contract
  - Exact Git topology normalization for authorized origin/main movement and its symbolic origin/HEAD alias
affects: [verification, release-hygiene, gsd-lifecycle]
actuals:
  duration: 49min
  tasks: 2
  commits: 4
  plan_head_before: 03c118c50ba5135681aab98bdd41d4cb46701eac
tech-stack:
  added: []
  patterns: [portable/live contract parity, blocking lifecycle gates, immutable receipt normalization]
key-files:
  created:
    - tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json
  modified:
    - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs
    - .github/workflows/ci.yml
    - test/lockspire/workflow_supply_chain_contract_test.exs
    - .planning/phases/139-required-truth-reconciliation/139-VALIDATION.md
    - scripts/maintainer/baseline_inventory.sh
key-decisions:
  - "Keep portable CI input bounded and non-authoritative; live mode compares the same contract with installed Codex GSD files and rendered hooks."
  - "Normalize origin/HEAD only when Git proves it is a symbolic alias of origin/main and origin/main is within the authorized lifecycle chain."
  - "Keep G-139-01 and G-139-09 pending until the supported live post-transition flow writes a valid receipt for synchronized main and exact external evidence."
metrics:
  duration: 49min
  completed: 2026-09-24
  status: complete
requirements-completed: []
coverage:
  - id: D1
    description: Portable lifecycle, production-router cancellation, final landing, and durable-receipt failure matrix.
    requirement: CI-06
    verification:
      - kind: integration
        ref: "LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs — 16 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "GSD_TOOLS=/Users/jon/.codex/gsd-core/bin/gsd-tools.cjs node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs — 16 tests, 0 failures with installed-runtime parity"
        status: pass
    human_judgment: false
  - id: D2
    description: Protected CI job contains the portable lifecycle command once and in the required order.
    requirement: HYGIENE-06
    verification:
      - kind: unit
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/lockspire/workflow_supply_chain_contract_test.exs — 4 tests, 0 failures"
        status: pass
      - kind: other
        ref: "bash scripts/ci/lint_workflows.sh — passed"
        status: pass
    human_judgment: false
  - id: D3
    description: Final acceptance fixture tolerates only the authorized origin/main fast-forward and matching symbolic origin/HEAD alias.
    verification:
      - kind: unit
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase139_final_acceptance --only phase139_acceptance_receipt — 2 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D4
    description: Synchronized production main, exact external CI and no-publish Release evidence, and durable live acceptance receipt.
    requirement: CI-07
    verification:
      - kind: other
        ref: "Still pending: supported live post-transition acceptance must synchronize main, validate canonical same-SHA CI and Release evidence, and retain the mode-0600 Git-common-dir receipt."
        status: unknown
    human_judgment: true
    rationale: "This is the actual external release-evidence boundary. Fixture tests cannot certify production GitHub refs, exact-run evidence, or create the repository's durable live receipt; the supported blocking GSD lifecycle must perform and verify it."
---

# Phase 139 Plan 09: Portable and Live Finalizer Lifecycle Summary

**The supported Phase 139 finalizer now has portable CI coverage and live Codex GSD parity checks, with authorized main movement represented precisely in the immutable Git receipt.**

## Performance

- **Duration:** 49 min
- **Started:** 2026-09-24T02:44:00Z
- **Completed:** 2026-09-24T03:33:00Z
- **Tasks:** 2
- **Files modified:** 6 planned artifacts plus one required Git-topology fix

## Accomplishments

- Added a tracked bounded host-contract fixture for `execute:post` and blocking `plan:pre`, and exercised portable lifecycle behavior without installing GSD.
- Added the lifecycle contract to the protected Release Hygiene Drift CI job and pinned its identity, permissions, command uniqueness, and order with ExUnit.
- Preserved live parity checks against installed Codex GSD capability files, rendered hooks, and workflow descriptors.
- Fixed final acceptance against real Git's symbolic `origin/HEAD` movement: it is normalized only when it aliases `origin/main` and that ref is within the exact authorized lifecycle chain.
- Updated the validation map with portable, live, CI, and exact-receipt boundaries. G-139-01 and G-139-09 remain `PENDING_EXTERNAL` until the actual supported lifecycle writes the synchronized live receipt.

## Evidence

- Portable router and lifecycle Node suite — 16 tests, 0 failures.
- Live Codex GSD router and lifecycle parity suite — 16 tests, 0 failures.
- Workflow source ExUnit contract — 4 tests, 0 failures.
- Phase 138 finalizer regression selectors — 2 tests, 0 failures.
- Phase 139 final acceptance and receipt selectors — 2 tests, 0 failures.
- Workflow lint — passed.
- GSD API coverage pre-check — passed; `COVERAGE.md` declares no external API integration.
- The supported production post-transition receipt was not produced in this plan; the phase remains subject to canonical verification and external exact-SHA acceptance.

## Task Commits

1. **Task 1: Prove one supported Phase 139 lifecycle from preverify to durable receipt** — `bd652415` (portable contract foundation).
2. **Task 2: Add the portable lifecycle contract to required CI and seal the gap audit** — `bebe366e`.
3. **Regex capture correction for workflow source contract** — `71d36406`.
4. **Authorized `origin/HEAD` alias normalization for exact main movement** — `32df92a5`.

## Decisions Made

- Kept fixture mode test-only; it cannot install or authorize runtime behavior.
- Kept CI-06 and CI-07 production receipt truth pending until the supported finalizer authenticates the synchronized exact SHA and writes the durable receipt.
- Retained Phase 139's historical `gaps_found` verification report; the next GSD action must perform fresh canonical verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test defect] Corrected nested Regex.scan captures in the workflow source contract**
- **Found during:** Task 2 verification
- **Issue:** `Regex.scan/3` with capture mode returns nested capture lists, while the assertions matched a flat list.
- **Fix:** Bind the inner capture list for both the release-hygiene job and named step extraction.
- **Files modified:** `test/lockspire/workflow_supply_chain_contract_test.exs`
- **Verification:** Focused workflow source ExUnit passes 4 tests, 0 failures.
- **Committed in:** `71d36406`.

**2. [Rule 1 - Bug] Normalize the symbolic origin/HEAD alias during authorized main advancement**
- **Found during:** Phase 139 final acceptance fixture
- **Issue:** Advancing `origin/main` also changes `origin/HEAD` in a normal clone, so the immutable branch receipt reported a false topology mismatch.
- **Fix:** Normalize the alias only when Git's symbolic-ref proves `origin/HEAD` points to `origin/main`, and only when `origin/main` is within the authorized candidate chain.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`
- **Verification:** Final acceptance/receipt selectors pass 2 tests, 0 failures; portable and live lifecycle suites each pass 16 tests, 0 failures.
- **Committed in:** `32df92a5`.

---

**Total deviations:** 2 auto-fixed (2 Rule 1)
**Impact on plan:** Both fixes were required by executable verification. No product or release scope was added.

## Issues Encountered

- Live parity first ran in the isolated worktree, which does not contain ignored installed `.gsd` capability files; rerunning in the primary checkout passed all 16 tests. The two temporary worktree dependency symlinks were removed before GSD cleanup.

## User Setup Required

None for the repository-owned tests. The actual synchronized-main acceptance remains an automated external GSD lifecycle gate.

## Next Phase Readiness

- Run fresh canonical Phase 139 verification (`$gsd-verify-work 139`) after this plan summary is recorded.
- G-139-01 and G-139-09 remain pending until the supported post-transition finalizer produces the live exact-SHA receipt. Do not start Phase 140 planning until its blocking `plan:pre` gate validates that receipt.

## Self-Check: PASSED

- SUMMARY file exists at the required phase path.
- Task commits `bd652415`, `bebe366e`, `71d36406`, and `32df92a5` are present in Git history.
- Phase 139's production receipt boundary remains explicitly pending; this plan summary does not claim phase verification.

---
*Phase: 139-required-truth-reconciliation*
*Completed: 2026-09-24*
