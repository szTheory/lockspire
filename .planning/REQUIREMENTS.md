# v1.29 Requirements: Admin UI Journey & Design-System Deep Polish

## Goal

Take the shipped admin UI from coherent baseline to a deliberately mapped operator product where every route, component, and state supports a clear persona, job, next action, and safety boundary.

## Personas And Jobs

- **Provider operator:** keep the embedded OAuth/OIDC provider healthy, understand attention-worthy state, and find the right workflow quickly.
- **Support engineer:** investigate account, client, consent, token, interaction, device, and logout incidents without source-diving or exposing secrets.
- **Security/platform owner:** configure issuer posture, client overrides, keys, DCR policy, and high-trust settings with clear blast-radius cues.
- **Partner-onboarding operator:** manage DCR policy, Initial Access Tokens, self-registered clients, RAT rotation, and handoff context.

## Requirements

### Journey Contract

- [x] **JOURNEY-01**: Operators can understand the admin UI's top-level model as Orient, Configure, Support, and Operate, with each route assigned to exactly one primary journey.
- [x] **JOURNEY-02**: Each admin route documents its persona, JTBD, entry point, primary decision, primary action, empty state, risk state, and follow-up route in one repo-local journey contract.
- [x] **JOURNEY-03**: Overview routes operators by task and urgency, not only by object type, so a new operator can choose the next workflow without prior Lockspire knowledge.
- [x] **JOURNEY-04**: Journey labels, page titles, hero copy, empty states, and action labels use one vocabulary across docs and LiveView surfaces.
- [x] **JOURNEY-05**: DCR onboarding, DCR policy, IAT inventory, IAT minting, and RAT rotation are clearly connected without collapsing onboarding and security-policy jobs into one ambiguous page.
- [x] **JOURNEY-06**: Logout workflows consistently distinguish browser post-logout redirect URIs from RP cleanup endpoints used for back-channel and front-channel logout propagation.

### Design System

- [x] **DESIGN-01**: Admin CSS keeps the existing `lockspire-admin-*` BEM/design-token architecture and avoids inline layout styles, one-off overrides, and arbitrary class naming.
- [x] **DESIGN-02**: Shared Phoenix components cover repeated page primitives: page hero, task/attention cards, filter bars, metric cards, responsive resource rows, status badges, empty states, confirmation panels, copy-once secret panels, and safe/destructive action groups.
- [x] **DESIGN-03**: Design tokens cover spacing, control size, radius, shadow, typography, status color, focus, z-index, and motion with names that make the Lockspire admin brand repeatable.
- [x] **DESIGN-04**: Button, link, badge, alert, table/list, form, and confirmation patterns behave consistently across desktop and mobile admin routes.
- [x] **DESIGN-05**: Motion is restrained, purposeful, performant, and disabled or simplified under `prefers-reduced-motion`.
- [x] **DESIGN-06**: Raw hex colors and repeated layout constants are moved toward semantic tokens where doing so reduces drift without creating a theming engine.

### Support And Operations Polish

- [ ] **OPS-01**: Support pages help operators investigate by account, client, status, incident, and next safe action without leaking secret material.
- [ ] **OPS-02**: Operations pages make waiting, retrying, failed, expired, and completed protocol state scannable without forcing operators to decode raw tables.
- [ ] **OPS-03**: Long identifiers, client names, URLs, timestamps, statuses, and counts stay readable on mobile without incoherent overlap or page-level horizontal scrolling.
- [ ] **OPS-04**: Risky actions remain visually distinct, confirmation-backed, and copy-clear about the consequence and reversibility of the action.
- [ ] **OPS-05**: Support and operations pages provide pivot context by client, account/subject, token family, consent, session, or delivery identifier when that context exists.

### Configure And Onboarding Polish

- [ ] **CONFIG-01**: Client detail and edit workflows group identity, posture, endpoints, credentials, DCR/RAT context, logout, and lifecycle actions in a predictable order that survives dense mobile layouts.
- [ ] **CONFIG-02**: Security, DCR, IAT, and key lifecycle pages expose current posture, exception pressure, and next actions with consistent page structure.
- [ ] **CONFIG-03**: Demo seed data exercises healthy, warning, incident, empty, disabled, self-registered, retryable, revoked, expired, long-value, and copy-once states across the admin UI.

### Proof And Documentation

- [ ] **PROOF-01**: Operator admin docs describe the final journey model and remain subordinate to `docs/supported-surface.md`.
- [ ] **PROOF-02**: Desktop and mobile screenshots cover every admin route in the approved route surface after the polish pass.
- [ ] **PROOF-03**: Design-system regression tests fail if admin routes drift from the journey model, reusable component contract, reduced-motion contract, or no-inline-style rule.
- [ ] **PROOF-04**: The milestone closes with compile, diff-check, admin LiveView tests, design-system contract tests, screenshot inventory, browser click-through evidence, and mobile no-page-overflow proof.

## Future Requirements

- A host-configurable theming engine.
- A third-party developer portal UI.
- Role-based staff permissions inside Lockspire.
- New protocol surfaces unrelated to admin UI operator experience.

## Out Of Scope

- **Tailwind migration:** v1.29 doubles down on the existing BEM/design-token architecture.
- **Standalone admin service:** Lockspire remains an embedded Phoenix library mounted behind host-owned operator auth.
- **Host-owned account/operator authentication UX:** staff sessions, MFA, role checks, tenant policy, layouts, and product branding remain host-owned.
- **Protocol breadth:** no SAML, LDAP/AD federation, hosted auth, full CIAM, or new OAuth/OIDC flow expansion.
- **Unbounded animation polish:** motion must serve orientation, feedback, and state continuity, not decoration.

## Traceability

| Requirement | Phase |
|-------------|-------|
| JOURNEY-01 | 107 |
| JOURNEY-02 | 107 |
| JOURNEY-03 | 107 |
| JOURNEY-04 | 107 |
| JOURNEY-05 | 107 |
| JOURNEY-06 | 107 |
| DESIGN-01 | 108 |
| DESIGN-02 | 108 |
| DESIGN-03 | 108 |
| DESIGN-04 | 108 |
| DESIGN-05 | 108 |
| DESIGN-06 | 108 |
| OPS-01 | 109 |
| OPS-02 | 109 |
| OPS-03 | 109 |
| OPS-04 | 109 |
| OPS-05 | 109 |
| CONFIG-01 | 109 |
| CONFIG-02 | 109 |
| CONFIG-03 | 110 |
| PROOF-01 | 110 |
| PROOF-02 | 110 |
| PROOF-03 | 110 |
| PROOF-04 | 110 |
