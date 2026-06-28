# Phase 121 Route Scorecards

This artifact is the canonical Phase 121 route scorecard inventory. It is maintainer-facing planning truth for page-first judgment work, not public support truth, runtime behavior, browser-tooling support, or package content.

## Source Truth

- Router source: `Lockspire.Web.AdminRouter`.
- Router derivation: `Phoenix.Router.routes(Lockspire.Web.AdminRouter)` with `/` published as `/admin` and every other router path published as `/admin...`.
- Query workflow exception: `/admin/clients/:client_id/edit?workflow=logout-propagation`.
- Expected scorecards: 29, made from 28 `AdminRouter` routes plus the single query workflow exception.
- Host seam: host applications own staff authentication, MFA, role checks, tenant policy, outer layouts, branding, product authorization, IP policy, and audit framing before this host-mounted admin router.
- Lockspire seam: Lockspire owns protocol/operator state after the host-guarded admin route is reached.

## Judgment Rubric

Each route is judged at four scopes. The questions are intentionally repeated in the same order so later guardrails can verify drift without interpreting prose.

### Page

- redundant?
- least-surprising?
- user-flow-oriented?
- visually intentional?
- on-brand?

### Section

- redundant?
- least-surprising?
- user-flow-oriented?
- visually intentional?
- on-brand?

### Action

- redundant?
- least-surprising?
- user-flow-oriented?
- visually intentional?
- on-brand?

### Component Group

- redundant?
- least-surprising?
- user-flow-oriented?
- visually intentional?
- on-brand?

Rubric application notes:

- Accessibility: every route must preserve AA contrast, visible focus, labels or descriptions, non-color-only status cues, keyboard reachability, and no duplicate IDs.
- Responsive reflow: long URLs, identifiers, handles, scopes, timestamps, and endpoint values must wrap or move into list/detail patterns without page-level overflow.
- Information architecture: pages must start from the operator job, not backend table shape.
- Security/redaction: no scorecard evidence may include client secrets, token plaintext, authorization codes, cookies, private keys, verifier material, user codes, or production-looking identifiers.
- Theme and motion: light, dark, system, and reduced-motion states are product requirements; motion must aid orientation or feedback only.
- Tooling weight: browser notes and internal lab proof stay maintainer-only and do not become runtime, CI, public docs, or package support.
- Component fit: Phoenix function components, `lockspire-admin-*` BEM classes, and `--ls-*` tokens remain the default implementation shape.
- Brand fit: Signal Cyan is constrained to the brandbook role; light-mode action text uses contrast-safe deep cyan or darker tokens.

## Baseline Candidate Classification

Authoritative baseline truth for Phase 121 is committed source plus committed planning artifacts. Current dirty admin UI/proof changes are candidate evidence only. They may sharpen scorecard judgment, but they are not accepted v1.32 implementation truth, route truth, source truth, evidence classes, or success criteria.

The observed worktree baseline from context capture named branch `milestone/v1.28-admin-ui-operator-experience-polish` at commit `8515245`. That branch name is stale context and must not be treated as Phase 121 implementation truth.

### Admin candidate evidence

These dirty files and path families may inform route scorecard questions, while remaining candidate evidence only:

- `lib/lockspire/web/admin_css.ex` and `lib/lockspire/web/admin*` style/source changes.
- `lib/lockspire/web/components/admin_components.ex` shared component changes.
- `lib/lockspire/web/live/admin/**` LiveView and HEEx changes.
- `test/lockspire/web/live/admin/**` admin proof and route contract changes.
- `test/support/lockspire/web/admin_lab/**` internal lab fixture and stress-surface changes.
- `.planning/threads/next-roadmap-assessment.md` narrow admin refresh notes.

Candidate evidence can be used to ask whether later page polish should adopt, reject, or refine:

- confirmation-form lifecycle safety on client enable/disable and other risky actions;
- DCR decision summaries that make policy posture and allowed methods scan faster;
- logout queue scanability for status, attempts, target URI, and read-only support truth;
- theme controls and light/dark/system parity where route-level orientation is affected;
- form-field consistency, help/error associations, and copy-once consequence framing;
- shared component stress coverage for dense rows, long values, disabled states, destructive confirmations, status fallback, and mobile pressure.

### Excluded dirty work

These dirty files and path families are excluded from Phase 121 truth and must not create admin scorecard requirements or v1.32 success criteria:

- `README.md`
- `docs/adoption-demo.md`
- `Makefile`
- `.dockerignore`
- `.gitignore`
- `examples/adoption_demo/**`
- `scripts/demo/**`
- `scripts/maintainer/repo_hygiene_check.sh`
- `test/lockspire/adoption_demo_docker_contract_test.exs`
- `tools/traefik/**`
- `.planning/research/.cache/**`

Excluded dirty work is not a scorecard route, source truth, evidence class, runtime/package impact, or success criterion. It is Docker, adoption-demo, Traefik, repository-hygiene, or research-cache work outside Phase 121.

No stash, revert, clean, or worktree split is part of Phase 121 unless separately requested. Executors must work around existing dirty changes without absorbing unrelated files into Phase 121 commits.

## Orient

### Scorecard: `/admin`

- **Route:** `/admin`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/")`, published as the mounted admin root.
- **Journey:** Orient
- **Persona:** Provider operator
- **JTBD:** Understand attention-worthy provider state and choose the next workflow.
- **Top task:** Decide whether to inspect clients, security posture, support cases, or live operations first.
- **Who / What / Where / When / Why:** Who: provider operator; What: provider overview; Where: host-mounted admin root; When: first arrival or return to cockpit; Why: choose the safest next workflow without alarmist noise.
- **Entry point:** Host admin mount or overview redirect.
- **Primary decision:** Which provider area needs attention first?
- **Primary action:** Review overview routing and open the most relevant journey.
- **Earned-place check:** Each overview card must point to a real journey, current posture, or actionable attention signal.
- **Empty state:** No attention items recorded; use journey cards to enter clients, security, support, or operations.
- **Error state:** If overview data cannot load, keep the operator oriented and preserve safe navigation to concrete route groups.
- **Long-data state:** Long client names, issuer URLs, and counts must wrap without moving the journey navigation off-screen.
- **Mobile risk:** First-viewport orientation and journey cards can collapse into an undifferentiated stack at 320px if hierarchy is weak.
- **Theme risk:** Overview signals must keep non-color text labels and contrast-safe status tokens in light, dark, and system themes.
- **Focus/motion risk:** Keyboard focus must remain visible on journey links and theme controls; motion must respect reduced-motion preferences.
- **Redaction/security check:** No dashboard metric may expose secrets, token material, cookies, auth codes, or production-looking tenant identifiers.
- **Unsupported action check:** Do not add protocol mutation controls on the cockpit; it routes to backed workflows only.
- **Follow-up route:** `/admin/clients`
- **Component/group fit:** `page_hero`, journey cards, `metric_grid`, `summary_stat`, `task_card`, status clusters, and host-guarded route shell.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Preserve Phoenix LiveDashboard and Oban Web style host-mounted admin clarity: Lockspire route truth is explicit while host protection remains outside this library.

