---
status: awaiting_human_verify
trigger: "Second source review SEC-178-06: caller-authored numeric registry row signals an unrelated same-user sibling session"
created: 2026-10-27T08:11:15.055317+00:00
updated: 2026-10-27T08:39:18.355681+00:00
---

## Current Focus

hypothesis: Caller-writable numeric rows become kill authority without OS lineage or process-creation identity validation.
bug_class: Bohrbug
test: Actual wrapper with a separately sessioned test-owned sibling injected into the inherited registry.
expecting: Current wrapper signals the sibling even though it is outside its process ancestry.
next_action: Independent source/security lanes must personally recheck actual foreign injection, authenticated IPC/creation identity, parent-gone and uncertainty custody at the committed owned source. Do not self-close review ledger, freeze or run runtime gates.
reasoning_checkpoint:
  hypothesis: Numeric rows written by the scenario become kill targets even when authoritative OS ancestry excludes the wrapper.
  confirming_evidence:
    - Independent reviewer directly observed an unrelated probe-owned sibling signalled.
    - Agent-authored actual-wrapper sibling regression fails before source changes with one executed test; all exact test groups reaped and probed absent before cleanup.
  falsification_test: Send the same foreign sibling through the new registration IPC and require rejection without any signal; honest nested registrations must still drain after TERM/timeout and parent exit.
  fix_rationale: Only helper-private cached OS identities admitted through an authenticated kernel peer and actual parent/ancestry check may become signal targets. Diagnostic files cannot extend that set; revalidate immutable creation/session identity before each signal.
  blind_spots: Platforms lacking supported authoritative process/peer identity must fail closed. A vanished leader with surviving unidentifiable group requires retained custody/125 rather than an unsafe numeric-group signal.
  candidate_causes:
    - code: parser shape validation was mistaken for ownership authentication
    - data: fake caller supplies positive sibling PID and a false parent_pid
    - environment: OS lookup permission or PID reuse invalidates cached identity
  and_gate: yes; caller-controlled positive numeric identity plus cleanup consuming the file as authority causes foreign signalling.

## Symptoms

expected: Only sessions launched inside the owned process tree may be signalled; foreign siblings survive injected PID claims; registered children remain supervised after their parent exits.
actual: Independent source reviewer observed actual wrapper signal a test-owned sibling whose numeric identity a fake runner wrote to the registry.
errors: Wrapper returned 125 after signalling the unrelated sibling.
reproduction: Separate sibling Popen(start_new_session=True); fake wrapper runner writes its PID/claimed parent into inherited registry, then exits or waits for timeout.
started: Present at reviewed implementation 5fcf9327 and clean resumed HEAD 7c6ff91e.

## Eliminated

## Evidence

- checked: Second source/security reports and knowledge base
  found: Source directly demonstrated foreign-session signalling; security's six prior controls tested honest ownership only. No matching knowledge-base resolution.
  implication: Prior timing and honest cleanup checks do not establish signalling authority.
- checked: Actual wrapper registered_groups and signal_group, package_input registration
  found: Child writes positive numeric JSON rows; helper rereads those rows into kill targets and does not inspect actual OS parent/session/creation identity.
  implication: Shape/privacy validation cannot authenticate ownership.
- checked: Native actual-wrapper sibling injection before source edits
  found: One test executed, exit 1; fixed-message checker stderr 982 bytes/SHA256 957e45e3c92d3d220a52d8ac7d302e803a7ecc6ac2dba87889f19947a6764b1e. Exact sibling/root/wrapper ownership was persisted before launch; every exact group was reaped and probed absent before cleanup.
  implication: Reproduces source review's destructive foreign-signal mechanism without touching any shared process. Full agent-authored fixed-message native record is 178-10-registry-authority-native-red.json.
- checked: New registration and signal authority
  found: Bounded UNIX prepare/register/release IPC checks kernel peer PID, actual OS ancestry and parent identity, isolated session/group, and process start identity. The helper caches authority privately; diagnostic JSON is never read into signal targets. Cached creation identity is checked before each signal, independently of mutable parent PID; pending launch ownership prevents false-green cleanup across a launch/exit race.
  implication: Foreign numeric rows and IPC requests cannot extend authority; acknowledged children remain supervised after parent exit. Reused/unavailable identities or unfinished launch reservations fail closed with safe custody.
- checked: Authoritative macOS identity implementation
  found: Local SDK sys/proc_info.h proc_bsdinfo and sys/un.h LOCAL_PEERPID were read. Exact self-PID probe matched actual pid, ppid, pgid and sid and returned two positive creation-time fields. No argv or process inventory was read.
  implication: Host implementation uses direct kernel data rather than caller parent/creation claims. Linux uses exact /proc/PID/stat and SO_PEERCRED; Linux execution remains for independent environment verification.
