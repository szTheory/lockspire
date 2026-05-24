# Phase 84: Host Plug Pipeline, Docs, and Milestone Closure - Context

**Gathered:** 2026-05-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 84 closes the v1.22 milestone by extending the shipped host Phoenix protected-route contract to include nonce-backed DPoP, aligning the public support/docs posture to that exact shipped surface, and proving the generated-host protected-route retry path end to end.

This phase stays inside Lockspire's embedded-library wedge. It does not broaden Lockspire into generic gateway middleware, arbitrary Plug-stack resource-server support, multi-issuer validation, or a wider protected-resource product.
</domain>

<decisions>
## Implementation Decisions

### Host plug contract

- **D-01:** Preserve the existing canonical protected-route pipeline:
  - `Lockspire.Plug.VerifyToken`
  - `Lockspire.Plug.EnforceSenderConstraints`
  - `Lockspire.Plug.RequireToken`
- **D-02:** Keep `VerifyToken` and `EnforceSenderConstraints` as soft validation plugs that assign structured failures onto `conn.assigns.access_token`; keep `RequireToken` as the single strict HTTP boundary.
- **D-03:** Do not collapse route protection into one fat plug and do not allow ad hoc response rendering from intermediate plugs.
- **D-04:** Treat plug order as contract, not suggestion. Downstream docs, generated examples, and proof should reinforce the exact order above.

### Protected-resource nonce contract

- **D-05:** The shipped host Phoenix plug pipeline must use the same resource-server DPoP nonce semantics as Lockspire-owned protected resources:
  - `401 Unauthorized`
  - `WWW-Authenticate: DPoP ... error="use_dpop_nonce"`
  - `DPoP-Nonce` response header
  - successful retry when the new proof includes the supplied resource-server nonce and all normal DPoP checks still pass
- **D-06:** Bearer, MTLS, dual-bound token, replay, `ath`, binding, and `401` vs `403` behavior must remain otherwise unchanged.
- **D-07:** Keep nonce failures in the authentication-retry bucket, not the authorization bucket:
  - no `403` for nonce failures
  - no collapse into generic bearer `invalid_token`

### Rendering and drift control

- **D-08:** Keep `Lockspire.Protocol.ProtectedResourceDPoP` as the single owner of protected-resource DPoP validation and typed nonce outcomes.
- **D-09:** Keep host-route HTTP rendering in `Lockspire.Plug.RequireToken` and Lockspire-owned protected-resource HTTP rendering in `Lockspire.Web.UserinfoController`.
- **D-10:** Extract one shared internal helper for protected-resource challenge rendering/data so `/userinfo` and the host plug pipeline emit the same:
  - `WWW-Authenticate` DPoP challenge semantics
  - `DPoP-Nonce`
  - `Access-Control-Expose-Headers`
- **D-11:** Do not let that shared helper absorb validation logic; it is for transport-shape consistency only.
- **D-12:** Ensure the host plug path passes the necessary endpoint secret material for resource-server nonce issuance/validation rather than relying on hidden ambient behavior.

### Proof strategy

- **D-13:** Anchor Phase 84 milestone closure on generated-host protected-route proof, not on plug-only local coverage.
- **D-14:** Minimum milestone-closing proof for the host-route nonce slice is:
  - one generated-host protected-route E2E proving initial nonce challenge and successful retry on the documented pipeline
  - focused local plug tests for typed sender-constraint failure propagation, DPoP-aware challenge rendering, nonce-header exposure, and unchanged `401`/`403` behavior
  - release-contract assertions that pin the public nonce-backed host-route claim to repo proof
- **D-15:** Do not duplicate the entire DPoP negative matrix at generated-host E2E level. Exhaustive replay/`ath`/binding coverage remains protocol-heavy and adapter-thin.

### Support truth and docs posture

- **D-16:** Public support language must stay narrow and explicit:
  - Lockspire supports nonce-backed DPoP for Lockspire-issued access tokens on Lockspire-owned `/token`, Lockspire-owned protected resources, and host Phoenix API routes protected by the shipped plug pipeline.
