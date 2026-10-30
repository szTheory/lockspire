---
status: resolved
trigger: "Actual fixed locked wrapper at b21ca75f exited125 with prepared root44752 and no completed child registration; original custody retained"
created: 2026-10-27
updated: 2026-10-30T19:29:56.936128+00:00
---

## Current Focus

hypothesis: A fast command exits before local/helper OS identity admission, leaving a prepared launch and refusing cleanup; fixed-lifetime gate until authoritative registration ACK removes this race.
test: Native actual-wrapper cold fast-command regression plus private actual-executable and actual-Mix caller counterfactual; all probes reconciled before further action.
expecting: Commands activate only after registration, then finish without pending ownership while original identity/signal/denial policies remain intact.
next_action: Independent source/security delta review of the scoped process correction, then root-controlled refreeze before any genuine pair retry. Preserve original retained custody and failed attempt; do not self-close ledger, source/package acceptance or STATE.
reasoning_checkpoint:
  hypothesis: Current API lets a target run immediately after Popen while local kernel lookup and a later IPC admission remain outstanding; short-lived children disappear before either check.
  confirming_evidence:
    - Actual /usr/bin/true exited between Popen return13.2ms and local identity read16.5ms, producing ProcessLookupError before register IPC and wrapper125/pending owner.
    - Actual pg_isready --version had local identity at13.0ms but helper admission at56.2ms rejected the exited child, followed by refused release and wrapper125/pending owner.
    - Holding only target exec behind a private pipe until original registrationACK completed all3 true/pgversion/actualMix caller commands; wrapper78,pending0,refusedfalse,all exact groups absent.
  falsification_test: Same strict native fast-command assertion must still fail with the gate disabled and pass with gate active; authority sibling/reuse/denial/pending-parent controls must remain unchanged.
  fix_rationale: Establish the original OS/peer/session/creation authority while a trusted isolated launcher remains alive, then exec the requested command in that same process. Do not extend a deadline, cancel an uncertain child by claim, or accept unregistered execution.
  blind_spots: Original actual attempt's private stderr was discarded, so no exact historical source line can be claimed. Linux launcher execution and full installed provider/database behavior remain unverified here.
  candidate_causes:
    - code: asynchronous target execution precedes ownership admission
    - environment: fast native executable lifetime is shorter than cold metadata/IPC scheduling latency
    - config: wrong runtime would cause failure but cannot explain a true process disappearing before its ownership registration
  and_gate: yes; immediate target execution plus a sufficiently short command lifetime exposes the ordering defect.
candidate_causes:
  - code: local identity lookup precedes register IPC and its failure branch does not complete the prepared reservation
  - environment: cold fast child exit, actual executable/asdf behavior or IPC latency changes the launch interval
  - config: selected frozen/runtime environment can cause an earlier child failure while owner capture separately passed
and_gate: unknown until the actual transition is observed

## Symptoms

expected: Acknowledge/register every launched child or preserve a correctly attributed unresolved launch, without claiming successful cleanup.
actual: Actual locked wrapper exited125; original custody records root44752 plus pending launch by the same root; no group or cell receipt exists.
errors: pending-owned-launch; original231-byte stderr discarded, unavailable.
reproduction: Executed b21ca75f, frozen runnerdf8f9c51/candidate51747a6e, local-current selected runtime and private PostgreSQL context. No retry authorized by inference.
started: Actual attempt wrapper41869 started2026-10-27T11:30:36.921063Z, terminal125 after approximately30s.

## Eliminated

## Evidence

- checked: Current source and accepted layout delta reports
  found: HEADb21ca75f clean. Process/IPC code is unchanged by accepted422fa6e9 archive materialization. Current frozen manifest covers1072 paths; runnerdf8f9c51, candidate51747a6e, archivef6f49878/treeedef4f97.
  implication: Do not undo or conflate accepted nonprocess layout correction with unresolved actual lifecycle failure.
- checked: Source prepare/Popen/register/cancel branches
  found: prepare ACK precedes Popen; ordinary Popen failure calls cancel. _register_session first queries child kernel identity, then sends registration. Failure before completed registration can retain pending ownership and fail closed.
  implication: A source-backed hypothesis, not an attributed actual cause; real frozen constructor instrumentation is required.
- checked: Original retained custody facts supplied by root
  found: Exact registrylockspire-verifier-owned-g7jst4pl retains root44752/session44752/start1793100649,927428,parent44714 and matching pending owner. Root, creator/helper and wrapper41869 were independently observed absent by root. Files remain untouched.
  implication: Never use retained rows as kill authority, and never remove the original attempt while diagnosing.
