---
phase: 84-host-plug-pipeline-docs-and-milestone-closure
plan: 01
subsystem: api
tags: [dpop, phoenix, plug, oauth]
requires:
  - phase: 83-lockspire-owned-dpop-endpoint-adoption
    provides: resource-server nonce semantics on Lockspire-owned surfaces
provides:
  - shared protected-resource DPoP challenge transport helper
  - explicit host plug secret_key_base handoff for nonce issuance
  - focused host plug challenge assertions
affects: [userinfo, host-routes, dpop, protected-resources]
tech-stack:
  added: []
  patterns:
    - shared protected-resource transport helper with protocol-owned validation
    - strict response rendering stays in RequireToken while soft validation stays upstream
key-files:
  created: [lib/lockspire/web/protected_resource_challenge.ex]
  modified:
    - lib/lockspire/plug/enforce_sender_constraints.ex
    - lib/lockspire/plug/require_token.ex
    - lib/lockspire/web/controllers/userinfo_controller.ex
    - test/lockspire/plug/require_token_test.exs
key-decisions:
  - "Kept DPoP validation in Lockspire.Protocol.ProtectedResourceDPoP and extracted only transport rendering."
  - "Shared DPoP challenge formatting between /userinfo and RequireToken while preserving bearer handling for non-DPoP userinfo failures."
patterns-established:
  - "Protected-resource adapters share one DPoP challenge helper for WWW-Authenticate, DPoP-Nonce, and expose-header shape."
requirements-completed: [NONCE-RS-01, NONCE-RS-03]
duration: 15m
completed: 2026-05-24
---

# Phase 84 Plan 01: Host Plug Pipeline Summary

**Shared protected-resource DPoP challenge transport now backs both `/userinfo` and the host plug boundary, with explicit `secret_key_base` handoff for nonce-backed retries.**

## Performance

- **Duration:** 15m
- **Started:** 2026-05-24T15:00:00Z
- **Completed:** 2026-05-24T15:15:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `Lockspire.Web.ProtectedResourceChallenge` to unify DPoP `WWW-Authenticate`, `DPoP-Nonce`, and `Access-Control-Expose-Headers` behavior.
- Updated `Lockspire.Plug.EnforceSenderConstraints` to pass `secret_key_base: conn.secret_key_base` into protected-resource DPoP validation.
- Kept `RequireToken` as the strict host-route boundary and preserved `403 insufficient_scope` behavior while tightening nonce retry assertions.

## Task Commits

This run executed in a dirty working tree and did not create phase-specific commits.

## Files Created/Modified

- `lib/lockspire/web/protected_resource_challenge.ex` - shared protected-resource challenge transport helper
- `lib/lockspire/plug/enforce_sender_constraints.ex` - explicit secret key handoff for resource-server nonce issuance
- `lib/lockspire/plug/require_token.ex` - strict host-route DPoP rendering through the shared helper
- `lib/lockspire/web/controllers/userinfo_controller.ex` - `/userinfo` challenge rendering through the shared helper
- `test/lockspire/plug/require_token_test.exs` - exact expose-header assertion for nonce retries

## Decisions Made

- Kept validation ownership inside `Lockspire.Protocol.ProtectedResourceDPoP`; the new helper only shapes HTTP transport.
- Preserved bearer `401` behavior for non-DPoP `/userinfo` failures instead of broadening every userinfo invalid-token response into a DPoP challenge.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first helper extraction over-broadened `/userinfo` invalid-token rendering and missed a generic `challenge: :dpop` clause for normalized plug errors. Both issues were corrected before the verification run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `84-02` docs truth updates and `84-03` generated-host proof on the same nonce transport shape.

## Self-Check: PASSED

- `MIX_ENV=test mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs test/lockspire/web/userinfo_controller_test.exs`

