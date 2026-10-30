---
status: integrating
trigger: "v1.48 postmerge acceptance after PR 141 squash"
created: 2026-10-30
updated: 2026-10-30
---

## Symptoms

expected: Accept the authorized squash merge after proving its source/evidence identities and exact-main gates.
actual: Main acceptance rejects squash history despite identical merged trees.
errors: Ancestry requirements reject the reviewed branch's commits on squash main.
timeline: PR #141 squash merged at b55eaafc6b01273aad6b72dc6d6301c76cf7fd4f; local main synchronized.
reproduction: Compare reviewed head 4a90525ccef493fc486e2950eecaeff703c88473 with main using the delivery provenance checker.

## Current Focus

hypothesis: Controlled delay confirms that two-second race-fixture budgets can prevent the intended second observation; original intermittent assertion remains unknown.
test: Old-budget delay experiments timeout; the full corrected rejection contract passes with deliberate three-second delays and unchanged outer timeout. Unmodified full diagnostic also passed, separately.
expecting: Review the concrete test-only correction before granting a new exact-source integration authorization; actual main receipt remains required afterward.
next_action: Await approval of 178-POSTMERGE-FIXTURE-TIMING-PROPOSAL.md for local candidate `5e524fd34919f38988e6142aaf1da0e5bff54a98`. Do not repoint prior authorization, push this correction, or waive held acceptance without it. All owned processes closed/data retained.

## Evidence

- timestamp: 2026-10-30
  checked: Live PR #141, synchronized HEAD/main/origin/main, final-head and main trees.
  observed: PR merged to main at b55eaafc; final head 4a90525c and main both have tree 671b2103109d33c61d6d8ed49ed6d0efc02f3dbc. All 1,079 selected input hashes agree; ancestry is false.
  implication: The provenance check has a reproducible false negative after squash.
- timestamp: 2026-10-30
  checked: Postmerge hosted CI 40987320716 and Release 40987320718.
  observed: Both succeeded; all seven canonical CI jobs succeeded.
  implication: Postmerge CI is no longer pending; exact local main acceptance remains separate.
- timestamp: 2026-10-30
  checked: Corrected provenance against live GitHub and original local Git objects.
  observed: Both qualified source e7ad5e67b7c6d00f97ce347b2576b671ddafd811 and reviewed CI head c465f2b8156c2f17db82910452dbcdf16aa8353b are integrated through PR #141's full-tree-identical squash. Five new focused history/authorization tests passed.
  implication: The bridge fixes the actual false negative without relabelling historical executions.
- timestamp: 2026-10-30
  checked: Synthetic receipt fixture epoch validation.
  observed: Five component tests initially failed because the fixture also required its historical epoch to be an ancestor of current HEAD. Binding only to the original immutable published descendant preserves its historical custody; all 21 delivery component tests then passed.
  implication: Synthetic templates must retain their original epoch independently of later squash history.
- timestamp: 2026-10-30
  checked: Full Python acceptance suite, initial unpinned sandboxed attempt.
  observed: 298 tests, two failures, three errors, zero skips/unexpected successes; failures were in native Mix/startup-witness tests. No raw child output retained. Pinned/native rerun is separate and pending.
  implication: Preserve this failed attempt; do not attribute a precise cause until reproduced.
- timestamp: 2026-10-30
  checked: Exact-main acceptance prerequisites.
  observed: Correction is local and uncommitted; 178-INTEGRATION-AUTHORIZATION.json is absent. Exact-main helper requires clean synchronized HEAD/main/origin/main, fresh owned contributor gate, exact push CI and no-publish Release; handoff additionally requires authorization bytes on authoritative main.
  implication: Local provenance success is not accepted-main status. Prepare the concrete change before requesting remote integration authority.
- timestamp: 2026-10-30
  checked: Separate native run with ASDF_ELIXIR_VERSION=1.19.5-otp-28, ASDF_ERLANG_VERSION=28.5 and ERL_FLAGS='+S 4'.
  observed: All 298 Python acceptance tests passed, zero failures/errors/skips/unexpected successes. Both complete ordinary-merge and squash handoff chains passed. Hygiene --ci --skip-mix-ci passed 18/0/0; whitespace and Python compilation checks passed. Protected root package SHA-256 remained 5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be.
  implication: Local correction is verified. Combined runtime/environment changes explain the passing rerun, but do not isolate the precise cause of the original five failures. This is not a fresh canonical Mix gate or accepted-main receipt.
- timestamp: 2026-10-30
  checked: Live retained-candidate identity after the initial local correction commit e857c9c6.
  observed: GitHub returns an empty pull_requests association for CI40954208717 attempt2 and HTTP404 for refs/pull/141/merge. The original seven job checkout logs still authenticate actual checkout 3c7bd2a. An ancestry fix alone was insufficient; candidate validation also conflated historical evidence with today's working bytes.
  implication: Authenticate closed-PR identity using exact attempt/job ownership and checkout logs; revalidate historical source/package bytes at their original authenticated checkout while requiring a separate fresh main gate.
- timestamp: 2026-10-30
  checked: Native historical candidate revalidation, original exec session73388/PID59493.
  observed: Seven jobs and both exact same-attempt artifacts passed, locked14/33 plus floor12/31, validation_scope=historical_candidate. No application/database was started and protected root tar stayed unchanged. Original Hex2.6.0 was required: runtime-local Hex2.4.2 changed only hex_metadata.config. The original source manifest's two recorded digests matched its bytes; its checkout mode0644 was tightened to0600 without changing bytes.
  implication: Original E7AD/c465/3c7bd execution identities remain historical and valid. Failed builder/mode attempts remain recorded in 178-POSTMERGE-CANDIDATE-VALIDATION.json; no main receipt is claimed.
