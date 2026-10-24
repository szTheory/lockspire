---
phase: 164-client-secret-expiry-atomic-rotation
plan: "02"
subsystem: auth
tags: [oauth, client-secret, jwt, refresh-token, ecto, postgres]
requires:
  - phase: 163
    provides: Client lifetime validation, current-row transaction boundaries, and compatible storage contract
provides:
  - One request-time sample for initial shared-secret and app eligibility
  - Final code and refresh authority validation after grant and token-family locks
  - Generic endpoint error regressions for expired client secrets
affects: [164-03, 164-05, 164-06, client-authentication, code-redemption, refresh-rotation]
actuals:
  tokens: 10522
  tasks: 3
  commits: 7
plan_head_before: 64bb22d8325d8c194b7396f82f4327ffae0cc03a
plan_head_after: f00d4da035a76940f964a209127d25ff65917613
tech-stack:
  added: []
  patterns:
    - Use one post-verification decision instant for secret and app eligibility
    - Recheck verified credential identity and current eligibility inside the last locked issuance callback
key-files:
  created:
    - test/lockspire/protocol/client_secret_lifetime_auth_test.exs
    - test/integration/client_secret_lifetime_code_refresh_test.exs
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-02-01-red-evidence.json
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-02-02-red-evidence.json
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-02-03-red-evidence.json
  modified:
    - lib/lockspire/protocol/client_auth.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
    - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
    - test/lockspire/web/token_controller_test.exs
    - test/lockspire/web/introspection_controller_test.exs
    - test/lockspire/web/revocation_controller_test.exs
key-decisions:
  - Reuse method-aware Client.secret_eligibility/3 for the three shared-secret methods; public-key and mTLS methods remain exempt.
  - Revalidate the current locked credential identity, app state, and secret deadline after all blocking code or refresh locks.
  - Keep secret-JWT assertion signature, claims, and JTI replay checks at ingress; final issuance checks authority without consuming the assertion again.
requirements-completed: []
coverage:
  - id: D1
    description: All seven supported client-auth methods have strict, method-aware secret lifetime coverage with real credential verification.
    requirement: DCR-08
    verification:
      - kind: unit
        ref: test/lockspire/protocol/client_secret_lifetime_auth_test.exs
        status: pass
      - kind: unit
        ref: test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Code redemption and refresh rotation reject authority that expires while requests wait for final locks, preserving durable state on denial.
    requirement: DCR-08
    verification:
      - kind: integration
        ref: test/integration/client_secret_lifetime_code_refresh_test.exs
        status: pass
      - kind: integration
        ref: test/integration/app_lifetime_code_redemption_test.exs
        status: pass
      - kind: integration
        ref: test/integration/app_lifetime_refresh_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Token, introspection, and revocation preserve their generic invalid_client response and Basic challenge for expired secrets.
    requirement: DCR-08
    verification:
      - kind: integration
        ref: test/lockspire/web/token_controller_test.exs
        status: pass
      - kind: integration
        ref: test/lockspire/web/introspection_controller_test.exs
        status: pass
      - kind: integration
        ref: test/lockspire/web/revocation_controller_test.exs
        status: pass
    human_judgment: false
duration: 10 min
completed: 2026-10-21
status: complete
---

# Phase 164 Plan 02: Shared-Secret Authentication and Final Issuance Summary

**Shared-secret expiry now governs all three secret auth methods at one decision instant and again after code or refresh locks, with existing endpoint errors preserved.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-21T14:06:42Z
- **Completed:** 2026-10-21T14:16:14Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Initial authentication validates shared-secret and app deadlines using one sampled request time after credential verification. Basic, post, and secret-JWT use the strict deadline; none, private-key JWT, and both mTLS methods remain usable with a past dormant secret date.
- Code redemption and refresh rotation revalidate the locked client's current verified identity, app eligibility, and secret eligibility at the final callback after the code or token-family locks. A denied final check rolls back token, code/family, and audit changes.
- Token, introspection, and revocation tests assert exact generic `invalid_client` responses and the existing Basic challenge. Corrupt durable lifetime state continues to return `server_error`.
- A successful secret-JWT code exchange confirms the assertion JTI is recorded once and remains replay-blocked.

## Task Commits

1. **Task 1: Apply one strict secret gate across every auth method** - `5e0db1b3` (RED test), `d0f124d2` (implementation), `f00d4da0` (all-method coverage)
2. **Task 2: Recheck current secret authority after code and refresh locks** - `3ed97e31` (RED tests), `a431c382` (implementation), `b003d98e` (single-use JWT issuance coverage)
3. **Task 3: Preserve endpoint errors for expired secret callers** - `13dcca6e` (RED and endpoint contract tests)

