---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "05"
subsystem: testing
tags: [elixir, ecto, postgresql, clean-room, verifier-maintenance, concurrency, rollback]
requires:
  - phase: 178-02
    provides: installed package builder, delegated host adapter, fixed verifier fixture overlay, and partial receipt contract
provides:
  - Installed PostgreSQL contention witnesses for both maintenance/rotation lock orders on locked and floor pairs
  - Installed valid audit INSERT rollback, caller outer rollback, and nested report commit-order witnesses
  - Strict finite receipts bound to installed candidate, pair, delegated store, runtime, and exact witness outcomes
affects: [178-06, 178-07, 178-10, VPROOF-02]
actuals:
  tokens: 10366
  tasks: 2
  commits: 10
plan_head_before: 77b9708297546d13f0d34d7e7e0e413913b29b7b
plan_head_after: d050519b7ac76c6637f5a46636f0936c1b9b76ff
tech-stack:
  added: []
  patterns:
    - Independent Repo transaction barriers with exact pg_blocking_pids verification
    - Run-owned audit trigger and sequence witness after strict metadata validation
    - Safe receipt projection with verifier and ciphertext comparisons held in memory
key-files:
  created:
    - scripts/acceptance/clean_room/verifier_transactions.py
    - test/clean_room/provider_host/lib/clean_room_provider/verifier_transactions.ex
    - test/acceptance/client_verifier_transactions_test.py
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-05-01-red-evidence.json
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-05-02-red-evidence.json
  modified:
    - scripts/acceptance/clean_room/verifier_receipts.py
    - scripts/acceptance/clean_room_verifier_upgrade.py
key-decisions:
  - "Keep contention and atomicity entrypoints in one ordinary host-owned verifier_transactions module, dispatched explicitly by group."
  - "Run the group-owned Repo pool at eight connections so concurrent holders, contenders, observers, and host processes have capacity."
  - "Keep VPROOF-02 pending until the remaining Phase 178 proof owners pass."
patterns-established:
  - "Capture PostgreSQL backend IDs inside the exact selected transaction that performs the contested operation."
  - "A contention case passes only after the exact holder PID appears in pg_blocking_pids(contender) before release."
  - "A valid audit failure is proven by an advanced run-owned sequence, unchanged persisted ciphertext, and no committed matching audit."
requirements-completed: []
coverage:
  - id: D1
    description: "Installed delegated maintenance and rotation prove both lock orders on locked and floor dependency pairs."
    verification:
      - kind: integration
        ref: ".artifacts/phase178/contention-final-v7/{locked,floor}-delegated/receipt.json"
        status: pass
      - kind: unit
        ref: "python3 -m unittest discover -s test/acceptance -p 'client_verifier_transactions_test.py'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Installed valid audit INSERT rollback, caller rollback, and nested-report commit order pass on both dependency pairs."
    verification:
      - kind: integration
        ref: ".artifacts/phase178/atomicity-final-v2/{locked,floor}-delegated/receipt.json"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_concurrency_test.exs (dedicated database)"
        status: pass
    human_judgment: false
duration: "31min"
completed: 2026-10-26
status: complete
---

# Phase 178 Plan 05: PostgreSQL Transaction Witnesses Summary

**Installed locked and floor hosts now prove both verifier-maintenance lock orders and three distinct audit/rollback/reporting outcomes through delegated PostgreSQL storage.**

## Performance

- **Duration:** About 31 minutes, including preserved failed attempts and reruns.
- **Started:** 2026-10-26T21:08:00Z (approximate; the dispatch did not record an exact start timestamp).
- **Completed:** 2026-10-26T21:39:27Z.
- **Tasks:** 2/2.
- **Files modified:** 7 tracked files, including the two RED evidence records.

## Accomplishments

- Added `verifier_transactions.py` as the shared group runner and `CleanRoomProvider.VerifierTransactions` as ordinary generated-host code. The installed host imports no checkout test support, private production debug hook, or repository implementation module.
- Both `locked/delegated` and `floor/delegated` receipts passed strict validation for rotation-first stale-material conflict and maintenance-first coherent rotation. Each case used distinct PostgreSQL holder and contender backend IDs and observed the exact holder in `pg_blocking_pids(contender)` before releasing the held transaction.
- Both pairs passed the valid-audit-INSERT failure case. The trigger sequence advanced, persisted verifier ciphertext remained unchanged, and no matching audit row committed. Separate cases proved a provisional low-level replacement rolled back with its caller transaction and that reporting rejected an already-open transaction before mutation, with a success report only after completion.
- Added strict exact case sets, PID relation checks, boolean witness checks, safe receipt fields, and behavioral CLI dispatch coverage. Missing or malformed witnesses fail closed.
- The installed receipts preserve their observed source identities: contention receipts bind runner/candidate revision `8d5e2b89e35a19f85e5578ca60a9541fb01a43d6`; atomicity receipts bind `88ecf964f5154ded82563075fcc9ade2aa936187`. They remain partial proof-group receipts; later Phase 178 final-source proof will rerun selected groups at its own source identity.

