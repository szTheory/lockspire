# Phase 92: Advanced Setup Support Truth - Research

**Researched:** 2026-05-25 [VERIFIED: current session date]
**Domain:** Advanced setup support-contract alignment for mTLS, protected Phoenix API routes, and logout propagation in an embedded Phoenix OAuth/OIDC library [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`]
**Confidence:** HIGH [VERIFIED: conclusions are grounded in codebase/runtime seams, current Hex package metadata, and official RFC/OIDC specifications]

<user_constraints>
## User Constraints (from CONTEXT.md)

**Source:** Verbatim copy from `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md` [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`]

### Locked Decisions
- **D-01:** Keep `docs/supported-surface.md` as the single canonical public support contract for advanced setup claims and non-claims.
- **D-02:** Treat adjacent guides (`docs/mtls-host-guide.md`, `docs/protect-phoenix-api-routes.md`, `docs/install-and-onboard.md`, `docs/operator-admin.md`, and related scenario docs) as derived setup/remediation guides that defer to the canonical support contract instead of restating a competing capability matrix.
- **D-03:** Follow the same split Phase 91 established for runtime diagnostics: prose support truth lives in the canonical docs, while any doctor/admin/runtime status surfaces consume shared normalized truth primitives rather than inventing local vocabularies.
- **D-04:** Preserve the boundary between install/onboarding diagnostics and runtime support incidents: `mix lockspire.verify` remains the canonical install-wiring check; doctor-style or admin diagnostics remain runtime-incident/status surfaces only.
- **D-05:** Publish one canonical two-pattern mTLS setup story:
  - direct TLS termination in the host Phoenix app using `Lockspire.MTLS.Extractor.CowboyDirect`; and
  - trusted reverse-proxy header extraction using `Lockspire.MTLS.Extractor.ProxyHeader`.
- **D-06:** Make the host/infrastructure ownership split explicit everywhere:
  - the host app or deployment environment owns TLS termination, trusted forwarding, and header anti-spoofing;
  - Lockspire owns certificate verification against client registration data plus token/certificate binding enforcement once the certificate reaches the request seam.
- **D-07:** Keep the generic `Lockspire.MTLS.Extractor` behaviour extensibility as an escape hatch for unusual deployments, but do not elevate arbitrary custom extractors to first-class support-contract parity with the two shipped patterns.
- **D-08:** Keep DPoP as the ergonomic default sender-constraining story for typical Phoenix SaaS deployments; mTLS remains a supported advanced path for teams that can satisfy the infrastructure prerequisites without expecting Lockspire to hide them.
- **D-09:** Standardize on one canonical protected-route pipeline for shipped host Phoenix API routes:
  `Lockspire.Plug.VerifyToken -> Lockspire.Plug.EnforceSenderConstraints -> Lockspire.Plug.RequireToken`.
- **D-10:** Treat `Lockspire.Plug.EnforceSenderConstraints` as part of the canonical supported pipeline even on bearer-only routes because it is a no-op for unconstrained tokens and preserves future correctness when clients adopt DPoP or mTLS.
- **D-11:** Keep the current responsibility split explicit:
  - `VerifyToken` authenticates the token and applies route-level scope/audience restrictions as protocol facts;
  - `EnforceSenderConstraints` applies DPoP and mTLS sender-binding checks when the token requires them;
  - `RequireToken` is the sole HTTP boundary that halts and renders OAuth-style failure responses.
- **D-12:** Keep the protected-route support claim narrow: Lockspire supports Lockspire-issued token validation on host Phoenix routes through the documented plug pipeline, not generic gateway middleware or third-party issuer validation.
- **D-13:** Preserve the current failure contract as part of the supported surface:
  - missing/invalid token and audience restriction failures remain `401 invalid_token`;
  - valid-but-under-scoped tokens remain `403 insufficient_scope`;
  - DPoP sender-constraint failures remain `401` with the DPoP challenge;
  - DPoP nonce retry remains `401 use_dpop_nonce` plus `DPoP-Nonce`.
- **D-14:** Standardize on one asymmetric logout truth model:
  - back-channel logout is the canonical durable propagation path;
  - front-channel logout is best-effort browser choreography only.
- **D-15:** Keep `/end_session/complete` as the protocol-owned fork point after the host app clears its own browser session; Lockspire then owns token revocation, persisted propagation intent, back-channel enqueueing, and rendering the front-channel cleanup page.
- **D-16:** Preserve the current metadata boundary: DCR and admin/operator workflows manage the four existing logout propagation metadata fields for the already-shipped runtime, but they do not create a broader “new logout system.”
- **D-17:** Keep post-logout redirect URIs explicitly separate from logout propagation URIs in every guide, admin help text, and support surface.
- **D-18:** Make prerequisites part of the support truth: back-channel durability depends on the shipped Oban + Req path and correct RP endpoint metadata; front-channel success is never reported as remotely verified logout completion.
- **D-19:** Shift the user’s preference left as repo policy for GSD: discuss/plan/review work on already-shipped surfaces should default to research-first, assumption-first, one-shot recommendation bundles instead of menus of medium-value choices.
- **D-20:** Escalate only when a choice materially changes product boundary, public support claims, operator responsibilities, security posture, API shape, or runtime guarantees.
- **D-21:** For support-truth and docs phases, future GSD artifacts should declare:
  - canonical authority;
  - derived surfaces;
  - surfaces that must not broaden the contract.

