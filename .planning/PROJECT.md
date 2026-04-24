# Lockspire

## What This Is

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It helps Phoenix SaaS teams turn an existing app into a trustworthy OAuth/OIDC provider for third-party developers without standing up a separate auth service or assembling protocol-sensitive pieces by hand. The host app owns accounts, login UX, layouts, branding, and product policy; Lockspire owns protocol correctness, token and consent domain logic, operator tooling, telemetry, and install flow.

## Core Value

A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Current Milestone: v1.1 Release Hardening

**Goal:** Make the current Lockspire surface boring to verify, ship, and trust before expanding protocol scope.

**Target features:**
- Repo-wide QA, CI, and release-readiness checks are green from repo truth rather than carve-outs.
- Trusted release-path verification is exercised and documented around the protected Hex publish workflow.
- Public docs, support posture, and release claims stay tightly bounded to the implemented preview surface.

## Current State

The first Lockspire milestone is complete and archived as [v1.0](milestones/v1.0-ROADMAP.md) at the planning level. The repo now contains the embedded install path, authorization code + PKCE flow, OIDC discovery/JWKS/userinfo, refresh rotation, revocation, introspection, LiveView-native operator tooling, and the security/observability baseline described by the milestone.

That said, the public release claim should still remain **v0.1 preview**, not `1.0`. Phase 10 closed the reopened contributor-gate gap by restoring the maintained `mix ci` lane and backfilling Phase 07 gate verification, but trusted Hex publish proof is still required before a full `1.0` claim is warranted.

## Next Milestone Goals

- Exercise the trusted Hex publish and release path end to end.
- Keep the public preview posture and docs aligned to what the repo can actually prove today.
- Re-audit v1.1 once the trusted release proof is recorded so the milestone can close without caveats.

## Requirements

### Validated

- Embedded-library install and host-owned integration seams were delivered in the archived v1.0 milestone.
- Authorization code + PKCE, OIDC discovery/JWKS/userinfo, revocation, introspection, and refresh rotation were delivered in the archived v1.0 milestone.
- Operator/admin workflows for clients, consents, tokens, and keys were delivered in the archived v1.0 milestone.
- Security defaults, telemetry, auditability, redaction, and negative-path coverage were delivered in the archived v1.0 milestone.
- Canonical onboarding, executable docs, CI/release assets, and supported-surface policy were delivered in the archived v1.0 milestone.

### Active

- [x] Repo-wide QA and release gates are green enough to support repeated preview releases without exceptions. Validated in Phase 10: Contributor Gate Recovery.
- [ ] Trusted release-path verification is exercised in the intended publish environment.
- [ ] Public docs, workflow contracts, and supported-surface claims remain synchronized to the implemented preview surface.
- [ ] PAR is the default next protocol-expansion milestone after release hardening, but it is not implemented and not supported in v1.1.

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
| Polish the current preview surface before adding more protocol breadth | The repo already has its core provider wedge; release trust is now the gating risk to adoption and velocity | Adopted for v1.1 milestone |
| Make PAR the first post-polish protocol wedge | PAR extends the existing auth-code flow with less product-shape drift than dynamic registration or device flow | Deferred to v1.2 planning; not implemented and not supported in v1.1 |

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
*Last updated: 2026-04-24 — Phase 10 restored the maintained contributor gate, kept v1.1 focused on release hardening, and left trusted release proof as the remaining closure gap before re-audit.*
