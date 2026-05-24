# Phase 73: JWT Introspection Responses - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 73 adds RFC 9701 JWT token introspection responses to the existing `/introspect` surface. When the caller explicitly negotiates `application/token-introspection+jwt`, Lockspire should return a signed JWT introspection response with the correct media type and RFC-shaped claims. This phase keeps the existing JSON response as the compatibility baseline, preserves current inactive-token collapse semantics, and does not widen Lockspire into a separate resource-server trust product, a second crypto-policy plane, or Message Signing strict enforcement. Encryption capability metadata and strict mandatory enforcement remain later concerns.

</domain>

<decisions>
## Implementation Decisions

### Decisioning posture

- **D-01:** Shift recommendation-heavy discussion left for protocol-bound phases like this. Downstream research, planning, and review should default to codebase-first analysis, standards research, and one coherent recommendation bundle rather than pulling the user through medium-impact option menus.
- **D-02:** Escalate to the user only for decisions that materially affect public API shape, product boundary, security/support claims, or hard-to-reverse strategy. Phase 73 does not meet that bar on its remaining gray areas, so planning should treat the decisions below as locked.

### Negotiation and delivery

- **D-03:** Phase 73 should use normal HTTP `Accept` negotiation, not singleton-header strictness. JWT introspection is enabled only when `application/token-introspection+jwt` is explicitly present and acceptable with non-zero weight.
- **D-04:** Do not treat wildcard-only `Accept` values, missing `Accept`, malformed headers, or mere general JSON acceptance as JWT opt-in. Those continue to receive the existing JSON response.
- **D-05:** If both JSON and JWT are acceptable, Lockspire should choose the negotiated winner using RFC 9110-style media-type rules rather than naive substring matching.
- **D-06:** JWT-vs-JSON selection belongs at the web delivery layer, not in token classification. `Lockspire.Protocol.Introspection` remains the source of truthful introspection payloads; the controller decides how that successful payload is represented on the wire.
- **D-07:** Do not require host Phoenix MIME registration or `plug :accepts` customization for this media type. As an embedded library, Lockspire should keep this negotiation logic internal and explicit.
- **D-08:** JWT delivery should add `Vary: Accept` alongside the existing `no-store` / `no-cache` response posture.
- **D-09:** Exact-header or mandatory-JWT enforcement is a Phase 74 concern, not a Phase 73 compatibility break.

### Success and error behavior

- **D-10:** When JWT introspection is negotiated, every successful introspection response should use the JWT representation, including inactive outcomes.
- **D-11:** Inactive introspection success stays semantically narrow: the nested `token_introspection` object contains only `active: false` and no other members.
- **D-12:** Error responses remain standard JSON even when JWT is requested. Do not introduce mixed error encodings or signed OAuth error bodies in Phase 73.
- **D-13:** Current confidential-caller requirements and inactive-response collapse semantics stay unchanged. Phase 73 changes representation, not authorization or token-state logic.

### JWT contract shape

- **D-14:** Phase 73 should follow the narrow RFC 9701 contract, not “sign the current JSON map directly” and not a custom Lockspire-specific outer JWT shape.
- **D-15:** The JWT header must include `typ: token-introspection+jwt` and the response `Content-Type` must be `application/token-introspection+jwt`.
- **D-16:** The top-level JWT claims for Phase 73 should be the narrow standard envelope: `iss`, `aud`, `iat`, and `token_introspection`.
- **D-17:** The current introspection response body becomes the nested `token_introspection` claim, preserving the existing payload semantics with string keys.
- **D-18:** Do not add top-level `sub`, `exp`, `nbf`, or `jti` by default in Phase 73. That would over-specify semantics early, increase cross-JWT confusion risk, and move Lockspire away from the standard narrow wrapper.
- **D-19:** `aud` should bind to the authenticated introspection caller identity already proven by the current direct-client auth surface. In the current Lockspire shape, that means the authenticated caller/client identifier rather than an invented new resource-server identity model.

### Signing posture and architecture

