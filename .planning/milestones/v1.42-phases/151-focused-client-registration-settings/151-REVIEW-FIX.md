---
phase: 151-focused-client-registration-settings
fixed_at: 2026-10-15T00:00:00Z
review_path: .planning/phases/151-focused-client-registration-settings/151-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 151: Code Review Fix Report

**Fixed at:** 2026-10-15
**Source review:** .planning/phases/151-focused-client-registration-settings/151-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8
- Fixed: 8
- Skipped: 0

Verification ran in the main checkout (`workflow.use_worktrees` is false). Phase test files plus the vocabulary contract test: 61 passed. `mix test.fast`: 1546 passed, 6 skipped, 0 failures.

## Fixed Issues

### WR-01: Apps list has no pagination controls, so apps past the first 10 are unreachable from the UI

**Files modified:** `lib/lockspire/web/live/admin/clients_live/index.ex`, `test/lockspire/web/live/admin/clients_live_test.exs`
**Commit:** ded415d4 (shared with WR-02, both touch the same files)
**Applied fix:** Added a "Previous apps" / "Next apps" pager nav under the list. Links are built from the normalized filters and only appear when another page exists. Regression test registers 12 apps and checks both pages.

### WR-02: Non-string `q` (for example `?q[]=a`) crashes the LiveView

**Files modified:** `lib/lockspire/web/live/admin/clients_live/index.ex`, `test/lockspire/web/live/admin/clients_live_test.exs`
**Commit:** ded415d4
**Applied fix:** `normalize_filters/1` now coerces any non-binary `q` to an empty string. Regression test loads `?q[]=x` and `?q[a]=b`.

### WR-03: Disable/enable failure is silent

**Files modified:** `lib/lockspire/web/live/admin/clients_live/show.ex`, `test/lockspire/web/live/admin/clients_live/show_test.exs`
**Commit:** bad55fcf (shared with WR-04, WR-05)
**Applied fix:** The `{:error, _}` branch of `apply_toggle/2` now sets `lifecycle_errors` with "The app was not changed. Reload the page and try again." Regression test deletes the app, submits a confirmed toggle and asserts the message.

### WR-04: `save_client` trusts a client-supplied `mode` and crashes when it is missing or unknown

**Files modified:** `lib/lockspire/web/live/admin/clients_live/show.ex`, `test/lockspire/web/live/admin/clients_live/show_test.exs`
**Commit:** bad55fcf
**Applied fix:** The handler is guarded on `form_mode in @saveable_modes` and derives attrs from the route's `form_mode` (`save_client_attrs/3` takes the atom mode). The posted `mode` is ignored. A catch-all clause no-ops for the read-only details page or malformed payloads. Regression test sends a bogus mode, an empty payload, and a save from the details page, and confirms nothing changes and nothing crashes.
**Status note:** Logic change, so it should get a human glance: requires human verification.

### WR-05: Successful saves outside `:edit` give no confirmation

**Files modified:** `lib/lockspire/web/live/admin/clients_live/show.ex`, `test/lockspire/web/live/admin/clients_live/show_test.exs`, `PRODUCT.md`
**Commit:** bad55fcf
**Applied fix:** Every mode now sets the success notice "App changes saved." (was "Client changes saved." and edit-only; copy changed to the "app" term, with the old phrase added to the retired-wording table in `PRODUCT.md`; body text now reads "The saved app settings are shown below."). Deviation from the suggested fix: non-edit modes stay on their form with the notice visible, rather than patching to the details page. Existing tests and the security profile flow rely on staying on the form, and the notice addresses the reported ambiguity. Stale notice fixed: a `save_notice_pending` flag keeps the notice only for the immediate edit-to-details patch, so later visits to the details page no longer show it. Regression test saves redirect URIs and checks the notice, then reloads the details page and checks it is gone.
**Status note:** Logic change: requires human verification.

### IN-01: Client IDs are concatenated into paths without encoding

**Files modified:** `lib/lockspire/web/live/admin/clients_live/index.ex`, `show.ex`, `form_component.ex`, `test/lockspire/web/live/admin/clients_live_test.exs`
**Commit:** 4b0d6bf5
**Applied fix:** Every app link and patch target encodes the Client ID with `URI.encode(client_id, &URI.char_unreserved?/1)`, matching the consents, tokens, interactions and sign-out notice pages. Regression test registers `odd/id?x#y` and checks the list link, the details page and its edit link.

### IN-02: Action-group slot names and button styles disagree with the documented variant semantics

**Files modified:** `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/live/admin/clients_live/show.ex`
**Commit:** 4b0d6bf5
**Applied fix:** `admin_button` declares `values: [:primary, :secondary, :danger]` and no longer maps unknown variants to secondary. "Edit app details" is now primary-styled in the primary slot; pane-level navigation links (policy edits, rotate secret, return URLs) moved to the secondary slot.

### IN-03: Show page "Back to apps" drops the operator's inventory filters

**Files modified:** `lib/lockspire/web/live/admin/clients_live/index.ex`, `show.ex`, `test/lockspire/web/live/admin/clients_live_test.exs`
**Commit:** 4b0d6bf5
**Applied fix:** List rows link to the details page with the normalized filters as query parameters (omitted when unfiltered). The details page normalizes them again on mount with `Index.normalize_filters/1` and builds every "Back to apps" link from them. Regression test covers filtered and unfiltered round trips.

---

_Fixed: 2026-10-15_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