### Claude's Discretion
- Exact section titles, wording, and cross-link placement across the touched guides, provided the canonical-authority hierarchy stays intact.
- The exact shape of any small shared support-truth primitive layer for admin/doctor/status summaries, provided it normalizes runtime states without turning all support prose into code constants.
- The exact amount of repetition needed in docs/admin copy to keep dangerous prerequisites and asymmetries legible without making the writing noisy.

### Deferred Ideas (OUT OF SCOPE)
- Broader mTLS deployment automation, trust-proxy autodetection, or infrastructure-specific installation helpers
- A hosted-style readiness dashboard or richer admin observability plane for every advanced setup surface
- Generic protected-resource middleware beyond the shipped host Phoenix plug pipeline
- Any stronger front-channel logout reliability claim or RP-success verification model
- Broader documentation architecture rewrites outside the surfaces needed to keep Phase 92 truthful
</user_constraints>

<phase_requirements>
## Phase Requirements

**Source:** Requirement IDs and descriptions copied from `.planning/REQUIREMENTS.md` [VERIFIED: `.planning/REQUIREMENTS.md`]

| ID | Description | Research Support |
|----|-------------|------------------|
| GUIDE-01 | A host team enabling mTLS client authentication can identify the required certificate extraction prerequisites, explicit host responsibilities, and supported deployment patterns before rollout. | Use one two-pattern mTLS story only: `CowboyDirect` for direct TLS termination and `ProxyHeader` for trusted forwarded certs; make TLS termination, trusted forwarding, and header anti-spoofing explicit host/infrastructure duties; keep custom extractors documented as escape hatches, not first-class support patterns. [VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `lib/lockspire/mtls/extractor.ex`; VERIFIED: `test/lockspire/mtls/cowboy_direct_extractor_test.exs`; VERIFIED: `test/lockspire/mtls/proxy_header_extractor_test.exs`; CITED: https://www.rfc-editor.org/info/rfc8705/] |
| GUIDE-02 | A host team protecting Phoenix API routes can follow one canonical setup path for `VerifyToken -> EnforceSenderConstraints -> RequireToken`, including the expected `401 invalid_token` and `403 insufficient_scope` behavior. | Plan around the existing three-plug order, keep `EnforceSenderConstraints` mandatory in the documented path, and preserve the current wire contract proven by unit tests and the generated-host integration test. [VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `lib/lockspire/plug/verify_token.ex`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; VERIFIED: `lib/lockspire/plug/require_token.ex`; VERIFIED: `test/lockspire/plug/verify_token_test.exs`; VERIFIED: `test/lockspire/plug/enforce_sender_constraints_test.exs`; VERIFIED: `test/lockspire/plug/require_token_test.exs`; VERIFIED: `test/integration/phase81_generated_host_route_protection_e2e_test.exs`] |
| GUIDE-03 | An operator configuring logout propagation can understand the current back-channel durability, front-channel best-effort semantics, and required metadata/setup prerequisites from one coherent support story. | Keep one asymmetric logout story everywhere: `/end_session/complete` is the protocol-owned fork point, back-channel is durable via Oban + Req, front-channel is best effort only, and DCR/admin merely manage the four existing metadata fields. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/operator-admin.md`; VERIFIED: `docs/dynamic-registration.md`; VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`; CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html; CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
| TRUTH-01 | Canonical docs, operator/admin wording, and any doctor or diagnostic surfaces describe the same supported truth for `jwks_uri` rotation, mTLS setup, logout propagation, and protected-route configuration. | Preserve `docs/supported-surface.md` as authority, push adjacent guides to defer to it, and reuse shared runtime truth primitives only for admin/doctor surfaces. Phase 91’s install-vs-runtime split is the direct precedent. [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/private-key-jwt-host-guide.md`; VERIFIED: `lib/mix/tasks/lockspire.verify.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`] |
| TRUTH-02 | Advanced setup guidance clearly states Lockspire-owned behavior versus host-owned or infrastructure-owned behavior so support boundaries stay explicit. | The planner should require explicit ownership subsections in each touched guide and operator surface: Lockspire owns protocol verification and durable propagation; hosts own TLS termination, forwarding safety, business authorization, account/session UX, and deployment operations. [VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/operator-admin.md`; VERIFIED: `AGENTS.md`; VERIFIED: `.planning/METHODOLOGY.md`] |
</phase_requirements>

## Summary

Phase 92 is a contract-alignment phase, not a protocol-expansion phase. The codebase already ships the core mechanics that the milestone wants to clarify: an explicit mTLS extraction seam, a stable three-plug protected-route pipeline, a protocol-owned `/end_session/complete` logout fork, a runtime/install diagnostic split, and admin surfaces that already expose some of the intended truth. The planning risk is therefore documentation drift and mixed authority, not missing runtime primitives. [VERIFIED: `lib/lockspire/mtls/extractor.ex`; VERIFIED: `lib/lockspire/plug/verify_token.ex`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; VERIFIED: `lib/lockspire/plug/require_token.ex`; VERIFIED: `lib/mix/tasks/lockspire.verify.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`; VERIFIED: `docs/supported-surface.md`]

The strongest repo signal is that `docs/supported-surface.md` already claims the advanced setup surface, but some adjacent guides still restate it with softer or competing wording. The most obvious example is protected routes: the canonical guide documents `VerifyToken -> EnforceSenderConstraints -> RequireToken`, while `docs/supported-surface.md` still describes `EnforceSenderConstraints` as optional. That mismatch directly conflicts with the locked Phase 92 decision to make the sender-constraint plug part of the canonical supported pipeline even for bearer-only routes. [VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`]

The planner should treat this phase as three coordinated edits: first, establish the authority hierarchy and normalize support wording; second, make each advanced surface state its ownership split and runtime guarantees explicitly; third, add or tighten repo-truth assertions only where they are needed to freeze the new contract in place for Phase 93. No new dependency or subsystem is required. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`; VERIFIED: `mix.exs`]

**Primary recommendation:** Make `docs/supported-surface.md` the explicit source of truth, rewrite adjacent guides and operator/admin wording as derived support guides, and remove every place where the repo currently implies stronger mTLS abstraction, looser protected-route setup, or more reliable front-channel logout than the runtime actually provides. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/operator-admin.md`; VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| mTLS TLS termination and certificate capture | Frontend Server / Deployment Edge | Browser / Client | The certificate only exists at the TLS termination boundary; Lockspire can validate and bind it only after the host app or proxy extracts it and forwards it safely. [VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `lib/lockspire/mtls/extractor.ex`; CITED: https://www.rfc-editor.org/info/rfc8705/] |
| mTLS client-certificate verification and token binding enforcement | API / Backend | Frontend Server / Deployment Edge | Lockspire verifies registered certificate constraints and checks certificate thumbprints against token confirmation data in backend plugs/runtime code. [VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; VERIFIED: `test/lockspire/plug/enforce_sender_constraints_test.exs`; CITED: https://www.rfc-editor.org/info/rfc8705/] |
| Protected Phoenix API route token validation | API / Backend | Frontend Server / Deployment Edge | `VerifyToken`, `EnforceSenderConstraints`, and `RequireToken` run in the host Phoenix plug stack and enforce OAuth wire behavior at request time. [VERIFIED: `lib/lockspire/plug/verify_token.ex`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; VERIFIED: `lib/lockspire/plug/require_token.ex`] |
| Business authorization on protected routes | Host App Backend | — | Lockspire validates protocol facts, but the host app still decides tenant policy, controller behavior, and whether the route should exist. [VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `AGENTS.md`] |
| RP-initiated logout completion and propagation orchestration | API / Backend | Database / Storage | `/end_session/complete` is the protocol-owned handoff that persists propagation intent, revokes token state, and enqueues durable back-channel work. [VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `lib/lockspire/protocol/logout_propagation.ex`] |
| Back-channel logout delivery durability | Database / Storage | API / Backend | Durable delivery depends on persisted logout state plus Oban-backed async processing and Req-based HTTP delivery. [VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/operator-admin.md`; VERIFIED: `lib/lockspire/workers/backchannel_logout_delivery_worker.ex`] |
| Front-channel logout cleanup | Browser / Client | API / Backend | Front-channel logout uses user-agent iframe choreography and therefore cannot claim remote success or durability. [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`; CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html; CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] |
| Runtime diagnosis for advanced incidents | API / Backend | Admin UI / CLI | Phase 91 established doctor/admin as runtime support surfaces separate from install verification. [VERIFIED: `lib/mix/tasks/lockspire.verify.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`; VERIFIED: `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | Repo constraint `~> 1.8.5`; current Hex release `1.8.7` on 2026-05-06 [VERIFIED: `mix.exs`; VERIFIED: `mix hex.info phoenix`] | Host router, plugs, controllers, docs surface integration | The advanced setup surfaces are already encoded as Phoenix plugs, routes, templates, and docs; Phase 92 should refine those seams rather than introduce another framework layer. [VERIFIED: `lib/lockspire/plug/verify_token.ex`; VERIFIED: `lib/lockspire/plug/require_token.ex`; VERIFIED: `docs/protect-phoenix-api-routes.md`] |
| Phoenix LiveView | Repo constraint `~> 1.1.28`; current stable Hex release `1.1.30` on 2026-05-05 [VERIFIED: `mix.exs`; VERIFIED: `mix hex.info phoenix_live_view`] | Admin/operator truth surfaces | Operator wording and support cues already live in LiveView admin components, so alignment work belongs there instead of a separate admin plane. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`] |
| Ecto SQL | Repo constraint `~> 3.13.5`; current Hex release `3.14.0` on 2026-05-19 [VERIFIED: `mix.exs`; VERIFIED: `mix hex.info ecto_sql`] | Durable protocol and support state | Logout propagation and client metadata truth are persisted, which matches Lockspire’s durable-truth posture. Phase 92 should keep documenting persisted truth, not implied session state. [VERIFIED: `docs/dynamic-registration.md`; VERIFIED: `.planning/METHODOLOGY.md`] |
| Oban | Repo constraint `~> 2.21.0`; current Hex release `2.22.1` on 2026-04-30 [VERIFIED: `mix.exs`; VERIFIED: `mix hex.info oban`] | Durable back-channel logout delivery | The supported logout story explicitly depends on durable queued delivery rather than synchronous browser-only behavior. [VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/operator-admin.md`] |
| Req | Repo constraint `~> 0.5`; current Hex release `0.5.18` on 2026-05-20 [VERIFIED: `mix.exs`; VERIFIED: `mix hex.info req`] | Back-channel logout HTTP delivery | The current logout contract already names Req as the outbound delivery client, so Phase 92 should document that prerequisite instead of hiding it. [VERIFIED: `docs/install-and-onboard.md`] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Bandit | Repo constraint `~> 1.11`; current Hex release `1.11.1` on 2026-05-13 [VERIFIED: `mix.exs`; VERIFIED: `mix hex.info bandit`] | Phoenix HTTP runtime option | Relevant only insofar as direct TLS termination is one of the two supported mTLS extraction patterns. [VERIFIED: `docs/mtls-host-guide.md`] |
| JOSE | Repo constraint `~> 1.11` [VERIFIED: `mix.exs`] | JWT/JWK work in runtime and tests | Relevant for token verification tests and logout token proof, but Phase 92 should not add new JOSE abstractions because the issue is support wording, not crypto capability. [VERIFIED: `test/lockspire/plug/verify_token_test.exs`; VERIFIED: `test/lockspire/protocol/logout_token_test.exs`] |
| NimbleOptions | Repo constraint `~> 1.1` [VERIFIED: `mix.exs`] | Plug option validation | Keep using it for narrow option contracts such as `mtls_extractor`, `audience`, and `audiences` rather than hand-parsing options. [VERIFIED: `lib/lockspire/plug/verify_token.ex`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing docs + admin + mix task stack | New readiness dashboard or richer diagnostics subsystem | Rejected for Phase 92 because the locked scope is support-truth alignment on shipped surfaces, not a new operator product. [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`] |
| Existing mTLS extractor seam | Autodetected proxies or infrastructure-specific helpers | Rejected because the current product boundary keeps TLS termination and trusted forwarding host-owned. [VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `AGENTS.md`] |
| Existing protected-route plug pipeline | Gateway middleware or generic third-party issuer validation | Rejected because the supported surface is intentionally narrow to Lockspire-issued tokens on host Phoenix routes. [VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/supported-surface.md`] |

**Installation:** No new dependencies are recommended for Phase 92; plan to use the existing repo stack only. [VERIFIED: `mix.exs`; VERIFIED: `.planning/ROADMAP.md`]

## Architecture Patterns

### System Architecture Diagram
```text
Host deploy / proxy TLS edge
  -> certificate present or absent
  -> direct TLS termination OR trusted forwarded header
  -> Phoenix request
     -> VerifyToken
        -> token valid? -> route scope/audience facts assigned
        -> invalid/missing -> structured access_token error assigned
     -> EnforceSenderConstraints
        -> DPoP proof / mTLS cert required? -> verify sender binding
        -> no binding required -> no-op
        -> binding fails -> structured sender-constraint error assigned
     -> RequireToken
        -> valid token -> host controller runs
        -> invalid token -> 401 OAuth response
        -> under-scoped token -> 403 OAuth response

Host browser logout
  -> host clears its own session
  -> redirect to /end_session/complete
     -> Lockspire revokes token/session state
     -> persist logout propagation intent
     -> enqueue back-channel delivery via Oban + Req
     -> render front-channel iframe cleanup page
        -> browser may or may not complete all iframe loads
```
[VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`]

### Recommended Project Structure
```text
docs/
├── supported-surface.md           # Canonical public support contract
├── mtls-host-guide.md             # Derived mTLS setup/remediation guide
├── protect-phoenix-api-routes.md  # Derived protected-route setup guide
├── install-and-onboard.md         # Canonical install path; links to advanced guides
└── operator-admin.md              # Operator wording that mirrors canonical truth

lib/
├── lockspire/plug/                # Runtime protected-route behavior
├── lockspire/mtls/                # mTLS extraction seam and shipped extractors
├── mix/tasks/                     # Install vs runtime diagnostics boundary
└── lockspire/web/live/admin/      # Operator/admin truth surfaces

test/
├── lockspire/release_readiness_contract_test.exs  # Doc/support-truth regression fence
├── lockspire/plug/                             # Protected-route contract proof
├── lockspire/mtls/                             # mTLS seam proof
└── integration/                                # End-to-end host/logout proof
```
[VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/operator-admin.md`; VERIFIED: `test/lockspire/release_readiness_contract_test.exs`]

### Pattern 1: Canonical Contract Then Derived Guides
**What:** `docs/supported-surface.md` should state the support claim once, while setup guides and operator surfaces explain how to satisfy it without restating a competing matrix. [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/maintainer-release.md`]
**When to use:** Any support-truth statement that affects public claims, maintainer release posture, admin wording, or support diagnostics. [VERIFIED: `docs/maintainer-release.md`; VERIFIED: `docs/operator-admin.md`]
**Example:**
```elixir
# Source: docs/protect-phoenix-api-routes.md
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```
[VERIFIED: `docs/protect-phoenix-api-routes.md`]

### Pattern 2: Explicit Ownership Split Per Advanced Surface
**What:** Every touched guide should say what Lockspire owns and what the host app or deployment environment owns. [VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/operator-admin.md`; VERIFIED: `AGENTS.md`]
**When to use:** mTLS extraction, protected-route authorization, logout propagation, and diagnostics boundaries. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/METHODOLOGY.md`]
**Example:**
```text
Lockspire owns protocol verification and fail-closed wire behavior.
The host or proxy owns TLS termination, trusted forwarding, anti-spoofing, and business authorization.
```
[VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`]

