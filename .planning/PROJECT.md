# Lockspire

## What This Is

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It helps Phoenix SaaS teams turn an existing app into a trustworthy OAuth/OIDC provider for third-party developers without standing up a separate auth service or assembling protocol-sensitive pieces by hand. The host app owns accounts, login UX, layouts, branding, and product policy; Lockspire owns protocol correctness, token and consent domain logic, operator tooling, telemetry, and install flow.

## Core Value

A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Current State

Lockspire has now archived twenty-six planning milestones. Beyond the earlier embedded-provider, release-hardening, and protected-route work, the most recent shipped sequence delivered FAPI 2.0 Message Signing in v1.19, Mutual TLS client authentication and certificate-bound tokens in v1.20, first-class Phoenix API route protection in v1.21, automatic DPoP nonce challenge/retry support in v1.22, DCR-managed logout propagation metadata in v1.23, a narrow `client_secret_jwt` direct-client authentication slice in v1.24, advanced-setup support-burden reduction in v1.25, and host integration/operator boundary hardening in v1.26.

Lockspire now supports a full embedded-provider-to-resource-server path: authorization code + PKCE, PAR, JAR request objects (including JWE decryption), DCR with logout propagation metadata management, device authorization, OIDC discovery/JWKS/userinfo, revocation, introspection, refresh rotation, DPoP with nonce-backed retry on shipped surfaces, strict FAPI 2.0 security mode, Token Exchange, OIDC CIBA (Poll, Ping, and Push), Resource Indicators, RAR, guarded remote `jwks_uri` resolution, `private_key_jwt`, narrow `client_secret_jwt` on shipped direct-client endpoints, mTLS client authentication, certificate-bound tokens, JARM, JWT introspection responses, and host Phoenix route protection for Lockspire-issued bearer, DPoP-bound, and MTLS-bound access tokens.

Between feature milestones, Lockspire's default posture remains a sustaining GA release train: keep `main` green, keep release-truth artifacts aligned, and let patch-eligible merged changes flow toward the next patch release through the maintained automated lane. Future feature milestones run on milestone branches and merge through one PR to `main` as described in `.planning/DEVELOPMENT-TRAIN.md`.

The most recently shipped feature milestone, `v1.26 Host Integration & Operator Boundary Hardening`, landed in `lockspire 1.2.0`: it improved the first real Phoenix SaaS adoption path around account/claims wiring, first-client bootstrap, protected-route proof, and host-guarded operator/admin mounting without adding protocol breadth. `v1.27 Phoenix Resource Server Token Acceptance` is now the deliberately opened next feature milestone, resolving the unfinished design tension between Lockspire-issued stored access tokens and the JWT-bearer-oriented Phoenix protected-resource plug.

## Recently Shipped Milestone: v1.26 Host Integration & Operator Boundary Hardening

**Goal:** Make the first real Phoenix SaaS adoption path clearer without adding protocol breadth.

**Delivered:**
- Added `Lockspire.Web.AdminRouter` as a bounded admin-only router that hosts can mount behind their own operator-auth pipeline.
- Updated generated router and account-resolver scaffolding so account lookup, stable subject claims, tenant checks, product authorization, and Sigra-specific wiring stay host-owned.
- Improved first-client CLI output with token endpoint auth truth and practical next steps for proving authorization-code + PKCE.
- Added a compact SaaS adoption recipe and release-readiness assertions that pin the host-owned account/operator boundary.

**Why now:** `v1.25` made the shipped advanced setup story coherent. The next highest-leverage adoption wedge was not more protocol breadth; it was reducing first-adopter ambiguity at the host seam.

## Recently Shipped Milestone: v1.25 Support-Burden Reduction

**Goal:** Reduce advanced setup ambiguity on already-shipped high-trust surfaces so adopters can configure, diagnose, and support Lockspire without source-diving or relying on maintainer tribal knowledge.

**Delivered:**
- Lockspire now classifies remote `jwks_uri` incidents through one shared diagnostics model and exposes the same bounded-reactive support story across runtime, doctor, admin, and docs.
- `mix lockspire.doctor remote-jwks` and the admin client detail Remote JWKS panel now provide one calm remediation path and ownership split without widening install-time verification.
- The canonical mTLS, logout propagation, and protected-route guidance now states one explicit Lockspire-owned versus host-owned support boundary.
- Release-contract assertions and representative runtime regressions now fail loudly if the advanced-setup support story drifts from shipped behavior.

