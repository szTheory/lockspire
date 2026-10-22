# Phase 165 Code Review Fix

## Fixed Issues

### CR-01 [BLOCKER]: Expired-app PUT validation can bypass the required expiry response

**Root cause:** `with_prepared_current/5` returned a preparation error before
checking `Client.app_eligibility/3`. With a valid management token for an
expired app, malformed PUT metadata could therefore disclose HTTP 400
`invalid_client_metadata` instead of the required HTTP 403
`registration_expired`.

**Fix:** Commit `e1883472` applies app eligibility after the existing
management-token check for both successful and failed preparation. This keeps
expired credentials at HTTP 401 / `invalid_token`, expired-app PUT at HTTP 403
/ `registration_expired`, and allows metadata errors only when the app is
eligible. Expired-app GET/DELETE exceptions remain. Current-row locking,
row-ID/token-hash checks, no-write behavior, and preparation-before-final-clock
sampling are preserved.

**Test-first evidence:** Before the implementation change, the focused HTTP
integration test observed an expired-app PUT with valid management credential
return HTTP 400 rather than 403: 3 tests, 1 failure, 4 excluded. This is an
observed semantic RED; no classifier-approved TDD RED is claimed.

**Regression matrix:** The integration test asserts that an eligible app with
a valid token and invalid body returns 400; an expired app with a valid token
and missing/mismatched `client_id` or invalid extension returns 403;
invalid and expired tokens on the expired app return 401. It also verifies no
client-row or audit writes.

## Verification

All Mix tests used the pinned Elixir/OTP, `MIX_HOME`, `HEX_HOME`, and dedicated
`lockspire_phase165_validation` database.

Common environment prefix:

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation
```

The commands and outcomes were:

| Command | Result |
|---|---|
| `mix format --check-formatted lib/lockspire/protocol/registration_management.ex test/integration/management_token_lifetime_access_test.exs` | Passed |
| `mix test test/integration/management_token_lifetime_access_test.exs --max-failures 1 --timeout 55000` | 5 tests, 0 failures |
| `test_files=( $(git diff --name-only ee7f8d2c..HEAD -- 'test/**/*_test.exs') ); mix test "${test_files[@]}" --max-failures 1 --timeout 55000` | 27 files; 218 tests, 0 failures |
| `mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000` | 21 tests, 0 failures |
| `mix test --include postgres_race test/lockspire/storage/management_token_client_wait_test.exs test/lockspire/storage/management_token_replacement_race_test.exs test/lockspire/storage/management_token_mutation_race_test.exs test/lockspire/storage/management_token_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs --max-failures 1 --timeout 55000` | 34 tests, 0 failures |
| `mix test.fast` | 2 properties, 2,413 tests, 0 failures, 485 excluded, 6 skipped, 129.6 seconds |

The original failed full-suite evidence remains historical in
`165-VALIDATION.md` and `deferred-items.md`. These reruns supersede the latest
clean full-suite count; exclusions and skips are still reported and are not
counted as independent PostgreSQL race evidence. Phase 165 remains open for
parent re-review, security review, and goal-backward verification.