- timestamp: 2026-10-30
  checked: Final native pinned Python gate, original exec session96510/PID56405.
  observed: 299 tests passed, zero failures/errors/skips/unexpected successes; all three source file hashes were unchanged throughout. Complete ordinary-merge and postmerge-squash chains include lost refs, wrong/duplicated/missing checkout logs, wrong closed-PR metadata/attempts, and later tooling changes. 178-POSTMERGE-DEBUG-TESTS-FINAL.json binds these results to actual local HEADe857 plus the exact uncommitted file hashes.
  implication: Final checker correction is reviewable; integration and fresh exact-main acceptance remain pending.
- timestamp: 2026-10-30
  checked: Prospective hosted source selection for the correction.
  observed: Both hosted proof jobs still used --reviewed-candidate-source, whose selector requires exact selected-byte agreement with the historical E7AD closure. Any checker correction changes selected bytes and would be rejected before proof execution. Both steps now pass --expected-candidate-source "$EXPECTED_RUNNER_REVISION" to the existing provisioner and retain their job-owned manifest/digest path. Actionlint passed; final300 native tests passed with zero failures/errors/skips/unexpected successes and all five source hashes unchanged. The source-bound record is 178-POSTMERGE-DEBUG-TESTS-CHECKOUT-PINS.json (original session14143/PID37073). Native exact-checkout provisioning follows at committed source.
  implication: Future CI must prove its actual checkout as fresh source while historical milestone evidence remains frozen at its original identities.
- timestamp: 2026-10-30
  checked: Native provisioner with both source and runner pinned to committed9ffe69f122f9a1d2fd3821ee0bf0bcbf5635094a in a fresh private shared-object checkout, original session63506/PID79518.
  observed: Passed with1079selected inputs and clean source afterward. Archiveeea947dd6a734b60bd502b4d202ecc9cfa7cc7adbdf05bf21d30fa7830f9209c/tree01285ffcc1ef607ebefe39ff02bbf08f50bb0ac44127cef1cd05dbc324bce10b equal the historical package. No app/database started; protected root tar unchanged. 178-POSTMERGE-NATIVE-PROVISION.json retains exact pins and private root.
  implication: The final correction can provision fresh job-owned source without rewriting original proof records or claiming a new runtime acceptance run. Only remote integration/authorization and fresh exact-main gates remain.

## Eliminated

- hypothesis: The squash changed the reviewed tree.
  evidence: Exact full Git tree identity is equal.

## Resolution

root_cause: Ancestry-only integration checks, temporary GitHub PR associations/merge refs treated as permanent, and historical candidate evidence evaluated against today's working bytes. The synthetic fixture epoch independently required invalid HEAD ancestry.
fix: Preserve strict historical identities; authenticate an origin merged-PR/full-tree squash bridge, recover old checkout ownership from all seven exact-attempt job logs, and label historical candidate validation separately from the fresh main gate. Keep synthetic fixtures bound to their immutable source/lock epoch.
verification: Final300 native pinned Python tests passed; live original7-job/26-receipt/64-case historical candidate revalidation passed; hygiene18/0/0 and whitespace/compilation checks passed. Exact-main gate remains pending integration.
files_changed: scripts/acceptance/clean_room/verifier_delivery.py; test/acceptance/client_verifier_delivery_chain_test.py; test/acceptance/verifier_owner_fixture.py; planning checkpoint/evidence records.

## Integration and subsequent local failure — 2026-10-30

- Correction PR143 merged after all canonical premerge jobs passed. Main `3f64e1c6c1af19f0e5f074aff326fa04f7f6b642` passed all seven CI jobs in run41068236671 and no-publish Release41068236662.
- Acceptance attempt3's actual owned source gate passed15 architecture/2187 fast plus2properties/261integration, zero failures; helper later blocked on workflow lookup while hosted CI was pending. Exact failing lookup predicate unknown. Original processes closed and data retained.
- Attempt4, started only after hosted success, failed the fast suite with one failure at repository_hygiene_contract_test.exs:188; integration did not run. Its database was independently absent after cleanup, every child group stopped, and original private PostgreSQL closed. No main receipt emitted.
- Isolated synthetic rejection fixtures passed within their original180second timeout. The two polling-race scenarios have two-second helper budgets, but timing is only a hypothesis, not an established original cause.
- Full diagnostic source run keeps original source/test selection/timeouts; captures only validated locations, fixed exception/predicate labels, counts and hashes. It is diagnostic only. Preserve the safety stop until resolved.

## Controlled fixture timing defect and verified correction

A three-second first fake workflow response makes both old two-second fixtures expire before their second observation. Main advancement then rejects at workflow evidence rather than acceptance identity; run replacement's broad label previously accepted timeout as success. With a3600second helper budget, both reach their intended identity check. The prepared correction retains the existing180second outer test limit, injects that delay, and strengthens replacement-message assertion. The complete corrected contract passed in122seconds; formatting/whitespace checks passed. This independently demonstrates a fixture defect but does not recover the original failed assertion. Evidence and proposal are linked from STATE; local source commit is recorded in the proposal. No new remote operation is authorized or executed. Main acceptance remains held.
