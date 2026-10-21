# Phase 165 Regression Fix Summary

Initial Phase 165 validation and a later security audit exposed test isolation,
credential-precedence, and guidance-ambiguity gaps. Four corrective commits
resolved them. The protocol fix preserves current-row and hash checks, runs
preparation before the final decision clock, and checks credential eligibility
before returning any preparation error.

## Root causes and fixes

| Failure | Root cause | Resolution |
|---|---|---|
| Compatibility baseline | The literal compatibility manifest did not list the additive host recovery/time-control arities from Phase 165: `read/3`, `delete/3`, and `rotate_registration_access_token/2`. The historical `rotate_registration_access_token/1` remains part of the baseline. | Added the three approved additive extensions and pinned them in the compatibility test. Phase 165 plans define these host APIs; they do not add client-authenticated recovery routes. |
| Three `ServerPolicyRecordTest` PK violations | Tests inserted the fixed singleton ID `1` while a prior run could leave that row persisted. Manual checkout lacked per-test owner lifecycle and rollback. | Start a shared sandbox owner for each test, delete the singleton only inside that transaction, and stop the owner on exit. |
| Discovery metadata assertion | The test assumed the persisted server policy defaulted to `registration_policy: :disabled`; an existing row with `:open` correctly caused discovery to publish `/register`. | Seed the expected disabled policy in each rollback-only test transaction. Discovery implementation and metadata behavior were not changed. |
| LiveView copy assertion | The assertion still expected the retired text after Phase 165-06 adopted “app management token” wording. | Updated both copy assertions to the exact current rendered text. |
| Five private-key JWT failures in the first corrected fast run | The new recovery LiveView module set global `:mount_path` to `""` and did not restore Lockspire or endpoint application configuration after `setup_all`. Later tests paired issuer `/lockspire` with mount path `""`. | Capture and restore the original application environment after the module and use a rollback-only sandbox owner per test. |
| T-165-03: expired management token with invalid PUT metadata returned 400 | `RegistrationManagement.update/2` performed request metadata validation before checking the current credential. In `with_current_client/5`, a preparation error also short-circuited before `decision_now/1` and management expiry evaluation. | Removed redundant preflight validation; perform validation in current-row preparation, retain its result, obtain the final clock after preparation, check management eligibility, then return any preparation error. Invalid credentials now win with 401/`invalid_token`; valid credentials still receive metadata errors. Current-row locking, ID/hash comparison, preparation-before-clock ordering, and decision time are preserved. |
| T-165-17: recovery guidance implied it enables PUT for an expired app | “must be recovered before it can update it” could imply token recovery is sufficient to restore update permission, while the integration contract keeps expired-app PUT blocked. | State that recovery leaves app expiry unchanged and an expired app's PUT remains blocked with `registration_expired` (HTTP 403). A source-backed guidance assertion pins the distinction. |

The existing audit-attribution test expected an invalid-metadata result when it
used a snapshot whose token had already been rotated by host recovery. It now
asserts `:invalid_token`, matching the same credential-first rule.

The initial failed-run evidence is retained in `165-VALIDATION.md` and
`deferred-items.md`; resolved entries are explicitly superseded by the reruns
below. The security fixes had observed test-first failures: expired-token PUT
returned 400 instead of 401, and the guidance contract failed on the missing
expired-app warning. These are semantic observations only; no
classifier-approved TDD RED evidence is claimed.

## Verification

All Mix commands used the pinned runtime and the dedicated
`lockspire_phase165_validation` database. No dependencies were installed.

| Command | Result |
|---|---|
| `mix format --check-formatted test/support/architecture/public_compatibility_manifest.ex test/lockspire/compatibility_baseline_contract_test.exs test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs` | Passed |
| `mix test test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 6 --timeout 55000` | 48 tests, 0 failures |
| `mix test test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs --max-failures 1 --timeout 55000` | 9 tests, 0 failures |
| `mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000` | 21 tests, 0 failures |
| `mix test` over all 27 `*_test.exs` files changed from `ee7f8d2c..HEAD`, with `--max-failures 1 --timeout 55000` | 217 tests, 0 failures; integration files explicitly included |
| `mix test --include postgres_race test/lockspire/storage/management_token_client_wait_test.exs test/lockspire/storage/management_token_replacement_race_test.exs test/lockspire/storage/management_token_mutation_race_test.exs test/lockspire/storage/management_token_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs --max-failures 1 --timeout 55000` | 34 tests, 0 failures, 1.0s |
| `mix test.fast` | 2 properties, 2,412 tests, 0 failures, 484 excluded, 6 skipped, 136.3s |

For each command above, the actual invocation was prefixed with:

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation
```

The initial failed `mix test.fast` run was 2,411 tests, 6 failures, 483
excluded, and 6 skipped in 139.4s. A first corrective rerun then found five
issuer/mount-path failures. After environment isolation, the full run passed
with 2,411 tests. The final security-fix run includes the added integration
regression and passed with 2,412 tests.

For the expiry regression, the isolated access test first showed 2 tests, 1
failure: expected HTTP 401 but received HTTP 400. The new focused case reproduced
that result with 4 tests, 1 failure, 3 excluded. The guidance test first failed
because the clarified expired-app behavior was absent. After the fixes, the
access module passed 4/0, the guidance module 6/0, and all 27 changed test files
passed 217/0.

## Corrective commits

- `f91a975a test(165): repair validation regressions`
- `0d2b0051 test(165): restore host recovery test environment`
- `63041a41 fix(165): prioritize expired credentials over metadata errors`
- `2c88994b docs(165): clarify recovery does not restore PUT access`

The historical validation run and the earlier 2,411-test clean rerun remain
preserved as dated evidence; the final security-fix run is the current
superseding result at 2,412 tests, 0 failures, 484 excluded, and 6 skipped.
The exact combined gate is 21/0, the explicit PostgreSQL batch is 34/0, and
all 27 changed test files are 217/0. The corrections do not close the phase:
independent security, code-review, and goal-backward verification remain open.

Phase 165 remains in verification status. Independent security, code-review,
and goal-backward verification are still required. The user-owned
`.planning/state.json` remained byte-for-byte identical to
`/private/tmp/lockspire-phase165-original-state.json` and was not staged.
