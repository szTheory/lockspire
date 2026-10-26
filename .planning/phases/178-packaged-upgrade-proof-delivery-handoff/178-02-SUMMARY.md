---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "02"
subsystem: auth
tags: [oauth, client-secret-verifier, phoenix, ecto, postgres, clean-room]
requires:
  - phase: 178-01
    provides: source-bound installed tracer and shared runtime/identity helpers
provides:
  - Installed core verification across locked/floor dependency pairs and builtin/delegated storage
  - Public delegated maintenance adapter witnesses and fixed group-scoped fixture source selection
  - Distinct installed dry-run, apply, fresh-check, unknown-material, and partial-inventory outcomes
affects: [178-03, 178-04, 178-05, 178-06, 178-07, VPROOF-02]
actuals:
  tokens: 13861
  tasks: 2
  commits: 4
plan_head_before: 9544010d5ac142ff0a363b24ea87950b88b7d91b
plan_head_after: e11c490150e6d3e2f68095da01ae08c046914f2d
commits: 4
tech-stack:
  added: []
  patterns: [fixed group-selected clean-room inputs, strict scope-specific receipts, delegated PostgreSQL maintenance witnesses]
key-files:
  created:
    - scripts/acceptance/clean_room/verifier_core.py
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-02-01-red-evidence.json
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-02-02-red-evidence.json
  modified:
    - scripts/acceptance/clean_room/build_provider.py
    - scripts/acceptance/clean_room/verifier_receipts.py
    - scripts/acceptance/clean_room_verifier_upgrade.py
    - test/acceptance/client_verifier_core_test.py
    - test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex
key-decisions:
  - "Keep delegated maintenance authority limited to the exact declared client, transaction, audit, and repository participants."
  - "Select optional verifier fixture files by fixed group ownership and fail when a selected input is missing."
  - "Keep these core receipts partial; VPROOF-02 remains pending until the remaining Phase 178 proof groups complete."
patterns-established:
  - "Installed group receipts bind one executed case to the runner, candidate source, framework pair, and selected storage composition."
  - "Negative delegated authority witnesses report rejection before inventory, fetch, or write callbacks."
requirements-completed: []
coverage:
  - id: D1
    description: "Installed fresh verifier maintenance core passes across both dependency pairs and both supported storage compositions."
    requirement: VPROOF-02
    verification:
      - kind: unit
        ref: "python3 -m unittest discover -s test/acceptance -p 'client_verifier_core_test.py'"
        status: pass
      - kind: integration
        ref: "python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group core --receipt-dir .artifacts/phase178/core"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix test test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs test/lockspire/install/repo_runner_test.exs test/lockspire/install/task_error_test.exs (dedicated migrated DB)"
        status: pass
    human_judgment: false
duration: 33min
completed: 2026-10-26
status: complete
---

# Phase 178 Plan 02: Packaged Upgrade Proof & Delivery Handoff Summary

**Installed verifier core proof now exercises locked and floor dependency pairs with both builtin and delegated PostgreSQL maintenance, including separate preview, apply, and fresh-check outcomes.**

## Performance

- **Duration:** 33 min (approximate; based on the recorded plan execution window)
- **Started:** 2026-10-26T18:01:56Z
- **Completed:** 2026-10-26T18:34:51Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added the installed core group with real HTTP token issuance, dedicated verifier persistence, dry-run, committed apply, a separate nil-cursor check, and fail-closed unknown or partial inventory outcomes.
- Added the host-owned delegated maintenance callbacks and invalid-authority witnesses. Delegated receipts observed callback activity; invalid declarations rejected before maintenance access.
- Reran all four installed cells from clean committed HEAD `fa61823c1b01eb4cf377ac4e0d4c5d48f02ecacd` into `.artifacts/phase178/core-final`. Each final receipt records that exact runner and candidate source revision, package `1.6.1`, Elixir `1.19.5`, OTP `28`, and PostgreSQL `14.17` (Homebrew). Locked resolves Phoenix `1.8.13` / LiveView `1.2.10`; floor resolves Phoenix `1.8.5` / LiveView `1.1.28`. Each cell executed one passing core case.
- Final candidate artifact identity: archive SHA-256 `5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be`, vendor tree SHA-256 `0aef9c3d4c8f9be0cf5df6afda15b82999888f9fdfffcd953a2ff7b6f6a91232`, source proof `2c358959f8c12be4f7b8bd9526411bdca23047f05fc4c1bcce96f350ea77e745`. Locked/floor lockfile SHA-256 values were `f77638eeed00fc0a7fa524219ad2fe0c0fd3c147b0436979b925bc4f236f4404` and `74212156d931add8c5acae6ad67928d08951a6c698cc6f29fec88992af38a954` respectively.

