# Phase 144 Route Inventory

This dated before-edit inventory records a live browser visit for each route pattern returned by `RouteScorecards.expected_routes/0`, including the explicit logout-propagation query workflow. The concrete URLs below were opened in the synthetic host operator session on the stable preview; no action was submitted.

**Preview:** `lockspire-phase144-preview` — `http://127.0.0.1:4121`  
**Captured:** 2026-10-09  
**Source revision:** `eeacb872cdbf655cad548d4553e65e3d02f8afef`  
**Served inline CSS:** normalized SHA-256 `cb478daf1ee2607aff12c01fa4a7b396c5fb26b5de65dc3f8af98ebb81b9c7a8`  
**Row identity notation:** `eeacb872 / cb478daf` refers to the revision and normalized served-style hash above.

| Route | Concrete URL | Top task | Browser result | Source / style identity | Follow-up risk |
| --- | --- | --- | --- | --- | --- |
| `/admin` | `http://127.0.0.1:4121/lockspire/admin/` | Review operator overview | **pass** — Overview rendered | `eeacb872 / cb478daf` | Check information hierarchy and responsive density |
| `/admin/clients` | `http://127.0.0.1:4121/lockspire/admin/clients` | Find a registered client | **pass** — five seeded clients rendered | `eeacb872 / cb478daf` | Check long client names and narrow table behavior |
| `/admin/clients/:client_id` | `http://127.0.0.1:4121/lockspire/admin/clients/billingo-dashboard-public` | Review client posture | **pass** — client identity, state, and actions rendered | `eeacb872 / cb478daf` | Check action priority and mobile layout |
| `/admin/clients/:client_id/edit` | `http://127.0.0.1:4121/lockspire/admin/clients/billingo-dashboard-public/edit` | Edit safe client metadata | **pass** — metadata form rendered; unchanged | `eeacb872 / cb478daf` | Check field grouping and save feedback |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | `http://127.0.0.1:4121/lockspire/admin/clients/billingo-dashboard-public/edit?workflow=logout-propagation` | Edit logout propagation settings | **pass** — workflow-specific form rendered; unchanged | `eeacb872 / cb478daf` | Check query workflow clarity and consequence copy |
| `/admin/clients/:client_id/logout-uris` | `http://127.0.0.1:4121/lockspire/admin/clients/billingo-dashboard-public/logout-uris` | Manage post-logout redirect URIs | **pass** — URI policy form rendered; unchanged | `eeacb872 / cb478daf` | Check exact-match guidance and validation recovery |
| `/admin/clients/:client_id/par-policy` | `http://127.0.0.1:4121/lockspire/admin/clients/billingo-dashboard-public/par-policy` | Review client PAR policy | **pass** — client PAR policy form rendered | `eeacb872 / cb478daf` | Check default-versus-client scope distinction |
| `/admin/clients/:client_id/redirects` | `http://127.0.0.1:4121/lockspire/admin/clients/billingo-dashboard-public/redirects` | Manage redirect URIs | **pass** — redirect URI form rendered; unchanged | `eeacb872 / cb478daf` | Check exact-match help and long URI wrapping |
| `/admin/clients/:client_id/rotate-registration-access-token` | `http://127.0.0.1:4121/lockspire/admin/clients/northstar-payables-portal/rotate-registration-access-token` | Rotate registration access token | **pass** — confirmation form rendered; not submitted | `eeacb872 / cb478daf` | Check one-time secret disclosure and recovery path |
| `/admin/clients/:client_id/rotate-secret` | `http://127.0.0.1:4121/lockspire/admin/clients/billingo-dashboard-public/rotate-secret` | Rotate client secret | **pass** — confirmation form rendered; not submitted | `eeacb872 / cb478daf` | Check destructive-action consequence and secret handling |
| `/admin/clients/:client_id/security-profile` | `http://127.0.0.1:4121/lockspire/admin/clients/billingo-dashboard-public/security-profile` | Review client security profile | **pass** — client security profile form rendered | `eeacb872 / cb478daf` | Check inherited and overridden values |
| `/admin/consents` | `http://127.0.0.1:4121/lockspire/admin/consents` | Find a consent grant | **pass** — consent inventory rendered | `eeacb872 / cb478daf` | Check filter and empty-state clarity |
| `/admin/consents/:id` | `http://127.0.0.1:4121/lockspire/admin/consents/1` | Review a consent grant | **pass** — grant detail and revoke consequence rendered | `eeacb872 / cb478daf` | Check revoke decision and scope readability |
| `/admin/dcr` | `http://127.0.0.1:4121/lockspire/admin/dcr` | Review dynamic registration | **pass** — onboarding, IAT, and client links rendered | `eeacb872 / cb478daf` | Check privileged onboarding boundaries |
| `/admin/device_authorizations` | `http://127.0.0.1:4121/lockspire/admin/device_authorizations` | Triage device authorizations | **pass** — device authorization queue rendered | `eeacb872 / cb478daf` | Check queue states and safe operator actions |
| `/admin/iats` | `http://127.0.0.1:4121/lockspire/admin/iats` | Review initial access tokens | **pass** — IAT inventory rendered; revoke not submitted | `eeacb872 / cb478daf` | Check sensitive values stay redacted |
| `/admin/iats/new` | `http://127.0.0.1:4121/lockspire/admin/iats/new` | Mint an initial access token | **pass** — mint form rendered; not submitted | `eeacb872 / cb478daf` | Check one-time secret presentation and copy |
| `/admin/interactions` | `http://127.0.0.1:4121/lockspire/admin/interactions` | Triage active interactions | **pass** — active interaction queue rendered | `eeacb872 / cb478daf` | Check interaction state and safe support context |
| `/admin/keys` | `http://127.0.0.1:4121/lockspire/admin/keys` | Review signing key lifecycle | **pass** — four lifecycle records rendered | `eeacb872 / cb478daf` | Check lifecycle distinctions and public metadata |
| `/admin/keys/:id` | `http://127.0.0.1:4121/lockspire/admin/keys/1` | Inspect a signing key | **pass** — key detail and public JWK metadata rendered | `eeacb872 / cb478daf` | Check private material remains absent |
| `/admin/logouts` | `http://127.0.0.1:4121/lockspire/admin/logouts` | Triage logout deliveries | **pass** — delivery outcomes and support context rendered | `eeacb872 / cb478daf` | Check long endpoint wrapping and read-only boundary |
| `/admin/overview` | `http://127.0.0.1:4121/lockspire/admin/overview` | Review overview panel | **pass** — Overview rendered | `eeacb872 / cb478daf` | Confirm duplicate overview entry behavior |
| `/admin/policies` | `http://127.0.0.1:4121/lockspire/admin/policies` | Review global security posture | **pass** — Security policy posture rendered | `eeacb872 / cb478daf` | Check navigation between global policy areas |
| `/admin/policies/dcr` | `http://127.0.0.1:4121/lockspire/admin/policies/dcr` | Review global DCR policy | **pass** — future registration policy rendered | `eeacb872 / cb478daf` | Check policy impact and irreversible consequences |
| `/admin/policies/dpop` | `http://127.0.0.1:4121/lockspire/admin/policies/dpop` | Review global DPoP policy | **pass** — global DPoP policy rendered | `eeacb872 / cb478daf` | Check protocol terms and default state explanation |
| `/admin/policies/par` | `http://127.0.0.1:4121/lockspire/admin/policies/par` | Review global PAR policy | **pass** — global PAR policy rendered | `eeacb872 / cb478daf` | Check protocol terms and default state explanation |
| `/admin/policies/security-profile` | `http://127.0.0.1:4121/lockspire/admin/policies/security-profile` | Review global security profile | **pass** — global security profile rendered | `eeacb872 / cb478daf` | Check defaults and per-client overrides |
| `/admin/tokens` | `http://127.0.0.1:4121/lockspire/admin/tokens` | Find a token record | **pass** — token inventory and six seeded links rendered | `eeacb872 / cb478daf` | Check redaction, filters, and mobile density |
| `/admin/tokens/:id` | `http://127.0.0.1:4121/lockspire/admin/tokens/2` | Inspect token lifecycle | **pass** — redacted token handle and lineage rendered | `eeacb872 / cb478daf` | Check safe actions and lineage readability |

