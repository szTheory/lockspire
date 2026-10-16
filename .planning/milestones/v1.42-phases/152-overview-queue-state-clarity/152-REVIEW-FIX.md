---
phase: 152-overview-queue-state-clarity
fixed_at: 2026-10-15T00:00:00Z
review_path: .planning/phases/152-overview-queue-state-clarity/152-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 152: Code Review Fix Report

**Fixed at:** 2026-10-15
**Source review:** .planning/phases/152-overview-queue-state-clarity/152-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

## Fixed Issues

### WR-01: Filter step runs outside the rescue in `handle_params` (interactions and device pages)

**Files modified:** `lib/lockspire/web/live/admin/interactions_live/index.ex`, `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`
**Commit:** ce2a8bb0
**Applied fix:** `load_interactions/1` and `load_device_authorizations/1` take the filter and apply it inside the guarded read, so a malformed row produces `{:unavailable, []}`. The waiting predicate also matches only `%DateTime{}` expiries.

### WR-02: Summary "Pending" and "Waiting" counts include expired requests, while the pending filter and overview exclude them

**Files modified:** `interactions_live/index.ex`, `device_authorizations_live/index.ex`, `test/lockspire/web/live/admin/overview_live_test.exs`
**Commit:** ce2a8bb0
**Applied fix:** A shared `waiting?/2` predicate drives the pending filter and the "Waiting for sign-in", "Waiting for consent" and "Pending" stats. Regression assertions in "expired pending records stay in inventories but not the waiting overview or pivots" check that the stats match the overview count.

### WR-03: Logout deliveries `load_deliveries` relies on CaseClauseError being rescued

**Files modified:** `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex`
**Commit:** ce2a8bb0
**Applied fix:** Added `_other -> {:unavailable, []}`; the rescue stays.

### IN-01: Device "App may check again" shows "Not recorded" when nothing is recorded

**Files modified:** `device_authorizations_live/index.ex`, `test/lockspire/web/live/admin/device_authorizations_live_test.exs`
**Commit:** ce2a8bb0
**Applied fix:** `next_poll_context/1` returns nil when `next_poll_allowed_at` is nil. New test "device rows omit the next-check line when no next check is recorded".

### IN-02: Inconsistent copy and duplicated helpers across the pages

**Files modified:** `logout_deliveries_live/index.ex`, `overview_live/index.ex`, `device_authorizations_live/index.ex`, `PRODUCT.md`, tests
**Commit:** ce2a8bb0
**Applied fix:** Singular copy says "1 app sign-out notice recorded" and "1 app sign-out notice needs review". The overview's failure note says "app sign-out notices". "logout delivery" is added to the retired-wording table, and the device page has the empty Client ID guard. The duplicated helpers were not extracted into a shared module; that is a refactor left for later.

### IN-03: Inconsistent path construction

**Files modified:** `interactions_live/index.ex`, `logout_deliveries_live/index.ex`
**Commit:** ce2a8bb0
**Applied fix:** Overview links use a local `admin_path/1`, matching the overview and device pages.

---

_Fixed: 2026-10-15_
_Fixer: Claude (orchestrator, inline)_
_Iteration: 1_
