---
phase: 37-protocol-strictness-conformance
plan: 3
subsystem: auth
tags: [oidc, auth_time, prompt-none, phoenix, ecto]
requires:
  - phase: 37-01
    provides: protocol-owned auth_time claim reservation and strict ID token timestamp handling
  - phase: 37-02
    provides: validated prompt=none, max_age, and auth_time demand parsing
provides:
  - durable interaction auth_time, max_age, and auth_time_requested persistence
  - strict prompt=none redirect-safe login_required, consent_required, and interaction_required outcomes
  - ID token auth_time emission from durable interaction truth with preserved nonce pass-through
affects: [37-04, oidf-conformance, token-exchange]
tech-stack:
  added: []
  patterns:
    - durable interaction metadata as the sole auth_time freshness source
    - protocol-owned silent-auth branching before any Phoenix login or consent redirect
key-files:
  created:
    - priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs
    - test/lockspire/storage/ecto/interaction_record_test.exs
  modified:
    - lib/lockspire/domain/interaction.ex
    - lib/lockspire/storage/ecto/interaction_record.ex
    - lib/lockspire/protocol/authorization_flow.ex
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/web/controllers/authorize_controller.ex
    - test/lockspire/protocol/authorization_flow_test.exs
    - test/lockspire/protocol/token_exchange_test.exs
    - test/lockspire/web/authorize_controller_test.exs
key-decisions:
  - "Durable interaction rows own max_age and auth_time request truth, and only explicit host auth_time input can advance auth_time on login resume."
  - "prompt=none short-circuits to redirect-safe OIDC errors inside AuthorizationFlow before any host login or Lockspire consent UI can execute."
  - "TokenExchange reads nonce and conditional auth_time from the linked interaction, while OpenID device grants still issue ID tokens without requiring an interaction row."
patterns-established:
  - "Persist OIDC request metadata on Interaction and consume it later during token exchange instead of re-deriving from request/session state."
  - "Map silent authorization blockers to standards-shaped redirect errors in protocol code and keep Phoenix adapters tuple-driven."
requirements-completed: [CONF-01, CONF-03]
duration: 10m
completed: 2026-04-29
---

# Phase 37 Plan 3: Durable auth_time truth, silent prompt=none enforcement, and conditional ID token auth_time emission

**Durable interaction auth_time truth with strict prompt=none protocol branching and conditional ID token auth_time emission from persisted OIDC request state**

## Performance

- **Duration:** 10m
- **Started:** 2026-04-29T01:03:07Z
- **Completed:** 2026-04-29T01:12:54Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Added durable `auth_time`, `max_age`, and `auth_time_requested` fields to `Interaction` plus storage round-trip coverage and migration support.
- Enforced strict `prompt=none` outcomes in `AuthorizationFlow` so silent failures return redirect-safe OIDC errors before any login or consent UI path.
- Updated token exchange to emit `auth_time` only when durable interaction state proves it was requested, while preserving existing `nonce` pass-through and device-grant behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Persist durable interaction auth_time metadata** - `af99349`, `7e187e4` (`test`, `feat`)
2. **Task 2: Enforce silent prompt=none outcomes and auth_time-backed ID token emission** - `174cee9` (`feat`)

## Files Created/Modified
- `priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs` - adds durable interaction OIDC freshness columns.
- `lib/lockspire/domain/interaction.ex` and `lib/lockspire/storage/ecto/interaction_record.ex` - carry and round-trip protocol-owned auth_time metadata.
- `lib/lockspire/protocol/authorization_flow.ex` - implements silent-auth branching, durable freshness checks, and explicit fresh-auth resume semantics.
- `lib/lockspire/protocol/token_exchange.ex` - derives `nonce` and conditional `auth_time` from persisted interaction truth.
- `lib/lockspire/web/controllers/authorize_controller.ex` - redirects redirect-safe silent errors without invoking host login orchestration.
- `test/lockspire/protocol/authorization_flow_test.exs`, `test/lockspire/storage/ecto/interaction_record_test.exs`, `test/lockspire/protocol/token_exchange_test.exs`, `test/lockspire/web/authorize_controller_test.exs` - lock the new persistence, silent-auth, and token-claim behavior.

## Decisions Made

- Persisted `max_age` and `auth_time_requested` on every interaction immediately, but only allow `auth_time` to advance when the host explicitly reports a fresh-auth timestamp.
- Treated `prompt=none` as a protocol hard gate that returns `login_required`, `consent_required`, or `interaction_required` from protocol code instead of falling back to controller redirects.
- Kept OpenID device grants compatible by making interaction lookup optional for ID token issuance unless durable interaction state is needed for `auth_time`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The local test database needed the new interaction migration applied via `MIX_ENV=test mix test.setup` before the new storage round-trip test could pass.
- The first silent-auth implementation regressed OpenID device grants by requiring an interaction row for every ID token; the fix made interaction lookup optional unless `auth_time` was required.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 37 now has durable freshness truth and strict silent-auth behavior that the conformance harness in `37-04` can exercise directly.
- The next plan can build OIDF proof lanes on top of deterministic `prompt=none`, `max_age`, `auth_time`, and `nonce` behavior without additional host-seam expansion.

## Self-Check: PASSED
