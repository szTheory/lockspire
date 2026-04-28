---
phase: "32"
plan: "02"
subsystem: "auth"
tags: ["oauth", "oidc", "device-flow", "token-endpoint", "tdd"]
requires:
  - phase: "32"
    provides: "Durable device poll outcomes and single-winner consume callbacks from plan 32-01"
provides:
  - "Device-code grant routing inside Lockspire.Protocol.TokenExchange"
  - "RFC-shaped public token errors for pending, slow_down, denied, expired, mismatch, unknown, and replayed device polls"
  - "Shared access-token, refresh-token, and optional id_token issuance for approved device authorizations"
affects:
  - "Phase 32 discovery and controller proof"
  - "Device polling support on the shared /token endpoint"
tech-stack:
  added: []
  patterns: ["grant-specific protocol routing", "shared token issuance reuse", "device replay audit evidence"]
key-files:
  created:
    - ".planning/phases/32-polling-token-issuance/32-02-SUMMARY.md"
  modified:
    - "lib/lockspire/protocol/token_exchange.ex"
    - "test/lockspire/protocol/token_exchange_test.exs"
key-decisions:
  - "Device polling stays inside TokenExchange and reuses the existing client-auth, token persistence, refresh-token, and id_token machinery instead of introducing a second issuance stack."
  - "Pending, slow_down, denied, expired, mismatch, unknown, and replayed device outcomes collapse to standard OAuth/RFC 8628 token errors while preserving private reason codes."
  - "Replay-safe device failures append durable device_authorization audit rows only when the repository outcome still carries enough device context to prove the event."
patterns-established:
  - "Device flow should enter the token endpoint as a grant-type branch that converts durable repository outcomes into standard OAuth errors at the protocol layer."
  - "Approved device authorizations can be projected into the shared token Success path by building a token-like grant source and consuming the device row under the existing audit transaction wrapper."
requirements-completed: ["DEV-07", "DEV-08", "DEV-09"]
duration: 13min
completed: 2026-04-28
---

# Phase 32 Plan 02: Polling Token Issuance Summary

**Device-code polling now redeems through Lockspire's shared `/token` pipeline with RFC-shaped continuation errors, single-use replay handling, durable replay audit evidence, and optional OIDC token issuance**

## Performance

- **Duration:** 13 min
- **Started:** 2026-04-28T12:06:00Z
- **Completed:** 2026-04-28T12:19:08Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `grant_type=urn:ietf:params:oauth:grant-type:device_code` routing directly inside `Lockspire.Protocol.TokenExchange`.
- Mapped durable repository poll outcomes into standard public token errors while preserving private `reason_code` values.
- Reused the existing access-token, refresh-token, and `id_token` success machinery for approved device authorizations instead of forking a second response path.
- Added executable protocol proof for pending, `slow_down`, terminal errors, replay safety, audit evidence, refresh-token policy, client mismatch, and optional `id_token`.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing device grant token exchange specs** - `4b8b5c3` (`test`)
2. **Task 1 GREEN: Route device grants through token exchange** - `79f27c6` (`feat`)
3. **Task 2 RED: Add failing device replay and OIDC token specs** - `37a39f5` (`test`)
4. **Task 2 GREEN: Audit and finalize device token redemption** - `8147ad8` (`feat`)

## Files Created/Modified

- `lib/lockspire/protocol/token_exchange.ex` - Adds the device-code grant branch, shared redemption path, RFC-shaped poll outcome mapping, optional device `id_token` support, and replay audit handling.
- `test/lockspire/protocol/token_exchange_test.exs` - Proves device pending/slow_down/terminal mappings, single-use redemption, replay audit evidence, refresh-token policy, client mismatch collapse, and optional `id_token` issuance.

## Decisions Made

- Reused the existing token exchange success struct and persistence helpers by projecting approved device authorizations into a token-like shared grant source.
- Allowed OIDC device success to issue an `id_token` without an interaction nonce when the device authorization has no interaction backing, while still requiring the normal claims and signing-key checks.
- Appended replay audit evidence for consumed device authorizations at the protocol mapping boundary so the audit path still has access to the durable device row.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The initial RED assertions polled too early for the repository's durable first-interval contract, so the pending case was moved to `next_poll_allowed_at` before verifying the intended `authorization_pending` behavior.
- Public and confidential device tests needed explicit `client_store: Repository` wiring because the test harness does not expose `fetch_client_by_id/1` on `Lockspire.TestRepo`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Discovery and controller work can now treat device flow as a shipped token grant with truthful protocol semantics behind it.
- Later Phase 32 work can build HTTP and metadata proof on top of the same shared token contract instead of inventing a device-only response family.

## Self-Check: PASSED

- `.planning/phases/32-polling-token-issuance/32-02-SUMMARY.md` FOUND
- `4b8b5c3` FOUND
- `79f27c6` FOUND
- `37a39f5` FOUND
- `8147ad8` FOUND

---
*Phase: 32-polling-token-issuance*
*Completed: 2026-04-28*