### Scorecard: `/admin/overview`

- **Route:** `/admin/overview`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/overview")`.
- **Journey:** Orient
- **Persona:** Provider operator
- **JTBD:** Understand attention-worthy provider state and choose the next workflow.
- **Top task:** Re-enter the overview cockpit from navigation without losing the journey model.
- **Who / What / Where / When / Why:** Who: provider operator; What: overview route; Where: Orient navigation; When: after checking a route or returning from a support case; Why: regain provider-wide context.
- **Entry point:** Orient navigation.
- **Primary decision:** Which provider area needs attention first?
- **Primary action:** Review overview routing.
- **Earned-place check:** The page must justify every section as orientation, posture, support pressure, or operation pressure.
- **Empty state:** No attention items recorded; use journey cards to enter clients, security, support, or operations.
- **Error state:** Overview failures should degrade to clear route navigation and not imply missing protocol state was mutated.
- **Long-data state:** Long labels and high counts must wrap inside cards without horizontal page overflow.
- **Mobile risk:** Duplicate root/overview routes can confuse operators if copy implies different behavior.
- **Theme risk:** Status and attention summaries must remain legible under semantic dark-mode remapping.
- **Focus/motion risk:** Focus order should follow journey order; any transitions must not hide feedback in reduced-motion mode.
- **Redaction/security check:** Counts and summaries only; no raw identifiers, secrets, tokens, cookies, or auth codes.
- **Unsupported action check:** Do not add one-click destructive actions to the overview route.
- **Follow-up route:** `/admin/clients`
- **Component/group fit:** `page_hero`, `metric_grid`, `task_card`, status clusters, and journey navigation.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Keep `/admin` and `/admin/overview` equivalent as Orient surfaces; do not make screenshot filenames or demo paths route truth.

## Configure

### Scorecard: `/admin/clients`

- **Route:** `/admin/clients`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients")`.
- **Journey:** Configure
- **Persona:** Provider operator
- **JTBD:** Find or create a client and inspect posture at inventory level.
- **Top task:** Locate the client that needs setup, review, or support.
- **Who / What / Where / When / Why:** Who: provider operator; What: client inventory; Where: Configure > Clients; When: onboarding, review, or support triage; Why: reach the correct client workspace quickly.
- **Entry point:** Configure navigation or overview client posture card.
- **Primary decision:** Which client needs setup, review, or support?
- **Primary action:** Open client workspace.
- **Earned-place check:** Filters, rows, and actions must help select a client, not duplicate detail-page posture.
- **Empty state:** No clients yet; create a client or return after DCR onboarding.
- **Error state:** Loading or persistence errors should preserve filters and point to retry without exposing internals.
- **Long-data state:** Long client IDs, names, redirect hints, and status metadata must wrap through `resource_item` or list patterns.
- **Mobile risk:** Inventory actions can crowd rows; primary open action must stay least-surprising on narrow widths.
- **Theme risk:** Disabled, warning, strict, and policy-exception statuses need text labels across themes.
- **Focus/motion risk:** Filter fields and row links need visible focus; no animation may be required to understand filter results.
- **Redaction/security check:** Show identifiers and posture only; never reveal client secret hash, verifier material, RAT plaintext, or token material.
- **Unsupported action check:** Do not add bulk mutation or lifecycle controls here unless backed by an existing route and confirmation pattern.
- **Follow-up route:** `/admin/clients/:client_id`
- **Component/group fit:** `filter_bar`, `resource_list`, `resource_item`, `status_badge`, `long_value`, and `action_group`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Candidate client lifecycle safety work may inform the earned-place and action questions, but this scorecard does not accept any dirty implementation as complete.

### Scorecard: `/admin/clients/:client_id`

- **Route:** `/admin/clients/:client_id`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients/:client_id")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Inspect one client's identity, credentials, endpoints, policy, DCR/RAT, and lifecycle state.
- **Top task:** Decide whether the client is healthy, risky, or ready for a specific mutation.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: client workspace; Where: client detail; When: posture review, partner setup, credential rotation, endpoint update, or support pivot; Why: make safe client-specific decisions.
- **Entry point:** Client inventory, overview support pivot, or direct client link.
- **Primary decision:** Is this client healthy, risky, or ready for a specific mutation?
- **Primary action:** Review client posture.
- **Earned-place check:** Identity, posture, credentials, endpoints, logout, DCR/RAT, and lifecycle groups must each support a decision or pivot.
- **Empty state:** Client not found; return to client inventory.
- **Error state:** Missing client, validation feedback, or failed mutation must leave the operator in the workspace with consequence copy.
- **Long-data state:** Redirect URIs, logout URIs, contacts, key IDs, and handles must use wrapping long-value patterns.
- **Mobile risk:** Action groups and lifecycle controls can become dense; destructive and copy-once actions need clear separation.
- **Theme risk:** Policy, lifecycle, and credential status badges must preserve semantic contrast in every theme.
- **Focus/motion risk:** Focus order should move through posture before mutations; reduced-motion must not hide confirmations.
- **Redaction/security check:** Never expose client secret plaintext after copy-once reveal, verifier material, token material, cookies, auth codes, or private keys.
- **Unsupported action check:** Only backed workspace actions should be visible; no fake retry, worker, or protocol-debug controls.
- **Follow-up route:** `/admin/clients/:client_id/edit`
- **Component/group fit:** `entity_header`, `pane`, `description_list`, `action_group`, `copy_once_secret_panel`, `confirmation_panel`, `long_value`, and status clusters.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Candidate confirmation-form lifecycle safety can inform judgment, but host-owned account and product policy remain outside this route.

### Scorecard: `/admin/clients/:client_id/edit`

- **Route:** `/admin/clients/:client_id/edit`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients/:client_id/edit")`.
- **Journey:** Configure
- **Persona:** Provider operator
- **JTBD:** Edit client identity and basic configuration without hiding endpoint or credential state.
- **Top task:** Save routine client settings safely.
- **Who / What / Where / When / Why:** Who: provider operator; What: client settings form; Where: client workspace edit mode; When: routine metadata or configuration updates; Why: adjust basic client settings without touching riskier endpoint or credential workflows.
- **Entry point:** Client workspace action group.
- **Primary decision:** Which basic client fields should change?
- **Primary action:** Save client settings.
- **Earned-place check:** Form fields must belong to routine settings; credential, endpoint, and policy mutations should stay in separate workflows.
- **Empty state:** Client not found; return to client inventory.
- **Error state:** Validation errors must attach to fields and preserve entered values.
- **Long-data state:** Client names, contacts, and descriptions must wrap without shrinking text or clipping labels.
- **Mobile risk:** Field help and validation can crowd the save action; layout must keep labels readable.
- **Theme risk:** Help, errors, and required markers need contrast-safe token use in light, dark, and system themes.
- **Focus/motion risk:** Focus must move to the error summary or invalid field; motion cannot be required for validation feedback.
- **Redaction/security check:** Do not mix secret or token values into routine edit fields.
- **Unsupported action check:** Do not add endpoint, credential, or policy mutation controls to this routine edit form.
- **Follow-up route:** `/admin/clients/:client_id`
- **Component/group fit:** `workflow_shell`, `form_field`, `error_summary`, `admin_button`, and `action_bar`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Keep routine edits separate from high-risk Configure workflows so operators do less per page.