All 29 listed URLs received an actual browser navigation on the same stable preview. This is route-visit evidence only; representative client and token/consent pages have deeper captures in [144-BROWSER-EVIDENCE.md](144-BROWSER-EVIDENCE.md). The rows do not claim keyboard, narrow viewport, dark theme, zoom, or mutation-flow coverage. The archived Phase 121 scorecards remain historical and were not used as current visit evidence.

## Changed consent route outcomes after Plan 144-04

The 29-entry before table above is immutable. These dated outcomes are additional observations on source revision `a03f1e44` and trimmed source CSS hash `62381363e2e337d00be8342035aae59509d71c1191a7a4d68dcb3486703e5bfb`; the refreshed checks page's delivered inline style matched it exactly. Read-only observations used stable preview project `lockspire-phase144-preview` at `http://127.0.0.1:4121`; the confirmed mutation used only `lockspire-phase144-checks` at `http://127.0.0.1:4122`.

| Changed route | Project and outcome | Result |
| --- | --- | --- |
| `/admin/consents` | Preview rendered the original two synthetic grants (1 active, 1 revoked), filters and matching count before secondary metrics, safe account/client handles, and detail links. Checks Active filter returned one grant; after the separate grant action the list showed 0 active and 2 revoked. | **pass** for populated/filter/mutation-count states; successful zero and dense states remain unobserved in browser. |
| `/admin/consents/:id` | Checks detail rendered grant identity, account/client pivots, kind/status, scopes, lifecycle values and explicit grant-only consequence. Confirmed revoke patched that grant to Revoked and reported only prevention of future remembered-consent reuse. | **pass** for connected success. Missing/read-failure/failed-revoke states are covered by focused LiveView tests and were not induced in browser. |
| `/admin/consents/:id` at native Chrome 200% | At a 756px screenshot width the first render clipped the final nav link/focus ring; after the 800px wrapping fix, all nav groups and the full focused “Logouts” link fit. | **pass** for the observed 200% layout and keyboard order. Actual browser widths below 756px remain untested. |

The checks grant revoke did not modify the preview database. See [the final browser evidence](144-BROWSER-EVIDENCE.md#after-consent-investigation-and-final-responsive-repair--2026-10-09-1700-utc) for test counts, theme observations, the 17-state status matrix, served-style receipt and remaining gaps.
