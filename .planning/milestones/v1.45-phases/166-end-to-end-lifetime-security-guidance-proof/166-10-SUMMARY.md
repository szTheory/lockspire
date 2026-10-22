---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "10"
subsystem: testing
tags: [elixir, python, github-actions, ci, client-lifetimes, receipts]
requires:
  - phase: 166-09
    provides: Packaged fresh, configured-store, and legacy-prefix lifetime proof legs
provides:
  - One explicit canonical packaged lifetime partition with strict nine-scenario receipt aggregation
  - SHA-bound, allowlisted receipt validation and 14-day CI retention
affects: [166-11, 166-12, integration-ci, client-lifetime-evidence]
actuals:
  tokens: 12900
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 9faf05913a8959e4895d74232885ecaf5df82fa6
plan_head_after: a23b32868f751e955c9108065849c190069da7d2
tech-stack:
  added: []
  patterns:
    - Exact tagged proof partition separated from broad integration selection
    - Receipt uploads gated on source-bound allowlist validation
key-files:
  created:
    - scripts/acceptance/client_lifetime_receipts.py
    - test/acceptance/client_lifetime_receipts_test.py
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-10-01-RED.json
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-10-02-RED.json
  modified:
    - scripts/ci/run_test_matrix.sh
    - .github/workflows/ci.yml
    - scripts/acceptance/clean_room/lifetime_receipts.py
    - test/lockspire/ci_workflow_evidence_contract_test.exs
key-decisions:
  - "Run the complete lifetime_package selection once after the broad integration selection, preserving the broad integration tag across test directories."
  - "Retain only receipt.json and validation.json after a strict source and field allowlist check; do not upload timing data containing host paths."
patterns-established:
  - "A combined receipt must contain all nine required scenario IDs with positive counts and zero failed or skipped scenarios."
  - "A CI artifact can be retained after a later matrix failure only when its SHA-bound receipt validation succeeds."
requirements-completed: []
coverage:
  - id: D1
    description: "Canonical local package run exercised all nine lifetime scenarios and emitted positive, sanitized receipts."
    requirement: DCR-17
    verification:
      - kind: integration
        ref: "scripts/ci/run_test_matrix.sh --integration; lifetime_package partition"
        status: pass
    human_judgment: true
    rationale: "The execution receipt names the pre-task1 observed source revision; archive and extracted-tree equality to task1 commit 5709092d was independently confirmed, while final-candidate CI rerun belongs to plan 166-12."
  - id: D2
    description: "CI selects the active tagged proof and uploads only the validated SHA-bound receipt pair for 14 days."
    requirement: DCR-18
    verification:
      - kind: unit
        ref: "test/lockspire/ci_test_matrix_contract_test.exs and test/lockspire/ci_workflow_evidence_contract_test.exs"
        status: pass
    human_judgment: true
    rationale: "Source contracts pass locally; live required-check success is a plan 166-12 gate."
duration: 31min
completed: 2026-10-21
status: complete
---

# Phase 166 Plan 10: Active Lifetime CI Receipts Summary

**The integration workflow now runs the nine-scenario packaged lifetime proof once and retains only its validated, SHA-bound receipt pair.**

## Performance

- **Duration:** 31 minutes from the first task commit through the workflow commit.
- **Started:** 2026-10-21T22:57:29-04:00 (first atomic RED commit).
- **Completed:** 2026-10-21T23:27:54-04:00.
- **Tasks:** 2.
- **Files modified:** 15, including the deferred-items record.

## Accomplishments

- Added strict receipt aggregation for all four fresh, three custom-store, and two legacy-prefix scenarios. Missing, failed, skipped, empty, duplicate, or mismatched identity evidence fails validation.
- Kept broad tagged integration selection across the repository, excluded only `lifetime_package` from that broad run, then invoked the complete packaged partition once with the same archive for all legs.
- Added workflow validation that checks exact receipt fields, all nine IDs, positive/reconciled counts, source revision, and candidate digest before uploading exactly two JSON files for 14 days. Removed upload of timing data that contained runner paths.
- Documented the 30-minute timeout against a measured 649 seconds across the four matrix partitions, with bounded setup and runtime headroom.

## Verification

