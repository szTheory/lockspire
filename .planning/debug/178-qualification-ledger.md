---
status: awaiting_human_verify
trigger: "Diagnose and coherently correct the new qualification ledger contract's four focused failures after local Main synchronization."
created: 2026-10-27T19:10:53Z
updated: 2026-10-27T20:06:56Z
---

## Current Focus

bug_class: bohrbug
hypothesis: Canonical CI stops after architecture because Credo EX3033 rejects frozen_section_hash's single-clause with/else at source line 1526.
test: Replace only that expression with the equivalent case, then run the exact Credo wrapper, formatter, and existing pure historical/SRC-10 controls before committing and executing one clean focused native guard.
expecting: Credo changes from exit 4 to exit 0 while successful section hashing and failure nil remain identical and all 26 native tests pass.
next_action: Commit this metadata-only final record and return the caller the clean current source and terminal witnesses for independent review, refreeze, and later canonical CI.
reasoning_checkpoint:
  hypothesis: The single-clause with plus else in frozen_section_hash triggers the configured Credo WithSingleClause rule, blocking canonical CI before later tests can run.
  confirming_evidence:
    - At clean 16c the exact canonical scripts/ci/run_credo.sh exited 4 and identified only the selected test at line 1526.
    - Source line 1526 has one pattern clause and an else branch; the installed Credo EX3033 implementation explicitly flags exactly this construct.
    - mix.exs places Credo immediately after the completed architecture section, matching the failed canonical CI's 15/0-only completed counts.
  falsification_test: If the same exact Credo wrapper still rejects the equivalent case, this attribution is incomplete; if behavior controls change, the rewrite is not equivalent.
  fix_rationale: A case expresses exactly the same successful byte hashing and wildcard nil result while satisfying the existing static gate without suppression or relaxed validation.
  blind_spots: Final full canonical CI requires a later reviewed/frozen source epoch and remains with the caller; its discarded logs are neither reconstructed nor tailed.
  candidate_causes:
    - code: The helper's single-clause with/else violates Credo EX3033.
    - config: The intended strict Credo configuration enforces the readability rule and must remain unchanged.
    - environment: Parse timeout or unavailable tooling could separately fail Credo, but the actual diagnostic identifies the concrete source line instead.
  and_gate: no; the identified construct is sufficient to trigger the established configured rule, independently of runtime data.

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
native_verification: Actual owned-source guard at 19f804061f5964e179e66a41f354339e2e4b6992 passed 26 tests with zero failures, test exit 0 and guard exit 0. Source and clean checkout matched before/after. Owned database OID 39298 was created, independently identified, migrated, dropped, and independently confirmed absent. All 24 child process groups stopped. Test PID 73765 and session 45411 terminal. Manifest /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-owned-source-tests-5h2sh3nx/manifest.json SHA-256 a796edeb3d54135814c2e50fe888ac05f52855df088d6c6959a61fbde3bd27ae. No manually assembled Mix test command, foreign database, remote write, or global toolchain change was used.
preserved_tests: AST comparison of all 25 prior test bodies at 6a5a7689babd697d20c63c7f1dd16ce08e07e9fb with the 26-test corrected file found all 25 unchanged; only the adversarial regression was added.
canonical_source_proof: At 19f804061f5964e179e66a41f354339e2e4b6992 the 1077 sorted native path/sha256 row objects have authoritative canonical JSON digest 2d0a647239c63758ac13892aa125fc3e3821f8fd517df3108a60359711f038d6. Exactly the selected consumer changed relative to 6a; other 1076 hashes unchanged, zero added/deleted paths. Consumer SHA-256 870e3b00a85c1035c8e631c2accaed7ada0bd0fb020d74dcda5ddd08ad5f23d4. All 13 Phase 175 frozen inputs unchanged. Proof /private/tmp/lockspire178-src10-_wmywl_4/source-proof.json SHA-256 57254128e0b44a9ea25c37ca5d4e6470f1d7171852cd808e71f4bf27d58f071b.
guardrail_verdict: accepted; actual target/adjacent 26/0, original 25 tests preserved, no behavior deleted for valid paths, pure path-guard bypass killed by the new regression and fixed reapplication passes. Stryker remains unavailable for Elixir; the private source-causal mutation is separately recorded rather than presented as Stryker.
limits: Prior native 25/0 and full Python 263/0 remain historical at their actual sources. This SRC-10 lane ran no full Python, canonical CI, package proof, network fetch, or full matrix. Caller must freshly review all 1077 canonical rows before freezing and broader qualification; final human confirmation and archival remain pending.

