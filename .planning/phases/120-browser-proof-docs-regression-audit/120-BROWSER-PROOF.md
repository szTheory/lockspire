# Phase 120 Browser Proof Matrix

**Status:** maintainer-only planning evidence.
**Route truth:** `Lockspire.Web.AdminRouter` plus `/admin/clients/:client_id/edit?workflow=logout-propagation`.
**Runtime impact:** none. This artifact does not create a supported admin route, public document, browser-testing product, CI gate, package dependency, or runtime behavior.

## Source Truth

Route proof starts from mounted `live(...)` entries in `Lockspire.Web.AdminRouter` and then appends one query-workflow row: `/admin/clients/:client_id/edit?workflow=logout-propagation`. That query workflow is URL evidence for `ClientsLive.Show` form mode, not a Phoenix router expansion.

Screenshots and browser notes are evidence after ExUnit/LiveView guardrails pass. They are not route truth, public support claims, or a replacement for source-derived route proof. Phase 110 screenshots remain historical baseline evidence only.

## Required Coverage

The representative matrix covers these widths and modes without requiring a full route x width x theme x motion cartesian table:

- Widths: `320px`, `390px`, `768px`, `1024px`, `1440px`
- Themes: `light`, `dark`, `system`
- Motion: default motion and `reduced-motion`
- Journeys: `Orient`, `Configure`, `Support`, `Operate`
- Internal proof boundary: `AdminLab.StressSurface`

## Guardrail Commands

Run deterministic guardrails before collecting or recording any browser evidence:

```bash
MIX_ENV=test mix test test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1
```

Optional seeded demo smoke remains a maintainer sanity check for route reachability when the adoption demo is running:

```bash
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 scripts/demo/adoption_smoke.sh
```

Manual browser evidence is recorded as notes under `tmp/admin-ui-polish/phase-120/`. Do not commit screenshots, traces, reports, cookies, tokens, private keys, auth codes, verifier material, user codes, copy-once plaintext, or token-looking strings.

## Tooling Boundary

ExUnit, Phoenix LiveViewTest, and LazyHTML guardrails are the blocking proof path for Phase 120. Browser notes are maintainer-only evidence that supplements those guardrails; they do not define runtime behavior, public documentation truth, or package support.

This plan uses manual browser evidence against the same route, viewport, theme, and reduced-motion matrix unless a maintainer later chooses browser automation. Optional browser automation is conditional maintainer proof only and not a phase-success requirement.

Any package-manager install, `package.json`, lockfile, Playwright config, browser download, axe dependency, npm script, browser report, trace, or screenshot workflow must stop at `checkpoint:human-verify` before it is created. `@playwright/test` and `@axe-core/playwright` are named here only as conditional maintainer tooling that requires human package verification before any package-manager install or package/config file is added.

Do not add public docs, Hex package content, CI browser gates, runtime browser-test behavior, or a supported admin route for this proof lane. If automation is not adopted, manual browser evidence remains the required fallback and the explicit gap notes in this artifact stay current.

## Representative Matrix

