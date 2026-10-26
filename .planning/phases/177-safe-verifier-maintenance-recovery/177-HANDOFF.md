# Phase 177 Source Handoff

## Tested source identity

Source acceptance is bound to commit `8bae1a306e836c6d512c1d7e34ed39ef3c22e088` on `milestone/v1.48-client-auth-key-isolation`. The canonical `mix ci` command ran from `/Users/jon/projects/lockspire` with Elixir 1.19.5, OTP 28.5, `ERL_FLAGS='+S 4'`, `MIX_ENV=test`, and the owned database `lockspire_phase177_20261026_owned`. It exited 0 from `2026-10-26T03:28:33Z` through `03:33:34Z` (301 seconds). Its exact stages and output digest are in [177-SOURCE-ACCEPTANCE.json](177-SOURCE-ACCEPTANCE.json).

The gate reported 15 boundary tests, 2 properties and 2,138 `test.fast` tests with 0 failures (6 skipped, 567 excluded), then 260 integration tests with 0 failures (46 excluded). Credo checked 721 source files with no issues. Compile with warnings as errors, Sobelow, docs checks, and package build also exited successfully. These are source contributor checks; package installation/composition, publication, delivery, independent review, and main acceptance remain outside this receipt.

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

Earlier failing CI logs remain in `/private/tmp` and are listed in the source receipt. The final canonical gate passed after the scoped fixes. A broader, noncanonical command that combined unit and integration verifier files in a single Mix invocation reported one configuration override failure; the standalone 16-test configuration suite and canonical separately staged `mix ci` both passed on the exact tested SHA. The combined-attempt limitation is retained in the receipt rather than hidden or represented as canonical CI failure.

## Phase 178 boundary

Phase 178 owns package-installed dependency-pair and composed-adapter journeys, independent final security/source/integration review, and CI/delivery/main acceptance and publication. This handoff does not mark Phase 177 complete; the orchestrator must run the independent phase verifier and any assigned security/source audits. Host fleet parity, quiescence, backups, PostgreSQL server logging, and unknown processes/resources remain outside local source acceptance.