**Why now:** `v1.24` closed the last practical direct-client auth gap. The remaining high-leverage work was support cost and setup ambiguity on advanced surfaces Lockspire already shipped.

## Current Milestone: v1.27 Phoenix Resource Server Token Acceptance

**Goal:** Make it obvious which Lockspire-issued token shape a host Phoenix API should accept, how that relates to `Lockspire.Plug.VerifyToken`, and what CI proof backs the blessed path — without conflating stored opaque access tokens with JWT bearer route-protection fixtures.

**Target features:**
- One authoritative answer for which Lockspire-issued token shape protects a host Phoenix API route, expressed in the shipped `Lockspire.Plug.VerifyToken` contract.
- A blessed adoption recipe spanning docs, the adoption demo, and generated-host guidance so first-adopter ambiguity at the RS token seam is gone.
- CI proof — repo-native — that the blessed RS token acceptance path stays aligned across runtime, plug, docs, demo, and generated host.
- Honest separation of stored opaque access tokens (token-endpoint shape) from JWT bearer route-protection (RS verifier shape), with explicit operator/adopter language about when each applies.

**Why now:** `v1.26` delivered the host integration seam and adoption demo, but in doing so exposed an unfinished design tension: the demo uses Lockspire's issued stored access token against Lockspire `/userinfo`, while the Phoenix protected-resource plug remains JWT-bearer-oriented. That ambiguity is now a real first-adopter trip hazard — and the earmark documented in `STATE.md` and `.planning/ROADMAP.md` flagged this as the next feature-sized wedge once adopter evidence justifies leaving sustainment.

**Explicit non-goals (do not broaden into):**
- Hosted auth / CIAM productization.
- Service mesh or gateway productization, generic API management.
- SAML / LDAP federation, auth-method parity chasing.
- Certification-breadth chasing beyond what the shipped surface already claims.

**Sustainment boundary:** This milestone is the deliberate exception to `milestone: none`. Patch-train work continues in parallel on `main`. Feature work for v1.27 runs on `milestone/v1.27-phoenix-rs-token-acceptance` per `.planning/DEVELOPMENT-TRAIN.md`.

## Release Train Default

**Goal:** Preserve Lockspire as a boring sustained GA library: patch-on-merge for eligible fixes, one maintainer hygiene gate, one CI drift fence, and one canonical release ledger instead of milestone churn.

**Default rules:**
- `milestone: none` is the normal GSD state.
- Patch-eligible merged changes flow toward the next patch release through Release Please on `main`.
- The train only moves when `main` is green and `./scripts/maintainer/repo_hygiene_check.sh` reports no `BLOCK`.
- New feature milestones should open only when explicit adopter evidence shows work that is larger than patch/support/release-hygiene sustainment, and should use one `milestone/vNEXT-short-slug` branch plus one PR to `main`.

**Why now:** Lockspire is near-done for its intended scope. At this maturity level, friction and ambiguity in repo/release hygiene are a bigger adoption risk than missing another protocol wedge, so the default should encode stability rather than roadmap momentum.

## Archived Milestone Snapshot: v1.24 client_secret_jwt

**Goal:** Add a narrow `client_secret_jwt` authentication slice on Lockspire-owned direct-client endpoints without widening the embedded-library shape or weakening current secret-handling posture.

**Delivered:**
- Lockspire-owned direct-client surfaces now accept valid `client_secret_jwt` assertions through one shared runtime path instead of implicitly treating all JWT assertions as `private_key_jwt`.
- The symmetric JWT verifier preserves the existing secret-at-rest posture by storing sealed verifier material alongside the hashed client secret, and it enforces HS256-only, issuer-string audience, bounded lifetime, replay, and FAPI-denial rules.
- DCR, RFC 7592, discovery, and admin/operator surfaces now publish one coherent `client_secret_jwt` plus `HS256` truth without exposing verifier material or claiming broader support than the runtime actually ships.
- Canonical docs, maintainer guidance, discovery metadata, release-contract tests, and full regression proof now all agree on the narrow support boundary for the shipped `client_secret_jwt` slice.

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
- Delivered narrow shared-runtime `client_secret_jwt` support with sealed verifier material and strict HS256, replay, audience, and FAPI-denial posture in Phase 88 of milestone v1.24.
- Delivered coherent `client_secret_jwt` registration, RFC 7592, discovery, and admin truth in Phase 89 of milestone v1.24.
- Delivered canonical docs, release-contract proof, and milestone-close evidence for the narrow `client_secret_jwt` support slice in archived milestone v1.24.

