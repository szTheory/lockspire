---
phase: 163-app-lifetime-compatible-host-storage
plan: 13
subsystem: storage-migrations
tags: [client-lifetime, migrations, package-upgrade, postgresql]
dependency-graph:
  requires: [162-shipped-package-contract]
  provides: [additive-client-lifetime-migration, packaged-old-to-candidate-upgrade-proof]
  affects: [install-dx, client-storage, clean-room-acceptance]
tech-stack:
  added: []
  patterns: [isolated-package-builds, postgres-upgrade-journey, preserved-migration-checksums]
key-files:
  created:
    - scripts/acceptance/clean_room/client_lifetime_upgrade.py
    - test/clean_room/lifetime_upgrade_scenarios.exs
    - test/integration/app_lifetime_migration_test.exs
    - test/integration/app_lifetime_packaged_upgrade_test.exs
  modified:
    - scripts/acceptance/clean_room/build_provider.py
    - test/lockspire/install/migrations_test.exs
decisions:
  - Build and run the pinned old package and current candidate in isolated provider roots and child processes against disposable PostgreSQL databases.
  - Preserve existing migration bytes and checksums; install the lifetime change as an additive migration.
metrics:
  duration: 173.7s (fresh packaged integration command; focused migrations 0.7s)
  completed: 2026-10-20
status: complete
verification:
  fresh-packaged-upgrade: "1 test, 0 failures; 173.7s"
  migration-and-installer: "14 tests, 0 failures"
  python-compile: passed
  diff-check: passed
  strengthened-receipt-check: passed
receipt:
  path: /private/tmp/lockspire-163-13-all-receipt.json
  sha256: 5edde26983007bf875e6ea7e10fe273c5a0e5d764359ae1e5069fdc009fa9ebf
  pinned-old-package: "Hex lockspire 1.6.1, sha256 629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d"
  old-migrations-preserved: 37
  old-migration-checksum-set-sha256: 6e1bdd8da5a93b8698e3b00b37c2661370f4e687388a17fc78ebf878495bc694
  candidate: built from the current checkout; executed from an isolated package/provider root
  scenarios:
    - public
    - tenant_auth
  per-scenario-proof:
    - old package created and migrated the database successfully
    - old package created five client rows, including nil, creation-date, past, future, and stale-after-rotation secret expiry values
    - old package read all five expanded rows and performed a real secret rotation; the stale historical date remained observable
    - candidate observed all five rows at lifetime version zero without date-based rejection
    - old writer processes exited before candidate v1 authoritative write
    - candidate v1 state was retained and no old binary was used after v1 traffic
    - disposable database cleanup process exited zero
  receipt-process-evidence:
    public: "old-process PIDs 15673, 16751, 19332, 19443, 19512, 19550, 19602, 19666, 19766; candidate v1 PID 19942; cleanup PID 20189; all exit codes 0"
    tenant_auth: "old-process PIDs 20302, 20359, 20431, 20456, 20541, 20730, 20888, 21014, 21079; candidate v1 PID 21583; cleanup PID 21776; all exit codes 0"
parent-owned-tracking:
  commits: pending parent integration
---

# Phase 163 Plan 13: App-Lifetime Compatible Host Storage Summary

An additive client-lifetime migration now supports safe host-app rollout from the pinned 1.6.1 package, with an executable PostgreSQL upgrade proof for both `public` and `tenant_auth` prefixes.

## Delivered

- Added migration-focused integration coverage for live PostgreSQL catalog behavior and bounded DDL lock failure, plus installer coverage for exact migration bytes, checksums, and no-overwrite behavior.
- Added a package-upgrade runner that downloads and verifies the pinned Hex 1.6.1 archive, builds the candidate from the current checkout, runs old and candidate packages in isolated roots and processes, and records a machine-checkable receipt.
- Added the old-writer drain boundary, legacy nil/past/future/creation/stale secret-date observations, candidate v0-unlimited verification, retained v1 state verification, explicit old-binary rollback boundary, and disposable database cleanup checks.
- Added a focused ExUnit wrapper and shared scenario contract for both storage prefixes.

## Verification

Fresh packaged run:

```text
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_packaged_upgrade_test.exs --max-failures 1 --timeout 900000
1 test, 0 failures; 173.7s
```

Focused migration and installer run:

```text
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_migration_test.exs test/lockspire/install/migrations_test.exs --max-failures 1 --timeout 55000
14 tests, 0 failures
```

`python3 -m py_compile scripts/acceptance/clean_room/client_lifetime_upgrade.py scripts/acceptance/clean_room/build_provider.py`, `git diff --check`, and `python3 scripts/acceptance/clean_room/client_lifetime_upgrade.py --check-receipt /private/tmp/lockspire-163-13-all-receipt.json` all passed.

The strengthened receipt is SHA-256 `5edde26983007bf875e6ea7e10fe273c5a0e5d764359ae1e5069fdc009fa9ebf`. It records both prefixes, all 37 historical migration files and their preserved checksum-set digest `6e1bdd8da5a93b8698e3b00b37c2661370f4e687388a17fc78ebf878495bc694`, successful old and candidate child processes, five legacy rows per prefix, the writer-drain-before-v1 boundary, retained v1 state, and successful database cleanup.

## Deviations

- Added reusable work-root support and per-child Hex/Mix cache isolation to the existing clean-room provider builder after observed Hex ownership/cache failures blocked isolated package execution. These changes allow rerunning child stages without rebuilding verified package trees.
- The packaged journey initially encountered an isolated dependency-fetch failure; the prepared-tree journey completed successfully and the final fresh packaged ExUnit run then passed without retries.

## Self-Check

Passed: all six created or modified implementation/test files are present, the focused PostgreSQL journey passes, and the fresh package-level upgrade test passes.

Parent implementation commit: `eac0f82a65c30c6079410a88282eafe57c25ee05`; freshparent14tests0failures andreceiptvalidationpassed.
