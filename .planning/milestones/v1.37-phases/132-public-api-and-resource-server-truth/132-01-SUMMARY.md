---
phase: 132-public-api-and-resource-server-truth
plan: 01
subsystem: api
tags: [elixir, oauth, oidc, jwt, plug, resource-server]
requires:
  - phase: 131-executable-installation
    provides: executable embedded-library installation and verification seams
provides:
  - Additive total AccessToken semantic readers for verified JWT claims
  - One audience, scope, and confirmation normalization contract shared with VerifyToken
affects: [132-04-documentation, 133-clean-room-saas-journey, resource-server-hosts]
tech-stack:
  added: []
  patterns:
    - Public semantic readers preserve raw claims while hiding malformed input
    - Route enforcement delegates claim normalization to the public token contract
key-files:
  created: []
  modified:
    - lib/lockspire/access_token.ex
    - lib/lockspire/plug/verify_token.ex
    - test/lockspire/access_token_test.exs
    - test/lockspire/plug/verify_token_test.exs
key-decisions:
  - "Keep the AccessToken struct and raw claims unchanged; semantic readers are additive."
  - "Retain missing-versus-invalid audience errors through an internal result helper while public reads stay total."
  - "Allowlist only DPoP JKT and mTLS certificate thumbprints in confirmation data."
patterns-established:
  - "Use Lockspire.AccessToken as the canonical semantic parser for verified resource-server claims."
requirements-completed: [API-01]
coverage:
  - id: D1
    description: Total normalized subject, scope, audience, expiration, and confirmation readers over AccessToken claims.
    requirement: API-01
    verification:
      - kind: unit
        ref: mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Signed JWT route restrictions consume the same normalized audiences, scopes, and sender-binding confirmation values exposed to hosts.
    requirement: API-01
    verification:
      - kind: integration
        ref: test/lockspire/plug/verify_token_test.exs#signed-token semantic reader parity
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-08-26
status: complete
---

# Phase 132 Plan 01: AccessToken Semantic Contract Summary

**Additive, malformed-safe JWT semantic readers now give host resource servers and VerifyToken the same subject, scope, audience, expiration, and sender-binding meaning.**

## Performance

- **Duration:** 7 min
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added typed, documented total readers for normalized subject, scopes, audiences, integer NumericDate expiration, and allowlisted confirmation data.
- Preserved the existing struct and raw `claims` map as the v1.x compatibility and extension path.
- Refactored VerifyToken route scope/audience enforcement and sender-binding derivation to use the same normalization contract, retaining `:missing_audience` versus `:invalid_audience` taxonomy.
- Added direct malformed-shape matrices and signed-JWT Plug parity tests, including non-disclosure of arbitrary `cnf` members.

## Task Commits

1. **Task 1: Prove one subject/scope/audience path from verified JWT to host reads** — `e984ae0` (RED tests), `9062934` (implementation)
2. **Task 2: Complete expiration and allowlisted confirmation semantics** — `bff75d7` (tests), `88d5e05` (implementation)

## Files Created/Modified

- `lib/lockspire/access_token.ex` — public readers and strict internal audience/confirmation normalization helpers.
- `lib/lockspire/plug/verify_token.ex` — delegates restriction and binding interpretation to AccessToken.
- `test/lockspire/access_token_test.exs` — direct valid and malformed semantic-reader coverage.
- `test/lockspire/plug/verify_token_test.exs` — signed JWT enforcement and sender-binding parity proofs.

## Decisions Made

- Public readers return `nil` or `[]` for malformed data; route enforcement retains strict failure classification through `normalize_audiences/1`.
- Confirmation returns a new map with only `:dpop_jkt` and `:mtls_x5t_s256`, never the raw nested `cnf` map.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The concurrent DPoP/registration executors briefly left the shared compilation state mid-edit; no Plan 01 files were changed outside this slice, and final focused tests plus warnings-as-errors compilation passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 132-04 can use the stable AccessToken semantic reader names in canonical documentation and generated examples.
- The clean-room SaaS journey can consume resource-server readers without parsing raw JWT shapes.

## Self-Check: PASSED

- All four implementation/test files exist.
- Task commits `e984ae0`, `9062934`, `bff75d7`, and `88d5e05` exist.
- Fresh verification passed: `mix compile --warnings-as-errors` and `mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs` (82 tests, 0 failures).
