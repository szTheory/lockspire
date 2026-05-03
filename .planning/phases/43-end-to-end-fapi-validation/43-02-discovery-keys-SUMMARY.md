---
phase: 43-end-to-end-fapi-validation
plan: 02
subsystem: api
tags: [oidc, discovery, fapi, phoenix, elixir]
requires:
  - phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
    provides: truthful algorithm publication and global FAPI policy semantics
provides:
  - discovery metadata for RFC 9207 iss support
  - global-profile-gated require_pushed_authorization_requests publication
  - regression tests proving per-client overrides do not alter server-wide discovery
affects: [fapi, discovery, release-readiness, oidc]
tech-stack:
  added: []
  patterns: [truthful discovery metadata composed in pipeline helpers, TDD for protocol metadata truth]
key-files:
  created: [.planning/phases/43-end-to-end-fapi-validation/43-02-discovery-keys-SUMMARY.md]
  modified: [lib/lockspire/protocol/discovery.ex, test/lockspire/protocol/discovery_test.exs]
key-decisions:
  - "Discovery publishes require_pushed_authorization_requests from the global server policy only, never from per-client overrides."
  - "The new global_security_profile/0 helper is reused for id_token_signing_alg_values_supported/0 to keep discovery truth sourced from one policy read."
patterns-established:
  - "Discovery truth keys append through small private pipeline helpers rather than inline branching in openid_configuration/0."
  - "Per-client FAPI overrides require an explicit negative test to prove server-wide metadata stays unchanged."
requirements-completed: [FAPI-06]
duration: 3min
completed: 2026-05-03
---

# Phase 43 Plan 02: Discovery Keys Summary

**OIDC discovery now advertises RFC 9207 iss-response support and publishes PAR-required metadata only when the global FAPI profile makes that claim true.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-03T12:43:30Z
- **Completed:** 2026-05-03T12:46:31Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `authorization_response_iss_parameter_supported: true` to `openid_configuration/0` unconditionally.
- Added `require_pushed_authorization_requests: true` only when the global `server_policy.security_profile` is `:fapi_2_0_security`.
- Locked the discovery truth with tests for both profile modes, the per-client override edge case, and the D-09 negative claims.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add unconditional iss-parameter discovery key (D-07)** - `92ef692` (test), `9255599` (feat)
2. **Task 2: Add conditional PAR-required discovery key (D-08)** - `f610ef2` (test), `36088c5` (feat)

## Files Created/Modified

- `.planning/phases/43-end-to-end-fapi-validation/43-02-discovery-keys-SUMMARY.md` - execution record for this plan
- `lib/lockspire/protocol/discovery.ex` - truthful discovery metadata helpers and pipeline wiring
- `test/lockspire/protocol/discovery_test.exs` - regression coverage for unconditional iss support, conditional PAR metadata, and per-client override behavior

## Decisions Made

- Used a shared `global_security_profile/0` helper so the PAR-required key and signing-algorithm publication both read the same global policy source.
- Kept `require_pushed_authorization_requests` absent rather than `false` when the global profile is not FAPI, matching the plan’s discovery contract exactly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Adjusted the per-client override fixture to a valid client scope**
- **Found during:** Task 2 (Add conditional PAR-required discovery key)
- **Issue:** The plan example registered a client with `allowed_scopes: ["openid"]`, but `Lockspire.Clients.register_client/1` rejects `openid` on this surface, which blocked the proof test setup.
- **Fix:** Changed the fixture client to use `allowed_scopes: ["profile"]` while keeping the real per-client `security_profile: :fapi_2_0_security` override path intact.
- **Files modified:** `test/lockspire/protocol/discovery_test.exs`
- **Verification:** `mix test test/lockspire/protocol/discovery_test.exs --color`
- **Committed in:** `f610ef2` (part of task commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. The fix only corrected the fixture so the required per-client override proof could execute.

## Issues Encountered

- Interleaved Phase 43 work from other agents modified unrelated files in the same repo during execution. Commits were staged file-by-file to avoid capturing those changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Discovery metadata now tells the truth for the Phase 43 FAPI-06 claims this plan owns.
- Phase 43 E2E and release-truth plans can rely on the new discovery keys and their unit-test proof.

## Self-Check: PASSED
