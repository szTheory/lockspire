# Upgrade the Host Admin Integration

Use this guide when an existing Phoenix app still mounts Lockspire's admin
surface by forwarding `/admin` to `Lockspire.Web.AdminRouter`. The canonical
integration expands Lockspire's native LiveView routes inside the host router,
where the host can supply current authorization policy and browser behavior.
For a new install, start with [Install and onboard](../install-and-onboard.md).

This upgrade changes the generated router helper only when the installed file
is still tracked by the install manifest and its bytes match the recorded
checksum. A release label or familiar path alone does not grant overwrite
authority. The documented historical conversion is grounded in the v1.45
generated helper and an older manifest shape that omits optional fields; it is
not a blanket migration for every customized or historical install.

## 1. Record the current state

Commit or back up the application before changing generated files. Keep a copy
of the host router, the generated Lockspire router helper, the install manifest,
and the current host authorization modules. Note any custom browser pipeline,
LiveView hooks, endpoint session settings, assets, mount path, storage prefix,
Oban prefix, and FAPI smoke choice.

Run the existing diagnostic and preserve its output:

```bash
mix lockspire.verify
```

A host still using the old forward may report that the canonical native admin
routes or host hook declarations are missing. Treat that as a wiring finding;
this command inspects compiled structure and does not decide whether the host's
authorization policy is correct.

## 2. Preview the managed conversion

Run the read-only preview:

```bash
mix lockspire.upgrade --dry-run
```

Review every `DRY-RUN` line, then compare the planned changes with the manifest
and the backup. The preview does not write generated files, migrations, the
manifest, transaction journal, or staging data. If it reports that transaction
recovery is required, the preview remains read-only and refuses to continue;
inspect the interrupted operation and its journal before choosing whether to
retry with `mix lockspire.upgrade`.

With command options omitted, the upgrade retains the manifest's recorded web
module, scope, mount path, storage prefix, Oban prefix, and FAPI smoke choice
when those inputs exist. Pass an explicit supported option only when you intend
to change that value; the change is recorded in the resulting manifest. For
example, `--mount-path /oauth` changes the mount path. Keep the existing mount
unless you have updated the host URLs, issuer configuration, and dependent
routes to match.

## 3. Apply a trusted upgrade

After reviewing the preview, apply it:

```bash
mix lockspire.upgrade
```

For a supported historical helper, the manifest must list the generated helper
as Lockspire-managed and its current bytes must match the listed SHA-256
checksum. The upgrade then replaces that unchanged helper with the canonical
`lockspire_routes/0` declaration and updates the manifest last. It creates
`lib/<web>/operator_authorization.ex` only if that host-owned file is absent.
The new seam denies all admin HTTP and LiveView access until you implement it.
If that file already exists, the upgrade leaves its bytes alone.

The upgrade does not replace host accounts, staff identity, sign-in, MFA,
roles, tenant or IP policy, layouts, branding, logout behavior, or the host's
consent decisions. Omitted CLI options preserve recorded inputs. Unchanged,
manifest-tracked Lockspire scaffolding may be updated; files outside that
managed set remain host-owned. Run `mix ecto.migrate` only if the command
reports copied migrations.

## 4. Reconcile drift or unsupported history manually

If the upgrade refuses a missing, modified, duplicate, malformed, or no-longer
shipped managed entry, stop and inspect the exact file and manifest entry. Do
not edit the checksum to authorize an overwrite and do not run a fresh install
over the existing application. Compare the current helper with the backed-up
version, preserve product changes, and manually compose the canonical generated
declaration with the host's routes. Keep the host-owned Plug and LiveView hook
outside Lockspire's managed-file list. Re-run `mix lockspire.verify` after
reconciliation.

`mix lockspire.upgrade` uses the existing file-transaction and recovery path.
An interrupted apply can be retried after the transaction recovers; the
manifest is committed after files. A preview that sees pending or invalid
recovery state will not recover it as a side effect. Concurrent generator
writers and hostile same-user ancestor replacement are not supported safety
guarantees; run upgrades where untrusted concurrent processes cannot alter the
project tree.

## 5. Move authorization into the host seam

The old host pipeline guarded the forwarded admin router. The canonical helper
instead calls
`Lockspire.Web.AdminRoutes.lockspire_admin_routes/2` with the browser pipeline,
the generated `:lockspire_operator_authorization` pipeline, and the host's
`OperatorAuthorization` LiveView hook. Keep the two authorization boundaries:

1. The Plug resolves the current staff identity through host authentication
   and denies with a halted response when the host's current policy does not
   allow the admin request.
2. The LiveView hook resolves the current staff identity from the LiveView
   session and independently applies current authorization before rendering or
   handling a navigation params transition.

Do not migrate an `allow` default, a copied session boolean, or cached
`conn.assigns` into the seam. Do not assume a successful Plug check proves the
LiveView session is current. Add host tests for an allowed staff member and for
missing, invalid, or withdrawn staff authority. The hook rechecks at mount and
params transitions; it is not a promise of continuous revocation during an
idle connected page. Event-level policy and disconnect behavior remain host
decisions.

## 6. Keep browser, endpoint, consent, and public routes aligned

The generated helper keeps the host-owned account routes and consent LiveView
separate from the protected admin routes and public OAuth/OIDC forward. Preserve
that order; do not use a broad admin forward that shadows the public protocol
routes, and do not copy Lockspire's 29-route inventory.

Check the host's browser and endpoint configuration while moving the route:

- The browser pipeline used by admin routes includes `fetch_session`,
  `fetch_live_flash`, `protect_from_forgery`, and
  `put_secure_browser_headers`.
- The endpoint's `/live` socket shares the same `@session_options` as
  `Plug.Session` through `connect_info: [session: @session_options]`.
- Endpoint app configuration supplies a LiveView `signing_salt`.
- The host layout and static plug serve Phoenix, Phoenix LiveView, and
  Lockspire's admin LiveView JavaScript assets at the URLs used by the page.

These remain host endpoint, cookie, and asset responsibilities. The maintained
[adoption demo](../adoption-demo.md) links to the concrete source example. A
connected LiveViewTest proves server-side lifecycle behavior; it does not prove
browser/socket transport.

## 7. Verify structure and host policy separately

After implementing the host Plug and hook, run:

```bash
mix lockspire.verify
```

The verifier checks compiled route and action inventory, fixed session,
declared host pipeline and hook ordering, and actual first-match route dispatch.
Its success message is structural evidence only. It cannot certify arbitrary
host code, account policy, session freshness, branding, or event behavior. Keep
host request and LiveView tests for both allow and denial cases.

Repository tests currently cover generated helper compilation, HTTP denial,
connected LiveViewTest behavior, upgrade preservation and retry, diagnostics,
and the maintained demo and clean-room source. They run against the repository's
locked dependencies. Phase 170 owns actual candidate-package adoption, real
browser/socket transport, exact Phoenix 1.8.5 and LiveView 1.1.28 runtime
verification, and required CI execution. No Phase 169 repository test implies
those results.

See [Install and onboard](../install-and-onboard.md), [Admin guide](../operator-admin.md),
and [Supported surface](../supported-surface.md) for the current host contract.
