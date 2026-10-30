---
status: resolved
trigger: "Repeated Phase 178 actual delivery producer/consumer false acceptance and rejection gaps"
created: 2026-10-27
updated: 2026-10-30T19:29:56.936128+00:00
---

## Current Focus

bug_class: Bohrbug
hypothesis: Separately tested producer and consumer schemas do not describe the same authenticated chain.
test: Exercise actual local producers and consumers with external OS/build/database/GitHub boundaries replaced.
expecting: Existing implementation rejects actual upload/helper output and accepts covered-input and typed-value substitutions.
next_action: Obtain independent source/security delta review of 5650e596 and its safe full-gate record; do not freeze or start runtime before closure.
reasoning_checkpoint:
  hypothesis: The acceptance boundary trusts divergent hand-selected paths and unchecked values while requiring a serialized layout different from its actual producers.
  confirming_evidence:
    - Native five-case suite at 7c6ff91e produced three assertion failures and two deliberate DeliveryError rejections before edits.
    - Actual wrapper postvalidation copy output adds raw-copies.json and raw files that the existing exact ZIP member check rejects.
  falsification_test: The unchanged actual upload/helper producer output passes and all selected tracked inputs plus known-value mutations are rejected by current code.
  fix_rationale: One commit-tree rule and exact typed serialized contracts remove the independent unchecked authorities; authoritative GitHub observations bind claimed identities.
  blind_spots: Actual hosted and installed runtime are unavailable and prohibited until independent review; controlled authority fixtures prove mechanisms only.
  candidate_causes:
    - code: schema and raw identity checks diverge across producer and consumer
    - config: finite input selection was maintained by isolated filename additions
  and_gate: yes; safe acceptance requires complete source closure AND typed safe receipts AND authenticated external ownership
known_pattern_candidate: none; local knowledge base has no matching resolution
candidate_causes:
  - code: divergent producer/consumer schemas and incomplete nested field contracts
  - config: manually selected covered-input names omit tracked dependencies
and_gate: yes; authenticity needs complete covered bytes, authenticated external identities, and exact producer schema together

## Symptoms

expected: One actual source-to-package-to-hosted-to-helper handoff chain authenticates selected bytes and observations while pending remains truthful.
actual: Independent second reviews found incomplete closure, contradictory judgments, unchecked known values, real upload/helper false rejections, and self-consistent substitutions.
errors: SEC-178-01, SEC-178-05, SEC-178-11, SEC-178-12, SRC-02, SRC-04
reproduction: Controlled external-boundary fixtures calling actual producers and consumers; no runtime or remote mutations.
started: Repeated through second independent re-review of 5fcf9327; original delivery pre-edit RED gap remains historical and is not repaired by later evidence.

## Eliminated

## Evidence

- checked: prior debug knowledge base
  found: no matching resolved pattern
  implication: investigate actual boundary behavior without assuming prior diagnosis
- checked: original and second source/security reports
  found: fixed name list, nested scalar holes, actual ZIP/helper shape mismatch and unauthenticated acceptance graphs recur
  implication: use a finite tracked-tree rule and actual producer-to-consumer tests rather than adding isolated fixture checks
- checked: native pre-edit delivery regressions at 7c6ff91e0d42e434ef8286e09960425a3f062eb9
  found: five executed targets failed natively (three assertions, two actual producer-format rejections); checker subsequently returned RED_EVIDENCE_OK after missing targetTest metadata was added
  implication: classifier invocation occurred after initial edits; this limitation and the earlier delivery original-RED gap remain, with no fabricated earlier checker timestamp
- checked: actual single-chain session 18592, PID 82607, 2026-10-27T08:36:17.454278Z, deadline 240 seconds
  found: one test passed through actual source, pair tree, exact uploaded ZIP, authoritative candidate observation, shell helper collector/validator/emitter and handoff in 40.675 seconds
  implication: proves controlled mechanism only; no live DB/build/GitHub or genuine integration authorization