- Delivered actionable diagnostics and remediation truth for `jwks_uri` rotation on Lockspire's shipped remote-JWKS surface in archived milestone v1.25.
- Delivered one canonical mTLS extraction, logout propagation, and protected-route setup support story in archived milestone v1.25.
- Delivered repo-native proof that advanced setup docs, diagnostics, and runtime behavior stay aligned in archived milestone v1.25.

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
| Ship `v1.25 Support-Burden Reduction` and default to stop-or-reassess afterward | The highest-leverage remaining work was support truth on already-shipped advanced setup surfaces; beyond that, roadmap inertia is a bigger risk than missing protocol breadth | Adopted at v1.25 milestone close |
| Treat the next work as release-truth polish rather than a new feature milestone | The remaining repo risk is stale public release posture and gate drift, not a missing core OAuth/OIDC wedge | Adopted after the v1.25 completion assessment |
| Add a repo-owned hygiene gate after the `1.1.0` release | A mature OSS library needs one disciplined pre-release command and one CI drift fence more than more branch folklore | Adopted during post-`1.1.0` release follow-through |
| Default Lockspire to a standing GA release train | A mature auth library should feel released by default: `milestone: none`, patch-on-merge for sustaining work, and a durable release ledger instead of milestone inertia | Adopted after the `1.1.0` public release verification |
| Use one milestone PR for future feature work | Keeps `main` as the release-train source of truth while preserving GSD milestones for larger feature development | Adopted after the `1.1.0` release-train baseline |
| Put green-main and support-truth work before `v1.26` | The next repo-local risks are CI trust and public-truth drift; feature work should start only after those are boring again | Adopted during post-PR #31 roadmap assessment |
| Make host integration/operator boundary hardening the next feature candidate | Account/claims recipes, client bootstrap, admin-route boundaries, and operator diagnostics improve real Phoenix adopter outcomes more than adjacent protocol breadth | Recommended for the next `$gsd-new-milestone` decision |
| Add a host-guarded admin-only router for v1.26 | The generated host needs a concrete way to put operator auth in front of `/lockspire/admin` without putting the public OAuth/OIDC endpoints behind staff auth | Adopted for v1.26 implementation |
| Deliberately leave sustainment and open `v1.27 Phoenix Resource Server Token Acceptance` | The adoption demo shipped in PR #44 exposed an unfinished design tension between Lockspire-issued stored access tokens and the JWT-bearer-oriented `Lockspire.Plug.VerifyToken`. Resolving it is a higher-leverage adopter wedge than additional protocol breadth, and qualifies as the adopter-evidenced exception to the sustaining-train default | Adopted at v1.27 milestone start (2026-05-27) |
| Resolve v1.27 with Branch A + JWT-default issuance | Narrow `Lockspire.Plug.VerifyToken` to RFC 9068 `at+jwt` only and flip the default access-token format from opaque to `:jwt` for AC/refresh/device/CIBA paths. Opaque remains available as an explicit per-client opt-in and continues to back `/userinfo` and `/introspect`. Canon-aligned (the prompts/ corpus explicitly endorses `access_token_format: :jwt` as the secure default), ecosystem-aligned (every modern RS library written post-RFC-9068 defaults to JWT at the plug), and structurally avoids the auto-detection footgun class documented in Ory oathkeeper #257 / Spring Boot's startup-exception guardrail. Branch B (dual-verifier plug with shape-dispatch) and introspection-at-the-RS as the host-API seam both explicitly rejected | Adopted at v1.27 milestone start (2026-05-27); recorded in `.planning/REQUIREMENTS.md` design-decision section |

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
*Last updated: 2026-05-27 — Phase 97 (contract-docs-first) complete: canonical pipeline pinned across four sites with SHA-256 content-hash invariants*
