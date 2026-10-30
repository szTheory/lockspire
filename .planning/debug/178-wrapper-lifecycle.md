---
status: awaiting_human_verify
trigger: "SEC-178-06 actual-wrapper nested-session leak and SEC-178-09 final paths/checkout relation"
created: 2026-10-27T00:00:00Z
updated: 2026-10-27T00:00:00Z
---

## Current Focus

hypothesis: Wrapper stops the root before registered nested-session cleanup completes; helper cleanup also lacks time import/reaping.
bug_class: Bohrbug with deterministic signal ordering trigger
test: Actual wrapper with registered child that ignores TERM before readiness.
expecting: Pre-fix wrapper fails bounded cleanup and nested child remains alive.
next_action: Independent security re-review must personally repeat affected actual-wrapper probes and final-path/frozen-consumer boundaries; do not self-close ledger, freeze, run canonical CI or package proof.
reasoning_checkpoint:
  hypothesis: Root KILL at two seconds interrupts registered child cleanup before three-second TERM grace completes; missing time import and missing post-KILL reap independently prevent verified escalation.
  confirming_evidence:
    - Actual wrapper timeout and external TERM regressions fail with strict expected exit/group-absence oracle; helper branch fails before group absence verification.
    - Auditor independently reproduced exact actual-wrapper leakage; source deadlines establish deterministic causal ordering.
  falsification_test: With only import/reap corrected, the actual wrapper should still leak because two-second root deadline precedes three-second child grace; with coordinated bounded cleanup plus explicit registry, original regressions should pass.
  fix_rationale: Preserve independent custody of every registered nested session, give existing ten-second rollout cleanup time to finish, reap killed children and verify all exact owned groups absent before reporting cleanup.
  blind_spots: Unregistered child sessions remain outside the declared start_owned_session ownership API; OS permission failure must retain safe custody and exit 125.
  candidate_causes:
    - code: missing import, leader reap and wrapper root-only custody
    - config: root grace shorter than nested session cleanup bounds
    - environment: group signalling/probe permission denial
  and_gate: yes; separately sessioned TERM-ignoring child plus shorter wrapper root deadline causes orphaning, while missing import is an independent escalation failure.

## Symptoms

expected: Actual wrapper timeout and external TERM stop every registered nested session and verify group absence; final locked/floor exact paths are accepted with independent frozen pins and compatible checkout relation.
actual: Auditor observed wrapper exit 125 with registered child alive; final paths rejected; metadata-only checkout rejected.
errors: Missing time import on escalation branch; unconfirmed cleanup.
reproduction: Fake runner calls start_owned_session with separate child session installing SIGTERM ignore before readiness; invoke actual wrapper timeout/external TERM.
started: Present before dedicated diagnosis at clean HEAD 5b6a6e9d.

## Eliminated

## Evidence

- checked: Knowledge base and project skill configuration
  found: No matching prior resolution; no configured debugger skills returned.
  implication: Investigate current implementation directly; no prior resolution assumed.
- checked: package_input.py imports and stop_process_group; actual wrapper stop_group
  found: Missing time import; stop_process_group waits leader without post-KILL reap; wrapper gives root two seconds before KILL, while nested child grace alone is three seconds.
  implication: Separate deterministic causes can combine under TERM-ignoring child; root-only group absence cannot establish nested-session absence.
- checked: Agent-authored native unittest reproduction before source edits
  found: Three tests executed and all failed; complete fixed-message checker record retained at 178-10-wrapper-lifecycle-native-red.json (stderr SHA256 0226cffc7954c3eabb0ba3a6ec5f02713e6ff471b323026e704da80eef5b6ed9).
  implication: Reproduction reaches actual timeout, external TERM with two children, and post-KILL missing-time branch. Exact probe-owned groups were killed from predeclared identity files.
- checked: SBFL and shrink availability
  found: No per-test coverage or Hypothesis configured; manually minimized three subprocess/helper controls.
  implication: SBFL skipped; specified exit/group-absence oracle and deterministic readiness synchronization retained.
- checked: Import/reap-only causal counterfactual
  found: Three tests executed; helper escalation passed while both actual-wrapper tests still failed (two failures, 7.354 seconds).
  implication: Deadline/custody failure is independent of missing import and reap.
- checked: Actual wrapper after explicit nested custody and shared cleanup
  found: Timeout one-child and external TERM two-child controls plus escalation branch passed; later four-test run including forced-denial custody passed in 11.311 seconds.
  implication: Root and each registered nested group were independently probed absent for normal interruption; forced-denial exits 125 and retains exact numeric custody.