### Scorecard: `/admin/clients/:client_id/redirects`

- **Route:** `/admin/clients/:client_id/redirects`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients/:client_id/redirects")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Maintain exact-match redirect URIs.
- **Top task:** Save browser callback destinations that are exact, current, and intentionally allowed.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: redirect URI workflow; Where: client endpoint action; When: onboarding or callback maintenance; Why: preserve exact-match OAuth safety.
- **Entry point:** Client workspace endpoint action.
- **Primary decision:** Are browser callback destinations exact and current?
- **Primary action:** Save redirect URIs.
- **Earned-place check:** Every field, help line, and warning must reinforce exact-match redirect URI validation.
- **Empty state:** No redirect URIs recorded; add exact browser callback destinations.
- **Error state:** Invalid URI, duplicate URI, or missing required callback feedback must be field-associated.
- **Long-data state:** Long HTTPS callback URLs must wrap as URLs, not force page-level overflow.
- **Mobile risk:** Multi-line URL inputs can obscure save/cancel controls on narrow screens.
- **Theme risk:** Invalid, warning, and help states need text plus contrast-safe status tokens.
- **Focus/motion risk:** Keyboard users must reach add/remove controls and invalid rows; reduced motion cannot hide add/remove feedback.
- **Redaction/security check:** Redirect URIs may be sensitive but are not secrets; do not preserve tenant-private production hostnames as evidence.
- **Unsupported action check:** Do not combine browser redirects with logout propagation cleanup endpoints.
- **Follow-up route:** `/admin/clients/:client_id`
- **Component/group fit:** `workflow_shell`, `form_field`, URL `long_value`, `error_summary`, and action grouping.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Exact-match redirect URI safety is a security default and must remain explicit.

### Scorecard: `/admin/clients/:client_id/logout-uris`

- **Route:** `/admin/clients/:client_id/logout-uris`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients/:client_id/logout-uris")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Maintain browser post-logout redirect destinations.
- **Top task:** Decide which browser destinations may receive the user after logout completes.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: post-logout redirect URI workflow; Where: client workspace logout action; When: RP-initiated logout setup or maintenance; Why: keep browser return destinations separate from RP cleanup.
- **Entry point:** Client workspace logout action.
- **Primary decision:** Which browser destinations may receive the user after logout?
- **Primary action:** Save post-logout redirect URIs.
- **Earned-place check:** Copy must distinguish browser destinations from logout propagation URIs on every section.
- **Empty state:** No post-logout redirect URIs recorded; add allowed browser destinations if RP-initiated logout uses them.
- **Error state:** Invalid URI or ambiguous logout URI wording must be corrected before save.
- **Long-data state:** Long post-logout URLs must wrap and preserve domain/path readability.
- **Mobile risk:** Similar logout terms can collapse into confusing stacked copy on phones.
- **Theme risk:** Help text and warnings must keep contrast and semantic meaning under dark-mode alias remapping.
- **Focus/motion risk:** Focus must identify the exact field being edited; reduced-motion cannot remove validation orientation.
- **Redaction/security check:** Do not record cookies, session IDs, token-looking query values, or real tenant logout URLs in evidence.
- **Unsupported action check:** Do not add cleanup delivery controls here; cleanup endpoint setup belongs to the query workflow.
- **Follow-up route:** `/admin/clients/:client_id/edit?workflow=logout-propagation`
- **Component/group fit:** `workflow_shell`, `form_field`, URL `long_value`, `alert`, and action grouping.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** This route protects the vocabulary split between post-logout redirect URIs and logout propagation URIs.

### Scorecard: `/admin/clients/:client_id/edit?workflow=logout-propagation`

- **Route:** `/admin/clients/:client_id/edit?workflow=logout-propagation`
- **Source truth:** URL/query workflow truth in `ClientsLive.Show.resolve_form_mode/2`; not a Phoenix route or router expansion.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Maintain RP logout cleanup endpoints separately from browser redirects.
- **Top task:** Save back-channel and front-channel logout propagation endpoints with clear delivery semantics.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: logout propagation workflow; Where: client edit route with explicit workflow query; When: configuring RP cleanup endpoints; Why: keep durable back-channel and best-effort front-channel cleanup separate from browser redirects.
- **Entry point:** Client workspace logout action.
- **Primary decision:** Which RP cleanup endpoints receive logout propagation?
- **Primary action:** Save logout propagation.
- **Earned-place check:** The workflow earns its query exception only if it clarifies cleanup endpoint ownership and delivery semantics.
- **Empty state:** No logout propagation URIs recorded; add back-channel or front-channel cleanup endpoints if the RP supports them.
- **Error state:** Failed cleanup, best-effort front-channel risk, or invalid URI feedback must explain consequence without implying delivery control here.
- **Long-data state:** Long endpoint URLs must wrap and preserve scheme, host, and path.
- **Mobile risk:** Query workflow context can be lost if heading and help copy do not name logout propagation.
- **Theme risk:** Back-channel and front-channel notes need clear semantic copy and contrast-safe warning tokens in all themes.
- **Focus/motion risk:** Focus should land inside the workflow without relying on animation; reduced-motion must preserve validation feedback.
- **Redaction/security check:** Do not store cookies, token-looking strings, endpoint secrets, or production cleanup URLs as evidence.
- **Unsupported action check:** Do not add retry, discard, or delivery worker controls; this route configures endpoints only.
- **Follow-up route:** `/admin/logouts`
- **Component/group fit:** `workflow_shell`, `form_field`, `alert`, URL `long_value`, and logout-specific help copy.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** This is the only allowed `?workflow=` scorecard and must not become a second Phoenix route.

### Scorecard: `/admin/clients/:client_id/par-policy`

- **Route:** `/admin/clients/:client_id/par-policy`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients/:client_id/par-policy")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Set client-specific PAR override and show effective posture.
- **Top task:** Decide whether this client inherits or overrides issuer PAR posture.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: client PAR policy form; Where: client workspace policy action; When: client exception review or FAPI readiness work; Why: make PAR posture explicit for this client.
- **Entry point:** Client workspace policy action.
- **Primary decision:** Should this client inherit or override issuer PAR posture?
- **Primary action:** Save PAR override.
- **Earned-place check:** The page must show inherited, overridden, and effective posture without duplicating global policy controls.
- **Empty state:** No override recorded; client inherits global PAR policy.
- **Error state:** Validation or conflict feedback must name the client-level consequence.
- **Long-data state:** Long client identifiers and policy descriptions must wrap in the form shell.
- **Mobile risk:** Inherit/override choices can be misread if labels and help collapse.
- **Theme risk:** Inherited versus override status must rely on text labels, not color alone.
- **Focus/motion risk:** Radio/select controls and save action need visible focus; no motion dependency for posture change.
- **Redaction/security check:** Policy posture only; no request objects, tokens, or client secrets.
- **Unsupported action check:** Do not mutate issuer-wide PAR posture from this client route.
- **Follow-up route:** `/admin/policies/par`
- **Component/group fit:** `workflow_shell`, `decision_summary`, `form_field`, `status_badge`, and `alert`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Preserve protocol/host seam separation: expose policy consequence, not backend internals.

