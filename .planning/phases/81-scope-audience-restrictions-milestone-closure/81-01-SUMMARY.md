---
phase: 81-scope-audience-restrictions-milestone-closure
plan: 01
subsystem: auth
tags: [plug, jwt, phoenix, scopes, audience]
requires:
  - phase: 79-core-validation-plug
    provides: Soft `%Lockspire.AccessToken{}` assignment for protected-resource validation
  - phase: 80-sender-constraining-integration
    provides: Sender-binding metadata carried through the validation pipeline
provides:
  - Route-level `scopes:` / `audience:` / `audiences:` validation in `VerifyToken`
  - Structured invalid-audience and insufficient-scope errors for downstream enforcement
  - Redaction-safe developer logs for JWT and restriction failures
affects: [require-token, generated-host-route-protection, release-docs]
tech-stack:
  added: [nimble_options]
  patterns: [validated plug init options, typed access-token restriction errors, redaction-safe restriction logging]
key-files:
  created: []
  modified: [mix.exs, lib/lockspire/plug/verify_token.ex, test/lockspire/plug/verify_token_test.exs]
key-decisions:
  - "Kept route restriction intake inside `VerifyToken.init/1` using `NimbleOptions` rather than introducing host config."
  - "Evaluated audience before scopes so wrong-resource tokens remain `invalid_token` instead of looking like authorization misses."
patterns-established:
  - "Protected-resource route options are validated up front in the plug `init/1` boundary."
  - "Restriction failures stay on `%Lockspire.AccessToken{}` as typed maps so downstream plugs can choose HTTP semantics without reparsing claims."
requirements-completed: [VAL-PLUG-04, VAL-DX-01, VAL-DX-03]
duration: 16min
completed: 2026-05-23
---

# Phase 81: Scope/Audience Restrictions & Milestone Closure Summary

**`VerifyToken` now validates route restriction options, evaluates audience and scope after JWT verification, and emits typed soft-failure metadata for the protected-route pipeline.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-05-23T13:54:00Z
- **Completed:** 2026-05-23T14:09:35Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added first-class `NimbleOptions` validation for `scopes:`, `audience:`, and `audiences:` in `Lockspire.Plug.VerifyToken.init/1`.
- Extended `VerifyToken` to enforce audience and scope restrictions after signature/time validation while preserving `%Lockspire.AccessToken{}` assignment and sender-binding metadata.
- Expanded the unit matrix to prove option validation, `aud` normalization, insufficient-scope handling, and redaction-safe failure logging.

## Task Commits

Each task was committed atomically where practical:

1. **Task 1: Validate and normalize explicit route restriction options in `VerifyToken.init/1`** - `97a6e9b` (feat)
2. **Task 2: Enforce normalized audience and scope restrictions in the soft verification step** - `97a6e9b` (feat)

**Plan metadata:** pending summary commit

## Files Created/Modified

- `mix.exs` - Adds a direct `nimble_options` dependency for the protected-resource plug surface.
- `lib/lockspire/plug/verify_token.ex` - Validates route options, evaluates audience before scopes, emits typed errors, and logs failure classes without leaking token material.
- `test/lockspire/plug/verify_token_test.exs` - Covers route-option validation, audience semantics, scope semantics, and redaction-safe logs with warnings treated as errors.

## Decisions Made

- Reused the `NimbleOptions` pattern already established by `EnforceSenderConstraints` so route-policy intake stays explicit and local to the plug.
- Treated missing, malformed, and mismatched audiences as structured `invalid_token` failures while treating missing scopes as structured `insufficient_scope` failures.
- Kept scope normalization case-sensitive and exact-match, using deduplicated token scope parsing without introducing aliases or OR semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated the targeted test module to remove deprecated `use Plug.Test`**
- **Found during:** Task 1/2 verification
- **Issue:** `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs --warnings-as-errors` surfaced a deprecation warning that would keep the task gate from clearing.
- **Fix:** Switched the test module to `import Plug.Test` and `import Plug.Conn`.
- **Files modified:** `test/lockspire/plug/verify_token_test.exs`
- **Verification:** `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs --warnings-as-errors`
- **Committed in:** `97a6e9b`

**2. [Rule 3 - Execution Protocol] Combined Tasks 1 and 2 into one code commit**
- **Found during:** Plan finalization
- **Issue:** Both tasks crossed the same `VerifyToken` implementation and shared test matrix, so a clean split would have required artificial partial commits against the same hunks.
- **Fix:** Landed the shipped code in one feature commit and recorded the deviation here.
- **Files modified:** `lib/lockspire/plug/verify_token.ex`, `test/lockspire/plug/verify_token_test.exs`, `mix.exs`
- **Verification:** `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs --warnings-as-errors`
- **Committed in:** `97a6e9b`

---

**Total deviations:** 2 auto-fixed (1 blocking verification fix, 1 commit-protocol deviation)
**Impact on plan:** No scope creep. The behavioral surface matches the plan; the only protocol deviation is the merged code commit for intertwined work.

## Issues Encountered

- `KeyCache` logged an initial refresh error before the test repo booted, but the targeted suite completed successfully after setup and did not require code changes in this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `RequireToken` can now consume structured invalid-audience and insufficient-scope errors without reparsing claims.
- The generated-host proof in Plan 02 can wire route options directly onto `VerifyToken` using the now-tested option contract.

---
*Phase: 81-scope-audience-restrictions-milestone-closure*
*Completed: 2026-05-23*