- checked: Private actual-wrapper frozen constructor
  found: Probe root /private/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire178-ipc-diag-i77bp_lj; actual copied wrapper with one declared helper instrumentation import, original core runner/frozen package preparation and adjacent archive verification reached original-signature-bound provider hard stop. Two real Elixir children completed prepare/register/release; registration round trips approximately46–49ms. Wrapper test exit78, pending0/refusedfalse, no provider body/network/SQL/forbidden commands, all owned groups absent, source bytes unchanged.
  implication: Constructor work itself succeeded in this controlled run. Original genuine failure cannot be attributed to an unobserved historical source line. An earlier /private/tmp diagnostic root was refused by the unchanged test-mode path guard before any scenario launch; its outer group was confirmed absent and the nonexecuting attempt was preserved.
- checked: Cold native true under actual wrapper/supervisor
  found: Probe root lockspire178-fast-launch-i8tsy7bu. Prepare ACK10.1ms; actual child70603 Popen returned13.2ms; local kernel lookup16.5ms raised ProcessLookupError before register IPC. Wrapper125 retained pending root70602, matching original structural failure. Wrapper70595/root70602/child70603 groups and helper70601 independently absent before next probe; new diagnostic custody retained.
  implication: Fast target execution can end before the factory obtains its local ownership pin.
- checked: Actual pg_isready binary in version-only mode
  found: Probe root lockspire178-pgversion-launch-gsgwpq0p. Local identity for child81169 read13.0ms; helper rejected registration56.2ms after target exit; release was also refused because admission never existed. Wrapper125 retained pending root81087. Exact wrapper80978/root81087/child81169 groups absent before next probe; diagnostic custody retained. No database connection or SQL occurred.
  implication: Even a successful local lookup does not prevent exit before later authoritative helper admission. This binary is the first provider preflight command's executable; version-only avoids any server contact.
- checked: Private exec-gate-only actual-command counterfactual
  found: Probe root lockspire178-exec-gate-y_dt4es7. Holding exec only until original registrationACK completed true, actual pg_isready --version and actual build_provider._run_mix(...--version), all exit0. Wrapper78, three gates released after ACK, pending0/refusedfalse, exact groups76929/76943/76974/77029/77037 independently absent; source bytes unchanged.
  implication: Lifetime synchronization at the exact launch boundary resolves both observed races without changing identity, peer, denial, pending or timeout policy.
- checked: Native pre-edit regression and supported classifier
  found: Actual-wrapper cold true target executed one test/one fixed assertion failure/zero errors, exit1; stderr1153 bytes/SHA256026d19edf6829b9df60e12110f81e3a83c865cef98d7cfa096cd5d7a9abaee4d. Supported tdd-red-evidence classifier returned RED_EVIDENCE_OK/target_test_failed/unittest/report_errors[] before production edit. Unmodified report is retained in178-10-launch-registration-native-red.json.
  implication: Qualified behavioral RED established the original API failure; fixed diagnostics and exact-resource reconciliation remained intact.
- checked: Product correction and semantic controls
  found: start_owned_session launches an isolated trusted Python -I -S -B pipe gate, obtains original local/helper OS authority, then activates the requested command in that same process. CLOEXEC status pipe preserves synchronous exec errno/filename. Existing cwd/env/stdin/out/err/pass_fds/PID/session and restore_signals behavior is preserved; arbitrary preexec callbacks are rejected before launch. Failed bootstrap Popen OSError cancels only the uncreated reservation; creator death before ACK closes the gate without target side effects and retains125 custody.
  implication: No deadline was extended and no unregistered child execution or cancel-by-claim was accepted.
- checked: Final affected native verification
  found: Forty-seven tests passed, zero errors/failures, exit0,19.333 seconds; stderr147 bytes/SHA256de65fbda32ebf45897ff6eaa44537b420cbc4e6fc04b13620a4f082d7b6f3981. Exact command, private environment selection and unchanged source hashes are in178-10-launch-registration-focused-green.json; raw checker output remained memory-only. Includes eleven new launch/semantic controls, all existing authority/lifecycle/process/sourceguard controls and six accepted archive-layout neighbors.
  implication: Real cold true/git/pgversion and actual Mix caller succeed; foreign sibling refusal, reuse/denial, parent-gone/pending, cleanup and nonprocess layout remain protected.
