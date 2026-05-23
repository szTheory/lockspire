---
phase: 80-sender-constraining-integration
plan: 02
subsystem: auth
tags: [oauth, dpop, plug, protected-resource, sender-constraining]
requires:
  - phase: 80-01
    provides: normalized sender-binding metadata and shared mtls helper
provides:
  - generic protected-resource dpop validator
  - soft sender-constraint plug for dpop-bound access tokens
affects: [80-03, require-token-challenges, resource-server-pipeline]
tech-stack:
  added: []
  patterns: [generic request-shape validation, soft sender-constraint error assignment]
key-files:
  created:
    - lib/lockspire/plug/enforce_sender_constraints.ex
    - test/lockspire/plug/enforce_sender_constraints_test.exs
  modified:
    - lib/lockspire/access_token.ex
    - lib/lockspire/protocol/protected_resource_dpop.ex
    - test/lockspire/protocol/protected_resource_dpop_test.exs
key-decisions:
  - "Protected-resource DPoP validation now accepts an explicit request target URI instead of hard-coding `/userinfo`."
  - "The new sender-constraint plug stays soft and records typed DPoP failures on the assigned access token rather than halting."
patterns-established:
  - "ProtectedResourceDPoP.validate_access/2 is the reusable entrypoint for plug-driven sender-constraint validation."
  - "Sender-constraint failures are represented as structured maps with challenge type, reason code, and RFC error text."
requirements-completed: [VAL-BIND-01, VAL-BIND-03, VAL-DX-03]
duration: 24min
completed: 2026-05-23
---

# Phase 80: Sender-Constraining Integration Summary

**Resource-server DPoP validation now works against arbitrary request URIs, and a new soft plug records typed DPoP sender-constraint failures without taking over the 401 boundary.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-05-23T13:12:00Z
- **Completed:** 2026-05-23T13:16:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Generalized `ProtectedResourceDPoP` into a reusable `validate_access/2` entrypoint that accepts explicit target URIs and normalized binding requirements.
- Added `Lockspire.Plug.EnforceSenderConstraints` as the soft middle plug for DPoP-bound access tokens.
- Introduced a negative-path plug matrix covering scheme downgrade, missing proof, replay, wrong `ath`, and wrong-key substitution failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Generalize protected-resource DPoP validation** - `9d41377` (`refactor`)
2. **Task 2: Introduce `Lockspire.Plug.EnforceSenderConstraints` for DPoP-bound tokens** - `faceb66` (`feat`)

## Files Created/Modified

- `lib/lockspire/protocol/protected_resource_dpop.ex` - Generic protected-resource DPoP validation with explicit `target_uri` and normalized binding-source handling.
- `test/lockspire/protocol/protected_resource_dpop_test.exs` - Regression coverage for generic protected-resource validation and target-URI validation failures.
- `lib/lockspire/plug/enforce_sender_constraints.ex` - Soft DPoP sender-constraint plug that assigns typed failures instead of responding.
- `test/lockspire/plug/enforce_sender_constraints_test.exs` - Negative-path plug coverage for downgrade, replay, `ath`, and proof-key mismatch scenarios.
- `lib/lockspire/access_token.ex` - Access-token error type widened so structured sender-constraint failures can flow to `RequireToken`.

## Decisions Made

- The plug passes a complete request shape into the protocol layer rather than reimplementing DPoP semantics inside plug code.
- Sender-constraint failures are stored as structured maps so the final `RequireToken` boundary can decide between `Bearer` and `DPoP` challenges later.
- A test-only `:now` option was added to the plug to keep DPoP proof validation deterministic without changing runtime behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial proof fixtures failed because the generic validator was no longer tied to the old `/userinfo` URI and because plug tests needed an injected clock. Both issues were fixed in the test seam rather than weakening runtime validation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `EnforceSenderConstraints` is ready for MTLS extraction and dual-binding enforcement in `80-03`.
- `RequireToken` can now consume structured sender-constraint failures to render DPoP-aware `WWW-Authenticate` challenges.

---
*Phase: 80-sender-constraining-integration*
*Completed: 2026-05-23*
