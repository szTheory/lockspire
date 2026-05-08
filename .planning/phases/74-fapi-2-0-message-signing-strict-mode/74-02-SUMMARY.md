---
phase: 74-fapi-2-0-message-signing-strict-mode
plan: 02
subsystem: auth
tags: [fapi, oauth, oidc, dcr, admin, readiness]
requires:
  - phase: 74-fapi-2-0-message-signing-strict-mode
    provides: durable strict-profile tier and resolver semantics
provides:
  - canonical message-signing readiness/remediation helper
  - shared strict-tier normalization and gating across admin, DCR, and RFC 7592
affects: [74-03, 74-04, 74-05, registration, admin]
tech-stack:
  added: []
  patterns: [shared readiness helper, repo-owned signing posture truth, unified profile normalization]
key-files:
  created:
    - lib/lockspire/protocol/message_signing_profile.ex
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/admin/server_policy.ex
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/protocol/registration_management.ex
key-decisions:
  - "Centralized strict-tier readiness in `Lockspire.Protocol.MessageSigningProfile` so every write path shares the same truth."
  - "Kept repo-owned signing posture as the source of readiness instead of duplicating key checks in admin or controller layers."
patterns-established:
  - "Strict-tier writes must validate through a reusable readiness/remediation helper before mutating state."
requirements-completed: [ENF-01]
duration: resume verification
completed: 2026-05-08
---

# Phase 74 Plan 02: Canonical Readiness Summary

**Admin and registration paths now share one canonical readiness contract before strict message-signing can be enabled**

## Performance

- **Duration:** Resume verification
- **Started:** 2026-05-08T15:02:07Z
- **Completed:** 2026-05-08T15:02:07Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added `Lockspire.Protocol.MessageSigningProfile` to report readiness, prerequisite reasons, and remediation text for strict mode.
- Routed admin server-policy writes, admin client writes, DCR intake, and RFC 7592 updates through the same readiness validation path.
- Normalized `fapi_2_0_message_signing` consistently across operator and self-service profile-setting surfaces.

## Task Commits

No plan-local commits were created during this resume pass. The implementation was already present as uncommitted work in the shared tree, so this execution pass verified behavior and documented the completed plan state.

## Files Created/Modified

- `lib/lockspire/protocol/message_signing_profile.ex` - Canonical readiness and remediation helper for the strict tier.
- `lib/lockspire/storage/ecto/repository.ex` - Repo-owned validation for strict signing readiness.
- `lib/lockspire/admin/server_policy.ex` - Global profile writes now gate on canonical readiness.
- `lib/lockspire/admin/clients.ex` - Client overrides now normalize and validate strict mode through the shared helper.
- `lib/lockspire/protocol/registration.ex` - DCR intake validates strict-profile transitions through the canonical readiness path.
- `lib/lockspire/protocol/registration_management.ex` - RFC 7592 updates reuse the same readiness contract.
- `test/lockspire/protocol/message_signing_profile_test.exs` - Readiness and remediation contract coverage.
- `test/lockspire/admin/server_policy_test.exs` - Global strict profile gating coverage.
- `test/lockspire/admin/clients_test.exs` - Per-client strict profile gating coverage.
- `test/lockspire/protocol/registration_test.exs` - DCR normalization and readiness coverage.
- `test/lockspire/protocol/registration_management_test.exs` - RFC 7592 normalization and readiness coverage.

## Decisions Made

- Canonical remediation text lives with the readiness helper so admin surfaces can reuse it verbatim.
- Effective-profile transitions are validated with the current client context where applicable, preserving mixed-mode behavior without introducing separate exception logic.

## Deviations from Plan

None. This resume pass found the plan already implemented in the working tree and focused on verification and documentation.

## Issues Encountered

- The repository state already contained broad uncommitted changes across Phase 74 files, so this pass treated execution as a resume/verify flow instead of producing fresh atomic commits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `/authorize` and `/introspect` enforcement can now ask one helper whether strict mode is both selected and ready.
- Operator LiveViews can render canonical remediation text instead of duplicating repository-key posture logic.

## Verification

- Covered by the Phase 74 aggregate verification run:
  `MIX_ENV=test mix test --warnings-as-errors test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/protocol/security_profile_test.exs test/lockspire/protocol/message_signing_profile_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs`

---
*Phase: 74-fapi-2-0-message-signing-strict-mode*
*Completed: 2026-05-08*
