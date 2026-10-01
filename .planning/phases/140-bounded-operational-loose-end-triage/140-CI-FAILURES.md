# Phase 140-08 Local CI Failure Census

## Run receipt

- **Command:** `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' HEX_HOME=/private/tmp/lockspire-hex-cache mix ci`
- **Started:** `2026-10-01T00:28:30Z`
- **Checkout:** `a6d6dcfd4abb589650f7dd46be44de7a877b3ff0`
- **Worktree status before run:** clean
- **Exit status:** `1`
- **Complete raw log:** `/private/tmp/lockspire-140-08-ci.XXXXXX.log` (mode `0600`; private temporary storage)

The run resolved existing locked dependencies, then stopped at `mix format --check-formatted`. ExUnit did not start. The two file identities below account for the complete formatter diagnostic; there is no current ExUnit failure count to infer from this run. The earlier 1,439-test/44-failure report remains historical and truncated, so none of its unnamed failures are represented as recurring current failures here.

## Complete observed failure set

| Identity | Exact current source | Root-cause group | Observed result | Focused verification | Disposition / trigger |
| --- | --- | --- | --- | --- | --- |
| `140-08-CI-FMT-001` | `test/lockspire/release/repository_hygiene_contract_test.exs` (formatter diff begins at line 124) | Formatting gate | `mix format --check-formatted` reports required spacing and line wrapping changes. No ExUnit test identity exists because the gate stopped before tests. | `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs` | Fix in a separate exact-scope gap plan, then repeat the formatter check. |
| `140-08-CI-FMT-002` | `test/support/lockspire/release_proof/package_assertions.ex` (formatter diff begins at line 4426) | Formatting gate | `mix format --check-formatted` reports required indentation and line wrapping changes. No ExUnit test identity exists because the gate stopped before tests. | `mix format --check-formatted test/support/lockspire/release_proof/package_assertions.ex` | Fix in a separate exact-scope gap plan, then repeat the formatter check. |

## Reconciliation

- **Complete diagnostic count:** 2 unformatted file identities in 1 blocking `mix format --check-formatted` gate.
- **ExUnit:** not reached; no test count or failure count was emitted.
- **Other CI gates:** not reached; the first Mix alias failure aborted the command.
- **Credentials:** the private log was not copied into this durable census; no credential or token material was observed in the returned diagnostics.
- **Repair boundary:** both formatter paths are outside Plan 140-08 `files_modified`. Plan 140-08 does not modify them; a separate scoped plan must close before its full CI task resumes.