- Receipt validator tests: `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_receipts_test.py' -v` — 7 passed.
- CI source contracts: targeted ExUnit command from `166-10-PLAN.md` — 4 tests, 0 failures.
- `bash -n scripts/ci/run_test_matrix.sh` and `bash scripts/ci/lint_workflows.sh` — passed.
- The exact canonical command `bash scripts/ci/run_test_matrix.sh --integration .artifacts/ci/integration-timings.json .artifacts/ci/coverage/integration "$GITHUB_SHA"` ran once. The explicit packaged lifetime partition passed 3 tests with 0 failures. Its sanitized receipt reports 49 executed, 49 passed, 0 failed, 0 skipped across the exact 9 required scenarios. Validation reports candidate digest `5ddfd5e4ce2633ecec61c2bc5295d09c10edd6e38b5c4521c934fe88d276cbe2`.
- The receipt records observed source revision `8050a3988139b7142a0c0713beae379bb8055e22`. A rebuilt candidate after commit `5709092d` matched both the recorded archive SHA and unpacked tree SHA, and no package source files differed from that commit. The observed receipt metadata remains unchanged; final-candidate CI evidence still belongs to plan 166-12.
- The full matrix exited 2: broad integration had existing fixture failures, and the separate clean-room journey hit a redacted `scenario=unknown` assertion. These failures and the exact remaining identity limitation are recorded in [deferred-items.md](./deferred-items.md). They do not change the passing packaged lifetime partition result.
- No live CI result or required-check success is claimed.

## Task Commits

1. **Task 1 RED:** `8050a398` — failing combined receipt contract.
2. **Task 1 GREEN:** `5709092d` — packaged lifetime receipts and matrix partition.
3. **Task 2 RED:** `3aa6b261` — active CI and safe artifact source contracts.
4. **Task 2 GREEN:** `a23b3286` — validated SHA-bound receipt retention.

## Decisions Made

- Keep the global integration selector broad and avoid the `test.integration` convenience alias for the required proof.
- Validate receipts even after matrix failure, then upload only when the validation step succeeds. This preserves a completed safe receipt if a later unrelated partition fails while preventing partial output from being retained.
- Keep CI retention to the exact receipt and validation files; do not upload timing artifacts that include host-specific paths.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unified candidate tree identity across package legs**
- **Found during:** Task 1.
- **Issue:** The fresh/custom journey produced a separate tree digest algorithm from the package identity, so receipt aggregation correctly rejected the otherwise passing legs as mismatched candidates.
- **Fix:** Both runners now use the canonical package identity archive and extracted-tree digests; all three legs agree on one candidate.
- **Files modified:** `scripts/acceptance/clean_room_saas_journey.py`, `scripts/acceptance/clean_room/client_lifetime_upgrade.py`, and the packaged integration wrappers.
- **Verification:** The explicit partition passed; combined receipt validation accepted the one archive/tree identity.
- **Committed in:** `5709092d`.

**2. [Rule 1 - Blocking issue] Corrected package-build shell invocation**
- **Found during:** Task 2 workflow lint.
- **Issue:** Shellcheck flagged the package-build environment assignment as ambiguous.
- **Fix:** Invoke the build through `env MIX_ENV=test`.
- **Files modified:** `scripts/ci/run_test_matrix.sh`.
- **Verification:** `bash -n` and workflow/shell lint passed.
- **Committed in:** `a23b3286`.

**Total deviations:** 2 auto-fixed.
**Impact on plan:** Both fixes were required for reliable candidate matching and clean CI tooling. No new dependency or CI platform was added.

## TDD Gate Compliance

- Task 1 RED evidence: `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-10-01-RED.json` classified `RED_EVIDENCE_OK`; task 1 GREEN is `5709092d`.
- Task 2 RED evidence: `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-10-02-RED.json` classified `RED_EVIDENCE_OK` through a Python `unittest` adapter that ran the targeted ExUnit source contracts; task 2 GREEN is `a23b3286`.
- Both targeted contract and receipt suites pass after implementation.

## Next Phase Readiness

Plan 166-11 can consume the completed local proof. Plan 166-12 must rerun evidence against the final committed candidate, obtain current live required CI and complete the independent scoped security review before umbrella closure.

## Self-Check: PASSED

- All created files and four task commits exist in the working tree/history.
- The summary commit ledger records 4 commits from `9faf05913a8959e4895d74232885ecaf5df82fa6` through `a23b32868f751e955c9108065849c190069da7d2`.
- The unrelated `.planning/state.json` change remains unstaged and untouched by this plan executor.

---
*Phase: 166-end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-21*
