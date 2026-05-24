# Phase 74: FAPI 2.0 Message Signing Strict Mode - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 74 adds strict enforcement for the v1.19 message-signing slice on top of the already shipped
FAPI 2.0 security baseline. Lockspire must let operators opt clients or the whole issuer into a
stricter profile that requires signed authorization responses via JARM and signed introspection
responses via RFC 9701 semantics, while preserving the existing compatibility-first behavior
outside that strict profile.

This phase is about enforcement and operator clarity, not about widening Lockspire into a
standalone policy engine, a second crypto-policy plane, or a full resource-server product. It also
does not redefine the meaning of the already shipped `:fapi_2_0_security` profile.

</domain>

<decisions>
## Implementation Decisions

### Decisioning posture

- **D-01:** Shift recommendation-heavy behavior left for this project within GSD. Downstream
  research, planning, and execution should default to one coherent recommendation set rather than
  medium-impact option menus, and only escalate choices that materially affect public support
  claims, product boundaries, migration risk, or irreversible architecture.

### Profile shape

- **D-02:** Add a new durable security-profile tier,
  `:fapi_2_0_message_signing`, instead of redefining `:fapi_2_0_security` or adding a separate
  toggle.
- **D-03:** Keep one policy plane. Message-signing strictness belongs inside the existing
  `security_profile` model, not in a second flag or separate compliance switch.
- **D-04:** The global/server profile shape should become
  `:none | :fapi_2_0_security | :fapi_2_0_message_signing`.
- **D-05:** The client override shape should become
  `:inherit | :none | :fapi_2_0_security | :fapi_2_0_message_signing`.
- **D-06:** Resolver semantics should be monotonic:
  `:fapi_2_0_message_signing` implies all `:fapi_2_0_security` behavior plus additional
  message-signing strictness.
- **D-07:** Preserve existing mixed-mode semantics from Phase 41. A client may still explicitly
  override a stricter global profile to `:none` when the operator intentionally wants that escape
  hatch.

### Authorization strictness

- **D-08:** Under `:fapi_2_0_message_signing`, `/authorize` must require explicit JARM.
- **D-09:** Accepted strict-mode JARM request values are `jwt`, `query.jwt`, `fragment.jwt`, and
  `form_post.jwt`. Bare `jwt` continues to resolve to `query.jwt` for `response_type=code`.
- **D-10:** Under `:fapi_2_0_message_signing`, reject omitted `response_mode` and reject raw
  non-JWT authorization response modes rather than silently upgrading them.
- **D-11:** Do not auto-upgrade strict-mode requests into JARM. Silent mutation would violate the
  principle of least surprise, blur conformance, and create hard-to-debug relying-party behavior.
- **D-12:** Authorization strictness belongs in `AuthorizationRequest` validation, not in the
  coarse FAPI boundary Plug. This decision depends on validated client/profile state and must
  produce redirect-safe OAuth errors.
- **D-13:** Do not require JARM encryption as part of strict mode. Keep encryption opt-in and
  per-client; strict mode is about mandatory signed responses, not mandatory encrypted responses.
- **D-14:** Any encrypted-JARM request path that is already selected must remain fail-closed. Do
  not permit downgrade from encrypted JARM to signed-only or raw parameters.

### Introspection strictness

- **D-15:** Under `:fapi_2_0_message_signing`, `/introspect` must require explicit negotiation of
  `application/token-introspection+jwt`.
- **D-16:** Missing `Accept`, wildcard-only acceptance, JSON-only acceptance, malformed headers, or
  negotiation that does not positively select `application/token-introspection+jwt` must be
  rejected for strict-mode callers rather than falling back to JSON.
- **D-17:** Every successful strict-mode introspection response must use the JWT representation.
  Error responses remain standard OAuth JSON errors.
- **D-18:** Strict-mode introspection should move toward an authenticated-and-entitled caller model
  rather than “any confidential client may introspect”. Planning should reuse existing direct-client
  authentication seams and add the smallest truthful authorization seam needed for this profile.
- **D-19:** Preserve the narrow inactive-token contract for successful JWT introspection responses:
  for an authenticated and authorized caller, inactive outcomes remain semantically small rather
  than expanding into a richer error-like payload.
- **D-20:** Do not keep JSON fallback under `:fapi_2_0_message_signing`. That would create a
  downgrade path and weaken the support claim.
- **D-21:** Introspection strictness belongs in the introspection controller plus protocol-owned
  negotiation/caller-policy seams, not in the coarse Plug. The Plug does not have enough context to
  safely decide authenticated caller identity, negotiated media type, and caller entitlement.

