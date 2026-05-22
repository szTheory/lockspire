# Lockspire Epic Arc

**Created:** 2026-04-28
**Purpose:** Persist the longer-range project gameplan so milestone selection compounds from repo truth instead of restarting from scratch each cycle.

## Current Position

Lockspire already has a substantial embedded-provider preview surface:

- Authorization code + PKCE
- OIDC discovery and JWKS
- Userinfo, revocation, introspection, and refresh rotation
- PAR and PAR policy controls
- JAR request-object support (with decryption deferred)
- Dynamic Client Registration (RFC 7591/7592)
- Device Authorization Grant
- DPoP core for public and CLI clients (proof validation, replay protection, token binding)
- Generated host seams and Phoenix-native operator workflows
- Repo-truth release, support, and preview-posture discipline

That means the next milestones should optimize for **real integrator readiness**, not raw spec breadth.

## Strategic Priority

Move Lockspire from a serious, truthful preview into a preview that real Phoenix teams can adopt for third-party integrations with fewer trust gaps.

The priority order is:

1. Raise real-client trust on the surfaces already shipped.
2. Keep public claims narrow and repo-verifiable.
3. Preserve the embedded-library shape and host-owned seams.
4. Delay broader CIAM, hosted-auth, federation, and enterprise-platform scope unless the product thesis itself changes.

## Planned Arc

### 1. v1.7 — DPoP Core for Public and CLI Clients (Shipped)

Why next:
- Highest leverage security/trust wedge for the already-shipped browser, DCR, and device/CLI paths.
- Better fit than mTLS for the current product shape.
- Improves actual adoption readiness without requiring hosted infrastructure or enterprise PKI.

Scope:
- Proof validation
- Replay protection
- Token binding via `cnf`
- DPoP-aware auth-code, refresh, and device-code exchanges
- DPoP-aware `userinfo`
- Truthful discovery/docs
- Explicit operator/DCR rollout controls

### 2. v1.8 — Session Management & Conformance (Shipped)

Why next:
- Real-world integration demanded reliable backend-initiated session termination (RP-Initiated, Back-Channel, and Front-Channel Logout).
- Essential protocol strictness fixes for timestamps and OIDC compliance were required for a robust provider surface.

Scope:
- RP-Initiated Logout (`/end_session`)
- Durable Session IDs
- Automated Back-Channel Logout webhook propagation
- Front-Channel Logout iframe rendering
- OIDC timestamp enforcement

### 3. v1.9 — JAR Decryption (Shipped)

Why next:
- Partner interoperability pressure centers on request-object completeness, specifically encrypted transmission of PII or sensitive claims.

Scope:
- JWKS `enc` key publication and storage
- Nested JWT validation (JWE + JWS) in `Protocol.Jar`

### 4. v1.10 — FAPI 2.0 Security Profile (Shipped)

Why next:
- Provides a massive leap in "real-integrator trust" without the infrastructural complexity of mTLS.
- Capitalizes perfectly on our already-shipped PAR and DPoP features.
- Enables Lockspire to be used in high-value environments (banking, healthcare) while preserving the simple embedded-library ergonomics via a single `security_profile: :fapi_2_0_security` option.

Scope:
- Single-flag strict mode enforcement.
- Mandatory PAR and DPoP enforcement.
- Cryptographic restrictions (PS256/ES256 only).
- Strict redirect URI matching.
- Truthful FAPI 2.0 discovery metadata.

### 5. v1.11 / 1.0 GA Release — The Stabilization Epoch (Active)

Why next:
- Lockspire has massive capabilities (DPoP, FAPI 2.0, JAR, PAR, DCR) but requires a stable API contract, formal audits, and comprehensive documentation to establish trust for enterprise adopters.
- You cannot build a house on shifting sand; all subsequent protocol additions must be built on a stable, semantic-versioned contract to prevent host-app churn.

Scope:
- Finalizing public APIs (`@moduledoc`, `@doc`, and Typespecs).
- Ensuring telemetry events and operator seams are consistent.
- Formal security audit and API contract lockdown.
- Transition from preview posture to 1.0 GA.

### 6. Post-1.0 — The Microservices & Real-Time Epoch

**Token Exchange (RFC 8693):**
- High demand for API gateways and service meshes (impersonation, delegation).
- Will expose a Behaviour (e.g., `Lockspire.TokenExchangeValidator`) for host apps to provide domain-specific delegation logic without hardcoding policies.

**OpenID Connect CIBA (Client Initiated Backchannel Authentication):**
- Decoupled authentication maps perfectly to Elixir's concurrency and Phoenix PubSub/Channels.
- Provides a massive competitive advantage over other ecosystem frameworks that struggle with decoupled real-time auth.

### 7. v1.20 — Mutual TLS (RFC 8705) (Active)

Why next:
- After FAPI 2.0 Message Signing, the final high-leverage trust gap for "real integrator readiness" in regulated domains is Mutual TLS for client authentication and sender-constrained tokens.
- We have established a safe architectural pattern for embedded Phoenix apps behind TLS-terminating proxies: forcing the host to explicitly opt-in via a `Lockspire.MTLS.Extractor` plug, solving the infrastructural friction while preventing header spoofing.

Scope:
- Explicit extraction behavior (`CowboyDirectExtractor` and `ProxyHeaderExtractor`).
- `tls_client_auth` and `self_signed_tls_client_auth` methods.
- Certificate-bound tokens (`x5t#S256`).
- Truthful `mtls_endpoint_aliases` discovery metadata.

### 8. Future Epochs — Advanced Security & Authorization

- **Rich Authorization Requests (RFC 9328):** Powerful for complex domains, but still bleeding edge. Wait for standard patterns to emerge and utilize Ecto `embedded_schema` for robust, type-safe validation.

## Milestone Selection Rules

Use these rules when choosing what comes next:

1. Prefer real integrator leverage over checklist spec breadth.
2. Do not widen into hosted auth, generic CIAM, or account-system ownership.
3. Keep Lockspire-owned protocol state separate from host-owned login/session/branding policy.
4. Ship only what the repo can prove end to end.
5. Favor wedges that compound on already-shipped surfaces instead of opening unrelated product families.

## Explicit Non-Goals

These are not the intended arc unless the product thesis changes:

- Becoming a standalone hosted identity provider
- Becoming a full workforce identity or enterprise federation suite
- Taking over the host app's account, session, or login UX model
- Chasing certification breadth before the Phoenix embedded path is boring and trustworthy

## How to Use This File

- Update it at every milestone boundary if the priority arc changes.
- Use it with `.planning/PROJECT.md`:
  - `PROJECT.md` = current milestone and current validated state
  - `EPIC.md` = longer-range sequence and selection logic
- Use it to justify why a candidate milestone is next, not just what it would build.