| Group | Pair | Store | Executed cases | Result |
| --- | --- | --- | ---: | --- |
| Contention | locked | delegated | 2 | pass |
| Contention | floor | delegated | 2 | pass |
| Atomicity | locked | delegated | 3 | pass |
| Atomicity | floor | delegated | 3 | pass |

## Verification

- `python3 -m unittest discover -s test/acceptance -p 'client_verifier_transactions_test.py'` — 4 tests passed.
- `python3 -m unittest discover -s test/acceptance -p '*_test.py'` — 104 tests passed.
- Installed contention command — 4 executed cases across the required two pairs; both receipts validate with `--validate-receipts`.
- Installed atomicity command — 6 executed cases across the required two pairs; both receipts validate with `--validate-receipts`.
- `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_concurrency_test.exs` with newly created `lockspire_phase178_05_owned_f59d8792` — 11 tests, 0 failures. The exact owned database was dropped after the run.
- Clean-room generated host compile preflight passed before the installed matrix. Python compilation, Elixir parse check, and `git diff --check` passed.
- The generic `python3 -m unittest discover -s test/acceptance` command discovered 0 tests because this repository's acceptance files use the `*_test.py` naming pattern. The explicit full-suite pattern above discovered and passed 104 tests; this was a command-pattern mismatch, not a skipped acceptance suite.

## TDD Gate Compliance

- Task 1 and Task 2 both have named target assertions in the same pre-implementation RED report because they own overlapping runner, receipt, and test files. The unchanged report recorded three expected assertion failures; `178-05-01-red-evidence.json` targets dispatch and `178-05-02-red-evidence.json` targets the atomicity finite case contract. Both records returned `RED_EVIDENCE_OK` from `gsd_run check tdd-red-evidence`.
- The shared behavioral RED suite was committed at `72e9f233` before implementation. The first implementation and host witness were committed at `219e3986`; subsequent implementation fixes are recorded below and each was committed before the final installed runs.
- GREEN: the focused suite passed 4/4, the full harness suite passed 104/104, source integration passed 11/0, and the four installed pair/group cells passed with nonzero exact case counts.
- REFACTOR: no production schema, runtime dependency, protocol, storage authority, shared builder, or adapter change was introduced.

## Task Commits

1. **Task 1 RED:** `72e9f233` — transaction group dispatch and finite witness contracts.
2. **Task 1 GREEN:** `219e3986` — installed contention/atomicity runners, host witness, and receipt validation.
3. **Task 1/2 corrections:** `a0bff3d4`, `9076e632`, `68b3be59`, `79329e8b`, `f59d8792`, `8d5e2b89`, `88ecf964` — host startup, predecessor-key fixture, connection headroom, transaction PID capture, and report outcome assertions.
4. **Task 2 RED evidence:** `d050519b` — second named target record from the original pre-implementation RED report.

**Plan commits measured from the persisted ledger:** 10 through `d050519b7ac76c6637f5a46636f0936c1b9b76ff`.

## Files Created/Modified

- `scripts/acceptance/clean_room/verifier_transactions.py` — source-bound locked/floor installed group setup, safe child output capture, and receipt construction.
- `test/clean_room/provider_host/lib/clean_room_provider/verifier_transactions.ex` — committed fixtures, in-transaction backend IDs, barriers, exact blocker polling, audit sequence trigger, and rollback/report observations.
- `scripts/acceptance/clean_room/verifier_receipts.py` — exact contention and atomicity cases and allowlisted positive witness validation.
- `scripts/acceptance/clean_room_verifier_upgrade.py` — explicit shared module dispatch for both transaction groups.
- `test/acceptance/client_verifier_transactions_test.py` — behavioral CLI dispatch and strict receipt rejection contracts.
- `178-05-01-red-evidence.json`, `178-05-02-red-evidence.json` — named RED records.

## Decisions Made