### Pattern 3: Runtime Status Surfaces Consume Normalized Truth
**What:** Admin and doctor surfaces should render normalized support truth from shared runtime helpers, while prose remains in docs. [VERIFIED: `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`; VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`] 
**When to use:** Only when a runtime incident or status surface exists; do not overload `mix lockspire.verify` or invent a second prose authority. [VERIFIED: `lib/mix/tasks/lockspire.verify.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`] 
**Example:**
```elixir
# Source: lib/mix/tasks/lockspire.doctor.remote_jwks.ex
summary = Clients.remote_jwks_summary(client)
```
[VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`]

### Anti-Patterns to Avoid
- **Competing capability matrices:** Do not let `install-and-onboard`, `operator-admin`, or host guides redefine the supported surface independently of `docs/supported-surface.md`. [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`; VERIFIED: `docs/maintainer-release.md`]
- **Optionalizing the sender-constraint plug in the canonical route story:** The locked decision and the existing guide both expect `EnforceSenderConstraints` in the canonical pipeline, even though it is a no-op for unconstrained tokens. [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`] 
- **Implying front-channel logout is remotely verifiable:** The current runtime copy and OIDC specs support best-effort only. [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`; CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html; CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]
- **Treating `mix lockspire.verify` as a runtime doctor surface:** Phase 91 explicitly split install verification from runtime diagnosis. [VERIFIED: `lib/mix/tasks/lockspire.verify.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`; VERIFIED: `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Phoenix protected-resource auth responses | Ad hoc controller error rendering | `Lockspire.Plug.RequireToken` | It already converts structured token/sender errors into the repo-proven OAuth wire contract, including DPoP nonce challenges and `403 insufficient_scope`. [VERIFIED: `lib/lockspire/plug/require_token.ex`; VERIFIED: `test/lockspire/plug/require_token_test.exs`] |
| Sender-constraint route enforcement | Per-controller DPoP/mTLS checks | `Lockspire.Plug.EnforceSenderConstraints` in the canonical pipeline | It already handles DPoP proof validation, nonce retries, mTLS thumbprint checks, and dual-bound tokens without halting early. [VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; VERIFIED: `test/lockspire/plug/enforce_sender_constraints_test.exs`] |
| mTLS extraction abstractions | New proxy autodetection or environment-specific extractors as first-class support | `Lockspire.MTLS.Extractor.CowboyDirect` and `Lockspire.MTLS.Extractor.ProxyHeader` | The product boundary intentionally supports only two canonical extraction patterns plus a generic escape hatch. [VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `lib/lockspire/mtls/extractor.ex`] |
| Logout delivery durability | Browser-only logout propagation or manual retry loops | Oban + Req-backed back-channel worker flow | The current support contract promises durable back-channel delivery, not synchronous page-driven reliability. [VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `lib/lockspire/workers/backchannel_logout_delivery_worker.ex`] |
| Support prose in CLI/admin code | Stringly-typed duplicated status vocabularies | Shared runtime truth helpers plus canonical docs | Phase 91 already established the pattern and Lockspire’s methodology prefers durable truth over folklore. [VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`; VERIFIED: `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`; VERIFIED: `.planning/METHODOLOGY.md`] |

**Key insight:** The planner should spend effort on authority and wording alignment, not on inventing replacement runtime primitives, because the shipped seams already embody the target behavior. [VERIFIED: `lib/lockspire/plug/verify_token.ex`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; VERIFIED: `lib/lockspire/plug/require_token.ex`; VERIFIED: `docs/supported-surface.md`]

## Common Pitfalls

### Pitfall 1: Canonical/Derived Drift
**What goes wrong:** `docs/supported-surface.md` and adjacent guides describe the same capability with slightly different guarantees or setup obligations. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `docs/operator-admin.md`]
**Why it happens:** Each guide tries to be self-contained and slowly grows a second support matrix. [ASSUMED]
**How to avoid:** Require each derived guide to link back to the canonical contract and explain setup/remediation only. [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`]
**Warning signs:** Any doc that says “optional” or “supported” differently than `docs/supported-surface.md`. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`]

### Pitfall 2: Proxy Header Spoofing Ambiguity
**What goes wrong:** A team enables header-based certificate forwarding without understanding that the proxy must strip or overwrite the client-cert header. [VERIFIED: `docs/mtls-host-guide.md`]
**Why it happens:** Header forwarding feels like an application concern, but the security boundary is really at the reverse proxy. [VERIFIED: `docs/mtls-host-guide.md`; CITED: https://www.rfc-editor.org/info/rfc8705/]
**How to avoid:** Make anti-spoofing and trusted forwarding part of the first-page support truth, not just a warning block deep in the guide. [VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`]
**Warning signs:** Documentation that says Lockspire “extracts the certificate” without naming who owns TLS termination and header safety. [VERIFIED: `docs/mtls-host-guide.md`; VERIFIED: `AGENTS.md`]

