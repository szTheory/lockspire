---
status: resolved
trigger: "Diagnose and fix bounded Plan 178-06 installed recovery blocker at expired_http; preserve fail-closed policy and safe child diagnostics."
created: 2026-10-26T22:27:41Z
updated: 2026-10-30T19:29:56.936128+00:00
---

## Current Focus

hypothesis: Root follow-up confirmed the host omitted inets from extra_applications, allowing Mix path pruning to break http_util.timestamp/0. This HTTP blocker is resolved; recovery assertions still need actual proof.
test: Exact extracted helper in an owned installed host failed at the source-backed http_util.timestamp/0 target; changing only its inets declaration restored all four loopback statuses and normal mounted rejection. Qualified reduced regression and full acceptance pass.
expecting: Resume Plan 06 from host fix 55f3f134; five remaining false recovery observations must be corrected/proved, not relaxed.
next_action: Read .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-06-ROOT-DIAGNOSIS.md. Original bounded diagnostic history below remains unchanged; it did not establish the root cause at its handoff.
bug_class: bohrbug
candidate_causes:
  - code: Undefined call deeper in HTTP request processing or generated-host helper execution.
  - config: Generated-host application startup/code path differs from root helper test.
  - environment: Installed runtime module availability differs during HTTP processing.
and_gate: Unknown until a specific failing operation is observed.
reasoning_checkpoint:
  hypothesis: Substring matching in _capture_child_output masks precise fixed failure stages because expired_http is a prefix of expired_http_timeout and related stages.
  confirming_evidence:
    - New focused test returned expired_http for exact expired_http_timeout marker.
    - Unknown expired_http suffix was incorrectly accepted as expired_http; four new code/assertion/request markers were withheld by both allowlists.
  falsification_test: Exact allowlisted token extraction still returns a prefix or unknown suffix as a known stage.
  fix_rationale: Match complete marker tokens and add only fixed substep enum values; no child data is emitted.
  blind_spots: This diagnostic defect does not establish the underlying installed failure. A fresh installed reproduction is required.
  candidate_causes:
    - code: Substring match against unordered fixed-stage set.
    - data: Child output carries a longer or unknown stage token sharing a known prefix.
    - config: Missing fixed stage from duplicated diagnostic allowlists.
  and_gate: No for the prefix ambiguity; substring matching alone permits misclassification. New substep instrumentation is separate observability work.

## Symptoms

expected: One installed locked/builtin recovery probe completes its strict recovery observations and receipt.
actual: Three corrected-fixture attempts failed with only the fixed expired_http stage and no accepted receipt.
errors: installed verifier host scenario failed at expired_http; child diagnostics withheld
reproduction: Process-local ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store builtin --group recovery --receipt-dir .artifacts/phase178/recovery-probe
started: Plan 178-06 installed recovery execution. Prior legacy fixture failure was corrected before the three repeated expired_http attempts.

## Eliminated

- hypothesis: Authorization-code interaction or token SQL insertion fails before HTTP.
  evidence: Instrumented installed probe advanced through both insertion stages and assertion construction to expired_request.
  timestamp: 2026-10-26T22:35:00Z
- hypothesis: Assertion construction or HTTP client startup is the failing operation.
  evidence: Stage expired_request is set only after successful inets startup, signed assertion, body and request tuple construction.
  timestamp: 2026-10-26T22:35:00Z

## Evidence

- timestamp: 2026-10-26T22:41:37Z
  checked: Third installed diagnostic attempt and minimized exact-helper root experiment
  found: Third installed failure was expired_request_undefined, zero receipts. Own database lockspire_clean_room_verifier_recovery_09ecaadb89744d06b1a4bf4455edf34b and temp root lockspire-verifier-recovery-locked-builtin-pzh8d1um independently absent; port 50005 child exited. Exact actual helper under root runtime returns real loopback 200/400/401/500 normally. Direct deliberate undefined-call self-check confirms module/function/arity classifier fields and no args field.
  implication: Three full diagnostic attempts are exhausted. Parent authorized exactly one differently bounded minimal installed-host runtime experiment, with only fixed known-target enums/ownership booleans.

