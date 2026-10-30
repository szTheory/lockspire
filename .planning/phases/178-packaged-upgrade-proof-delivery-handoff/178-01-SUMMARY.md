---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "01"
subsystem: testing
tags: [packaging, phoenix, oauth, postgresql, receipts, clean-room]
requires:
  - phase: 177-safe-verifier-maintenance-recovery
    provides: "Accepted source receipt and frozen Phase 175 compatibility contract"
provides:
  - "Installed locked-pair tracer that issues a token through mounted HTTP and validates a partial strict receipt"
  - "Separate runner and candidate identities with package, vendor, resolved dependency, and compiled-byte bindings"
  - "Pair-independent provider preparation and adversarial finite receipt contracts"
affects: [phase-178-plan-02, packaged-upgrade-proof, delivery-handoff]
actuals:
  tokens: 15391.25
  tasks: 2
  commits: 5
plan_head_before: b5cfa7fc2aa19fd2a695d88f007a442af5b3b647
plan_head_after: 6334c8b6d51ff7b1d09f486d6170b37506029eda
tech-stack:
  added: []
  patterns:
    - "Keep runner identity separate from source-bound package identity"
    - "Validate scenario-group receipts as finite, explicitly partial evidence"
    - "Select and verify dependency pins, lock, cache, and reuse marker independently of admin overlays"
key-files:
  created:
    - scripts/acceptance/clean_room_verifier_upgrade.py
    - scripts/acceptance/clean_room/verifier_receipts.py
    - test/acceptance/client_verifier_tracer_test.py
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-01-01-red-evidence.json
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-01-02-red-evidence.json
  modified:
    - scripts/acceptance/clean_room/package_input.py
    - scripts/acceptance/clean_room/build_provider.py
    - test/acceptance/client_lifetime_boundary_test.py
key-decisions:
  - "Bind the installed checkout package to its source revision only when covered package inputs are clean; keep the runner revision separate."
  - "Configure a dedicated verifier key independently from endpoint and signing keys, and provision an active signing key through the installed public facade."
  - "Keep tracer receipts partial and require exact pair versions, nonempty execution, token issuance, dedicated verifier persistence, and a fresh assertion."
  - "Keep VPROOF-02 pending until the remaining Phase 178 plans complete their assigned coverage."
requirements-completed: []
coverage:
  - id: D1
    description: "One source-bound installed client authenticates over mounted HTTP and receives a token with a validated receipt."
    requirement: VPROOF-02
    verification:
      - kind: e2e
        ref: ".artifacts/phase178/tracer-final/receipt.json#VPROOF-02-INSTALLED-TOKEN"
        status: pass
      - kind: unit
        ref: "test/acceptance/client_verifier_tracer_test.py"
        status: pass
    human_judgment: true
    rationale: "This plan proves the tracer slice only; the full VPROOF-02 requirement remains assigned to later Phase 178 plans."
duration: 36min
completed: 2026-10-26
status: complete
commits: 5
---

# Phase 178 Plan 01: Packaged Upgrade Proof and Delivery Handoff Summary

**A locked Phoenix 1.8.13 / LiveView 1.2.10 host installed the source-bound Lockspire package, issued an authorization-code token over mounted HTTP, and emitted a validated partial receipt.**

## Performance

- **Duration:** 36 minutes
- **Started:** 2026-10-26T17:23:48Z
- **Completed:** 2026-10-26T17:59:26Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added the installed verifier runner with fixed group dispatch, strict receipt loading, and safe failure reporting. Unimplemented groups fail closed.
- Bound the checkout package archive and extracted tree to candidate source identity, while keeping runner identity separate. External source labels without proof remain unavailable; invalid supplied bindings fail.
- Proved one installed locked/builtin host flow end to end: public client registration, fresh login and consent, fresh HS256 client assertion/JTI, HTTP 200 token issuance, and persisted `LSCV1` verifier format.
- Moved pair pins, locks, markers, cache selection, and reuse validation outside the admin overlay switch. Added adversarial contracts for pair drift, identity changes, duplicate JSON keys, incomplete outcomes, skipped cases, unsafe fields, and zero execution.

## Final Installed Receipt

The final command exited 0:

`ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store builtin --group tracer --receipt-dir .artifacts/phase178/tracer-final`

The receipt validator exited 0 with `executed_count=1`. Receipt run ID: `3874dd84ea904892bfd67a9fbf26827a`. The package was version `1.6.1`; archive SHA-256 `5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be`; extracted and installed vendor tree SHA-256 `0aef9c3d4c8f9be0cf5df6afda15b82999888f9fdfffcd953a2ff7b6f6a91232`; compiled candidate SHA-256 `ae9b1fc7df1798da48e1a190e6fa4609b8bdc51c5a18368ac1153f1c18ada5c8`. Candidate and runner revisions both identify committed source `6334c8b6d51ff7b1d09f486d6170b37506029eda`. Host lock SHA-256 is `f77638eeed00fc0a7fa524219ad2fe0c0fd3c147b0436979b925bc4f236f4404`. Runtime was Elixir 1.19.5, OTP 28, PostgreSQL 14.17 (Homebrew). The receipt remains `scope: tracer` and `partial: true`.

