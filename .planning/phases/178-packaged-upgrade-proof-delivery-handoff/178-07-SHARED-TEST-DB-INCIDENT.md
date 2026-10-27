# Plan 178-07 Shared Test Database Attempt

Status: failed source-verification attempt preserved for custody. This record does not assert that the shared database was unchanged.

## Command and result

Command:

```sh
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs
```

No run-specific `LOCKSPIRE_TEST_DB_NAME`, `PGDATABASE`, or `DATABASE_URL` override was passed. The command output did not print `current_database()`. In a follow-up read-only environment check those variables were unset, and `config/test.exs` therefore selects its default `lockspire_test` database. Preserve that as the best-supported database identity, not as a captured connection query.

The run completed at approximately `2026-10-26 21:00:11 EDT` (UTC `2026-10-27 01:00:11`). The tool did not persist the child spawn timestamp; the visible SQL output spans `21:00:11.551`–`21:00:11.632` EDT. Result: 9 tests, 1 failure. The failing test was `successful maintenance keeps real plaintext, key bytes and ciphertext out of owned channels`. Maintenance returned an error report with one committed change and two `missing_expected_material` failures for existing `lifetime-client-wait-*` rows. No raw credential value was emitted in the captured failure output.

## Source-based transaction and cleanup assessment

- `client_secret_verifier_maintenance_disclosure_test.exs` starts `TestRepo` in manual Sandbox mode and checks out the ordinary per-test connection in `setup/1`. Ordinary test operations and the test-local DDL run through that checked-out connection.
- The failing success test explicitly creates its generated `disclosure-*` fixture with `Sandbox.unboxed_run/2`, runs `ClientVerifierMaintenance.run(mode: :apply)` in another `Sandbox.unboxed_run/2`, and reads the audit in a third. Those operations are outside the per-test rollback transaction. The report's `committed_changed: 1` confirms that the failed test attempt performed a committed change before returning its aggregate failure.
- That test registers `on_exit(fn -> cleanup_client(client_id) end)`. `cleanup_client/1` uses `Sandbox.unboxed_run/2` to delete audit rows and the exact generated client row. The command output included cleanup DELETE statements for generated `disclosure-*` identifiers. No independent post-run row-count check was made, so the cleanup outcome is supported by the source path and observed statements, not a before/after database snapshot.
- The two preexisting lifetime rows were not queried or modified manually. The run's report classifies both as missing-material failures; no pre-run snapshot exists, so their full before/after state is unknown. Do not delete, repair, or certify those rows from this incident.
- `client_secret_verifier_inspection_test.exs` is `async: true` and exercises in-memory nested inspection only. It does not own database resources.
- The integration file has transaction-local trigger/function setup in tests using the normal checked-out connection. The audit-insert test has an explicit `after` block that drops its run-specific trigger, function, and sequence. No database-wide DDL or database drop command was part of this test invocation.

## Disposition

This shared-target command is not a source pass. The preexisting rows and any unobserved shared state remain outside this run's cleanup authority. At the time this section was written, the planned next step was to rerun on a uniquely named database; the later wrong-environment incident below supersedes that plan and records why no further database work proceeded.

## Second Source Database Target Incident

Status: wrong-environment create/migrate attempt preserved. No cleanup or repair was performed against the inferred development database.

### Commands and results

The selected test database name was `lockspire_test_17807_20261027_012450`. A read-only `pg_database` check immediately before the following commands returned count `0` for that exact name.

Create command (exit 0; captured output classified as already created, not newly created):

```sh
umask 077; export LOCKSPIRE_TEST_DB_NAME=lockspire_test_17807_20261027_012450; export ASDF_ELIXIR_VERSION=1.19.5-otp-28; export ASDF_ERLANG_VERSION=28.5; export ERL_FLAGS='+S 4'; mix ecto.create > /private/tmp/lockspire-17807-owned-create.log 2>&1
```

Migration command (exit 0; captured output records successful migrations `20260528150000_add_access_token_format` and `20261021000000_add_client_lifetime_contract`):

```sh
umask 077; export LOCKSPIRE_TEST_DB_NAME=lockspire_test_17807_20261027_012450; export ASDF_ELIXIR_VERSION=1.19.5-otp-28; export ASDF_ERLANG_VERSION=28.5; export ERL_FLAGS='+S 4'; mix ecto.migrate > /private/tmp/lockspire-17807-owned-migrate.log 2>&1
```

Both commands omitted `MIX_ENV=test`. Project source `config/dev.exs` selects `LOCKSPIRE_DB_NAME || "lockspire_dev"`; it does not read `LOCKSPIRE_TEST_DB_NAME`. The invocation did not set `LOCKSPIRE_DB_NAME`, `DATABASE_URL`, or `PGDATABASE`; those are also unset in the current inherited shell. The best-supported create/migrate target is therefore `lockspire_dev`, while the test-name variable did not select the intended target. Create output indicates storage was already present; two migrations nevertheless ran. There is no pre-run snapshot of that database's schema/version state, so the prior state and exact durable delta are unknown. Do not query, drop, roll back, repair, or claim it unchanged.

The source test command did set the dedicated test name and `MIX_ENV=test`:

```sh
umask 077; export LOCKSPIRE_TEST_DB_NAME=lockspire_test_17807_20261027_012450; export ASDF_ELIXIR_VERSION=1.19.5-otp-28; export ASDF_ERLANG_VERSION=28.5; export ERL_FLAGS='+S 4'; MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs > /private/tmp/lockspire-17807-owned-source-tests.log 2>&1
```

It exited 2 with 9 tests and 8 failures. Safe in-memory parsing found Postgrex missing-relation diagnostics; raw test output remains private and was not inspected or forwarded. `test/test_helper.exs` only starts ExUnit; no test setup alias ran. It is unknown whether the exact test database was created by another source path during this invocation or whether the observed errors came from a different connection target. Its existence and contents remain unverified and must not be changed.

The command-log completion mtimes were `2026-10-27T01:23:02.397Z` (create), `01:23:04.648Z` (migrate), and `01:23:41.458Z` (test); command spawn timestamps were not recorded, so starts are not asserted. Shell-reported durations were approximately 0.44 s, 0.44 s, and 32.8 s. Logs are retained under `/private/tmp/lockspire-17807-owned-{create,migrate,source-tests}.log` with restricted mode from `umask 077`.

### Disposition

This is not a source pass. It is a distinct database-targeting incident and remains visible beside the earlier shared-test-database incident. No database cleanup is performed. The inferred `lockspire_dev` target received two migrations and its exact durable delta is unknown. The dedicated test-name target's state is also unknown: it was absent at the pre-command catalog check, then selected by the failed test command, and no post-run catalog or row snapshot exists. Future database actions require a fresh source audit with a guard that resolves and verifies the exact target before every create, migrate, test, or drop command.
