---
status: verifying
created: 2026-10-27
updated: 2026-10-27
trigger: "Repair the diagnosed startup producer/reader transport mismatch without raw log capture."
---

## Current Focus

hypothesis: Confirmed; owned listener startup emits context booleans to discarded stdout while recovery reads an uncreated log path.
test: Final affected Python contracts and exact legacy/typed transport counterfactual, using an actual owned Elixir VM for the generated startup producer.
expecting: Typed selected-VM handoff passes; exact legacy transport fails the behavioral regression. No database/provider/canonical CI or acceptance run is part of this correction.
next_action: Commit exact authorized Python/helper/test scope after final affected gate, then return for independent delta review/refreeze.
bug_class: bohrbug
candidate_causes: code producer/consumer path mismatch; configuration selects recovery startup witness while shared listener deliberately discards raw output
and_gate: yes; recovery witness enabled plus discarded output/legacy file consumer jointly trigger failure

## Symptoms

expected: Missing-key and restored-key startup proofs read the actual selected running VM's two booleans.
actual: Private immutable bfe recovery/locked/builtin cell raises PackageInputError in recovery reader OSError handler at line463, through restore372/cell225.
errors: PackageInputError; underlying OS errno was not captured and is not labeled observed FileNotFoundError.
reproduction: Exact source wrapper stderr75-byte hash recovered overall/recovery/locked/all. One nonaccepting private supervised cell then located the reader failure; no accepted cell resulted.
started: Genuine wrapper at bfe33ac; diagnostic session92833 terminal wrapperexit1 after58.883seconds.

## Evidence

- Original startup producer is generated in build_provider.write_host_runtime's Application.start/2. It calls the existing Lockspire.Config.client_secret_verifier_context getter and projects state==valid and membership of verifier-new. Listener _start_server ignores legacy log_path and directs stdout/stderr to DEVNULL; reader subsequently opens that path. This diagnosis preceded product correction.
- Original private diagnostic custody remains at /private/tmp/ls178-rec-4ciqycfg. Eighteen recorded sessions independently absent; three tracked run directories absent; exact new recovery UUID database independently catalog-count0 on private64853 at13:20:05Z. Two inactive owned Mix cache directories remain retained. Four initial child observation claims were not final independent restore proof. Original four receipts, old custody and foreign5432 remain untouched.
- First controlled regression runs were setup errors, not qualified RED: actual selected unit VM exited early; bounded safe attribution eventually identified TokenMissingError in the controlled multiline program envelope. Base64 framing fixed only this fixture boundary. Original setup attempts are not relabeled native behavioral failures.
- Before any product edit, actual generated startup producer block ran in an owned Elixir VM with controlled runtime getter/HTTP/command boundary. Current reader then failed the fixed behavioral assertion: one target, one failure, zero errors, childexit1. Native SHA256 ee1e878ad6aebdd8a66ecbfee4d463fbcdc18a0e1c896def5e90184117716791. Supported native checker returned RED_EVIDENCE_OK/target_test_failed before product edit; exact record retained /private/tmp/ls178-witness-tdd-21pq1wh7/qualified-native-red.json.
- New actual producer contracts4/4 passed: actual missing-key true/false and restored true/true; stdout/stderr remain DEVNULL; generated unknown output and encoded output never enter witness files; closed bounded payload rejects nonce/PID/bool/extra/sensitive/oversize mutations kept in memory; stale/unowned/symlink paths and replay reject.
- Exact immutable bfe legacy start/reader functions substituted in memory yield one target/one fixed assertion failure/zero errors. Restoring typed functions yields one target/zero failures/errors. Both controlled VM sessions independently absent. First counterfactual attempt used detached globals and produced a harness error; it was not accepted as behavioral counterfactual proof. It is retained as a setup limitation; later substitution uses live module globals so controlled external command boundaries remain effective.
- Initial affected gate70parents had one source-string assertion failure and zero errors: root's earlier AST-equivalent formatter expanded rollout argv parsing. Focused test now checks the same exact tokens/branches with flexible whitespace, including the equivalent optional semicolon. No Elixir fixture was edited by this lane.

## Resolution

root_cause: Generated startup context and recovery consumer used incompatible transports after listener raw output was intentionally discarded.
fix: An exclusive new0700 channel carries only fixed schema, nonce, actual OS PID and two literal booleans. The actual selected VM writes an exclusive temporary file, chmod0600 and atomically links the complete payload. Python binds authority in RAM to the existing gated listener identity, waits publication within the existing35second readiness deadline, bounds/parses exact bytes, checks nonce/PID/live identity and consumes once. Owned listener cleanup removes only its private channel. Raw stdout/stderr remain DEVNULL; no default booleans or peer-receipt inference.
oracle_type: specified producer/consumer contract plus exact-source counterfactual
verification:
  target_test: pass after supported native pre-edit RED
  mutation_check: Stryker unavailable for Python; six wrong-value payload mutations reject, and exact legacy transport counterfactual kills target
  no_op_deletion: additive typed transport; actual Config getters/startup requirements, process authority, readiness deadline and raw-output suppression retained
  adjacent_tests: final affected70parents all pass; failure/error/skip/expected/unexpected/loader counts0; three controlled VM sessions independently absent; channel registry0
  revert_and_reconfirm: exact legacy start/reader substitution fails target; typed restoration passes,2/2runtime sessions absent
limits: Controlled producer VM uses a runtime getter and host-service boundary; it is not a full installed recovery/DB acceptance. Existing bfe frozen1073 source is stale for changed code and new selected helper/test. Independent delta review/refreeze remains necessary. Root separately owns two Elixir lint files and canonical CI. No real recovery cell, source CI, freeze, matrix, remote operation or self-review closure was performed after this correction.
files_changed: verifier_rollout.py; verifier_recovery.py; startup_witness.py; only generated Application startup block in build_provider.py; three focused Python test files; this journal