- timestamp: 2026-10-26T22:35:27Z
  checked: Second instrumented installed locked/builtin reproduction
  found: Exit 1 at exact expired_request_error; zero receipts. This excludes ArgumentError, CaseClauseError, FunctionClauseError, MatchError and ErlangError. Owned database lockspire_clean_room_verifier_recovery_e0917a2acb454a7cb1a60a1ea5c5acb6 independently absent, temp root lockspire-verifier-recovery-locked-builtin-3uy9nyie absent, port 49366 child exited.
  implication: Add omitted standard exception classes and a fixed undefined-httpc target distinction; no arbitrary module/function/error values will be surfaced.
- timestamp: 2026-10-26T22:35:27Z
  checked: Cross-plan positive-only HTTP helper hypothesis
  found: Plan 06 directly returns all normal HTTP statuses from httpc.request/4. No positive-only helper or status assertion runs before expired_metadata. Its later expired status equality is separate from the current request exception.
  implication: Positive-only helper mechanism from Plan 03 does not explain this failure.

- timestamp: 2026-10-26T22:35:27Z
  checked: Harmless minimal httpc request under exact ASDF/ERL_FLAGS runtime
  found: Same request tuple/options against a closed loopback port returned classified connect failure normally.
  implication: No blanket runtime/API failure is established. Added fixed exception-class enum labels only around the installed request call for the next discriminating experiment.

- timestamp: 2026-10-26T22:35:00Z
  checked: One instrumented installed locked/builtin recovery reproduction
  found: Exit 1, exact fixed stage expired_request, zero receipts. Child output remained in memory. Owned database lockspire_clean_room_verifier_recovery_73e2820efcec47de9626d86a2fa8ee46 absent independently; owned temporary root lockspire-verifier-recovery-locked-builtin-wi86xw5x absent; port 64973 child exited.
  implication: Failure is inside httpc.request/4 or matching its return; pre-request SQL/assertion inference is eliminated.

- timestamp: 2026-10-26T22:30:00Z
  checked: Diagnostic regression and exact enum extraction
  found: Before observability correction, five focused tests ran with six failed assertions (four missing substeps, timeout prefix masking, unknown suffix accepted). After complete-token enum matching and fixed substeps, five tests passed. Existing random unregistered child stdout/stderr regression remains passing.
  implication: Earlier expired_http labels cannot prove the absence of a transport error. Next run must use exact stages.

- timestamp: 2026-10-26T22:27:41Z
  checked: Repository and checkpoint state
  found: Clean shared tree at c005cec58d28669dcf0e3b5f514f0ca9c4bf4fe5; Plan 06 incomplete. Parent authorized one bounded diagnosis and reproduction, local exact-file commits only.
  implication: No matrix or issuance execution is authorized for this diagnostic owner.
- timestamp: 2026-10-26T22:27:41Z
  checked: Diagnostic boundary and disclosure history
  found: Three historical harness disclosure incidents must remain disclosed. Current boundary withholds child stdout/stderr and errors, exposing only fixed stages. No raw tails will be inspected or retained.
  implication: All diagnostic extensions must be fixed enums/booleans/counts only, including unknown generated secrets.
- timestamp: 2026-10-26T22:27:41Z
  checked: Agent skill discovery and memory availability
  found: No project skill directories or configured debugger skills; no MemPalace tool available. Knowledge base consulted as fallback. No existing matching recovery resolution.
  implication: Proceed with direct evidence; no prior resolution is accepted as diagnosis. SBFL skipped because no per-test failing/passing coverage exists for this installed host scenario.

- timestamp: 2026-10-26T22:45:07Z
  checked: One authorized minimal generated-host runtime comparison
  found: Setup completed and the runner reached its minimal_request command phase, then the child exited before a safe facts object was returned. No target/module/HTTP status was observed or inferred. Own database lockspire_clean_room_verifier_recovery_8d3acfb3ed4d4b3998f1e55ace488633 and temp root lockspire-verifier-minimal-installed-73kuz1bp independently absent; port 51446 child exited; zero receipts.
  implication: The minimal comparison is inconclusive, not a successful reproduction or root-cause proof. Parent directed terminal handoff without another installed run.