### Pitfall 3: Treating `EnforceSenderConstraints` as Optional in Practice
**What goes wrong:** Hosts omit the sender-constraint plug on bearer-only routes, then silently lose correctness when clients later adopt DPoP or mTLS-bound tokens. [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`]
**Why it happens:** The plug is a no-op for unconstrained tokens, which makes it look skippable. [VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; VERIFIED: `test/lockspire/plug/enforce_sender_constraints_test.exs`]
**How to avoid:** Document the three-plug order once as canonical and remove “optional” wording from support-contract surfaces. [VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`]
**Warning signs:** Example pipelines that jump directly from `VerifyToken` to `RequireToken`. [VERIFIED: `docs/protect-phoenix-api-routes.md`]

### Pitfall 4: Overclaiming Front-Channel Logout
**What goes wrong:** Docs or admin copy imply remote logout completion when the runtime only triggers browser-driven iframe cleanup. [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]
**Why it happens:** Front-channel UX feels visible and immediate, while back-channel durability is asynchronous and less obvious. [VERIFIED: `docs/operator-admin.md`; CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html; CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]
**How to avoid:** Repeat the asymmetric truth model consistently: back-channel is durable, front-channel is best effort only. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/operator-admin.md`; VERIFIED: `docs/dynamic-registration.md`] 
**Warning signs:** Phrases like “signs out connected apps” without “best effort” or without naming the browser/user-agent channel. [VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`]

