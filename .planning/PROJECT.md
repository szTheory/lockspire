# Lockspire

## What This Is

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It helps Phoenix SaaS teams turn an existing app into a trustworthy OAuth/OIDC provider for third-party developers without standing up a separate auth service or assembling protocol-sensitive pieces by hand. The host app owns accounts, login UX, layouts, branding, and product policy; Lockspire owns protocol correctness, token and consent domain logic, operator tooling, telemetry, and install flow.

## Core Value

A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Phoenix teams can install Lockspire into an existing app and complete a real authorization flow quickly.
- [ ] Lockspire delivers a secure authorization code + PKCE and OIDC baseline with strong defaults and clear protocol boundaries.
- [ ] Operators can manage clients, consents, tokens, keys, and incidents from a calm LiveView-native admin surface.
- [ ] Host apps keep ownership of accounts, login, branding, and product-specific policy through narrow explicit seams.
- [ ] The library ships with strong telemetry, auditability, docs, CI/CD, and release discipline.

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

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Ship Lockspire as a separate companion library, not a Sigra module | Keeps provider-side OAuth/OIDC concerns isolated from end-user authentication concerns | — Pending |
| Build as an embedded library rather than a standalone auth service | Matches Phoenix team deployment reality and preserves host control over UI, accounts, and app policy | — Pending |
| Use Phoenix LiveView for admin and consent UX | Gives operators and host apps first-class Phoenix-native surfaces instead of a foreign console | — Pending |
| Default to Ecto/Postgres durable storage with explicit seams for later adapters | Prioritizes correctness, auditability, and operational simplicity for v1 | — Pending |
| Optimize for a narrow v1 focused on auth code + PKCE, OIDC discovery/JWKS/userinfo, client management, consent, rotation, telemetry, and release readiness | Keeps the initial scope credible and avoids drifting into a heavyweight CIAM suite | — Pending |
| Treat PAR, dynamic client registration, device flow, stronger sender-constrained modes, and stronger certification profiles as later roadmap candidates | Preserves room for future protocol expansion without bloating the first milestone | — Pending |
| **Sigra ecosystem sequencing** | Finish **Phase 3 → 5 → 6** before public “Sigra + Lockspire” golden paths; document via **ECOSYSTEM-SIGRA.md** and **`docs/sigra-companion-host.md`** | — Pending |

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
*Last updated: 2026-04-23 — Ecosystem sequencing doc (**ECOSYSTEM-SIGRA.md**), **`docs/sigra-companion-host.md`**, **`mix lockspire.install --sigra-host`**, ROADMAP ecosystem note.*
