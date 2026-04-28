---
phase: "31"
plan: "04"
subsystem: "auth"
tags: ["device-authorization", "device-flow", "oauth", "phoenix", "tdd"]
requires:
  - phase: "31"
    provides: "Durable verification handles, lifecycle state, and row-locked repository transitions from plan 31-01"
provides:
  - "Typed device-verification lookup and approve/deny protocol APIs for host-owned /verify flows"
  - "verification_uri_complete in device authorization success responses"
  - "Executable protocol and controller proof for prefill-only verification response fields"
affects:
  - "Phase 31 generated verification controller seam"
  - "Phase 32 device polling and token issuance"
tech-stack:
  added: []
  patterns: ["two-step verification API", "opaque-handle mutation", "TDD"]
key-files:
  created:
    - "lib/lockspire/protocol/device_verification.ex"
    - "test/lockspire/protocol/device_verification_test.exs"
    - ".planning/phases/31-host-owned-verification-ui-seam/31-04-SUMMARY.md"
  modified:
    - "lib/lockspire/protocol/device_authorization.ex"
    - "test/lockspire/protocol/device_authorization_test.exs"
    - "test/lockspire/web/controllers/device_authorization_controller_test.exs"
key-decisions:
  - "Verification lookup canonicalizes user_code with the same strip-separators-and-uppercase rule used at issuance time."
  - "Approval and denial require actor context with subject_id and mutate only through verification handles."
  - "verification_uri_complete is derived centrally in the protocol response, not in controllers."
patterns-established:
  - "Host verification seams should lookup by normalized code, then approve or deny by opaque handle."
  - "Device authorization response assembly must preserve issued raw codes even when durable storage only keeps hashes."
requirements-completed: ["DEV-04"]
duration: 32min
completed: 2026-04-28
---

# Phase 31 Plan 04: Host-Owned Verification UI Seam Summary

**Typed device-verification lookup/mutation APIs and prefill-safe `verification_uri_complete` responses for the host-owned `/verify` seam**

## Performance

- **Duration:** 32 min
- **Started:** 2026-04-28T09:15:00Z
- **Completed:** 2026-04-28T09:47:21Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `Lockspire.Protocol.DeviceVerification` with canonical user-code lookup, typed pending/expired/not-active classification, and actor-bound approve/deny mutations.
- Added Wave 0 protocol coverage for formatted-vs-unformatted lookups, client-name fallback, subject binding, and stale mutation outcomes.
- Updated device authorization success responses to include `verification_uri_complete` and preserved raw issued codes for the HTTP response contract.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing device verification protocol tests** - `524264e` (`test`)
2. **Task 1 GREEN: Add the device verification protocol API** - `211c385` (`feat`)
3. **Task 2 RED: Add failing verification_uri_complete assertions** - `5917d49` (`test`)
4. **Task 2 GREEN: Emit verification_uri_complete and preserve response codes** - `1deed15` (`feat`)

## Files Created/Modified

- `lib/lockspire/protocol/device_verification.ex` - New narrow protocol API for lookup, approve, and deny operations against opaque verification handles.
- `lib/lockspire/protocol/device_authorization.ex` - Builds `verification_uri_complete` and preserves issued `device_code` and `user_code` in the success payload after persistence.
- `test/lockspire/protocol/device_verification_test.exs` - Covers normalization, typed lookup outcomes, actor validation, and stale approve/deny behavior.
- `test/lockspire/protocol/device_authorization_test.exs` - Proves the protocol success struct emits `verification_uri_complete`.
- `test/lockspire/web/controllers/device_authorization_controller_test.exs` - Proves the JSON response includes `verification_uri_complete` as a prefill-only field.

## Decisions Made

- Used `Lockspire.Domain.DeviceAuthorization.canonicalize_user_code/1` and `hash_user_code/1` as the only lookup normalization path so issued and entered codes share one durable lookup key.
- Kept approval and denial thin over `transition_device_authorization/3` so storage remains the single owner of expected-state race handling.
- Derived `verification_uri_complete` by appending a `user_code` query parameter to the configured verification URI, preserving any existing query string.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved issued device/user codes in repo-backed success responses**
- **Found during:** Task 2 (Emit verification_uri_complete and prove the response contract)
- **Issue:** The repository-backed device authorization path returned `nil` for `device_code` and `user_code`, which made the HTTP response incomplete and blocked truthful `verification_uri_complete` output.
- **Fix:** Merged the issued raw codes back into the stored domain struct when building the success response and then derived `verification_uri_complete` from that preserved `user_code`.
- **Files modified:** `lib/lockspire/protocol/device_authorization.ex`
- **Verification:** `MIX_ENV=test mix test test/lockspire/protocol/device_authorization_test.exs test/lockspire/web/controllers/device_authorization_controller_test.exs`
- **Committed in:** `1deed15`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix was required for the planned response contract to work. No scope creep.

## Issues Encountered

- The initial RED double for verification lookup used placeholder hash labels instead of the real canonicalized SHA256 values. The tests were corrected to use `DeviceAuthorization.hash_user_code/1`, which aligned the fake store with the actual lookup contract.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The host-owned verification controller seam can now consume a narrow lookup API and mutate only through opaque verification handles.
- Phase 32 can build token-polling behavior on top of the same durable device-authorization lifecycle state.

## Self-Check: PASSED

- `.planning/phases/31-host-owned-verification-ui-seam/31-04-SUMMARY.md` FOUND
- `524264e` FOUND
- `211c385` FOUND
- `5917d49` FOUND
- `1deed15` FOUND

---
*Phase: 31-host-owned-verification-ui-seam*
*Completed: 2026-04-28*