## Code Examples

Verified patterns from the repo:

### Canonical Protected-Route Pipeline
```elixir
# Source: docs/protect-phoenix-api-routes.md
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```
[VERIFIED: `docs/protect-phoenix-api-routes.md`]

### mTLS Proxy Header Configuration
```elixir
# Source: docs/mtls-host-guide.md
config :lockspire,
  mtls_extractor: {Lockspire.MTLS.Extractor.ProxyHeader, header: "x-client-cert"}
```
[VERIFIED: `docs/mtls-host-guide.md`]

### Install-vs-Runtime Diagnostic Boundary
```text
mix lockspire.verify
mix lockspire.doctor remote-jwks --client CLIENT_ID
```
[VERIFIED: `lib/mix/tasks/lockspire.verify.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.ex`; VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`]

### Logout Propagation Admin Copy Pattern
```html
<!-- Source: lib/lockspire/web/live/admin/clients_live/form_component.ex -->
<p><strong>Separate concern:</strong> these URIs control RP logout propagation, not post-logout redirects.</p>
<p><strong>Truth model:</strong> front-channel logout stays best effort because browsers can block cross-site cleanup.</p>
```
[VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treating support docs as mostly narrative onboarding | Treat support docs as release-contract surfaces backed by regression tests | This posture was already present before Phase 92 and was reinforced by Phase 91’s runtime/support split on 2026-05-25. [VERIFIED: `test/lockspire/release_readiness_contract_test.exs`; VERIFIED: `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`] | Phase 92 should add coherence, not a new documentation architecture. [VERIFIED: `.planning/ROADMAP.md`] |
| Browser-centric logout intuition | Explicit asymmetric logout model: durable back-channel plus best-effort front-channel | The runtime and docs already reflect this shipped model in the current repo state. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/operator-admin.md`; VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`] | Planner should preserve the asymmetry and prevent stronger claims in admin/docs. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| “Optional sender-constraint plug” language in support contract | Canonical three-plug pipeline with sender-constraint enforcement always present in the documented route stack | Locked by Phase 92 context on 2026-05-25, while some current docs still lag. [VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`] | The main planning task is wording reconciliation, not code invention. [VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`] |

**Deprecated/outdated:**
- Describing `Lockspire.Plug.EnforceSenderConstraints` as optional in the public support contract is outdated relative to the locked Phase 92 decision and the current canonical route guide. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md`] 

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Each guide tends to grow a second support matrix when allowed to be self-contained. [ASSUMED] | Common Pitfalls | Low; it only affects framing of the doc-maintenance risk. |
| A2 | Phase 92 should add only minimal new contract assertions and leave broader proof expansion to Phase 93. [ASSUMED] | Open Questions | Medium; if wrong, the planner may under-scope Phase 92 verification work. |
| A3 | Wording-only alignment is preferable unless repeated runtime/admin text clearly justifies a shared helper. [ASSUMED] | Open Questions | Medium; if wrong, the planner may miss a small refactor that would reduce future drift. |

