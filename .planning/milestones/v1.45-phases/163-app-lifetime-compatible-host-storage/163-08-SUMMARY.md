---
phase: 163-app-lifetime-compatible-host-storage
plan: "08"
subsystem: auth
tags: [oauth, ciba, device-code, postgres, jwt]
requires:
  - phase: 163-app-lifetime-compatible-host-storage
    provides: Typed client lifetime authority, ordered current-client/request transitions, and prepared access-token signing.
provides:
  - Device and CIBA polling revalidate the locked client and request before consuming approved grants.
  - Poll and push token expiry is calculated at the final locked decision and shared by durable tokens, JWTs, and expires_in.
  - CIBA push reloads durable client/request state and uses explicit Repository stores and clock.
affects: [163-12, 164, 166]
actuals:
  tokens: 9509
  tasks: 2
  commits: 0
plan_head_before: aab929f5a338b9b6418ac786a69bdebe4225c33b
plan_head_after: aab929f5a338b9b6418ac786a69bdebe4225c33b
commits: 0
tech-stack:
  added: []
  patterns:
    - Prepare access-token signing before client/request locks, then sign with the post-lock expiry.
    - Consume approved device/CIBA requests through existing post-request-lock mutation callbacks.
key-files:
  created:
    - test/integration/app_lifetime_poll_issuance_test.exs
    - test/integration/app_lifetime_ciba_push_test.exs
  modified:
    - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_support.ex
    - lib/lockspire/protocol/token_exchange/internal/token_issuer.ex
    - lib/lockspire/workers/ciba_notification_worker.ex
key-decisions:
  - "Acquire the current client before the device/CIBA request and take the final clock sample inside the request mutation callback."
  - "Prepare signing and refresh material before locks; persist consumption, access/refresh tokens, and audit in the shared transaction."
  - "Leave the independent-session delivery lock probe to Plan 12; the Plan 08 bounded run does not claim that proof."
requirements-completed: [] # Phase-level proof pending
coverage:
  - id: D1
    description: "Device and CIBA app equality prevents approved-grant consumption and token/audit writes; successful JWT and opaque polls share the app cap."
    requirement: DCR-06
    verification:
      - kind: integration
        ref: "test/integration/app_lifetime_poll_issuance_test.exs"
        status: pass
      - kind: integration
        ref: "test/integration/phase32_device_flow_token_exchange_e2e_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Queued CIBA push checks current app eligibility and successful delivery receives the capped token response after issuance."
    requirement: DCR-06
    verification:
      - kind: integration
        ref: "test/integration/app_lifetime_ciba_push_test.exs"
        status: pass
      - kind: integration
        ref: "test/integration/phase53_ciba_delivery_modes_e2e_test.exs"
        status: pass
    human_judgment: true
    rationale: "The separate-session row-lock probe requested by the plan was not run here and remains assigned to Plan 12."
duration: 20min
completed: 2026-10-20
status: complete
---

# Phase 163 Plan 08: Guard Device/CIBA Polling and Push Summary

**Device and CIBA issuance now rechecks current app/request authority after ordered locks and derives the response, JWT, and stored expiry from one final decision.**

## Accomplishments

- Device and CIBA polling acquire the current client, then lock and inspect the approved request. The injected clock is sampled only after both locks; app rejection leaves the request approved and writes no access token, refresh token, or audit event.
- Access signing and refresh-token material are prepared before locks. Final access and refresh deadlines are separately capped by the app deadline, and `expires_in` is derived from the persisted access expiry.
- CIBA push issues through the stable TokenExchange facade with explicit built-in stores and clock. It reloads the current authorization and client by durable identity, then performs delivery after the issuance transaction returns.
- Focused integration coverage verifies equality rejection for device/CIBA polls, JWT and opaque poll expiry agreement, stale push rejection without delivery/token writes, and capped successful push output.

## Task Commits

The parent executor owns shared-workspace commits and measured tracking. No commits were made by this subagent; the implementation and summary remain pending the parent commit.

## Files Created/Modified

- `test/integration/app_lifetime_poll_issuance_test.exs` — final-equality rollback and JWT/opaque expiry agreement for device and CIBA polls.
- `test/integration/app_lifetime_ciba_push_test.exs` — queued-push app-expiry refusal and successful capped delivery proof.
- `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex` — ordered client/request locks, final-time eligibility/cap, and atomic token/request/audit persistence.
- `lib/lockspire/protocol/token_exchange/internal/grant_support.ex` — prepares poll signing before locks and maps final issuance results while retaining endpoint errors.
- `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex` — reuses the prepared code-grant signer for poll issuance.
- `lib/lockspire/workers/ciba_notification_worker.ex` — passes explicit built-in stores and an injectable worker clock to the stable facade.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing integration seam] Extended poll support through GrantSupport and TokenIssuer**
- **Found during:** Task 1
- **Issue:** The listed source files omitted the existing poll response/signing seam in GrantSupport and the reusable prepared signer interface in TokenIssuer.
- **Fix:** Added narrow helpers for prepared poll signing and threaded the final persistence result back to existing endpoint success/error mapping.
- **Files modified:** `lib/lockspire/protocol/token_exchange/internal/grant_support.ex`, `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex`
- **Verification:** Focused poll tests and Phase 32 device flow tests passed.
- **Committed in:** Pending parent executor.

**Total deviations:** 1 auto-fixed (missing integration seam). The independent-session row-lock probe remains unrun and is assigned to Plan 12; no plan-wide `mix test.fast` run was performed in this bounded subtask.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_poll_issuance_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs --max-failures 1` — passed, 6 tests, 0 failures.
- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/integration/app_lifetime_ciba_push_test.exs test/integration/phase53_ciba_delivery_modes_e2e_test.exs --max-failures 1` — passed, 5 tests, 0 failures.
- `git diff --check` — passed.

## Next Phase Readiness

Plan 12 still needs to provide the independent-session lock proof for delivery-after-release. Phase-level DCR-06/DCR-14 completion and the broader `mix test.fast` gate remain open for the parent phase executor.

## Self-Check: PENDING PARENT COMMIT

- Both requested integration test files exist and the focused commands pass.
- Parent executor will record task/metadata commits, finalize measured commit counts, and complete the cross-phase state update.

---
*Phase: 163-app-lifetime-compatible-host-storage*
*Completed: 2026-10-20*

Parent implementation commit: `f95fb3632613e3e17d4d1e46d89022d3c9c7255f`; parentfocusedcompatibilityrunpassed.
