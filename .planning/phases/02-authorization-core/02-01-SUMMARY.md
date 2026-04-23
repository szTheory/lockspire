---
phase: 02-authorization-core
plan: 01
subsystem: auth
tags: [oauth, pkce, phoenix, ecto, telemetry]
requires:
  - phase: 01-foundation-and-host-seam
    provides: mountable router, host seam, Ecto-backed storage contracts
provides:
  - durable client registration API with one-time secret disclosure
  - strict authorization request validator with redirect-safe error branching
  - mountable /authorize controller with first-party browser error handling
affects: [02-02, 02-03, AUTH-01, AUTH-03]
tech-stack:
  added: []
  patterns:
    - protocol validation before host seam or Phoenix consent/login handoff
    - telemetry plus audit emission through a shared observability wrapper
    - client registration through domain API plus bootstrap Mix task
key-files:
  created:
    - lib/lockspire/clients.ex
    - lib/lockspire/clients/registration_result.ex
    - lib/lockspire/observability.ex
    - lib/mix/tasks/lockspire.client.create.ex
    - lib/lockspire/protocol/authorization_request.ex
    - lib/lockspire/web/controllers/authorize_controller.ex
    - lib/lockspire/web/controllers/authorize_html.ex
    - test/lockspire/clients_test.exs
    - test/lockspire/protocol/authorization_request_test.exs
    - test/lockspire/web/authorize_controller_test.exs
  modified:
    - lib/lockspire/config.ex
    - lib/lockspire/web/router.ex
key-decisions:
  - "Client registration stays on the existing Ecto repository contract and returns plaintext secrets only through a typed result struct."
  - "Known OAuth scopes are runtime-configured via :lockspire, :known_scopes so authorize validation can enforce both server-known and client-allowed scope policy."
  - "The Phase 2 /authorize success branch returns a validated handoff contract as JSON until 02-02 and 02-03 add interaction orchestration."
patterns-established:
  - "Validate-first authorize flow: load client, exact-match redirect URI, then decide browser-vs-redirect error surfaces."
  - "Redaction-first observability: emit structured telemetry and audit metadata without secrets, hashes, or PKCE material."
requirements-completed: [AUTH-01, AUTH-03]
duration: 7min
completed: 2026-04-23
---

# Phase 2 Plan 1: Authorization Core Summary

**Durable OAuth client registration, PKCE-only authorize validation, and a mountable `/authorize` endpoint with safe browser-vs-redirect error behavior**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-23T01:20:00Z
- **Completed:** 2026-04-23T01:27:04Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments
- Added `Lockspire.Clients.register_client/1` with confidential/public client validation, one-time secret disclosure, and a canonical `mix lockspire.client.create` bootstrap surface.
- Added `Lockspire.Protocol.AuthorizationRequest` to enforce exact redirect matching, `response_type=code`, PKCE S256, known-and-allowed scopes, and prompt policy before any host seam handoff.
- Mounted `GET /authorize` through a thin Phoenix controller that renders first-party HTML for unsafe failures and redirects only when the redirect URI is already validated.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the durable client registration API and bootstrap path** - `0443c1b` (feat)
2. **Task 2: Implement strict authorization-request validation as protocol-core logic** - `8e0bd1d` (feat)
3. **Task 3: Wire `/authorize` as a thin controller with protocol-safe error handling** - `e74e963` (feat)

**Plan metadata:** created after summary/state updates

## Files Created/Modified
- `lib/lockspire/clients.ex` - Phase 2 client registration API with secure defaults and persistence through the repository contract.
- `lib/lockspire/clients/registration_result.ex` - Typed one-time registration result carrying the persisted client and plaintext secret.
- `lib/lockspire/observability.ex` - Shared audit and telemetry emitter with redaction of secrets and PKCE fields.
- `lib/mix/tasks/lockspire.client.create.ex` - Operator bootstrap CLI for durable client creation.
- `lib/lockspire/protocol/authorization_request.ex` - Pure authorize validator returning typed success, browser-error, and redirect-error outcomes.
- `lib/lockspire/web/controllers/authorize_controller.ex` - Thin `/authorize` delivery adapter around the protocol validator.
- `lib/lockspire/web/controllers/authorize_html.ex` - First-party HTML error page for unsafe authorize failures.
- `lib/lockspire/config.ex` - Runtime helper for server-known scope configuration.
- `lib/lockspire/web/router.ex` - Mounted `GET /authorize`.
- `test/lockspire/clients_test.exs` - Coverage for secure client registration, secret handling, and CLI bootstrap behavior.
- `test/lockspire/protocol/authorization_request_test.exs` - Coverage for valid authorize requests and unsafe rejection paths.
- `test/lockspire/web/authorize_controller_test.exs` - Coverage for first-party browser errors, redirect-safe OAuth errors, and validated handoff responses.

## Decisions Made
- Used a typed `RegistrationResult` return shape so confidential client secrets are exposed exactly once without polluting durable domain structs.
- Kept authorize validation inside protocol-core and limited the controller to branching on typed outcomes, preserving the Phase 2 boundary from web-layer drift.
- Added runtime-configured known scopes so authorize validation can reject unknown scopes without silently downgrading requests.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `Config.repo!/0` resolves the raw Ecto repo, so the new client registration service was corrected to persist through `Lockspire.Storage.Ecto.Repository`, which is the actual storage-contract boundary.
- Phoenix controller tests needed `Phoenix.ConnTest.build_conn/3` instead of raw `Plug.Test.conn/2` so query params reached the controller under the Phoenix router.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `02-02` can now consume the validated authorize-request contract without re-implementing redirect, PKCE, scope, or prompt validation.
- `02-03` can replace the temporary validated JSON success response with interaction/login/consent orchestration while keeping the safe error surfaces intact.

## Self-Check: PASSED

- Verified `.planning/phases/02-authorization-core/02-01-SUMMARY.md` exists.
- Verified the core created files exist: `lib/lockspire/clients.ex`, `lib/lockspire/protocol/authorization_request.ex`, and `lib/lockspire/web/controllers/authorize_controller.ex`.
- Verified task commits `0443c1b`, `8e0bd1d`, and `e74e963` exist in git history.

---
*Phase: 02-authorization-core*
*Completed: 2026-04-23*
