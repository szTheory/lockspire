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
- Ran all four installed cells against source revision `9013e240e930fae932219bdf888b3cac33c8e4d9`, package `1.6.1`, Elixir `1.19.5`, OTP `28`, and PostgreSQL `14.17` (Homebrew). Locked resolves Phoenix `1.8.13` / LiveView `1.2.10`; floor resolves Phoenix `1.8.5` / LiveView `1.1.28`. Each cell executed one passing core case.

| Cell | Run ID | HTTP/token | Dry-run unchanged | Apply committed | Fresh check | Unknown/partial rejected |
|---|---|---|---|---|---|---|
| locked / builtin | `b332705b49b24d8abc348dbf83632147` | 200 / yes | yes | yes | ready | yes / yes |
| locked / delegated | `d9ba38de75a3403a9fa02f463a111aee` | 200 / yes | yes | yes | ready | yes / yes |
| floor / builtin | `1c0c0c0604f741a1b2d7d18830bafe50` | 200 / yes | yes | yes | ready | yes / yes |
| floor / delegated | `cb6c94e7d1db4199a90fc970203694fc` | 200 / yes | yes | yes | ready | yes / yes |

The Task 1 locked/delegated installed run also passed with one executed case: `7a86a5e4b84c4746a68449f7cafd0ef9`, source/runner revision `da3066323ff9c35ff05ed97a518c6c2861591214`.

## Verification

- `python3 -m unittest discover -s test/acceptance -p 'client_verifier_core_test.py'` — passed, 3 tests.
- `python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store all --group core --receipt-dir .artifacts/phase178/core` — passed; all four receipts were loaded and validated against their expected pair/store identities.
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

## Proof Scope

The receipts intentionally cover only the Phase 178 core scope and mark it partial. Later plans own rollout, endpoint, recovery, disclosure, contention, and delivery proof; those limits do not prevent this plan's four core cells from passing.

## Next Phase Readiness

Plans 03–07 can consume the fixed group-source selection and host adapter contracts without changing the shared builder or adapter. `VPROOF-02` remains pending until the complete Phase 178 proof set is assembled and independently evaluated.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Completed: 2026-10-26*

## Self-Check: PASSED

Summary and implementation artifacts exist; all four task commits are ancestors of the current HEAD.
