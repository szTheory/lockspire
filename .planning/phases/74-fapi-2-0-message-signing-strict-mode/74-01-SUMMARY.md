---
phase: 74-fapi-2-0-message-signing-strict-mode
plan: 01
subsystem: auth
tags: [fapi, oauth, oidc, security-profile, ecto, tdd]
requires:
  - phase: 73-jwt-introspection-responses
    provides: message-signing baseline needed by the strict tier
provides:
  - durable `:fapi_2_0_message_signing` profile support in domain and Ecto models
  - monotonic resolver semantics for strict message-signing enforcement
affects: [74-02, 74-03, 74-04, 74-05, security_profile]
tech-stack:
  added: []
  patterns: [single security-profile policy plane, monotonic effective-profile resolution]
key-files:
  created: []
  modified:
    - lib/lockspire/domain/server_policy.ex
    - lib/lockspire/domain/client.ex
    - lib/lockspire/storage/ecto/server_policy_record.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/protocol/security_profile.ex
    - test/lockspire/protocol/security_profile_test.exs
    - test/lockspire/storage/ecto/server_policy_record_test.exs
    - test/lockspire/storage/ecto/client_record_test.exs
key-decisions:
  - "Represented strict message signing as a first-class security profile tier instead of introducing a second toggle."
  - "Kept `:none` as an intentional escape hatch even when a stricter global profile is active."
patterns-established:
  - "New profile tiers must be durable end-to-end before any endpoint or UI enforcement is layered on top."
requirements-completed: [ENF-01]
duration: resume verification
completed: 2026-05-08
---

# Phase 74 Plan 01: Strict Profile Tier Summary

**Strict message-signing became a durable security-profile tier across domain, storage, and effective-profile resolution**

## Performance

- **Duration:** Resume verification
- **Started:** 2026-05-08T15:02:07Z
- **Completed:** 2026-05-08T15:02:07Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `:fapi_2_0_message_signing` to the durable server-policy and client profile types.
- Extended Ecto persistence and validation so the new tier round-trips cleanly.
- Updated effective-profile resolution so strict mode still implies baseline FAPI semantics while preserving explicit client opt-out.

## Task Commits

No plan-local commits were created during this resume pass. The implementation was already present as uncommitted work in the shared tree, so this execution pass verified behavior and documented the completed plan state.

## Files Created/Modified

- `lib/lockspire/domain/server_policy.ex` - Added the strict profile to the server policy type.
- `lib/lockspire/domain/client.ex` - Added the strict profile to client overrides.
- `lib/lockspire/storage/ecto/server_policy_record.ex` - Persisted the server strict profile enum value.
- `lib/lockspire/storage/ecto/client_record.ex` - Persisted the client strict profile enum value and signing-alg validation.
- `lib/lockspire/protocol/security_profile.ex` - Added strict-mode resolution semantics and strict-mode boolean truth.
- `test/lockspire/protocol/security_profile_test.exs` - Covered monotonic strict-profile resolution and algorithm gating.
- `test/lockspire/storage/ecto/server_policy_record_test.exs` - Covered strict-tier server-policy persistence.
- `test/lockspire/storage/ecto/client_record_test.exs` - Covered strict-tier client persistence and FAPI signing constraints.

## Decisions Made

- Used one policy plane: strict message signing rides on the existing `security_profile` field rather than creating auxiliary flags.
- Preserved mixed mode: client `:none` still resolves to compatibility mode under stricter global policy.

## Deviations from Plan

None. This resume pass found the plan already implemented in the working tree and focused on verification and documentation.

## Issues Encountered

- The `gsd-sdk query` helpers referenced by the executor workflow were unavailable in this environment, so plan execution was reconstructed directly from `.planning/phases/74-...`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The strict profile tier is now available as canonical input for admin, DCR, `/authorize`, `/introspect`, and LiveView surfaces.
- Plan `74-02` can reuse one profile plane instead of normalizing separate strictness toggles.

## Verification

- Covered by the Phase 74 aggregate verification run:
  `MIX_ENV=test mix test --warnings-as-errors test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/protocol/security_profile_test.exs test/lockspire/protocol/message_signing_profile_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs`

---
*Phase: 74-fapi-2-0-message-signing-strict-mode*
*Completed: 2026-05-08*