| Route / Surface | Source | Journey / JTBD | Viewport / Theme / Motion Risk | Seeded Or Fixture State | Evidence Path Or Note | Accessibility Note | Sensitive Evidence Check | Gap Note |
|---|---|---|---|---|---|---|---|---|
| `/admin` or `/admin/overview` | `AdminRouter` overview routes | Orient: understand attention-worthy provider state and choose the next workflow. | `1440px` light plus `390px` system. Shell/nav scanability and first-viewport orientation. | Adoption demo overview with healthy, warning, incident, DCR, key, support, and operations summary state. | `tmp/admin-ui-polish/phase-120/orient-overview-1440-light.md` and `tmp/admin-ui-polish/phase-120/orient-overview-390-system.md` notes. | Confirm skip-free keyboard access to journey navigation and visible focus on nav/theme controls. | Deny cookies, auth codes, token-looking strings, and real tenant hostnames. | Browser evidence pending until maintainer manual pass; ExUnit source route proof is blocking. |
| `/admin/clients/:client_id` | `AdminRouter` client detail route | Configure: inspect one client's identity, posture, credentials, endpoints, DCR/RAT, support pivots, and lifecycle state. | `320px` light plus `1440px` dark. Dense panes, long values, and support pivot wrapping. | `northstar-dcr-self-registered` seeded self-registered client with strict posture, logout URIs, contacts, RAT context, and long values. | `tmp/admin-ui-polish/phase-120/client-detail-320-light.md` and `tmp/admin-ui-polish/phase-120/client-detail-1440-dark.md` notes. | Confirm pane headings remain navigable and support pivot links are keyboard reachable. | Refute client secret hash/verifier material; support pivot must use `/admin/logouts`. | Manual evidence should record no page-level overflow at `320px`. |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | Query workflow in `ClientsLive.Show`; not a router expansion | Configure: maintain RP logout cleanup endpoints separately from browser redirects. | `390px` light with `reduced-motion`. Query workflow clarity and form help copy. | Seeded Northstar back-channel/front-channel logout propagation URI state. | `tmp/admin-ui-polish/phase-120/client-logout-propagation-390-light-reduced-motion.md` note. | Confirm labels/help text explain durable back-channel delivery and best-effort front-channel cleanup. | Refute plaintext credentials, cookies, and copied tokens. | Manual evidence should record that reduced motion does not hide form feedback or focus. |
| `/admin/policies/dcr` | `AdminRouter` DCR policy route | Configure: decide who may self-register and which auth methods are allowed. | `768px` dark. One-form grouping and dense allowlist readability. | DCR disabled/open policy and allowed auth-method fixture state from adoption demo policy seed. | `tmp/admin-ui-polish/phase-120/dcr-policy-768-dark.md` note. | Confirm one submit workflow, visible focus, and field help/error associations. | Refute secret or registration token plaintext. | Browser evidence pending; Phase 119 tests cover form names and grouped workflow source behavior. |
| `/admin/iats` | `AdminRouter` IAT index route | Configure: review initial access token inventory and intake state. | `320px` system. Dense list wrapping and status comprehension. | Active, revoked, used, and expired initial access token seed states. | `tmp/admin-ui-polish/phase-120/iats-index-320-system.md` note. | Confirm statuses include text labels and action destinations remain reachable by keyboard. | Refute plaintext initial access token values after creation. | Manual evidence should note whether list rows avoid horizontal page overflow. |
| `/admin/iats/new` | `AdminRouter` IAT creation route | Configure: create a bounded intake token for partner onboarding. | `390px` reduced-motion. Copy-once risk, form help, and consequence framing. | Empty draft plus copy-once creation state if maintainer chooses to exercise mint flow locally. | `tmp/admin-ui-polish/phase-120/iat-new-390-reduced-motion.md` note. | Confirm labels, help, and copy-once warning are clear without relying on animation. | Do not commit minted plaintext IAT; record only redacted/manual observation. | If mint flow is not exercised, record as explicit manual gap rather than storing plaintext evidence. |
| `/admin/tokens/:id` | `AdminRouter` token detail route | Support: decide whether one token or refresh family needs revocation. | `320px` dark. Redaction, destructive consequence copy, long family IDs. | Active, revoked, expired, reuse-detected, and long-family seed states. | `tmp/admin-ui-polish/phase-120/token-detail-320-dark.md` note. | Confirm revoke/family-revoke controls have visible focus and consequence text. | Refute access/refresh token plaintext and token hash leakage. | Manual evidence should record which seeded token ID was inspected without copying sensitive values. |
| `/admin/consents/:id` | `AdminRouter` consent detail route | Support: decide whether one stored grant is healthy or should be revoked. | `768px` system. Stored grant detail and revoke framing. | Remembered and revoked consent seed states. | `tmp/admin-ui-polish/phase-120/consent-detail-768-system.md` note. | Confirm account/client/scopes remain understandable and revoke form is labelled. | Refute unredacted account secrets or token material. | Manual evidence pending; deterministic tests cover revoke consequence copy. |
| `/admin/device_authorizations` | `AdminRouter` device authorization route | Operate: inspect device authorization queue and expiry state. | `320px` light. Read-only queue rows, long verification handles, no unsupported controls. | Pending, approved, denied, consumed, expired, and long-handle seed states. | `tmp/admin-ui-polish/phase-120/device-authorizations-320-light.md` note. | Confirm queue state text is non-color-only and keyboard traversal reaches each row/action destination. | Refute user code plaintext and device code plaintext. | Manual evidence should confirm no page-level overflow at `320px`. |
| `/admin/interactions` | `AdminRouter` interactions route | Operate: inspect active authorization interaction queue state. | `390px` system. Dense rows, pending/denied/expired state copy. | Pending login, pending consent, denied, expired, and long return-to seed states. | `tmp/admin-ui-polish/phase-120/interactions-390-system.md` note. | Confirm read-only queue language and focus states remain visible. | Refute authorization codes, cookies, and session tokens. | Manual evidence pending; operate queue remains read-only unless existing domain APIs back actions. |
| `/admin/logouts` | `AdminRouter` logout deliveries route | Operate: inspect logout propagation delivery outcomes and support pressure. | `1440px` dark plus `390px` reduced-motion. Supported logout route, queue density, retryable/discarded state copy. | Pending, retryable, rendered, succeeded, discarded, and long endpoint URL seed states. | `tmp/admin-ui-polish/phase-120/logouts-1440-dark.md` and `tmp/admin-ui-polish/phase-120/logouts-390-reduced-motion.md` notes. | Confirm queue rows expose status text, attempts, target URI wrapping, and no unsupported queue mutation controls. | Refute cookies, token-looking strings, and raw sensitive endpoint secrets. | Route/link guardrails now pin `/admin/logouts`; manual evidence should verify the supported route renders. |
| `AdminLab.StressSurface` | Internal `test/support` renderer, not an admin route | Internal lab boundary: prove component states without public support truth. | Light, dark, system, and `reduced-motion` markers across hostile fixture states. | `AdminLab.Fixtures.all()` hostile but redaction-safe component state matrix. | `tmp/admin-ui-polish/phase-120/internal-lab-stress-surface.md` note if manually inspected; ExUnit component stress remains the blocking proof. | Confirm component labels, help/error IDs, disabled links, destructive groups, and long values render coherently. | Use fixture denylist; refute live secrets, token plaintext, private keys, and copy-once values. | No browser route should be added for this surface; it stays internal lab evidence only. |

## Sensitive Evidence Denylist

Before preserving any maintainer evidence, scan notes/screenshots/reports for these classes and delete or redact evidence if found:

- client secrets, registration access token plaintext, initial access token plaintext, refresh/access token plaintext
- authorization codes, cookies, private keys, verifier material, user codes
- JWT-looking strings, `sk_live_`, `pk_live_`, real tenant hostnames, production account identifiers
- source-only values such as `client_secret_hash`, verifier material, or private JWK text

## Explicit Gaps

- Manual browser evidence is not yet captured in this plan artifact; the table defines the route, viewport, theme, motion, seeded state, and evidence note contract for the maintainer pass.
- Optional Playwright/axe automation is not adopted in Plan 120-01. The equivalent manual browser evidence path remains the active PROOF-02 route.
- Phase 110 screenshot filenames are intentionally not reused as current proof. New Phase 120 notes or screenshots, if captured, must live under `tmp/admin-ui-polish/phase-120/` and remain uncommitted unless explicitly scrubbed and approved.
- Full route x width x theme x motion cartesian coverage is intentionally not required; the representative rows above cover each required width/mode and route risk.
