# Phase 153: Configure & Support Page Refinement - Context

**Gathered:** 2026-10-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine the existing Lockspire admin Configure and Support experiences so staff can understand the task, see the facts that affect a decision, and find the next supported action. Cover all 29 existing route scorecards and the Phase 151 `/admin/clients/new` route (30 current paths). Preserve the embedded-library boundary and all OAuth/OIDC, credential, revocation, and queue behavior.

</domain>

<decisions>
## Implementation Decisions

### User-facing language and hierarchy
- **D-01:** Write for the staff member's job and familiarity, not the implementation. Use short, concrete language that explains a choice, consequence, or next step; do not use “operator” as visible audience copy.
- **D-02:** Remove duplicate page and section titles, generic introductions, “Measured from…” provenance, and other copy that does not help interpret a value or act. Do not move low-value copy into tooltips.
- **D-03:** Keep OAuth/OIDC terms where they identify a real concept or affect a setup decision; introduce unfamiliar terms in plain context and preserve exact distinctions between stored records and what those records prove.
- **D-04:** Every current path receives a rendered review. Phase 151's dedicated client-registration page is included with its focused title, form, return path, validation recovery, and copy-once result.

### Components, actions, and visual system
- **D-05:** Keep the existing Signal Cyan identity, Phoenix components, semantic design tokens, native controls, and dependency tree. Do not introduce a third-party UI library or new font/dependency.
- **D-06:** Remove eyebrows/kickers above headings. Refactor `page_hero/1` and its callers so it does not require or render an eyebrow; preserve a title, supporting sentence, summary, or actions only when each has a distinct purpose.
- **D-07:** Use primary styling for the principal safe task, secondary for navigation and recovery, and danger for consequential destructive actions with their existing confirmation.
- **D-08:** Keep useful information and controls visible. Use existing component patterns and spacing; avoid nested panels and decorative metric rows. Give the native theme selector at least a 16px right-side caret inset.
- **D-09:** Add motion only when it clarifies a real state change or orientation; otherwise preserve the current reduced-motion-safe behavior.

### Safety and verification
- **D-10:** Keep interaction, device-authorization, and logout queues read-only. Preserve exact filters, outcome meanings, unavailable-versus-empty behavior, redaction, copy-once credential handling, confirmation semantics, and distinct revocation scopes.
- **D-11:** Use synthetic Billingo demo data for browser captures. Never capture one-time credentials, user/device codes, private key material, or other secrets.
- **D-12:** Phase 153 improves Configure and Support copy/layout. Capture a redaction-safe baseline for all 30 paths before its source changes; Phase 154 captures all 30 final paths, using a full-page screenshot when readable or one capture per meaningful section when needed. Phase 154 also owns viewport, zoom, theme, keyboard, and comparison proof. Add browser automation to CI only for reliable recurring regressions.

### the agent's Discretion
- Choose exact route copy, section ordering, existing component composition, and spacing within `153-UI-SPEC.md`; verify wording against the route's data and supported handlers.
- Select focused tests for each edited route and add only stable assertions that protect a meaningful recurring contract.
- Correct an inherited Phase 151/152 route only when a current rendered regression is demonstrated, then keep its prior behavior covered by tests.

</decisions>

<specifics>
## Specific Ideas

- The user's screenshot critique called out unnecessary “Measured from…” notes, jargon such as “posture” and unexplained “issuer”, redundant “Overview” and provider-overview headings, unclear reuse/logout implications, repeated client-registration descriptions, and a theme-select caret too close to the border.
- The user specifically asked to separate client creation from the client inventory. Phase 151 already implements `/admin/clients/new`; Phase 153/154 must verify the served demo reflects that source.
- The synthetic Billingo adopter is a demonstration host, not a real customer or production account.
</specifics>

<canonical_refs>
## Canonical References

### Scope and route behavior
- `.planning/REQUIREMENTS.md` — v1.42 requirements and safety boundaries.
- `.planning/ROADMAP.md` — Phase 153/154 goals and success criteria.
- `.planning/phases/151-focused-client-registration-settings/151-CONTEXT.md` and `151-01-SUMMARY.md`, `151-02-SUMMARY.md` — dedicated registration, task context, action styling, and copy-once behavior.
- `.planning/phases/152-overview-and-queue-state-clarity/152-CONTEXT.md`, `152-RESEARCH.md`, and plan summaries — truthful overview/queue states and read-only boundaries.
- `.planning/milestones/v1.32-phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` — the 29 existing route jobs, data states, follow-up pivots, and risks.

### Design and implementation contract
- `.planning/phases/153-configure-support-page-refinement/153-UI-SPEC.md` — approved visual, interaction, copy, and 30-path rendered-review contract.
- `.planning/phases/153-configure-support-page-refinement/153-UI-CHECK.md` — seven-dimension Impeccable/UI contract checker approval.
- `.planning/phases/153-configure-support-page-refinement/153-RESEARCH.md` — source-grounded implementation seams, tests, and risks.
- `.impeccable/critique/2026-10-11T17-47-19Z__ire-web-live-admin-overview-live-index-ex-d708f649.md` — earlier overview critique; not a current visual verification result.
- `brandbook/notes/decision-log.md`, `brandbook/notes/accessibility-checks.md`, and `brandbook/tokens/tokens.css` — current identity, semantic tokens, and accessibility constraints.
- `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/admin_css.ex`, and `lib/lockspire/web/live/admin_layout_live.ex` — reusable components, styling, and shell heading ownership.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Web.Components.AdminComponents` — form, list, detail, alert, confirmation, button, and page-hero components; refactor the page hero to remove the eyebrow before reuse.
- `Lockspire.Web.Admin.CSS` and brandbook tokens — existing responsive layout, theme roles, focus, semantic state colors, and native form control styling.
- Existing LiveView tests and AdminProof route contracts — per-route assertions for data scope, filters, redaction, confirmations, and supported actions.

### Established Patterns
- The embedded admin shell owns the sole page H1; route content uses H2/H3 only for distinct sections.
- Component forms preserve submitted values and associate field errors; one-time credentials are displayed and cleared under the existing copy-once lifecycle.
- The demo runs with synthetic Billingo records and gives a browser surface for rendered review.

### Integration Points
- Mounted routes come from `Lockspire.Web.AdminRouter`; current proof also includes the logout-propagation workflow query and the Phase 151 `/admin/clients/new` route.
- Admin layout and shared component/CSS changes can affect every route, so compile, focused route tests, theme/CSS contracts, and browser evidence must cover the shared seam.
</code_context>

<deferred>
## Deferred Ideas

- CR-01 plaintext private signing-key storage remains a separate critical security design and is not solved by this UI milestone.
- New OAuth/OIDC capabilities, queue mutation controls, host-owned authentication/branding changes, a new design system, third-party visual dependencies, and open-ended critique loops remain out of scope.
- Further personal copy or visual feedback can be handled as a bounded follow-up after the user reviews this cleaned baseline.
</deferred>

---

*Phase: configure-support-page-refinement*
*Context gathered: 2026-10-12*
