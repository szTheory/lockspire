# Lockspire

## What This Is

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It helps Phoenix SaaS teams turn an existing app into a trustworthy OAuth/OIDC provider for third-party developers without standing up a separate auth service or assembling protocol-sensitive pieces by hand. The host app owns accounts, login UX, layouts, branding, and product policy; Lockspire owns protocol correctness, token and consent domain logic, operator tooling, telemetry, and install flow.

## Core Value

A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Current State

Lockspire has now archived twenty-three planning milestones. Beyond the earlier embedded-provider, release-hardening, and protected-route work, the most recent sequence delivered FAPI 2.0 Message Signing in v1.19, Mutual TLS client authentication and certificate-bound tokens in v1.20, first-class Phoenix API route protection in v1.21, automatic DPoP nonce challenge/retry support in v1.22, and DCR-managed logout propagation metadata in v1.23.

Lockspire now supports a full embedded-provider-to-resource-server path: authorization code + PKCE, PAR, JAR request objects (including JWE decryption), DCR with logout propagation metadata management, device authorization, OIDC discovery/JWKS/userinfo, revocation, introspection, refresh rotation, DPoP with nonce-backed retry on shipped surfaces, strict FAPI 2.0 security mode, Token Exchange, OIDC CIBA (Poll, Ping, and Push), Resource Indicators, RAR, guarded remote `jwks_uri` resolution, `private_key_jwt`, mTLS client authentication, certificate-bound tokens, JARM, JWT introspection responses, and host Phoenix route protection for Lockspire-issued bearer, DPoP-bound, and MTLS-bound access tokens.

Lockspire is now starting milestone `v1.24 client_secret_jwt`, the current highest-priority remaining direct-client authentication gap in the milestone arc.

## Current Milestone: v1.24 client_secret_jwt

**Goal:** Add a narrow `client_secret_jwt` authentication slice on Lockspire-owned direct-client endpoints without widening the embedded-library shape or weakening current secret-handling posture.

**Target features:**
- Accept and verify `client_secret_jwt` assertions on the existing Lockspire-owned direct-client surfaces that already share client authentication.
- Keep verification strict on replay prevention, issuer-string `aud` handling, algorithm allowlists, and bounded expiry semantics.
- Publish truthful registration, discovery, admin, and support-surface posture for the shipped symmetric-JWT slice.

**Why now:** `v1.23` closed the DCR logout metadata gap, leaving `client_secret_jwt` as the most practical remaining direct-client auth gap without changing Lockspire's package boundaries or host-owned seams.

## Recently Shipped Milestone: v1.23 DCR Logout Metadata

**Goal:** Let self-service clients manage Lockspire's existing logout propagation metadata through DCR and RFC 7592 without broadening the product boundary.

**Delivered:**
- DCR create now accepts, validates, persists, and reads back `backchannel_logout_*` and `frontchannel_logout_*` metadata using the existing Lockspire logout truth model.
- RFC 7592 management updates now replace and clear the four logout metadata fields under full-replace semantics while preserving RAT rotation, provenance, and audit continuity.
- Repo-native protocol and controller proof now covers positive and negative logout metadata lifecycle behavior across create, read, and update flows.
- Support-surface, DCR lifecycle, operator, and maintainer docs now describe the shipped self-service logout slice truthfully without overstating front-channel guarantees.

## Archived Milestone Snapshot: v1.23 DCR Logout Metadata

**Goal:** Let self-service clients manage Lockspire's existing logout propagation metadata through DCR and RFC 7592 without broadening the product boundary.

**Target features:**
- Accept, validate, store, and expose `backchannel_logout_uri` plus `backchannel_logout_session_required` through DCR create/read/update flows.
- Accept, validate, store, and expose `frontchannel_logout_uri` plus `frontchannel_logout_session_required` through DCR create/read/update flows.
- Keep repo-native proof and support-truth docs aligned with Lockspire's existing asymmetric logout model: durable back-channel delivery and best-effort front-channel cleanup.

**Why now:** This milestone has shipped and is archived in `.planning/milestones/v1.23-ROADMAP.md` plus `.planning/milestones/v1.23-REQUIREMENTS.md`.

<details>
<summary>Previous milestone snapshot</summary>

### v1.22 DPoP Nonce Support

**Goal:** Add automatic DPoP nonce challenge and retry behavior across all shipped Lockspire DPoP validation surfaces.

**Delivered:**
- A shared stateless DPoP nonce primitive with strict authorization-server vs resource-server purpose separation.
- Retryable `use_dpop_nonce` behavior on Lockspire-owned `/token` and `/userinfo` surfaces.
- Nonce-aware host Phoenix protected-route enforcement through the shipped `VerifyToken -> EnforceSenderConstraints -> RequireToken` pipeline.
- Support-surface, onboarding, and protected-route docs that now describe the shipped nonce-backed DPoP slice truthfully.