## Open Questions

1. **Should Phase 92 itself add release-contract assertions, or leave all new proof to Phase 93?**
   - What we know: The milestone traceability assigns proof requirements to Phase 93, but Phase 92 changes support-contract wording and could benefit from at least minimal regression fencing. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/ROADMAP.md`]
   - What's unclear: Whether the planner wants doc edits in Phase 92 to land without any new contract assertions until Phase 93. [VERIFIED: phase scope ambiguity between `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md`]
   - Recommendation: Let Phase 92 add only the smallest assertions needed to keep touched docs/admin wording from drifting during implementation, then let Phase 93 broaden proof coverage. [ASSUMED]

2. **Do admin/doctor surfaces need a new shared primitive for Phase 92, or only wording changes?**
   - What we know: The repo already has a strong precedent for shared runtime truth in remote-JWKS diagnostics, while logout/admin wording currently appears to be static template copy. [VERIFIED: `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]
   - What's unclear: Whether there is enough repeated advanced-setup wording across admin surfaces to justify a small shared presenter/helper in this phase. [VERIFIED: current admin surface inspection]
   - Recommendation: Prefer wording-only alignment unless the same status text appears in more than one runtime/admin surface and is likely to drift again. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Docs/tests/contract verification commands | ✓ [VERIFIED: `elixir --version`] | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Mix | Test aliases and docs verification | ✓ [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: `mix --version`] | — |
