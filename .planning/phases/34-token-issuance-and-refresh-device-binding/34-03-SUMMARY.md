---
phase: 34-token-issuance-and-refresh-device-binding
plan: "03"
subsystem: auth
tags: [dpop, oauth, oidc, device-flow, token-endpoint, phoenix, ecto]
requires:
  - phase: 34
    provides: shared token-endpoint DPoP issuance context and durable cnf persistence for auth-code issuance
provides:
  - device-code redemption through the shared DPoP issuance seam
  - truthful DPoP token_type responses for approved device-code exchange
  - generated-host proof that DPoP binding happens only on the winning /token request
affects: [phase-35-userinfo, phase-36-dpop-e2e, device-flow, public-clients]
tech-stack:
  added: []
  patterns: [shared issuance_context reuse across grant types, token-time DPoP binding for device flow]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/token_exchange.ex
    - test/lockspire/protocol/token_exchange_test.exs
    - test/integration/phase32_device_flow_token_exchange_e2e_test.exs
key-decisions:
  - "Device-code exchange now resolves TokenEndpointDPoP before approved-redemption so DPoP binding stays at the Lockspire-owned /token boundary instead of leaking into host-owned /verify state."
  - "The generated-host replay proof uses a fresh DPoP JWT on the second /token request so the test isolates consumed device_code collapse to invalid_grant rather than proof replay rejection."
patterns-established:
  - "Reuse TokenEndpointDPoP.resolve_context/2 for device flow exactly as for other /token grant paths."
  - "Public/CLI DPoP end-to-end tests should attach the proof only on the winning token request and keep /verify interactions unchanged."
requirements-completed: [DPoP-08]
duration: 6min
completed: 2026-04-28
---

# Phase 34 Plan 03: Device DPoP Redemption Summary

**Device-code redemption now reuses the shared token-endpoint DPoP issuance path, returns truthful `token_type: "DPoP"` for approved DPoP clients, and proves binding occurs only on the winning `/lockspire/token` call**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-28T17:38:00Z
- **Completed:** 2026-04-28T17:43:52Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Threaded `issuance_context` through device-code redemption so approved device authorizations can issue DPoP-bound access and refresh tokens without a device-specific path.
- Preserved bearer-mode device behavior and existing public pending/slow_down/denied/expired/replay semantics while making successful DPoP responses truthful.
- Added generated-host end-to-end proof for a public DPoP device client showing `/verify` stays unchanged and replayed device codes still collapse to `invalid_grant`.

## Task Commits

1. **Task 1: Apply the shared DPoP issuance context to device-code redemption**
   - `0a48c3a` `test(34-03): add failing device dpop redemption proofs`
   - `f235d2d` `feat(34-03): bind device redemption through shared dpop issuance`
2. **Task 2: Prove DPoP device redemption through the generated-host end-to-end flow**
   - `a99458c` `test(34-03): add device dpop host-flow proof`

## Files Created/Modified

- `lib/lockspire/protocol/token_exchange.ex` - resolves shared DPoP issuance context for device-code exchange and carries it through success persistence and response shaping.
- `test/lockspire/protocol/token_exchange_test.exs` - proves approved DPoP device redemption persists `cnf.jkt`, returns `token_type: "DPoP"`, and preserves bearer-mode device behavior.
- `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` - proves host-approved public device flow attaches DPoP only at `/lockspire/token` and still collapses replayed device codes to `invalid_grant`.

## Decisions Made

- Reused the existing shared issuance seam instead of adding any DPoP state to `DeviceAuthorization` records, preserving the host-owned verification boundary exactly as planned.
- Treated device-code replay and DPoP proof replay as separate behaviors in end-to-end coverage so the test remains truthful about which boundary rejects each failure.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `userinfo` and related owned-surface work can now rely on durable `cnf.jkt` state from both auth-code and device-code DPoP issuance paths.
- The milestone has executable public/CLI-oriented DPoP proof ready to extend in Phase 36 without widening the host verification seam.

## Threat Flags

None.

## Self-Check: PASSED

- Required summary file exists on disk.
- Commits `0a48c3a`, `f235d2d`, and `a99458c` are present in git history.
