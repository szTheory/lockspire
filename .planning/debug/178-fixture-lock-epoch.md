---
status: awaiting_human_verify
trigger: Phase178 current full Python gate reports eleven fixture authority assertions after the JOSE lock update.
created: 2026-10-28
updated: 2026-10-28
---

## Current Focus

reasoning_checkpoint:
  hypothesis: Retained receipt host locks are authentic at their pinned historical source epoch, while current fixture validators select changed live lock files, rejecting setup before the intended assertions.
  confirming_evidence:
    - Current 0e94 full gate ran 276 tests with 11 assertions and no errors; its original record remains unchanged.
    - Three representative actual calls reproduced three assertions with no errors at pair line636 or matrix line730 in clean_room_verifier_upgrade.py.
    - All26 receipt lock values match actual Git lock blobs at their runner and candidate source; none matches the current locks. All26 compiled digest formats remain valid.
  falsification_test: Supplying only independently pinned private epoch lock inputs still produces the same lock rejection in the representative actual calls.
  fix_rationale: Give synthetic and historical fixture calls explicit immutable Git-owned lock inputs while preserving production checks and all retained receipt bytes.
  blind_spots: These are synthetic fixture mechanisms with external OS/build/database/GitHub boundaries faked, not a new installed/runtime/hosted acceptance epoch. Nested sessions were not independently inventoried by the outer collector.
  candidate_causes:
    - code: A production validator might have changed receipt structure or source binding.
    - data: Authentic retained fixture lock identities refer to a different dependency epoch than live source inputs.
  and_gate: Yes; the lock update and an implicit live-input dependency in fixture construction are both required for this regression.
next_action: Commit the exact five-file test/debug scope and return clean ownership to the orchestrator for independent review and its one current full-Python gate.

## Symptoms

expected: Current fixture tests exercise their declared positive and negative authority contracts without promoting historical evidence into new acceptance.
actual: Eleven current full-gate assertions fail before the intended receipt/copy/composition operations complete.
errors: Fixed pair and matrix host-lock rejection families.
reproduction: Full gate at0e94 and three representative actual calls recorded in /private/tmp/lockspire178-authority-attribution-dhna6gry/terminal.json.
started: After the approved JOSE minimum and pair lock changes.

## Evidence

- 2026-10-28: Read-only representative diagnostic PID/PGID/SID71881, source0e94 unchanged and clean, three tests/three assertions/zero errors, direct session independently absent. Earlier private harness NameError occurred before child launch and is not product evidence.
- 2026-10-28: Fixed historical input epoch is Git commit2da528fba3ca894cda4e5776b47eb6ccaf12f93c. Its two actual lock blobs authenticate all26 retained receipt lock values; no retained receipt/descriptor is rewritten.
- 2026-10-28: The helper verifies that2da is an actual ancestor of published4d512ae2c6a042e2b4557750eca2d49e57fb7189 and current HEAD before loading either exact Git lock blob. Both runner and candidate source must equal the independently fixed epoch, even when a borrowed claim retains identical lock bytes.
- 2026-10-28: First post-edit focused attempt ran13 tests with3 assertions and0 errors. Ten passed; the remaining upload/full-chain setup assertions were resolved by adding the clean-room import path before loading the test-only lock context in the upload bootstrap. PID73498 independently absent; /private/tmp/lockspire178-epoch-focused-hsalsh3g/terminal.json preserves this unsuccessful attempt.
- 2026-10-28: Settled focused attempt ran all11 original failed parent IDs plus2 new epoch controls:13 tests,0 failures,0 errors, exit0. The actual full chain reached pair CLI14/33 and12/31, source acceptance, actual wrapper-copy/upload/ZIP, candidate graph, actual helper emitter and handoff consumer, including coordinated archive/version/runtime/base/attempt negatives. PID/PGID/SID74082 independently absent. Evidence /private/tmp/lockspire178-epoch-focused-k1n99hrd/terminal.json; five owned input hashes unchanged during execution.
- 2026-10-28: Remaining adjacent tests in all three affected modules ran37 tests,0 failures,0 errors, exit0. The context-disable counterfactual reproduced1 assertion/0 errors; restoring the same context produced1 test/0 failures/0 errors. PID/PGID/SID75255 independently absent. Evidence /private/tmp/lockspire178-epoch-focused-y5wt01k0/terminal.json; five owned input hashes unchanged during execution.
- 2026-10-28: All raw import/test/child output and exception details remained memory-only. Durable records contain fixed parent IDs, known source locations, counts, digests and custody facts. Direct outer session cleanup is certified; separate nested-session cleanup was not independently inventoried. No DB/Mix/provider runtime or remote operation was performed by this correction.

## Resolution

root_cause: Fixture authority implicitly selected live dependency locks instead of immutable lock bytes belonging to the retained receipt epoch.
fix: Test-only private lock materialization from a fixed Git source pin, explicit scoped input selection, and inclusion of those exact locks before committing the full chain's private source fixture. Production validators and historical proof files remain unchanged.
oracle_type: derived
verification:
  target_test: {result: pass, unique_tests: 13, failures: 0, errors: 0}
  mutation_check: {result: skipped, reason_if_skipped: No Stryker configuration for these Python fixture helpers; explicit input-context disable/reapply provides the causal control.}
  no_op_deletion: {result: pass, deletion_justified_by_rca: false, explanation: Existing accepting and rejection checks remain; the change supplies independently pinned private input bytes.}
  adjacent_tests: {result: pass, unique_tests: 37, failures: 0, errors: 0}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, method: Disable only the private input-context seam in memory, then restore it; no validator result is mocked.}
  guardrail_verdict: accepted
  limitations: Independent review, current full-Python qualification, fresh freeze and actual installed/hosted proof remain pending. Original276/11 and historical proof epochs remain unchanged.
files_changed:
  - test/acceptance/verifier_owner_fixture.py
  - test/acceptance/client_verifier_delivery_test.py
  - test/acceptance/client_verifier_delivery_chain_test.py
  - test/acceptance/client_verifier_receipts_test.py
