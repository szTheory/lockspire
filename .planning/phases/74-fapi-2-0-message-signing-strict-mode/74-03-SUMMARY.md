---
phase: 74-fapi-2-0-message-signing-strict-mode
plan: 03
subsystem: auth
tags: [fapi, oauth, oidc, jarm, par, authorize]
requires:
  - phase: 74-fapi-2-0-message-signing-strict-mode
    provides: canonical strict-profile and readiness semantics
provides:
  - strict JARM response-mode enforcement for direct and PAR-backed `/authorize` requests
  - persisted PAR `response_mode` truth for later authorization validation
affects: [74-05, authorization_request, par]
tech-stack:
  added: []
  patterns: [protocol-owned strict enforcement, fail-closed JARM validation]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/authorization_request.ex
    - lib/lockspire/domain/pushed_authorization_request.ex
    - lib/lockspire/storage/ecto/pushed_authorization_request_record.ex
    - lib/lockspire/storage/ecto/repository.ex
    - priv/repo/migrations/20260508105000_add_response_mode_to_pushed_authorization_requests.exs
    - test/lockspire/protocol/authorization_request_test.exs
    - test/lockspire/protocol/pushed_authorization_request_test.exs
key-decisions:
  - "Placed strict JARM enforcement in `AuthorizationRequest` instead of host-facing plugs."
  - "Stored PAR `response_mode` explicitly so consumed request URIs preserve the same strictness truth as direct requests."
patterns-established:
  - "Strict message-signing checks happen after effective-profile resolution and response-mode parsing, not as silent upgrades."
requirements-completed: [ENF-01]
duration: resume verification
completed: 2026-05-08
---

# Phase 74 Plan 03: Authorization Strictness Summary

**Strict message signing now rejects non-JARM authorization requests for both direct and PAR-backed `/authorize` flows**

## Performance

- **Duration:** Resume verification
- **Started:** 2026-05-08T15:02:07Z
- **Completed:** 2026-05-08T15:02:07Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added explicit JWT response-mode enforcement when the effective profile resolves to `:fapi_2_0_message_signing`.
- Preserved accepted `jwt`, `query.jwt`, `fragment.jwt`, and `form_post.jwt` paths while rejecting omitted and raw response modes.
- Persisted `response_mode` on pushed authorization requests so consumed PAR requests uphold the same strictness gate.

## Task Commits

No plan-local commits were created during this resume pass. The implementation was already present as uncommitted work in the shared tree, so this execution pass verified behavior and documented the completed plan state.

## Files Created/Modified

- `lib/lockspire/protocol/authorization_request.ex` - Strict JARM response-mode gate and persisted PAR response-mode handling.
- `lib/lockspire/domain/pushed_authorization_request.ex` - PAR domain support for `response_mode`.
- `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex` - PAR persistence for `response_mode`.
- `lib/lockspire/storage/ecto/repository.ex` - Repository plumbing for persisted PAR response-mode storage.
- `priv/repo/migrations/20260508105000_add_response_mode_to_pushed_authorization_requests.exs` - Schema support for persisted response modes on PAR records.
- `test/lockspire/protocol/authorization_request_test.exs` - Direct and PAR-backed strict JARM enforcement coverage.
- `test/lockspire/protocol/pushed_authorization_request_test.exs` - PAR record persistence coverage.

## Decisions Made

- Fail closed: strict mode rejects invalid response modes explicitly instead of coercing them into JWT variants.
- Encryption remains optional: strict mode requires JARM, not JWE, while still preserving encrypted-JARM selections where already configured.

## Deviations from Plan

None. This resume pass found the plan already implemented in the working tree and focused on verification and documentation.

## Issues Encountered

- The phase relied on a new migration and PAR storage shape that were already present but uncommitted in the worktree, so the resume pass verified persistence behavior rather than introducing new schema changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Strict `/authorize` behavior is now proven at the protocol seam for both direct and PAR-backed requests.
- Phase `74-05` can rely on end-to-end tests to prove strict and mixed-mode authorization behavior without inventing new enforcement branches.

## Verification

- Covered by the Phase 74 aggregate verification run:
  `MIX_ENV=test mix test --warnings-as-errors test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/protocol/security_profile_test.exs test/lockspire/protocol/message_signing_profile_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs`

---
*Phase: 74-fapi-2-0-message-signing-strict-mode*
*Completed: 2026-05-08*
