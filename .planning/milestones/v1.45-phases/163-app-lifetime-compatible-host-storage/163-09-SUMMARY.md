---
phase: 163-app-lifetime-compatible-host-storage
plan: "09"
subsystem: token-exchange
tags: [elixir, oauth, rfc8693, postgres, token-lifetime]
requires:
  - phase: 163-app-lifetime-compatible-host-storage
    provides: Typed client lifetime authority, final guarded issuance, and shared expiry helpers
provides:
  - RFC 8693 checks requester, subject issuer, and actor issuer app eligibility independently
  - Durable subject and actor token identities survive host validation and final persistence
  - Ordered client and input-token locks protect final-time expiry and atomic output/audit writes
affects: [163-10, 163-12, 166]
actuals:
  tokens: 9679
  tasks: 2
  commits: 0 # Parent executor owns shared commits and measured commit tracking.
tech-stack:
  added: []
  patterns:
    - Lock all participating clients in stable ID order, then lifecycle tokens in token-hash order
    - Prepare signing material before locks and issue JWT claims from the final capped expiry
key-files:
  created:
    - test/integration/app_lifetime_rfc8693_test.exs
  modified:
    - lib/lockspire/host/token_exchange_context.ex
    - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
    - lib/lockspire/protocol/token_exchange/internal/dependencies.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
    - lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex
    - lib/lockspire/protocol/token_exchange/internal/token_issuer.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/storage/ecto/repository/token_store.ex
    - lib/lockspire/storage/token_store.ex
    - test/lockspire/protocol/rfc8693_exchange_test.exs
key-decisions:
  - "Keep actor_token as the host-facing claims map and add actor_token_identity for the durable Token record, preserving the existing validator contract."
  - "Add a declared lock_lifecycle_tokens callback because the existing token adapter had no row-lock operation for final durable input-token revalidation."
  - "Preserve exchange output format behavior: opaque without host claims, signed JWT with host claims; both use the requesting app cap."
metrics:
  duration: 35min
  completed: 2026-10-20
status: complete
---

# Phase 163 Plan 09: RFC 8693 App-Lifetime Guard Summary

**RFC 8693 now validates the requesting, subject-issuing, and actor-issuing apps separately, then issues and audits the result under one final-time transaction.**

## Accomplishments

- Preserved the complete subject and optional actor token records through validation; host validators receive the existing actor claims map plus a new durable actor identity field.
- Checked requester eligibility as `invalid_client` and subject/actor issuer eligibility as `invalid_grant` before calling host validation or claims logic. Invalid lifetime state and unavailable storage remain `server_error`.
- Replaced standalone token storage with shared guarded persistence. The transaction locks all participant clients in stable ID order, locks subject/actor lifecycle tokens by stable token hash, rechecks current state after waits, and samples one final clock value.
- Capped opaque and signed output expiry to the current requesting app deadline. JWT `exp`, persisted expiry, and `expires_in` use the same final decision; token and audit writes roll back together.
- Adapted the legacy RFC 8693 mock stores to declare the required shared authority and lock callback.
- Added PostgreSQL integration coverage for independent expired subject and actor issuers, zero host callbacks and writes on issuer rejection, durable identities passed to the host, opaque and signed expiry agreement, and final-deadline equality with unchanged token and audit counts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing storage seam] Added a narrow lifecycle-token lock callback**
- **Found during:** Task 2
- **Issue:** The declared client adapter already exposed stable current-client locks, but the token store had no callback for locking and reloading the durable subject and actor tokens before final issuance.
- **Fix:** Added `lock_lifecycle_tokens/1` to the token-store contract, Repository facade, and Ecto implementation. The Ecto callback requires an active transaction and locks deduplicated token hashes in sorted order.
- **Files modified:** `lib/lockspire/storage/token_store.ex`, `lib/lockspire/storage/ecto/repository.ex`, `lib/lockspire/storage/ecto/repository/token_store.ex`
- **Verification:** Focused integration and compatibility suite passed.
- **Commit:** Pending parent executor.

**2. [Rule 2 - Missing issuance seam] Added prepared RFC 8693 signing through shared persistence**
- **Found during:** Task 2
- **Issue:** Existing exchange signing selected an expiry before the final client and token locks, so it could not match the durable row and response at app-deadline equality.
- **Fix:** Added prepared signing helpers so key lookup happens before locks and the JWT is signed with the final capped expiry inside the shared persistence operation.
- **Files modified:** `lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex`, `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex`, `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex`
- **Verification:** Signed and opaque expiry agreement passed in PostgreSQL integration tests.
- **Commit:** Pending parent executor.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_rfc8693_test.exs test/lockspire/protocol/rfc8693_exchange_test.exs --max-failures 1` — passed, 15 tests, 0 failures.
- `git diff --check` — passed.
- `mix test.fast` was not run; this subtask stayed within the bounded focused verification requested for Plan 09.

## Next Phase Readiness

RFC 8693 app-lifetime enforcement and focused compatibility proof are ready for the remaining phase work. The separate-session opposing-order lock proof remains part of the designated concurrency plan.

## Self-Check: PENDING PARENT COMMIT

- The integration test and summary files exist, and the focused command passes.
- Parent executor will measure plan commits and update the final commit ledger fields.

---
*Phase: 163-app-lifetime-compatible-host-storage*
*Completed: 2026-10-20*

Parent implementation commit: `0399c77f732c6620b0fc666489e1b4e6ea604981`; parentfresh15tests0failures.