| PostgreSQL CLI / server family | Repo tests and Ecto-backed integration flows | ✓ CLI [VERIFIED: `psql --version`] | 14.17 [VERIFIED: `psql --version`] | No realistic fallback for full integration proof. [VERIFIED: `mix.exs`; VERIFIED: `test/integration/phase39_logout_propagation_e2e_test.exs`; VERIFIED: `test/integration/phase81_generated_host_route_protection_e2e_test.exs`] |

**Missing dependencies with no fallback:**
- None detected at the CLI/tooling level for planning and local verification. [VERIFIED: `elixir --version`; VERIFIED: `mix --version`; VERIFIED: `psql --version`]

**Missing dependencies with fallback:**
- None. [VERIFIED: current environment audit]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir/Mix. [VERIFIED: `test/test_helper.exs`; VERIFIED: `mix.exs`] |
| Config file | `config/test.exs` plus `test/test_helper.exs`. [VERIFIED: `config/test.exs`; VERIFIED: `test/test_helper.exs`] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/plug/verify_token_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs test/lockspire/web/end_session_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/integration/phase39_logout_propagation_e2e_test.exs` [VERIFIED: `mix.exs`; VERIFIED: relevant test files exist] |
| Full suite command | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration && MIX_ENV=test mix test.phase3` or `mix ci` for the maintained contributor lane. [VERIFIED: `mix.exs`] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GUIDE-01 | mTLS guide and support contract describe only the two supported extraction patterns plus explicit host responsibilities | contract + unit | `MIX_ENV=test mix test test/lockspire/mtls/cowboy_direct_extractor_test.exs test/lockspire/mtls/proxy_header_extractor_test.exs test/lockspire/release_readiness_contract_test.exs` | ✅ [VERIFIED: files exist] |
| GUIDE-02 | Protected routes keep the canonical three-plug order and current 401/403 wire contract | unit + integration | `MIX_ENV=test mix test test/lockspire/plug/verify_token_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs` | ✅ [VERIFIED: files exist] |
| GUIDE-03 | Logout propagation docs/admin wording preserve durable back-channel and best-effort front-channel truth | controller + integration + contract | `MIX_ENV=test mix test test/lockspire/web/end_session_controller_test.exs test/integration/phase39_logout_propagation_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` | ✅ [VERIFIED: files exist] |
| TRUTH-01 | Canonical docs and derived surfaces stay aligned | contract | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` | ✅ [VERIFIED: file exists] |
| TRUTH-02 | Docs/admin wording keep host-vs-Lockspire boundaries explicit | contract + admin | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ [VERIFIED: files exist] |

### Sampling Rate
- **Per task commit:** Run the smallest touched subset from the quick-run command above. [VERIFIED: existing test layout]
- **Per wave merge:** Run `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/plug/verify_token_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/plug/require_token_test.exs test/lockspire/web/end_session_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/integration/phase39_logout_propagation_e2e_test.exs`. [VERIFIED: relevant files exist]
- **Phase gate:** Run `mix ci` before `/gsd-verify-work`. [VERIFIED: `mix.exs`; VERIFIED: `docs/maintainer-release.md`]

### Wave 0 Gaps
- Add explicit release-contract assertions that `docs/supported-surface.md`, `docs/mtls-host-guide.md`, `docs/protect-phoenix-api-routes.md`, `docs/install-and-onboard.md`, and `docs/operator-admin.md` agree on the Phase 92 advanced-setup truth hierarchy and failure/ownership wording. [VERIFIED: current contract file exists; VERIFIED: docs currently contain the touched surfaces]
- Add a release-contract assertion that the public support contract no longer describes `EnforceSenderConstraints` as optional in the canonical protected-route story. [VERIFIED: current mismatch between `docs/supported-surface.md` and `docs/protect-phoenix-api-routes.md`]
- Consider one focused admin wording test for logout propagation labels/help text if Phase 92 changes those strings materially. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`; VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: phase touches OAuth client authentication and protected-resource token validation] | Preserve shipped `VerifyToken` and mTLS/DPoP sender-binding seams; do not broaden auth claims beyond runtime proof. [VERIFIED: `lib/lockspire/plug/verify_token.ex`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`] |
| V3 Session Management | yes [VERIFIED: phase touches logout propagation and `/end_session/complete`] | Keep host browser-session clearing separate from Lockspire’s protocol-owned logout completion and propagation flow. [VERIFIED: `docs/install-and-onboard.md`; VERIFIED: `docs/operator-admin.md`] |
| V4 Access Control | yes [VERIFIED: phase touches route-level scope/audience restrictions] | Use `VerifyToken` for protocol restrictions and keep host business authorization separate. [VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `lib/lockspire/plug/verify_token.ex`] |
| V5 Input Validation | yes [VERIFIED: route plug options and metadata handling are configuration-sensitive] | Keep NimbleOptions validation and existing URI/metadata validation paths; document exact required setup rather than inferring ambient state. [VERIFIED: `lib/lockspire/plug/verify_token.ex`; VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; VERIFIED: `docs/dynamic-registration.md`] |
| V6 Cryptography | yes [VERIFIED: mTLS token binding and logout token semantics depend on crypto-backed proofs] | Do not hand-roll sender-binding or certificate validation semantics; defer to the shipped runtime and RFC 8705/OIDC logout specs. [VERIFIED: `lib/lockspire/plug/enforce_sender_constraints.ex`; CITED: https://www.rfc-editor.org/info/rfc8705/; CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html] |

### Known Threat Patterns for This Phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Proxy-header certificate spoofing | Spoofing | Make trusted proxy stripping/overwrite requirements explicit whenever `ProxyHeader` is documented. [VERIFIED: `docs/mtls-host-guide.md`] |
| Stolen bearer or DPoP token reused on host routes | Tampering / Elevation | Keep `VerifyToken -> EnforceSenderConstraints -> RequireToken` as the canonical route pipeline. [VERIFIED: `docs/protect-phoenix-api-routes.md`; VERIFIED: `test/integration/phase81_generated_host_route_protection_e2e_test.exs`] |
| Operators mistaking front-channel cleanup for durable logout completion | Repudiation / Integrity | Repeat that front-channel is best effort and back-channel is the durable channel. [VERIFIED: `docs/operator-admin.md`; VERIFIED: `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`; CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html] |
| Support drift broadening public security claims beyond runtime proof | Information Disclosure / Integrity | Keep `docs/supported-surface.md` authoritative and test it with release-contract assertions. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `test/lockspire/release_readiness_contract_test.exs`; VERIFIED: `docs/maintainer-release.md`] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md` - locked scope, canonical authority hierarchy, and plan constraints. [VERIFIED: file read in session]
- `.planning/REQUIREMENTS.md` - milestone requirement IDs and phase traceability. [VERIFIED: file read in session]
- `docs/supported-surface.md` - current canonical public support contract. [VERIFIED: file read in session]
- `docs/install-and-onboard.md` - onboarding, diagnostics boundary, and logout/setup prerequisites. [VERIFIED: file read in session]
- `docs/mtls-host-guide.md` - current mTLS support wording and proxy-header warning. [VERIFIED: file read in session]
- `docs/protect-phoenix-api-routes.md` - canonical protected-route pipeline and ownership split. [VERIFIED: file read in session]
- `docs/operator-admin.md` and `docs/dynamic-registration.md` - operator/logout metadata truth. [VERIFIED: files read in session]
- `lib/lockspire/plug/*`, `lib/lockspire/mtls/extractor.ex`, `lib/mix/tasks/lockspire.verify.ex`, `lib/mix/tasks/lockspire.doctor*.ex`, and relevant admin/templates - runtime/source-of-truth behavior. [VERIFIED: files read in session]
- `test/lockspire/*` and `test/integration/*` listed in Validation Architecture - repo-native proof surfaces. [VERIFIED: files read in session]
- RFC 8705 - OAuth 2.0 Mutual-TLS Client Authentication and Certificate-Bound Access Tokens. https://www.rfc-editor.org/info/rfc8705 [CITED: https://www.rfc-editor.org/info/rfc8705/]
- OpenID Connect Back-Channel Logout 1.0. https://openid.net/specs/openid-connect-backchannel-1_0.html [CITED: https://openid.net/specs/openid-connect-backchannel-1_0.html]
- OpenID Connect Front-Channel Logout 1.0. https://openid.net/specs/openid-connect-frontchannel-1_0.html [CITED: https://openid.net/specs/openid-connect-frontchannel-1_0.html]

### Secondary (MEDIUM confidence)
- Hex package metadata for current stable versions of Phoenix, Phoenix LiveView, Ecto SQL, Bandit, Oban, and Req via `mix hex.info`. [VERIFIED: `mix hex.info phoenix`; VERIFIED: `mix hex.info phoenix_live_view`; VERIFIED: `mix hex.info ecto_sql`; VERIFIED: `mix hex.info bandit`; VERIFIED: `mix hex.info oban`; VERIFIED: `mix hex.info req`]

### Tertiary (LOW confidence)
- None. [VERIFIED: current research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - this phase reuses the existing repo stack and current Hex metadata was verified during the session. [VERIFIED: `mix.exs`; VERIFIED: `mix hex.info *`]
- Architecture: HIGH - the runtime seams, docs, and tests all point to the same underlying architecture; the remaining issue is wording drift, not uncertain behavior. [VERIFIED: codebase/doc/test inspection]
- Pitfalls: HIGH - the major pitfalls are directly evidenced by current wording mismatches, explicit warnings, or official specs. [VERIFIED: docs/code inspection; CITED: RFC/OIDC specs]

**Research date:** 2026-05-25 [VERIFIED: current session date]
**Valid until:** 2026-06-24 for planning on this milestone, unless Phase 91/92 code lands and changes the touched docs or support surfaces first. [VERIFIED: current repo state]
