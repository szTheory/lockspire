---
phase: 163-app-lifetime-compatible-host-storage
plan: "06"
subsystem: auth
tags: [elixir, oauth, authorization-code, token-lifetime, postgres]
requires:
  - phase: 163-app-lifetime-compatible-host-storage
    provides: Typed lifetime/transaction authority from plan 02 and verified credential identities from plan 03
provides:
  - Authorization-code redemption guarded by locked current client and code rows
  - Access and refresh expiry calculated from the final post-lock time and authoritative app deadline
  - Access JWT exp, durable expiry and expires_in sourced from the same access deadline
affects: [163-07, 163-08, 163-09, 163-10, 163-11, 163-12, 164]
actuals:
  tokens: 12800
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns:
    - Prepare access-token format and signing key before durable locks; sign with the final capped expiry inside the guarded operation
    - Acquire current-client then authorization-code locks and sample the injected clock after both locks
key-files:
  created:
    - test/integration/app_lifetime_code_redemption_test.exs
  modified:
    - lib/lockspire/protocol/token_exchange/internal/authorization_code_grant.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_support.ex
    - lib/lockspire/protocol/token_exchange/internal/token_issuer.ex
    - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
    - lib/lockspire/protocol/token_lifetime.ex
    - lib/lockspire/storage/token_store.ex
    - lib/lockspire/storage/ecto/repository/token_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/protocol/token_exchange/authorization_code_test.exs
    - test/support/token_exchange_case.ex
key-decisions:
  - "Carry plan 03's redacted verified-client identity through the issuance context and compare it with the locked current client before code consumption."
  - "Defer final issuance time and access/refresh expiry calculation until the authorization-code row lock is held; prepare remote key lookup and format before locking."
  - "Keep ID-token claims, response assembly and encoding after the durable transaction releases locks."
requirements-completed: [] # Phase-level proof pending
coverage:
  - id: D1
    description: Authorization-code redemption uses current locked client/code state and leaves the grant untouched at the final app deadline.
    requirement: DCR-06
    verification:
      - kind: integration
        ref: test/integration/app_lifetime_code_redemption_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Signed and opaque access tokens share durable, signed and response expiry values capped by the app deadline.
    requirement: DCR-05
    verification:
      - kind: integration
        ref: test/integration/app_lifetime_code_redemption_test.exs
        status: pass
    human_judgment: false
---

# Phase 163 Plan 06: Guarded Code Redemption and Token Expiry Summary

**Authorization-code redemption now checks the locked current client and grant after waits, then persists access and refresh tokens using one final-time app-capped expiry decision.**

## Performance

- **Duration:** approximately 20 minutes
- **Started:** 2026-10-20
- **Completed:** 2026-10-20
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Threaded plan 03's redacted verified-client identity into code redemption and compared it with the current locked client after acquiring the client lock.
- Extended the token-store redemption contract with a builder invoked only after locking the authorization-code row. The builder samples the injected clock once, rechecks app eligibility and code expiry, and prepares issuance with current state.
- Added a shared effective-expiry calculation. Access and refresh tokens use their independent ordinary TTLs, each capped by the current finite app deadline. Persisted expiry, signed JWT `exp`, and `expires_in` now agree; opaque access tokens use the same durable result.
- Prepared key lookup and access-token format before durable locks; built the ID token and response after the transaction released locks.
- Added real PostgreSQL integration checks for signed access/refresh expiry, opaque access expiry, and a clock sequence that authenticates before the deadline but rejects after the code lock at equality without changing code, token or audit counts.

## Task Commits

The parent executor owns shared-workspace commits. Implementation and summary commit hashes are pending parent tracking; `actuals.commits` is currently 0.

## Files Created/Modified

