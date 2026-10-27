---
status: verifying
trigger: "Diagnose and coherently correct the new qualification ledger contract's four focused failures after local Main synchronization."
created: 2026-10-27T19:10:53Z
updated: 2026-10-27T19:42:23Z
---

## Current Focus

bug_class: bohrbug
hypothesis: SRC-10 occurs because the generic frozen-input reader passes malformed binary paths through to System.cmd without validating the argument boundary.
test: Completed pure RED/green/counterfactual and 42-path command-boundary controls; native focused source qualification is next.
expecting: All 26 native tests pass on a clean committed source while prior 25/0 proof remains bound to its earlier source.
next_action: Commit only the selected test and this journal, then execute one actual owned-source guard selecting the 26-test file.
reasoning_checkpoint:
  hypothesis: SRC-10 occurs because malformed binary manifest paths reach System.cmd without a validated repository-relative argument boundary, so NUL raises instead of returning a fixed rejection.
  confirming_evidence:
    - Independent immutable source/security review identifies the unguarded generic path-to-System.cmd boundary at the reviewed source.
    - The agent-authored adversarial regression is RED before the fix; its first NUL reader case is caught and rendered as a fixed Boolean assertion failure without diagnostic values.
  falsification_test: If any malformed path still invokes the Git boundary, raises, or lacks the fixed validation rejection, the correction is insufficient; the valid neighboring input must continue to resolve.
  fix_rationale: Reject malformed manifest paths before validation can perform Git operations, validate again at the reader boundary, and convert expected process-launch argument/system failures to :error without exposing diagnostics.
  blind_spots: Final-source focused native guard and boundary counterfactual remain pending; prior 25/0 proof and Python qualification remain bound to the old source.
  candidate_causes:
    - code: Missing manifest path validation allows forbidden argv bytes into System.cmd.
    - data: Adversarial control/non-relative/invalid-UTF-8 manifest path values violate the reader's input boundary.
    - environment: A missing Git executable could separately raise at process launch and must also fail closed.
  and_gate: yes; a malformed path and the missing validation boundary combine to produce SRC-10. Reject that input while preserving valid historical reads and all prior evidence.

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
- hypothesis: Missing historical Git objects caused the observed four positive failures.
  evidence: The original pure validator resolved all source identities and returned only the manifest error; the retained source resolves every external input, and both actual focused runs passed on full-history source checkouts.
  timestamp: 2026-10-27T19:22:28Z

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
- timestamp: 2026-10-27T19:22:28Z
  checked: Final actual focused guard at 9d526f145577e9bfaab93dfc6a4032174344443c.
  found: 25 tests, zero failures; test exit 0 and guard exit 0; exact source and clean checkout confirmed before/after. Owned database OID 38966 was created, independently identified, migrated, dropped, and independently confirmed absent. All 24 owned child process groups stopped. Manifest SHA-256 66f1868d1b3d232aeb0031bbc909b21fb33eaaadb10b3470a42a416303010950 at /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-owned-source-tests-cps_5nnf/manifest.json; test PID 82360 and session 24350 terminal. No raw child output retained or surfaced.
  implication: Original 22 assertions and the three new provenance/history tests all pass on the final consumer implementation. This focused run does not replace the caller's full qualification sequence.
- timestamp: 2026-10-27T19:22:28Z
  checked: Exact committed selected-source delta and retained immutable evidence.
  found: The baseline and tested selected closures both contain 1077 files, with no added/deleted inputs and exactly one changed file (the imported qualification consumer); the other 1076 hashes remain unchanged. Tested closure SHA-256 f96b825552342101dfe28edeceba3d8e1fed850306da8840debf4fd06c479759. Original ledger SHA-256 d4f790a7057ed967f105068631d44eae46d69fefc7013836b868c74121a403b7; original receipt SHA-256 be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39, matching its retained pin. Phase 175 frozen inputs 13/13 unchanged. Source proof /private/tmp/lockspire178-qualification-ledger-oddypgnm/source-proof.json SHA-256 7934ce0e7516398844149a3523cad7ea7c9fcf3665028bc6adf0a2a2914825d0.
  implication: The historical ledger, matrix identities, receipts, source-bound observations, current docs, and old selected inputs were preserved. No full Python suite, matrix, fresh freeze, or canonical CI was run in this bounded session.

## Resolution

