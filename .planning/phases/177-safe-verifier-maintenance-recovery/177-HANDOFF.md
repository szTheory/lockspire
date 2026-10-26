# Phase 177 Source Handoff

## Tested source identity

Current source acceptance is bound to corrected commit `5e8cd65e6a45deee205c79a0f23592be68c0ffb8` on `milestone/v1.48-client-auth-key-isolation`. The canonical `mix ci` command ran from `/Users/jon/projects/lockspire` with Elixir 1.19.5, OTP 28.5, `ERL_FLAGS='+S 4'`, `MIX_ENV=test`, and the owned database `lockspire_phase177_20261026_owned`. It exited 0 on 2026-10-26 from `04:25:52.521Z` through `04:30:18.138Z` (265.625 seconds, measured with a monotonic clock). The earlier successful `8bae1a30`, `6aca1b86` and `75988f42` acceptances remain archived in the receipt. Its exact stages and output digest are in [177-SOURCE-ACCEPTANCE.json](177-SOURCE-ACCEPTANCE.json).

The gate reported 15 boundary tests, 2 properties and 2,138 `test.fast` tests with 0 failures (6 skipped, 568 excluded), then 261 integration tests with 0 failures (46 excluded). Credo checked 721 source files with no issues. Compile with warnings as errors, Sobelow, docs checks, and package build also exited successfully. These are source contributor checks; package installation/composition, publication, delivery, independent review, and main acceptance remain outside this receipt.

The 13 frozen Phase 175 inputs were rehashed and matched their accepted SHA256 values. The source receipt records each digest. The frozen compatibility ledger was not edited. Documentation commits made after this source run do not replace the tested source SHA.

## Requirement outcomes

| Requirement | Source outcome | Evidence and remaining limit |
|---|---|---|
| VUP-03 | Passed | Interrupted/overlapping work preserves committed progress; stale issuance fails after maintenance and a fresh JTI can recover. No fleet recovery claim. |
| VOPS-01 | Passed | Replacement is idempotent; partial progress does not imply completion; a fresh complete inventory is required. |
| VOPS-02 | Passed | Selected-store authority, compare-and-swap preservation, independent PostgreSQL contention, rollback, and audit sequencing are covered. |
| VOPS-03 | Passed | Inventory paging, bytewise cursor rules, readiness, CLI outcomes, and no-material rows are covered. |
| VOPS-04 | Source recovery evidence passed; E-09 unresolved | Reader-first local recovery and restoration are exercised; the generic unclassified edge stays flagged. |
| VPROOF-01 | Source disclosure evidence passed; E-10 unresolved | Owned logger, query telemetry, audit, API, CLI, protocol, inspection, and rollback channels are covered; host handlers and server logging are outside scope. |

## Stable Phase 175 cases

All eight Phase 175 stable case IDs are mapped in the source receipt and have source-passed evidence:

- `MAINTENANCE-CAPABILITY-AUTHORITY`
- `MAINTENANCE-INVENTORY-PAGING`
- `MAINTENANCE-INVENTORY-READINESS`
- `MAINTENANCE-ATOMIC-CAS-AND-PRESERVATION`
- `MAINTENANCE-RACE-AND-ROLLBACK`
- `ROLLOUT-READER-FIRST-ROLLBACK-RETIREMENT`
- `DISCLOSURE-SENTINELS`
- `MAINTENANCE-INTERRUPTED-RESUME-IDEMPOTENCE-RECOVERY`

`LEGACY-AGE-BOUNDARIES` is referenced only as an approved preservation regression. The concurrency evidence uses independently checked-out PostgreSQL connections: the support harness captures contender and blocker backend PIDs and checks their relation with `pg_blocking_pids`. See `177-05-SUMMARY.md`, `177-06-SUMMARY.md`, and `test/support/client_verifier_maintenance_concurrency.ex`; no test count alone is used as contention proof.

## Probe audit retained

The eight explicit planning predicates remain as recorded in the source receipt: interrupted progress and fresh retry; exact replacement idempotence; randomized overlap and reconciliation; exact callback idempotence; both PostgreSQL lock orders and metadata preservation; exclusive adjacent bytewise paging; empty/singleton/no-material readiness; and stable unsigned UTF-8 traversal with duplicate/out-of-order rejection.

Two unclassified edges remain flagged and unresolved:

- E-09, VOPS-04/unclassified: no deterministic category was supplied. Do not auto-resolve or dismiss it.
- E-10, VPROOF-01/unclassified: no deterministic category was supplied. Do not auto-resolve or dismiss it.