## Files Created/Modified

- `lib/lockspire/protocol/client_auth.ex` - Reuses one final authentication time for shared-secret and app eligibility.
- `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex` - Adds `validate_current_authority/4` for current identity and lifetime checks, and samples time inside the locked code builder.
- `lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex` - Applies the same authority predicate inside the post-token-family-lock refresh builder.
- `test/lockspire/protocol/client_secret_lifetime_auth_test.exs` - Covers secret method equality, independent JWT assertion validity, one initial decision instant, and non-secret method exemptions.
- `test/integration/client_secret_lifetime_code_refresh_test.exs` - Covers final code/refresh denial rollback and successful one-time secret-JWT assertion use.
- `test/lockspire/web/token_controller_test.exs`, `test/lockspire/web/introspection_controller_test.exs`, and `test/lockspire/web/revocation_controller_test.exs` - Pin public error envelopes, challenge behavior, and malformed-state handling.
- `164-02-01-red-evidence.json`, `164-02-02-red-evidence.json`, and `164-02-03-red-evidence.json` - Preserve classifier-verified RED reports for the authentication, finalizer, and endpoint regressions.

## Decisions Made

- Kept the existing `Client.secret_eligibility/3` as the shared method-aware policy and preserved its fail-closed handling of malformed lifetime state.
- Reused `ClientAuthentication.verified_identity_matches?/2` at final issuance; no second client-authenticator or JTI consumption was added inside transactions.
- Kept the validation instant inside the code redemption callback and refresh token-family callback, after their blocking locks.

## TDD Evidence

- `164-02-01-red-evidence.json`: `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`. The target Basic authentication test observed the clock advance between secret and app eligibility before the one-sample fix.
- `164-02-02-red-evidence.json`: classifier returned `RED_EVIDENCE_OK` for the code and refresh cases. Before the final guard, both operations returned successful token responses when their final clock sample reached secret-deadline equality.
- `164-02-03-red-evidence.json`: classifier returned `RED_EVIDENCE_OK` for all three endpoint regressions while the shared gate was temporarily omitted. Revocation and introspection returned 200, and token returned 500 instead of the expected authentication failure.
- The project config has `workflow.tdd_mode: false`; these task-level RED/GREEN cycles do not assert a strict phase-wide TDD mode.

## Verification

- Auth selection: `mix test test/lockspire/protocol/client_secret_lifetime_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/client_app_authentication_test.exs --max-failures 1 --timeout 55000` — **35 tests, 0 failures**.
- Code/refresh integration selection: `mix test test/integration/client_secret_lifetime_code_refresh_test.exs test/integration/app_lifetime_code_redemption_test.exs test/integration/app_lifetime_refresh_test.exs --max-failures 1 --timeout 55000` — **9 tests, 0 failures**.
- Endpoint selection: `mix test test/lockspire/web/token_controller_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/revocation_controller_test.exs --max-failures 1 --timeout 55000` — **40 tests, 0 failures**.
- `mix compile --warnings-as-errors` — exit 0.
- `mix format --check-formatted` on the eight owned source/test files — exit 0.

All Mix commands used the supplied Elixir/Erlang versions, `MIX_HOME`, `HEX_HOME`, and `LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation`; no default database was used.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The malformed-state controller test initially expected a secret-specific description. The live endpoint correctly returned its existing generic `Unable to validate client lifetime state` description, so the test was aligned with the established server-error contract.
- The JTI replay assertion needed a microsecond-precision `expires_at` to match its Ecto column; the test now uses the repository's UTC microsecond representation.
- The state progress updater could not find a body `Progress:` line, and the roadmap updater returned `missing_phase_details` despite the existing Phase 164 entries. The verified 164-02 plan checkbox and in-progress count were updated directly; Phase 164 remains incomplete and DCR-08 remains unchecked.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The shared-secret auth and final issuance boundaries are covered for plan 164-02. Plan 164-03 and the phase-level race/full-suite gate remain pending. Management-token lifetime enforcement stays in Phase 165.

## Self-Check: PASSED

- Created test and evidence files listed in frontmatter exist.
- All seven plan task commits are ancestors of the current plan head (`f00d4da0`).
- Task acceptances and all three plan verification selections passed; compile and formatting checks also passed.
- The pre-existing `state.json` bytes still match `/private/tmp/lockspire-v145-original-state.json`.

---
*Phase: 164-client-secret-expiry-atomic-rotation*
*Completed: 2026-10-21*