- **D-17:** Keep the anchor phrase:
  - `host Phoenix API routes protected by the shipped plug pipeline`
- **D-18:** Keep these explicitly out of scope in public wording for this phase:
  - generic resource-server middleware
  - gateway or service-mesh claims
  - arbitrary Plug-stack support
  - third-party issuer validation
  - multi-issuer protected-resource support
- **D-19:** `docs/supported-surface.md` remains the authoritative support contract; `docs/protect-phoenix-api-routes.md` is the concrete guide for this shipped surface; `docs/install-and-onboard.md` may link to it as the canonical optional protected-route path but must not imply a second product topology.
- **D-20:** Docs should explicitly say Lockspire verifies token protocol facts while the host app still owns business authorization, tenant policy, domain record lookup, and whether a protected route should exist at all.

### Workflow preference

- **D-21:** Shift medium-impact implementation and wording choices left within GSD for this class of Lockspire phases.
- **D-22:** Downstream agents should resolve coherent medium-value choices autonomously after codebase + ecosystem research, and escalate only for decisions that materially affect:
  - product boundary
  - public API shape
  - security posture
  - support/release claims
  - hard-to-reverse strategic direction

### the agent's Discretion

- Exact helper/module placement for the shared protected-resource challenge-rendering helper, provided validation ownership and public semantics remain unchanged.
- Exact naming of any small internal helper APIs or structs used to share `/userinfo` and host-route challenge rendering.
- Exact split of assertions between plug tests, generated-host E2E, and release-contract tests, provided the proof hierarchy above stays intact.
- Exact prose ordering in `docs/protect-phoenix-api-routes.md` and `docs/supported-surface.md`, provided the narrow support boundary remains explicit and easy to discover.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and methodology
- `.planning/ROADMAP.md` — Phase 84 scope and plan split
- `.planning/REQUIREMENTS.md` — `NONCE-RS-*` and `NONCE-TRUTH-*` requirements
- `.planning/PROJECT.md` — embedded-library boundary, DPoP nonce milestone thesis, and support constraints
- `.planning/STATE.md` — current milestone position
- `.planning/METHODOLOGY.md` — assumption-first, least-surprise host seam, research-first defaults, and high-threshold escalation

### Upstream phase decisions
- `.planning/phases/80-sender-constraining-integration/80-CONTEXT.md` — split plug architecture and sender-constraint composition
- `.planning/phases/81-scope-audience-restrictions-milestone-closure/81-CONTEXT.md` — protected-route semantics, support boundary, and generated-host proof bar
- `.planning/phases/82-shared-dpop-nonce-primitive/82-CONTEXT.md` — nonce primitive, purpose separation, and typed nonce failures
- `.planning/phases/83-lockspire-owned-dpop-endpoint-adoption/83-CONTEXT.md` — owned-surface nonce contract and Phase 84 boundary
- `.planning/phases/83-lockspire-owned-dpop-endpoint-adoption/83-RESEARCH.md` — endpoint-adoption proof and adapter-thin guidance
- `.planning/phases/64-sigra-golden-path-generated-host-proof/64-RESEARCH.md` — generated-host proof philosophy and host seam truth

### Current code seams
- `lib/lockspire/plug/verify_token.ex` — soft token validation and route restrictions
- `lib/lockspire/plug/enforce_sender_constraints.ex` — host-route sender-constraint validation seam
- `lib/lockspire/plug/require_token.ex` — strict host-route response boundary
- `lib/lockspire/protocol/protected_resource_dpop.ex` — protected-resource DPoP validation and nonce classification
- `lib/lockspire/protocol/dpop.ex` — shared proof validator
- `lib/lockspire/protocol/dpop_nonce.ex` — shared nonce issue/validate primitive
- `lib/lockspire/protocol/userinfo.ex` — Lockspire-owned protected-resource orchestration
- `lib/lockspire/web/controllers/userinfo_controller.ex` — current protected-resource challenge rendering