The floor pair's generic preparation and exact pin selection passed its contract. This plan did not run the installed floor pair, delegated storage, or the remaining scenario groups.

## Verification

- `python3 -m unittest discover -s test/acceptance -p '*_test.py'` — exit 0, 72 tests passed.
- `python3 scripts/acceptance/clean_room_verifier_upgrade.py --self-test` — exit 0, 16 contract tests passed; output explicitly reports `installed_acceptance: false`.
- `python3 scripts/acceptance/clean_room_verifier_upgrade.py --validate-receipts .artifacts/phase178/tracer-final/receipt.json --pair locked --store builtin` — exit 0, one executed outcome validated.
- `git diff --check` — exit 0.

## Task Commits

1. **Task 1 RED contracts and evidence** — `99e7228a` (`test`)
2. **Task 1 installed tracer and package helpers** — `22a8f203` (`feat`)
3. **Task 2 RED receipt contracts and evidence** — `a3e87871` (`test`)
4. **Task 2 strict receipt and identity validation** — `e598306c` (`fix`)
5. **Task 2 pair-reuse manifest pin hardening** — `6334c8b6` (`fix`)

Measured plan commit count is 5 from `plan_head_before` through `plan_head_after`.

## TDD Gate Compliance

- **Task 1 RED:** The preserved target assertion in `178-01-01-red-evidence.json` was classified `RED_EVIDENCE_OK`; the intended runner/source attribution test failed. The test/evidence commit is `99e7228a`.
- **Task 1 GREEN:** The installed tracer and focused contracts passed in `22a8f203`; the tracer was rerun after that commit before task 2 began.
- **Task 2 RED:** `178-01-02-red-evidence.json` was classified `RED_EVIDENCE_OK`; 10 tests ran and the target framework-pair assertion plus missing token-outcome assertion failed as intended. The test/evidence commit is `a3e87871`.
- **Task 2 GREEN:** Receipt and package identity contracts passed in `e598306c`; the added reused-manifest pin guard passed in `6334c8b6`. Final full acceptance passed 72/72, and the final installed tracer receipt binds `6334c8b6`.

## Files Created and Modified

- `scripts/acceptance/clean_room_verifier_upgrade.py` — fixed scenario dispatcher and installed HTTP tracer.
- `scripts/acceptance/clean_room/verifier_receipts.py` — finite, partial receipt schema and validator.
- `scripts/acceptance/clean_room/package_input.py` — separated runner/source fields and checked archive/tree bindings.
- `scripts/acceptance/clean_room/build_provider.py` — pair selection, cache and reuse validation independent of admin overlays.
- `test/acceptance/client_verifier_tracer_test.py` — package attribution, pair and receipt rejection contracts.
- `test/acceptance/client_lifetime_boundary_test.py` — reusable-host fixture now carries its exact pair pins and lock marker.
- `178-01-01-red-evidence.json`, `178-01-02-red-evidence.json` — unchanged machine-validated RED records.

## Decisions Made

- A clean checkout can name the candidate source revision; the harness revision remains a separate field. External artifact source remains unavailable without a validated source/archive/tree binding.
- The generated host uses an independent dedicated verifier key with `write_mode: :dedicated` and `legacy_read: :reject`. The runner provisions its access-token signing key through the installed public API.
- Receipts for individual groups always remain partial. The strict tracer outcome requires HTTP 200, token issuance, dedicated verifier persistence, and a fresh signed assertion.
- VPROOF-02 is not marked complete by this plan; the remaining Phase 178 plans own additional coverage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Completed the preserved tracer runner execution path**
- **Found during:** Task 1
- **Issue:** The draft had an indentation error, did not dispatch the in-process tracer, used a different dependency cache from provider preparation, and had a malformed framework-version probe.
- **Fix:** Corrected the syntax, tracer dispatch, pair-scoped cache, and Phoenix/LiveView probe.
- **Files modified:** `scripts/acceptance/clean_room_verifier_upgrade.py`
- **Verification:** Focused contracts, self-test, and final installed tracer passed.
- **Committed in:** `22a8f203`.

**2. [Rule 2 - Missing critical functionality] Configured actual dedicated verifier custody and signing**
- **Found during:** Task 1 installed run
- **Issue:** Host setup initially only configured the endpoint/key-encryption key, so client registration produced the legacy verifier form and access-token issuance had no active signing key.
- **Fix:** Generated an independent verifier key for the host runtime, selected dedicated write/reject-legacy behavior, and provisioned an active signing key via the installed public API. Registration also moved to the public facade to set the required HS256 client-auth algorithm.
- **Files modified:** `scripts/acceptance/clean_room_verifier_upgrade.py`
- **Verification:** Final receipt confirms token HTTP 200 and persisted `LSCV1` format.
- **Committed in:** `22a8f203`.

