---
phase: 82-shared-dpop-nonce-primitive
plan: 01
subsystem: auth
tags: [dpop, oauth, oidc, nonce, jwt]
requires: []
provides:
  - Shared stateless DPoP nonce issuance and validation rooted in secret_key_base
  - Opt-in nonce enforcement inside the shared DPoP proof validator
  - Typed nonce failure propagation for token and protected-resource adapters
affects: [phase-83-dpop-endpoint-adoption, phase-84-host-plug-pipeline]
tech-stack:
  added: []
  patterns: [stateless-signed-nonce, typed-validator-failures, purpose-separated-dpop-nonces]
key-files:
  created: [lib/lockspire/protocol/dpop_nonce.ex]
  modified: [lib/lockspire/protocol/dpop.ex, lib/lockspire/protocol/token_endpoint_dpop.ex, lib/lockspire/protocol/protected_resource_dpop.ex]
key-decisions:
  - "Nonce issuance stays stateless and uses Plug.Crypto signing rooted in secret_key_base."
  - "Purpose separation is encoded in the nonce payload so cross-surface reuse fails deterministically."
  - "Nonce validation composes into DPoP.validate_proof/2 and remains opt-in per caller."
patterns-established:
  - "Shared proof validator owns nonce checking and returns typed atoms."
  - "Endpoint adapters map nonce-specific atoms to later HTTP challenge behavior without reparsing proofs."
requirements-completed: [NONCE-CORE-01, NONCE-CORE-02, NONCE-CORE-03, NONCE-CORE-04]
duration: 3 min
completed: 2026-05-23
---

# Phase 82: Shared DPoP Nonce Primitive Summary

**Shared DPoP nonce issuance now sits behind one stateless helper and one opt-in validator seam for both authorization-server and resource-server proof validation.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-23T20:47:22Z
- **Completed:** 2026-05-23T20:50:03Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added a protocol-owned `DPoPNonce` helper that issues opaque signed nonce values for authorization-server and resource-server purposes.
- Extended `DPoP.validate_proof/2` to enforce nonce presence and validity only when callers explicitly request it.
- Preserved typed `:missing_dpop_nonce` and `:invalid_dpop_nonce` outcomes through token-endpoint and protected-resource DPoP consumers.

## Task Commits

Each task was intended to be committed atomically, but this run preserved the existing dirty working tree instead of creating mixed-ownership commits.

1. **Task 1: Add the stateless shared nonce primitive with explicit purpose separation** - `N/A` (verified in working tree)
2. **Task 2: Compose nonce enforcement into the shared DPoP proof validator and preserve typed downstream mapping** - `N/A` (verified in working tree)

**Plan metadata:** `N/A` (summary written without a metadata commit because the repository already contained uncommitted phase edits)

## Files Created/Modified
- `lib/lockspire/protocol/dpop_nonce.ex` - Stateless nonce issue/validate helper with purpose-tagged signed payloads
- `lib/lockspire/protocol/dpop.ex` - Optional nonce enforcement branch inside the shared proof validator
- `lib/lockspire/protocol/token_endpoint_dpop.ex` - Authorization-server nonce failure mapping to typed DPoP errors
- `lib/lockspire/protocol/protected_resource_dpop.ex` - Resource-server nonce failure mapping to typed DPoP errors

## Decisions Made
- Kept nonce state out of storage and operator configuration by using signed opaque payloads.
- Reused the existing validator seam instead of creating separate token and resource nonce validators.
- Preserved nonce-specific internal reason atoms so later public challenge work can stay adapter-local.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Preserved dirty-tree source work instead of creating atomic commits**
- **Found during:** Task 1 and Task 2
- **Issue:** The repository already contained uncommitted phase-related edits in the same protocol files, so new task commits would have mixed existing user-owned work with this execution pass.
- **Fix:** Verified the in-progress source implementation in place, avoided rebasing or overwriting it, and documented the no-commit outcome explicitly.
- **Files modified:** `.planning/phases/82-shared-dpop-nonce-primitive/82-01-SUMMARY.md`
- **Verification:** `mix test test/lockspire/protocol/dpop_test.exs`
- **Committed in:** `N/A`

---

**Total deviations:** 1 auto-fixed (1 blocking/workflow safety)
**Impact on plan:** Source implementation still satisfied the plan goal, but commit-level provenance for this plan remains deferred until the user chooses how to handle the dirty tree.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Shared nonce issuance and typed validator failures are available for public token and userinfo challenge adoption.
- Dirty-tree cleanup remains outstanding before phase work can be split into clean task commits.

## Self-Check: PASSED

---
*Phase: 82-shared-dpop-nonce-primitive*
*Completed: 2026-05-23*
