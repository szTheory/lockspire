# Phase 137 Plan 02: Truthful Coverage Aggregation Summary

**Completed:** 2026-08-27
**Requirements:** CI-02

## Outcome

Fast and integration ExUnit ownership now maps to distinct native Mix coverage exports. The runner records a bounded same-SHA checksum receipt for each export and keeps the separately booted clean-room journey as independent behavioral evidence.

`scripts/ci/aggregate_coverage.sh` accepts exactly one `fast` and one `integration` manifest/coverdata pair, rejects missing, duplicate, extra, checksum-mismatched, malformed, or foreign-SHA data, and copies only validated coverdata into a fresh report directory. It invokes the native `Mix.Tasks.Test.Coverage` task with the ordinary test alias disabled, so aggregation does not execute either test partition. The complete-suite project mode enforces 84%; ordinary developer coverage retains the measured 73% fast-only floor.

## Evidence

- Focused coverage, matrix, and baseline contracts: 6 tests, 0 failures.
- Both maintained shell scripts pass `bash -n`.
- Native baseline measurement before implementation: one fast export plus one integration export produced 78.03%, establishing the behavioral closure needed in Plan 03.
- No production module was ignored and no external coverage dependency was added.

## Security Notes

- Coverage artifacts are data only; no artifact field becomes a command or source path.
- A strict allowlist schema, exact filenames, regular-file checks, source SHA, and SHA-256 bind each input before Mix imports it.
- The native Mix threshold is authoritative; the parsed percentage is receipt metadata only.
