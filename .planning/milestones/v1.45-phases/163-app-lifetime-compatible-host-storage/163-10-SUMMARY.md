---
phase: 163-app-lifetime-compatible-host-storage
plan: "10"
subsystem: protocol
tags: [elixir, oauth, oidc, app-lifetime, userinfo, introspection, revocation]

requires:
  - phase: 163-app-lifetime-compatible-host-storage
    provides: Typed ClientLifetime adapter and shared ClientAuth app eligibility from plans 02 and 03
provides:
  - UserInfo checks the current issuing app through the configured client adapter before security-profile or host claims work
  - Introspection preserves caller authorization and token ownership before current target app observation
  - Revocation authenticates eligible callers, including public clients, while retaining non-disclosing unknown-token success
affects: [163-11, 163-12, 163-13, 163-14, 164, 165, 166]

tech-stack:
  added: []
  patterns:
    - Online consumers adapt declared client lifetime support at their options boundary
    - Endpoint-owned errors keep inactive credentials distinct from adapter and storage failures
    - Offline VerifyToken remains independent of issuing-app storage state

key-files:
  created:
    - test/integration/app_lifetime_online_consumers_test.exs
  modified:
    - lib/lockspire/protocol/userinfo.ex
    - lib/lockspire/protocol/introspection.ex
    - lib/lockspire/protocol/revocation.ex

key-decisions:
  - "UserInfo uses the declared client adapter for both current issuer state and the security profile, before host account or claims callbacks."
  - "Introspection checks target app state only after caller authorization and token ownership; inactive owned targets expose only active:false."
  - "VerifyToken remains offline, so an already-issued signed JWT cannot learn a later app expiry or disablement."

requirements-completed: [] # Phase-level proof pending
metrics:
  duration: "about 15 minutes"
  completed: 2026-10-20
status: complete
actuals:
  tokens: 5166
  tasks: 2
  commits: pending_parent
---

# Phase 163 Plan 10: Online Consumer App Lifetime Summary

**UserInfo, introspection, and revocation now apply current app lifetime through the declared client adapter while preserving endpoint-specific errors and ownership rules.**

## Accomplishments

- UserInfo adapts typed lifetime support at its request boundary, resolves and validates the current issuer before security-profile processing, and returns the existing 401 Bearer `invalid_token` for expired or disabled issuers. Store, malformed lifetime, and adapter configuration failures remain server errors.
- Replaced UserInfo's hardcoded Ecto client lookup, including security-profile resolution, with the declared client store. Denied requests do not call host account or claims callbacks.
- Introspection retains caller authentication and token ownership checks before reading the target issuer. An owned token from an expired or disabled app returns exactly `%{active: false}`; malformed adapter state and store failures remain server errors.
- Revocation now passes typed lifetime support through `ClientAuth`, so expired confidential and public callers fail authentication before token work. Eligible callers still receive success for unknown tokens.
- Added a runtime regression proving discovery and JWKS remain public, and that offline `VerifyToken` still accepts a correctly signed JWT after its issuing app expires.

## Files

- `lib/lockspire/protocol/userinfo.ex` — current issuer lookup before access-mode/security-profile and host claims work.
- `lib/lockspire/protocol/introspection.ex` — owned target lifetime observation and fail-closed adapter errors.
- `lib/lockspire/protocol/revocation.ex` — typed caller lifetime support.
- `test/integration/app_lifetime_online_consumers_test.exs` — custom adapter, callback ordering, HTTP challenge, target ownership, caller eligibility, unknown-token semantics, discovery/JWKS, and offline JWT regressions.

## Deviations from Plan

None. VerifyToken production behavior is unchanged; its regression test demonstrates that signed JWT verification remains offline.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_online_consumers_test.exs test/lockspire/web/userinfo_controller_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/plug/verify_token_test.exs --max-failures 1` — passed, 113 tests, 0 failures.
- `git diff --check -- lib/lockspire/protocol/userinfo.ex lib/lockspire/protocol/introspection.ex lib/lockspire/protocol/revocation.ex test/integration/app_lifetime_online_consumers_test.exs` — passed.
- Phase-wide `mix test.fast`, security review, migration/upgrade proof, and cross-phase packaged journeys remain with their assigned plans.

## Parent-Owned Tracking

The shared-workspace parent owns implementation commits, measured commit metadata, and final planning-state bookkeeping. Commit hashes and the final parent-commit self-check are pending that tracking.

## Self-Check: PASSED (subtask files and verification)

- All four implementation/test artifacts listed above exist.
- Focused runtime suite and whitespace check passed.
- Task and summary commits are intentionally pending the parent executor.

---
*Phase: 163-app-lifetime-compatible-host-storage*
*Plan: 10*
*Completed: 2026-10-20*

Parent combined implementation commit: `ff424b48c123d369a77ab2963c935bf8467bc9bd`; fresh combined consumer run296tests0failures.