</details>

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
- Deliver RFC 7591 `POST /register` intake bounded by operator policy without widening the embedded-library shape. Validated in Phase 26.
- Deliver operator policy controls for self-registration, Initial Access Tokens, and truthful discovery without widening the embedded-library shape. Validated across Phases 25-29.
- Deliver RFC 7592 client configuration management with `registration_access_token` rotation and admin-UI provenance. Validated in Phases 26-28.
- Implement `POST /device/code`, host-owned `/verify`, durable polling cadence enforcement, and `POST /token` device-code redemption with RFC 8628 outcomes. Validated across Phases 30-32.
- Generated-host proof, security posture, and support-truth docs for the device-flow slice were delivered and archived in the v1.6 milestone.
- Deliver DPoP core: proof validation, token binding, replay protection, and DPoP-aware issuance for authorization-code, refresh, and device-code exchanges. Validated across Phases 33-36.
- End-to-end proof, security posture, and support-truth docs for the shipped DPoP slice were delivered and archived in the v1.7 milestone.
- Session Management & RP-Initiated Logout workflows were verified and archived in the v1.8 milestone.
- Automated Back-Channel and Front-Channel Logout propagation mechanisms were verified and archived in the v1.8 milestone.
- Strict OIDC protocol validation and integer enforcement for timestamps were verified and archived in the v1.8 milestone.
- Implement RSA/EC encryption key management in `Storage.KeyStore` and advertise via JWKS, validated in Phase 40.
- Implement nested JWT validation (Sign-then-Encrypt) in `Protocol.Jar`, validated in Phase 40.
- Deliver single-flag configuration (`security_profile: :fapi_2_0_security`) to enable strict mode globally or per-client, validated in Phase 41.
- Enforce mandatory PAR usage and DPoP sender-constraining for token and userinfo endpoints when the profile is active, validated in Phase 41.
- Restrict cryptographic algorithms to `PS256` or `ES256` exclusively under the profile, validated in Phase 41.
- Strictly enforce exact redirect URI matching and expose FAPI 2.0 compliance in discovery metadata, validated in Phase 42.
- Delivered 1.0 GA stabilization including API contract lock, telemetry standardization, operator seams consistency, and formal security audit in the v1.11 milestone.
- Delivered OAuth 2.0 Token Exchange (RFC 8693) with host policy behavior and delegation depth enforcement in the v1.12 milestone.
- Implement OIDC CIBA Core: `/bc-authorize` endpoint, CIBA token grant type, and durable polling state machine. Validated across Phases 51-53.
- Deliver resilient CIBA notifications: Oban-backed webhook delivery for both Ping and Push modes, including direct token delivery in Push mode. Validated across Phases 51-53.
- Establish CIBA host seams: defined and integrated `Lockspire.Host` behaviours for out-of-band notification and user consent resolution. Validated across Phases 51-53.
- Support Rich Authorization Requests (RAR - RFC 9396) intake in PAR and Authorization pipelines. Validated in Phase 55.
- Deliver Resource Indicators (RFC 8707) for targeted audience claims and resource parameter validation. Validated in archived v1.14.
- Deliver Ecto-based RAR validation framework and durable storage for rich authorization details. Validated in archived v1.14.
- Expose rich authorization details via introspection and verify end-to-end flows. Validated in archived v1.14.
- Update Discovery metadata and provide executable documentation for the v1.14 advanced authorization surface. Validated in archived v1.14.
- Delivered 1.0.0 GA public release artifacts and post-release execution verification in archived v1.17 and v1.18.
- Delivered 1.0.0 GA public release artifacts and post-release execution verification in archived v1.17 and v1.18.
- Delivered FAPI 2.0 Message Signing support including JARM and JWT introspection responses in archived v1.19.
- Delivered Mutual TLS client authentication, certificate-bound tokens, and truthful MTLS discovery metadata in archived v1.20.
- Delivered first-class Phoenix API route protection for Lockspire-issued tokens in archived v1.21.
- Delivered automatic DPoP nonce challenge and retry support on Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline in archived v1.22.
- Delivered DCR registration intake, typed persistence, and truthful readback for Lockspire's shipped logout propagation metadata in Phase 85 of milestone v1.23.
- Delivered RFC 7592 logout metadata replacement/clear semantics, lifecycle proof, and support-truth docs in archived milestone v1.23.

### Active

- Add `client_secret_jwt` as a narrow direct-client authentication option on Lockspire-owned direct-client endpoints.
- Keep `client_secret_jwt` verification strict on replay prevention, issuer-string `aud`, bounded lifetime checks, and algorithm allowlists tied to the effective security posture.
- Expose truthful DCR, discovery, admin, and documentation posture for the shipped `client_secret_jwt` slice without broadening FAPI or higher-trust support claims.

### Out of Scope

