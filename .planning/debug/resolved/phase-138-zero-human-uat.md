---
status: resolved
trigger: "Phase 138 UAT produced 13 manual checkpoints, while the project goal is zero human verification through shift-left integration, E2E, smoke, and selectively recurring CI coverage."
created: 2026-09-12T19:35:13.689Z
updated: 2026-10-05T22:34:03Z
---

## Current Focus

hypothesis: Confirmed — later summary coverage syntax caused false UAT presentation, and overlapping release-hygiene steps ran the router suite twice.
test: Completed supported coverage classification, isolated original-byte replay, focused prohibition contract, portable Node suite, workflow lint, UAT count assertions, and diff check.
expecting: Met — 105 automated coverage entries, one truthful historical human entry, zero schema errors, one router CI invocation, zero new human UAT checkpoints.
next_action: Resolved and archived; Phase 140/141 retains the deferred live snapshot refresh.
bug_class: workflow-coverage-gap
reasoning_checkpoint:
  hypothesis: "Later summary coverage metadata uses unsupported field/kind shapes, causing four entries to be presented; the CI step added after plan 138-34 repeats the router file already included in the portable lifecycle invocation."
  confirming_evidence:
    - "The supported classifier reports missing_id/missing_description/invalid_kind on exactly 138-37 and 138-38; their summaries cite passing focused owner contracts."
    - "Current ci.yml names the command-router test in both a standalone node --test step and a combined portable lifecycle node --test step."
    - "138-38 and UAT #101 record resolved judgments with a passing six-test contract; 138-36's earlier human_judgment=true remains historically accurate."
  falsification_test: "If post-edit classification still reports schema errors or the remaining CI command does not execute the router suite, this diagnosis or repair is incomplete."
  fix_rationale: "Schema-compatible metadata exposes existing proof without changing evidence claims; removing one redundant CI step keeps one router run and the lifecycle run."
  blind_spots: "Live GitHub/current-snapshot #100 is deferred to Phase 140/141 and cannot be counted as a pass here; delegated policy judgments are not machine-proven enforcement."
  candidate_causes:
    - "data: 138-37/38 coverage frontmatter uses legacy keys and unsupported kinds."
    - "config: release-hygiene CI accumulated overlapping node --test invocations."
  and_gate: "No for each failure: schema errors and duplicate execution occur independently; the historical human judgment is a separate resolved policy decision."

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
- timestamp: 2026-10-05T22:28:17Z
  checked: Supported uat.classify-coverage query over all current Phase 138 summaries
  found: 38 summaries declare 106 deliverables; 101 auto-pass, five are presented, and twelve schema errors are limited to 138-36 through 138-38.
  implication: The 138-34 closure was valid for its earlier 33-summary state, but newer summaries reopened deterministic coverage classification.
- timestamp: 2026-10-05T22:28:17Z
  checked: Current Phase 138 UAT and release-hygiene CI job
  found: UAT now records 101 tests, 100 passes, one automated skip for stale live snapshot, and no issue/pending/blocked result. CI invokes the command-router test in both a standalone step and the portable lifecycle step.
  implication: Preserve the dated snapshot's stale status; remove duplicate CI execution and regenerate only UAT entries whose new summary coverage can be proven.
- timestamp: 2026-10-05T22:29:17Z
  checked: 138-35 through 138-38 summaries, 138-VERIFICATION, and UAT #101
  found: 138-35 auto-classifies. 138-36's single human-judgment entry was truthful when 108 claims were pending. 138-37/38 have four schema-invalid coverage rows. Plan 138-38 later recorded 10 evidence-backed and 98 delegated maintainer-affirmed claims; the current verifier passed 7/7 and UAT #101 passed via the focused six-test closure contract.
  implication: Repair only coverage syntax in 138-37/38; preserve 138-36's historical human state and the final ledger's distinction between judgment/UNVERIFIED and test/ENFORCED.