### Scorecard: `/admin/clients/:client_id/security-profile`

- **Route:** `/admin/clients/:client_id/security-profile`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients/:client_id/security-profile")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Set client security profile and show protocol impact.
- **Top task:** Decide whether this client inherits, opts into, or opts out of stricter security.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: client security profile form; Where: client workspace policy action; When: profile hardening or exception review; Why: make client-level security posture deliberate.
- **Entry point:** Client workspace policy action.
- **Primary decision:** Should this client inherit, opt into, or opt out of stricter security?
- **Primary action:** Save security profile.
- **Earned-place check:** The route must connect selection to consequence and readiness without exposing irrelevant protocol mechanics.
- **Empty state:** No override recorded; client inherits global security profile.
- **Error state:** Strict readiness blocked or mixed-mode validation feedback must explain what remains unsafe.
- **Long-data state:** Client IDs and warning copy must wrap in summary and form groups.
- **Mobile risk:** Strict, inherit, and opt-out choices can look equal unless action hierarchy is clear.
- **Theme risk:** Warning and danger semantics need non-color status text and contrast-safe tokens.
- **Focus/motion risk:** Focus should remain visible through profile choice, warnings, and save controls.
- **Redaction/security check:** Do not expose private keys, request objects, token material, or verifier material.
- **Unsupported action check:** Do not change global security profile from this client route.
- **Follow-up route:** `/admin/policies/security-profile`
- **Component/group fit:** `workflow_shell`, `decision_summary`, `form_field`, `alert`, `status_badge`, and `action_bar`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Keep strict-profile copy consequence-oriented and avoid fear-led security tropes.

### Scorecard: `/admin/clients/:client_id/rotate-secret`

- **Route:** `/admin/clients/:client_id/rotate-secret`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients/:client_id/rotate-secret")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Rotate a confidential client secret with copy-once handling.
- **Top task:** Confirm and rotate a confidential client secret without leaking it.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: secret rotation workflow; Where: client workspace credential action; When: credential compromise, scheduled rotation, or partner handoff; Why: issue a new secret while preserving copy-once safety.
- **Entry point:** Client workspace credential action.
- **Primary decision:** Is this confidential client's secret ready to rotate?
- **Primary action:** Rotate client secret.
- **Earned-place check:** Confirmation, consequence copy, and copy-once output must be the only point of the route.
- **Empty state:** Client is not confidential or not found; return to client workspace.
- **Error state:** Rotation failure must not reveal secret material and must preserve a safe retry path.
- **Long-data state:** Client identifiers and copy-once placeholder text must wrap without clipping.
- **Mobile risk:** Copy-once warning and generated value can crowd confirmation controls on narrow screens.
- **Theme risk:** Danger/warning copy and copy-once panel must remain legible in light, dark, and system themes.
- **Focus/motion risk:** Focus should move predictably to confirmation and copy-once panel; reduced-motion must not hide reveal state.
- **Redaction/security check:** Only copy-once plaintext appears at creation time; never commit, log, screenshot, or scorecard real secret material.
- **Unsupported action check:** Do not add bulk secret rotation, reveal-old-secret, or verifier export controls.
- **Follow-up route:** `/admin/clients/:client_id`
- **Component/group fit:** `confirmation_panel`, `copy_once_secret_panel`, `action_group`, `alert`, and `long_value`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** This scorecard preserves the hashed-at-rest and copy-once secret safety posture.

### Scorecard: `/admin/clients/:client_id/rotate-registration-access-token`

- **Route:** `/admin/clients/:client_id/rotate-registration-access-token`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/clients/:client_id/rotate-registration-access-token")`.
- **Journey:** Configure
- **Persona:** Partner-onboarding operator
- **JTBD:** Rotate a self-registered client's management token.
- **Top task:** Issue a new registration access token and understand prior token invalidation.
- **Who / What / Where / When / Why:** Who: partner-onboarding operator; What: RAT rotation workflow; Where: client workspace DCR/RAT action; When: partner management token must change; Why: restore management access without leaking token material.
- **Entry point:** Client workspace DCR/RAT action.
- **Primary decision:** Does this self-registered client need a new management token?
- **Primary action:** Rotate registration access token.
- **Earned-place check:** The route earns its place only if it clearly names self-registered scope, invalidation, and copy-once handling.
- **Empty state:** Client is not self-registered or not found; return to client workspace.
- **Error state:** Rotation failure should preserve current management-token state and avoid plaintext leakage.
- **Long-data state:** Client IDs, registration handles, and copy-once placeholders must wrap.
- **Mobile risk:** Copy-once warning and lifecycle consequence can be missed if controls stack poorly.
- **Theme risk:** Warning, danger, and copy-once panels need contrast-safe status treatment.
- **Focus/motion risk:** Confirmation focus and copy-once reveal focus must remain visible with reduced motion.
- **Redaction/security check:** Never preserve RAT plaintext in scorecards, docs, screenshots, logs, or tests.
- **Unsupported action check:** Do not add unrelated DCR policy or client lifecycle controls to this rotation route.
- **Follow-up route:** `/admin/dcr`
- **Component/group fit:** `confirmation_panel`, `copy_once_secret_panel`, `long_value`, `alert`, and `action_group`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** The page must protect the self-registration management seam without becoming a developer portal.

### Scorecard: `/admin/policies`

- **Route:** `/admin/policies`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/policies")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Inspect issuer posture and exception pressure.
- **Top task:** Choose which issuer-level policy needs review first.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: policy overview; Where: Configure > Security; When: issuer posture review or readiness audit; Why: decide which global policy route needs attention.
- **Entry point:** Configure > Security.
- **Primary decision:** Which issuer-level policy needs review first?
- **Primary action:** Review security posture.
- **Earned-place check:** Each policy summary must connect current posture to a specific route or safe next action.
- **Empty state:** No policy exceptions visible; inspect detailed policy routes as needed.
- **Error state:** Policy load failures must state that no mutation happened and keep navigation available.
- **Long-data state:** Policy names, exception descriptions, and client counts must wrap in summaries.
- **Mobile risk:** Policy cards can become generic if summaries omit the decision each route supports.
- **Theme risk:** FAPI, PAR, DPoP, DCR, warning, and exception statuses need text and contrast-safe colors.
- **Focus/motion risk:** Secondary policy navigation needs visible focus and stable order.
- **Redaction/security check:** Policy posture only; no secrets, tokens, private keys, request objects, or verifier material.
- **Unsupported action check:** Do not save global policy directly from the overview without the detailed route context.
- **Follow-up route:** `/admin/policies/par`
- **Component/group fit:** `page_hero`, `policy_nav`, `decision_summary`, `section_card`, `status_badge`, and `task_card`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Candidate DCR decision-summary work can inform this cluster but is not accepted by this plan as implemented polish.