- HTTP Message Signatures (RFC 9421) for the Token Endpoint — Not required by FAPI 2.0 Message Signing and adds immense complexity. Rely on DPoP.
- SAML IdP and LDAP/AD federation — expands the protocol and enterprise-systems surface far beyond the core OAuth/OIDC provider wedge.
- Hosted auth product or required separate process — the product value is embedded Phoenix deployment, not another service to run.
- End-user authentication primitives such as passwords, MFA, passkeys, and session ownership — those belong to Sigra or the host app.
- Full CIAM suite or "Keycloak for Elixir" breadth — Lockspire wins by staying narrow, trustworthy, and operator-capable.
- Mandatory theming engine — host apps should own layouts, copy, and branding through editable generated code.

## Context

Lockspire is a greenfield OSS library project with a substantial prep corpus in `prompts/` defining product thesis, domain language, market positioning, implementation shape, operator workflows, telemetry, release readiness, and security posture. The core target is Phoenix SaaS teams that need provider-side OAuth/OIDC for partner ecosystems, integration marketplaces, or Auth0 exit paths. The project should follow Doorkeeper-style install DX, node-oidc-provider-style protocol seriousness and extensibility, OpenIddict-style separation between core, storage, and host seams, and Rodauth-style security defaults.

The short-to-medium-term project arc is now explicit: finish the most leverage-heavy real-integrator trust wedges first, keep the public support posture narrow and truthful, and only then spend milestone budget on broader certification depth or lower-leverage auth-method expansion. `.planning/EPIC.md` is the durable record of that arc. With v1.16 complete, `v1.17` shifted from release-truth alignment in git to the real public release cut and post-publish verification, and `v1.18` proved it in production.

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
| Treat PAR, dynamic client registration, device flow, stronger sender-constrained modes, and stronger certification profiles as later roadmap candidates | Preserves room for future protocol expansion without bloating the first milestone | Deferred to later milestone planning |
| **Sigra ecosystem sequencing** | Finish **Phase 3 → 5 → 6** before public “Sigra + Lockspire” golden paths; document via **ECOSYSTEM-SIGRA.md** and **`docs/sigra-companion-host.md`** | Adopted in archived v1.0 milestone |
| Polish the current preview surface before adding more protocol breadth | The repo already has its core provider wedge; release trust is now the gating risk to adoption and velocity | Adopted in archived v1.1 milestone |
| Make PAR the first post-polish protocol wedge | PAR extends the existing auth-code flow with less product-shape drift than dynamic registration or device flow | Adopted and delivered by Phase 15 |
| Make Dynamic Client Registration the v1.5 wedge | DCR turns Lockspire from operator-tended into partner-buildable while reusing the narrow protocol-plus-operator-policy pattern | Adopted and delivered across Phases 25-29 |
| Make Device Authorization Grant the v1.6 wedge | Device flow extends the embedded provider into CLI and partner-device use cases while preserving the host-owned verification seam and shared token pipeline | Adopted and delivered by Phase 32 |
| Make DPoP the v1.7 wedge | DPoP raises the real-integrator security story across existing public/CLI paths without requiring hosted infrastructure or enterprise PKI and composes directly with the shipped device and DCR surfaces | Adopted at v1.7 milestone start |
| Persist the multi-milestone strategy in `.planning/EPIC.md` | Milestone selection should compound from repo truth and prior decisions rather than being rediscovered every cycle | Adopted at v1.7 milestone start |
| Transition to 1.0 GA | After shipping FAPI 2.0 Security Profile, the library has the necessary features and security depth to confidently drop preview status | Adopted at v1.11 milestone start |
| Add Token Exchange (RFC 8693) | Provides standard delegation and impersonation primitives for microservice patterns without custom grant types | Adopted at v1.12 milestone start |
| Add OpenID Connect CIBA | Provides decoupled authentication and real-time out-of-band notifications, leveraging Elixir's concurrency and Oban for resilient delivery | Adopted at v1.13 milestone start |
| Use Oban for resilient delivery | Ensures that CIBA webhooks (Ping/Push) and back-channel logouts are retriable and durable across system restarts | Adopted for v1.13 CIBA implementation |
| **Select RAR & Resource Indicators for v1.14** | Empowers Phoenix teams in complex domains (fintech, healthcare) and enables "Zero Trust" targeted tokens | Adopted at v1.14 milestone start |
| Target FAPI 2.0 Message Signing for v1.19 | Provides application-layer non-repudiation without mTLS infrastructure overhead, building off existing JWS/JWE primitives | Adopted at v1.19 milestone start |
| Start `v1.23 DCR Logout Metadata` as a narrow self-service wedge | The logout propagation runtime already exists; the highest-leverage remaining gap is letting partner-managed clients register and manage the existing metadata without widening beyond current logout truth | Adopted and archived in milestone v1.23 |
| Activate `v1.24 client_secret_jwt` as the current milestone | The remaining leverage-heavy gap is a practical direct-client authentication option that fits the current embedded-library boundary when kept narrow and truthfully documented | Adopted at v1.24 milestone start |

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
*Last updated: 2026-05-24 for v1.24 milestone start*