- `lib/lockspire/protocol/token_exchange/internal/authorization_code_grant.ex` — carries the verified auth identity in the issuance context.
- `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex` — locks current client and code rows, checks identity and eligibility, samples final time, caps expiry, persists tokens and audit under one outer transaction.
- `lib/lockspire/protocol/token_exchange/internal/grant_support.ex` — prepares the code grant before locks, maps final app/credential rejection, and assembles success after persistence.
- `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex` and `access_token_signer.ex` — prepare signing/format work before locking, issue with final token expiry, and derive code-grant `expires_in` from persisted expiry.
- `lib/lockspire/protocol/token_lifetime.ex` — computes effective expiry and response seconds.
- `lib/lockspire/storage/token_store.ex`, `lib/lockspire/storage/ecto/repository/token_store.ex`, and `lib/lockspire/storage/ecto/repository.ex` — document and implement the after-code-lock redemption builder while retaining the existing token-value path.
- `test/integration/app_lifetime_code_redemption_test.exs` — real-PostgreSQL signed, opaque, refresh and final-clock boundary proof.
- `test/lockspire/protocol/token_exchange/authorization_code_test.exs` and `test/support/token_exchange_case.ex` — explicitly select the real transaction/audit stores in the legacy fake-token-store PKCE fixture.

## Decisions Made

- The final authorization time is sampled inside the code-row builder, which runs after the locked current client and grant rows are both acquired.
- Access JWT signing uses a key prepared before locking and the exact expiry on the access-token domain value. Response construction and ID-token claim resolution remain outside the locked transaction.
- Whole-second decisions are converted to microsecond-precision UTC values for Ecto `:utc_datetime_usec` writes without changing their Unix second.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing integration seam] Extended GrantSupport for final guarded issuance**
- **Found during:** Task 1
- **Issue:** The plan's files list omitted `GrantSupport`, although it owns endpoint error mapping and response construction for authorization-code redemption.
- **Fix:** Made the minimal path change to prepare issuance before persistence, pass client identity/context to `GrantPersistence`, preserve typed final authority errors, and build the success response after persistence.
- **Files modified:** `lib/lockspire/protocol/token_exchange/internal/grant_support.ex`
- **Verification:** Focused code-redemption and authorization-code suites passed.
- **Committed in:** Pending parent executor.

**2. [Rule 2 - Adapter compatibility] Made the fake PKCE fixture's authority explicit**
- **Found during:** Focused authorization-code regression run
- **Issue:** The legacy `PlainMethodTokenStore` fixture was implicitly selected as transaction and audit authority, so dependency adaptation correctly rejected it before the intended unsupported-PKCE case.
- **Fix:** Allowed the shared test helper to accept explicit transaction/audit stores and set both to `Repository` in this read-only rejection fixture; mutation authority checks remain unchanged.
- **Files modified:** `test/lockspire/protocol/token_exchange/authorization_code_test.exs`, `test/support/token_exchange_case.ex`
- **Verification:** Focused authorization-code suite passed.
- **Committed in:** Pending parent executor.

**3. [Rule 1 - Persistence precision] Preserved second boundaries in UTC microsecond columns**
- **Found during:** Task 2 integration run
- **Issue:** Ecto rejected whole-second `DateTime` values for `:utc_datetime_usec` fields.
- **Fix:** Converted the final Unix second to a microsecond-precision UTC value before persistence; expiry comparison and JWT Unix seconds remain unchanged.
- **Files modified:** `lib/lockspire/protocol/token_lifetime.ex`, `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex`
- **Verification:** Focused real-PostgreSQL redemption suite passed.
- **Committed in:** Pending parent executor.

**Total deviations:** 3 auto-fixed. Changes remain within the code-redemption integration boundary.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_code_redemption_test.exs test/lockspire/storage/repository_atomicity_test.exs test/lockspire/protocol/access_token_signer_test.exs test/lockspire/protocol/token_exchange/authorization_code_test.exs --max-failures 1` — passed, 45 tests, 0 failures.
- `git diff --check` — passed.
- The plan's later PostgreSQL lock-wait/blocking proof remains owned by its designated later plan and is not claimed here.

## Next Phase Readiness

The code-grant persistence and expiry seam is ready for later token-exchange consumers. This plan does not close Phase 164 secret-expiry behavior or replace the separate PostgreSQL blocking proof.

## Self-Check: PENDING PARENT COMMIT

- Focused verification passed with 45 tests and 0 failures.
- Parent executor will record implementation commit hashes, measured commit count and the final self-check.

---
*Phase: 163-app-lifetime-compatible-host-storage*
*Completed: 2026-10-20*

Parent combined implementation commit: `ff424b48c123d369a77ab2963c935bf8467bc9bd`; fresh combined consumer run296tests0failures.