- timestamp: 2026-10-26T22:45:07Z
  checked: Current diagnostic correction verification
  found: Focused Python 5/0; adjacent verifier Python 51/0; required source integration 25/0; fixture mix format and git diff --check exit 0. Exact Python-file revert made the unknown-suffix regression fail; restoring current files returned focused suite to 5/0.
  implication: Only the safe diagnostic correction is verified. Original installed recovery remains failing, with no accepted recovery receipt or Plan 06 completion claim.

## Resolution

root_cause:
diagnostic_root_cause: Recovery boundary used substring matching against an unordered fixed-stage set; a longer known or unknown token could be reported as its expired_http prefix. Duplicated lower/upper allowlists also lacked operation substeps.
fix: Diagnostic-only correction. Both Python boundaries extract complete marker tokens and accept only fixed enums; host adds fixed code/HTTP substeps and exception-class stages. Child bytes and arbitrary exception values remain withheld. No fix to the original undefined call is claimed.
oracle_type: specified (exact fixed allowlist stage or fixed withheld reason; no arbitrary child bytes)
verification:
  target_test: {result: pass, suite: client_verifier_recovery_test.py, tests: 5}
  mutation_check: {result: skipped, reason_if_skipped: No Stryker or mutation runner configured for this Python/Elixir harness}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true, detail: Only ambiguous token matching replaced; no scenario, policy, assertion or runtime behavior removed}
  adjacent_tests: {result: pass, suites_run: [verifier Python acceptance 51/0, required source integration 25/0]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true}
  guardrail_verdict: accepted for diagnostic correction only
original_issue_verification: not verified; three diagnostic recovery failures plus one inconclusive minimal run, all zero receipts
files_changed:
  - scripts/acceptance/clean_room/build_provider.py
  - scripts/acceptance/clean_room/verifier_recovery.py
  - test/acceptance/client_verifier_recovery_test.py
  - test/clean_room/provider_host/lib/clean_room_provider/verifier_recovery.ex

## Handoff

- Source diagnostic correction commit: 05c20cb795ac1ebb8489fc126754fc82221ba87a (`fix(178-06): preserve exact safe recovery failure stages`), four exact source/test files, normal hooks. Initial local commit attempt failed exit 128 with filesystem permission denial; narrow authorized sandbox escalation retried the same commit successfully. No automatic approval rejection occurred.
- Original checkpoint and receipts are unchanged. Three historical disclosure incidents remain open metadata truth (03 raw-log, 04 failed-tool, 06 failed-tool); this diagnosis exposed no child bytes and retained no raw logs.
- Requested runtime throughout: process-local ASDF_ELIXIR_VERSION=1.19.5-otp-28, ASDF_ERLANG_VERSION=28.5, ERL_FLAGS='+S 4'; source integration additionally MIX_ENV=test. No toolchain/config changes.
- Package inputs remained clean at c005cec58d28669dcf0e3b5f514f0ca9c4bf4fe5; Lockspire package version 1.6.1. Diagnostic runner/host overlay edits were uncommitted during attempts and are not presented as immutable accepted proof. Locked host pins Phoenix 1.8.13 / LiveView 1.2.10; actual runtime/package proof records were queried by the recovery runner but no receipt was accepted or restamped.
- All generated hosts use a unique vfy-prefixed PostgreSQL schema, isolated newly named database, local port, dedicated old/new random verifier keys, legacy_read reject, frozen configured issuer audience, and normal generated-host startup. No schema/dependency/production API changes.
- Three diagnostic command shapes: exact original process-local environment plus `python3 /private/tmp/phase178_recovery_diagnosis.py .artifacts/phase178/recovery-diagnosis-01` (then 02 and 03). Each invokes original CLI main with locked/builtin/recovery and the named fresh receipt directory; stdout/stderr remain in memory. Safe stage sequence: expired_request, expired_request_error, expired_request_undefined.
- Last differently bounded command shape: same environment plus `python3 /private/tmp/phase178_minimal_installed.py`. It uses prepare_package(checkout), prepare_provider(locked, builtin, recovery fixture), identical custody/runtime configuration, ecto.create/migrate and signing-key provisioning, then `mix run /private/tmp/phase178_http_probe.exs`. The probe extracts actual helper AST into a test-only module, removes the diagnostic rescue, uses only static harmless credentials, owned TCP responses and an invalid-client mounted probe. It did not return its safe facts object; no claim is made that those substeps executed. The root no-start version returned 200/400/401/500 and classifier_selftest true. Its test-only HTTP timeout is 1000ms; production fixture remains 15000ms.
- Relevant code: fixture seed_authorization_code!/1 at line 507, token_request/4 at line 560, undefined classifier at lines 622/625, signed_assertion/4 at line 652. Python build boundary line 693 and recovery boundary line 177; focused boundary regressions at test lines 117 and 147.
- Next audit: inspect the exact UndefinedFunctionError path and generated-host/minimal startup before any further run. Do not use raw tails. Ensure a future minimal probe emits fixed facts immediately and handles a pre-connect failure without linked TCP-task cleanup masking them; this is an untested probe blind spot, not an established failure cause. The later expired status equality currently expects 400; it has no actual observed HTTP outcome yet and cannot be credited.
- No full recovery matrix, issuance, final phase verification, remote write, merge or publication was run.
- Safe diagnostic scripts remain available to parent at /private/tmp/phase178_recovery_diagnosis.py, /private/tmp/phase178_minimal_installed.py, /private/tmp/phase178_http_probe.exs, /private/tmp/phase178_parser_reconfirm.py and /private/tmp/phase178_verify_diagnosis.py. They contain no generated secret values or raw child output. All run-created temporary directories were deleted.