- **D-20:** Reuse the existing signing-key and effective-security-profile infrastructure rather than creating a second introspection-specific crypto-policy plane.
- **D-21:** Phase 73 should add a dedicated introspection-response signer module rather than overloading JARM helpers or introducing a generic “sign any map” utility. The code should mirror the purpose-specific shaping style used by `IdToken` and `LogoutToken`.
- **D-22:** Signing behavior should remain compatibility-first in the baseline profile and naturally narrow under stricter existing security-profile constraints when the active key/algorithm posture requires it.
- **D-23:** Encryption support and introspection metadata publication from RFC 9701 are not part of this phase unless planning proves they are already required to satisfy repo-truth docs for the shipped slice. Do not widen scope casually.

### Developer ergonomics and support truth

- **D-24:** Great DX for this phase means a relying party can request JWT introspection with a standard `Accept` header and receive one predictable success format, without extra host-app framework wiring.
- **D-25:** Great maintainer ergonomics means tests and docs describe one simple rule set: explicit `Accept` negotiation selects JWT, success responses stay uniform, inactive responses remain narrow, and errors stay JSON.
- **D-26:** Docs should describe this as RFC 9701 support specifically, not generic “JWT introspection mode”, and should include both active and inactive JWT examples.

### the agent's Discretion

- Exact helper/module names for `Accept` parsing and introspection-JWT signing.
- Whether the negotiation helper lives beside the controller or in a small protocol-adjacent utility module, as long as it stays Lockspire-owned and not host-config-driven.
- Exact internal reason-code taxonomy for signer and negotiation failures, provided the external contract above remains stable.

</decisions>

<specifics>
## Specific Ideas

- Coherent recommendation bundle for Phase 73:
  - negotiate JWT introspection through normal HTTP `Accept` semantics,
  - keep JSON as the compatibility baseline when JWT is not explicitly negotiated,
  - sign every successful negotiated JWT response, including inactive results,
  - use the standard RFC 9701 envelope with `typ=token-introspection+jwt` and nested `token_introspection`,
  - avoid extra outer claims and avoid host-level MIME/config burden.
- Ecosystem lessons worth carrying forward:
  - successful OAuth/OIDC servers treat JWT introspection as a negotiated representation of the same endpoint, not as a separate route or host-owned behavior,
  - custom outer JWT claim contracts are a footgun because they freeze semantics early and create cross-server drift,
  - embedded-library DX gets worse quickly when protocol features require host framework registration or app-wide MIME configuration,
  - strict enforcement should be a deliberate later profile decision, not an early compatibility surprise.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning artifacts
- `.planning/PROJECT.md` — embedded-library boundary, milestone goal, and DX/support posture
- `.planning/REQUIREMENTS.md` — `INT-01`
- `.planning/ROADMAP.md` — Phase 73 goal and success criteria
- `.planning/STATE.md` — current milestone position
- `.planning/METHODOLOGY.md` — recommendation-heavy, research-first, high-threshold-escalation posture

### Prior phase context
- `.planning/phases/41-fapi-2-0-profile-configuration/41-CONTEXT.md` — effective security-profile posture and strict-mode precedent
- `.planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md` — shared direct-client auth and guarded client-crypto posture
- `.planning/phases/71-jarm-core/71-CONTEXT.md` — no second crypto-policy plane, narrow JWT contract, truthful discovery/support posture
- `.planning/phases/72-jarm-encryption-and-metadata/72-CONTEXT.md` — fail-closed crypto behavior, coherent runtime capability story, and recommendation-heavy decision posture

### Authoritative standards
- `https://www.rfc-editor.org/rfc/rfc7662` — baseline introspection success/error semantics, especially inactive-token handling
- `https://www.rfc-editor.org/rfc/rfc9701` — JWT introspection response contract, `typ`, nested `token_introspection`, and media type
- `https://www.rfc-editor.org/rfc/rfc9110` — HTTP `Accept` negotiation semantics
- `https://openid.net/specs/fapi-message-signing-2_0-final.html` — later strict-mode destination for Message Signing posture

