---
phase: 153-configure-support-page-refinement
reviewed: 2026-10-15T00:00:00Z
depth: standard
files_reviewed: 36
files_reviewed_list:
  - examples/adoption_demo/lib/adoption_demo_web/router.ex
  - lib/lockspire/web/admin_css.ex
  - lib/lockspire/web/components/admin_components.ex
  - lib/lockspire/web/live/admin/clients_live/index.ex
  - lib/lockspire/web/live/admin/clients_live/show.ex
  - lib/lockspire/web/live/admin/consents_live/index.ex
  - lib/lockspire/web/live/admin/consents_live/show.ex
  - lib/lockspire/web/live/admin/dcr_live/index.ex
  - lib/lockspire/web/live/admin/device_authorizations_live/index.ex
  - lib/lockspire/web/live/admin/iat_live/index.html.heex
  - lib/lockspire/web/live/admin/iat_live/new.html.heex
  - lib/lockspire/web/live/admin/interactions_live/index.ex
  - lib/lockspire/web/live/admin/keys_live/index.ex
  - lib/lockspire/web/live/admin/keys_live/show.ex
  - lib/lockspire/web/live/admin/logout_deliveries_live/index.ex
  - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
  - lib/lockspire/web/live/admin/policies_live/dpop.ex
  - lib/lockspire/web/live/admin/policies_live/index.ex
  - lib/lockspire/web/live/admin/policies_live/par.ex
  - lib/lockspire/web/live/admin/policies_live/security_profile.ex
  - lib/lockspire/web/live/admin/tokens_live/index.ex
  - lib/lockspire/web/live/admin/tokens_live/show.ex
  - scripts/demo/adoption_smoke.py
  - test/lockspire/adoption_demo_docker_contract_test.exs
  - test/lockspire/web/live/admin/consents_live_test.exs
  - test/lockspire/web/live/admin/dcr_live_test.exs
  - test/lockspire/web/live/admin/design_system/route_contract_test.exs
  - test/lockspire/web/live/admin/iat_live_test.exs
  - test/lockspire/web/live/admin/keys_live_test.exs
  - test/lockspire/web/live/admin/policies_live/dcr_test.exs
  - test/lockspire/web/live/admin/policies_live/dpop_test.exs
  - test/lockspire/web/live/admin/policies_live/index_test.exs
  - test/lockspire/web/live/admin/policies_live/par_test.exs
  - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
  - test/lockspire/web/live/admin/tokens_live_test.exs
  - test/support/lockspire/web/admin_proof/css_assertions.ex
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 153: Code Review Report

**Reviewed:** 2026-10-15
**Depth:** standard
**Files Reviewed:** 36

## Summary

This was a diff-focused review (a very large copy and layout refactor). I did not find any secret or token leakage. Token views show only handles. The IAT and client secret panels are copy-once, and the "hide" handlers clear the secret from assigns. Event handlers pattern-match on params, and IDs are parsed strictly (`Integer.parse` with a `""` remainder and a positive check). There are no blockers. The warnings are mostly about unguarded events, brittle source-string tests, and vocabulary drift.

## Warnings

### WR-01: Revoke events are not guarded against a nil or missing token detail

**File:** `lib/lockspire/web/live/admin/tokens_live/show.ex:52-110`
**Issue:** The `revoke_token` and `revoke_family` handlers call `Admin.revoke_token(socket.assigns.token_id, ...)` without checking `token_detail`. When the URL id is invalid, `token_id` is `nil` and `token_detail` is `nil`, so the forms are not rendered. A crafted or stale `phx-submit` event can still reach the handler with `confirm=true`. The handler then calls the admin API with `nil`, which crashes the LiveView or returns a misleading "revocation could not be confirmed" error. The forms are also hidden once a token is already revoked, but the server does not enforce that. The same applies to `family`. Server-side enforcement should match what the UI shows.
**Fix:** Add a guard clause such as `def handle_event(_event, _params, %{assigns: %{token_detail: nil}} = socket), do: {:noreply, socket}` before the confirm clauses. Also check `token_action_disabled?/1` and `family_action_disabled?/1` inside the confirm clauses.

