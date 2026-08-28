---
phase: 136-static-analysis-and-sustainable-proof
plan: "01"
subsystem: testing
tags: [credo, dialyzer, exunit, telemetry, quality]
requires:
  - phase: 135-cohesive-internals
    provides: stable collaborator seams whose static-analysis debt is now characterized
provides:
  - deterministic repository-relative classifiers for source, proof, Dialyzer, and runtime diagnostic debt
  - executable temporary baseline identities that Plan 11 can ratchet to empty sets
affects: [136-02, 136-03, 136-04, 136-05, 136-06, 136-07, 136-08, 136-09, 136-10, 136-11]
tech-stack:
  added: []
  patterns: [structured repo-relative quality classifiers, synthetic allowed-and-violating fixtures]
key-files:
  created:
    - test/support/quality_baseline.ex
    - test/lockspire/quality/source_quality_baseline_test.exs
    - test/lockspire/quality/proof_quality_baseline_test.exs
    - test/lockspire/quality/runtime_noise_baseline_test.exs
  modified: []
key-decisions:
  - "Baseline identities are structured locations, not grep counts or raw captured diagnostics."
  - "Quality baseline fixtures are excluded from active-proof scans to avoid self-observation."
patterns-established:
  - "Temporary debt baselines must name exact offenders and have synthetic violating fixtures before convergence removes them."
requirements-completed: [QUAL-01, QUAL-02, QUAL-03, QUAL-04]
coverage:
  - id: D1
    description: Credo directives are classified by file, line, kind, and optional named check.
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: test/lockspire/quality/source_quality_baseline_test.exs
        status: pass
      - kind: other
        ref: bash scripts/ci/run_credo.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Proof archaeology, Dialyzer warning identities, and routine runtime noise have executable baselines.
    requirement: QUAL-02
    verification:
      - kind: unit
        ref: test/lockspire/quality/proof_quality_baseline_test.exs
        status: pass
      - kind: unit
        ref: test/lockspire/quality/runtime_noise_baseline_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 14min
  completed: 2026-08-27
status: complete
---

# Phase 136 Plan 01: Quality Baseline Summary

**Executable debt baselines distinguish narrow static-analysis remediation from proof and runtime evidence that must remain visible.**

## Accomplishments

- Classified the three file-wide and five unnamed-next-line library Credo directives by exact repository-relative location; strict Credo still parsed all 541 configured sources without findings.
- Classified active `__using__` macro injection, three archived-phase reads, and five historical proof/count contracts without treating the baseline's own fixtures as debt.
- Parsed Dialyzer warning headers and pinned the measured baseline of 66 warnings across 23 owning library files, with no ignore file; classified KeyCache startup, Ecto query, and telemetry-handler output separately from explicit redaction evidence.

## Task Commits

1. **Task 1: Trace one source-quality offender through classification and strict tooling** — `e4ac566a` (RED), `2c55e0e5` (GREEN)
2. **Task 2: Characterize proof debt and routine-versus-explicit diagnostics** — `50bca162` (RED), `3f59acd8` (GREEN), `38839460` (baseline-fixture correction)

## Verification

- `mix test test/lockspire/quality/source_quality_baseline_test.exs` — 2 tests, 0 failures.
- `bash scripts/ci/run_credo.sh` — 541 source files parsed, no issues.
- `mix test test/lockspire/quality/source_quality_baseline_test.exs test/lockspire/quality/proof_quality_baseline_test.exs test/lockspire/quality/runtime_noise_baseline_test.exs test/lockspire/key_cache_test.exs test/lockspire/protocol/dcr_telemetry_redaction_test.exs` — 11 tests, 0 failures.
- One baseline `MIX_ENV=dev mix qa.dialyzer` observation — 66 warnings, 23 owning files, no ignore baseline. This plan intentionally does not silence or fix those warnings.

## Decisions Made

- Do not persist command output: the classifier operates on caller-supplied text and tests use safe synthetic diagnostic snippets.
- Treat startup KeyCache failure, debug SQL, and local telemetry-handler notices as routine output categories only; preserve dedicated KeyCache and DCR telemetry-redaction tests as explicit evidence.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Corrected source scan glob and argument ordering.**
- **Found during:** Task 1
- **Issue:** the initial glob did not enumerate both Elixir extensions and piped source text into the classifier's file argument.
- **Fix:** enumerate `.ex` and `.exs` paths explicitly and invoke the classifier with its structured `(file, source)` order.
- **Files modified:** `test/support/quality_baseline.ex`
- **Verification:** source baseline and strict Credo passed.
- **Committed in:** `2c55e0e5`

2. **[Rule 1 - Bug] Excluded baseline fixtures from active proof inventory.**
- **Found during:** Task 2
- **Issue:** the scanner correctly found its own synthetic `__using__` and phase-read examples, contaminating the live cleanup baseline.
- **Fix:** added an explicit active-proof view that excludes only `test/lockspire/quality/` fixtures.
- **Files modified:** `test/support/quality_baseline.ex`, `test/lockspire/quality/proof_quality_baseline_test.exs`
- **Verification:** focused quality tests passed.
- **Committed in:** `3f59acd8`, `38839460`

## Known Stubs

None.

## Next Phase Readiness

Plans 02–10 can remove or restructure the named debt while Plan 11 replaces temporary baseline expectations with empty violation sets. The routine diagnostic output remains intentionally unsilenced for the later runtime-hygiene work.

## Self-Check: PASSED

- All four baseline artifacts exist.
- All five task commits are present in git history.