### Ecosystem references
- `https://docs.duendesoftware.com/identityserver/reference/endpoints/introspection/` — negotiated JWT introspection shape on a mature server
- `https://connect2id.com/products/server/docs/api/token-introspection` — introspection behavior and inactive-payload expectations
- `https://www.authlete.com/kb/oauth-and-openid-connect/introspection/jwt-introspection-response/` — endpoint-level JWT introspection framing
- `https://raw.githubusercontent.com/panva/node-oidc-provider/main/lib/actions/introspection.js` — practical negotiated representation precedent

### Code and tests
- `lib/lockspire/protocol/introspection.ex` — truthful introspection payload classification and inactive collapse
- `lib/lockspire/web/controllers/introspection_controller.ex` — current delivery adapter that will own negotiation and response representation
- `lib/lockspire/protocol/client_auth.ex` — shared direct-client authentication surface for introspection callers
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex` — existing authenticated-caller and effective-signing-policy precedent
- `lib/lockspire/protocol/id_token.ex` — purpose-specific JWT shaping precedent
- `lib/lockspire/protocol/logout_token.ex` — purpose-specific JWT shaping precedent
- `lib/lockspire/protocol/jarm.ex` — signing-key/JOSE implementation precedent, but not the exact contract to reuse verbatim
- `lib/lockspire/storage/key_store.ex` — active signing-key lookup seam
- `lib/lockspire/storage/ecto/repository.ex` — active signing-key fetch behavior and security-profile filtering
- `test/lockspire/protocol/introspection_test.exs` — current protocol payload truth and inactive-collapse coverage
- `test/lockspire/web/introspection_controller_test.exs` — current `/introspect` HTTP contract to extend with negotiation and JWT cases

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.Introspection` already cleanly separates caller auth, token lookup, lifecycle classification, and payload shaping. That is the correct source of the nested `token_introspection` payload.
- `Lockspire.Protocol.ClientAuth` already gives introspection a shared confidential-client authentication surface, including `private_key_jwt`, so Phase 73 should not invent a separate resource-server auth mechanism.
- `Lockspire.Protocol.IdToken` and `Lockspire.Protocol.LogoutToken` provide the best local precedent for a dedicated purpose-built signer with explicit header and claim shaping.
- `Lockspire.Protocol.Jarm` provides useful signing-key/JOSE mechanics and a cautionary precedent: reuse the infrastructure, but do not copy its claim contract because RFC 9701 requires a different envelope.
- `Repository.fetch_active_signing_key/1` and the current security-profile filtering already provide the right signing-key seam for this phase.

### Established Patterns

- Lockspire keeps controllers thin and protocol/security truth in protocol modules; Phase 73 should preserve that split by keeping token classification separate from response representation.
- Lockspire prefers one coherent crypto-policy plane derived from current runtime posture rather than per-feature ad hoc signing knobs.
- Lockspire favors truthful, narrow, standards-shaped public contracts over clever custom variants.
- Embedded-library DX is protected by avoiding host-app framework burden for protocol correctness.

### Integration Points

- The delivery decision belongs in `lib/lockspire/web/controllers/introspection_controller.ex`, with a small Lockspire-owned negotiation helper if needed.
- The JWT signing path should likely live in a new dedicated protocol module that consumes the payload from `Introspection` plus issuer/signing-key context from the existing repo/config seams.
- Tests should extend the current protocol and controller suites rather than introducing isolated one-off proof files.
- Phase 74 should consume this context when deciding what becomes mandatory under Message Signing strict mode, especially exact-header enforcement and possibly stricter caller expectations.

</code_context>

<deferred>
## Deferred Ideas

- Exact-header or mandatory-JWT enforcement for all compliant callers — Phase 74
- RFC 9701 response encryption and related metadata publication unless later planning proves they are already required in this milestone
- Any separate resource-server registration or identity model beyond the current direct-client caller surface
- Custom outer JWT claim contracts such as default top-level `exp`, `sub`, `jti`, or `nbf`
- Host-app MIME registration, custom Phoenix formats, or any framework-level setup that widens the embedded integration seam

</deferred>

---

*Phase: 73-jwt-introspection-responses*
*Context gathered: 2026-05-07*
