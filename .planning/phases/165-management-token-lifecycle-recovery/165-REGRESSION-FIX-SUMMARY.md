# Phase 165 Regression Fix Summary

The first Phase 165 validation run found five distinct test-contract or isolation
causes behind six failures. Two corrective commits fixed the causes without
changing OAuth protocol behavior; the requested focused, compatibility, explicit
PostgreSQL, and full fast gates now pass.

## Root causes and fixes

| Failure | Root cause | Resolution |
|---|---|---|
| Compatibility baseline | The literal compatibility manifest did not list the additive host recovery/time-control arities from Phase 165: `read/3`, `delete/3`, and `rotate_registration_access_token/2`. The historical `rotate_registration_access_token/1` remains part of the baseline. | Added the three approved additive extensions and pinned them in the compatibility test. Phase 165 plans define these host APIs; they do not add client-authenticated recovery routes. |
| Three `ServerPolicyRecordTest` PK violations | Tests inserted the fixed singleton ID `1` while a prior run could leave that row persisted. Manual checkout lacked per-test owner lifecycle and rollback. | Start a shared sandbox owner for each test, delete the singleton only inside that transaction, and stop the owner on exit. |
| Discovery metadata assertion | The test assumed the persisted server policy defaulted to `registration_policy: :disabled`; an existing row with `:open` correctly caused discovery to publish `/register`. | Seed the expected disabled policy in each rollback-only test transaction. Discovery implementation and metadata behavior were not changed. |
| LiveView copy assertion | The assertion still expected the retired text after Phase 165-06 adopted “app management token” wording. | Updated both copy assertions to the exact current rendered text. |
| Five private-key JWT failures in the first corrected fast run | The new recovery LiveView module set global `:mount_path` to `""` and did not restore Lockspire or endpoint application configuration after `setup_all`. Later tests paired issuer `/lockspire` with mount path `""`. | Capture and restore the original application environment after the module and use a rollback-only sandbox owner per test. |

The initial failed-run evidence is retained in `165-VALIDATION.md` and
`deferred-items.md`; those entries are marked resolved and explicitly
superseded by the reruns below. No TDD RED evidence is claimed for this
post-plan corrective work.

## Verification

All Mix commands used the pinned runtime and the dedicated
`lockspire_phase165_validation` database. No dependencies were installed.

| Command | Result |
|---|---|
| `mix format --check-formatted test/support/architecture/public_compatibility_manifest.ex test/lockspire/compatibility_baseline_contract_test.exs test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs` | Passed |
| `mix test test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 6 --timeout 55000` | 48 tests, 0 failures |
| `mix test test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs --max-failures 1 --timeout 55000` | 9 tests, 0 failures |
| `mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000` | 21 tests, 0 failures |
| `mix test --include postgres_race test/lockspire/storage/management_token_client_wait_test.exs test/lockspire/storage/management_token_replacement_race_test.exs test/lockspire/storage/management_token_mutation_race_test.exs test/lockspire/storage/management_token_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs --max-failures 1 --timeout 55000` | 34 tests, 0 failures, 1.0s |
| `mix test.fast` | 2 properties, 2,411 tests, 0 failures, 483 excluded, 6 skipped, 134.0s |

For each command above, the actual invocation was prefixed with:

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation
```

The initial failed `mix test.fast` run was 2,411 tests, 6 failures, 483
excluded, and 6 skipped in 139.4s. A first corrective rerun then found five
issuer/mount-path failures; after fixing environment restoration, the final
full run above passed.

## Corrective commits

- `f91a975a test(165): repair validation regressions`
- `0d2b0051 test(165): restore host recovery test environment`

Phase 165 remains in verification status. Independent security, code-review,
and goal-backward verification are still required. The user-owned
`.planning/state.json` remained byte-for-byte identical to
`/private/tmp/lockspire-phase165-original-state.json` and was not staged.
