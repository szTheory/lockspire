# Phase 177 Verifier Test Isolation Fix

## Finding

`WR-177-ISOLATION`: the listed-hidden-key assertion in `ConfigClientSecretVerifierTest` failed only after the verifier maintenance integration suite had run. This was a test fixture leak, not a verifier configuration defect.

`test/integration/client_secret_verifier_maintenance_test.exs` installed test-created contexts directly into the process-global `:persistent_term` startup-context cache. Its helper did not restore the prior value. The subsequent configuration test read a stale `maintenance-migrated-new` context whose `forbidden_key_bytes` did not include the cached signing-key encryption key. An unlisted hidden key was rejected because the context shape was malformed; the same hidden key passed once its ID was included because the stale forbidden-key snapshot was missing it.

The failing run's temporary trace confirmed the current keyset contained the hidden key and the new base context recognized it, while the leaked startup snapshot did not. Production behavior correctly uses the immutable startup snapshot; the test helper was violating that lifetime by leaving a fabricated snapshot behind.

## Fix

Updated the maintenance test helper to capture the prior persistent context and register an `on_exit` restoration for each replacement. This handles tests that install more than one context and restores the original process state after the test. No product code, policy, public API, or assertion changed.

## Verification

Runtime environment: `ASDF_ELIXIR_VERSION=1.19.5-otp-28`, `ASDF_ERLANG_VERSION=28.5`, `ERL_FLAGS='+S 4'`, `MIX_ENV=test`, `LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned`.

| Run | Exit | Result | Log |
|---|---:|---|---|
| Before fix, requested verifier-family command, seed 82284 | 2 | 107 tests, 1 failure at the listed-hidden-key assertion | `/private/tmp/lockspire-177-09-verifier-family-8bae1a30.log` |
| After fix, same verifier-family command, seed 82284 | 0 | 107 tests, 0 failures | `/private/tmp/lockspire-177-09-verifier-family-isolation-fix-seed-82284.log` |
| After fix, maintenance/config paired scope, seed 55421 | 0 | 23 tests, 0 failures | `/private/tmp/lockspire-177-09-verifier-isolation-pair-seed-55421.log` |
| After fix, config suite alone | 0 | 16 tests, 0 failures | `/private/tmp/lockspire-177-09-verifier-config-alone-isolation-fix.log` |

All 13 frozen input digests in `177-SOURCE-ACCEPTANCE.json` were verified unchanged. The canonical full CI gate was not run as part of this scoped fix.