### WR-02: Admin source-scanning tests are brittle and give false confidence

**File:** `test/lockspire/web/live/admin/design_system/route_contract_test.exs` (new "eyebrow" test), `test/lockspire/adoption_demo_docker_contract_test.exs` (new router-order test), `test/support/lockspire/web/admin_proof/css_assertions.ex`
**Issue:**
- The eyebrow test uses a relative `File.read!` and `Path.wildcard`. It breaks if tests run from another cwd, such as an umbrella setup or a Mix alias. It also fails on any future use of the word "eyebrow", including in a comment.
- The router-order test compares `:binary.match` positions on raw source text. Reformatting the route with `mix format` or a different quote style breaks it, because the literal route strings are hard-coded. It also asserts an ordering of strings, not that `/clients/new` actually resolves to the `:new` action.
- The CSS assertions check exact declaration text, for example `"padding: var(--ls-space-2) var(--ls-select-text-clearance) var(--ls-space-2) var(--ls-space-3)"` and `"display: grid"`. Any harmless CSS refactor fails them.
**Fix:**
- Use `Path.expand("../../../../..", __DIR__)` for the paths.
- Test routing behavior, for example `Phoenix.Router.route_info` or a LiveViewTest `live/2` to `/clients/new`.
- Loosen the CSS checks to property-level checks.

### WR-03: The smoke test is coupled to seed data and runs after earlier mutations

**File:** `scripts/demo/adoption_smoke.py:228-245`, `examples/adoption_demo/priv/repo/seeds.exs`
**Issue:** The smoke script hard-codes `"2 tokens in this family are revoked."` and picks the first `reuse_detected` link that the regex finds. This depends on the seed ordering and on exact family counts. If another smoke step revokes tokens first, or the seeds gain a second reuse family, the assertion fails or checks the wrong token. The regex `[^\"]*` inside a raw string is also confusing. In a raw string `\"` is a literal backslash plus a quote, so the character class excludes backslash, not only the quote. It works only by accident.
**Fix:** Select the link by a known seed handle. Use `[^"]*` in the pattern, written as a normal quoted string if needed. Derive the expected count from the seed fixture.

### WR-04: Vocabulary drift from the PRODUCT.md "UI says" map

**File:** `lib/lockspire/web/live/admin/clients_live/index.ex:137` (and nearby copy), `lib/lockspire/web/live/admin/tokens_live/index.ex` against `show.ex`
**Issue:** The vocabulary map says client should read as "app" except in identifiers. The new create-success panel title still says `"Client created"`. Elsewhere this change says "Back to apps" and "View app details". The tokens inventory filter calls the status "Used after replacement", while the detail page says "Used again at". The `test/.../vocabulary_contract_test.exs` retired-wording table does not catch these. The DPoP help text says "depending on the choice above", but the radio options render below the help text.
**Fix:** Change the title to "App created". Pick one term for the refresh-reuse state and add the retired phrases to the table. Reword the DPoP help to "the choice below" or drop the position reference.

## Info

### IN-01: `revoked_by: "operator"` is hard-coded in the token revocation handlers

**File:** `lib/lockspire/web/live/admin/tokens_live/show.ex:53,78`
**Issue:** Auditability is a project priority, but every token revocation is attributed to a generic "operator" string. This is probably pre-existing, but the page was reworked and the actor was not threaded through.
**Fix:** Pass the host-resolved operator identity if the layout or session exposes it.

### IN-02: Duplicate submission can create duplicate apps

**File:** `lib/lockspire/web/live/admin/clients_live/index.ex:61-88`
**Issue:** After a successful `save_client`, the create form stays rendered below the result panel, with `create_params: nil`. A second submit creates another client. Whether the submit button has `phx-disable-with` was not verified.
**Fix:** Hide the form after success, or show only a "Create another app" action.

---

_Reviewed: 2026-10-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