### Operator visibility and admin UX

- **D-22:** Do more than a badge, but less than a sprawling dashboard. The admin surface should
  expose a bounded readiness/remediation view derived from canonical enforcement logic.
- **D-23:** Operators should not have to infer whether “supports JARM/JWT introspection” means
  “strictly enforced for this client”. The UI must make effective message-signing posture explicit.
- **D-24:** Reuse the current calm admin style: one readiness panel or equivalent derived state that
  tells the operator:
  - what the effective profile is,
  - what strict mode changes for this client,
  - what prerequisites are missing, and
  - how to remediate them.
- **D-25:** Do not invent UI-only policy logic. Any readiness/remediation view must read canonical
  protocol/admin validation helpers so the UI cannot drift from runtime enforcement.
- **D-26:** Extend the existing global and per-client security-profile views rather than creating a
  separate message-signing console.

### Architecture and support posture

- **D-27:** Keep compatibility-first behavior outside `:fapi_2_0_message_signing`. Phase 71 and
  Phase 73 shipped baseline JARM and JWT introspection as optional negotiated features; that public
  contract must remain true.
- **D-28:** Keep one truthful support story: Lockspire offers baseline optional JARM/RFC 9701 for
  normal OIDC interop, and a stricter message-signing profile for high-security deployments.
- **D-29:** Do not overclaim beyond the shipped enforced subset. Docs and telemetry must describe
  Phase 74 as the strict-enforcement layer for the v1.19 message-signing slice, not as a broader
  promise than the repo actually proves.

### the agent's Discretion

- Exact resolver struct fields and helper names for the new
  `:fapi_2_0_message_signing` profile tier.
- Exact module/function names for message-signing readiness derivation, as long as admin and
  runtime consume the same canonical logic.
- Exact rejection copy and reason-code taxonomy, provided the messages remain explicit,
  least-surprising, and remediation-friendly.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle for Phase 74 is:
  - add a new `:fapi_2_0_message_signing` profile tier,
  - keep one durable policy plane,
  - require explicit JARM under strict mode,
  - require explicit JWT introspection negotiation under strict mode,
  - keep encrypted JARM optional but never silently downgraded,
  - keep strict authorization logic in `AuthorizationRequest`,
  - keep strict introspection logic in the controller/protocol seam,
  - expose one calm readiness/remediation view in admin,
  - preserve compatibility behavior unchanged outside the new profile.
- Ecosystem lessons to carry forward:
  - Mature servers separate baseline support from stricter profiles instead of redefining existing
    profile meaning underneath operators.
  - “Supported” and “strictly enforced” are not the same thing; collapsing them is a support
    footgun.
  - Silent compatibility upgrades are attractive in the short term and corrosive in the long term.
  - Embedded-library DX improves when protocol correctness stays Lockspire-owned and host apps do
    not need MIME registration, custom Plug glue, or parallel policy configuration.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning artifacts

- `.planning/PROJECT.md` — milestone goal, embedded-library boundaries, operator/DX values
- `.planning/REQUIREMENTS.md` — `ENF-01` plus adjacent v1.19 requirements
- `.planning/ROADMAP.md` — Phase 74 goal and success criteria
- `.planning/STATE.md` — current milestone position

### Prior phase context

- `.planning/phases/41-fapi-2-0-profile-configuration/41-CONTEXT.md` — durable profile model,
  mixed-mode semantics, and boundary-enforcement precedent
- `.planning/phases/42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep/42-CONTEXT.md` —
  one canonical crypto-policy source and truthful publication posture
- `.planning/phases/71-jarm-core/71-CONTEXT.md` — JARM baseline contract and compatibility-first
  posture
- `.planning/phases/72-jarm-encryption-and-metadata/72-CONTEXT.md` — encrypted-JARM behavior,
  fail-closed posture, and discovery truth
- `.planning/phases/73-jwt-introspection-responses/73-CONTEXT.md` — RFC 9701 negotiation model,
  JWT contract shape, and compatibility baseline

### Existing implementation seams

- `lib/lockspire/protocol/security_profile.ex` — effective-profile resolver and algorithm posture
- `lib/lockspire/protocol/fapi20_enforcer_plug.ex` — current coarse FAPI boundary enforcement
- `lib/lockspire/protocol/authorization_request.ex` — validated authorization request state,
  response-mode parsing, and per-client/profile validation seam
- `lib/lockspire/protocol/authorization_flow.ex` — persisted interaction response_mode and JARM
  response delivery
- `lib/lockspire/protocol/jarm.ex` — JARM signing/encryption seam
- `lib/lockspire/protocol/introspection.ex` — introspection payload shaping and current caller
  handling
