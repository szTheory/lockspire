---
phase: 151-focused-client-registration-settings
reviewed: 2026-10-15T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - docs/operator-admin.md
  - lib/lockspire/web/admin_router.ex
  - lib/lockspire/web/components/admin_components.ex
  - lib/lockspire/web/live/admin/clients_live/form_component.ex
  - lib/lockspire/web/live/admin/clients_live/index.ex
  - lib/lockspire/web/live/admin/clients_live/show.ex
  - test/lockspire/web/admin_router_test.exs
  - test/lockspire/web/live/admin/clients_live/show_test.exs
  - test/lockspire/web/live/admin/clients_live_test.exs
  - test/support/endpoint.ex
findings:
  critical: 0
  warning: 5
  info: 3
  total: 8
status: issues_found
---

# Phase 151: Code Review Report

**Reviewed:** 2026-10-15
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Routing order is correct (`/clients/new` precedes `/clients/:client_id`; the test host router mirrors the production router). Return paths are built from normalized filters (status and provenance are allow-listed, page is coerced to a positive integer). The copy-once secret lifecycle is sound: secrets are cleared on `handle_params`, on acknowledge, and on hide, and duplicate rotate events are blocked by the `revealed_* : nil` guards. Rotation and disable/enable require a confirmation checkbox. The server also enforces confidential-only rotation in `Admin.rotate_client_secret`. No security vulnerabilities were found. The defects below are robustness and UX correctness problems. I did not run the tests.

## Warnings

### WR-01: Apps list has no pagination controls, so apps past the first 10 are unreachable from the UI

**File:** `lib/lockspire/web/live/admin/clients_live/index.ex:337-340` (render at 277-294)
**Issue:** `paginate/2` slices to `@per_page` (10) based on `filters["page"]`, but the render has no previous/next links. The help text says "N matching apps" while only 10 are shown. An operator can only see further apps by guessing `?page=2` in the URL, or by narrowing the search. The `page` filter is carried through every path, but nothing in the UI ever sets it.
**Fix:** Add a pager under the `resource_list` that links to `clients_index_path(Map.put(@filters, "page", to_string(page ± 1)))`, shown only while `page * @per_page < @matching_clients` (next) and `page > 1` (previous). Alternatively, drop the slice if pagination is out of scope.

### WR-02: Non-string `q` (for example `?q[]=a`) crashes the LiveView

**File:** `lib/lockspire/web/live/admin/clients_live/index.ex:342-349` (also 451-458, 379-380)
**Issue:** `normalize_filters/1` passes `"q"` through unvalidated, but status, provenance and page are all sanitized. A request such as `/admin/clients?q[]=x` or `?q[a]=b` yields a list or map. `blank_to_nil/1` has no clause for it (FunctionClauseError), and `URI.encode_query` would also raise. The operator gets a 500 or a crash loop instead of the normalized-filter behavior the other fields have.
**Fix:**
```elixir
"q" => (case Map.get(params, "q", "") do q when is_binary(q) -> q; _ -> "" end),
```

### WR-03: Disable/enable failure is silent

**File:** `lib/lockspire/web/live/admin/clients_live/show.ex:889-899`
**Issue:** In `apply_toggle/2`, the `{:error, _reason}` branch returns `socket` unchanged. `lifecycle_errors` is not set, so the operator checks "Disable app", submits, and sees nothing happen. The client stays active while they believe it is disabled. For a security-relevant destructive action, the failure path must be visible.
**Fix:** Return `assign(socket, lifecycle_errors: [%{field: :base, reason: :request_failed, detail: nil, message: "The app was not changed. Reload and try again."}])`. Use the same shape as `client_secret_rotation_error/0`.

### WR-04: `save_client` trusts a client-supplied `mode` and crashes when it is missing or unknown