- timestamp: 2026-10-05T22:31:13Z
  checked: Post-edit classifier, portable CI Node invocation, workflow lint, and diff whitespace
  found: All 38 summaries classify with 106 total, 105 automated, one historical human-presented entry in 138-36, and zero errors. The remaining single CI invocation passed 18 tests, failed zero, and intentionally skipped two installed-runtime cases; workflow lint and git diff --check passed.
  implication: Coverage syntax and CI duplicate are corrected; UAT needs a current source/reconciliation note but no outcome promotion.
- timestamp: 2026-10-05T22:32:56Z
  checked: Focused prohibition closure contract and UAT structural counts
  found: The Phase 138 prohibition contract passed 6 tests, 0 failures. UAT now cites 38 summary sources and retains 101 checks: 100 passes, one automated skip, zero human sources, and fourteen resolved gap records; the CI YAML contains one command-router node --test invocation.
  implication: The resolved claim ledger remains executable and the UAT reconciliation changes no outcome or deferred live-source decision.
- timestamp: 2026-10-05T22:34:03Z
  checked: Isolated replay of committed pre-fix 138-37/38 bytes and CI YAML
  found: Original 138-37 classified zero automated/two presented/eight errors; corrected classifies two automated/zero presented/zero errors. Original 138-38 classified zero automated/two presented/four errors; corrected classifies two automated/zero presented/zero errors. Original CI invoked the router test twice; corrected CI invokes it once.
  implication: The scoped edits directly eliminate the newly introduced schema and duplicate-execution defects; the original historical 138-36 judgment remains presented by design.

## Resolution

root_cause: The original thirteen manual checkpoints came from legacy or invalid coverage metadata and were closed by Plan 138-34. Subsequent Plans 138-37/38 introduced four schema-invalid coverage entries, and a later portable lifecycle CI step duplicated the already recurring router invocation. Plan 138-36's human-judgment entry accurately records its earlier pending state; Plan 138-38 later resolved that policy work through delegated maintainer outcomes, not automated enforcement.
fix: Repaired only 138-37/38 coverage frontmatter to use supported IDs, descriptions, and verification kinds while preserving their evidence prose and claim outcomes; removed the standalone duplicate router CI step; updated UAT sources and added a current reconciliation note without changing outcomes.
verification:
  target_test: {result: pass, evidence: "38 summaries; 106 deliverables; 105 automated, one historical presented, zero classifier errors"}
  mutation_check: {result: skipped, reason_if_skipped: "No Stryker configuration or package manifest exists for these Markdown/YAML changes", mutant_killed: null}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true, evidence: "Only deleted CI hunk was the proven duplicate router invocation; the combined router/lifecycle invocation remains"}
  adjacent_tests: {result: pass, suites_run: ["portable Node router/lifecycle 18 passed, 2 intentional skips, 0 failed", "Phase 138 prohibition contract 6 passed, 0 failed", "workflow lint passed", "git diff --check passed"]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, evidence: "Isolated original-byte replay reproduced 8+4 classifier errors and two CI router invocations; corrected bytes yield zero errors and one invocation"}
  guardrail_verdict: accepted
  uat_receipt: "101 tests: 100 automated passes, one automated deferred snapshot skip, zero human sources; no new conversational UAT"
  limitation: "138-36:D1 remains historically human-presented; the 2026-08-28 immutable snapshot remains stale and is deferred to Phase 140/141"
files_changed:
  - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-37-SUMMARY.md
  - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-38-SUMMARY.md
  - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md
  - .github/workflows/ci.yml
  - .planning/debug/resolved/phase-138-zero-human-uat.md
oracle_type: specified

## Blameless Postmortem

why_not_caught: The phase-wide coverage classification from Plan 138-34 was not repeated when Plans 138-37 and 138-38 added summaries, and a later CI addition overlapped the router invocation.
guard: The current 38-summary classifier receipt and UAT reconciliation record zero schema errors; the release-hygiene job runs the router test once through its combined portable lifecycle command.
