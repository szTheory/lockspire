---
status: verifying
trigger: "Repeated Phase 178 actual delivery producer/consumer false acceptance and rejection gaps"
created: 2026-10-27
updated: 2026-10-27
---

## Current Focus

bug_class: Bohrbug
hypothesis: Separately tested producer and consumer schemas do not describe the same authenticated chain.
test: Exercise actual local producers and consumers with external OS/build/database/GitHub boundaries replaced.
expecting: Existing implementation rejects actual upload/helper output and accepts covered-input and typed-value substitutions.
next_action: Commit exact delivery scope and obtain independent source/security/integration re-review before any fresh runtime or final freeze.
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
