---
phase: 80-sender-constraining-integration
plan: 01
subsystem: auth
tags: [oauth, oidc, dpop, mtls, plug, jwt]
requires:
  - phase: 79-core-validation-plug
    provides: soft token verification and strict require-token boundary
provides:
  - normalized access-token sender-binding metadata
  - shared mtls thumbprint helper for issuance and protected-resource flows
affects: [80-02, 80-03, resource-server-validation]
tech-stack:
  added: []
  patterns: [soft verification metadata normalization, shared mtls confirmation helper]
key-files:
  created:
    - lib/lockspire/access_token.ex
    - lib/lockspire/plug/verify_token.ex
    - lib/lockspire/protocol/mtls_token_binding.ex
    - test/lockspire/access_token_test.exs
    - test/lockspire/plug/verify_token_test.exs
  modified:
    - lib/lockspire/protocol/token_endpoint_dpop.ex
    - lib/lockspire/protocol/userinfo.ex
    - test/lockspire/protocol/token_endpoint_dpop_test.exs
    - test/lockspire/web/userinfo_controller_test.exs
key-decisions:
  - "Access tokens now preserve the presented authorization scheme separately from normalized sender-binding requirements."
  - "Dual-bound tokens are represented with binding_type `dpop+mtls` plus explicit `binding_requirements` keys instead of a single ambiguous thumbprint field."
  - "MTLS x5t#S256 derivation and comparison now live in one shared protocol helper reused by issuance and protected-resource code."
patterns-established:
  - "Keep VerifyToken soft: it verifies JWTs and normalizes metadata but does not enforce sender constraints."
  - "Use Lockspire.Protocol.MTLSTokenBinding for certificate thumbprint derivation and comparison rather than duplicating SHA-256 logic."
requirements-completed: [VAL-BIND-01, VAL-BIND-02, VAL-DX-03]
duration: 25min
completed: 2026-05-23
---

# Phase 80: Sender-Constraining Integration Summary

**Verified access tokens now carry explicit DPoP and MTLS binding metadata, and issuance plus userinfo paths share one MTLS thumbprint helper.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-23T13:08:00Z
- **Completed:** 2026-05-23T13:12:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- `Lockspire.AccessToken` and `Lockspire.Plug.VerifyToken` now preserve authorization scheme and normalized `cnf` requirements for bearer, DPoP, and dual-bound tokens.
- Added `Lockspire.Protocol.MTLSTokenBinding` to centralize `x5t#S256` thumbprint generation and matching.
- Rewired token-endpoint refresh validation and userinfo MTLS enforcement to use the shared helper without changing their external failure semantics.

## Task Commits

Each task was committed atomically:

1. **Task 1: Normalize verified token sender-binding metadata** - `3320f91` (`feat`)
2. **Task 2: Extract and adopt a shared MTLS token-binding helper** - `39d11fe` (`refactor`)

## Files Created/Modified

- `lib/lockspire/access_token.ex` - Access-token contract for scheme-aware, normalized sender-binding metadata.
- `lib/lockspire/plug/verify_token.ex` - Soft JWT verification plug that accepts `Bearer` and `DPoP` schemes and normalizes `cnf`.
- `lib/lockspire/protocol/mtls_token_binding.ex` - Shared helper for certificate thumbprint derivation and equality checks.
- `lib/lockspire/protocol/token_endpoint_dpop.ex` - Refresh-path and issuance-path MTLS checks now use the shared helper.
- `lib/lockspire/protocol/userinfo.ex` - Userinfo MTLS enforcement now uses the shared helper.
- `test/lockspire/access_token_test.exs` - Contract coverage for the expanded access-token struct.
- `test/lockspire/plug/verify_token_test.exs` - Coverage for DPoP auth-scheme parsing and dual-bound token normalization.
- `test/lockspire/protocol/token_endpoint_dpop_test.exs` - Shared-helper-backed MTLS issuance assertions.
- `test/lockspire/web/userinfo_controller_test.exs` - Shared-helper-backed MTLS userinfo assertions.

## Decisions Made

- `authorization_scheme` is stored exactly as presented so later sender-constraint enforcement can detect DPoP downgrade attempts.
- `binding_requirements` is the durable source of truth for sender constraints; `binding_type` remains only a summary field.
- The MTLS helper returns pure values and booleans so each caller can preserve its own protocol-specific error surface.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first MTLS-helper swap used a remote function inside an Elixir guard in `Userinfo`; verification caught the compile error immediately and the call site was rewritten as a normal conditional before rerunning the targeted suites.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 2 can now build the soft sender-constraint plug on top of normalized DPoP and MTLS token metadata.
- The shared MTLS helper is ready to be reused by the upcoming protected-resource plug without duplicating certificate logic.

---
*Phase: 80-sender-constraining-integration*
*Completed: 2026-05-23*