- checked: final stable session 26109, PID 39848, 2026-10-27T08:44:09.139852Z, deadline 240 seconds
  found: 27 tests, zero failures/errors; full-scope active judgment, covered byte, newly tracked dependency, authoritative base/attempt and package archive substitutions rejected; handoff completed at 29.531 seconds
  report_bytes: 127
  report_sha256: ae4ee45464f93ea3cff75ecaf3d7b5bdabf5b9ad7c0dd8e418c8e4f8222009f5
  test_sha256: c2ad2906f2a5b87ed1c194305b234feeece434c8449991080d9b3b9f14d5254e
  implication: full selected tree stays intact; frozen C, actual source checkout Cf, PR metadata C2, synthetic merge H and subsequent main evidence M remain distinct actual Git commits
- checked: held-out adjacent receipt and actual CI-wrapper suite
  found: 25 tests, zero failures/errors; shell syntax and diff whitespace checks passed
  implication: no observed adjacent regression; full Python gate remains orchestrator-owned at combined committed source
- checked: original receipt implementation restored in isolated in-memory module
  found: original 7c6ff91e known-value target failed once with zero load errors; restored current implementation passed the same target
  implication: counterfactual confirms the typed-value correction causes the regression guard to pass, without reverting shared files
- checked: probe epochs and diagnostic handling
  found: initial fixture failed on owned temp path alias; long session 2318 terminated with harness exit zero but unittest one error and no attributable final-stage mapping because source line numbers changed; context-managed roots and registered guard directories cleaned
  implication: neither failed attempt is acceptance; two exploratory summaries exposed standard exception text (owned temp path ValueError and denied ps PermissionError stack), containing no injected values or child captures; strict enum-only handling deviation preserved
- checked: official GitHub event and REST workflow documentation
  found: PR GITHUB_SHA is the merge-ref commit while REST head_sha and associated PR head/base are separate observations
  sources: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request ; https://docs.github.com/en/rest/actions/workflow-runs#get-a-workflow-run-attempt
  implication: identity check observes run head separately, authenticates PR head/base and merge ref/commit rather than equating PR head with checkout

## Resolution

root_cause: Divergent producer/consumer contracts plus incomplete selected-input and nested-value validation allow self-consistent claims to replace authenticated ownership.
fix: One finite commit-tracked closure and complete typed receipt contract; actual archive/manifest uploaded with exact wrapper output; raw/index owner bindings; truthful frozen/tested/hosted identities; authoritative candidate and main graph/source/authorization observations; actual helper gate runs only through owned source guard.
oracle_type: specified
verification:
  target_test: {result: pass, tests: 27, failures: 0, errors: 0}
  mutation_check: {result: skipped, reason: no Stryker configured; finite field and source/archive/authority mutation controls passed}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true, note: manual path list replaced by complete tracked-tree rule rather than removing checks}
  adjacent_tests: {result: pass, tests: 25, failures: 0, errors: 0}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, note: isolated actual original receipt module, no shared file reverts}
  guardrail_verdict: accepted
files_changed:
  - .github/workflows/ci.yml
  - scripts/acceptance/clean_room/verifier_delivery.py
  - scripts/acceptance/clean_room/verifier_input_closure.py
  - scripts/acceptance/clean_room/verifier_receipts.py
  - scripts/ci/provision_verifier_candidate.py
  - scripts/maintainer/repo_hygiene_check.sh
  - test/acceptance/client_verifier_delivery_test.py
  - test/acceptance/client_verifier_delivery_chain_test.py

## Remaining boundaries

Runtime remains OFF. No actual final freeze, canonical CI, installed package producer, hosted observation, integration authorization, main acceptance, merge or publication is established here. Linux process-authority implementation is independently source reviewed and unit exercised elsewhere; its actual OS branch was not run on this macOS host. Independent source/security/integration review must assess the combined committed corrections before runtime owners may proceed. Historical secret/database incidents, EPERM custody, old wrapper failures, original 13 Phase 175 pins and prior RED/diagnostic deviations remain unchanged.

## Postcommit narrow source-runner seam — 2026-10-27

Parent full gate at f809a40b: 226 executed tests, one error in the unchanged source-guard child-output privacy test, no ordinary assertion failures. Both failed full-gate records remain parent-owned and unchanged.

Narrow reproduction: one test, zero failures, one GuardFailure; no skips or unexpected successes. Actual instrumented cleanup observed identity_registered=false, direct_child_reaped=true, cleanup_result=false. Fixed exception facts: stage=test, reason=process_group_cleanup_unconfirmed. No child data or exception arguments were rendered.