### Scorecard: `/admin/policies/par`

- **Route:** `/admin/policies/par`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/policies/par")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Decide global PAR requirement.
- **Top task:** Save issuer-level PAR posture.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: global PAR policy form; Where: security policy overview; When: issuer hardening or exception review; Why: decide whether PAR is required by default.
- **Entry point:** Security policy overview.
- **Primary decision:** Should pushed authorization requests be required globally?
- **Primary action:** Save global PAR policy.
- **Earned-place check:** The page must separate default issuer posture from client-level overrides.
- **Empty state:** No override pressure; keep inherited/default posture.
- **Error state:** FAPI conflict or direct authorization exception must be explained as a policy consequence.
- **Long-data state:** Exception lists and client references must wrap and link to client-level route where needed.
- **Mobile risk:** Policy radio/select groups can read as generic settings without consequence copy.
- **Theme risk:** Strict, inherited, and exception status indicators need semantic labels in all themes.
- **Focus/motion risk:** Keyboard focus must cover policy nav, inputs, help, and save controls.
- **Redaction/security check:** No request-object payloads, authorization codes, tokens, cookies, or private material.
- **Unsupported action check:** Do not mutate individual client overrides from the global route.
- **Follow-up route:** `/admin/clients/:client_id/par-policy`
- **Component/group fit:** `policy_nav`, `workflow_shell`, `decision_summary`, `form_field`, `alert`, and `status_badge`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Keep policy language exact and calm; PAR is a security posture decision, not a marketing toggle.

### Scorecard: `/admin/policies/security-profile`

- **Route:** `/admin/policies/security-profile`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/policies/security-profile")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Decide global security profile posture.
- **Top task:** Select issuer default security profile and understand readiness consequences.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: global security profile form; Where: security policy overview; When: FAPI or standard posture review; Why: set the issuer default without hiding readiness constraints.
- **Entry point:** Security policy overview.
- **Primary decision:** Which issuer security profile should apply by default?
- **Primary action:** Save security profile.
- **Earned-place check:** Every readiness note must help decide standard versus strict posture.
- **Empty state:** No strict profile selected; standard OIDC posture applies.
- **Error state:** Strict profile readiness blocked or mixed-mode escape hatch feedback must name blocked conditions.
- **Long-data state:** Readiness lists and client exceptions must wrap and stay scannable.
- **Mobile risk:** Readiness details can turn into dense policy prose; summary must lead.
- **Theme risk:** Strict, warning, and disabled states must use text labels and safe contrast.
- **Focus/motion risk:** Focus must stay visible across policy nav, choice controls, and warnings.
- **Redaction/security check:** Do not reveal private keys, tokens, signed request objects, cookies, or verifier material.
- **Unsupported action check:** Do not change client-specific profile overrides here.
- **Follow-up route:** `/admin/clients/:client_id/security-profile`
- **Component/group fit:** `policy_nav`, `workflow_shell`, `decision_summary`, `alert`, `form_field`, and `status_badge`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Avoid leaking backend protocol internals unless they support an operator readiness decision.

### Scorecard: `/admin/policies/dpop`

- **Route:** `/admin/policies/dpop`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/policies/dpop")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Decide DPoP sender-constraint posture.
- **Top task:** Save whether DPoP is required, optional, or disabled by default.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: global DPoP policy form; Where: security policy overview; When: sender-constraint posture review; Why: align clients with proof-of-possession requirements.
- **Entry point:** Security policy overview.
- **Primary decision:** Should DPoP be required, optional, or disabled by default?
- **Primary action:** Save DPoP policy.
- **Earned-place check:** The form must name operational consequence and compatible-client risk.
- **Empty state:** No DPoP posture change needed; keep current issuer setting.
- **Error state:** Sender-constraint mismatch or incompatible client feedback must be consequence-oriented.
- **Long-data state:** Client exception references and compatibility notes must wrap.
- **Mobile risk:** Required/optional/disabled choices can be misread without direct labels and help text.
- **Theme risk:** Sender-constraint status must use text labels and contrast-safe semantic colors.
- **Focus/motion risk:** Policy choices and save action must be reachable and visible by keyboard.
- **Redaction/security check:** Do not expose DPoP proofs, token material, private keys, nonces, or cookies.
- **Unsupported action check:** Do not add token debugging, nonce reset, or client mutation controls to this policy form.
- **Follow-up route:** `/admin/policies`
- **Component/group fit:** `policy_nav`, `workflow_shell`, `form_field`, `alert`, and `decision_summary`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Preserve protocol/host seam: Lockspire owns sender-constraint enforcement; the host owns app-level authorization.

### Scorecard: `/admin/policies/dcr`

- **Route:** `/admin/policies/dcr`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/policies/dcr")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Decide who may self-register and which auth methods are allowed.
- **Top task:** Save the global DCR policy that gates partner registration.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: DCR policy form; Where: security policy overview or DCR onboarding; When: onboarding posture setup or registration-risk review; Why: bound self-registration without turning Lockspire into a hosted CIAM product.
- **Entry point:** Security policy overview or DCR onboarding.
- **Primary decision:** Which DCR policy safely gates partner registration?
- **Primary action:** Save global DCR policy.
- **Earned-place check:** The page must summarize decision posture, allowed methods, and onboarding consequence before the form.
- **Empty state:** DCR disabled or no methods allowed; use DCR onboarding only after policy is set.
- **Error state:** Open registration, unsupported auth method, or broad registration posture warnings must be explicit.
- **Long-data state:** Allowed method lists and policy descriptions must wrap in decision summaries.
- **Mobile risk:** DCR policy can become a dense settings form without a decision summary.
- **Theme risk:** Open, disabled, warning, and allowed-method statuses need text labels and safe contrast.
- **Focus/motion risk:** Policy nav, form fields, warnings, and save action must have visible focus and reduced-motion-safe feedback.
- **Redaction/security check:** Do not expose initial access token plaintext, registration access token plaintext, client secrets, or bearer values.
- **Unsupported action check:** Do not mint IATs or mutate individual clients on the policy route.
- **Follow-up route:** `/admin/dcr`
- **Component/group fit:** `policy_nav`, `decision_summary`, `workflow_shell`, `form_field`, `alert`, and status clusters.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Candidate DCR decision summary work belongs here as evidence to judge, not as accepted Phase 121 implementation.

### Scorecard: `/admin/keys`

