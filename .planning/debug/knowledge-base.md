# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## phase-numbered-proof-labels — historical phase name in active capability proof
- **Date:** 2026-10-05
- **Error patterns:** `active_phase_numbered_proof_locations()` returns package assertion locations; `proof_quality_baseline_test.exs` expects `[]`
- **Root cause(s):** Commit a354e723 inlined a phase-numbered production execution label into five active package-proof assertions, violating the permanent phase-neutral proof-label contract.
- **Fix:** Renamed the proposal-only execution label to `no — inventory proposal only` in the collector and all five package assertions (commit 57252ca5).
- **Files changed:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
- **Why not caught:** The existing quality gate caught the issue in the post-wave test run, after the gap changes had landed.
- **Recurrence guard:** `test/lockspire/quality/proof_quality_baseline_test.exs:62` requires zero phase-numbered labels in active proof files; repository hygiene collector tests assert phase-neutral proposal-only output.
---