| Cell | Run ID | HTTP/token | Dry-run unchanged | Apply committed | Fresh check | Unknown/partial rejected |
|---|---|---|---|---|---|---|
| locked / builtin | `30e5f4cd08324566a421ee3cc3766020` | 200 / yes | yes | yes | ready | yes / yes |
| locked / delegated | `fb33c10e8df64a208f13ef7bc5b63aee` | 200 / yes | yes | yes | ready | yes / yes |
| floor / builtin | `facdb24a777e43dfacb31e1b42be47e3` | 200 / yes | yes | yes | ready | yes / yes |
| floor / delegated | `1f0492fd50f7460f84e572332fc938f6` | 200 / yes | yes | yes | ready | yes / yes |

The prior receipts under `.artifacts/phase178/core/` are preserved as historical evidence. They record runner/candidate revision `9013e240e930fae932219bdf888b3cac33c8e4d9`, before the all-selector runner change was committed; the runner file was therefore not source-bound to a clean committed checkout. The earlier Task 1 run `7a86a5e4b84c4746a68449f7cafd0ef9` similarly records predecessor runner revision `da3066323ff9c35ff05ed97a518c6c2861591214`. These runs are not counted as the final clean-source matrix; the `core-final/` receipts are.

## Verification

- `python3 -m unittest discover -s test/acceptance -p 'client_verifier_core_test.py'` — passed, 3 tests.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group core --receipt-dir .artifacts/phase178/core-final` — passed; all four receipts were loaded and validated against expected pair/store identities and runner `fa61823c1b01eb4cf377ac4e0d4c5d48f02ecacd`.
- `MIX_ENV=test mix test test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs test/lockspire/install/repo_runner_test.exs test/lockspire/install/task_error_test.exs` with `LOCKSPIRE_TEST_DB_NAME=lockspire_phase178_20261026_owned` after creating and migrating that database — passed, 33 tests, 0 failures. The owned database was dropped afterward.
- Both TDD RED evidence files passed `gsd-tools check tdd-red-evidence` with `RED_EVIDENCE_OK`; the RED commits precede their corresponding implementation commits.
- `git diff --check` — passed.

## TDD Gate Compliance

- Task 1 RED: the selected-source contract and public maintenance callback contract failed as expected; evidence is in `178-02-01-red-evidence.json`. GREEN implementation followed.
- Task 2 RED: the runner rejected `--pair all`; evidence is in `178-02-02-red-evidence.json`. GREEN implementation added finite all-pair/all-store selectors.
- Task commits preserve the sequence: RED `da306632`, GREEN `8a792935`, RED `9013e240`, GREEN `e11c4901`.

## Task Commits

1. Task 1 RED — `da306632` (`test(178-02): add delegated verifier adapter and group-input contracts`)
2. Task 1 GREEN — `8a792935` (`feat(178-02): add delegated installed verifier core proof`)
3. Task 2 RED — `9013e240` (`test(178-02): require all-pair all-store core selection`)
4. Task 2 GREEN — `e11c4901` (`feat(178-02): enable four-cell core runner matrix`)

## Files Created/Modified

- `scripts/acceptance/clean_room/verifier_core.py` — core installed maintenance journey and required observations.
- `scripts/acceptance/clean_room/build_provider.py` — exact optional source selection and narrow public storage source audit.
- `scripts/acceptance/clean_room/verifier_receipts.py` — strict core receipt facts and scope validation.
- `scripts/acceptance/clean_room_verifier_upgrade.py` — fixed pair/store matrix selectors and core dispatch.
- `test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex` — delegated maintenance behavior and callback witnesses.
- `test/acceptance/client_verifier_core_test.py` — selected-input, public callback, and matrix selector contracts.
- `test/acceptance/client_lifetime_boundary_test.py` — optional verifier/JTI public seam regression contracts added after the inherited wave gate.
- `.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-02-01-red-evidence.json` and `178-02-02-red-evidence.json` — TDD RED evidence.

## Decisions Made

- Delegated maintenance uses the host-owned client/transaction adapter while preserving the declared Repository audit and shared PostgreSQL authority. Unsupported or mismatched participant declarations fail before data callbacks.
- Optional fixture inputs are selected by the fixed group map; selected missing sources fail closed. No blanket `Storage` allowlist or checkout test support was added.
- Core receipts remain explicitly partial and do not complete the phase-wide `VPROOF-02` requirement.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing correctness plumbing] Delegate JTI replay persistence through the host-owned client adapter**
- **Found during:** Task 1 installed HTTP authentication.
- **Issue:** Real `client_secret_jwt` token authentication invokes the public `UsedJtiStore` callback; without this narrow delegation the host fixture did not satisfy the selected storage composition.
- **Fix:** Added the explicit `UsedJtiStore.record_used_jti/1` delegation to the host fixture and its exact public source reference.
- **Files modified:** `test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex`, `scripts/acceptance/clean_room/build_provider.py`.
- **Verification:** Locked/delegated HTTP returned 200 and the installed maintenance callbacks were observed.
- **Committed in:** `8a792935`.

**2. [Rule 3 - Required interface plumbing] Extend strict receipts and runner dispatch for the new core group**
- **Found during:** Task 1.
- **Issue:** The core group needed its own exact required facts and dispatch while preserving strict tracer receipts and source attribution.
- **Fix:** Added scope-specific core receipt validation and delegated core dispatch without loosening other scopes.
- **Files modified:** `scripts/acceptance/clean_room/verifier_receipts.py`, `scripts/acceptance/clean_room_verifier_upgrade.py`.
- **Verification:** Focused acceptance test, installed locked/delegated proof, and receipt validation passed.
- **Committed in:** `8a792935`.

**3. [Rule 3 - Required runner interface] Add finite `all` selectors for the four-cell matrix**
- **Found during:** Task 2.
- **Issue:** The planned four-cell verification command could not be expressed because the runner accepted only one pair and store at a time.
- **Fix:** Added `all` choices for pair and store; selection remains bounded to the two declared pairs and stores.
- **Files modified:** `scripts/acceptance/clean_room_verifier_upgrade.py`.
- **Verification:** TDD GREEN unit test and the installed four-cell matrix passed.
- **Committed in:** `e11c4901`.

**Total deviations:** 3 auto-fixed. All were required to run and validate the planned public installed path; no new dependency, schema, arbitrary store scope, or protocol was added.

## Issues Encountered

- An initial source regression attempt against the shared default database encountered stale rows in an unrelated lifetime-client case. The shared database was preserved. A new owned database was used instead.
- The first owned-database run had not yet applied migrations and failed during test-client registration with `:storage_error`. After creating and migrating the owned database, the exact source regression command passed all 33 tests; the database was then dropped.

## Post-wave Compatibility Correction

An inherited acceptance gate found that the builder's boundary audit made verifier-specific maintenance and JTI seams mandatory for every lifetime adapter, including supported non-verifier lifetime-only hosts. This was a false mandatory contract introduced by the Plan 02 allowlist expansion.

- **Correction commit:** `e94dc48c940d8ffaf80ffa59eac572f102a5cdb8` (`fix(178-02): keep verifier adapter seams optional`).
- The audit still requires the established four public lifetime seams: `ClientStore`, `TransactionStore`, `Repository`, and `Domain.Client`. `ClientVerifierMaintenance` is optional. `UsedJtiStore` and `Domain.UsedJti` are optional as a pair; a partial pair fails closed. Nested storage and protocol references remain rejected.
- Focused boundary contracts passed 10/10; focused verifier-core contracts passed 3/3.
- The full acceptance suite at the correction commit passed 77/77 with zero failures or errors. The original 75-test failure remains preserved in `178-WAVE-02-GATES.md`; the two additional tests cover optional JTI pairing.
- No installed rerun was needed because the core verifier host declares the complete optional maintenance/JTI capability set. The correction changes optionality for lifetime-only adapters while leaving the installed core adapter's audit result unchanged.

## Proof Scope

The receipts intentionally cover only the Phase 178 core scope and mark it partial. Later plans own rollout, endpoint, recovery, disclosure, contention, and delivery proof; those limits do not prevent this plan's four core cells from passing.

## Next Phase Readiness

Plans 03–07 can consume the fixed group-source selection and host adapter contracts without changing the shared builder or adapter. `VPROOF-02` remains pending until the complete Phase 178 proof set is assembled and independently evaluated.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Completed: 2026-10-26*

## Self-Check: PASSED

Summary and implementation artifacts exist; all four task commits and correction commit `e94dc48c` are ancestors of the current HEAD. All four `core-final/` receipts validate against their expected cells and the clean runner revision. Full acceptance passes 77/77 at the correction commit.
