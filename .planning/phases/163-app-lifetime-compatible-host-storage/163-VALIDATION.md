---
phase: "163"
slug: "app-lifetime-compatible-host-storage"
status: validated
nyquist_compliant: true
wave_0_complete: false
created: "2026-10-20"
---

# Phase 163 — Validation Strategy

ExUnit with real PostgreSQL14+ and Ecto Sandbox; config/test.exs. Select installed compatible Elixir/OTP through task-local ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15, without changing host tool configuration.

Quick sampling: focused ExUnit files specified by each plan after every task. Full sampling: MIX_ENV=test mix test.fast after each wave. Real independent PostgreSQL transactions and observed pg_blocking_pids are mandatory for issuance waits. Tests are paired with implementation slices, not deferred to166.

| Requirement | Proof | Command owner |
|---|---|---|
| DCR-05 | v1 registration, zero/unlimited/finite, exact equality, disabled/public state | Registration and eligibility slice |
| DCR-06 | Every selected consumer, final guarded token issuance, signed/opaque caps, no failed-redemption side effects | Consumer and issuance slices |
| DCR-13 | v0 historical dates and atomic promotion; pinned old/candidate package across additive schema | Storage and upgrade slices |
| DCR-14 | Fresh/custom-prefix migrations, custom-store conformance, failclosed dropped state/transaction mismatch | Storage and upgrade slices |

## Wave 0 requirements

New focused tests must be created by their implementing slices: lifetime domain/adapter/registration, consumer matrix, real PostgreSQL concurrency and isolated package upgrade. Existing ExUnit/PostgreSQL infrastructure suffices; no dependencies are added. Planner must replace generic test paths from research with exact executable paths and pair every automated command with observable fails_when.

## Sign-off

Plan 163-14 execution evidence (2026-10-20):

| Check | Command / evidence | Result |
|---|---|---|
| Guidance and installer contract | `MIX_ENV=test mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/install/migrations_test.exs` | 15 tests, 0 failures. |
| Focused lifecycle, guidance, migration, and compatibility contracts | `MIX_ENV=test mix test test/lockspire/compatibility_baseline_contract_test.exs test/lockspire/client_lifecycle_test.exs test/lockspire/client_lifetime_guidance_test.exs test/lockspire/install/migrations_test.exs` | 23 tests, 0 failures. Existing `AuthorizationRequest.validate/2` and `validate_pushed/3` option-bearing entrypoints are recorded as explicit additive extensions; original literal v1.x arities remain asserted. |
| Format and whitespace | `mix format --check-formatted test/lockspire/client_lifetime_guidance_test.exs test/lockspire/compatibility_baseline_contract_test.exs test/support/architecture/public_compatibility_manifest.ex`; `git diff --check` | Passed. |
| Full fast suite on a fresh isolated PostgreSQL test database | `LOCKSPIRE_TEST_DB_NAME=lockspire_phase163_plan14_full MIX_ENV=test mix test.fast` with Elixir 1.18.4 / OTP 27 task-local toolchain; complete output: `/private/tmp/phase163-plan14-test-fast-fresh.log` | 2 properties, 2290 tests, 0 failures, 398 excluded, 6 skipped; 222.2s. This clean-database run passed after two direct lifecycle fixtures were updated to declare legacy `lifetime_version: 0` and the additive API extension was made explicit in the compatibility contract. |
| Previously failing admin LiveView files on fresh isolated test DB | Six affected admin files, log `/private/tmp/phase163-plan14-admin-fresh.log` | 98 tests, 0 failures. Count/copy expectations from the earlier default-database run did not reproduce against a fresh database. |
| Independent PostgreSQL waits and rollback | Plan 163-12 focused result in `163-12-SUMMARY.md`; client/grant helpers inspected for teardown | 13 tests, 0 failures. The unboxed client/grant race tests register `on_exit` cleanup; cleanup deletes audit, authorization, token, interaction and client rows (grant helper also deletes CIBA rows). |
| Fresh packaged migration/upgrade journey | Plan 163-13 receipt `/private/tmp/lockspire-163-13-all-receipt.json`; `python3 scripts/acceptance/clean_room/client_lifetime_upgrade.py --check-receipt /private/tmp/lockspire-163-13-all-receipt.json` | Receipt verified. Both `public` and `tenant_auth`; pinned 1.6.1 old package and candidate processes; 37 historical migrations preserved; five representative legacy date rows per prefix; old writers exited before first v1 write; v1 retained; cleanup exited successfully. Receipt SHA-256: `5edde26983007bf875e6ea7e10fe273c5a0e5d764359ae1e5069fdc009fa9ebf`. |

