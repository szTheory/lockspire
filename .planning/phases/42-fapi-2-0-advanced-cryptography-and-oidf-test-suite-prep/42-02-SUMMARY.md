---
phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
plan: 02
subsystem: auth
tags: [oauth, oidc, fapi, jar, id-token, jose]
requires:
  - phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
    provides: canonical ES256/PS256-only signing policy and FAPI key lifecycle guards
provides:
  - profile-aware JAR verification allow-listing
  - profile-aware ID token signing preflight
  - focused runtime tests for ES256/PS256-only FAPI behavior
affects: [logout, end-session, dpop, discovery, jwks]
tech-stack:
  added: []
  patterns: [canonical allow-list propagation, signer preflight before JOSE operations]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/jar.ex
    - lib/lockspire/protocol/id_token.ex
    - test/lockspire/protocol/jar_test.exs
    - test/lockspire/protocol/id_token_test.exs
key-decisions:
  - "JAR and ID token flows both resolve FAPI signing algorithms from SecurityProfile.allowed_signing_algorithms/1 instead of per-surface constants."
  - "ID token signing rejects unsupported algorithms before JOSE signing and preserves the legacy RS256 path only when the effective profile is :none."
patterns-established:
  - "Runtime protocol surfaces must preflight algorithms against the canonical security profile before invoking JOSE verification or signing."
requirements-completed: [FAPI-04]
duration: 8min
completed: 2026-05-02
---

# Phase 42: Plan 02 Summary

**JAR request-object verification and ID token signing now share the canonical FAPI allow-list, rejecting RS256 and EdDSA under FAPI-effective runtime behavior while preserving legacy behavior only for `:none`**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-02T01:46:00Z
- **Completed:** 2026-05-02T01:54:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Removed the JAR-local algorithm constant and made request-object verification consume profile-aware algorithm lists from the Phase 42 canonical policy.
- Tightened ID token signer preflight so emitted JOSE headers and key validation stay aligned with the same canonical allow-list.
- Added focused protocol tests proving FAPI-effective runtime behavior accepts only ES256/PS256 and keeps the broader RS256/EdDSA behavior only for non-FAPI profiles.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make JAR verification consume the canonical profile-aware allow-list** - `dc0c4b5` (`feat`)
2. **Task 2: Make ID token signing enforce the canonical FAPI signer policy** - `35ea281` (`feat`)

**Plan metadata:** This summary is committed separately after the task commits.

## Files Created/Modified
- `lib/lockspire/protocol/jar.ex` - Accepts a caller-provided allow-list, decodes persisted JWKs safely, and routes signature verification through the canonical policy.
- `test/lockspire/protocol/jar_test.exs` - Covers FAPI rejection of RS256/EdDSA, acceptance of ES256/PS256, and legacy `:none` compatibility.
- `lib/lockspire/protocol/id_token.ex` - Enforces canonical signing algorithms before JOSE signing and preserves both JSON and Erlang-encoded key decoding.
- `test/lockspire/protocol/id_token_test.exs` - Covers FAPI rejection of RS256 and FAPI acceptance of ES256/PS256.

## Decisions Made
- JAR verification now treats the algorithm allow-list as an explicit dependency so future callers can pass resolved profile truth instead of relying on hidden module state.
- ID token signing keeps the existing error envelope but introduces a distinct `:unsupported_signing_algorithm` failure before cryptographic work begins.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered
- The initial executor again stalled before committing; the partial runtime diff was completed and validated directly on the main worktree.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plans 05 and 07 can now assume the highest-throughput signer and verifier paths honor the canonical Phase 42 algorithm truth.
- Discovery, JWKS, logout, end-session, and DPoP follow-on work no longer need to compensate for RS256/EdDSA drift in JAR or ID token behavior.

---
*Phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep*
*Completed: 2026-05-02*
