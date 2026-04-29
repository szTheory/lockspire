---
phase: 37-protocol-strictness-conformance
plan: 1
subsystem: auth
tags: [oidc, jwt, dpop, claims, testing]
requires:
  - phase: 36-auth-code-dpop-core
    provides: DPoP validation and token-endpoint proof handling used for timestamp strictness regressions
provides:
  - Integer-only `iat`, `exp`, and optional `auth_time` emission in signed ID tokens
  - Protocol-owned reservation of `auth_time` across host claim merge boundaries
  - Regression proof that string DPoP `iat` values still fail as `invalid_iat` and collapse publicly to `invalid_dpop_proof`
affects: [phase-37, oidc-conformance, token-exchange, host-claims]
tech-stack:
  added: []
  patterns:
    - Protocol-owned JWT timestamp claims are emitted from `%DateTime{}` inputs only
    - Host claim merge helpers reserve freshness claims before protocol claims are merged
    - Token-boundary timestamp strictness is locked with protocol and controller regression tests
key-files:
  created:
    - test/lockspire/protocol/id_token_test.exs
    - test/lockspire/host/claims_test.exs
  modified:
    - lib/lockspire/protocol/id_token.ex
    - lib/lockspire/host/claims.ex
    - test/lockspire/protocol/dpop_test.exs
    - test/lockspire/protocol/token_endpoint_dpop_test.exs
    - test/lockspire/web/token_controller_test.exs
key-decisions:
  - "Keep `auth_time` protocol-owned by validating it in `IdToken.sign/1` and filtering it from host claim maps."
  - "Preserve existing DPoP runtime behavior and add regression coverage instead of changing proof validation code."
patterns-established:
  - "ID token claim-shaping accepts optional protocol timestamps and emits only integer Unix values."
  - "Public token-endpoint error contracts stay stable even when internal proof rejection reasons get more explicit."
requirements-completed: [CONF-01]
duration: 4min
completed: 2026-04-29
---

# Phase 37 Plan 1: Protocol Strictness Conformance Summary

**Integer-only OIDC ID token timestamps plus reserved `auth_time` filtering and string-`iat` DPoP regression proof**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-29T00:47:30Z
- **Completed:** 2026-04-29T00:51:37Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Added focused ID token tests that decode signed JWT payloads and assert integer `iat`, `exp`, and optional `auth_time` claims.
- Extended `Lockspire.Protocol.IdToken` to reject invalid `auth_time` input before signing and emit Unix timestamps only from `%DateTime{}` values.
- Reserved `auth_time` in host claim filtering and added end-to-end regression coverage that string DPoP `iat` stays invalid internally and publicly maps to `invalid_dpop_proof`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add protocol-owned auth_time support to IdToken** - `ea9bebb` (test), `2b6a3ef` (feat)
2. **Task 2: Reserve auth_time in host claim filtering** - `77a5b32` (test), `a17c039` (feat)
3. **Task 3: Preserve token-facing iat strictness regressions** - `dc0b3ff` (test)

## Files Created/Modified
- `lib/lockspire/protocol/id_token.ex` - Validates optional `auth_time` and emits integer timestamp claims.
- `lib/lockspire/host/claims.ex` - Reserves `auth_time` as protocol-owned claim material.
- `test/lockspire/protocol/id_token_test.exs` - Direct JWT decode coverage for integer timestamp claims and invalid `auth_time`.
- `test/lockspire/host/claims_test.exs` - Host claim filtering regressions for `auth_time` and `sub`.
- `test/lockspire/protocol/dpop_test.exs` - Internal `:invalid_iat` regression for string proof timestamps.
- `test/lockspire/protocol/token_endpoint_dpop_test.exs` - Token-endpoint public `invalid_dpop_proof` regression for string `iat`.
- `test/lockspire/web/token_controller_test.exs` - Controller-surface proof that malformed DPoP timestamp input stays on the stable public error contract.

## Decisions Made
- `auth_time` stays protocol-owned on both input and merge boundaries, so host code cannot override Lockspire’s freshness truth.
- Existing DPoP runtime strictness was already correct; the task stayed narrow and added explicit regression tests instead of altering production behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Task 3 was a regression-only slice because DPoP already rejected string `iat`; the implementation work was limited to proof coverage.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 37 now has a locked timestamp-strictness baseline for `auth_time` and DPoP proof handling.
- The next plans can build durable freshness state and silent-auth behavior on top of protocol-owned timestamp semantics without host claim override risk.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/37-protocol-strictness-conformance/37-01-SUMMARY.md`
- Task commits found: `ea9bebb`, `2b6a3ef`, `77a5b32`, `a17c039`, `dc0b3ff`

---
*Phase: 37-protocol-strictness-conformance*
*Completed: 2026-04-29*