The initial fast run against the pre-existing default test database reported 16 failures: two direct client fixtures lacked the now-required explicit legacy version, one compatibility assertion did not enumerate the intentional option-bearing public arities, and admin copy/count expectations were sensitive to database contents. The fixture and compatibility contract were corrected; the affected admin files passed alone on a clean database, and the entire fast suite then passed on a separate fresh database. The initial failure log is `/private/tmp/phase163-plan14-test-fast.log`; it is retained as execution evidence, not as the final result.

No UI verification is applicable. The full suite does not run 398 tagged tests, including independent race suites; their focused PostgreSQL evidence is recorded by the owning plans rather than treated as covered by the fast-suite count. Plan 163-14's gate and packaged receipt pass, but phase sign-off remains pending independent review/verifier. DCR-07–12 and DCR-15–19, later shared-secret and management-token work, and the umbrella lifetime todo remain open for their owning phases/Phase 166.

## Final adversarial validation (2026-10-20)

| Check | Command / evidence | Result |
|---|---|---|
| Fresh isolated test database setup | Task-local Elixir 1.18.4 / OTP 27, `MIX_ENV=test LOCKSPIRE_TEST_DB_NAME=lockspire_phase163_final_validation mix test.setup`; task-local `MIX_HOME` and `HEX_HOME` under `/private/tmp/lockspire-163-13-debug-8/old-public/` | Database created and all migrations completed, including `AddClientLifetimeContract`. |
| Required post-review full fast suite | `MIX_ENV=test LOCKSPIRE_TEST_DB_NAME=lockspire_phase163_final_validation mix test.fast`; full durable output: `/private/tmp/phase163-final-test-fast.log` | 2 properties, 2291 tests, 0 failures, 398 excluded, 6 skipped; 201.9s. |
| Review fix regressions | `163-REVIEW-FIX-SUMMARY.md`: `client_app_authentication_test.exs` and `client_lifetime_conformance_test.exs` — 18 tests, 0 failures; client/grant wait and rollback tests — 13 tests, 0 failures | CR-01 normalized fractional decision instants at UTC-second precision; WR-01 dropped-field adapters reach and fail the intended persistence checks. |
| PostgreSQL waits and rollback | `test/lockspire/storage/client_lifetime_client_wait_test.exs`, `client_lifetime_grant_wait_test.exs`, `client_lifetime_rollback_test.exs`; exact result in 163-12 and review-fix summaries | 13 tests, 0 failures, real independent PostgreSQL sessions. |
| Packaged migration proof | `/private/tmp/lockspire-163-13-all-receipt.json`, checked with `python3 scripts/acceptance/clean_room/client_lifetime_upgrade.py --check-receipt /private/tmp/lockspire-163-13-all-receipt.json` | Passed for `public` and `tenant_auth`, with old and candidate packages, historical migration/checksum preservation, drained old writers, first v1 write, retained v1 state, and successful cleanup. Receipt SHA-256 remains `5edde26983007bf875e6ea7e10fe273c5a0e5d764359ae1e5069fdc009fa9ebf`. |

## Requirement and decision coverage disposition

The 29 task-level automated verify blocks across plans 163-01 through 163-14 map to the focused executable checks recorded in their matching summaries; no task is left without a command or actual result. The DCR-05, DCR-06, DCR-13 and DCR-14 rows above are backed by executed behavior. `163-COVERAGE.md` maps C-APP-01–18 and C-TOK-01–03 to focused tests or an explicit unaffected-boundary disposition; `163-SOURCE-AUDIT.md` maps D-01–D-24 and all four requirement IDs to proof. The 398 full-suite exclusions and 6 skips are not counted as passing full-suite tests; PostgreSQL wait/rollback and package proof have separate passing evidence. Phase completion and cross-phase requirements remain pending the independent goal verifier; this status records Nyquist test coverage only.
