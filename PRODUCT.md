# Lockspire Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Phoenix application teams adopt Lockspire to become an OAuth/OIDC provider inside their existing product. They own integration, deployment, account behavior, and product-specific authorization policy.

The primary admin UI audience is the authorized technical provider operator: an engineer or platform owner configuring integrations, operating the provider, and investigating authorization problems. Support and security teammates also use the interface and need clear domain language, understandable consequences, and useful diagnostic context without having to read implementation code. Partner-onboarding operators manage client registration and access credentials.

End users signing in, granting consent, authorizing a device, or managing connected applications interact with host-owned account experiences. They are a separate audience from staff using the operator UI.

The maintainer confirmed this audience priority on 2026-10-09.

## Product Purpose

A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

Lockspire supplies protocol correctness, durable authorization state, secure defaults, integration helpers, and operator tools. Successful adoption means a team can install and verify the embedded provider, connect clients, and operate it while retaining ownership of its application and account experience.

For operators, success means understanding the relevant state, finding the affected client or authorization, and completing the appropriate supported action with clear consequences and feedback. Common jobs should be straightforward, with sufficient depth for expert investigation.

## Positioning

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. Its distinguishing integration model is a narrow host seam: the host retains accounts, login UX, layouts, branding, and product policy while Lockspire owns protocol and authorization-domain behavior.

The product remains a separate companion library. It does not require a standalone authentication service and is not a full CIAM, SAML, or LDAP/AD platform. The canonical description of supported capability is [docs/supported-surface.md](docs/supported-surface.md); design and marketing work must stay within that contract.

## Operating Context

The operator UI consists of Phoenix LiveViews mounted through `Lockspire.Web.AdminRouter` behind the host's operator authentication and authorization pipeline. The host owns staff sessions, MFA, role checks, tenant policy, and access policy around those routes.

Existing jobs fall into four connected journeys:

- **Orient:** understand provider state and choose the next useful investigation or configuration task.
- **Configure:** manage clients, redirects, logout settings, credentials, signing keys, registration, and issuer or client security policy.
- **Support:** find and inspect consent grants and tokens, understand client and lifecycle context, and revoke the appropriate authorization.
- **Operate:** inspect authorization interactions, device authorization requests, and logout delivery state. These queues have intentionally read-only controls.

Operators move between inventories, object details, configuration forms, and related evidence. The UI must work with empty inventories, dense records, long identifiers and URLs, missing or failed observations, and consequential actions. Support narrow screens and browser zoom while retaining productive desktop layouts.

The repository's adoption demo is a fictional Phoenix SaaS host called Billingo, with synthetic accounts and clients. It is a local integration and inspection environment, not a hosted Lockspire product or production deployment guide. Its startup and login instructions are in [docs/adoption-demo.md](docs/adoption-demo.md).

## Capabilities and Constraints

Lockspire provides the supported OAuth/OIDC flows and endpoints, client and consent management, token lifecycle, signing-key management, operator policy workflows, telemetry, and Phoenix installation/verification helpers. Detailed protocol support and limitations remain in the supported-surface contract rather than being duplicated here.

Security and ownership boundaries are product behavior:

- Preserve PKCE S256 by default, exact redirect URI matching, hashed client secrets, short-lived single-use authorization codes, and refresh rotation with family-wide revocation on reuse. Implicit flow and `alg=none` are excluded.
- Preserve host-owned accounts, login/consent UX, outer layouts and branding, and product-specific authorization decisions.
- Preserve credential redaction, copy-once secret behavior, and accurate confirmation and consequence text. Retained screenshots and diagnostic evidence must not expose credentials or other sensitive material.
- Keep distinct authorization actions distinct: revoking a consent grant, a token, or a refresh token family must not be presented as interchangeable operations.
- Keep interaction, device, and logout queues read-only unless a separate capability change explicitly introduces a supported operation. Visual refinement must not invent approve, deny, retry, discard, or worker controls.
- Distinguish a failed or unavailable observation from a successful empty result. Feedback must describe what the operation or evidence actually establishes.
- Scope admin styling and interactions to the embedded surface. Existing shared Phoenix components and runtime tokens are the implementation base; host applications must not need a frontend-stack replacement or global CSS reset.
- Component labs, stress fixtures, browser evidence, and design tooling remain maintainer infrastructure, outside the published runtime support contract.