- checked: Causal disable/reapply at the gate token boundary
  found: Same native actual-wrapper target with identical100ms registration delay: disabling only gate wait gives one target/one fixed failure/exit1; restoring wait gives one target/zero failures/exit0. Product/test source files were not mutated. Records and private driver digest are in178-10-launch-registration-counterfactual.json; each exact probe root/group was reconciled by the native fixture before its removal.
  implication: The held exec boundary, rather than a timeout relaxation or changed assertion, causes success.
- checked: Delta boundaries and original custody preservation
  found: AST source-segment comparison withb21ca75f shows only existing function start_owned_session changed and two new helpers; every existing nonprocess/layout, Supervisor, IPC, identity and signal function/class is byte-identical. Original g7jst4pl directory remains0700 with exactly44752.json and pending-launches.json, matching both root-supplied SHA256 values. Original failed root/receipt-owner remains untouched.
  implication: Accepted archive materialization is preserved. Existing freeze covers old bytes and is invalid for new runtime until independent delta review/refreeze.

## Resolution

root_cause: The session factory executed the requested target before ownership registration completed. A short-lived command can disappear before local kernel lookup or before the helper's later authenticated admission; registration cannot prove the dead target and the prepared reservation correctly forces125. The original genuine attempt's unavailable traceback prevents unique historical line attribution, but its pending-owner signature is reproduced by both fast-child boundaries.
fix: Synchronize target exec with the unchanged ownership-admission ACK using an isolated ordinary Python pipe launcher, same PID/session/env/cwd/stdio, synchronous exec status channel, bytecode suppression and original signal restoration. Parent death cannot activate an unacknowledged target. Existing authority/refusal/pending/deadline mechanisms remain intact.
verification:
  target_test: {result: pass, new_launch_semantic_tests: 11, native_pre_edit_classifier: RED_EVIDENCE_OK}
  mutation_check: {result: skipped, reason_if_skipped: No Stryker configuration; explicit gate-wait disable/reapply native counterfactual killed the defect boundary.}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true}
  adjacent_tests: {result: pass, total_affected_tests: 47}
  revert_and_reconfirm: {result: pass, bug_returned_on_disable: true, fixed_on_reapply: true}
  guardrail_verdict: accepted_for_local_delta_review_only
oracle_type: specified transition/ownership invariants and actual source-bound counterfactual
files_changed:
  - scripts/acceptance/clean_room/package_input.py (process factory, two gated-launch helpers and trusted launcher constant only)
  - test/acceptance/client_verifier_launch_registration_test.py
  - this journal and three safe native evidence records

No original custody was removed, no original raw diagnostics were sought, and no probe or test signalled the root-owned PostgreSQL controller or foreign5432 clients. All new exact probe groups were reconciled before later probes; only safe explicitly owned diagnostic files and failed-probe custody remain retained. No provider body, database connection/SQL, package producer, canonical source CI, full matrix, hosted/main/remote action or final acceptance was run. Actual downstream runtime remains a separate root owner after review/refreeze.


## Closeout reconciliation — 2026-10-30

The original `awaiting_human_verify` checkpoint above is superseded for the implemented fix by the later independent source/integration/security review of the complete selected closure, the final declared-threat assessment, actual current/minimum installed-package receipts and accepted main `dc3969302152028e2132759eb9edf5a7d260ac39`. See [closeout reconciliation](../../milestones/v1.48-CLOSEOUT-RECONCILIATION.md), [final phase verification](../../phases/178-packaged-upgrade-proof-delivery-handoff/178-VERIFICATION.md), and [actual main acceptance](../../phases/178-packaged-upgrade-proof-delivery-handoff/178-POSTMERGE-ACCEPTANCE.md).

The native acceptance suite was rerun at this unchanged main during closeout: 301 tests passed, exit 0, owned group closed; [safe result](../../milestones/v1.48-CLOSEOUT-PYTHON.json). These later observations satisfy the earlier review/qualification follow-up for the current correction. For the installed-recovery journal, the later root diagnosis owns the `:inets` cause and subsequent fixture corrections; the original diagnostic-only entry did not establish that cause.

This resolves the current debugging work, not unknown predicates or custody from earlier failed runs. Original diagnostic/TDD limits, unknown historical closures, failed attempts, retained resources and formal PARTIAL/Nyquist-false flags remain unchanged. No historical run is restamped, no unknown process is stopped, and no new database/package/application proof, integration or publication is authorized.

Original checkpoint SHA-256: `d2152526e01ab58a137e643be8d0690905bd4ef9c524da662c1b158355c75070`. The body above remains unchanged; only its leading lifecycle status/updated date and this reconciliation changed.
