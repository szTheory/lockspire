# Lockspire

## What This Is

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It helps Phoenix SaaS teams turn an existing app into a trustworthy OAuth/OIDC provider for third-party developers without standing up a separate auth service or assembling protocol-sensitive pieces by hand. The host app owns accounts, login UX, layouts, branding, and product policy; Lockspire owns protocol correctness, token and consent domain logic, operator tooling, telemetry, and install flow.

## Core Value

A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Current State

Lockspire has now archived six planning milestones. The embedded provider foundation from v1.0 remains intact, v1.1 closed the release-hardening work needed to make repo-truth QA and trusted release claims defensible, v1.2 delivered the narrow PAR wedge plus the remaining release-runtime hygiene needed to keep the preview lane boring, v1.3 added PAR policy controls, and v1.4 added the narrow JAR request-object slice without widening the embedded-library shape.

At archive time, the package version in `mix.exs` is `0.2.0`, the protected release path has real proof behind it, and the checked-in Release Please path no longer depends on the deprecated Node 20 marketplace runtime. Even so, the public product posture should still be treated as preview until repeated green release discipline makes a stronger claim boring.

Lockspire can now accept pushed authorization requests at `/par`, consume its own PAR-issued `request_uri` values inside the existing authorization code + PKCE path, enforce global and per-client PAR policy controls, and validate the shipped JAR request-object slice while keeping JAR-04 decryption deferred.

v1.5 delivered Dynamic Client Registration (DCR) RFC 7591/7592 with operator policy controls, Initial Access Tokens, and truthful discovery without widening the embedded-library shape.

## Requirements

### Validated

- Embedded-library install and host-owned integration seams were delivered in the archived v1.0 milestone.
- Authorization code + PKCE, OIDC discovery/JWKS/userinfo, revocation, introspection, and refresh rotation were delivered in the archived v1.0 milestone.
- Operator/admin workflows for clients, consents, tokens, and keys were delivered in the archived v1.0 milestone.
- Security defaults, telemetry, auditability, redaction, and negative-path coverage were delivered in the archived v1.0 milestone.
- Canonical onboarding, executable docs, CI/release assets, and supported-surface policy were delivered in the archived v1.0 milestone.
- Repo-truth QA, contributor gate closure, trusted protected release proof, and preview-posture drift fences were delivered in the archived v1.1 milestone.
- PAR-backed authorization consumption on the existing authorization code + PKCE path was validated in Phase 15.
- Discovery, support docs, and SECURITY wording now describe only the shipped PAR slice, validated in Phase 15.
- PAR milestone closure and release-runtime hygiene were validated in Phase 16, including warning-free checked-in release automation.
- Deliver RFC 7591 `POST /register` intake bounded by operator policy without widening the embedded-library shape. Validated in Phase 26: protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
- Deliver operator policy controls for self-registration (allowlists, defaults, on/off, optional initial access tokens). Validated in Phase 26: protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
- Deliver RFC 7592 client configuration management with `registration_access_token` rotation and admin-UI provenance. Validated in Phase 26: protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
- Advertise `registration_endpoint` truthfully and bound SECURITY/support docs to the shipped DCR slice. Validated in v1.5 milestone.
- Close v1.5 with end-to-end verification, telemetry/audit coverage, and full traceability for shipped DCR requirements. Validated in v1.5 milestone.

### Active

(None currently)

### Out of Scope

- SAML IdP and LDAP/AD federation — expands the protocol and enterprise-systems surface far beyond the core OAuth/OIDC provider wedge.
- Hosted auth product or required separate process — the product value is embedded Phoenix deployment, not another service to run.
- End-user authentication primitives such as passwords, MFA, passkeys, and session ownership — those belong to Sigra or the host app.
- Full CIAM suite or "Keycloak for Elixir" breadth — Lockspire wins by staying narrow, trustworthy, and operator-capable.
- Mandatory theming engine — host apps should own layouts, copy, and branding through editable generated code.

## Context

Lockspire is a greenfield OSS library project with a substantial prep corpus in `prompts/` defining product thesis, domain language, market positioning, implementation shape, operator workflows, telemetry, release readiness, and security posture. The core target is Phoenix SaaS teams that need provider-side OAuth/OIDC for partner ecosystems, integration marketplaces, or Auth0 exit paths. The project should follow Doorkeeper-style install DX, node-oidc-provider-style protocol seriousness and extensibility, OpenIddict-style separation between core, storage, and host seams, and Rodauth-style security defaults. The first milestone should get a host Phoenix app to client registration, authorization code flow, code redemption, token inspection, and usable operator workflows without requiring the host to design protocol internals.

