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

## Final adversarial audit

**Status:** PROOF-02, PROOF-03, and PROOF-04 are closed as committed deterministic guardrails plus maintainer-only evidence contracts. Browser evidence remains manual or conditional maintainer automation; no Playwright, axe, screenshot workflow, Node package file, public route, public docs page, protocol/storage change, or runtime browser-test product was added.

### Route and JTBD signoff

| Journey / Surface | Operator job | Representative route evidence | Accessibility / focus | Responsive reflow | Theme / motion | Security/redaction | Docs truth | Maintainability / DX | Gap status |
|---|---|---|---|---|---|---|---|---|---|
| Orient | Understand what needs attention and choose the next workflow. | `/admin`, `/admin/overview`; matrix rows cover `1440px` light and `390px` system. | Source contracts pin visible focus on nav and theme controls; manual keyboard comprehension remains evidence-note work. | Matrix includes narrow and desktop overview risks; CSS contracts pin `min-width: 0`, wrapping, and mobile grid behavior. | System/light/dark selector and reduced-motion CSS are guarded. | Sensitive evidence denylist blocks cookies, auth codes, token-looking strings, and real tenant hostnames. | Operator docs preserve Orient as the overview cockpit and remain subordinate to `docs/supported-surface.md`. | Route truth is source-derived from `AdminRouter`, not screenshot filenames. | Manual browser notes pending; deterministic route/source proof is green. |
| Configure | Decide what posture should change for clients, policies, keys, DCR, IAT, and logout metadata. | `/admin/clients/:client_id`, `/admin/clients/:client_id/edit?workflow=logout-propagation`, `/admin/policies/dcr`, `/admin/iats`, `/admin/iats/new`. | Mounted and source guardrails cover labels/help references, form grouping, support pivots, and copy-once warning semantics. | Matrix covers `320px`, `390px`, `768px`, and `1440px` configure risks; long values and action clusters are guarded. | Light, dark, system, and reduced-motion rows are assigned to concrete configure workflows. | Contracts reject client secret hash/verifier material, IAT plaintext after creation, cookies, copied tokens, and registration token leakage. | Operator docs explain shared primitives, internal lab boundary, theme behavior, reduced motion, and verification expectations without changing the support ceiling. | The Phase 120 docs/support-boundary contract and package file assertions prevent proof artifacts from becoming Hex/runtime content. | Manual mint-flow evidence for `/admin/iats/new` remains optional and must not preserve plaintext. |
| Support | Investigate what happened to an account, client, token, or grant. | `/admin/tokens/:id`, `/admin/consents/:id`; matrix rows cover `320px` dark and `768px` system. | Mounted tests cover labels/descriptions, destructive consequence copy, and reachable revoke controls. | Long token family IDs, scopes, and grant details use wrapping primitives and are represented in the matrix. | Dark/system risk rows are assigned; reduced-motion behavior is covered by global CSS contracts. | Contracts reject access/refresh token plaintext, token hashes, and unredacted account secrets. | Docs keep Support as investigation context and do not add public browser tooling or lab support claims. | Reusable AdminProof helpers keep markup checks deterministic and test-only. | Manual evidence should record inspected seed IDs without copying sensitive values. |
| Operate | Inspect live protocol work that is waiting, failing, expired, or safely reviewable. | `/admin/device_authorizations`, `/admin/interactions`, `/admin/logouts`; matrix rows cover `320px`, `390px`, `1440px`, light, dark, system, and reduced-motion. | Mounted route tests reject unsupported queue mutation controls and check read-only route semantics. | Queue rows use dense resource/list primitives with wrapping long handles and endpoint URLs. | Dark/mobile/reduced-motion risks are explicitly assigned to operate rows. | Contracts reject user code plaintext, device codes, authorization codes, cookies, session tokens, and token-looking strings. | Operator docs and supported-surface contracts keep queue behavior bounded to shipped admin workflows. | Read-only route control assertions prevent accidental retry/discard/worker-control DX drift. | Manual browser notes pending; no unsupported operation controls were added. |
| Internal lab | Prove component states without creating route or support truth. | `AdminLab.StressSurface` under `test/support`; not an admin route. | Component stress tests cover labels, help/error IDs, disabled links, destructive groups, and long values. | Stress fixtures exercise hostile long values and narrow-layout pressure through reusable primitives. | Lab markers cover light, dark, system, and reduced-motion states. | Fixture denylist blocks secrets, token plaintext, private keys, and copy-once values. | Operator docs describe the lab as internal maintainer proof only; `docs/supported-surface.md` stays unchanged. | The lab remains test/support infrastructure, never `admin_supported`. | No public lab route, public component API, or host extension point was created. |

### D-15 design-quality pillar signoff