## Terminology and Voice

Use concrete, consistent operator language across navigation, headings, fields, actions, and feedback. Preserve protocol terms when they identify an actual concept, and expand unfamiliar abbreviations when helpful. Explanations should help the operator decide or act, rather than describe CSS, implementation structure, or the development process.

Important distinctions:

- A **client** is a registered application; a client identifier and a client secret are different data with different disclosure rules.
- A **consent grant**, an **access token**, a **refresh token**, and a **refresh token family** represent different authorization and lifecycle concepts.
- **Dynamic client registration (DCR) onboarding** and **DCR policy** are connected but separate jobs. Initial access tokens and registration access tokens have different purposes.
- **Post-logout redirect URIs** are browser destinations; **logout propagation URIs** are relying-party cleanup endpoints. Back-channel delivery and best-effort front-channel behavior must not imply the same proof of remote success.
- Requested, accepted, completed, failed, expired, revoked, empty, and unknown states must retain their actual meanings.

Voice is calm, direct, concise, and specific. Use domain nouns and clear verbs; avoid promotional filler, generic AI copy, exaggerated reassurance, and repeated explanations.

## Brand Commitments

Lockspire's name, logo assets, and implemented identity are the starting point for refinement. The existing [brand book](brandbook/README.md) and [brand decisions](brandbook/notes/decision-log.md) record the shipped identity and distinguish illustrative assets from product behavior.

The requested work refines the established interface. Missing Impeccable design documentation is not evidence of a new product or permission to replace its visual identity. The host's own branding remains under host control.

## Evidence on Hand

- [Project context](.planning/PROJECT.md), [supported surface](docs/supported-surface.md), and [operator guide](docs/operator-admin.md) describe product truth and ownership boundaries.
- [Admin router](lib/lockspire/web/admin_router.ex) and [route scorecards](.planning/milestones/v1.32-phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md) provide the existing surface and job inventory.
- [Shared components](lib/lockspire/web/components/admin_components.ex), [runtime CSS](lib/lockspire/web/admin_css.ex), and [internal fixtures](test/support/lockspire/web/admin_lab/fixtures.ex) supply implementation and realistic state examples.
- [UI refinement preflight](.planning/UI-MILESTONE-PREFLIGHT.md) records current source findings, earlier UI work, sibling-project lessons, and the requested next direction. Its findings are not a fresh visual verification result.
- Existing tests and archived reports support specific recorded behaviors. Historical screenshot files are not a current browser baseline, and an evidence-record parser does not itself prove rendered quality.

Fresh rendered inspection remains outstanding. This product record does not establish that the local demo is currently running, that every route has passed fresh browser verification, or that the product has an accessibility or protocol certification.

## Product Principles

1. Make the next useful action clear while retaining diagnostic depth for expert users.
2. Use familiar controls and consistent domain language; make structure serve the task.
3. Represent state and consequences honestly, especially when evidence is missing or an action is consequential.
4. Protect credentials and preserve the narrow ownership boundary between library and host.
5. Keep responsive, accessible behavior coherent across everyday and adverse states; motion should clarify feedback without delaying the task.

## Accessibility & Inclusion

Preserve keyboard operation, visible focus, properly associated labels and errors, non-color-only status cues, and readable contrast in light, dark, and system-selected appearance. Existing route scorecards call for AA contrast; that is an acceptance target, not a certification claim.

Support browser zoom, narrow-screen reflow, long content, accessible diagnostic values, and reduced-motion preferences. Responsive layout must not rely on shrinking text until it becomes difficult to read. State changes and validation feedback should remain understandable without animation or pointer hover.