- **Route:** `/admin/keys`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/keys")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Maintain signing/encryption key readiness and lifecycle.
- **Top task:** Confirm active, upcoming, and retiring keys are ready for JWKS exposure.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: key inventory; Where: Configure > Keys; When: rotation, readiness, or incident review; Why: keep key lifecycle safe and explainable.
- **Entry point:** Configure > Keys.
- **Primary decision:** Are active, upcoming, and retiring keys ready for JWKS exposure?
- **Primary action:** Manage keys.
- **Earned-place check:** Key rows must support lifecycle readiness decisions, not expose cryptographic internals for curiosity.
- **Empty state:** No keys available; publish key material before relying on JWKS.
- **Error state:** Missing active key, unsafe lifecycle transition, or storage failure must be consequence-oriented.
- **Long-data state:** Key IDs, thumbprints, and timestamps must wrap or use `long_value`.
- **Mobile risk:** Lifecycle actions and long key metadata can overflow if rows stay table-shaped.
- **Theme risk:** Active, upcoming, retiring, and missing states need non-color status cues across themes.
- **Focus/motion risk:** Key row links and lifecycle actions require visible focus; no required animation for state changes.
- **Redaction/security check:** Never expose private JWK material, verifier material, or secrets.
- **Unsupported action check:** Do not add unbacked export-private-key, force-publish, or bulk lifecycle actions.
- **Follow-up route:** `/admin/keys/:id`
- **Component/group fit:** `resource_list`, `resource_item`, `lifecycle_row`, `status_badge`, `long_value`, and `confirmation_panel`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Keep operator view focused on safe lifecycle transitions and JWKS readiness.

### Scorecard: `/admin/keys/:id`

- **Route:** `/admin/keys/:id`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/keys/:id")`.
- **Journey:** Configure
- **Persona:** Security/platform owner
- **JTBD:** Inspect one key's state and safe lifecycle transitions.
- **Top task:** Decide which lifecycle transition is safe for this key.
- **Who / What / Where / When / Why:** Who: security/platform owner; What: key detail; Where: key inventory; When: activation, publication, retirement, or incident review; Why: make one key lifecycle decision safely.
- **Entry point:** Key inventory.
- **Primary decision:** What lifecycle transition is safe for this key?
- **Primary action:** Review key lifecycle.
- **Earned-place check:** Detail sections must justify lifecycle status, JWKS readiness, and transition consequence.
- **Empty state:** Key not found; return to key inventory.
- **Error state:** Unsafe transition or storage failure must explain what did not change.
- **Long-data state:** Key IDs, thumbprints, timestamps, and algorithms must wrap without leaking private material.
- **Mobile risk:** Long cryptographic identifiers and confirmation controls can hide the main consequence.
- **Theme risk:** Lifecycle status colors must be paired with text labels and accessible contrast.
- **Focus/motion risk:** Confirmation and navigation focus must be visible; reduced-motion cannot hide lifecycle feedback.
- **Redaction/security check:** Public metadata only; never expose private keys, key material, secrets, tokens, or verifier material.
- **Unsupported action check:** Do not add private-key export or unsupported lifecycle mutations.
- **Follow-up route:** `/admin/keys`
- **Component/group fit:** `entity_header`, `description_list`, `lifecycle_row`, `confirmation_panel`, `status_badge`, and `long_value`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Operator copy should expose just enough crypto posture to support safe lifecycle decisions.

### Scorecard: `/admin/dcr`

- **Route:** `/admin/dcr`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/dcr")`.
- **Journey:** Configure
- **Persona:** Partner-onboarding operator
- **JTBD:** Guide partner onboarding from policy to IATs to self-registered clients.
- **Top task:** Decide the next DCR onboarding step.
- **Who / What / Where / When / Why:** Who: partner-onboarding operator; What: DCR onboarding hub; Where: Configure > DCR; When: partner intake or registration support; Why: connect policy, IATs, self-registered clients, and RAT support.
- **Entry point:** Configure > DCR.
- **Primary decision:** What is the next DCR onboarding step?
- **Primary action:** Mint initial access token.
- **Earned-place check:** Sections must show policy posture, intake-token state, self-registration results, and RAT support without duplicating each detail route.
- **Empty state:** No self-registered clients yet; mint an IAT or edit DCR policy first.
- **Error state:** Open registration, expired/used/revoked IATs, or RAT rotation need must be consequence-oriented.
- **Long-data state:** Partner names, client IDs, and registration handles must wrap in resource rows.
- **Mobile risk:** Onboarding sequence can flatten into unrelated cards unless step order is clear.
- **Theme risk:** Open, disabled, expired, used, revoked, and warning states need text labels across themes.
- **Focus/motion risk:** Step cards, IAT links, and client pivots need visible focus and no motion dependency.
- **Redaction/security check:** Do not show IAT plaintext after creation, RAT plaintext, client secrets, or token material.
- **Unsupported action check:** Do not turn this into a hosted developer portal or public self-service console.
- **Follow-up route:** `/admin/iats/new`
- **Component/group fit:** `page_hero`, `task_card`, `decision_summary`, `resource_item`, `status_badge`, and `action_group`.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Keep DCR onboarding connected but distinct from DCR policy.

### Scorecard: `/admin/iats`

- **Route:** `/admin/iats`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/iats")`.
- **Journey:** Configure
- **Persona:** Partner-onboarding operator
- **JTBD:** Review initial access token inventory and intake state.
- **Top task:** Identify which intake tokens are active, used, expired, or revoked.
- **Who / What / Where / When / Why:** Who: partner-onboarding operator; What: IAT inventory; Where: DCR onboarding; When: partner intake review or troubleshooting; Why: understand whether intake credentials are still usable.
- **Entry point:** DCR onboarding.
- **Primary decision:** Which intake tokens are active, used, expired, or revoked?
- **Primary action:** Review initial access tokens.
- **Earned-place check:** Rows must emphasize intake state, expiry, scope, and next route rather than raw token material.
- **Empty state:** No initial access tokens; mint one for a bounded partner intake.
- **Error state:** Revoked, expired, or ambiguous token state must be readable without support escalation.
- **Long-data state:** Token labels, partner metadata, scopes, and timestamps must wrap.
- **Mobile risk:** IAT inventory is a known weak spot; rows need list alternatives and clear state copy at 320px.
- **Theme risk:** Active, used, expired, and revoked statuses need text and contrast-safe tokens.
- **Focus/motion risk:** Row links and create action need visible focus; no animation should be required to learn token state.
- **Redaction/security check:** Never show initial access token plaintext after creation.
- **Unsupported action check:** Do not add reveal-token or bulk revoke controls not backed by existing flows.
- **Follow-up route:** `/admin/iats/new`
- **Component/group fit:** `resource_list`, `dense_resource_row`, `status_badge`, `timestamp`, `long_value`, and `empty_state`.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Later polish should treat this as a Configure weak spot and prove mobile scanability.

### Scorecard: `/admin/iats/new`

