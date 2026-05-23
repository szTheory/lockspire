---
phase: 80-sender-constraining-integration
plan: 03
subsystem: auth
tags: [oauth, dpop, mtls, plug, bearer, challenge]
requires:
  - phase: 80-02
    provides: soft dpop sender-constraint plug and structured sender errors
provides:
  - mtls sender-constraint enforcement
  - dpop-aware require-token challenges
affects: [phase-80-completion, resource-server-pipeline, challenge-rendering]
tech-stack:
  added: []
  patterns: [single strict 401 boundary, typed sender-constraint challenge mapping]
key-files:
  created: []
  modified:
    - lib/lockspire/plug/enforce_sender_constraints.ex
    - lib/lockspire/plug/require_token.ex
    - test/lockspire/plug/enforce_sender_constraints_test.exs
    - test/lockspire/plug/require_token_test.exs
key-decisions:
  - "MTLS failures remain bearer-side invalid_token challenges while DPoP failures become RFC 9439-style DPoP challenges."
  - "EnforceSenderConstraints prefers conn.private certificate handoff and falls back to an explicit extractor tuple."
patterns-established:
  - "VerifyToken -> EnforceSenderConstraints -> RequireToken is the canonical sender-constrained resource-server pipeline."
  - "RequireToken owns all transport responses; upstream plugs only mutate the assigned access-token error context."
requirements-completed: [VAL-BIND-02, VAL-BIND-03, VAL-DX-02, VAL-DX-03]
duration: 26min
completed: 2026-05-23
---

# Phase 80: Sender-Constraining Integration Summary

**The resource-server plug chain now enforces both DPoP and MTLS bindings and renders standards-aware Bearer vs DPoP 401 challenges from one strict boundary.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-05-23T13:16:00Z
- **Completed:** 2026-05-23T13:20:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Extended `EnforceSenderConstraints` to validate MTLS-bound and dual-bound access tokens using explicit extractor seams or `conn.private[:lockspire_mtls_cert]`.
- Updated `RequireToken` to render DPoP-aware `WWW-Authenticate` responses for structured sender-constraint failures while keeping bearer semantics for generic and MTLS failures.
- Verified the full sender-constraining pipeline with targeted plug tests and a green full-suite run (`844 tests, 0 failures`).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add MTLS enforcement to `EnforceSenderConstraints`** - `f39bab5` (`feat`)
2. **Task 2: Keep `RequireToken` as the strict 401 boundary with DPoP-aware challenges** - `6cba3c2` (`feat`)

## Files Created/Modified

- `lib/lockspire/plug/enforce_sender_constraints.ex` - MTLS extraction, dual-binding enforcement, and bearer-side MTLS sender errors.
- `test/lockspire/plug/enforce_sender_constraints_test.exs` - MTLS, extractor, and dual-binding plug coverage.
- `lib/lockspire/plug/require_token.ex` - Structured sender-error mapping to Bearer vs DPoP `WWW-Authenticate` challenges.
- `test/lockspire/plug/require_token_test.exs` - Final 401 regression matrix for DPoP and MTLS sender-constraint failures.

## Decisions Made

- MTLS enforcement happens in the same soft plug as DPoP so dual-bound tokens can require both constraints in one pass.
- `RequireToken` uses `Lockspire.Protocol.DPoP.signing_alg_values_supported/0` for DPoP challenge algorithm disclosure instead of duplicating an algorithm list.
- Structured sender-constraint errors remain transport-agnostic until the final boundary, preserving the Phase 79 soft/strict split.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Final-wave edits hit one more Elixir guard restriction in MTLS certificate extraction; the code was rewritten as a normal conditional and the plug/challenge suites reran green immediately.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 80 is complete: host routes can compose `VerifyToken -> EnforceSenderConstraints -> RequireToken` for DPoP and MTLS sender-constrained access tokens.
- Milestone follow-on work can build scope and audience restrictions on top of the stabilized sender-constrained pipeline.

---
*Phase: 80-sender-constraining-integration*
*Completed: 2026-05-23*