reasoning_checkpoint:
  hypothesis: Source CI's PrivateProcessRunner uses direct Popen, bypassing the owned identity capture now required by the unchanged strict stop_process_group consumer.
  confirming_evidence:
    - Actual cleanup call observed absent registered identity and returned false after reaping the direct child.
    - Source guard creates Popen directly while package_input.stop_process_group requires the identity cached only by start_owned_session.
  falsification_test: A registered launch still yields the same missing-identity failure, or the direct launch already populates the ownership cache.
  fix_rationale: Use the existing owned-session factory at this producer boundary; preserve independent session identity and all cleanup rejection behavior.
  blind_spots: Actual database-backed source CI remains prohibited; only its actual subprocess ownership seam is exercised locally.
  candidate_causes:
    - code: caller bypasses the changed shared ownership API
    - environment: platform process inspection could independently fail despite registered authority
  and_gate: no for the observed failure; absent identity alone deterministically prevents cleanup acceptance, regardless of the already-exited child

Correction: PrivateProcessRunner imports and calls the existing start_owned_session factory. The bounded communicate/stop logic and strict authority consumer are unchanged. Factory owner confirmed that a missing supervisor endpoint disables IPC only; authoritative local identity capture remains mandatory.

Verification: native new real-child authority target failed its fixed assertion before the production edit; RED_EVIDENCE_OK was obtained before that edit. The unchanged child-output privacy target and all guard tests then passed: 16 tests, zero failures/errors/skips/unexpected successes (session 50071, PID 51484, start 2026-10-27T09:00:14.906246Z, deadline 60 seconds). Direct-child callback sees registered authority and cleanup forgets that exact authority. Test-owned fixtures and child sessions completed their normal cleanup.

Caller audit: every other production stop_process_group scenario caller (admin, rollout, endpoints, disclosure, bounded package commands) is factory-backed. Remaining direct Popen sites in build_provider, processes, client_lifetime_upgrade and clean_room_saas_journey use separate lifecycle consumers and are not callers of the changed strict authority API. No package_input or process-registry code was changed. Actual source DB execution remains prohibited; no such command ran.

Counterfactual: loading the actual f809a40b guard source into an isolated in-memory module causes the new real-child authority target to fail one assertion with zero errors/skips/unexpected successes. Restoring the current guard module passes that identical target. No shared file was reverted and no ownership check was weakened.

## Third security re-review string boundary — 2026-10-27

Source fab5a49e669afc6b74515ad40e22feca4866b40a. Original and all independent re-review reports remain untouched. SEC-178-05 reports three actual producer invocation literals accepted as arbitrary nonempty strings. Read actual producer dictionary literals at verifier_endpoints.py and finite receipt consumer/schema before changes. New test reads those literals from the producer AST for its positive and mutates only in-memory copies with generated opaque/base64/hex/percent strings. Full 26-cell string-leaf walk uses boolean fixed-message assertions and no value-bearing subtest parameters.

reasoning_checkpoint:
  hypothesis: Nonempty-string checks accept same-type private payloads in fixed descriptions and insufficiently constrained derived identities.
  confirming_evidence:
    - Independent third security reviewer reproduced all three opaque invocation substitutions at b021d442.
    - Actual producer uses three fixed invocation literals, run_id-derived release node, candidate-version/module-derived path, and issuer-derived rejected audience; consumer only checks nonempty/prefix/inequality for these channels.
  falsification_test: The unchanged validator rejects the generated same-type substitutions while accepting the actual producer literals.
  fix_rationale: Exact producer literals and independently related bounded identities close these finite string channels before raw copying without hiding or changing producer output.
  blind_spots: No runtime or hosted action is authorized; controlled receipt/chain tests establish validator behavior only.
  candidate_causes:
    - code: type-only check used for a fixed description
    - data: a well-typed but semantically arbitrary receipt string
  and_gate: no; a single unchecked invocation field is sufficient to carry private bytes

