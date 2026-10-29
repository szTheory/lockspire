---
status: diagnosed
trigger: "Parent-assigned diagnosis of e13 locked rollout ReceiptError; no source fixes or remote mutations"
created: 2026-10-29
updated: 2026-10-29
---

## Current Focus

hypothesis: Actual Hex2.6.0 rebuilds the pinned predecessor with different generated metadata, so its archive and package-tree identities disagree with the independently pinned Hex2.5.1 bytes and native rollout rejects at e13 verifier_receipts.py:561.
test: Native rejection location, three retained native offline builds, and independent owned read-only actual version markers all support the mechanism.
expecting: Parent can correct the scoped build-toolchain selection while retaining strict source/package validation and all failed attempts.
next_action: Return terminal diagnosis and witness JSON to parent; no source/workflow edits, helper modifications, or additional runtime are authorized in this subtask.
bug_class: Bohrbug for the reproduced current-home mismatch; original rejected predicate was not retained and is not retroactively assigned.
candidate_causes:
  - code: receipt assembly or predicate disagreement
  - environment: transient installed-run state or cleanup failure
  - data: missing or differently shaped rollout receipt fact
and_gate: yes; the failure requires a current builder producing Hex2.6.0 metadata while predecessor byte authority remains pinned to the Hex2.5.1-generated archive/tree. The same source with actual Hex2.5.1 reconstructs the pinned bytes exactly.

## Symptoms

expected: Locked installed verifier pair emits valid core, rollout, and disclosure receipts.
actual: Native locked pair failed after two core receipts and before a rollout receipt; failed attempt preserved.
errors: ReceiptError type validated against source AST; original finite rejected predicate unavailable.
reproduction: Fresh-owned PostgreSQL and newly captured native selected owner, exact e13 frozen candidate and runner, rollout/builtin/locked group.
started: First observed in native epoch lockspire178-e13-native-3fml_p78, collect-verifier-locked-6c4w3not.

## Eliminated

None established. Later successful runs cannot diagnose the original failure.

## Evidence

- checked: epoch.json and accepted helper definitions
  found: Both source and runner are e13a71976f216c8953e060729825b821a3e6eba5; accepted driver and coordinator hashes match parent-provided identities.
  implication: New diagnostics must preserve accepted helper bytes and pin fresh receipt ownership to the same frozen artifact.
- checked: .planning/debug/knowledge-base.md
  found: No matching rollout ReceiptError resolution; no configured project agent skills.
  implication: Proceed with native finite location capture; do not assume a known cause.
- checked: Native driver profile branch and cleanup
  found: Dependent cleanup is sticky false before inner profile launch; original PostgreSQL shutdown is independent; all private data is retained by policy.
  implication: Diagnostic branch must preserve these ownership and retention boundaries.
- checked: Pure constructor-observer fixture against the committed structural validator
  found: Invalid empty rollout input triggered validated tracked raise at verifier_receipts.py:515; original exception type and constructor argument identity were preserved; untracked constructor calls failed observation closed.
  implication: The observer can locate a native receipt rejection without recording its message, arguments, local values, or stack. This fixture does not diagnose the original runtime failure.
- checked: New helper static compilation, source blob comparison, and epoch hashes
  found: All four helpers parse; three tracked observer target files byte-match committed e13; accepted epoch helper hashes remain unchanged. New helper pins and native-baseline diff are recorded under the private epoch.
  implication: Runtime remains gated on the parent-requested security review. No native attempt has yet been launched.
- checked: Independent security review of v1
  found: Original Popen was appended to the observer capture list after identity lookup; a failing lookup could lose access to that handle before the native caller received it. No other v1 delta blocker was found.
  implication: v1 was never run and remains preserved. v2 captures the original Popen/token=None first, then guards original token lookup and journaling locally while returning the original process unchanged.
- checked: Pure fixtures executing the exact v2 owned_start AST
  found: Failing token lookup retains and returns the original Popen; failing journal preserves the original token and returns the original Popen; successful observation preserves both. No child processes were launched by these fixtures.
  implication: Observer failure marks metadata false without interrupting the native caller's cleanup path. All v2 helpers parse, and exact hashes/diff were sent to parent and security reviewer.
