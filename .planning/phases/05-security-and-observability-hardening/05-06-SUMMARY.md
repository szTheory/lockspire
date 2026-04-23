---
phase: 05-security-and-observability-hardening
plan: 06
subsystem: ui
tags: [liveview, redaction, admin, oauth, oidc]
requires:
  - phase: 05-05
    provides: shared redaction handles and audit-safe masking helpers
  - phase: 04-02
    provides: confirmation-gated token and key operator workflows
provides:
  - masked token detail projections for operator support flows
  - masked signing-key detail projections for operator support flows
  - LiveView confirmation-gate regressions for masked admin detail pages
affects: [admin, tokens, keys, redaction, operator-workflows]
tech-stack:
  added: []
  patterns: [redaction-backed admin detail projections, calm confirmation-gate reset behavior]
key-files:
  created: []
  modified:
    - lib/lockspire/admin/tokens.ex
    - lib/lockspire/admin/keys.ex
    - lib/lockspire/web/live/admin/tokens_live/show.ex
    - lib/lockspire/web/live/admin/keys_live/show.ex
    - test/lockspire/web/live/admin/tokens_live_test.exs
    - test/lockspire/web/live/admin/keys_live_test.exs
key-decisions:
  - "Token detail pages now render client names plus redaction-backed handles instead of raw client, account, family, or parent identifiers."
  - "Key detail pages now render masked key and database handles while keeping lifecycle actions driven by canonical ids held outside the rendered projection."
patterns-established:
  - "Admin detail projections should translate durable structs into masked maps before LiveView rendering."
  - "Confirmation-gated LiveViews should clear stale success notices when an operator submits an unconfirmed follow-up action."
requirements-completed: [SECU-03]
duration: 5min
completed: 2026-04-23
---

# Phase 05 Plan 06: Security and Observability Hardening Summary

**Masked token and signing-key admin detail pages backed by shared redaction handles and calm confirmation-gated LiveView flows**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-23T17:20:00Z
- **Completed:** 2026-04-23T17:24:55Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Replaced raw token detail identifiers with redaction-backed handles and client-friendly display fields.
- Replaced raw key detail identifiers with masked key and database handles while preserving lifecycle metadata and public-JWK shape.
- Hardened confirmation-gated LiveView flows so unconfirmed follow-up actions clear stale success notices instead of leaving misleading state behind.

## Task Commits

Each task was committed atomically:

1. **Task 1: Project masked token and key detail models through the shared redaction seam** - `39d6bef` (feat)
2. **Task 2: Render the masked operator detail surfaces without weakening confirmation gates** - `0667cf3` (fix)

TDD red gate:

1. **Shared failing assertions for masked admin detail** - `0f62add` (test)

## Files Created/Modified
- `lib/lockspire/admin/tokens.ex` - Projects token detail and family lineage into masked operator-facing maps.
- `lib/lockspire/admin/keys.ex` - Projects key detail into masked operator-facing maps with masked public metadata.
- `lib/lockspire/web/live/admin/tokens_live/show.ex` - Renders masked token detail and clears stale notices on failed confirmation attempts.
- `lib/lockspire/web/live/admin/keys_live/show.ex` - Renders masked key detail and clears stale notices on failed confirmation attempts.
- `test/lockspire/web/live/admin/tokens_live_test.exs` - Covers masked token detail rendering and confirmation-gate reset behavior.
- `test/lockspire/web/live/admin/keys_live_test.exs` - Covers masked key detail rendering and confirmation-gate reset behavior.

## Decisions Made

- Used `Lockspire.Redaction.handle/2` directly in the admin projection layer so LiveViews remain thin adapters over already-masked data.
- Kept canonical ids out of rendered token/key detail payloads and continued using existing socket assigns for command targeting.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Cleared stale success notices after unconfirmed follow-up actions**
- **Found during:** Task 2 (Render the masked operator detail surfaces without weakening confirmation gates)
- **Issue:** Token and key detail LiveViews kept prior success notices visible after a later action failed confirmation, which made the operator workflow less exact.
- **Fix:** Cleared the stale notice fields in the confirmation-guard branches and added regression coverage.
- **Files modified:** `lib/lockspire/web/live/admin/tokens_live/show.ex`, `lib/lockspire/web/live/admin/keys_live/show.ex`, `test/lockspire/web/live/admin/tokens_live_test.exs`, `test/lockspire/web/live/admin/keys_live_test.exs`
- **Verification:** `PGUSER=jon mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs`
- **Committed in:** `0667cf3`

**2. [Rule 3 - Blocking] Switched verification commands to the local PostgreSQL role**
- **Found during:** Task 1 (Project masked token and key detail models through the shared redaction seam)
- **Issue:** The test repo defaulted to PostgreSQL role `postgres`, but this environment only exposes local roles `jon` and `squadup_2_0`.
- **Fix:** Bootstrapped and ran plan verification with `PGUSER=jon` so execution could continue without changing project config.
- **Files modified:** None
- **Verification:** `PGUSER=jon mix lockspire.test.setup` and `PGUSER=jon mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs`
- **Committed in:** none (environment-only execution adjustment)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both changes stayed inside the plan boundary. One corrected LiveView workflow state; the other unblocked local verification without changing repository code.

## Issues Encountered

- Local PostgreSQL auth used a different role than the repo default. Verification succeeded after switching to `PGUSER=jon`.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Threat Flags

None.

## Next Phase Readiness

- Token and key operator detail pages now consume masked projections and preserve the Phase 4 confirmation workflow shape.
- The next hardening plans can build on these admin projections without inventing new per-screen masking rules.

## Self-Check: PASSED

- Verified files exist: `lib/lockspire/admin/tokens.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/web/live/admin/tokens_live/show.ex`, `lib/lockspire/web/live/admin/keys_live/show.ex`, `test/lockspire/web/live/admin/tokens_live_test.exs`, `test/lockspire/web/live/admin/keys_live_test.exs`
- Verified commits exist: `0f62add`, `39d6bef`, `0667cf3`

---
*Phase: 05-security-and-observability-hardening*
*Completed: 2026-04-23*
