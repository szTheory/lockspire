---
phase: 127-installer-against-a-real-host
plan: 10
subsystem: testing
tags: [ci, bash, python, mix-alias, github-actions, adopter-walk, defect-ledger]

# Dependency graph
requires:
  - phase: 127-installer-against-a-real-host (plans 127-05, 127-06, 127-09)
    provides: the router-template rewrite (D-11), config-template rewrite, and the six
      retired workaround markers/re-scoped ADOPT-D04/ADOPT-D18 workarounds this plan's
      baseline predicts against
provides:
  - A machine-readable adopter-walk report (NUL-delimited record stream -> JSON via a
    committed Python emitter, never bash-constructed JSON)
  - A hand-authored, committed-before-any-run baseline predicting every expected
    (step_id, occurrence) row from source alone
  - A deterministic verifier distinguishing REGRESSION/UNRECORDED_FIX/NEW_ROW/MISSING_ROW/INFRA
    with a defined exit-code contract, exercised against 6 fixture reports including the
    plan's required negative control
  - A CI-wrapper with an attempt-2 reproducibility check (REGRESSION vs UNSTABLE/INFRA)
  - An advisory, non-blocking, paths-filtered GitHub Actions lane with no schedule trigger
affects: [phase-128-documented-wiring-truth, phase-129-reference-artifact-alignment,
  phase-130-adopter-path-guardrail]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "NUL-delimited record stream (printf injection-proof) converted to JSON only by a
      committed stdlib-only Python emitter -- never constructed in bash"
    - "Baseline keyed on (step_id, occurrence), not step_id alone, since a step can emit
      multiple rows per run"
    - "Verifier exit-code contract: 0=match, 1=usage/precondition, 2=infra, 3=mismatch,
      with the walk's own exit code deliberately irrelevant to the gate"
    - "CI reproducibility check via resume-marker-only retry, comparing raw report rows for
      specific keys rather than re-running the full verifier against a resumed report
      (which the verifier's own precondition would reject)"

key-files:
  created:
    - scripts/maintainer/adopter_walk_report.py
    - scripts/maintainer/adopter_walk_baseline.json
    - scripts/maintainer/adopter_walk_verify.py
    - scripts/maintainer/adopter_walk_ci.sh
    - test/lockspire/maintainer/adopter_walk_baseline_contract_test.exs
    - .github/workflows/adopter-walk.yml
  modified:
    - scripts/maintainer/adopter_path_walk.sh
    - mix.exs
    - test/lockspire/maintainer/adopter_walk_contract_test.exs

key-decisions:
  - "Derived the baseline's 28 rows (22 expected PASS, 6 expected FAIL) by reading every
    record_result call site and [PASS]/[FAIL] driver line directly, never from a remembered
    summary or a real run -- 127-09's own ~25/6 estimate is a rough estimate, the derived
    rows are the artifact"
  - "Kept one still-live dead FAIL branch (step-03b-router-call, ADOPT-D01) traceable in the
    baseline as a PASS row carrying the historic defect ID, so the invariant-2 contract test's
    two-way static mapping stays satisfied without asserting a level that no longer occurs"
  - "Resolved three run_step_* functions that pass \"$step_id\" as a variable (not a literal)
    to record_result by nearest-preceding `local step_id=` source position, since a naive
    literal-only regex silently misses their FAIL call sites entirely"
  - "CI attempt-2 retry compares raw report rows for specific mismatched keys directly,
    bypassing adopter_walk_verify.py's own resumed-row precondition for that narrow
    reproducibility check -- rerunning the full verifier against a resumed second attempt
    would always trip that precondition"

requirements-completed: [INSTALL-01, INSTALL-02, INSTALL-03]

coverage:
  - id: D1
    description: "The walk emits a machine-readable JSON report via a NUL-delimited record
      stream and a committed Python emitter, keyed on (step_id, occurrence)"
    requirement: INSTALL-01
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs (walk script always
          writes a machine-readable JSON report; record_result appends to the NUL-delimited
          record stream)"
        status: pass
      - kind: other
        ref: "manual smoke of adopter_walk_report.py against a hand-built NUL record stream,
          confirmed occurrence/guide_section/defect_ids/resumed derivation"
        status: pass
    human_judgment: false
  - id: D2
    description: "The walk is repeatable without hand cleanup: --force moves a prior host
      aside instead of unconditionally refusing, and the phx.gen.auth seed is idempotent"
    requirement: INSTALL-02
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs (walk script preserves
          the evidence tree unconditionally; walk script seeds the user through the
          generator's own confirmation path)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A hand-authored, committed-before-any-run baseline is bound to the ledger
      by four static contract-test invariants"
    requirement: INSTALL-01
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_baseline_contract_test.exs (all 5 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A deterministic verifier classifies REGRESSION/UNRECORDED_FIX/NEW_ROW/
      MISSING_ROW/INFRA with a defined exit-code contract, no --bless/--update-baseline flag"
    requirement: INSTALL-03
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs (adopter.walk.verify
          alias wiring; verifier never provides --bless or --update-baseline)"
        status: pass
      - kind: other
        ref: "manual fixture exercise of all 5 verifier exit paths (0/1/2/3 x2) plus the
          plan-required negative control: hand-edited the committed baseline, confirmed exit 3
          naming the exact row, reverted"
        status: pass
    human_judgment: false
  - id: D5
    description: "An advisory, paths-filtered CI lane runs the walk and verifier with a
      timeout, no schedule, and no dependency-resolution caching"
    requirement: INSTALL-03
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/ full suite (68 tests) + YAML parse via python3 -c
          'import yaml' confirming no schedule trigger and timeout-minutes: 45"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 10: Adopter Walk Machine-Readable Verdict Summary

**A NUL-delimited-stream JSON report, a hand-authored pre-run baseline with a two-way static
contract test, a deterministic exit-coded verifier, and an advisory CI lane -- replacing the
human who reads a 31-line report by eye with a mechanical diff.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-07-29
- **Tasks:** 5
- **Files modified:** 9 (4 created new scripts, 1 created baseline JSON, 1 created test file,
  1 created workflow file, 2 modified existing files)

## Accomplishments

- `record_result` now appends to a NUL-delimited record stream (`RECORD_STREAM`), and
  `scripts/maintainer/adopter_walk_report.py` converts it to JSON (schema
  `lockspire.adopter_walk.report/1`) -- no JSON is ever constructed in bash. `--report-json`
  is always written, from `print_report()` before its own `exit 1` and on the
  `--preflight-only` path.
- The walk is now repeatable without hand cleanup: the regenerate refusal is gated on
  `FORCE -ne 1`, and `--force` moves a prior host aside to a timestamped
  `.superseded.<utc>.<pid>` directory (never deletes it, per D-20). The phx.gen.auth user seed
  now looks the user up by email first and reuses it when present, since `WALK_DB_NAME` is
  fixed and the database survives between runs.
- `scripts/maintainer/adopter_walk_baseline.json` was derived from every `record_result` call
  site and driver `[PASS]`/`[FAIL]` line, not from a remembered summary: 28 rows, 22 expected
  PASS / 6 expected FAIL, `authored_before_run: true`, `confirmed_by_run: null`.
  `test/lockspire/maintainer/adopter_walk_baseline_contract_test.exs` (new file) asserts four
  static invariants binding it to the ledger and the harness.
- `scripts/maintainer/adopter_walk_verify.py` compares a report against the baseline over
  `(step_id, occurrence)`, with exit 0 on a full match (the walk's own exit code is
  irrelevant), exit 1 on a precondition violation (partial/resumed run), exit 2 on
  infrastructure failure, and exit 3 on any REGRESSION/UNRECORDED_FIX/NEW_ROW/MISSING_ROW.
  `--print-baseline-patch` prints proposed rows for a human to paste and annotate; there is no
  `--bless`/`--update-baseline` flag.
- `scripts/maintainer/adopter_walk_ci.sh` runs the walk, verifies, and on a mismatch retries
  once (resume markers only, never `--force`) to distinguish a reproducible regression from an
  unstable/flaky run, writing a verdict to `$GITHUB_STEP_SUMMARY`.
- `mix.exs` gained the `"adopter.walk.verify"` alias outside `ci:`, and
  `.github/workflows/adopter-walk.yml` is a new, separate, advisory, paths-filtered workflow
  with `timeout-minutes: 45`, no schedule, and no dependency-resolution caching.

## Task Commits

Each task was committed atomically:

1. **Task 1: Emit a machine-readable walk report** - `d15037f` (feat)
2. **Task 2: Make the walk repeatable without hand cleanup** - `bd4845c` (fix)
3. **Task 3: Hand-author the expected-outcome baseline and bind it to the ledger** - `5186122` (feat)
4. **Task 4: Build the verifier and wire the alias** - `da00dbb` (feat)
5. **Task 5: Add the advisory CI lane** - `50868b1` (feat)

## Files Created/Modified

- `scripts/maintainer/adopter_path_walk.sh` - Added `--report-json`, `RECORD_STREAM`,
  `collect_resolved_versions()`, `emit_report_json()`; gated the regenerate refusal on
  `FORCE`; made the user seed idempotent; documented the flow-drive step's deliberate
  markerlessness
- `scripts/maintainer/adopter_walk_report.py` - NUL-stream-to-JSON emitter, stdlib-only
- `scripts/maintainer/adopter_walk_baseline.json` - Hand-authored, pre-run expected outcomes
- `test/lockspire/maintainer/adopter_walk_baseline_contract_test.exs` - Four static invariants
- `scripts/maintainer/adopter_walk_verify.py` - Deterministic report-vs-baseline verifier
- `scripts/maintainer/adopter_walk_ci.sh` - CI wrapper: run, verify, retry-for-reproducibility
- `mix.exs` - Added `"adopter.walk.verify"` alias outside `ci:`
- `test/lockspire/maintainer/adopter_walk_contract_test.exs` - New assertions for
  `--report-json`, the record stream, the baseline file, the new alias, and the absent
  `--bless`/`--update-baseline` flags
- `.github/workflows/adopter-walk.yml` - Advisory, paths-filtered PR lane plus
  `workflow_dispatch`

## Decisions Made

- Derived the baseline's rows directly from `record_result` call sites and driver
  `[PASS]`/`[FAIL]` lines rather than from 127-09's own rough ~25 PASS / 6 FAIL estimate; the
  derived count (22/6) is the artifact, and the gap from the estimate is expected, not a bug.
- Kept the dead `ADOPT-D01` FAIL branch in `step-03b-router-call` traceable in the baseline as
  a PASS row carrying the historic defect ID (with a `why` explaining the resolved
  counterpart), so the invariant-2 contract test's two-way static source mapping stays
  satisfied without inventing a level that no longer occurs in practice.
- Resolved `run_step_03c_resolver`/`run_step_03d_app_tree`/`run_step_03e_protected_route`'s
  `"$step_id"`-variable `record_result` calls (rather than literal step-id strings) by
  nearest-preceding `local step_id=` source position in the new contract test, since a
  literal-only regex (matching the existing `shell_steps/1` shape) silently misses every FAIL
  call site inside those three functions.
- `adopter_walk_ci.sh`'s attempt-2 reproducibility check compares raw report rows for the
  specific mismatched keys directly, rather than re-running `adopter_walk_verify.py`'s full
  comparison against the resumed second attempt -- the verifier's own resumed-row precondition
  would otherwise always reject that second report outright.

## Deviations from Plan

None - plan executed exactly as written. All five tasks, their acceptance criteria, and the
plan-level `<verification>` steps (excluding the actual `mix adopter.walk`/
`mix adopter.walk.verify` runs, which `<do_not_run_the_walk>` explicitly reserved for the
orchestrator) were completed and verified.

## Issues Encountered

- Initial invariant-2 design in `adopter_walk_baseline_contract_test.exs` used a literal-only
  regex (mirroring the existing `shell_steps/1` shape exactly) and failed against two real
  baseline rows (`step-03c-resolver`/`ADOPT-D11`, `step-03d-app-tree`/`ADOPT-D05`) because
  those two `run_step_*` functions pass `record_result "FAIL" "$step_id" "..."` (a variable)
  rather than a literal step-id string. Resolved by adding position-based resolution against
  each function's `local step_id="..."` assignment before the invariant's set comparison.
  Caught immediately by running the new test file (`mix test`), fixed in the same task before
  committing -- not a deviation requiring a separate fix-forward commit.
- The verifier's own doc comment mentioning `--bless`/`--update-baseline` (to explain they are
  deliberately absent) tripped a naive substring assertion in the extended contract test.
  Narrowed the assertion to check for an actual `add_argument("--bless")`-shaped flag
  registration instead of a raw substring match, before committing Task 4.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The instrumentation (report emitter, baseline, verifier, CI wrapper, GitHub Actions lane) is
  complete and self-consistent, verified via `bash -n`, `python3 -m py_compile`,
  `mix test test/lockspire/maintainer/` (68 tests green), `mix qa`, and hand-built fixture
  exercises of all verifier exit paths plus the plan's required negative control (a hand-edited
  committed-baseline row correctly produces exit 3, then was reverted).
- Per `<do_not_run_the_walk>`, the actual confirming `mix adopter.walk` /
  `mix adopter.walk.verify` run against a real generated host, real PostgreSQL, and a real
  booted server was deliberately not performed here -- that is the orchestrator's next step
  after this plan's work lands. If that first real run's report disagrees with this baseline,
  that disagreement is itself useful signal (a REGRESSION, an UNRECORDED_FIX needing a ledger
  disposition, or a genuine baseline-derivation error to fix), not evidence this plan failed.
- Phases 128-130 can now build on a deterministic, machine-adjudicated walk verdict instead of
  a human reading a report by eye.

## Self-Check: PASSED

All 10 created/modified files confirmed present on disk; all 5 task commit hashes (`d15037f`,
`bd4845c`, `5186122`, `da00dbb`, `50868b1`) confirmed in `git log`.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*