- checked: Read-only Git export of the independently pinned predecessor
  found: Current git archive SHA256 equals the committed PREDECESSOR_SOURCE_ARCHIVE_SHA256, 67a9daf5a54cb104e5647e3de3a7372b0eeee896189c2c043409e2497784f5a6.
  implication: Current source-export bytes agree with the static source proof pin. This does not identify the original rejected runtime predicate.
- checked: Independent exact-hash v2 static acceptance and parent continuation
  found: Security accepted observer896ea984cdf1b924042f005ea7a8a6309c2b54f12954509161118f07dcb22ee5, driver928f3b13b1cb11ae7c88b20ffbb8d295437a0a7998fc04cec96b1c8e5f3083b9, coordinator09c7de3f0aa31c35993bbc94353f2b83d0f20e795b6cf74bcbad81321b407878, collector53c63ddb8642a6915d56243d70b273a813baec4656a31f2bcaf0d2e4a2028178. Parent explicitly authorized one fresh owned PostgreSQL diagnostic.
  implication: Proceed with bounded diagnostic collection only; no native proof acceptance or original failure attribution is implied.
- checked: First v2 diagnostic collector, collect-diagnose-rollout-rejection-locked-6yj8jn1u/result.json
  found: initdb exited 1 (stderr classification unknown; byte count345, SHAbe73f35d300e7d113048c7e7eb9d80d5671bf7c6ed7a1a17f6f2f2d84b027aa7). Original initdb and outer groups stopped, server null, no owner or inner journal, invalid metadata0; all private data retained. Native group was never launched.
  implication: This is a distinct pre-runtime initialization failure, not rollout evidence. Retry unchanged reviewed helper with automatic review for unsandboxed local execution; retain the failed attempt.
- checked: Second unchanged v2 diagnostic, tool session76688
  found: Native owner receipt exists under fresh diagnostic-rollout-rejection-locked-e13-v2. Inner journal2ca7d801c0a544e1a31f8aab2d21829a records16 starts/15 confirmed stops at observation; one owned native command is active.
  implication: Real rollout is executing. No terminal failure or pass conclusion is available yet; first pre-runtime failure remains preserved separately.
- checked: Terminal finite witness in collect-diagnose-rollout-rejection-locked-zfgwk31d/result.json
  found: Native runner_exit1; receipt_error_count1; exact validated location scripts/acceptance/clean_room/verifier_receipts.py:561; native_raised false; observer_ok true; diagnostic_status observed. Collector diagnostic_collected true only certifies diagnostic collection, never native proof success.
  implication: Fresh real rollout rejected the predecessor source-owner identity predicate. This is a new reproduced failure; original ci-locked remains failed and its original rejected predicate remains unavailable.
- checked: Exact e13 source at verifier_receipts.py:555-561
  found: Rejected OR predicate checks predecessor kind accepted-git-source, version1.6.1, independently pinned source revision/archive SHA/tree SHA, and a finite compiled-candidate SHA. The immediately preceding exact field-set check did not reject.
  implication: The actual finite category is predecessor provenance binding. Location-only observation does not distinguish which member of this OR predicate differed.
- checked: Diagnostic terminal process custody and private PostgreSQL boundary
  found: Fresh PG port53368 with matched private data directory, loopback, and port; native selected owner and all owner checks true. All48 inner original groups independently absent; observer and outer groups stopped; exact original PG3756/start1793268385.949228 stopped. Driver dependent cleanup remains false and PG data/root retained by policy. No metadata projection errors.
  implication: Bounded diagnostic is terminal, with original handles/tokens preserved and no borrowed/re-enrolled cleanup authority. Failed initial attempt, original locked attempt, accepted helpers, and protected root tar remain untouched.
- checked: Actual reviewed coordinator MIX_HOME selections and read-only directory inventory
  found: Current home has only hex-2.6.0; minimum home has only hex-2.5.1. The failing native run used the current home. The exact PG root bound to observed private port53368 is /private/tmp/lockspire178-owned-pg-e13a7197-29li3w3d, and root/data both still exist.
  implication: Hex metadata drift is a specific environment/data hypothesis. Parent requested offline bound builds to identify the false predecessor comparison(s); later success alone must not diagnose the failure.
