---
status: verifying
trigger: "Diagnose and coherently correct the new qualification ledger contract's four focused failures after local Main synchronization."
created: 2026-10-27T19:10:53Z
updated: 2026-10-27T19:21:07Z
---

## Current Focus

bug_class: bohrbug
hypothesis: Frozen Phase 171 input identities are compared with mutable workspace files, so a later supported-surface documentation change invalidates historical evidence.
test: Bind the unchanged ledger and digest to the verified retained Git snapshot; compare source-based versus workspace-based hashing without database startup.
expecting: The source-based consumer accepts the unchanged historical inputs and still rejects invalid provenance and mutated hashes; restoring workspace hashing recreates the original error family.
next_action: Commit the final actionable-history diagnostic and debug evidence, then rerun the same 25-test owned-source guard on the final clean source.
reasoning_checkpoint:
  hypothesis: The historical frozen manifest fails because input_entry_hash reads today's supported-surface bytes rather than the retained frozen input snapshot.
  confirming_evidence:
    - The unchanged test-owned pure validator returned exactly one known error, at original test line 1141; zero unknown errors.
    - Exhaustive 33-entry comparison found only docs/supported-surface.md differed; the manifest digest and both planning selectors matched.
    - All 28 external file/selector inputs match at retained Main 173059a166e9ade0f5f57c9980b7b2400a98538c, whose ledger bytes and frozen digest are unchanged.
  falsification_test: If source-based reads still produce the same frozen-manifest error, or workspace-only hashing no longer produces it, this proposed cause is insufficient.
  fix_rationale: Resolve retained historical file identities at an explicitly authenticated historical source, preserving the original ledger, observations, receipts, frozen hashes, and fixture mutation checks.
  blind_spots: Native focused execution remains pending; no broader current-source qualification is claimed. Original qualification_sha predates the final frozen input bytes and cannot be used as the snapshot anchor.
  candidate_causes:
    - code: The frozen consumer uses workspace file reads without a separate retained-input source identity.
    - data: Frozen ledger input hashes or ordered digest were corrupted during synchronization.
    - environment: Missing historical Git objects prevent resolution of qualification or case identities.
  and_gate: yes; the consumer's missing epoch boundary and a legitimate later supported-surface change co-occur. Fix the epoch boundary while retaining the later document and all original evidence.

## Symptoms

expected: The retained historical Phase 171 qualification ledger validates without asserting current-source requalification.
actual: The newly imported focused contract repeatedly runs 22 tests with four positive-validation failures.
errors: Exact error families pending; raw assertion values and child output deliberately withheld.
reproduction: Existing owned-source guard selects test/lockspire/qualification_ledger_contract_test.exs; prior actual native runs returned 22 tests, four failures, test exit 2, guard exit 1.
started: Following the local Main synchronization which imported this selected test file; all previous 1076 selected source files retained their bytes.

## Eliminated

- hypothesis: Restoring only the historical requirements and roadmap sections fully resolves the failure.
  evidence: Actual focused runs at e28bc00fd6bdc3931c8b1692845afb1e90c4bd22, 3eef126a5f89c38f00c156d152455010fbba81fe, and b3343d4de2692352c77d32988216c285ec28b072 each still reported 22 tests and four failures.
  timestamp: 2026-10-27T19:10:53Z
- hypothesis: The original matrix qualification_sha is the frozen-input snapshot source.
  evidence: Its supported-surface hash is 078b723ec78a7005bf76633ca5fe47c2a7504b203a5c9a87de366a31f876c6bb, which differs from the retained 2cd32dee2d0bf1bcc301c26afeea634698e7b0b4a44ee55cf15204705d6f4471 input.
  timestamp: 2026-10-27T19:13:19Z
- hypothesis: Ledger hashes or ordered digest were corrupted during synchronization.
  evidence: The synchronized Main snapshot contains identical ledger bytes and input digest; every external input matches at that snapshot and all five in-ledger projections match now.
  timestamp: 2026-10-27T19:13:19Z

## Evidence

- timestamp: 2026-10-27T19:10:53Z
  checked: Entire imported qualification contract and its validation call graph.
  found: The four reported positive failure sites load the frozen ledger. Positive draft fixtures bypass frozen input checks. The contract independently validates baseline receipts, profiles, cases, probes, frozen selectors, and raw input files.
  implication: Enumerate every frozen predicate before another native database run; shared frozen validation is the bounded initial candidate.
- timestamp: 2026-10-27T19:10:53Z
  checked: Knowledge-base fallback and per-test coverage availability.
  found: No matching qualification-ledger knowledge-base entry; no per-test coverage spectrum supplied for this failure.
  implication: No semantic memory tool available; no SBFL ranking. Use deterministic private reproduction and source-identity differential testing.
- timestamp: 2026-10-27T19:13:19Z
  checked: Actual pure validator, exhaustive workspace manifest predicates, and retained-source historical blobs.
  found: Pure evaluator process exit 0; one known error at original source line 1141; zero unknown errors. Workspace 32/33 entries match, all five projections match, ordered digest matches. Retained source 173059a166e9ade0f5f57c9980b7b2400a98538c satisfies all 28 external entries.
  implication: Confirmed code/data epoch mismatch. Current docs are not substituted into historical evidence and historical hashes must not be refreshed.
