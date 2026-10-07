---
phase: publish-and-verify-lockspire-1-5-1
plan: "03"
subsystem: release
tags: [github-actions, hex, artifact, release, evidence, elixir]
requires:
  - phase: 143-02
    provides: Manifest-bound Hex publisher and exact-tar proof.
provides:
  - Strict deterministic terminal receipt with per-stage states, exact run identity, manifest/artifact digests, and safe recovery actions.
  - Read-only workflow-dispatch collector that observes Hex, GitHub release/tag, docs, and public install outcomes after jobs settle.
  - Maintainer guidance for public-but-unverified outcomes and the 30-day same-artifact recovery limit.
affects: [143-04, 143-05, 143-06, release-train]
actuals:
  tokens: 12423
  tasks: 3
  commits: 4
  plan_head_before: eda45d34291ce49b02e1011db3b92acbea0dc64c
  plan_head_after: d00b34b15bbb46cf9df60316f07ad1a747ab7259
tech-stack:
  added: []
  patterns:
    - Validate allowlisted workflow state and observed public facts before writing compact, sorted JSON evidence.
    - Represent missing or contradictory observations as unknown and keep public package presence separate from complete verification.
key-files:
  created: []
  modified:
    - scripts/publish/release_artifact.py
    - .github/workflows/release.yml
    - scripts/publish/verify_install_truth.sh
    - test/lockspire/release_artifact_chain_contract_test.exs
    - test/lockspire/release_workflow_artifact_contract_test.exs
    - docs/maintainer-release.md
key-decisions:
  - "A terminal receipt binds its workflow_run_id to the current invocation and computes the manifest digest from the exact downloaded bytes."
  - "A failed job does not prove a package is absent; remote Hex/GitHub observations and stage outputs remain separate evidence."
  - "A missing Hex checksum or unavailable tag target remains unknown and cannot produce release_verified=true."
requirements-completed: [REL-03]
coverage:
  - id: D1
    description: "Terminal receipts encode success, partial, not-run, and unknown outcomes with a strict redacted schema."
    requirement: REL-03
    verification:
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#terminal receipt records complete public verification with deterministic manifest identity"
        status: pass
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#terminal receipt keeps Hex public truth when later release proof fails"
        status: pass
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#terminal receipt records prepublish stages as not run when no manifest exists"
        status: pass
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#terminal receipt rejects secret-bearing input without echoing the value"
        status: pass
    human_judgment: false
  - id: D2
    description: "The read-only collector runs after failed or skipped dispatch jobs and retains one exact-run receipt for 90 days."
    requirement: REL-03
    verification:
      - kind: unit
        ref: "test/lockspire/release_workflow_artifact_contract_test.exs#terminal outcome is collected after failed or skipped publish stages"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/release.yml"
        status: pass
    human_judgment: false
  - id: D3
    description: "The runbook distinguishes public presence from verification and explains same-artifact recovery and expiry."
    requirement: REL-03
    verification:
      - kind: unit
        ref: "test/lockspire/release_workflow_artifact_contract_test.exs#postpublish verifies exact public behavior and retains only bounded JSON"
        status: pass
      - kind: other
        ref: "git diff --check"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-10-07
status: complete
---

# Phase 143 Plan 03: Terminal Release Truth Summary

**Every manual release attempt now emits a bounded receipt that distinguishes public Hex presence from complete release verification and points to a safe recovery action.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-07T17:42:04Z
- **Completed:** 2026-10-07T17:55:50Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `terminal-receipt`, which validates an exact allowlist, binds the decimal-string workflow run ID to the current CLI invocation, hashes the exact manifest bytes, validates source/version identity, and emits deterministic compact JSON with all four-state stage results.
- The receipt records Hex public presence/checksum/latest version, GitHub release and tag target, docs and install outcomes, a separate `release_verified` result, a bounded blocker, and the next safe action. Missing or contradictory observations stay unknown; no raw exception or credential value is retained.
- Added a read-only `always()` collector for `workflow_dispatch` runs. It tolerates a missing prepublish artifact, verifies available tar/manifest bytes, queries Hex/GitHub/docs, and uploads only `release-terminal-receipt.json` for 90 days.
- Added per-stage GitHub outputs for postpublish docs and install truth, plus runbook procedures for partial public release state and same-SHA/same-tar recovery through the 30-day package artifact window.

## Task Commits

1. **Task 1: Carry a partial publish outcome into a validated receipt** - `ff82e132` (`feat(143-03): capture terminal release truth`), followed by `d00b34b1` (`fix(143-03): keep unavailable Hex checksums unknown`).
2. **Task 2: Collect terminal truth after every workflow-dispatch attempt** - `e0130395` (`feat(143-03): collect outcomes for every release attempt`).
3. **Task 3: Document partial public truth and recovery boundaries** - `c10a51a6` (`docs(143-03): explain partial release recovery`).

## Files Modified

- `scripts/publish/release_artifact.py` - Validates terminal receipt input and emits digest-bound, four-state release truth.
- `.github/workflows/release.yml` - Adds stage outputs and the read-only always-run receipt collector.
- `scripts/publish/verify_install_truth.sh` - Reports docs and install outcomes through GitHub step outputs.
- `test/lockspire/release_artifact_chain_contract_test.exs` - Covers full, partial, not-run, unknown, malformed, mismatched-run, and secret-bearing receipt fixtures.
- `test/lockspire/release_workflow_artifact_contract_test.exs` - Pins collector conditions, permissions, artifact contents/retention, and runbook fields.
- `docs/maintainer-release.md` - Defines the receipt fields, public-versus-verified distinction, and recovery expiry.

## Decisions Made

- The collector derives release truth from allowlisted step outputs and independent public observations; it does not convert a failed job into proof of package absence.
- A matching Hex checksum can establish package presence after a later job failure, but `release_verified` remains false until every required stage and public fact agrees.
- An unavailable public checksum or tag target is unknown, not a mismatch or pass.

## Deviations from Plan

**1. Added `scripts/publish/verify_install_truth.sh` to expose docs and install outcomes.** The plan listed the workflow and contract test but did not list this helper. Its step outputs are needed to distinguish a docs failure from an install failure after the existing postpublish script returns nonzero. The script's normal verification behavior remains unchanged.

**2. Added a fourth follow-up commit to task 1.** A review found that a present Hex release with an unavailable checksum could be classified as a mismatch. The receipt now records that case as unknown, with a regression fixture.

## Issues Encountered

The workflow contract initially used an exact runbook phrase that crossed a Markdown line break; the test now checks the stable receipt field name. The final focused suites passed after that adjustment.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 143-04 can review and merge the release hardening. Its exact-PR merge decision remains a blocking checkpoint, and the following publish decision is separate.

## Self-Check: PASSED

- All four task commits are reachable from the current branch.
- `actionlint`, shell syntax, Python AST parsing, and `git diff --check` passed.
- The focused artifact-chain and workflow-artifact suites passed together: all 23 tests passed.

---
*Phase: publish-and-verify-lockspire-1-5-1*
*Completed: 2026-10-07*