- **Route:** `/admin/iats/new`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/iats/new")`.
- **Journey:** Configure
- **Persona:** Partner-onboarding operator
- **JTBD:** Create a bounded intake token for partner onboarding.
- **Top task:** Set constraints, create the token, and handle copy-once plaintext safely.
- **Who / What / Where / When / Why:** Who: partner-onboarding operator; What: IAT creation form; Where: IAT inventory or DCR onboarding CTA; When: partner needs a bounded intake credential; Why: create only the required onboarding credential and avoid plaintext leakage.
- **Entry point:** IAT inventory or DCR onboarding CTA.
- **Primary decision:** What intake token constraints should be issued?
- **Primary action:** Create initial access token.
- **Earned-place check:** Constraint fields, consequence copy, and copy-once result must each earn their place.
- **Empty state:** No token draft yet; set expiry and scope for partner intake.
- **Error state:** Validation errors or overly broad intake warnings must attach to fields and preserve draft input.
- **Long-data state:** Scopes, labels, partner metadata, and copy-once placeholder values must wrap.
- **Mobile risk:** Copy-once risk and form help can be missed if the route stacks as a generic form.
- **Theme risk:** Warning, success, and copy-once panels must stay legible and semantic across themes.
- **Focus/motion risk:** Focus should move to validation summary or copy-once panel predictably; reduced-motion must not hide output.
- **Redaction/security check:** Do not commit or record minted plaintext IAT values in evidence.
- **Unsupported action check:** Do not create public developer portal behavior or reveal historical token plaintext.
- **Follow-up route:** `/admin/iats`
- **Component/group fit:** `workflow_shell`, `form_field`, `copy_once_secret_panel`, `alert`, `error_summary`, and `action_bar`.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Manual mint-flow evidence must stay redacted or be omitted.

## Support

### Scorecard: `/admin/consents`

- **Route:** `/admin/consents`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/consents")`.
- **Journey:** Support
- **Persona:** Support engineer
- **JTBD:** Investigate remembered and revoked grants by account, client, and status.
- **Top task:** Filter consent grants that match a support case.
- **Who / What / Where / When / Why:** Who: support engineer; What: consent grant list; Where: Support > Consents or overview support pivot; When: account/client access investigation; Why: find durable grants without exposing token material.
- **Entry point:** Support > Consents or overview support queue.
- **Primary decision:** Which stored grants match the support case?
- **Primary action:** Filter consent grants.
- **Earned-place check:** Filters, rows, and empty copy must help investigation before any revoke decision.
- **Empty state:** No consent grants match this view; adjust account, client, or status filter.
- **Error state:** Filter or load failure should preserve query context and avoid backend leakage.
- **Long-data state:** Long account IDs, client IDs, scopes, and timestamps must wrap in dense rows.
- **Mobile risk:** Support filters and dense grant rows are weak spots; mobile list alternatives must keep investigation context.
- **Theme risk:** Remembered, revoked, warning, and empty states need text labels and contrast-safe tokens.
- **Focus/motion risk:** Filter fields, row links, and reset actions need visible focus without motion dependency.
- **Redaction/security check:** No tokens, cookies, auth codes, secrets, or unredacted account-sensitive values.
- **Unsupported action check:** Do not add bulk revocation or hidden mutation controls to the index.
- **Follow-up route:** `/admin/consents/:id`
- **Component/group fit:** `filter_bar`, `dense_resource_row`, `resource_list`, `long_value`, `status_badge`, and `empty_state`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Later Support polish should prioritize scanability and account/client context over decorative density.

### Scorecard: `/admin/consents/:id`

- **Route:** `/admin/consents/:id`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/consents/:id")`.
- **Journey:** Support
- **Persona:** Support engineer
- **JTBD:** Decide whether one stored grant is healthy or should be revoked.
- **Top task:** Review one grant and confirm any revocation consequence.
- **Who / What / Where / When / Why:** Who: support engineer; What: consent grant detail; Where: consent grant list; When: grant investigation or revoke request; Why: act on a durable grant with clear consequence.
- **Entry point:** Consent grant list.
- **Primary decision:** Should this durable grant remain active?
- **Primary action:** Review stored grant.
- **Earned-place check:** Detail groups must support health, history, scope, and revoke consequence.
- **Empty state:** Consent not found; return to filtered grant list.
- **Error state:** Revoke failure or missing history must explain what remains active.
- **Long-data state:** Account IDs, client IDs, scope lists, grant IDs, and timestamps must wrap.
- **Mobile risk:** Detail sections and revoke confirmation can obscure one another on narrow screens.
- **Theme risk:** Active/revoked/destructive states need non-color labels and contrast-safe status treatment.
- **Focus/motion risk:** Revoke confirmation controls and back links must have visible focus; reduced-motion must preserve feedback.
- **Redaction/security check:** Grant metadata only; never expose token plaintext, secrets, cookies, or authorization codes.
- **Unsupported action check:** Do not add grant editing or unsupported recovery actions.
- **Follow-up route:** `/admin/consents`
- **Component/group fit:** `entity_header`, `description_list`, `confirmation_panel`, `status_badge`, `long_value`, and `action_group`.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Revocation copy must name durable consequence without implying host-owned account policy.

### Scorecard: `/admin/tokens`

- **Route:** `/admin/tokens`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/tokens")`.
- **Journey:** Support
- **Persona:** Support engineer
- **JTBD:** Investigate token and refresh-family state by account, client, and status.
- **Top task:** Filter lifecycle records that match an incident.
- **Who / What / Where / When / Why:** Who: support engineer; What: token lifecycle list; Where: Support > Tokens or overview support pivot; When: incident, revocation, reuse-detection, or support inquiry; Why: find safe token/family context without exposing bearer values.
- **Entry point:** Support > Tokens or overview support queue.
- **Primary decision:** Which token lifecycle records match the incident?
- **Primary action:** Filter tokens.
- **Earned-place check:** Filters and rows must help identify incident state, family state, and safe detail route.
- **Empty state:** No lifecycle tokens match this view; adjust account, client, or status filter.
- **Error state:** Load or filter failure must not expose implementation internals or sensitive values.
- **Long-data state:** Token handles, family IDs, account IDs, client IDs, and timestamps must wrap.
- **Mobile risk:** Token rows are weak on mobile if IDs dominate over incident state.
- **Theme risk:** Reuse detected, revoked, expired, and active statuses need labels and safe contrast.
- **Focus/motion risk:** Filters, reset, and row links must be reachable by keyboard with visible focus.
- **Redaction/security check:** Do not show access token plaintext, refresh token plaintext, hashes, cookies, auth codes, or secrets.
- **Unsupported action check:** Do not add bulk revoke or family mutation controls on the index.
- **Follow-up route:** `/admin/tokens/:id`
- **Component/group fit:** `filter_bar`, `dense_resource_row`, `long_value`, `status_badge`, `empty_state`, and `resource_list`.
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Later Support polish should make incident state lead the row rather than raw identifiers.

### Scorecard: `/admin/tokens/:id`