root_cause: The frozen historical consumer reads mutable workspace input bytes, and later supported-surface documentation legitimately changed; no separate frozen-input snapshot identity was represented. The original qualification_sha predates final frozen inputs.
fix: Pin the retained final-input source, original ledger SHA-256, and ordered frozen digest inside the selected consumer; validate that provenance and resolve file/section inputs at the retained Git source while continuing to hash fixture projections from their supplied ledger. Add three tests for missing/wrong provenance, execution versus snapshot separation, and fail-closed missing objects. Original ledger, current documentation, receipts, and Phase 175 frozen inputs remain unchanged.
oracle_type: specified
verification:
  target_test: {result: pass, original_native: "22 tests, four failures", final_native: "25 tests, zero failures", tested_revision: "9d526f145577e9bfaab93dfc6a4032174344443c", guard_exit: 0}
  mutation_check: {result: skipped, reason: "No Stryker configured for Elixir; private source-boundary mutation separately reproduced the original error family."}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true, detail: "Workspace reads replaced with authenticated historical reads; original manifest, digest, case, receipt, and selector assertions retained."}
  adjacent_tests: {result: pass, suites_run: ["All original 22 contract tests plus three new provenance/history tests in the same 25/0 focused native run"], static_immutable_checks: "1076 other selected files unchanged; Phase 175 frozen inputs 13/13 unchanged"}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, mode: "private in-memory source-causal counterfactual; no filesystem reversion or DB startup"}
  guardrail_verdict: accepted
files_changed:
  - test/lockspire/qualification_ledger_contract_test.exs
  - .planning/debug/178-qualification-ledger.md

## SRC-10 Follow-up

review: Immutable /private/tmp/lockspire178-source8-6a-ledger-4g0yig7r/REVIEW.md at reviewed clean source 6a5a7689babd697d20c63c7f1dd16ce08e07e9fb identifies generic malformed paths reaching System.cmd.
root_cause: Binary/nonempty path checks did not enforce a valid repository-relative argv boundary; NUL could raise during process argument construction.
fix: Check manifest paths before entering validation that can invoke Git, guard the frozen reader with the same path contract, and return :error for expected ArgumentError/ErlangError process-launch failures. Reject C0/DEL, invalid UTF-8, empty/absolute/traversal/doubled-separator/backslash paths. Preserve all historical evidence and 25 existing test scenarios; add one adversarial test.
oracle_type: specified
pure_red: Agent-authored new test directly invoked with ExUnit compilation only, no application or database startup. Command shape was elixir -pa _build/test/lib/jason/ebin -e (compile private stdin source at the original test path; directly invoke the named new test; emit a fixed outcome). Actual pre-fix test source SHA-256 b63c7610c6b926e49436defa4d2416d7067919bc6fce303d3364a01e234271f2 returned fixed_assertion_red with process exit 0.
pure_green: Same pure scope/runtime and actual new-test invocation passes at selected source SHA-256 870e3b00a85c1035c8e631c2accaed7ada0bd0fb020d74dcda5ddd08ad5f23d4. Runtime observed Elixir 1.19.5, OTP release 28, four online schedulers. This does not substitute for the pending guarded native 26-test run.
counterfactual: Fixed/shared-path-guard-bypassed/fixed new-test outcomes pass/fixed_assertion_red/pass. Only private in-memory source was modified; repository source was not reverted. Proof /private/tmp/lockspire178-src10-aa94aera/pure-regression.json SHA-256 b1860227f161945e52ed7de0fa77d87c27109be692dcee60f651b2e005cf3d55.
command_boundary: Private evaluation replaced only the external System.cmd boundary with a fixed observer. All 42 invalid inputs returned :error before any command at the reader and returned the exact fixed reason before any command at the full validator. Both expected argument/system launch failures returned :error for valid input. Observer arguments/output were not surfaced.
digest_reconciliation: The earlier f96b825552342101dfe28edeceba3d8e1fed850306da8840debf4fd06c479759 used newline path-space-hash records and is a nonauthoritative preparation artifact. The authority recipe is sorted objects with path and sha256, encoded by json.dumps(rows, sort_keys=True, separators=(',', ':')). It independently reproduces the reviewers' 1077-row digest 82fcb59ab87e3ffdbe608f932e8969865cb3d97ff58e0a79e839d2cc878828fc at 6a5a7689babd697d20c63c7f1dd16ce08e07e9fb. The recipes differ; no canonical match is claimed for f96. Original proof/report files are preserved.
native_verification: pending
guardrail_verdict: pending
