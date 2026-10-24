---
phase: 163-app-lifetime-compatible-host-storage
plan: "07"
subsystem: token-issuance
tags: [refresh-token, app-lifetime, postgres, jwt]
requires:
  - phase: 163-app-lifetime-compatible-host-storage
    provides: Current-client lock and verified-credential validation from plan 06
provides:
  - Refresh rotation checks locked current-client state after refresh-family locks
  - Access and replacement refresh expiries use their separate TTLs capped by app deadline
  - Refresh rotation preserves replay-family revocation under one audit rollback authority
affects: [163-12, 166]
actuals:
  tokens: 6795
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [after-lock refresh rotation builder, stable token-family row locking]
key-files:
  created: [test/integration/app_lifetime_refresh_test.exs]
  modified:
    - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
    - lib/lockspire/protocol/token_exchange/internal/token_issuer.ex
    - lib/lockspire/storage/token_store.ex
    - lib/lockspire/storage/ecto/repository/token_store.ex
    - lib/lockspire/storage/ecto/repository.ex
key-decisions:
  - "Prepare signing before locks; decide eligibility and effective expiry after client and refresh-family locks."
  - "Extend the existing refresh mutation API with a builder while retaining fixed-value callers."
requirements-completed: [] # Phase-level proof pending
coverage:
  - id: D1
    description: "Refresh rotation enforces current app authority and stores access/refresh deadlines capped by the app deadline."
    requirement: DCR-06
    verification:
      - kind: integration
        ref: test/integration/app_lifetime_refresh_test.exs
        status: pass
      - kind: integration
        ref: "env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_refresh_test.exs test/lockspire/protocol/refresh_exchange_test.exs --max-failures 1"
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-10-20
status: complete
---

# Phase 163 Plan 07: Refresh Rotation Summary

**Refresh rotation now checks the locked current client after family waits and persists separate access and refresh expiries capped by the app deadline.**

## Accomplishments

- Added an after-lock refresh builder to the token-store contract and Ecto implementation while preserving existing fixed-value rotation calls.
- Refresh issuance now locks client state before family rows, validates the previously verified credential identity after family locks, samples one final clock, and computes both effective expiries from that decision.
- Kept family replay revocation and required audit writes inside the transaction authority; app rejection at deadline equality leaves the family, token count, and audit count unchanged.
- Added PostgreSQL integration proof for signed expiry agreement, equality rejection, valid replay revocation, and offline verification of an already-issued JWT after client disablement.

## Task Commits

Implementation commits are pending the parent executor, which owns shared-workspace commit tracking.

## Files Created/Modified

- `test/integration/app_lifetime_refresh_test.exs` — refresh expiry, rollback, replay, and offline JWT verification proof.
- `lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex` — guarded, final-time refresh rotation and response expiry.
- `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex` — exposes shared current-client validation for refresh use.
- `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex` — prepared access-token signing helpers reused by refresh.
- `lib/lockspire/storage/token_store.ex` and `lib/lockspire/storage/ecto/repository/token_store.ex` — callback contract and ordered family locking.
- `lib/lockspire/storage/ecto/repository.ex` — adapter facade support for builder-based refresh rotation.

## Decisions Made

- Signing preparation remains outside the transaction; final identity/app validation, clock sampling, token signing with final expiry, and durable rotation run after locks.
- Fixed-value token-store callers remain supported alongside the new builder form.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing integration seam] Added repository facade support for refresh builders**
- **Found during:** Task 1
- **Issue:** The plan listed the Ecto token-store adapter but not its public repository facade, which otherwise rejected builder calls.
- **Fix:** Extended the existing facade arity to forward builder calls while preserving fixed-value calls.
- **Files modified:** `lib/lockspire/storage/ecto/repository.ex`
- **Verification:** Both focused plan test commands passed.
- **Committed in:** Pending parent executor.

**Total deviations:** 1 auto-fixed. The facade change is required to use the declared store contract through the built-in adapter.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_refresh_test.exs test/lockspire/protocol/refresh_exchange_test.exs --max-failures 1` — passed, 19 tests, 0 failures.
- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_refresh_test.exs test/lockspire/protocol/access_token_signer_test.exs --max-failures 1` — passed, 21 tests, 0 failures.
- `git diff --check` — passed.

## Next Phase Readiness

Refresh lifetime enforcement is ready for the later PostgreSQL race and packaged-host proof. This work does not close Phase 164 secret expiry or Phase 166 cross-phase validation.

## Self-Check: PENDING PARENT COMMIT

- Focused refresh, signer, rollback, and replay checks passed.
- Parent executor will record implementation commits and finalize the measured commit count.

---
*Phase: 163-app-lifetime-compatible-host-storage*
*Completed: 2026-10-20*

Parent implementation commit: `fd7a71cb541e6bfc729653d92a3ef8109b203858`; parentfreshfocusedcheckpassed.
