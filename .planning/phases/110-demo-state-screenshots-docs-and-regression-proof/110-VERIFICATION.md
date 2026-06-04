---
phase: 110-demo-state-screenshots-docs-and-regression-proof
status: gaps_found
verified_at: "2026-06-04T09:30:00Z"
---

# Phase 110 Verification

## Status

Gaps - automated verification passed, route-complete desktop/mobile screenshot evidence was captured, and browser click-through evidence was recorded. Phase 110 is not marked fully passed because 390px no-page-overflow proof failed for client workspace/workflow routes.

## Command Results

| Check | Result | Notes |
|-------|--------|-------|
| `MIX_ENV=test mix compile --warnings-as-errors` | Passed | Re-run after final evidence/test-contract edits. |
| `git diff --check` | Passed | No whitespace errors in tracked changes. |
| `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | Passed | 21 tests, 0 failures. |
| `mix test test/lockspire/web/live/admin --max-failures 1` | Passed | 85 tests, 0 failures. |
| `mix test` | Passed | 1073 tests, 0 failures, 287 excluded. |
| `rg "tmp/admin-ui-polish" lib >/tmp/lockspire-phase110-runtime-screenshot-ref.txt; test ! -s /tmp/lockspire-phase110-runtime-screenshot-ref.txt` | Passed | Runtime source under `lib/` does not reference screenshot evidence paths. |

## Browser Evidence

| Proof | Result | Notes |
|-------|--------|-------|
| Overview-start click-through | Captured | Signed in as seeded `ops` operator, started at `/lockspire/admin`, and reached Orient, Configure, Support, and Operate groups. |
| Screenshot inventory | Captured | 58 fresh desktop/mobile screenshots generated under `tmp/admin-ui-polish/phase110-*.png`. |
| Confirmation workflows | Captured with constraints | Risky actions were opened only to pre-confirmation/copy-once states; no irreversible production-like action was confirmed. |
| Copy-once/redaction | Captured with constraints | Evidence records durable handles only and does not persist plaintext IATs, RATs, client secrets, user codes, verifier material, access tokens, refresh tokens, or token hashes. |
| 390px no-page-overflow | Gaps | Client workspace and client workflow routes returned `true` for page-level overflow at 390px. |

## Exact Gaps

The following routes were captured but failed the 390px page-level overflow proof:

- `/admin/clients/:client_id`
- `/admin/clients/:client_id/edit`
- `/admin/clients/:client_id/redirects`
- `/admin/clients/:client_id/logout-uris`
- `/admin/clients/:client_id/edit?workflow=logout-propagation`
- `/admin/clients/:client_id/par-policy`
- `/admin/clients/:client_id/security-profile`
- `/admin/clients/:client_id/rotate-secret`
- `/admin/clients/:client_id/rotate-registration-access-token`

## Gap Diagnosis

The gap is isolated to `Lockspire.Web.Live.Admin.ClientsLive.Show` routes and
the shared client detail/edit layout:

- `lib/lockspire/web/live/admin/clients_live/show.ex` renders every failing
  route through the same client workspace, form workflow, or rotation workflow
  sections.
- `lib/lockspire/web/admin_css.ex` stacks action groups and description lists
  below 720px, but the affected client routes still contain long identifiers,
  long URI values, full-width action links/buttons, form controls, and
  copy-once/rotation panels inside the same card path.
- Other route groups passed the same 390px proof, so the defect is not the
  global admin shell, route inventory, browser session, or screenshot capture
  process.

Most likely fix surface:

- Add a client-route responsive overflow contract in admin CSS for
  `.lockspire-admin-card`, `.lockspire-admin-client-workspace`,
  `.lockspire-admin-form-shell`, form controls, action links/buttons,
  description-list values, value lists, and copy-once code blocks so their
  min-content widths cannot push the page wider than the viewport.
- Add deterministic regression coverage for the client route responsive
  contract. Prefer source/CSS contract assertions plus browser proof rerun;
  do not persist secret plaintext and do not make runtime code depend on
  screenshot paths.

## Fix Plan For Execution

1. Patch `lib/lockspire/web/admin_css.ex` so the client workspace and nested
   client workflow controls have `min-width: 0`, `max-width: 100%`, and
   wrapping behavior on the mobile path.
2. Re-run focused source tests:

   ```bash
   mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1
   mix test test/lockspire/web/live/admin --max-failures 1
   ```

3. Start the seeded adoption demo and re-check the nine failing routes at 390px
   with:

   ```js
   document.documentElement.scrollWidth > document.documentElement.clientWidth
   ```

4. When every listed route returns `false`, update `110-SCREENSHOTS.md`,
   `110-BROWSER-EVIDENCE.md`, and this file to `status: complete`, then run:

   ```bash
   MIX_ENV=test mix compile --warnings-as-errors
   git diff --check
   mix test
   ```

## Rerun Instructions

1. Start the adoption demo from `examples/adoption_demo` with seeded Phase 110 state.
2. Sign in as `ops` and open the routes above under `/lockspire/admin/...`.
3. Set the viewport to 390px width.
4. Re-run:

```js
document.documentElement.scrollWidth > document.documentElement.clientWidth
```

5. Update `110-SCREENSHOTS.md`, `110-BROWSER-EVIDENCE.md`, and this file only if every route returns `false`.
