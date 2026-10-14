# Phase 153 Baseline Screenshots

**Status: COMPLETE — 30 of 30 current admin routes captured before Phase 153 implementation edits.**

## Capture setup

- The demo runs from the current workspace source in an isolated Docker project named `lockspire-ui-review` at `http://127.0.0.1:4112`; it uses the synthetic Billingo seed data.
- The browser stayed at its default desktop display settings with no device emulation. Chrome saved full-page PNGs at 2522 physical pixels wide; each row records the exported image dimensions. The captures share one browser session and scale.
- Screenshots are local-only artifacts under the ignored `tmp/` directory.
- The app and browser were only navigated. No form was submitted, credential created/rotated/revealed, token or consent revoked, key changed, or other lifecycle action taken.
- Every saved image was reviewed for sensitive material. None contains a plaintext client secret, Registration Access Token, access/refresh token, Initial Access Token, authorization/device/user code, private JWK, or signing key. The pages may show synthetic client IDs, account handles, family handles, and demo redirect/endpoint URIs. Those are fixtures from the disposable demo.
- The `/admin/clients/new` capture records a real rendered defect: the demo host router treats the static word `new` as a dynamic client ID and shows “Client not found.” The embedded Lockspire router and its route test already define the dedicated creation route. This defect needs an adopter-level routing regression check and final-route proof.
- All captures below represent pre-Phase-153 source. No Phase 153 implementation source was edited before this set was complete.

## Route coverage

