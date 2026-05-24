---
status: complete
phase: 30-core-device-authorization-endpoint-and-storage
source:
  - 30-01-SUMMARY.md
  - 30-02-SUMMARY.md
  - 30-03-SUMMARY.md
mode: shift-left-ci
started: 2026-04-28T13:30:36Z
updated: 2026-04-28T13:39:09Z
---

## Current Test

[testing complete]

## Notes

Phase 30 no longer requires manual UAT. Its four user-observable checks are
covered by executable ExUnit proof and the maintained CI integration lane.

Automation entrypoints:
- `mix test.phase30` runs the focused Phase 30 proof slice (`mix.exs:69-72`)
- `mix test.integration` runs the full repo integration lane (`mix.exs:60`, `.github/workflows/ci.yml:161-165`)
- `mix test.fast` keeps the cold-start migrate-from-empty path in CI (`mix.exs:59`, `.github/workflows/ci.yml:93-99`)

Observed verification result on 2026-04-28:
- `MIX_ENV=test mix test.phase30` — `28 tests, 0 failures`
- `MIX_ENV=test mix test.integration` — `126 tests, 0 failures (360 excluded)`

## Tests

### 1. Cold Start Smoke Test
expected: Stop any running Lockspire services, create the test database from cold state, migrate cleanly, and reach a live request path without startup errors.
result: pass
auto_verified_by: |
  - `mix test.phase30` begins with `test.setup`, which runs `lockspire.test.setup`
    (`mix.exs:69-72` and `lib/mix/tasks/lockspire.test.setup.ex`).
  - CI provisions a fresh Postgres service container for every run and executes
    `mix test.fast`, which includes `test.setup` (`.github/workflows/ci.yml:25-46,93-99`).

### 2. Request Device Authorization Code
expected: A valid POST to `/device/code` returns `200 OK` with `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`, `expires_in`, and the published poll `interval`. Response headers include `Cache-Control: no-store` and `Pragma: no-cache`.
result: pass
auto_verified_by: |
  - End-to-end mounted-route proof in `test/integration/phase30_device_authorization_e2e_test.exs:49-94`.
  - Controller-level response contract proof in
    `test/lockspire/web/controllers/device_authorization_controller_test.exs:48-68`.

### 3. Reject Missing or Invalid Client
expected: A POST to `/device/code` without a valid client identity is rejected with `401`, `invalid_client`, and strict no-store cache headers.
result: pass
auto_verified_by: |
  - End-to-end failure-path proof in `test/integration/phase30_device_authorization_e2e_test.exs:96-109`.
  - Controller-level failure-path proof in
    `test/lockspire/web/controllers/device_authorization_controller_test.exs:70-81`.
  - Protocol-level invalid-client proof in
    `test/lockspire/protocol/device_authorization_test.exs:42-55`.

### 4. Persist Hashed Codes With 300s Expiry
expected: Successful issuance durably stores hashed device and user codes, keeps plaintext codes out of the persisted domain object, enforces a 300-second TTL, and uses the expected Base20 user-code format plus 5-second initial poll interval.
result: pass
auto_verified_by: |
  - End-to-end persistence assertions in
    `test/integration/phase30_device_authorization_e2e_test.exs:80-93`.
  - Domain issuance contract in `test/lockspire/domain/device_authorization_test.exs:8-30`.
  - Base20 and high-entropy generator proof in
    `test/lockspire/security/device_code_test.exs:6-27`.
  - Repository durability and uniqueness proof in
    `test/lockspire/storage/ecto/repository_device_authorization_test.exs:47-134`.

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
