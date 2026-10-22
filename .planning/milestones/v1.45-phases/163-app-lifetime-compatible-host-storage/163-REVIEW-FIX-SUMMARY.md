# Phase 163 Review Fix Summary

Fixed the two requested findings from `163-REVIEW.md`.

## CR-01: Normalize the decision instant

`Client.app_eligibility/3` now converts the decision instant to a UTC whole second before comparing it with a finite deadline. This shared domain decision covers authentication and direct callers. The stored deadline still must be UTC and whole-second; malformed or unknown lifetime state still fails closed, and equality remains expired.

The new public-client authentication regression first failed against the original implementation: an injected `11:59:59.999999Z` decision instant before a `12:00:00Z` deadline returned HTTP 500 (`:client_lifetime_state_invalid`). It now accepts that instant, rejects `12:00:00.999999Z` at equality, and accepts a finite-future client through the default clock path.

## WR-01: Make dropped-field fixtures reach storage comparisons

`DroppedVersion` and `DroppedDeadline` now declare valid adapter-owned transaction authorities. Their registration and fetch callbacks record that conformance reached persistence. Assertions verify those callbacks ran and inspect the returned state: the version fixture omits `lifetime_version`, while the deadline fixture drops both the app and registration-access-token deadlines. The existing independent missing/unknown authority and atomicity cases remain.

As a red check, restoring the fixtures' original scalar `:custom_test` authority made the conformance regression fail because the registration callback was never reached. Restoring the valid declarations makes the regression pass.

## Files changed

- `lib/lockspire/domain/client.ex`
- `test/lockspire/protocol/client_app_authentication_test.exs`
- `test/lockspire/storage/client_lifetime_conformance_test.exs`

## Verification

All commands used the requested task-local Mix and Hex homes, Elixir 1.18.4 / OTP 27, and `MIX_ENV=test`.

- `mix test test/lockspire/protocol/client_app_authentication_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs` — 18 tests, 0 failures.
- `mix test test/lockspire/storage/client_lifetime_client_wait_test.exs test/lockspire/storage/client_lifetime_grant_wait_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs --max-failures 1 --timeout 55000` — 13 real PostgreSQL tests, 0 failures.
- `mix format --check-formatted` on the three changed Elixir files — passed.
- `git diff --check` — passed.

No commits or planning-state changes were made by this fix task. Broader `mix test.fast` remains with the parent workflow.