## Canonical CI Credo Follow-up

failed_canonical_source: 16c66c8ae6064846d918d9642f78ac0857424b41, clean; actual completed architecture counts 15/0 only. Failed session 86972/PID 8244 was terminal with independent owned database absence and all 22 groups absent, per caller custody. Original manifest /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-owned-source-tests-3p4o979l/manifest.json SHA-256 2103fdcf7bc0b44054be4a29cfa437774940db7fa0b27ad663234da214e63a21 and custody /private/tmp/lockspire178-ci16c-9qq9uzmu/terminal-custody.json SHA-256 3a1f844980047a52ecb3c45c6f86f95559252f91dde9b0df8ed7bda7b282ba9a remain untouched. Discarded canonical raw logs were not reconstructed or tailed.
actual_red: The one source-indicated read-only diagnostic used the exact canonical command [bash, scripts/ci/run_credo.sh] under the selected private environment and MIX_ENV=test, without application/database/test/CI startup. It exited 4; selected file line 1526; stdout 665 bytes SHA-256 19818b30e76818e2fa7bee6a0af1efb5d6769c25b7f1da723c514d3b6bb60f3d, stderr 0 bytes. Raw diagnostics stayed in memory and were discarded. Session 11134/PID 13863 terminal; owned process group stopped.
root_cause: Credo.Check.Readability.WithSingleClause (EX3033) flags the one <- plus else in frozen_section_hash. Canonical alias order is formatter, warnings-as-errors compile, architecture, Credo, then Sobelow; this blocker precedes later CI sections.
authorized_fix: Coordinator explicitly authorized only an equivalent case over frozen_source_file, retaining {:ok, bytes} hashing and wildcard nil. No suppression, dependency, configuration, validation, or unrelated refactor is selected.
actual_static_green: Exact canonical [bash, scripts/ci/run_credo.sh] exit 0, PID 17114, process group stopped; stdout 317 bytes SHA-256 243ecd4bb41dd311bf9fa3423356ee93f7e72c5b29b4ce7e60bbc458dd925688, stderr 0 bytes. Full canonical [mix, format, --check-formatted] exit 0, PID 17115, process group stopped, stdout/stderr 0 bytes. All output remained in memory.
behavior_controls: Five actual existing historical/SRC-10 test functions passed in pure ExUnit compilation/direct invocation with no application/database startup. Previous with and current case return equal successful section hashes and nil for unavailable/malformed input controls. Selected consumer SHA-256 ae27e1ba29ad9c8b3cece357c89fd06d8ea6ed853d60202af2196ffe303dd2d4.
verification: Static gate RED exit 4 to GREEN exit 0 confirmed; formatter and five existing behavior controls pass. One actual clean owned-source guard passed 26 tests, zero failures, test exit 0 and guard exit 0 at 8a90a0a833a25d5a6b5f6af6525ba818e577df61. Exact source and clean checkout were confirmed before/after. Owned database OID 39962 was created, independently identified, migrated, dropped, and independently confirmed absent. All 24 child groups stopped. Test PID 18332 and session 44571 terminal. Manifest /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-owned-source-tests-z0me6vyk/manifest.json SHA-256 43de64d532b136633d7e4041a17ba26c6e7b799b6fa8847336c929571ee81f3c.
source_identity: Current canonical sorted path/sha256 JSON row digest f0b319d52ed30e640029ce983283d2fee4809aad9a3addacb1e7dac05aad5900 across 1077 selected files. Only the selected test changed from failed 16c; 1076 hashes unchanged, no added/deleted selected paths. Consumer SHA-256 ae27e1ba29ad9c8b3cece357c89fd06d8ea6ed853d60202af2196ffe303dd2d4. All 13 Phase 175 frozen inputs unchanged. All 26 test scenarios were preserved; selected diff was exactly two insertions/three deletions in frozen_section_hash.
scope_boundary: No failed canonical log was reconstructed or tailed; original failed CI/custody and historical freeze records remain untouched. No full CI retry, package run, matrix, dependency, suppression, architecture change, or validation relaxation occurred. Fresh current-source review/refreeze and canonical CI remain with the caller; focused success is not restamped as canonical CI success.
