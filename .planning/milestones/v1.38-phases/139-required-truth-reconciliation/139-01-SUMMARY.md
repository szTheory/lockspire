---
phase: 139-required-truth-reconciliation
plan: "01"
subsystem: repository-maintenance
tags: [bash, exunit, github-actions, exact-sha, release-hygiene]

requires:
  - phase: 138-baseline-inventory-evidence-taxonomy
    provides: Immutable proposal-only repository evidence and fail-closed currentness conventions
provides:
  - Exact-SHA maintainer acceptance mode joining synchronized Git identity, local gates, canonical CI, and Release no-publish evidence
  - Deterministic allowlisted JSON receipt with explicit WARN dispositions and supplemental OIDF classification
  - Hermetic fail-closed fixture matrix for stale, ambiguous, malformed, moving, or incomplete evidence
affects: [139-02, 139-05, 139-06, 139-07, phase-140, phase-141]

actuals:
  tokens: 9854
  tasks: 2
  commits: 4
plan_head_before: de720abbf480952d4666826140f1966d1bc5ec86

tech-stack:
  added: []
  patterns: [capture-once exact-SHA join, stable-run bounded polling, complete job pagination, allowlisted receipt projection]

key-files:
  created: []
  modified:
    - scripts/maintainer/repo_hygiene_check.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - test/lockspire/release/repository_hygiene_contract_test.exs

key-decisions:
  - "Exact acceptance derives authority only when the caller SHA equals HEAD, local main, refreshed origin/main, and both canonical workflow run SHAs before and after long-running gates."
  - "Workflow and command responses remain private; only bounded scalar identities, allowlisted job outcomes, and validated WARN disposition tokens enter the deterministic receipt."

patterns-established:
  - "Stable remote evidence: select exactly one run id for the target SHA and never swap identities while polling."
  - "Intentional no-publish: a push Release run passes only with Release Please successful and all protected publication jobs skipped."

requirements-completed: [CI-06, CI-07, QUAL-05, HYGIENE-05]

coverage:
  - id: D1
    description: Exact-SHA happy path joins synchronized Git identity, executed local tests, required CI jobs, Release no-publish jobs, and a deterministic receipt.
    requirement: CI-06
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs#exact-SHA repository hygiene joins synchronized local and workflow truth"
        status: pass
    human_judgment: false
  - id: D2
    description: Exact-SHA acceptance fails closed for ambiguous, stale, moving, malformed, incomplete, undispositioned, or disclosure-prone evidence.
    requirement: HYGIENE-05
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs#exact-SHA repository hygiene fails every ambiguous or stale path closed"
        status: pass
    human_judgment: false
  - id: D3
    description: Ordinary local and CI hygiene modes retain their established diagnostics and exit behavior.
    requirement: QUAL-05
    verification:
      - kind: integration
        ref: "bash scripts/maintainer/repo_hygiene_check.sh --ci (18 PASS, 0 WARN, 0 BLOCK)"
        status: pass
    human_judgment: false

duration: 41 min
completed: 2026-09-11
status: complete
---

# Phase 139 Plan 01: Exact-SHA Acceptance Path Summary

**A maintainer-only exact-SHA mode now joins clean local `mix ci` proof, synchronized main identity, canonical CI, intentional Release no-publish outcomes, and bounded WARN dispositions in one redacted JSON receipt.**

## Performance

- **Duration:** 41 min
- **Started:** 2026-09-11T21:11:42Z
- **Completed:** 2026-09-11T21:52:24Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `--accept-sha`, `--wait-seconds`, repeatable `--warn-disposition`, and `--format json` while preserving ordinary local and `--ci` behavior.
- Implemented `validate_acceptance_sha`, `collect_exact_workflow_run`, `validate_required_ci_run`, `validate_required_ci_jobs`, `validate_no_publish_release_run`, `require_warn_dispositions`, and `emit_acceptance_receipt`.
- Proved 38 success and hostile fixture scenarios, including stable-id polling, complete pagination, exact workflow metadata, no-publish job outcomes, test-count proof, redaction, and WARN cardinality.

## Task Commits

Each task followed RED then GREEN and was committed atomically:

1. **Task 1: Carry one exact main SHA through the full acceptance happy path**
   - `58e28d11` — `test(139-01): add failing exact-SHA hygiene contract`
   - `412f8e02` — `feat(139-01): implement exact-SHA acceptance receipt`
2. **Task 2: Fail every ambiguous, empty, stale, moving, or undispositioned path closed**
   - `af290e1d` — `test(139-01): add failing exact-SHA hostile matrix`
   - `e3507337` — `feat(139-01): fail exact-SHA acceptance closed`

## Files Created/Modified

- `scripts/maintainer/repo_hygiene_check.sh` — Exact-SHA parsing, Git/local gates, structured GitHub polling and job validation, disposition enforcement, and JSON receipt emission.
- `test/support/lockspire/release_proof/package_assertions.ex` — Hermetic fake-command fixtures for the happy path and fail-closed matrix.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — Thin tagged Phase 139 entry points for exact-SHA behavior.

## Evidence

- `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase139_exact_sha_hygiene` — 2 tests, 0 failures (37 excluded).
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — 39 tests, 0 failures.
- `bash scripts/maintainer/repo_hygiene_check.sh --ci` — 18 PASS, 0 WARN, 0 BLOCK; safe-to-start result retained.
- `bash -n scripts/maintainer/repo_hygiene_check.sh` — passed.

## TDD Gate Compliance

- Task 1 RED: the named assertion failed because `--accept-sha` was unknown; `tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 1 GREEN: the happy-path fixture passed end to end before expansion.
- Task 2 RED: the named hostile-matrix assertion caught a failed Git status observation being accepted; `tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 2 GREEN: all hostile fixtures and the full 39-test repository-hygiene contract passed.
- No separate REFACTOR commit was needed; cleanup and allowlisted receipt projection were completed while GREEN.

## Decisions Made

- Acceptance SHA input is evidence to validate, not caller-selected authority: it must equal synchronized local and remote main throughout the run.
- Polling locks onto one numeric run id and rejects candidate replacement, ambiguity, timeout, and concurrent main movement.
- Receipt job objects are projected to `name`, `status`, and `conclusion`; raw API bodies, command output, environment values, and uncontrolled caller text are never emitted.
- Supplemental OIDF remains `supplemental_non_certifying` and is not queried as a required gate.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The repository-wide workflow lint still reports the four pre-existing `baseline_inventory.sh` ShellCheck warnings documented by Phase 139 research. They are outside this plan's files and explicitly assigned to plan 139-02; no suppression or unrelated repair was made here.

## Known Stubs

None. Empty shell values in the implementation are initialization state, not rendered or behavioral placeholders.

## Threat Flags

None. The new GitHub API observation and receipt boundaries are the exact surfaces covered by T-139-01 through T-139-06; no runtime endpoint, auth path, file trust boundary, or schema surface was added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The exact-SHA tracer is green and ready for the shell-lint and proof-quality repairs in 139-02.
- Final live acceptance remains intentionally deferred until every Phase 139 mutation is synchronized on `main`; no release workflow was dispatched by this plan.

## Self-Check: PASSED

- All three modified implementation/test files and this summary exist.
- RED/GREEN commits `58e28d11`, `412f8e02`, `af290e1d`, and `e3507337` are present in history.
- Summary frontmatter records `status: complete`, the measured four task commits, and the persisted plan base.

---
*Phase: 139-required-truth-reconciliation*
*Completed: 2026-09-11*