- checked: Forced-denial emergency cleanup test failure and exact resource reconciliation
  found: Test compared lexical and physical temporary paths, then received transient OS EPERM on exact group-0 probe after KILL. Preserved numeric custody identified root PGID 26036 and child PGID 26051. Two later exact probes each returned ESRCH for both; only matching private registry was removed. Safe detailed record is 178-wrapper-probe-custody.json.
  implication: No absence was inferred from EPERM. No uncertain owned resource remains. Probe test now persists layout before launch, treats EPERM as uncertainty, polls bounded and retains its root if absence cannot be confirmed.
- checked: Production wrapper paths with real frozen validator and local Git
  found: Eleven tests passed in 60.910 seconds. Complete covered inputs, thirteen immutable pins, source-owner checks, actual runner ancestry/commit blobs were real; package rebuild/unpack alone mocked. Final locked/floor reached intentionally failing safe fake producer; metadata and synthetic merge checkouts preserved pins; changed covered source, missing/wrong pins, stale paths and symlinks rejected before mutation.
  implication: Wrapper delegates preserved-runner/current-checkout relation without restamping or weakening pins. No genuine package producer or package acceptance occurred.
- checked: Revert-and-reconfirm path and runner equality controls
  found: Original 5b6a6e9d wrapper final-path checker failed (one test); restoring only HEAD equality in corrected wrapper caused metadata-checkout checker to fail (one test). Fixed bytes restored. Full fixed-message native records retained in 178-10-wrapper-paths-counterfactual-red.json.
  implication: Each removed accidental restriction independently prevents an authorized workflow; regressions detect both at actual wrapper boundary.
- checked: Final dedicated native checker after source settled with delivery executor
  found: ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s test/acceptance -p 'client_verifier_wrapper_*_test.py' executed 17 tests, exit 0, 65.962 seconds. Full checker count/digest record 178-10-wrapper-focused-green.json; stderr SHA256 dfbee6368f36c866a8a7e425639909fd593f4ef6a59a5f69eac63976f55cfd5d.
  implication: Actual wrapper overall timeout exits exactly 124, external TERM exactly 143, with root and every declared separate-session group independently absent; forced denial exits exactly 125 with safe private numeric custody and test-owned emergency reconciliation. Shared nested drain bound is five seconds; wrapper root grace is fifteen seconds plus at most two seconds reap and two seconds group verification, outside runtime deadline.
- checked: Adjacent existing regression controls and source syntax
  found: ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=test/acceptance python3 -m unittest client_verifier_process_supervision_test client_verifier_recovery_test client_verifier_rollout_test client_verifier_endpoints_test executed 40 tests, exit 0, 2.573 seconds. bash -n and owned git diff --check exited 0.
  implication: Adjacent process and installed-proof logic contracts remain green. This is focused harness evidence, not database/package/canonical CI/environment acceptance.

## Resolution

root_cause: Missing time import and post-KILL reap broke escalation; two-second root KILL interrupted longer nested session cleanup, and root-only group probes lacked independent nested custody. Wrapper independently prohibited authorized final paths and equated executed HEAD with preserved runner.
fix: Import and reap before group-absence verification; private inherited numeric session registry, deferred launch-time signals, shared five-second session drain, fifteen-second root cleanup window plus bounded reap/probe and failure custody; exact final/CI paths, safe job manifest selection and delegation to real independently pinned frozen validator.
verification:
  target_test: {result: pass, tests: 17}
  mutation_check: {result: skipped, reason_if_skipped: No Stryker configured for Python; targeted source counterfactuals instead killed each restored wrapper restriction.}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true}
  adjacent_tests: {result: pass, tests: 40, suites_run: [client_verifier_process_supervision_test, client_verifier_recovery_test, client_verifier_rollout_test, client_verifier_endpoints_test]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true}
  guardrail_verdict: accepted
files_changed:
  - scripts/acceptance/clean_room/package_input.py (owned process registry/group functions)
  - scripts/ci/run_verifier_upgrade_proof.sh
  - test/acceptance/client_verifier_wrapper_lifecycle_test.py
  - test/acceptance/client_verifier_wrapper_paths_test.py
oracle_type: specified

Independent review remains pending. All probe-owned groups were confirmed absent before removing their exact temporary roots; no uncertain local process remains. The OS EPERM interruption and lexical-path mistake remain explicit historical evidence. Only the independent reviewer may disposition SEC-178-06/09; this journal makes no threat-ledger closure or production/staging acceptance claim.