- **Route:** `/admin/tokens/:id`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/tokens/:id")`.
- **Journey:** Support
- **Persona:** Support engineer
- **JTBD:** Decide whether one token or refresh family needs revocation.
- **Top task:** Choose single-token revoke or family-wide revoke with consequence clarity.
- **Who / What / Where / When / Why:** Who: support engineer; What: token detail; Where: token list; When: incident or lifecycle review; Why: take the narrowest safe revocation action.
- **Entry point:** Token list.
- **Primary decision:** Is the safe action single-token revoke or family revoke?
- **Primary action:** Review token.
- **Earned-place check:** Detail groups must distinguish token, refresh family, reuse detection, and destructive actions.
- **Empty state:** Token not found; return to filtered token list.
- **Error state:** Revoke failure, reuse-detected state, or missing token context must state what remains active.
- **Long-data state:** Family IDs, token handles, account IDs, client IDs, scopes, and timestamps must wrap.
- **Mobile risk:** Destructive actions and long identifiers can compete; incident summary must come first.
- **Theme risk:** Reuse-detected, revoked, expired, and danger states must use labels and accessible contrast.
- **Focus/motion risk:** Revoke controls, family revoke controls, and back links need visible focus; reduced-motion must preserve confirmation feedback.
- **Redaction/security check:** Never expose access token plaintext, refresh token plaintext, token hashes, cookies, auth codes, or secrets.
- **Unsupported action check:** Do not add token editing, reveal-token, or unbacked recovery controls.
- **Follow-up route:** `/admin/tokens`
- **Component/group fit:** `entity_header`, `description_list`, `confirmation_panel`, `long_value`, `status_badge`, and `action_group`.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** This route should teach the difference between single token revocation and family-wide response.

## Operate

### Scorecard: `/admin/interactions`

- **Route:** `/admin/interactions`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/interactions")`.
- **Journey:** Operate
- **Persona:** Support engineer
- **JTBD:** Inspect active authorization interaction queue state.
- **Top task:** Review pending login or consent interactions without inventing worker controls.
- **Who / What / Where / When / Why:** Who: support engineer; What: active interaction queue; Where: Operate > Interactions; When: live authorization work appears stuck, pending, denied, or expired; Why: understand queue state and route back to overview or support context.
- **Entry point:** Operate > Interactions.
- **Primary decision:** Which pending login or consent interaction is waiting?
- **Primary action:** Review interactions with read-only support truth.
- **Earned-place check:** Queue rows must clarify waiting state, age, client, and safe observation value.
- **Empty state:** No active interactions; there are no interactions at this time.
- **Error state:** Queue load failure should say observation failed, not imply interactions were changed.
- **Long-data state:** Interaction IDs, client IDs, return-to URLs, and timestamps must wrap.
- **Mobile risk:** This was a weak raw table; dense rows must preserve status, age, and client at 390px.
- **Theme risk:** Pending, denied, expired, and empty states need text labels and non-color status cues.
- **Focus/motion risk:** Queue row links or pivots need visible focus; live updates must not rely on motion.
- **Redaction/security check:** Do not expose authorization codes, cookies, session tokens, request objects, or raw sensitive return values.
- **Unsupported action check:** Read-only support truth only; no approve, deny, logout-now, requeue, retry, discard, or worker controls unless an existing backed domain API exists.
- **Follow-up route:** `/admin/overview`
- **Component/group fit:** `metric_grid`, `summary_stat`, `dense_resource_row`, `long_value`, `status_badge`, and `empty_state`.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Preserve Operate read-only support truth and avoid backend worker leakage.

### Scorecard: `/admin/device_authorizations`

- **Route:** `/admin/device_authorizations`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/device_authorizations")`.
- **Journey:** Operate
- **Persona:** Support engineer
- **JTBD:** Inspect device authorization queue and expiry state.
- **Top task:** Review pending or expiring device flow requests without exposing user codes.
- **Who / What / Where / When / Why:** Who: support engineer; What: device authorization queue; Where: Operate > Device Auth; When: device flow work is pending, approved, denied, consumed, or expired; Why: understand state and expiry pressure safely.
- **Entry point:** Operate > Device Auth.
- **Primary decision:** Which device flow requests are pending or expiring?
- **Primary action:** Review device authorizations with read-only support truth.
- **Earned-place check:** Rows must show state, expiry, client context, and read-only observation value.
- **Empty state:** No device authorizations; there are currently no device flow requests.
- **Error state:** Queue load failure should preserve route orientation and avoid implying mutation.
- **Long-data state:** Client IDs, device handles, verification URIs, and expiry timestamps must wrap.
- **Mobile risk:** This route was weak on mobile; list rows must keep queue state and expiry visible at 320px.
- **Theme risk:** Pending, approved, denied, consumed, expired, and empty states need text labels and safe contrast.
- **Focus/motion risk:** Any row link or support pivot needs visible focus; no motion-only expiry feedback.
- **Redaction/security check:** Do not expose user code plaintext, device code plaintext, tokens, cookies, auth codes, or secrets.
- **Unsupported action check:** Read-only support truth only; no approve, deny, logout-now, requeue, retry, discard, or worker controls unless an existing backed domain API exists.
- **Follow-up route:** `/admin/overview`
- **Component/group fit:** `metric_grid`, `summary_stat`, `dense_resource_row`, `long_value`, `status_badge`, and `empty_state`.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Device authorization proof must stay redaction-safe; user-code plaintext is banned evidence.

### Scorecard: `/admin/logouts`

- **Route:** `/admin/logouts`
- **Source truth:** `Lockspire.Web.AdminRouter` `live("/logouts")`.
- **Journey:** Operate
- **Persona:** Support engineer
- **JTBD:** Inspect logout propagation delivery outcomes and support pressure.
- **Top task:** Review failed, retryable, rendered, succeeded, and discarded logout deliveries.
- **Who / What / Where / When / Why:** Who: support engineer; What: logout delivery queue; Where: Operate > Logouts or overview support pivot; When: RP cleanup delivery needs support review; Why: understand durable back-channel and best-effort front-channel delivery outcomes without inventing controls.
- **Entry point:** Operate > Logouts or overview support queue.
- **Primary decision:** Which logout deliveries failed, retried, or were discarded?
- **Primary action:** Review logout deliveries with read-only support truth.
- **Earned-place check:** Rows must make status, attempts, target URI, delivery type, and next configuration pivot earn their place.
- **Empty state:** No logout deliveries; there are no logout deliveries at this time.
- **Error state:** Queue load failure must not imply deliveries were retried, discarded, or changed.
- **Long-data state:** Target URLs, client IDs, delivery IDs, and timestamps must wrap with no page-level overflow.
- **Mobile risk:** Logout queue scanability is a known candidate area; status and target URI must remain readable at 390px.
- **Theme risk:** Pending, retryable, rendered, succeeded, discarded, and failed states require text and contrast-safe semantic colors.
- **Focus/motion risk:** Row pivots and logout-propagation configuration links need visible focus and reduced-motion-safe feedback.
- **Redaction/security check:** Do not record cookies, token-looking strings, endpoint secrets, live tenant hostnames, or session data.
- **Unsupported action check:** Read-only support truth only; no retry, discard, approve, deny, logout-now, requeue, or worker controls unless an existing backed domain API exists.
- **Follow-up route:** `/admin/clients/:client_id/edit?workflow=logout-propagation`
- **Component/group fit:** `metric_grid`, `summary_stat`, `dense_resource_row`, URL `long_value`, `status_badge`, and `empty_state`.
- **Evidence class:** manual_browser_note
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning scorecard only, with no router, runtime, browser package, docs support-surface, or Hex package change.
- **Notes:** Candidate logout queue scanability work can inform later Operate polish, but Phase 121 does not add retry or discard UI.