- checked: Independent static review of exact no-DB predecessor helper
  found: Security accepted SHAa83dbc2901cc46c93b7dcd690ad4bad366b15893c2506b104a99c50fa6f8ced6. Native builder/export/unpack has no provider, DB, source-test path, or predecessor hex.build alias invoking them. Reviewer cautioned that runtime/Hex labels denote configured selection and unique archive-directory inventory, not an additional fresh version observation.
  implication: Execute the parent-requested offline comparison with retained artifacts and finite public digest flags, preserving that evidence limit.
- checked: Three native no-DB predecessor builds, retained predecessor-offline-bfbpi725/result.json SHA7245761532a531be547f07bc5d9c17e8c4d93ec6ad679fb19a1fdae53b944216
  found: Actual current home produces archivefe9e88780a5c7fdd395b6f03349d3ef71c21a77518833a38055676958744dda5 and treec5d441d1a77b8978c63c3a44f4c09b61420df5a6f6f81f24c5b1354a799b613d, failing both pins identically on repeat. Reference home produces exact pinned archive792967609e41d216fc0178ef069570c39350c9bb5ee481da4e2852993267e758 and tree2dcf7705bd5651e853a02a931a1e0c595639438b3bd0a36a9c330017eab98315. Both homes match kind/version/source/export/Git-tree comparisons. Only extracted file differing is hex_metadata.config. All9 original owned groups independently absent; no DB environment; all artifacts retained.
  implication: Archive and package-tree comparisons at observed verifier_receipts.py:557-558 are reproducibly false under the actual current-home selection. The reference home restores the independently pinned artifact bytes with unchanged committed source. Compiled host identity was not evaluated offline.
- checked: Independent exact-hash version-probe static acceptance
  found: Security accepted SHA25c7d0c027836250fc128c43c6ada41c389ef9ba3f09e3a38b27d4691e488e9e for fixed no-start/no-compile/no-deps-check expressions, private HEX_HOME/cleared DB environment, original ownership cleanup and finite marker validation.
  implication: Proceed with parent-requested bounded read-only tool observations. This static review certifies no runtime versions.
- checked: Direct no-start version observations, predecessor-version-probe-t802g0l9/result.json SHA8740f1fca10317ed075cd498021701057fadec07d40fa6d1b709973a2ec249f3
  found: Actual current home emitted Elixir1.19.5, OTP_VERSION28.5, Hex.version2.6.0; offline reference home emitted the same Elixir/OTP and Hex.version2.5.1. Both cases exited0 with three finite markers and unchanged archive bytes. The extra original-H175-current-home case exited1 with no markers; its archive tree was already empty before invocation despite retained hex-2.5.1 directory names. Whole probe remains failed, all3 original groups stopped, and the failed record is preserved.
  implication: Actual current/reference versions independently bind the native rebuild difference to Hex2.6.0 versus2.5.1. No actual H175-home version claim is made, and its empty archives are not repaired or modified.
- checked: Final integrity and retention checks
  found: Accepted epoch and diagnostic-v2 helper hashes unchanged; diagnostic clone remains exact e13 with clean tracked files; private PG data retained; protected user tar remains SHA5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be.
  implication: Diagnosis introduced only new private helpers/artifacts and new phase diagnostic records. No production fix, commit, remote mutation, original receipt overwrite, or borrowed cleanup authority was used.

## Resolution

root_cause: Current execution selects actual Hex2.6.0, whose generated predecessor hex_metadata.config changes the archive and extracted package-tree identities from the independently pinned Hex2.5.1 bytes. Native rollout rejects that predecessor source-owner mismatch at committed e13 verifier_receipts.py:561. Bound offline builds reproduce both false archive/tree comparisons and reconstruct exact pinned bytes with actual Hex2.5.1, unchanged source, and the same observed Elixir1.19.5/OTP28.5 runtime. The original locked attempt's exact rejected predicate remains unretained.
fix: none; diagnosis only
verification: exact-hash static security accepted all executed helpers; pure constructor/custody failure fixtures passed; actual native rollout failed at a committed e13 raise location; deterministic actual-home offline digest mismatch repeated twice; reference-home build exactly matched both independent pins; only hex_metadata.config differed; direct actual current/reference version observations succeeded with archive bytes unchanged. All48 native inner groups,9 offline groups,3 version groups, observer, outer, and exact original PG groups stopped. Data retained. Full version probe remains failed because the extra original-H175 archive directory has no regular files and its case yielded no version markers. No proof pass is claimed.
files_changed: []
