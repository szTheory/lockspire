---
phase: 163-app-lifetime-compatible-host-storage
plan: "03"
subsystem: auth
tags: [elixir, oauth, client-authentication, client-lifetime, token-exchange]
requires:
  - phase: 163-app-lifetime-compatible-host-storage
    provides: Typed client-lifetime adapter support from plan 163-02
provides:
  - App enabled-state and deadline enforcement after every supported client-auth method
  - Redacted method-specific verified-client identity comparison helper for guarded writers
  - Explicit token-auth clock and typed lifetime dependency handoff
affects: [163-04, 163-06, 163-12, 164]
actuals:
  tokens: 6263
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns:
    - Client authentication maps one domain eligibility result to OAuth 401 or server 500
    - Internal verified identities fingerprint only method-specific stored auth configuration
key-files:
  created:
    - test/lockspire/protocol/client_app_authentication_test.exs
  modified:
    - lib/lockspire/protocol/client_auth.ex
    - lib/lockspire/protocol/token_exchange/internal/client_authentication.ex
    - test/lockspire/protocol/client_auth_test.exs
    - test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs
key-decisions:
  - "Authentication success remains {:ok, Client}; internal writers can derive and compare a redacted identity from that verified snapshot."
  - "Shared-secret expiry stays outside this plan; v0 historic dates and v1 secret dates do not gate authentication here."
requirements-completed: []
duration: 6min
completed: 2026-10-20
status: complete
---

# Phase 163 Plan 03: Authentication App Eligibility Summary

**Client authentication now rejects disabled or expired applications consistently across public, secret, key, and mTLS methods while preserving endpoint error classes and injected time.**

## Accomplishments

- Applied `Client.app_eligibility/3` after successful credential verification for `none`, Basic, post, secret-JWT, private-key-JWT, TLS client authentication, and self-signed TLS client authentication.
- Mapped disabled and expired apps to 401 `invalid_client`; malformed lifetime state and adapter/configuration failures remain 500 `server_error` results.
- Passed the typed lifetime support, injected clock, and mTLS certificate from token-exchange dependencies into `ClientAuth`.
- Added a redacted method-specific verified identity and comparison helper. Secret methods bind stored hashes and verifier configuration; key and mTLS methods bind their stored authentication configuration. A final writer can compare this identity with its reloaded client row; persistence threading and lock-time validation remain in plan 06.
- Adapted legitimate pre-lifetime auth test fixtures to explicit v0, keeping absent or unknown lifetime state fail-closed.

## Task Commits

Parent executor owns the shared-workspace commit. Implementation commit hash and measured plan commit count are pending parent tracking.

## Files Created/Modified

- `lib/lockspire/protocol/client_auth.ex` — shared app eligibility enforcement and server-error mapping.
- `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex` — explicit clock/lifetime handoff and internal verified-identity helper.
- `test/lockspire/protocol/client_app_authentication_test.exs` — method matrix, lifetime boundaries, server errors, secret-date scope, identity comparison, and clock adaptation.
- `test/lockspire/protocol/client_auth_test.exs`, `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` — explicit legacy v0 in existing historical auth fixtures.

## Decisions Made

- `ClientAuth.authenticate/3` retains its public `{:ok, Client}` result. The authenticated client snapshot carries the method-specific configuration from which internal guarded writers can construct and compare `VerifiedIdentity`.
- Phase 164 remains responsible for enforcing finite shared-secret expiry. This plan checks application enabled state and app lifetime only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Compatibility] Marked existing direct-auth fixtures as legacy v0**
- **Found during:** Task 1
- **Issue:** Existing auth tests constructed persisted clients without the now-required lifetime version.
- **Fix:** Set `lifetime_version: 0` on the affected private-key, secret, remote-key, and mTLS test clients without adding a production fallback.
- **Files modified:** `test/lockspire/protocol/client_auth_test.exs`, `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`.
- **Verification:** Focused authentication tests passed.
- **Commit:** Pending parent executor.

**Total deviations:** 1 compatibility adjustment. No dependency or Phase 164 behavior was added.

## TDD Gate Compliance

- **Task 1 RED:** The new injected-clock equality test executed and failed on its planned assertion: at `now == client_expires_at`, the baseline returned `{:ok, client}` instead of `:client_app_expired`. An earlier attempt failed at test compilation due to a test helper syntax error; that run was discarded and did not count as RED evidence.
- **Task 1 GREEN:** The eligibility mapping was added after credential verification; the new method matrix and existing client-auth suites passed.
- **Task 2:** Added identity rotation/configuration comparison tests and callback-preservation checks for normal and CIBA dependency adaptation. No refactor was needed after the focused green run.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/lockspire/protocol/client_app_authentication_test.exs test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/token_exchange/dependencies_test.exs test/lockspire/architecture_fitness_test.exs --max-failures 1` — passed, 43 tests, 0 failures.
- `git diff --check` — passed.
- Full `mix test.fast` remains phase-final work.

## Next Phase Readiness

Plans 163-04 onward can reuse the shared authentication gate. Plan 163-06 owns carrying the verified identity into final guarded writers and comparing it after current-row locks. Secret expiry and rotation remain Phase 164 work.

## Self-Check: PENDING PARENT COMMIT

- Focused verification passed with 43 tests and 0 failures.
- Parent executor will record the implementation commit, measured commit count, and final commit self-check.

---
*Phase: 163-app-lifetime-compatible-host-storage*
*Completed: 2026-10-20*

Parent implementation commit: `5367a9481744249f15a5c8c96924155dd905f528`; fresh parent verification43tests0failures.
