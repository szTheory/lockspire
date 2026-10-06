---
phase: 139-required-truth-reconciliation
plan: "14"
subsystem: release-hygiene
tags: [release-train, exact-sha, bash, exunit]
status: complete
requires:
  - phase: 139-required-truth-reconciliation
    provides: Plan 139-13 completion-transition fixture and the maintained Phase 139 evidence context
provides:
  - Release train hygiene parses Release Please metadata separately from latest public package truth
  - Exact-SHA fixture proves refreshed origin/main and same-SHA no-publish receipt after hygiene passes
  - Temporary repository adversaries reject missing, duplicate, malformed, and conflicting ledger fields before fetch
affects: [phase-139-verification, exact-sha-acceptance, release-hygiene]
actuals:
  tokens: 2413
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 96b68a85013d970ff1839e2bb41c0e83f2a9dd04
plan_head_after: 7c25ae0c86c0ef44e22f2b20cf645bd334b31ebc
tech-stack:
  added: []
  patterns:
    - Independent release metadata and public package claims with corroborating artifact and tag
    - Hostile ledger cases run from isolated temporary repository roots
key-files:
  created: []
  modified:
    - scripts/maintainer/repo_hygiene_check.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - test/lockspire/release/repository_hygiene_contract_test.exs
key-decisions:
  - "Release Please metadata and latest public package remain independent claims; the public value must match its package artifact and GitHub tag."
  - "Any absent, duplicate, malformed, or conflicting release-train claim blocks before exact-SHA acceptance begins."
patterns-established:
  - "Mutate only a copied ledger in a temporary repo while symlinking read-only repository inputs and excluding .git and generated directories."
requirements-completed: [HYGIENE-05, HYGIENE-06, QUAL-05, TRUTH-04]
coverage:
  - id: D1
    description: Current release metadata and separately observed public package pass hygiene and allow synchronized exact-SHA acceptance.
    requirement: HYGIENE-05
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#exact-SHA repository hygiene joins synchronized local and workflow truth
        status: pass
    human_judgment: false
  - id: D2
    description: Missing, duplicate, malformed, legacy-only, or contradictory ledger claims block before ref fetch or receipt output.
    requirement: HYGIENE-06
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#exact-SHA hygiene blocks misleading release train claims before acceptance
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-10-06
---

# Phase 139 Plan 14: Required Truth Reconciliation Summary

The repository hygiene gate now distinguishes Release Please metadata `1.5.1` from the latest public package `1.5.0`, corroborates public truth against its package artifact and tag, and reaches exact-SHA acceptance only after that validation passes.

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-06T00:00:34Z
- **Completed:** 2026-10-06T00:09:25Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced the obsolete “Latest released version” parser with a single-entry Release Please metadata parser that accepts the maintained marker suffix.
- Kept current public package version independent from Release Please metadata and required agreement with the ledger's package artifact name and GitHub release tag.
- Proved the valid fixture fetches only `origin/main`, checks synchronized full SHAs, validates same-SHA CI and Release no-publish evidence, and emits its bounded temporary receipt.
- Added isolated adversarial ledger fixtures for missing, duplicate, malformed, mismatched, misleading-public, artifact/tag disagreement, and legacy-only claims; each blocks before fetch or receipt.

## Verification

- Initial RED observation: the existing positive fixture failed before any origin/main fetch because the old parser reported `[BLOCK] release train ledger` for the maintained schema.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 MIX_ENV=test mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase139_exact_sha_hygiene`: **5 tests, 0 failures** (58 excluded).
- `bash -n scripts/maintainer/repo_hygiene_check.sh`: passed.
- `bash scripts/ci/lint_workflows.sh`: passed.
- Scoped `git diff --check`: passed.
- The exact-SHA tests used fake Git/GitHub/Mix/Docker commands and temporary fixture state. No live finalizer, workflow, ref mutation, publication, or real acceptance receipt was invoked.

## Task Commits

1. **Task 1: Accept the maintained release train and reach exact-SHA receipt through refreshed origin/main** — `fc4420f0` (`fix`).
2. **Task 2: Reject misleading release-train values before acceptance** — `7c25ae0c` (`test`).

## Files Created/Modified

- `scripts/maintainer/repo_hygiene_check.sh` — parses and corroborates current metadata/public package claims before acceptance.
- `test/support/lockspire/release_proof/package_assertions.ex` — asserts valid exact-SHA proof and temporary hostile ledger behavior.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — exposes the focused passing and fail-closed contracts.

## Decisions Made

- Release Please's `1.5.1` metadata is not evidence that `1.5.1` is publicly released; current public package truth stays independently anchored to `1.5.0` artifact and tag records.
- Invalid or ambiguous ledger authority blocks before exact-SHA fetch and workflow validation.

## Deviations from Plan

None - implementation stayed within the listed parser and fixture files. A sandbox denial of `.git` writes was resolved through the authorized escalated commit path; no unrelated files were staged.

## Issues Encountered

- The first task commit attempt was denied because the sandbox restricts `.git` writes. The same plan-scoped commit succeeded after requesting escalated write access.
- The first parser draft did not match the ledger's quoted tag date. The focused fixture exposed the issue; the tag parser was corrected and all focused checks passed afterward.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 139-14 is complete. Plan 139-15 remains the next dependent plan; no public release status or historical Phase 140/141 acceptance claim changed.

## Self-Check: PASSED

- Summary exists at the planned path.
- Parser and both fixture/test files exist.
- Task commits `fc4420f0` and `7c25ae0c` are present in Git history.
