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

## phase-139-finalizer-stale-seal — pending plan-pre receipt bound to an older checkout
- **Date:** 2026-10-05
- **Error patterns:** `another final acceptance is active`, `recovery working-tree identity`, `refresh_required`, pending plan:pre receipt candidate differs from HEAD
- **Root cause(s):** The pending receipt sealed an earlier HEAD and worktree snapshot; `prepare` intentionally reuses it, so later Phase 140 work could not authenticate through the ordinary gate. The first opt-in successor path had incomplete durable-authority, lineage, mutation, ref-drift, and durability checks.
- **Fix:** Added and reviewed a digest-bound one-hop supersession protocol with strict durable acceptance validation, immutable prior archive, serialized receipt mutation, prepublication ref checks, and exact-state rollback/reporting. The live operation and separate exact-SHA publication were not invoked; the gate remains blocked.
- **Files changed:** `scripts/maintainer/baseline_inventory.sh`, `scripts/maintainer/finalize_phase_139_acceptance.sh`, `tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs`, `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs`
- **Why not caught:** The first lifecycle fixture and initial review did not cover truncated acceptance evidence, repeat v2 lineage, direct completion interleaving, late ref drift, or directory-sync failure.
- **Recurrence guard:** The Phase 140 recovery fixture in `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` now checks these cases; `.planning/phases/140-bounded-operational-loose-end-triage/140-2026-10-05-finalizer-supersession-REVIEW.md` records final dispositions.
---