- PostgreSQL backend IDs are queried from inside each selected transaction, then compared as integers; a separate pool checkout is not accepted as the transaction identity.
- The generated host pool is raised to eight only within this transaction-proof host to reserve independent connections for holders, contenders, and observers.
- The audit trigger increments a unique run-owned sequence and then fails a valid audit INSERT; invalid metadata preflight is not used as rollback proof.
- `VPROOF-02` remains pending until its remaining Phase 178 evidence owners complete.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Boundary correctness] Removed a forbidden repository implementation reference from the host witness.**
- **Found during:** Task 1 compile preflight.
- **Issue:** The ordinary host source boundary audit rejected `Lockspire.Storage.Ecto.Repository`.
- **Fix:** Removed the unused alias; witness operations use the configured delegated callbacks and public client/admin operations.
- **Verification:** Provider boundary audit and generated host compile passed.
- **Committed in:** `219e3986`.

**2. [Rule 1 - Witness identity] Capture backend IDs inside the transaction that performs the operation.**
- **Found during:** Task 1 installed contention run.
- **Issue:** A PID fetched before `Store.transact` could belong to another pool checkout, so the exact blocker relation was absent.
- **Fix:** Capture `pg_backend_pid()` inside each selected transaction callback before the operation starts; receipt validation requires distinct IDs and the exact observed blocker.
- **Verification:** Both lock orders passed on both pairs with the recorded holder/contender IDs.
- **Committed in:** `8d5e2b89`.

**3. [Rule 1 - Fixture correctness] Seed authenticated predecessor-key material.**
- **Found during:** Task 1 installed contention run.
- **Issue:** New-key registration produced already-current material, so no legitimate predecessor-to-current replacement existed.
- **Fix:** Seal the committed fixture under the configured predecessor key in memory before each witness.
- **Verification:** Contention and atomicity cells passed and compared durable state without serializing secret or ciphertext values.
- **Committed in:** `68b3be59`.

**4. [Rule 1 - Report assertion] Recognize the public error report for a nested maintenance call.**
- **Found during:** Task 2 installed atomicity run.
- **Issue:** The admin API returns an error report map when mutation is rejected inside an open transaction, rather than the lower-level fixed error atom.
- **Fix:** Assert the error report has failed rows, the persisted row is unchanged, and no success report is returned before the transaction closes.
- **Verification:** Both atomicity receipts validate the nested rejection and post-transaction success report.
- **Committed in:** `88ecf964`.

**5. [Rule 3 - Runtime capacity] Provision pool headroom inside the generated proof host.**
- **Found during:** Task 1 installed contention run.
- **Issue:** The initial pool size raised a possible capacity concern for two transactions, a blocker observer, and application processes; the recorded failed witness later established a backend-ID/transaction identity mismatch as the concrete blocker-witness cause. Pool starvation was not independently established.
- **Fix:** Set only the generated transaction-proof host pool to eight before its runtime starts; shared builder and host policy remain unchanged.
- **Verification:** Both pair/group cells completed with observed independent blocker relations after the transaction backend IDs were captured in their own callbacks. Pool headroom is a precaution, not a demonstrated root-cause fix.
- **Committed in:** `79329e8b`.

**Total deviations:** 5 auto-fixed. All changes stay within the planned runner, generated host witness, and strict receipt scope. No product API, production storage behavior, schema, or dependency changed.

## Issues Encountered

- The first runner invocation omitted Lockspire application context initialization; the retry initially started the host Repo twice. The final `--no-start` command starts the Repo first and Lockspire second. These failed attempts are preserved under `.artifacts/phase178/contention-final/` and `.artifacts/phase178/contention-final-v2/`.
- A later failure waited for a BEAM PID although the host reported an integer PostgreSQL backend ID. After correcting the matcher and querying inside the selected transaction, exact blocker observations passed. The intermediate attempt logs remain under `.artifacts/phase178/contention-final-v3/` through `contention-final-v6/`.
- The first atomicity receipt correctly failed closed because its nested report assertion expected an error atom. The fix accepts only a failed public error report plus unchanged persisted state. That failed attempt remains under `.artifacts/phase178/atomicity-final-v1/`.
- The pool-size increase was a capacity provision from the declared two-transaction-plus-observer requirement; the confirmed missing blocker cause was the backend-ID capture/matcher mismatch.

## User Setup Required

None.

## Next Phase Readiness

- Plan 06 can consume the shared transaction runner and exact witness receipt schema.
- `VPROOF-02` remains pending phase-wide. These four installed receipts establish only this plan's contention and atomicity cases.
- Merge, hosted CI, exact-main acceptance, and publication are outside this plan's authorization.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Completed: 2026-10-26*

## Self-Check: PASSED

- Summary and all three planned implementation artifacts exist.
- All ten measured plan commits are ancestors of the current HEAD.
- Both contention and both atomicity receipts validate against their pair/store identities and required case counts.