### Docs and support contract
- `docs/supported-surface.md` — canonical public support contract
- `docs/protect-phoenix-api-routes.md` — shipped protected-route guide and nonce contract
- `docs/install-and-onboard.md` — canonical onboarding path and protected-route link surface
- `docs/maintainer-release.md` — maintainer release-truth posture
- `test/lockspire/release_readiness_contract_test.exs` — docs/support contract fences

### Proof files
- `test/lockspire/plug/enforce_sender_constraints_test.exs` — sender-constraint typed-failure proof
- `test/lockspire/plug/require_token_test.exs` — strict DPoP/Bearer response rendering proof
- `test/lockspire/web/userinfo_controller_test.exs` — Lockspire-owned protected-resource nonce challenge/retry proof
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` — generated-host protected-route proof precedent
- `test/support/generated_host_app_web/router/lockspire.ex` — generated-host router seam precedent

### Prompt corpus
- `prompts/lockspire-oauth-oidc-implementation-playbook.md` — intended protocol/storage/web split and design lineage
- `prompts/lockspire-elixir-oss-library-practices.md` — explicit runtime config, library UX, and small-public-API guidance
- `prompts/lockspire-host-app-integration-seam.md` — explicit host seam and ownership boundaries
- `prompts/lockspire-security-posture-and-threat-model.md` — secure-by-default and release-blocking negative-path expectations
- `prompts/lockspire-phoenix-system-design.md` — Plug/Phoenix architectural norms and anti-patterns
- `prompts/lockspire-release-readiness-and-conformance.md` — docs-as-contract and repo-proof expectations
- `prompts/lockspire-market-gap-and-positioning.md` — positioning and category-drift guardrails

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken` already form the intended split protected-route pipeline.
- `Lockspire.Protocol.ProtectedResourceDPoP` already owns resource-server DPoP nonce classification, replay handling, `ath`, and binding checks.
- `Lockspire.Web.UserinfoController` already provides the canonical Lockspire-owned protected-resource challenge shape for `use_dpop_nonce`.
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` already proves the generated-host route surface and is the right anchor for the Phase 84 host-route nonce retry closure.
- `test/lockspire/release_readiness_contract_test.exs` already acts as the repo-truth fence for support and release wording.

### Established Patterns

- Lockspire prefers protocol-owned validation plus thin Phoenix/Plug adapters over per-surface reimplementation.
- Public support claims are supposed to stay narrow, explicit, and repo-provable.
- Host-owned business authorization remains outside Lockspire's token-validation and sender-constraint layers.
- Generated-host proof is the preferred way to close claims about the shipped host seam.

### Integration Points

- Phase 84 planning should center on:
  - aligning host-route rendering with the Lockspire-owned protected-resource nonce contract
  - eliminating drift between `/userinfo` and `RequireToken`
  - proving the documented generated-host plug pipeline retry path
  - updating docs and release-contract tests so the public claim matches the exact proof surface

</code_context>

<specifics>
## Specific Ideas

- The coherent recommendation bundle is:
  - preserve the split plug pipeline
  - keep validation soft and rendering strict
  - share protected-resource challenge rendering details between `/userinfo` and host routes
  - close the milestone with generated-host E2E proof plus focused local adapter tests
  - keep support wording anchored to `host Phoenix API routes protected by the shipped plug pipeline`
- Good ecosystem lessons to follow:
  - Guardian/Pow-style verify-then-enforce separation is the right Elixir shape.
  - Spring Security-style centralized auth entry-point rendering is a strong precedent for one strict boundary.
  - Doorkeeper/OpenIddict/node-oidc-provider earn trust by documenting exact supported integration topologies, not vague middleware promises.
- One concrete drift risk to inspect during planning/implementation:
  - keep `/userinfo` and host-route DPoP challenge rendering aligned, including nonce/header exposure details and any algorithm-list behavior

</specifics>

<deferred>
## Deferred Ideas

- Generic resource-server middleware or gateway product claims
- Arbitrary Plug-stack or third-party framework support claims
- Multi-issuer or third-party issuer validation on host routes
- A broader resource-server validation product surface distinct from the shipped Phoenix plug pipeline
- New operator/client policy knobs for DPoP nonce behavior

</deferred>