- timestamp: 2026-10-27T19:13:19Z
  checked: Immutable Phase 175 frozen inputs and CI historical-object availability.
  found: All 13 Phase 175 frozen inputs match their original SHA-256 pins. Canonical source CI checks out full history, and the existing validator already depends on historical commits.
  implication: No Phase 175 edit or new historical-object environment assumption is required.
- timestamp: 2026-10-27T19:17:18Z
  checked: Final source-only provenance pinning, current closure, historical-object CI setup, and source-causal private counterfactual.
  found: Provenance pins reside inside the centrally selected consumer; no extra sidecar exists. Current closure remains exactly 1077 files and authenticates that consumer. Fast and minimum CI checkouts already use fetch-depth 0. Original/fixed/workspace-boundary-counterfactual/fixed evaluators returned known-error counts 1/0/1/0, respectively; all processes exited 0 and unknown errors remained 0.
  implication: The fix changes the historical/current boundary without weakening manifest comparisons or expanding the closure. Pure diagnostics are not native test qualification.
- timestamp: 2026-10-27T19:17:18Z
  checked: Final bounded diagnostic proof and formatting.
  found: Proof /private/tmp/lockspire178-qualification-ledger-p8fm6vii/diagnostic.json has SHA-256 9dd4fd38a0d4265133c3e9a56417d4f1ad56165dc778ce9c56bdbfa5e1f843e6. Final selected consumer SHA-256 is 0d182480d4872ee6ce83e2f680fb5e69670ff0749b6001ad640ead24b95593e8. Formatting and scoped whitespace checks returned exit 0. Earlier implementation diagnostic proof remains retained separately and is not represented as final-source qualification.
  implication: Ready for a clean local commit and the smallest actual owned native run; full Python/matrix/native-CI qualification remains pending with the orchestrator.
- timestamp: 2026-10-27T19:20:28Z
  checked: First actual focused owned-source guard after local fix commit 8b3195faed43558b717a8a68c5c8834663bb317c.
  found: 25 tests, zero failures; test exit 0 and guard exit 0; exact source and clean checkout confirmed before/after. Owned database OID 38634 was created, independently identified, migrated, dropped, and independently confirmed absent. All 24 owned child process groups stopped. Manifest SHA-256 78f1505dc28a738d852b657b7fa26fc4943d4af6033161d1ea4461ae76206f7d at /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-owned-source-tests-b7un_67_/manifest.json; test PID 54956 and session 38295 terminal.
  implication: Functional correction verified on 8b3195fa. A caller-requested actionable missing-history diagnostic remains to be added; this first run will not be restamped for the later revision.
- timestamp: 2026-10-27T19:20:28Z
  checked: Optional launcher liveness probe before the first actual guard launch.
  found: A signal-zero PID query was denied by the sandbox before guard import or any database/child creation. The unnecessary query was removed; the actual guard used its existing exact private-target preflight.
  implication: No source test or database attempt occurred in that launcher preflight failure, and no foreign resource was touched.
- timestamp: 2026-10-27T19:21:07Z
  checked: Final actionable missing-history diagnostic and private source-causal recheck after that source edit.
  found: The consumer now returns a fixed message instructing use of a full-history checkout (fetch-depth 0) when the retained object is missing, without raw Git stderr or workspace fallback. The existing missing-source test asserts that message; total test definitions remain 25. Local qualification requires full Git history; fast/minimum CI already provide it. Final consumer SHA-256 a827ea95bf0a5c7b5e2fb06675c3f5711a4dd81764849c1bde7e1d8bf4b43e60; private original/fixed/workspace-counterfactual/fixed counts remain 1/0/1/0, zero unknowns. Proof /private/tmp/lockspire178-qualification-ledger-gg05ovc6/diagnostic.json SHA-256 ed9d77a61f22f134f3823163c915cf7d430b5db09b984608dea93b605f422e28. Format check exit 0; closure 1077; Phase 175 frozen inputs 13/13 unchanged.
  implication: Earlier diagnostic and native proofs remain bound to their prior source epochs. Final-source native qualification is next.

## Resolution

root_cause: The frozen historical consumer reads mutable workspace input bytes, and later supported-surface documentation legitimately changed; no separate frozen-input snapshot identity was represented. The original qualification_sha predates final frozen inputs.
fix: Pin the retained final-input source, original ledger SHA-256, and ordered frozen digest inside the selected consumer; validate that provenance and resolve file/section inputs at the retained Git source while continuing to hash fixture projections from their supplied ledger. Add three tests for missing/wrong provenance, execution versus snapshot separation, and fail-closed missing objects. Original ledger, current documentation, receipts, and Phase 175 frozen inputs remain unchanged.
oracle_type: specified
verification:
  target_test: {result: pending, original_native: "22 tests, four failures"}
  mutation_check: {result: skipped, reason: "No Stryker configured for Elixir; private source-boundary mutation separately reproduced the original error family."}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true, detail: "Workspace reads replaced with authenticated historical reads; original manifest, digest, case, receipt, and selector assertions retained."}
  adjacent_tests: {result: pending, suites_run: []}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, mode: "private in-memory source-causal counterfactual; no filesystem reversion or DB startup"}
  guardrail_verdict: pending
files_changed:
  - test/lockspire/qualification_ledger_contract_test.exs
  - .planning/debug/178-qualification-ledger.md