| Pillar | Final check | Outcome |
|---|---|---|
| accessibility | Source, LazyHTML, component stress, and mounted LiveView tests cover duplicate IDs, labels, descriptions, visible focus selectors, non-color status text, and read-only queue semantics. | PASS with manual keyboard/screen-reader comprehension still recorded as maintainer evidence work, not WCAG certification. |
| responsive reflow | CSS contracts and route matrix cover `320px`, `390px`, `768px`, `1024px`, and `1440px`, with wrapping/`min-width: 0`/mobile list behavior pinned. | PASS for deterministic contracts; no committed screenshot evidence. |
| information architecture | Route/JTBD matrix keeps Orient, Configure, Support, Operate jobs distinct and includes every representative route row. | PASS. |
| security/redaction | Denylists and route tests reject secret/plaintext leakage in docs, fixtures, source, package paths, and rendered operate/support surfaces. | PASS. |
| theme/motion | System/light/dark selector, semantic dark-mode remapping, and reduced-motion neutralization are source-guarded. | PASS. |
| performance/tooling weight | Browser automation was not adopted; no Node package, browser binary, CI gate, package file, screenshot, trace, or report was added. | PASS. |
| maintainability | AdminProof helpers and design-system contract tests keep proof source-derived and reusable without exposing public APIs. | PASS. |
| docs truth | `docs/operator-admin.md` now explains workflow, internal lab boundary, theme behavior, reduced motion, verification expectations, and host/Lockspire ownership; `docs/supported-surface.md` remains the public ceiling. | PASS. |
| DX | Maintainers get deterministic Mix commands and a clear manual evidence matrix; adopters do not inherit browser tooling or lab-surface support burden. | PASS. |

### D-14 adversarial concern signoff

| Concern | Check | Outcome |
|---|---|---|
| host-app integration weight | Docs preserve that Lockspire owns protocol/operator state after the host-guarded admin router while the host owns staff auth, MFA, roles, tenant policy, outer layouts, branding, product authorization, IP policy, and audit framing. | PASS. |
| inaccessible custom behavior | Tests cover focus selectors, labels, descriptions, duplicate IDs, disabled-link semantics, and non-color status text; manual keyboard/screen-reader review remains explicit. | PASS with manual evidence gap noted. |
| backend implementation leakage into operator UX | Route/JTBD audit checks each page for operator job language rather than implementation tables, worker controls, or backend identifiers. | PASS. |
| generic template UI drift | Source contracts reject generic CTAs and generic security-console copy; shared primitives keep admin UI Lockspire-specific. | PASS. |
| dark/mobile regressions | Theme/motion CSS contracts and representative matrix rows cover dark, system, reduced-motion, and narrow widths. | PASS for source contracts. |
| screenshot-only quality | Screenshots are evidence only; blocking proof is ExUnit, LiveView, LazyHTML, docs, and source contracts. | PASS. |
| secret/plaintext leakage | Denylist covers client secrets, RAT/IAT/access/refresh token plaintext, authorization codes, cookies, private keys, verifier material, user codes, JWT-looking strings, and live-looking keys. | PASS. |
| bad links | Route proof pins `AdminRouter` plus logout-propagation query workflow and rejects stale logout route drift in Plan 120-01. | PASS. |
| unsupported queue actions | Mounted operate tests reject retry, discard, approval, logout, requeue, and worker controls without existing domain APIs. | PASS. |
| protocol/support-surface creep | Public support ceiling stays in `docs/supported-surface.md`; contract tests reject component lab, public design-system, theming-engine, browser proof, Playwright, axe, screenshot-product, and package-content creep. | PASS. |

### Verification command outcomes

| Command | Outcome |
|---|---|
| `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | Passed after Task 120-03-02 GREEN: `43 tests, 0 failures`. Test output includes the pre-existing KeyCache startup log before the test repo is started. |
| `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | Passed in Plan 120-02: `4 tests, 0 failures`. |
| `MIX_ENV=test mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` | Passed in Plan 120-02: `25 tests, 0 failures`. |
| `MIX_ENV=test mix test.fast` | Passed in Task 120-03-03: `1141 tests, 0 failures, 287 excluded`. |
| `mix docs.verify` | Passed in Task 120-03-02 after the hidden-module docs link was made plain text; rerun before final signoff. |

### Final gaps and boundaries

- Manual browser notes under `tmp/admin-ui-polish/phase-120/` are not committed. The representative matrix remains the maintainer evidence contract for manual browser review.
- Optional Playwright/axe automation was not adopted, and no package-manager install was attempted. This avoids browser-tooling support creep and package-legitimacy risk.
- The audit does not claim WCAG certification, public design-system support, public lab support, public theming support, visual-diff support, CI browser gate support, or browser-testing product support.
- No public route, protocol behavior, storage schema, admin operation control, standalone admin behavior, package file, screenshot, trace, or browser report was added.