**3. [Rule 1 - Bug] Bound the actual authorization-code flow and safe persisted-state query**
- **Found during:** Task 1 installed run
- **Issue:** The initial tracer omitted the host login-resume request; the verifier probe also tried to start a second endpoint on the server's port and then lacked the Ecto SQL watcher when run without the application.
- **Fix:** Added the intermediate login-resume request and queried the owned database with `mix run --no-start` plus an explicitly started Ecto SQL app and Repo. Token error diagnostics expose only allowlisted protocol text and redacted server log material.
- **Files modified:** `scripts/acceptance/clean_room_verifier_upgrade.py`
- **Verification:** Final installed tracer returned one passing HTTP outcome and the dedicated format projection.
- **Committed in:** `22a8f203`.

**4. [Rule 1 - Bug] Rejected incomplete and mismatched receipt identities**
- **Found during:** Task 2
- **Issue:** The first validator accepted a locked receipt with floor framework versions and treated a false `token_issued` flag as success. Its broad field-name check also rejected the safe boolean `token_issued` field.
- **Fix:** Validate exact pair versions, finite observation keys/types, and all required positive tracer outcomes; keep unsafe fields rejected.
- **Files modified:** `scripts/acceptance/clean_room/verifier_receipts.py`, `test/acceptance/client_verifier_tracer_test.py`
- **Verification:** Full acceptance passed 72 tests; self-test passed 16 contracts.
- **Committed in:** `e598306c` and `6334c8b6`.

**5. [Rule 1 - Bug] Validated supplied source binding on cached external package inputs**
- **Found during:** Task 2
- **Issue:** A reused extracted package could return a supplied source claim without checking that its source proof bound the archive and tree.
- **Fix:** Use the same proof validation for cached and newly unpacked external inputs; a raw source label remains unavailable.
- **Files modified:** `scripts/acceptance/clean_room/package_input.py`, `test/acceptance/client_verifier_tracer_test.py`
- **Verification:** New cached-input rejection contract and the full acceptance suite passed.
- **Committed in:** `e598306c`.

**6. [Rule 3 - Blocking issue] Required exact pins for reused provider pair selection**
- **Found during:** Task 2 full acceptance and final review
- **Issue:** Existing reusable-provider boundary fixtures lacked the selected pair lock/marker; a missing manifest could also defer pair validation until Mix.
- **Fix:** Updated the fixture to carry locked pair pins and lock identity, and require the reused manifest before validating its exact versions.
- **Files modified:** `scripts/acceptance/clean_room/build_provider.py`, `test/acceptance/client_lifetime_boundary_test.py`, `test/acceptance/client_verifier_tracer_test.py`
- **Verification:** Full acceptance passed 72 tests; the final installed tracer passed against the committed helper.
- **Committed in:** `e598306c` and `6334c8b6`.

**Total deviations:** 6 scoped fixes (4 Rule 1, 1 Rule 2, 1 Rule 3). **Impact:** Each correction was needed to produce a trustworthy installed receipt or preserve exact dependency-pair validation; no runtime dependency, schema, protocol, or public Lockspire API change was added.

## Issues Encountered

- The preserved draft's earlier self-test failed with an `IndentationError`; that historical result remains recorded in `178-EXECUTION-CHECKPOINT.md`. During authorized execution, initial tracer attempts also exposed missing dispatcher/cache setup, invalid registration fields, incomplete login resumption, absent host signing/custody setup, verifier-query lifecycle issues, and incomplete receipt acceptance. Each attempt was corrected before the final receipt; no earlier failed receipt was restamped.
- A child GSD commit attempt was denied while creating `.git/index.lock`. The root committed only the explicitly requested task files through the authorized local Git path. No remote refs, merge, or publication were changed.
- The generated receipt is a local ignored artifact at `.artifacts/phase178/tracer-final/receipt.json`; earlier receipt runs remain distinct and retain their original runner identities.

## Auth Gates

None.

## User Setup Required

None.

## Next Phase Readiness

Plan 01's installed tracer is committed and passes end to end, so Plan 02 may expand coverage. This receipt proves only the locked/builtin tracer case. The installed floor pair, delegated storage, and all other groups remain assigned to later plans; VPROOF-02 remains pending.

## Self-Check: PASSED

- Final receipt exists and validates with one nonzero executed outcome.
- All five task commits are ancestors of `plan_head_after`.
- The measured commit ledger contains 5 commits from `plan_head_before` to `plan_head_after`.
- Acceptance suite, contract self-test, and `git diff --check` passed.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Plan: 01*
*Completed: 2026-10-26*
