---
phase: 37-protocol-strictness-conformance
plan: 2
subsystem: auth
tags: [oidc, oauth, authorize, phoenix, testing]
requires:
  - phase: 37-protocol-strictness-conformance
    provides: "Typed auth_time handling in ID token signing from 37-01"
provides:
  - "Strict authorize parsing for prompt=none, max_age, nonce, and auth_time claim demand"
  - "Redirect-safe controller regressions for strict authorize validation failures"
affects: [authorization-flow, id-token, conformance]
tech-stack:
  added: []
  patterns: ["Protocol-owned authorize parsing", "Tuple-driven Phoenix authorize adapter"]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/authorization_request.ex
    - test/lockspire/protocol/authorization_request_test.exs
    - test/lockspire/web/authorize_controller_test.exs
key-decisions:
  - "Treat prompt=none as valid only when it is the sole prompt value, with a stable :prompt_none_conflict rejection for combinations."
  - "Parse max_age and auth_time claim demand centrally in AuthorizationRequest so controller behavior stays tuple-driven."
patterns-established:
  - "Validate max_age as an untrimmed digit-only string before any host handoff."
  - "Allow only claims=id_token.auth_time.essential=true and reject all other claims payloads as invalid_request."
requirements-completed: [CONF-02, CONF-03]
duration: 5min
completed: 2026-04-29
---

# Phase 37 Plan 2: Protocol Strictness Summary

**Strict `/authorize` parsing for `prompt=none`, digit-only `max_age`, and narrow `auth_time` claims while preserving redirect-safe nonce and redirect URI behavior**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-29T00:54:00Z
- **Completed:** 2026-04-29T00:58:48Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Extended `AuthorizationRequest.Validated` with parsed `max_age` and `auth_time_requested?` fields.
- Hardened `/authorize` validation so `prompt=none` is standalone-only, `max_age` rejects malformed input, and `claims` admits only `id_token.auth_time.essential=true`.
- Locked controller-facing regressions proving redirect-safe validation errors preserve trusted callback handling while invalid `redirect_uri` stays browser-safe.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend AuthorizationRequest with strict prompt, max_age, and claims parsing** - `23cad1c` (test), `7794a02` (feat), `5d4e4ad` (test)
2. **Task 2: Keep controller error surfaces deterministic for the new request rules** - `60e7c37` (test)

_Note: Task 2 required no controller code change because the tuple-driven adapter already preserved the correct error surfaces once Task 1 hardened the protocol layer._

## Files Created/Modified
- `lib/lockspire/protocol/authorization_request.ex` - Added strict `prompt=none`, `max_age`, and `claims` parsing plus richer validated request state.
- `test/lockspire/protocol/authorization_request_test.exs` - Added regressions for prompt conflicts, malformed `max_age`, narrow claims support, nonce preservation, and exact redirect URI rejection wording.
- `test/lockspire/web/authorize_controller_test.exs` - Added redirect-surface proof for prompt conflicts, malformed `max_age`, missing nonce, and browser-safe invalid redirect URIs.

## Decisions Made

- Kept all new request parsing inside `AuthorizationRequest` so Phoenix adapters remain thin and driven only by browser-safe vs redirect-safe tuples.
- Rejected whitespace-padded `max_age` values instead of trimming them, preserving the plan's digit-only input contract.
- Left `AuthorizeController` implementation unchanged because the stricter protocol tuples already satisfied the controller-side contract.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The initial Task 2 RED pass showed the controller already honored the new redirect-safe vs browser-safe contract after Task 1. The task outcome stayed test-only instead of forcing an unnecessary controller patch.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `AuthorizationFlow` can now consume deterministic `prompt`, `max_age`, and `auth_time_requested?` fields for silent-auth and freshness decisions.
- Controller regressions are in place to catch any later drift between protocol validation tuples and `/authorize` redirect behavior.

## Threat Flags

None.

## Self-Check: PASSED

- Verified `.planning/phases/37-protocol-strictness-conformance/37-02-SUMMARY.md` exists.
- Verified task commits `23cad1c`, `7794a02`, `60e7c37`, and `5d4e4ad` exist in git history.