Native pre-edit evidence: three actual tests at fab5a49e, one producer-literal positive pass, two fixed boolean assertion failures, zero errors. The repeated capture propagated process exit 1 and its exact invocation is retained in 178-10-receipt-strings-native-red.json. RED_EVIDENCE_OK was obtained before editing verifier_receipts.py. The first in-memory collector returned process exit 0 while reporting the same native failing result; it was not accepted as a passing run or used instead of the exit-propagating capture. Prior native/checker timing gaps remain unchanged.

Finite string inventory: 26 fixture cells, 876 string positions, 71 normalized paths, 3,504 generated opaque/base64/hex/percent substitutions. All reject after correction. Dispositions: schema/scope/pair/store/kinds/cases/fleet/public/failure/context descriptions are fixed enums or literals; hashes and revisions use fixed ASCII digest/commit grammars and existing owner/index/Git relationships; versions use bounded 96/128-character lexical contracts; PID uses bounded positive ASCII decimal; release node derives from indexed run_id; loaded beam path derives from candidate version and the exact module; endpoint issuer uses the actual loopback/port/mount grammar with discovered/audience equality and rejected URI derived as /wrong. The three command descriptions now equal the actual producer's literals, and an AST-based positive test detects future producer/consumer drift. No producer source, dependency, public API or independent report changed.

Verification: receipt suite 19/0/0; initial chain/adjacent run 10 tests, zero failures, two ReceiptError errors from legacy positive fixtures containing invented HTTPS issuer/short RPC labels/unrelated node. Only those fixture values were aligned with retained producer evidence and exact descriptions; their missing-case/outside-beam negatives remain. Final stable run session 33136, PID 76066, start 2026-10-27T09:25:19.923058Z, deadline 240 seconds: 29 tests, zero failures/errors/skips/unexpected successes. The actual full source-to-handoff chain completed at 36.696 seconds with 26 cells/64 cases, exact uploaded bytes, authoritative fixture observations and the actual helper collector/validator/emitter. Source SHA-256 3d69d4a6cdc0f90141743313f78e710bfe44a0311da178ebc4d11269e9fd3f76 stayed unchanged during the run. Temporary roots and exact owned fixture sessions completed normal cleanup. No generated mutation value, raw child capture, exception argument or value-bearing test parameter was rendered or persisted.

Counterfactual: the actual fab5a49e receipt module fails the fixed-invocation target once with zero errors/skips/unexpected successes; current module passes that identical target. No shared source was reverted. Scoped whitespace check passed. No full Python gate was repeated and no actual runtime, database, freeze, package producer, hosted observation or remote action ran. Source/security delta re-review is required; these local results do not close the independent finding.

## Fourth re-review: independent package/runtime ownership — 2026-10-27

Read both fourth re-review reports and the fourth ledger section; all independent judgments remain immutable. Native RED at 3c6a0b1d: one target, one fixed assertion failure, zero errors, process exit 1. Four coordinated grammar-preserving version/beam and runtime substitutions were accepted. Exact invocation/native output are in 178-10-receipt-owner-native-red.json; RED_EVIDENCE_OK was obtained before production edits. No generated value was persisted or rendered.

Confirmed mechanism: actual archive metadata and independently selected/observed runtime identity were missing from raw receipt acceptance. The prior grammatical and peer-derived checks only reconciled claims. The fix captures actual verified package version plus source-owned local-current/hosted-current/hosted-minimum selection, exact observed Elixir/OTP, and read-only numeric server_version_num before groups run. Only canonical safe observations are retained, with an independent caller digest. Immutable owner snapshots are required by every accepting validator; raw writers, pair projection, raw-copy producer and actual ZIP consumer compare version/runtime with that authority. The uploaded owner re-derives version from actual authenticated archive bytes and checks the separately selected job profile. Process authority code and original five frozen pins remain unchanged.

Boundary audit: standalone new producers/accepting CLI paths fail closed without captured owner context. Retained observations can use only the explicitly named historical-structure-only full-matrix corroboration path; it emits a distinct nonauthoritative schema with runtime_acceptance=false, preserves original source/validator identities and creates no raw copies or pair index. Pure schema unit checks use private _validate_*_structure seams. Synthetic component contexts are explicitly fixtures, not real package/runtime observations; genuine owner capture and actual package bytes are exercised by the full chain.