- checked: Focused honest and adversarial controls
  found: Actual injected sibling survived without TERM (one test passed); honest cleanup, parent-gone child, unfinished-launch125 custody, creation mismatch/reuse, lookup denial, missing leader and existing process control passed 13 tests in 13.687 seconds. Actual full-closure wrapper path fixture passed eleven tests in 28.777 seconds.
  implication: No needed acknowledged child is silently dropped when its parent exits; uncertain identities do not receive destructive signals. Exact test-owned resources were reconciled before later probes.
- checked: Immediate child transition after first TERM
  found: Eight controlled probes returned states owned then unconfirmed before the direct child's zombie was reaped; five exited125 and three143. Each exact pair was reaped/probed absent before the next probe. Added direct-child reap and bounded identity recheck within the original deadline. Ten repeated existing-process controls then passed in 2.174 seconds.
  implication: Reaping a dead owned child establishes real group absence. Denial is never converted into absence; changed creation identity never regains authority.
- checked: Actual old-wrapper counterfactual after correction
  found: Exact wrapper bytes from 7c6ff91e were copied to one owned temporary path and exercised with the current native authority regression; one test failed with stderr982 bytes/SHA256980f49a46dd7a0b065713cf0cc196d0ea8a8edd72fd3facda803110655553b79. Current source was never changed; all exact groups were reconciled before removing the counterfactual root.
  implication: Counterfactual restores the foreign-signal failure. Record 178-10-registry-authority-counterfactual-red.json preserves actual checker output, count, wrapper digest and command.
- checked: Parallel delivery interface
  found: Wrapper now invokes delivery-owned --copy-upload-owner after raw copying with selected manifest and all five caller pins. Final pair validation pins the actual initial checkout runner; frozen owner pins remain preserved separately, without rewriting receipts.
  implication: Actual candidate manifest/archive bytes reach the upload tree through the agreed helper. This invocation is not actual package proof or source/hosted acceptance; the parallel chain owner verifies its producer/consumer boundary.
- checked: Final native dedicated and adjacent checker
  found: Selected runtime PYTHONPATH=test/acceptance python3 -m unittest client_verifier_session_authority_test client_verifier_wrapper_lifecycle_test client_verifier_wrapper_paths_test client_verifier_process_supervision_test client_verifier_recovery_test client_verifier_rollout_test client_verifier_endpoints_test executed 64 tests, exit0,69.421 seconds. Raw output remained memory-only; stderr243 bytes/SHA2563c076dd9c042fb960b4fb12910b26fe5de26df6bc19a5181ff2586c07cec3b7a. All five owned source/test hashes were unchanged throughout. Safe native record 178-10-registry-authority-focused-green.json.
  implication: Twenty-four dedicated authority/lifecycle/path and forty existing adjacent controls passed. Every exact probe group was reconciled before deleting only its owned root. Shell syntax and owned diff checks also passed. No unresolved process custody remains.
- checked: Coordinated source epoch with parallel chain owner
  found: Held all source/fixture edits and commits during chain session18592; owner reported actual single-chain one test/zero failures completed through source, uploaded pair tree, candidate and helper/handoff in40.675 seconds, then released window.
  implication: This is the parallel owner's bounded test report, not an independent review disposition or final runtime acceptance. No source epoch was relabelled as a tested committed HEAD.

## Resolution

root_cause: The scenario-writable numeric registry was treated as signalling authority without authenticated launcher lineage or immutable process identity; shape checks could not distinguish a foreign sibling.
fix: Helper-private cached OS authority via bounded peer-authenticated prepare/register/release IPC; immutable process/session/creation checks before each signal; diagnostic-only sanitized custody, fail-closed pending/denied/reused identities, and bounded reap/recheck. Existing final paths/five pins remain; actual executed runner and selected owner-upload bytes are passed to the agreed delivery interfaces.
verification:
  target_test: {result: pass, dedicated_tests: 24}
  mutation_check: {result: skipped, reason_if_skipped: No Python Stryker setup; actual original-wrapper counterfactual detects foreign signal instead.}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true}
  adjacent_tests: {result: pass, tests: 40}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true}
  guardrail_verdict: accepted
oracle_type: specified
files_changed:
  - scripts/acceptance/clean_room/package_input.py (process custody only)
  - scripts/ci/run_verifier_upgrade_proof.sh
  - test/acceptance/client_verifier_session_authority_test.py
  - test/acceptance/client_verifier_wrapper_lifecycle_test.py
  - test/acceptance/client_verifier_wrapper_paths_test.py

Limits: macOS actual process and peer APIs were executed here; Linux /proc/SO_PEERCRED branch was not executed in this environment. A missing leader with a surviving unverifiable group, changed creation identity, denied identity/signal operation or incomplete launch does not grant numeric kill authority; it retains diagnostic custody and refuses completion. The API acknowledges registrations only after OS ownership admission. Arbitrary sessions started outside start_owned_session are outside this API's declared supervision boundary. No database, genuine package producer, freeze, canonical CI, remote write, hosted/main acceptance, reviewer waiver or threat-ledger closure is claimed.
