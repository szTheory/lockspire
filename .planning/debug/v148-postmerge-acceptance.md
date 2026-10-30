---
status: awaiting_integration
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

hypothesis: Ancestry-only provenance conflates commit identity with integration of identical reviewed source.
test: Real Git squash fixtures plus authoritative PR metadata, including negative mutations.
expecting: An authenticated merged PR with an identical full tree provides a narrow squash bridge; changed/unrelated source fails.
next_action: Review the exact local correction and authorize its remote integration plus committed authorization custody; then run fresh exact-main acceptance on the merged SHA.

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

## Eliminated

- hypothesis: The squash changed the reviewed tree.
  evidence: Exact full Git tree identity is equal.

## Resolution

root_cause: Delivery provenance required ordinary Git ancestry after a squash; the synthetic fixture epoch independently made the same invalid HEAD-ancestry assumption.
fix: Preserve strict ancestry for historical evidence; add an authoritative same-repository merged-PR bridge with reviewed-head ancestry, full-tree equality at the squash boundary, and merge containment in selected main. Keep synthetic fixtures tied to their immutable published source/lock epoch.
verification: 298 native pinned Python tests passed; 18 hygiene PASS/zero WARN/BLOCK; five focused squash tests and live PR141 provenance passed. Exact-main gate remains pending integration.
files_changed: scripts/acceptance/clean_room/verifier_delivery.py; test/acceptance/client_verifier_delivery_chain_test.py; test/acceptance/verifier_owner_fixture.py; planning checkpoint/evidence records.
