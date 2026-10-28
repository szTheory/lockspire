---
status: awaiting_human_verify
trigger: "SRC-11: raw_root is allocated before tool-configuration rejection while its EXIT trap is installed later."
created: 2026-10-28T06:09:58Z
updated: 2026-10-28T06:19:26Z
---

## Current Focus

hypothesis: Early configuration exit leaks the owned empty raw_root; the draft regression additionally counts cumulative duplicate admission events instead of this invocation's unique process identities.
bug_class: bohrbug
test: Scope the source-backed regression to unique identities from this invocation; execute exact HEAD baseline without the early trap and then the restored draft under a pre-exec pinned parent process using the existing qualified collector.
expecting: Baseline fails the owned-directory-empty assertion; early-trap draft passes with status64 and one independently absent outer group, with no inner child or DB launch.
next_action: Commit exact two-file correction and this debug record; return clean ownership for one settled-commit full qualified Python run and author re-review/current1078 digest rebinding. Do not restamp prior278-test or immutable review evidence.
reasoning_checkpoint:
  hypothesis: raw_root mktemp precedes usage/required-tool exits, so only the late cleanup trap cannot remove that owned directory; the regression's global event count fails independently because supervisor.close rewrites its existing root witness.
  confirming_evidence:
    - Exact HEAD source allocates raw_root before tool validation and installs full EXIT cleanup much later.
    - Current tracked harness appends _record on both root admission and supervisor.close and keeps PROBE_RECORDS across cases; new assertion reads the entire global list.
  falsification_test: Exact baseline with a corrected source-backed oracle leaves no owned directory, or the early-trap draft still leaves an owned directory after status64.
  fix_rationale: Install owned-directory EXIT cleanup immediately after allocation, before chmod/configuration failure; later established full cleanup replaces it. Scope only the regression's event accounting, preserving the strict directory/status/closure assertions.
  blind_spots: Earlier worker's assertion categories/source lines were not trustworthy and its dropped full-class session has no retained outer identity or handle; no historical source/closure inference is possible.
  candidate_causes:
    - code: late EXIT trap and cumulative duplicate admission counting
    - config: rejected timeout or required tool before full trap installation
  and_gate: yes for the leak; owned-directory allocation plus a pre-full-trap configuration exit is required. The duplicate-witness test failure is independent.

## Symptoms

expected: Every validation exit after private-directory allocation removes exactly that owned empty directory, preserving native exit64 and launching no runtime child or database work.
actual: Independent current-source review identifies a pre-child empty0700 directory leak. Prior worker reported assertion failures but retracted exact line/leftover attribution.
errors: Prior known assertion count only; current static regression counts duplicate/cumulative identity events.
reproduction: Actual wrapper with a private TMPDIR and invalid LOCKSPIRE_PROOF_TEST_TIMEOUT_SECONDS.
started: Exact baseline cd975d1d7ec5040ce28e2622eabf8304f0c7f59c; inherited draft wrapper5f041f7dfdf0f08d1bbebd1b51afa642e2dbb88673307f64aca18ed7f72a72a7 and testc8a0559d9e68f27f717dfe163b3ce1de9f086be15be057dcf8829c36abc2ed58.

## Eliminated

## Evidence

- checked: Exact owned dirty diff and current test/harness source.
  found: Only inherited early EXIT cleanup and new invalid-config case/extra_env seam differ from HEAD. New case asserts one cumulative admission event; close() re-emits the same already-owned root witness.
  implication: Fix this test accounting before assigning any new live failure to product cleanup.
- checked: Prior qualified collector/launcher sources.
  found: Existing immutable private collector uses source-authenticated IDs and SafeResult without formatting exceptions/subtest params. Reuse it; do not create another result framework.
  implication: A narrow adapter can add only dynamic known-source traceback line/category fields, with unknown streams kept in RAM.
- checked: Actual fresh exact-baseline target under the corrected oracle.
  found: One test, one assertion failure, zero errors/skips; dynamically extracted known source test/acceptance/client_admin_failure_transport_test.py line294 is the owned-directory-empty assertion. Baseline wrapper6297620f8d605987fd820fa60367f86214215359cdaebb0465221cc47129180a and test e79d18bf886908f02bee54d3606ff600834b68050eae6c8aa6ad17d67fea4cb6 stayed unchanged. Qualified collector protocol valid, raw stderr0. Outer test94742/PGID94742/SID94742/start[1793167988,850438] was durably pinned before target exec and confirmed absent; wrapper94743/start[1793167988,937504] independently absent/kernelerrno3. Actual terminal record /private/tmp/lockspire178-src11-4ajab5_b/baseline-terminal.json.
  implication: Fresh source-attributed RED proves the early directory leak; no old worker assertion/line/closure attribution is used.