Verification facts: owner-bound chain session 7249 passed one test with zero failures/errors/skips/unexpected successes through handoff at 40.437 seconds, including four pre-copy pair mutations and four actual in-memory ZIP coordinated mutations with raw/flat/index/copy digests recomputed. Initial session 63501 failed one DeliveryError after the source/26-cell stage because the hosted fixture selected its canonical rather than job manifest; no later stage was counted passed. Fixture roots and guard directories cleaned before retry.

Real CLI verification: session 87511, PID 24103, start 2026-10-27T10:03:04.543444Z, deadline 240 seconds, passed one full-chain target with zero failures/errors/skips/unexpected successes through handoff at 16.813 seconds. It launches the actual Python pair CLI with independently captured context in the provisioned fixture, derives locked 14/33 and floor 12/31, and exercises local-current for both framework pairs plus hosted-current/hosted-minimum separately. Wrong observed BEAM for the minimum selection is rejected before any context file is created. No genuine DB/package build/GitHub boundary ran.

Component reconciliation: first two 46-test runs each had two subtest failures in the old unowned pair-positive contract. The first collector omitted subtest parent attribution; the second mapped only the pre-discovered parent ID, with no parameters. The pair positive was retained with explicit expected component authority and actual CLI-derived projections. Session 78879 then passed 46 tests with zero failures/errors/skips/unexpected successes. Historical structural checks did not become acceptance.

Wrapper context-path verification: initial 11 tests had four fixed failures because the new capture call omitted explicit phase-dir under the existing external-source test shim; the job-owned manifest case passed. The capture CLI now receives the same explicit repository phase directory as frozen validation. Fixture OS/runtime observations are faked narrowly so no actual DB query runs. Session 57551 passed all 11 tests with zero failures/errors/skips/unexpected successes. No process deadline, signal, registration, ancestry or cleanup logic changed. Scoped whitespace and shell syntax checks passed. Full Python gate follows at committed source; review closure remains independent.

Full gate: committed implementation 5650e596c71259f83020aed941d4a9ce2a2f13b8, session 46929, PID 28432, start 2026-10-27T10:09:24.861388Z, deadline 900 seconds. Native discovery selected and executed 232 parent tests. Failures, errors, unexpected successes, skips, expected failures and loader errors were all zero. Import and test output remained memory-only; safe lengths/digests and counts are retained in 178-10-PYTHON-OWNER-CONTEXT-5650E596.json. No source edit occurred during the run and HEAD remained 5650e596. Context-managed fixture roots and exact owned processes completed cleanup. No full-gate outcome was restamped at the later evidence commit. Runtime remains OFF; independent reviews alone own finding closure.


## Closeout reconciliation — 2026-10-30

The original `verifying` checkpoint above is superseded for the implemented fix by the later independent source/integration/security review of the complete selected closure, the final declared-threat assessment, actual current/minimum installed-package receipts and accepted main `dc3969302152028e2132759eb9edf5a7d260ac39`. See [closeout reconciliation](../../milestones/v1.48-CLOSEOUT-RECONCILIATION.md), [final phase verification](../../phases/178-packaged-upgrade-proof-delivery-handoff/178-VERIFICATION.md), and [actual main acceptance](../../phases/178-packaged-upgrade-proof-delivery-handoff/178-POSTMERGE-ACCEPTANCE.md).

The native acceptance suite was rerun at this unchanged main during closeout: 301 tests passed, exit 0, owned group closed; [safe result](../../milestones/v1.48-CLOSEOUT-PYTHON.json). These later observations satisfy the earlier review/qualification follow-up for the current correction. For the installed-recovery journal, the later root diagnosis owns the `:inets` cause and subsequent fixture corrections; the original diagnostic-only entry did not establish that cause.

This resolves the current debugging work, not unknown predicates or custody from earlier failed runs. Original diagnostic/TDD limits, unknown historical closures, failed attempts, retained resources and formal PARTIAL/Nyquist-false flags remain unchanged. No historical run is restamped, no unknown process is stopped, and no new database/package/application proof, integration or publication is authorized.

Original checkpoint SHA-256: `d3056f66468fe0563b69de718b19cb78a5dbe6ce49380a61bd8904d4f764a18b`. The body above remains unchanged; only its leading lifecycle status/updated date and this reconciliation changed.
