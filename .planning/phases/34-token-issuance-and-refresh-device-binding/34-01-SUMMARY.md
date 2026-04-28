---
phase: 34-token-issuance-and-refresh-device-binding
plan: "01"
subsystem: auth
tags: [dpop, oauth, oidc, token-endpoint, phoenix, ecto]
requires:
  - phase: 33
    provides: protocol-owned DPoP proof validation, replay persistence, and explicit bearer-vs-DPoP policy resolution
provides:
  - shared token-endpoint DPoP issuance context resolution
  - truthful DPoP token_type responses for authorization-code exchange
  - durable cnf.jkt persistence on DPoP-bound access and refresh tokens
affects: [phase-34-refresh-binding, phase-34-device-binding, phase-35-userinfo]
tech-stack:
  added: []
  patterns: [shared issuance_context seam, protocol-owned token-endpoint DPoP resolution, durable cnf propagation]
key-files:
  created:
    - lib/lockspire/protocol/token_endpoint_dpop.ex
    - test/lockspire/protocol/token_endpoint_dpop_test.exs
  modified:
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/web/controllers/token_controller.ex
    - test/lockspire/protocol/token_exchange_test.exs
    - test/lockspire/web/token_controller_test.exs
key-decisions:
  - "Authorization-code exchange now resolves one protocol-owned issuance_context and threads it through builders and persistence instead of using grant-local DPoP flags."
  - "Server-policy and replay-store defaults fall back to the request’s repository adapter seam so token-endpoint DPoP resolution stays truthful in embedded and test environments."
patterns-established:
  - "Use TokenEndpointDPoP.resolve_context/2 as the shared /token DPoP choke point before grant-specific issuance."
  - "Persist DPoP binding truth by copying issuance_context.cnf onto every token row created by the exchange."
requirements-completed: [DPoP-05, DPoP-06]
duration: 10min
completed: 2026-04-28
---

# Phase 34 Plan 01: Token Issuance and Refresh/Device Binding Summary

**Shared token-endpoint DPoP context with truthful auth-code `token_type: "DPoP"` responses and durable `cnf.jkt` persistence on issued tokens**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-28T17:25:34Z
- **Completed:** 2026-04-28T17:35:44Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `Lockspire.Protocol.TokenEndpointDPoP` as the shared token-endpoint seam for effective DPoP policy resolution, proof validation, and replay recording.
- Threaded a single `issuance_context` through authorization-code issuance so DPoP-mode success responses now return `token_type: "DPoP"` while bearer clients stay unchanged.
- Persisted `cnf.jkt` on both access and refresh tokens for DPoP-bound auth-code exchanges and extended protocol/HTTP proofs around that durable state.

## Task Commits

1. **Task 1: Create the shared token-endpoint DPoP context seam**
   - `d079319` `test(34-01): add failing token-endpoint dpop context tests`
   - `0df116e` `feat(34-01): add shared token-endpoint dpop context seam`
2. **Task 2: Thread auth-code issuance through the shared DPoP context and persist cnf**
   - `29bf581` `test(34-01): add failing dpop auth-code issuance proofs`
   - `5d010fd` `feat(34-01): issue truthful dpop-bound auth-code tokens`

## Files Created/Modified

- `lib/lockspire/protocol/token_endpoint_dpop.ex` - resolves shared token-endpoint DPoP issuance context and replay acceptance.
- `lib/lockspire/protocol/token_exchange.ex` - routes auth-code issuance through `issuance_context`, persists `cnf`, and emits truthful `token_type`.
- `lib/lockspire/web/controllers/token_controller.ex` - passes raw DPoP header/method and repository adapters into protocol code while staying thin.
- `test/lockspire/protocol/token_endpoint_dpop_test.exs` - proves bearer-vs-DPoP context resolution and `invalid_dpop_proof` failures.
- `test/lockspire/protocol/token_exchange_test.exs` - proves DPoP auth-code success, durable `cnf.jkt`, replay rejection, and bearer-default preservation.
- `test/lockspire/web/token_controller_test.exs` - proves `/token` returns HTTP-level `"token_type":"DPoP"` for DPoP-mode clients.

## Decisions Made

- Kept token-endpoint DPoP policy, proof, replay, and binding decisions in protocol-owned code and left the Phoenix controller as a transport adapter only.
- Reused the existing token row `cnf` carrier instead of introducing any new binding storage concept.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Resolved repository-adapter defaults for server policy and replay storage**
- **Found during:** Task 2
- **Issue:** `Config.repo!()` points at the bare Ecto repo in tests, which does not expose Lockspire’s server-policy or DPoP replay store callbacks.
- **Fix:** Fell back to the request’s repository adapter seam and wired `server_policy_store` / `dpop_replay_store` explicitly from the token controller.
- **Files modified:** `lib/lockspire/protocol/token_endpoint_dpop.ex`, `lib/lockspire/web/controllers/token_controller.ex`
- **Verification:** `MIX_ENV=test mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/web/token_controller_test.exs`
- **Committed in:** `5d010fd`

**2. [Rule 3 - Blocking] Normalized verification commands for the local Mix version**
- **Found during:** Task 1 verification
- **Issue:** The plan’s `mix test ... -x` command is not supported by this Mix version, so literal execution fails before tests run.
- **Fix:** Ran the same targeted test commands without `-x` for all verification loops.
- **Files modified:** None
- **Verification:** `MIX_ENV=test mix test.setup` plus the targeted test commands completed successfully.
- **Committed in:** None

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both deviations were required to execute the planned slice truthfully in this repo’s embedded/test environment. No scope creep.

## Issues Encountered

- None beyond the blocking issues above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Refresh-token exchange can now compare presented proofs against durable `cnf.jkt` state instead of reconstructing binding from transport context.
- Device-code redemption can reuse the same `issuance_context` pattern when Phase 34 extends DPoP binding beyond auth-code exchange.

## Threat Flags

None.

## Self-Check: PASSED

- Required summary and key implementation files exist on disk.
- Commits `d079319`, `0df116e`, `29bf581`, and `5d010fd` are present in git history.