- `lib/lockspire/protocol/introspection_jwt.ex` — RFC 9701 JWT signer
- `lib/lockspire/web/controllers/authorize_controller.ex` — authorization delivery adapter
- `lib/lockspire/web/controllers/introspection_controller.ex` — `Accept` negotiation and wire
  representation seam
- `lib/lockspire/admin/server_policy.ex` — global profile validation/update seam
- `lib/lockspire/admin/clients.ex` — per-client profile validation/update seam
- `lib/lockspire/web/live/admin/policies_live/security_profile.ex` — global admin profile surface
- `lib/lockspire/web/live/admin/clients_live/show.ex` — per-client effective-profile visibility
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — per-client profile edit UI

### Existing tests to preserve or extend

- `test/integration/phase41_fapi_2_0_e2e_test.exs` — existing strict-profile enforcement proof
- `test/lockspire/protocol/security_profile_test.exs` — effective-profile semantics
- `test/lockspire/protocol/jarm_test.exs` — JARM behavior
- `test/lockspire/web/introspection_controller_test.exs` — RFC 9701 negotiation and HTTP contract
- `test/lockspire/protocol/introspection_test.exs` — introspection payload truth
- `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` — global admin profile
  UX

### Authoritative standards and ecosystem references

- `https://openid.net/specs/fapi-message-signing-2_0-final.html` — final Message Signing profile
  requirements and profile framing
- `https://openid.net/specs/oauth-v2-jarm-final.html` — JARM response-mode semantics
- `https://www.rfc-editor.org/rfc/rfc9701` — JWT introspection response media type and claim
  contract
- `https://docs.duendesoftware.com/identityserver/tokens/fapi-2-0-specification/` — mature
  security-profile implementation posture and operator-facing guidance
- `https://www.authlete.com/kb/oauth-and-openid-connect/jarm/enabling-jarm/` — client-oriented
  JARM enablement precedent
- `https://www.authlete.com/kb/oauth-and-openid-connect/introspection/jwt-introspection-response/`
  — caller-negotiated JWT introspection behavior
- `https://curity.io/resources/learn/jwt-secured-authorization-response-mode/` — JARM rationale and
  interoperability framing
- `https://curity.io/blog/the-state-of-fapi-2/` — Message Signing as a stricter profile with
  non-repudiation goals
- `https://github.com/panva/node-oidc-provider` — embedded-provider precedent with mounted-host
  architecture and standards breadth

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `SecurityProfile.resolve_effective_profile/2` already gives Lockspire the correct single source
  of truth for global/client inheritance and mixed-mode semantics.
- `AuthorizationRequest` already owns response-mode parsing and validated authorization-request
  semantics, making it the right place for strict JARM requirements.
- `IntrospectionController` already owns `Accept` parsing and response representation selection,
  making it the right delivery boundary for strict JWT-introspection negotiation.
- `Introspection.Success` already carries resolved security-profile context into
  `IntrospectionJwt`, so the signer path is already close to strict-mode reuse.
- The current admin LiveViews already surface global and effective per-client profile state and can
  be extended without inventing a second console.

### Established Patterns

- Durable Ecto-backed policy state instead of app-config-only behavior
- One canonical source for runtime truth and metadata truth
- Thin Phoenix delivery adapters over protocol-owned correctness
- Recommendation-heavy, cohesive decisions rather than option-heavy policy sprawl
- Calm operator UX with explicit remediation rather than broad control-plane complexity

### Integration Points

- Extend `security_profile` enums, normalization, validation, telemetry, and resolution rather than
  adding a parallel toggle.
- Add strict JARM checks to `AuthorizationRequest` after effective-profile resolution and before
  interaction persistence.
- Keep the coarse `FAPI20EnforcerPlug` focused on Phase 41-style path/header guards unless planning
  finds a small truthful way to reuse it without duplicating protocol logic.
- Add admin-visible derived readiness/remediation state by reusing the same canonical checks used by
  runtime/profile validation.

</code_context>

<deferred>
## Deferred Ideas

- Any second toggle or parallel compliance-policy plane separate from `security_profile`
- Silent auto-upgrade of non-JARM authorization requests under strict mode
- JSON fallback for strict-mode introspection success responses
- Mandatory JARM encryption as part of strict mode
- A broad standalone resource-server registration product shape beyond the minimum truthful strict
  caller-authorization seam Phase 74 may need

</deferred>

---

*Phase: 74-fapi-2-0-message-signing-strict-mode*
*Context gathered: 2026-05-08*
