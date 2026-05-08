---
phase: 74-fapi-2-0-message-signing-strict-mode
plan: 05
subsystem: ui
tags: [fapi, liveview, admin, integration, docs, release]
requires:
  - phase: 74-fapi-2-0-message-signing-strict-mode
    provides: strict authorize and introspection enforcement with canonical readiness truth
provides:
  - operator-facing strict posture and readiness signals in admin LiveViews
  - end-to-end proof for strict global mode, strict per-client mode, and mixed-mode opt-out
  - support-surface wording pinned to the shipped strict message-signing slice
affects: [release_readiness, supported_surface, admin_liveview]
tech-stack:
  added: []
  patterns: [canonical readiness surfaced in UI, support-contract tests for shipped claims]
key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/policies_live/security_profile.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
    - test/integration/phase41_fapi_2_0_e2e_test.exs
    - docs/supported-surface.md
    - test/lockspire/release_readiness_contract_test.exs
key-decisions:
  - "Rendered canonical readiness and remediation directly in the admin surfaces instead of inventing separate UI-only truth."
  - "Pinned support wording to optional baseline capability plus explicit strict-tier enforcement, without overclaiming broader FAPI posture."
patterns-established:
  - "Public support claims are backed by release-readiness contract tests alongside end-to-end runtime proof."
requirements-completed: [ENF-01]
duration: resume verification
completed: 2026-05-08
---

# Phase 74 Plan 05: Operator Visibility and Contract Summary

**Operators can now see strict message-signing posture and readiness in LiveView, while end-to-end tests and release docs pin the shipped support contract**

## Performance

- **Duration:** Resume verification
- **Started:** 2026-05-08T15:02:07Z
- **Completed:** 2026-05-08T15:02:07Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added strict posture, readiness, remediation, and mixed-mode escape-hatch messaging to the admin policy and client LiveViews.
- Extended the Phase 41 integration suite to prove strict global mode, strict per-client mode, and compatibility-preserving client `:none` overrides across `/authorize` and `/introspect`.
- Updated `docs/supported-surface.md` and release-readiness tests so the public contract distinguishes optional baseline JARM/RFC 9701 support from the stricter message-signing tier.

## Task Commits

No plan-local commits were created during this resume pass. The implementation was already present as uncommitted work in the shared tree, so this execution pass verified behavior and documented the completed plan state.

## Files Created/Modified

- `lib/lockspire/web/live/admin/policies_live/security_profile.ex` - Global strict-tier selector, readiness panel, and remediation copy.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - Client-facing strict posture, readiness, and mixed-mode warning panel.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - Strict-tier option and readiness context inside client edit flows.
- `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` - Global readiness UI coverage.
- `test/lockspire/web/live/admin/clients_live/show_test.exs` - Client strict posture, readiness, and mixed-mode coverage.
- `test/integration/phase41_fapi_2_0_e2e_test.exs` - End-to-end strict global, strict per-client, and mixed-mode behavior.
- `docs/supported-surface.md` - Narrow public support wording for strict message signing.
- `test/lockspire/release_readiness_contract_test.exs` - Contract tests that reject support-surface overclaims.

## Decisions Made

- Surfaced calm, explicit operator truth: readiness panels explain what strict mode requires and what to fix when prerequisites are missing.
- Kept the support contract narrow: strict mode requires JARM and JWT introspection negotiation, but still does not claim mandatory JARM encryption or a broader FAPI certification scope.

## Deviations from Plan

None. This resume pass found the plan already implemented in the working tree and focused on verification and documentation.

## Issues Encountered

- Full non-integration testing remains warning-blocked in unrelated test files, so release-wide `--warnings-as-errors` exits are still pending despite Phase 74’s own suites passing.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The milestone now has operator-facing strictness visibility, end-to-end proof, and release-pinned support wording for the shipped strict slice.
- Remaining work is outside Phase 74 scope: either close the milestone or remove unrelated warning debt to restore globally clean `--warnings-as-errors` exits.

## Verification

- Covered by the Phase 74 aggregate verification run:
  `MIX_ENV=test mix test --warnings-as-errors test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/protocol/security_profile_test.exs test/lockspire/protocol/message_signing_profile_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs`

---
*Phase: 74-fapi-2-0-message-signing-strict-mode*
*Completed: 2026-05-08*
