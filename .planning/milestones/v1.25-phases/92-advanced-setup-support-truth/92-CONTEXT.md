# Phase 92: Advanced Setup Support Truth - Context

**Gathered:** 2026-05-25 (assumptions mode with targeted subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Lockspire's canonical advanced-setup story explicit, coherent, and supportable across the already-shipped mTLS, protected-route, and logout propagation surfaces without widening the embedded-library boundary, changing runtime guarantees, or inventing a hosted-auth control plane. This phase aligns support truth, operator wording, and setup guidance around what Lockspire actually ships and what the host app or deployment environment still owns.

</domain>

<decisions>
## Implementation Decisions

### Shared support-contract architecture
- **D-01:** Keep `docs/supported-surface.md` as the single canonical public support contract for advanced setup claims and non-claims.
- **D-02:** Treat adjacent guides (`docs/mtls-host-guide.md`, `docs/protect-phoenix-api-routes.md`, `docs/install-and-onboard.md`, `docs/operator-admin.md`, and related scenario docs) as derived setup/remediation guides that defer to the canonical support contract instead of restating a competing capability matrix.
- **D-03:** Follow the same split Phase 91 established for runtime diagnostics: prose support truth lives in the canonical docs, while any doctor/admin/runtime status surfaces consume shared normalized truth primitives rather than inventing local vocabularies.
- **D-04:** Preserve the boundary between install/onboarding diagnostics and runtime support incidents: `mix lockspire.verify` remains the canonical install-wiring check; doctor-style or admin diagnostics remain runtime-incident/status surfaces only.

### mTLS support truth
- **D-05:** Publish one canonical two-pattern mTLS setup story:
  - direct TLS termination in the host Phoenix app using `Lockspire.MTLS.Extractor.CowboyDirect`; and
  - trusted reverse-proxy header extraction using `Lockspire.MTLS.Extractor.ProxyHeader`.
- **D-06:** Make the host/infrastructure ownership split explicit everywhere:
  - the host app or deployment environment owns TLS termination, trusted forwarding, and header anti-spoofing;
  - Lockspire owns certificate verification against client registration data plus token/certificate binding enforcement once the certificate reaches the request seam.
- **D-07:** Keep the generic `Lockspire.MTLS.Extractor` behaviour extensibility as an escape hatch for unusual deployments, but do not elevate arbitrary custom extractors to first-class support-contract parity with the two shipped patterns.
- **D-08:** Keep DPoP as the ergonomic default sender-constraining story for typical Phoenix SaaS deployments; mTLS remains a supported advanced path for teams that can satisfy the infrastructure prerequisites without expecting Lockspire to hide them.

### Protected-route support truth
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

### Logout propagation support truth
- **D-14:** Standardize on one asymmetric logout truth model:
  - back-channel logout is the canonical durable propagation path;
  - front-channel logout is best-effort browser choreography only.
- **D-15:** Keep `/end_session/complete` as the protocol-owned fork point after the host app clears its own browser session; Lockspire then owns token revocation, persisted propagation intent, back-channel enqueueing, and rendering the front-channel cleanup page.
- **D-16:** Preserve the current metadata boundary: DCR and admin/operator workflows manage the four existing logout propagation metadata fields for the already-shipped runtime, but they do not create a broader “new logout system.”
- **D-17:** Keep post-logout redirect URIs explicitly separate from logout propagation URIs in every guide, admin help text, and support surface.
- **D-18:** Make prerequisites part of the support truth: back-channel durability depends on the shipped Oban + Req path and correct RP endpoint metadata; front-channel success is never reported as remotely verified logout completion.

### Planning and repo-level GSD defaults
- **D-19:** Shift the user’s preference left as repo policy for GSD: discuss/plan/review work on already-shipped surfaces should default to research-first, assumption-first, one-shot recommendation bundles instead of menus of medium-value choices.
- **D-20:** Escalate only when a choice materially changes product boundary, public support claims, operator responsibilities, security posture, API shape, or runtime guarantees.
- **D-21:** For support-truth and docs phases, future GSD artifacts should declare:
  - canonical authority;
  - derived surfaces;
  - surfaces that must not broaden the contract.

### the agent's Discretion
- Exact section titles, wording, and cross-link placement across the touched guides, provided the canonical-authority hierarchy stays intact.
- The exact shape of any small shared support-truth primitive layer for admin/doctor/status summaries, provided it normalizes runtime states without turning all support prose into code constants.
- The exact amount of repetition needed in docs/admin copy to keep dangerous prerequisites and asymmetries legible without making the writing noisy.

</decisions>

<specifics>
## Specific Ideas

- Preferred product truth for advanced setup should feel calm and specific:
  - one canonical support contract;
  - one canonical protected-route pipeline;
  - one canonical asymmetric logout story;
  - one canonical two-pattern mTLS setup story.
- Strong ecosystem lessons to preserve:
  - borrow Doorkeeper’s short-path installation instincts, but not its tendency toward guide drift and extension ambiguity;
  - borrow `node-oidc-provider`’s protocol seriousness and explicit feature truth, but avoid configuration sprawl and integrator archaeology;
  - borrow OpenIddict and Spring Authorization Server’s boundary clarity, but keep the Phoenix embedded-library seam explicit instead of adopting a heavy framework-first posture;
  - do not let admin UI become the de facto truth authority the way standalone-console products can.
- Recommended repo-level GSD posture:
  - read repo truth first;
  - synthesize ecosystem lessons second;
  - recommend one coherent bundle;
  - escalate only for high-impact boundary or support-claim changes.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase boundary
- `.planning/PROJECT.md` — v1.25 support-burden-reduction goal, embedded-library boundary, and current product priorities
- `.planning/REQUIREMENTS.md` — `GUIDE-01`, `GUIDE-02`, `GUIDE-03`, `TRUTH-01`, and `TRUTH-02`
- `.planning/ROADMAP.md` — Phase 92 goal, scope, and plan breakdown
- `.planning/STATE.md` — current repo state and milestone framing
- `.planning/METHODOLOGY.md` — assumption-first, least-surprise host seam, research-first decisive defaults, and high-threshold escalation

### Prior phase truth
- `.planning/phases/87-CONTEXT.md` — prior decision to keep one canonical public support contract with targeted adjacent guides for logout-related truth
- `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md` — prior decision to separate canonical support prose from shared runtime diagnostics and to keep `mix lockspire.verify` scoped to install truth

### Current support and setup docs
- `docs/supported-surface.md` — canonical public support contract that Phase 92 must preserve and refine
- `docs/install-and-onboard.md` — onboarding/install truth, host seam, protected-route optional path, and logout propagation setup sequence
- `docs/mtls-host-guide.md` — existing mTLS setup story, extractor patterns, and proxy-header security warning
- `docs/protect-phoenix-api-routes.md` — existing canonical plug pipeline, assigns contract, and failure semantics
- `docs/operator-admin.md` — operator/admin wording for logout propagation and workflow boundaries
- `docs/dynamic-registration.md` — DCR/logout metadata truth that must continue to align with the shipped runtime
- `docs/private-key-jwt-host-guide.md` — precedent for narrow advanced-setup support truth plus doctor/admin/runtime support alignment
- `docs/maintainer-release.md` — maintainer guidance that must defer to the canonical support contract

### Existing runtime and UI surfaces
- `lib/lockspire/mtls/extractor.ex` — explicit extractor seam and supported input contract
- `lib/lockspire/plug/verify_token.ex` — soft token verification and route restriction semantics
- `lib/lockspire/plug/enforce_sender_constraints.ex` — DPoP/mTLS sender-constraint enforcement and mTLS extraction boundary
- `lib/lockspire/plug/require_token.ex` — strict failure-to-wire rendering semantics
- `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex` — front-channel best-effort wording and protocol-owned completion surface
- `lib/lockspire/web/live/admin/clients_live/show.ex` — current operator summary surfaces and route/workflow links
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — current admin help text for logout propagation and DPoP/policy surfaces
- `lib/mix/tasks/lockspire.verify.ex` — install/onboarding diagnostic boundary
- `lib/mix/tasks/lockspire.doctor.ex` — doctor command family boundary
- `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` — precedent for shared runtime diagnostics consumed by support surfaces

### Repo-native proof
- `test/lockspire/plug/verify_token_test.exs` — route restriction and token failure semantics
- `test/lockspire/plug/enforce_sender_constraints_test.exs` — DPoP and mTLS sender-constraint enforcement behavior
- `test/lockspire/plug/require_token_test.exs` — OAuth-style HTTP response rendering contract
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` — end-to-end proof of the canonical protected-route pipeline
- `test/lockspire/release_readiness_contract_test.exs` — docs/support-truth regression assertions across supported-surface and advanced setup docs

### Product and ecosystem guidance
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` — product thesis, ecosystem comparisons, and narrow embedded-library positioning
- `prompts/lockspire-host-app-integration-seam.md` — explicit ownership boundary between Lockspire and the host app
- `prompts/lockspire-oauth-oidc-implementation-playbook.md` — intended library shape, install model, and boundary discipline
- `prompts/lockspire-elixir-oss-library-practices.md` — explicit public API, runtime config, diagnostics, and library DX guidance
- `prompts/lockspire-operator-admin-ia-and-workflows.md` — calm operator UX expectations and authority boundaries
- `prompts/lockspire-operator-ux-liveview.md` — LiveView/operator presentation guidance
- `prompts/lockspire-phoenix-system-design.md` — durable truth vs derived state and BEAM/Phoenix architecture guidance
- `prompts/lockspire-security-posture-and-threat-model.md` — security defaults, threat boundaries, and support-footgun constraints
- `prompts/lockspire-telemetry-audit-and-introspection.md` — “what happened, why, what next?” observability goal
- `.planning/research/RESEARCH-FAPI.md` — DPoP-over-mTLS ergonomics and deployment-reality lessons
- `.planning/research/v1.11-MILESTONE-RECOMMENDATION.md` — advanced-setup mTLS complexity and operator-DX lessons
- `.planning/research/phase-68-publish-verification.md` — canonical-contract and derived-surface proof discipline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.MTLS.Extractor` and the shipped extractor implementations already define the narrow mTLS host seam; Phase 92 should align docs and operator wording around that seam rather than inventing a broader abstraction.
- `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken` already embody the canonical protected-route pipeline and stable failure semantics.
- `Lockspire.Web.Controllers.EndSessionHtml.frontchannel_logout.html.heex` already carries truthful front-channel best-effort copy that adjacent docs should not contradict.
- The Phase 91 doctor and diagnostics work provide a strong precedent for “shared runtime truth consumed by CLI/admin” without overloading the install verification command.

### Established Patterns
- The repo already centralizes public support truth in `docs/supported-surface.md` and expects adjacent docs to defer to it.
- Lockspire favors explicit seams, typed/domain-owned truth, and durable operator state over hidden framework magic or inferred infrastructure behavior.
- The project methodology already prefers decisive recommendations backed by codebase reading and ecosystem synthesis rather than repeated user arbitration on medium-value choices.

### Integration Points
- Phase 92 planning should expect coordinated edits across the canonical support contract, scenario guides, and admin/operator wording so all advanced-setup surfaces agree on one truth hierarchy.
- If any small support-truth primitive layer is introduced for admin/doctor surfaces, it should remain a consumer-facing normalization layer rather than a prose authority.
- Phase 93 should add regression proof that the canonical contract and derived advanced-setup surfaces still agree after Phase 92 lands.

</code_context>

<deferred>
## Deferred Ideas

- Broader mTLS deployment automation, trust-proxy autodetection, or infrastructure-specific installation helpers
- A hosted-style readiness dashboard or richer admin observability plane for every advanced setup surface
- Generic protected-resource middleware beyond the shipped host Phoenix plug pipeline
- Any stronger front-channel logout reliability claim or RP-success verification model
- Broader documentation architecture rewrites outside the surfaces needed to keep Phase 92 truthful

</deferred>

---

*Phase: 92-advanced-setup-support-truth*
*Context gathered: 2026-05-25*