**File:** `lib/lockspire/web/live/admin/clients_live/show.ex:91-96, 1294-1322`
**Issue:** The `save_client` handler dispatches on `params["mode"]`, which comes from the hidden `client[mode]` field, not from `socket.assigns.form_mode`. A submit with no mode, an unknown mode, or `"new"` raises FunctionClauseError in `save_client_attrs/2` and kills the LiveView. A mode that differs from the route is also accepted. For example, the `:par_policy` page can submit `mode=edit` and apply `edit_attrs`. The `form_mode` checks that decide the push_patch and save notice then disagree with what was actually saved. The handler also does not require `form_mode != nil`, so it can be invoked from the read-only `:show` page.
**Fix:** Add a guard `%{assigns: %{form_mode: mode}} when not is_nil(mode)` to the handler. Derive the attrs from `socket.assigns.form_mode` (ignore `params["mode"]`), and add a catch-all `save_client_attrs/2` or event clause that returns `{:noreply, socket}`.

### WR-05: Successful saves outside `:edit` give no confirmation

**File:** `lib/lockspire/web/live/admin/clients_live/show.ex:98-117`
**Issue:** `save_notice` is set only when `form_mode == :edit`, and only `:edit` patches back to the details page. For `:redirects`, `:logout_uris`, `:par_policy`, `:security_profile` and `:logout_propagation`, a successful save re-renders the same form with no notice, no navigation, and `form_params` cleared. These are the task-first routes this phase introduced. The operator cannot tell whether a change to a security setting was applied or the click was ignored. Also, the `save_notice` set after an edit persists across later visits to the `:show` action (see the `handle_params` branch at line 70), because it is only reset when entering a form mode.
**Fix:** Set a notice for every mode and push_patch to `show_path(client.client_id, :show)` for all modes. Clear `save_notice` after the details page renders it, or on the next `handle_params` that does not come from a save.

## Info

### IN-01: Client IDs are concatenated into paths without encoding

**File:** `lib/lockspire/web/live/admin/clients_live/index.ex:385`, `lib/lockspire/web/live/admin/clients_live/show.ex:1011`, `lib/lockspire/web/live/admin/clients_live/form_component.ex:723-724`
**Issue:** `client_id` is appended raw to `"/admin/clients/"`. Generated IDs are probably URL-safe, but if a host or DCR flow ever allows IDs containing `/`, `?` or `#`, these links and `push_patch` targets break or point to the wrong route.
**Fix:** Use `URI.encode(client_id, &URI.char_unreserved?/1)` in one shared helper.

### IN-02: Action-group slot names and button styles disagree with the documented variant semantics

**File:** `lib/lockspire/web/live/admin/clients_live/show.ex:335-343, 462-467, 543-548`; `lib/lockspire/web/components/admin_components.ex:301-325, 1011-1013`
**Issue:** `docs/operator-admin.md:129` says primary is "the page's main safe action". But `action_group :primary` slots are filled with `lockspire-admin-btn-secondary` links, for example "Edit app details", "Rotate client secret" and the two policy edit links. A reader (or a future contributor) cannot tell what primary means. `admin_button` also silently maps any unknown variant (such as a typo like `:destructive`, which matches the `action_group` slot name) to secondary. That is how a destructive button could lose its danger styling unnoticed. The `:destructive` slot is never used. The Rotate secret and Rotate management token submits use `:danger` correctly.
**Fix:** Either rename the slot usage to match the styling, or make `admin_button` raise or log on an unrecognized variant. Restrict `attr :variant, values: [:primary, :secondary, :danger]`.

### IN-03: Show page "Back to apps" drops the operator's inventory filters

**File:** `lib/lockspire/web/live/admin/clients_live/show.ex:270, 347, 1028`
**Issue:** The new-app route preserves filters, but the app details page always returns to the unfiltered `/admin/clients`. An operator who filtered, opened an app and returned loses their filter. This is inconsistent with the filter-preserving return the phase added for `/clients/new`. It is not necessarily in scope, but worth confirming against the phase requirement.
**Fix:** Pass the filter query through to the Show route (for example `?return=...` with an allow-listed, normalized query), or document that the details page returns to the unfiltered list.

---

_Reviewed: 2026-10-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
