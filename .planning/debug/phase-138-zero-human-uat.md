---
status: diagnosed
trigger: "Phase 138 UAT produced 13 manual checkpoints, while the project goal is zero human verification through shift-left integration, E2E, smoke, and selectively recurring CI coverage."
created: 2026-09-12T19:35:13.689Z
updated: 2026-09-12T19:35:13.689Z
---

## Current Focus

hypothesis: Confirmed — executable proof already exists for all 13 behaviors, but incomplete or malformed SUMMARY coverage metadata prevented deterministic auto-pass; one fast capability-router contract is also absent from recurring CI.
test: Classify all Phase 138 SUMMARY coverage, map every manual checkpoint to existing repository tests, and inspect CI/lifecycle execution boundaries.
expecting: No new product behavior test is needed; metadata repair plus one durable CI wiring change eliminates manual UAT without duplicating expensive or live-source checks.
next_action: Execute the verified Phase 138 gap-closure plan, then regenerate UAT from corrected coverage classification.
bug_class: workflow-coverage-gap

## Symptoms

expected: Phase 138 verification derives every checkpoint from automated proof and requires zero human UAT.
actual: 82 deliverables auto-passed, but 13 checkpoints were presented manually.
errors:
  - Seven summaries use legacy coverage format: 138-01, 138-02, 138-03, 138-05, 138-18, 138-21, and 138-22.
  - 138-09 uses unsupported verification kind "live" for D3.
  - 138-23 encodes five verification values as mappings instead of lists.
reproduction: Run gsd_run query uat.classify-coverage for every Phase 138 SUMMARY, then start gsd-verify-work 138.

## Evidence

- timestamp: 2026-09-12T19:35:13.689Z
  checked: Phase 138 coverage classification
  found: 82 entries are deterministic automated passes; the remaining 13 human checkpoints trace only to seven legacy summaries and six malformed coverage entries.
  implication: The manual burden is coverage-contract debt, not untested product behavior.
- timestamp: 2026-09-12T19:35:13.689Z
  checked: test/lockspire/release/repository_hygiene_contract_test.exs and package_assertions.ex
  found: Safe Git receipts, GitHub queues, maintained taxonomy, publication integrity, immutable relation, PR-head coherence, full-blob archive classification, object-format validation, and current inventory paths all have executable production-CLI contracts.
  implication: Each manual checkpoint can cite existing automated proof; adding duplicate tests would increase runtime without additional failure detection.
- timestamp: 2026-09-12T19:35:13.689Z
  checked: mix.exs and .github/workflows/ci.yml
  found: mix test.fast includes test/lockspire, and the GitHub fast job executes that matrix, so the ExUnit inventory contracts already recur in CI.
  implication: Do not add a second CI invocation of the expensive repository-hygiene matrix.
- timestamp: 2026-09-12T19:35:13.689Z
  checked: tools/gsd-capabilities/lockspire-phase-finalizer/*.test.cjs and the release-hygiene CI job
  found: The fast, self-contained command-router contract is tracked but not invoked by CI; the lifecycle test requires an installed GSD runtime and exercises long real-repository matrices.
  implication: Add only the router unit contract to recurring CI. Keep the GSD-dependent lifecycle suite at the automated execute/verify boundary.
- timestamp: 2026-09-12T19:35:13.689Z
  checked: scripts/maintainer/finalize_phase_138_inventory.sh and capability hooks
  found: Authenticated mutable-source collection and relation checks already run automatically at pre-verify/post-transition boundaries.
  implication: Live GitHub/current-repository checks remain automated without putting credentials or mutable external truth into pull-request CI.

## Resolution

root_cause: Phase 138 accumulated historical SUMMARY files before structured coverage became mandatory, and two later summaries used invalid coverage syntax. The verifier therefore fell back to human checkpoints despite existing executable proof. Separately, the self-contained finalizer router test was never wired into recurring CI.
fix_direction:
  - Add valid coverage lists to the seven legacy summaries and correct 138-09/138-23 coverage syntax, mapping all 13 checkpoints to existing passing tests or automated lifecycle commands.
  - Add the self-contained Node router contract to the release-hygiene CI job.
  - Keep the already-recurring ExUnit matrix in the fast job and keep authenticated/current-source checks in the automatic GSD lifecycle hooks; do not duplicate either.
  - Reclassify all Phase 138 summaries and regenerate the UAT result so every checkpoint is automated.
files_involved:
  - .planning/phases/138-baseline-inventory-evidence-taxonomy/*-SUMMARY.md
  - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md
  - .github/workflows/ci.yml
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs
oracle_type: specified