- checked: Actual same-target early-trap draft.
  found: One test, zero failures/errors/skips; protocol valid and source unchanged. Wrapper5f041f7dfdf0f08d1bbebd1b51afa642e2dbb88673307f64aca18ed7f72a72a7, test e79d18bf886908f02bee54d3606ff600834b68050eae6c8aa6ad17d67fea4cb6. Outer94887/start[1793168024,857393] durably pinned before target exec and absent; wrapper94889/start[1793168024,936348] independently absent/kernelerrno3. Status64, fixed usage, empty owned directory and one unique invocation-local group all passed. Terminal record /private/tmp/lockspire178-src11-4ajab5_b/draft-terminal.json.
  implication: Restoring only the early trap fixes the fresh baseline leak. The corrected harness no longer mistakes close-time duplicate witnesses or preceding controls for a nested launch.
- checked: Actual affected class, exec session38318 retained through terminal.
  found: Dynamic13 discovered/run; failures/errors/skips/expected failures/unexpected successes/loader errors/unknown-ID events all0; protocol valid and both source hashes unchanged. Thirty wrapper controls,60 inner groups independently absent/kernelerrno3; outer95002/start[1793168056,921839] durably pinned before collector exec and independently absent. Terminal /private/tmp/lockspire178-src11-4ajab5_b/focused-terminal.json SHAe804a440e3a27091d4f01534ce7778404c49147bcb1049f69cb318c72aa7edfa. Baseline/draft terminal hashes3ad7c310f99f49a943d4ac2aa30edfc502b079bb877b845fcbc7e782d76a41e1 and3978e96a4b15bc7bdc93bc92fb63e2727b4be611ac9974afdac039ebfbfef4cd.
  implication: All65 newly owned groups across baseline, draft, and focused controls are reconciled; the historical discarded invocation remains UNKNOWN.
- checked: Final static and metadata custody checks.
  found: bash -n, test/embedded Python compile, scoped git diff --check pass. No source/ownership/protocol logic beyond the immediate early trap and invocation-local unique-identity test accounting changed. Qualified collector SHA0df252abbd0435584ddc94ab3e94634d997a4dce593bc75ba6ae4704366c1f4e was reused; no test/error/subtest values were formatted or retained.
  implication: Scoped correction is ready for a local commit and independent author/full-Python continuation; no broad gate has run at these new bytes.

## Resolution

root_cause: Owned raw_root allocation preceded configuration rejection, while EXIT cleanup was installed only later. The new regression independently counted cumulative duplicate admission events rather than this invocation's distinct factory identities.
fix: Install exact-owned-directory EXIT cleanup immediately after allocation and before chmod/config validation; established full cleanup replaces it later. Scope the regression to current invocation records and deduplicate immutable process identities, preserving strict64/usage/directory-empty/no-nested-launch checks.
verification:
  target_test: {result: pass, tests: 1, native_status: 64}
  mutation_check: {result: skipped, reason: No Python Stryker; exact baseline counterfactual detects the leak}
  no_op_deletion: {result: pass, rationale: Additive early cleanup; existing runtime/TERM/native-exit/schema/capture/cleanup authority unchanged}
  adjacent_tests: {result: pass, tests: 13, wrapper_controls: 30, inner_groups_absent: 60, parent_group_absent: true}
  revert_and_reconfirm: {result: pass, baseline_assertion_line_dynamically_observed: 294, baseline_failures: 1, restored_failures: 0}
  guardrail_verdict: accepted
  qualification_limit: One full qualified Python run at the settled commit is still required; cd975278-test evidence remains historical
files_changed: [scripts/ci/run_host_integration_proof.sh, test/acceptance/client_admin_failure_transport_test.py, .planning/debug/178-src11-early-cleanup.md]
oracle_type: specified

Permanent limits: The previous worker discarded a nonempty exec session handle for a full-class invocation. No outer PID/start/handle or reliable terminal result/closure exists. Its outcome and process closure remain UNKNOWN; finite inner test durations do not prove absence. No guessed-PID probe, global process scan, signal, or retrospective enrollment is authorized. Earlier Group4 unknown closures and hosted minimum browser_0 cause remain UNKNOWN. Root PG1307/privatePG54547 and private Hex resources are unrelated and untouched.