| Route | Screenshot | Page title and sections shown | Full-page PNG | Redaction check |
|---|---|---|---:|---|
| `/admin` | `tmp/admin-ui-polish/v1.42/before/overview-root.png` | Overview; Needs review, Current activity, Security settings, Signing keys | 2522×2376 | Pass |
| `/admin/overview` | `tmp/admin-ui-polish/v1.42/before/overview-route.png` | Overview; same overview sections through the explicit route | 2522×2376 | Pass |
| `/admin/clients` | `tmp/admin-ui-polish/v1.42/before/clients.png` | Clients; search, status/source filters, client records | 2522×2468 | Pass |
| `/admin/clients/:client_id` | `tmp/admin-ui-polish/v1.42/before/client-detail.png` | Client configuration; identity, effective settings, credentials, destinations, registration, related records, lifecycle | 2522×5790 | Pass |
| `/admin/clients/:client_id/edit` | `tmp/admin-ui-polish/v1.42/before/client-edit.png` | Client configuration; focused client settings form | 2522×3448 | Pass |
| `/admin/clients/:client_id/redirects` | `tmp/admin-ui-polish/v1.42/before/client-redirects.png` | Update redirect URIs; exact callback URI form | 2522×1778 | Pass |
| `/admin/clients/:client_id/logout-uris` | `tmp/admin-ui-polish/v1.42/before/client-logout-uris.png` | Update post-logout redirect URIs; browser return destinations | 2522×1778 | Pass |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | `tmp/admin-ui-polish/v1.42/before/client-logout-propagation.png` | Update logout propagation settings; server/browser sign-out destinations | 2522×2120 | Pass |
| `/admin/clients/:client_id/par-policy` | `tmp/admin-ui-polish/v1.42/before/client-par-policy.png` | Set client PAR policy; client override and effective behavior | 2522×1722 | Pass |
| `/admin/clients/:client_id/security-profile` | `tmp/admin-ui-polish/v1.42/before/client-security-profile.png` | Update client security profile; requirements and signing-key readiness | 2522×2272 | Pass |
| `/admin/clients/:client_id/rotate-secret` | `tmp/admin-ui-polish/v1.42/before/client-rotate-secret.png` | Rotate client secret; confirmation only, no secret generated | 2522×1516 | Pass |
| `/admin/clients/:client_id/rotate-registration-access-token` | `tmp/admin-ui-polish/v1.42/before/client-rotate-rat.png` | Rotate Registration Access Token; confirmation only, no token generated | 2522×1512 | Pass |
| `/admin/policies` | `tmp/admin-ui-polish/v1.42/before/policies.png` | Security; policy-area navigation and current policy summaries | 2522×2280 | Pass |
| `/admin/policies/par` | `tmp/admin-ui-polish/v1.42/before/policy-par.png` | Pushed Authorization Requests policy; default, effect, client overrides | 2522×2724 | Pass |
| `/admin/policies/security-profile` | `tmp/admin-ui-polish/v1.42/before/policy-security-profile.png` | Security profile; default, readiness, prerequisites, client overrides | 2522×3392 | Pass |
| `/admin/policies/dpop` | `tmp/admin-ui-polish/v1.42/before/policy-dpop.png` | DPoP policy; bearer/DPoP choice and client overrides | 2522×2804 | Pass |
| `/admin/policies/dcr` | `tmp/admin-ui-polish/v1.42/before/policy-dcr.png` | Dynamic Client Registration policy; registration gate, allowlists, lifetimes | 2522×6142 | Pass |
| `/admin/keys` | `tmp/admin-ui-polish/v1.42/before/keys.png` | Keys; lifecycle counts and active/upcoming/retiring/retired records | 2522×2750 | Pass |
| `/admin/keys/:id` | `tmp/admin-ui-polish/v1.42/before/key-detail.png` | Key detail; public metadata and current lifecycle state only | 2522×3110 | Pass |
| `/admin/dcr` | `tmp/admin-ui-polish/v1.42/before/dcr.png` | Dynamic Client Registration; policy, setup-token inventory, client review | 2522×2464 | Pass |
| `/admin/iats` | `tmp/admin-ui-polish/v1.42/before/iats.png` | Initial Access Tokens; state counts and redacted inventory | 2522×2714 | Pass |
| `/admin/iats/new` | `tmp/admin-ui-polish/v1.42/before/iats-new.png` | Create an Initial Access Token; expiry form before token creation | 2522×1512 | Pass |
| `/admin/consents` | `tmp/admin-ui-polish/v1.42/before/consents.png` | Consents; filters, result counts, active and revoked grants | 2522×2490 | Pass |
| `/admin/consents/:id` | `tmp/admin-ui-polish/v1.42/before/consent-detail.png` | Consent detail; grant state, scope, exact-grant revoke confirmation | 2522×2992 | Pass |
| `/admin/tokens` | `tmp/admin-ui-polish/v1.42/before/tokens.png` | Tokens; filters, lifecycle records, redacted identifiers | 2522×3944 | Pass |
| `/admin/tokens/:id` | `tmp/admin-ui-polish/v1.42/before/token-detail.png` | Token detail; reuse evidence, lineage, single-token and family actions | 2522×4722 | Pass |
| `/admin/interactions` | `tmp/admin-ui-polish/v1.42/before/interactions.png` | Authorization interactions; pending and completed history | 2522×3098 | Pass |
| `/admin/device_authorizations` | `tmp/admin-ui-polish/v1.42/before/device-authorizations.png` | Device authorization requests; status counts and synthetic records | 2522×3518 | Pass |
| `/admin/logouts` | `tmp/admin-ui-polish/v1.42/before/logouts.png` | Logout deliveries; delivery states, endpoints, and response outcomes | 2522×4214 | Pass |
| `/admin/clients/new` | `tmp/admin-ui-polish/v1.42/before/clients-new-routing-error.png` | Client configuration; demo router incorrectly renders “Client not found” | 2522×1512 | Pass |

The route set is the 29 current scorecard paths plus `/admin/clients/new`, captured exactly once. Each screenshot is a full-page image, so all page sections are present in the corresponding artifact.

## Review gate cleared

The original Plan 00 blocker is resolved. The full route set has persisted, readable images, and each image has been checked for sensitive values. Phase 153 source implementation may proceed. Keep the baseline images unchanged so the final proof can be compared against them.