| Attempt | Fixed result | Owned database (independently absent) | Port | Deleted temporary-root basename |
|---|---|---|---|---|
| Diagnostic 01 | expired_request; exit 1; 0 receipts | lockspire_clean_room_verifier_recovery_73e2820efcec47de9626d86a2fa8ee46 | 64973 | lockspire-verifier-recovery-locked-builtin-wi86xw5x |
| Diagnostic 02 | expired_request_error; exit 1; 0 receipts | lockspire_clean_room_verifier_recovery_e0917a2acb454a7cb1a60a1ea5c5acb6 | 49366 | lockspire-verifier-recovery-locked-builtin-3uy9nyie |
| Diagnostic 03 | expired_request_undefined; exit 1; 0 receipts | lockspire_clean_room_verifier_recovery_09ecaadb89744d06b1a4bf4455edf34b | 50005 | lockspire-verifier-recovery-locked-builtin-pzh8d1um |
| Minimal installed runtime | command phase minimal_request; no safe facts; 0 receipts | lockspire_clean_room_verifier_recovery_8d3acfb3ed4d4b3998f1e55ace488633 | 51446 | lockspire-verifier-minimal-installed-73kuz1bp |

All temporary roots above were under `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/` (the same filesystem as `/private/var/...`). Synchronous child processes exited. No daemon was started. No Phase 177 database or unknown resource was deleted or modified by diagnostic cleanup.


## Closeout reconciliation — 2026-10-30

The original `investigating` checkpoint above is superseded for the implemented fix by the later independent source/integration/security review of the complete selected closure, the final declared-threat assessment, actual current/minimum installed-package receipts and accepted main `dc3969302152028e2132759eb9edf5a7d260ac39`. See [closeout reconciliation](../../milestones/v1.48-CLOSEOUT-RECONCILIATION.md), [final phase verification](../../phases/178-packaged-upgrade-proof-delivery-handoff/178-VERIFICATION.md), and [actual main acceptance](../../phases/178-packaged-upgrade-proof-delivery-handoff/178-POSTMERGE-ACCEPTANCE.md).

The native acceptance suite was rerun at this unchanged main during closeout: 301 tests passed, exit 0, owned group closed; [safe result](../../milestones/v1.48-CLOSEOUT-PYTHON.json). These later observations satisfy the earlier review/qualification follow-up for the current correction. For the installed-recovery journal, the later root diagnosis owns the `:inets` cause and subsequent fixture corrections; the original diagnostic-only entry did not establish that cause.

This resolves the current debugging work, not unknown predicates or custody from earlier failed runs. Original diagnostic/TDD limits, unknown historical closures, failed attempts, retained resources and formal PARTIAL/Nyquist-false flags remain unchanged. No historical run is restamped, no unknown process is stopped, and no new database/package/application proof, integration or publication is authorized.

Original checkpoint SHA-256: `26eff562ccd47c7ed67ee29dd05d2ace43b0254fb74ec6f8507da41c92d45456`. The body above remains unchanged; only its leading lifecycle status/updated date and this reconciliation changed.
