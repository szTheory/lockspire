---
phase: 152-overview-queue-state-clarity
reviewed: 2026-10-15T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - lib/lockspire/web/live/admin/device_authorizations_live/index.ex
  - lib/lockspire/web/live/admin/interactions_live/index.ex
  - lib/lockspire/web/live/admin/logout_deliveries_live/index.ex
  - lib/lockspire/web/live/admin/overview_live/index.ex
  - test/lockspire/web/live/admin/device_authorizations_live_test.exs
  - test/lockspire/web/live/admin/interactions_live_test.exs
  - test/lockspire/web/live/admin/logout_deliveries_live_test.exs
  - test/lockspire/web/live/admin/overview_live_test.exs
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 152: Code Review Report

**Reviewed:** 2026-10-15
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

The four admin LiveViews were reviewed in full. The test files were checked only by grep and size, not read line by line. No security issues were found. Logging stays redacted, client ids are URI-encoded in links, and the status copy avoids implying that a user was signed out. The overview counts match the filtered list pages they link to: the interactions, device and logouts filters use the same predicates as the overview. The findings below are robustness and consistency issues.

## Warnings

### WR-01: Filter step runs outside the rescue in `handle_params` (interactions and device pages)

**File:** `lib/lockspire/web/live/admin/interactions_live/index.ex:26-27` (also `device_authorizations_live/index.ex:26-27`)
**Issue:** `load_interactions/0` and `load_device_authorizations/0` rescue errors, but `filter_interactions/2` and `filter_device_authorizations/2` run afterwards, unprotected. They call `DateTime.compare(&1.expires_at, now)`. If any row has a nil or non-DateTime `expires_at`, or the reader returns malformed rows, the LiveView process crashes on `?status=pending`. The overview page wraps the same calculation in `observe_list` and degrades to "Unavailable". The migrations make `expires_at` NOT NULL, so this is a defense-in-depth gap, not a reproduced crash. It does make the pages behave differently from the overview.
**Fix:** Move filtering inside the guarded load, for example `load_*` takes the filter and returns `{:loaded, filtered_and_all}`, or wrap the filter in the same `rescue` and return `{:unavailable, []}`.

### WR-02: Summary "Pending" and "Waiting" counts include expired requests, while the pending filter and overview exclude them

**File:** `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:58`, `lib/lockspire/web/live/admin/interactions_live/index.ex:59-65`
**Issue:** `count_status(..., :pending)` and `count_status(..., :pending_login/:pending_consent)` in the "all" view count rows by raw status. The overview, the `?status=pending` filter and the pending list title treat a row as waiting only if `expires_at > now`. A row whose time has passed but whose status has not yet been swept to `:expired` therefore appears as "Pending 3" in the stats. The same page's "Waiting" filter shows 2, and the overview shows 2. This is the kind of queue-state ambiguity the phase is meant to remove.
**Fix:** Count only unexpired rows in those stats, using the same predicate as the filter. Extract a shared `waiting?/2` helper and use it for the stat, the filter and the overview.

### WR-03: Logout deliveries `load_deliveries` relies on CaseClauseError being rescued

**File:** `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:154-160`
**Issue:** The `case` has no fallback clause, unlike the other pages. An `{:error, _}` return raises `CaseClauseError`, which the blanket `rescue` converts to `:unavailable`. The result is correct, but it is accidental. It hides real error tuples and swallows genuine exceptions without logging, and the sibling modules handle this explicitly.
**Fix:** Add `_other -> {:unavailable, []}` and keep the `rescue`. Consider logging the rescued exception, since all four modules discard it silently.

## Info

### IN-01: Device "App may check again" shows "Not recorded" when nothing is recorded

**File:** `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:139, 274-279`
**Issue:** `next_poll_context/1` returns `formatted_timestamp(nil)`, which is the string `"Not recorded"`. That is truthy, so the `:if={next_poll_context(auth)}` guard never hides the row for pending or approved requests.
**Fix:** Return `nil` when `next_poll_allowed_at` is nil.

### IN-02: Inconsistent copy and duplicated helpers across the pages

**File:** `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:171, 179`
**Issue:** The singular count strings say "1 logout delivery recorded" and "1 logout delivery needs review". The plural forms use "app sign-out notices". PRODUCT.md retires wording, and the vocabulary contract test may not cover the singular forms. The helpers `safe_identifier`, `formatted_timestamp`, `client_detail_path_available?`, `client_detail_path` and `admin_path` are also copied across the pages, with slightly different guards: the device page lacks the `byte_size > 0` check that the other two have.
**Fix:** Change the singulars to "1 app sign-out notice ...". Extract the shared helpers into one admin-path/format module, and add the empty-string guard to the device page.

### IN-03: Inconsistent path construction

**File:** `lib/lockspire/web/live/admin/interactions_live/index.ex:93, 112`, `logout_deliveries_live/index.ex:88, 107`
**Issue:** These build `Lockspire.mount_path() <> "/admin/overview"` inline, while the overview and device pages use an `admin_path/1` helper.
**Fix:** Use a shared helper.

---

_Reviewed: 2026-10-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