Three descriptorless prohibitions remain `unverified` and flagged, not passed truths:

- Do not treat custody maintenance as authority to replace partner credentials or extend their authenticated lifetime.
- Do not turn a local complete custody check into permission to retire fleet or backup keys.
- Do not turn missing-key recovery into automatic partner-secret replacement without the existing authorized one-time handoff.

The structural validator establishes document shape only; it is not runtime evidence.

## Routine source-gate corrections

- Credo findings in the current maintenance changes were addressed in `fdb6ae35`.
- The issuance fixture now removes only its exact paired maintenance-race interaction rows, as well as its owned client, in `162e9a7f`.
- The generated installer test restores the exact Lockspire application-env entries it changes, and the quality scanner runs synchronously with the existing shared generated-fixture mutators, in `8bae1a30`.
- The previously accepted configuration export extension from `be6faa47` was already in place and was preserved.

Earlier failing CI logs remain in `/private/tmp` and are listed in the source receipt. The final canonical gate passed after the scoped fixes. A broader, noncanonical command that combined unit and integration verifier files in a single Mix invocation reported one configuration override failure; the standalone 16-test configuration suite and canonical separately staged `mix ci` both passed on the exact tested SHA. That failure was investigated during the final gate: the maintenance fixture leaked a fabricated startup context without signing-key exclusions. Commit `6aca1b86` restores its exact prior context. The original seed 82284 command now passes 107/0, the paired scope seed 55421 passes 23/0, and configuration alone passes 16/0. Fresh canonical CI on the corrected committed SHA passed 2413/0. The failed attempt remains retained; see `177-ISOLATION-FIX.md`.

## Phase 178 boundary

Phase 178 owns package-installed dependency-pair and composed-adapter journeys, independent final security/source/integration review, and CI/delivery/main acceptance and publication. This handoff does not mark Phase 177 complete; the orchestrator must run the independent phase verifier and any assigned security/source audits. Host fleet parity, quiescence, backups, PostgreSQL server logging, and unknown processes/resources remain outside local source acceptance.

## Independent review correction

The initial 32-file source review found WR-01: the low-level audit callback allowed field names without constraining values. The red regression accepted a secret actor sentinel. Source commit `9758550c` now rejects malformed required shapes/values before locking or mutation; fixed system actor, client-bound resource, bounded key IDs and a valid DateTime preserve native and legacy maintenance. Targeted maintenance passed 8/0 and the combined suite passed 43/0. Fresh canonical CI on `75988f427bc244d9c7a86183cbcda8bd75989c12` passed 2,414 tests, zero failures; earlier successes and all six failure attempts remain preserved. Current Nyquist, security and code-review refreshes remain pending until their independent returns.

## Audit-trigger evidence correction

Security re-audit reopened T-177-24 after strict validation made an incomplete fixture fail before the intended audit INSERT. Fixture commit `0a3c9ca5` supplies complete valid metadata and adds a unique test-owned PostgreSQL sequence incremented by the failing trigger. The new witness failed while metadata was incomplete, then required `[1, true]` after the trigger exception and transaction rollback. Existing no-sensitive-marker, unchanged-ciphertext and no-audit assertions remain intact. Disclosure passed 8/0, combined targeted tests 43/0, and fresh canonical CI on `5e8cd65e6a45deee205c79a0f23592be68c0ffb8` passed 2,414/0 in 265.625 seconds. Only Phase 177 evidence docs were dirty during CI; committed source/test/docs matched the tested SHA. All seven failed attempts and three earlier successful acceptances remain retained. Independent security closure and review refresh remain pending; the earlier audit overstatement is archived explicitly.

## Independent pre-verifier gates complete

Current Nyquist validation covers 18 tasks, 23 decisions and six requirements; all three concrete gaps are resolved. Security is independently re-audited SECURED 29/29 with zero open threats, preserving the initial missed finding and intermediate OPEN verdict. Source review is clean across 32 files and WR-01 is recorded fixed. The manifest finalizer predicate actually returned exit 0 / block false for Phase 177. UI review is skipped because there is no UI implementation surface. The required prior Phase 175/176 regression gate passed 29 referenced test files, 188 tests and zero failures in 3.147 seconds under the configured 1,800-second wrapper. See `177-FINAL-GATES.md` and the exact source receipt. The independent goal verifier remains the next owner; phase completion and Phase 178 are not claimed here.