## Constraints

- **Tech stack**: Embedded Phoenix/Elixir library with Phoenix LiveView admin and consent UX — the product must feel native inside a host Phoenix app.
- **Storage**: Ecto/Postgres is the default durable path — protocol truth, auditability, and operational clarity should live in durable storage rather than process state.
- **Security**: Secure-by-default OAuth/OIDC posture is mandatory — PKCE S256, exact redirect matching, hashed client secrets, single-use short-lived codes, refresh rotation, no implicit flow, no `alg=none`.
- **Architecture**: Strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and operator UI — this keeps the public API small and the library maintainable.
- **Host seam**: Host apps own accounts, login UX, layouts, branding, and policy — Lockspire must not take over the host's authentication model.
- **Release quality**: Executable docs, warnings-as-errors, CI/CD, changelog hygiene, and publish-from-release discipline are part of the product — release trust is a core feature for an auth library.
- **Verification posture**: Default phase closure to executable proof in tests and CI — human UAT is only valid when automation is blocked by a real external boundary such as protected release credentials, third-party trust, or physical hardware.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Ship Lockspire as a separate companion library, not a Sigra module | Keeps provider-side OAuth/OIDC concerns isolated from end-user authentication concerns | Adopted in archived v1.0 milestone |
| Build as an embedded library rather than a standalone auth service | Matches Phoenix team deployment reality and preserves host control over UI, accounts, and app policy | Adopted in archived v1.0 milestone |
| Use Phoenix LiveView for admin and consent UX | Gives operators and host apps first-class Phoenix-native surfaces instead of a foreign console | Adopted in archived v1.0 milestone |
| Default to Ecto/Postgres durable storage with explicit seams for later adapters | Prioritizes correctness, auditability, and operational simplicity for v1 | Adopted in archived v1.0 milestone |
| Optimize for a narrow v1 focused on auth code + PKCE, OIDC discovery/JWKS/userinfo, client management, consent, rotation, telemetry, and release readiness | Keeps the initial scope credible and avoids drifting into a heavyweight CIAM suite | Adopted in archived v1.0 milestone |
| Treat PAR, dynamic client registration, device flow, stronger sender-constrained modes, and stronger certification profiles as later roadmap candidates | Preserves room for future protocol expansion without bloating the first milestone | Deferred to next milestone planning |
| **Sigra ecosystem sequencing** | Finish **Phase 3 → 5 → 6** before public “Sigra + Lockspire” golden paths; document via **ECOSYSTEM-SIGRA.md** and **`docs/sigra-companion-host.md`** | Adopted in archived v1.0 milestone |
| Polish the current preview surface before adding more protocol breadth | The repo already has its core provider wedge; release trust is now the gating risk to adoption and velocity | Adopted in archived v1.1 milestone |
| Make PAR the first post-polish protocol wedge | PAR extends the existing auth-code flow with less product-shape drift than dynamic registration or device flow | Adopted and delivered by Phase 15 |
| Include the lingering release-automation runtime warning in v1.2 scope rather than treating it as indefinite background debt | PAR should not land on top of a release path already known to drift toward a GitHub runtime cutoff | Adopted at v1.2 milestone start |
| Keep PAR support limited to Lockspire-issued `request_uri` values in v1.2 | Preserves truthful support claims and avoids smuggling broader request-object semantics into the first PAR milestone | Adopted and delivered by Phase 15 |
| Wrap Release Please in a checked-in composite action | Future runtime migrations should stay behind a stable, reviewable workflow contract | Adopted and delivered by Phase 16 |
| Make Dynamic Client Registration the v1.5 wedge | DCR turns Lockspire from operator-tended into partner-buildable, which is the gating capability for the partner-ecosystem and integration-marketplace core target; it reuses the established narrow-protocol-plus-operator-policy pattern from PAR/PAR-policy/JAR | Adopted at v1.5 milestone start |
| Bound v1.5 to RFC 7591/7592 with operator policy and exclude software statements, external-IdP federation, and FAPI bundles | Preserves truthful support claims and avoids importing CIAM-suite breadth into the first DCR slice | Adopted at v1.5 milestone start |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-27 after v1.5 milestone*