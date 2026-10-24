---
phase: 163-app-lifetime-compatible-host-storage
plan: "05"
subsystem: protocol
tags: [elixir, oauth, device-authorization, ciba, app-lifetime]
requires:
  - phase: 163-02
    provides: Typed client-lifetime and transaction authority contracts
  - phase: 163-03
    provides: Current client eligibility and explicit clock conventions
provides:
  - Current-app checks for device creation, lookup, verification, and approval
  - Lock-aware device and CIBA approval mutations with decision clocks sampled after request locks
  - Current-app checks for CIBA initiation and host approval
affects: [163-08, 164, 165]
actuals:
  tokens: 22500
  tasks: 2
  commits: 0 # Parent owns shared-workspace commits and final tracking
tech-stack:
  added: []
  patterns:
    - Mutation callbacks execute after the current request row is locked
    - Client-before-request approval checks share one transaction and explicit clock
key-files:
  created:
    - test/integration/app_lifetime_device_test.exs
    - test/integration/app_lifetime_ciba_approval_test.exs
  modified:
    - lib/lockspire/protocol/device_authorization.ex
    - lib/lockspire/protocol/device_verification.ex
    - lib/lockspire/storage/device_authorization_store.ex
    - lib/lockspire/storage/ecto/repository/device_authorization_store.ex
    - lib/lockspire/protocol/backchannel_authentication.ex
    - lib/lockspire/ciba.ex
    - lib/lockspire/storage/ciba_authorization_store.ex
    - lib/lockspire/storage/ecto/repository/ciba_authorization_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/protocol/device_authorization_test.exs
    - test/lockspire/protocol/device_verification_test.exs
    - test/lockspire/protocol/backchannel_authentication_test.exs
    - test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs
    - test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs
key-decisions:
  - "Retained existing public CIBA approval API and added an internal clock-aware seam."
  - "Preserved map-based transition callers while allowing post-lock mutation callbacks."
  - "Host callbacks and CIBA notification work remain outside database row locks."
duration: 1 day
completed: 2026-10-20
status: complete
requirements-completed: [] # Phase-level proof pending
---

# Phase 163 Plan 05: Device and CIBA App Lifetime Guards Summary

**Device and CIBA entry and approval paths now validate current application authority in the shared transaction, sampling decision time after request-lock waits.**

## Accomplishments

- Device creation and lookup use the declared lifetime adapter and explicit clock; creation rechecks eligibility after acquiring the current client lock.
- Device verification and approval guard the current client and request under client-before-request lock order. Approval mutations evaluate the supplied clock and current request only after the request lock, and rejection leaves status and durable grant/audit counts unchanged.
- CIBA initiation rechecks app state and expiry after host resolution and under the client lock. Host approval uses a private clock-aware seam while preserving `approve_authorization/3`; status and approval audit persist atomically after ordered locks.
- Store transition contracts preserve map callers and support callbacks evaluated after row-lock acquisition. Existing polling, expiry, replay, and delivery behavior remains covered by focused compatibility tests.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_device_test.exs test/lockspire/protocol/device_verification_test.exs --max-failures 1` — passed, 15 tests, 0 failures.
- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_ciba_approval_test.exs test/lockspire/protocol/backchannel_authentication_test.exs --max-failures 1` — passed, 9 tests, 0 failures.
- Device authorization and existing device/CIBA delivery compatibility tests — passed, 9 tests, 0 failures.
- Direct client JWT authentication tests — passed, 9 tests, 0 failures after adapting fixtures to the explicit lifetime/transaction contract.
- `mix format --check-formatted` on the touched protocol, store, and repository facade files — passed.
- The plan-wide `mix test.fast` gate was not run, per parent orchestration's bounded-check instruction; parent wave verification remains responsible for the broader gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Compatibility] Updated direct JWT fixtures for the explicit adapter contract**
- **Found during:** Focused direct JWT regression tests.
- **Issue:** Existing test adapters omitted lifetime and transaction authority now required by the declared client-authentication contract.
- **Fix:** Updated the affected fixtures to declare legacy v0 lifetime and the transaction authority explicitly; production validation was not weakened.
- **Files modified:** `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`, `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`.
- **Verification:** Both focused tests passed (9 tests, 0 failures).

## Parent-Owned Tracking

Implementation and this summary are uncommitted in the shared workspace. Parent orchestration owns the combined commit, commit hashes, and shared planning-state updates.

## Self-Check: PASSED

- Both new durable integration test files exist and the focused device/CIBA boundary tests pass.
- Parent-side commit/hash verification remains pending.

Parent combined implementation commit: `ff424b48c123d369a77ab2963c935bf8467bc9bd`; fresh combined consumer run296tests0failures.
