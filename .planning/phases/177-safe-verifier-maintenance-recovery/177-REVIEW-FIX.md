# Phase 177 Code Review Fix Report

## WR-01: Constrain maintenance audit attributes

**Status:** Fixed
**Fix commit:** 9758550c (fix(177): WR-01 constrain maintenance audit attrs)
**Files changed:**

- lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex
- test/integration/client_secret_verifier_maintenance_test.exs

The repository callback previously checked only the outer audit keys and the set of metadata key names. It did not bind actor/resource values or check metadata value types. A red regression test confirmed a caller could supply a secret sentinel as the actor type and receive {:ok, :changed}.

The callback now validates the complete exact attribute shape before locking or updating a client: fixed action and outcome, exact system actor, exact client resource bound to the requested client_id, exactly the three maintenance metadata fields, bounded ASCII key IDs, and a round-trippable DateTime. The actual legacy promotion path emits legacy as its old key ID, so both key ID fields use the existing 1–32 character key-ID grammar. Tests cover missing, extra, wrong-typed, malformed, and sentinel values and assert rejected calls leave ciphertext unchanged and write no audit row. Native audit/idempotence coverage remains, and legacy promotion now verifies its audit metadata.

### Verification

Runtime environment: Elixir 1.19.5-otp-28, Erlang 28.5, ERL_FLAGS=+S 4, MIX_ENV=test, LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned.

| Command | Exit | Result | Log |
|---|---:|---|---|
| mix test --include integration test/integration/client_secret_verifier_maintenance_test.exs --seed 82540 before source fix | 2 | 8 tests, 1 failure; sentinel audit actor was accepted and returned :changed | /private/tmp/lockspire-177-review-wr01-red.log |
| Same maintenance integration test after fix | 0 | 8 tests, 0 failures | /private/tmp/lockspire-177-review-wr01-maintenance-final.log |
| Focused maintenance, concurrency, disclosure, issuance, recovery, rotation, and legacy-age suites, seed 82540 | 0 | 43 tests, 0 failures | /private/tmp/lockspire-177-review-wr01-maintenance-family-final.log |
| mix format --check-formatted on both changed source files | 0 | Passed | — |
| mix credo --strict on both changed source files | 0 | 36 mods/funs, no issues | — |

All 13 frozen input digests from 177-SOURCE-ACCEPTANCE.json were rechecked and remain unchanged. Full CI was left for the parent workflow.

## T-177-24 disclosure fixture follow-up

**Status:** Fixed
**Fixture commit:** `0a3c9ca5` (`test(177): prove failed audit insert trigger executes`).

The failed-audit disclosure case had been rejected by the new audit-attribute validator before its INSERT trigger ran. Its previous safe error, unchanged ciphertext, and absent audit row assertions therefore did not exercise PostgreSQL driver diagnostics.

The fixture now supplies the complete valid maintenance audit shape with the scenario key labels `disclosure-old` and `disclosure-new`. Its test-owned trigger increments a uniquely named PostgreSQL sequence before raising the diagnostic marker. Sequence state is read after the operation; `[1, true]` proves the trigger executed even though the transaction rolled back. The test continues to assert the marker is absent from captured Logger output and the returned result, the stored ciphertext is unchanged, and no audit row exists. Teardown drops only the exact trigger, function, and sequence created by this test.

The new positive witness was first run while the fixture still had incomplete metadata: it failed with the sequence uncalled, demonstrating that the prior generic error assertions did not establish trigger execution.

| Command | Exit | Result | Log |
|---|---:|---|---|
| Disclosure suite with witness and incomplete audit metadata, seed 81501 | 2 | 8 tests, 1 failure: audit trigger sequence witness remained uncalled | `/private/tmp/lockspire-177-review-t17724-witness-red.log` |
| Disclosure suite with complete valid audit metadata, seed 81501 | 0 | 8 tests, 0 failures; sequence witness required `[1, true]` | `/private/tmp/lockspire-177-review-t17724-witness-green.log` |
| Maintenance, concurrency, disclosure, issuance, recovery, rotation, and legacy-age suites, seed 81501 | 0 | 43 tests, 0 failures | `/private/tmp/lockspire-177-review-t17724-maintenance-family-final.log` |
| Format check and strict Credo on the changed disclosure test | 0 | Passed; 29 mods/funs, no issues | — |

No production file, schema, frozen input, or unrelated review evidence was changed. Full CI remains with the parent workflow.
