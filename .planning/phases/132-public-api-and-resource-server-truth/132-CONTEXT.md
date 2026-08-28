# Phase 132: Public API and Resource-Server Truth - Context

**Gathered:** 2026-08-26 (assumptions mode, autonomous)
**Status:** Ready for planning

<domain>
## Phase Boundary

Align Lockspire's supported client-registration and Phoenix resource-server APIs with behavior the library actually ships. This phase adds normalized access-token accessors, makes advertised OIDC, `private_key_jwt`, and device-only client shapes registerable without weakening redirect validation, makes durable configured-repository DPoP replay protection the normal path, and corrects public examples and compatibility guidance. The clean-room separate-origin provider/client/resource-server journey remains Phase 133.

</domain>

<decisions>
## Implementation Decisions

### Public Access-Token Contract
- **D-01:** Add documented, additive `Lockspire.AccessToken` accessors for normalized subject, scopes, audiences, expiration, and confirmation data. Callers should not need to know whether JWT claims arrived as a scalar, space-delimited string, list, numeric date, or nested claim map.
- **D-02:** Preserve the current public struct fields and raw `claims` map for v1.x compatibility. Do not replace the struct, remove `claims`, or make existing integrations rewrite immediately.
- **D-03:** Use one normalization contract across token verification, route enforcement, and public accessors so authorization checks and application reads cannot interpret the same verified token differently.
- **D-04:** Prefer the semantic accessors in all supported examples. Treat raw claim access as an explicit low-level compatibility/extension path, not the normal resource-server API.

### Registration Shape Coherence
- **D-05:** Let public `Lockspire.Clients.register_client/1`, DCR, and their shared validation accept the protocol shapes Lockspire advertises: `openid` is a built-in OIDC scope; `private_key_jwt` remains a confidential-client method with the existing key-material constraints; and a device-code-only client may omit redirect URIs and code response types.
- **D-06:** Make redirect requirements capability-aware. Any authorization-code or other redirect-based shape still requires a non-empty set of valid redirect URIs and exact-match runtime validation; relaxing device-only registration must not create a redirect bypass for mixed or code-flow clients.
- **D-07:** Keep direct/operator and dynamic registration behavior coherent by centralizing or sharing shape validation rather than maintaining endpoint-specific exceptions.
- **D-08:** Preserve current error contracts where possible; new shape-specific errors must be actionable and deterministic without leaking key material or weakening client authentication.

### DPoP Replay-Store Boundary
- **D-09:** Default protected-resource DPoP replay recording to `Lockspire.Storage.Ecto.Repository`, which resolves the configured host repo through `Lockspire.Config.repo!/0` and uses the shipped durable replay table and uniqueness constraint.
- **D-10:** Preserve dependency injection through the existing `Lockspire.Storage.DpopReplayStore` behavior so tests and advanced hosts may provide a compatible custom store.
- **D-11:** Replay persistence remains fail-closed. A storage error must never silently degrade to process-local, optional, or skipped replay checking, and duplicate proofs must remain rejected across requests and nodes sharing the repository.
- **D-12:** Document the configured repository as the ordinary installed-host path; custom stores are an advanced override, not a prerequisite for safe adoption.

### Documentation and Compatibility
- **D-13:** Make `docs/protect-phoenix-api-routes.md`, generated protected-route comments, supported-surface wording, and public API docs agree with compiled behavior and exact accessor names/types.
- **D-14:** Keep the authorization boundary explicit: Lockspire verifies token protocol facts and route-level scope/audience/sender constraints; the host app owns tenant membership, object authorization, billing/product rules, response shaping, and any additional rate limits.
- **D-15:** Use additive/deprecation-led v1.x evolution. Existing supported entry points remain available; any genuinely superseded API receives truthful migration guidance and, where removal is intended, explicit deprecation rather than a silent semantic change.
- **D-16:** Phase 132 proves these contracts with focused unit/integration/documentation tests. It does not create the external client app or duplicate the full HTTP lifecycle acceptance journey assigned to Phase 133.

### the agent's Discretion
- Exact accessor names and return types, provided they are unsurprising, typed, normalized, consistent with verifier behavior, and documented with nil/empty/malformed-edge semantics.
- Internal placement of shared registration-shape and claim-normalization helpers, provided public facades remain small and protocol/storage boundaries stay directional.
- Whether generated router comments link to or briefly summarize the canonical guide, provided there is one source of truth and drift is executable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` — embedded-library boundary, v1.37 goal, and compatibility posture.
- `.planning/REQUIREMENTS.md` — API-01 through API-04 acceptance requirements.
- `.planning/ROADMAP.md` — Phase 132 success criteria and Phase 133 boundary.
- `.planning/phases/131-executable-installation/131-CONTEXT.md` — generated-host decisions and explicit deferral of public API/resource-server work.
- `lib/lockspire/access_token.ex` — current public token struct contract.
- `lib/lockspire/plug/verify_token.ex` — existing internal claim normalization and verified-token assignment.
- `lib/lockspire/plug/enforce_sender_constraints.ex` — route sender-constraint integration.
- `lib/lockspire/clients.ex` — current public client-registration validation.
- `lib/lockspire/protocol/registration.ex` — DCR path and client-shape mapping.
- `lib/lockspire/protocol/authorization_request.ex` — shipped OIDC scope handling.
- `lib/lockspire/protocol/discovery.ex` — advertised OAuth/OIDC capabilities.
- `lib/lockspire/protocol/protected_resource_dpop.ex` — current default/custom replay-store resolution.
- `lib/lockspire/storage/dpop_replay_store.ex` — custom-store behavior contract.
- `lib/lockspire/storage/ecto/repository.ex` — configured-repository durable implementation.
- `priv/repo/migrations/20260428150000_add_lockspire_dpop_replay_state.exs` — durable replay schema and uniqueness.
- `docs/protect-phoenix-api-routes.md` — canonical resource-server adoption guide requiring correction.
- `docs/private-key-jwt-host-guide.md` — supported `private_key_jwt` shape and key constraints.
- `docs/device-flow-host-guide.md` — shipped device-only behavior.
- `docs/supported-surface.md` — public support and compatibility claims.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Plug.VerifyToken` already normalizes the five target JWT claim families internally; the public accessors should reuse that semantic contract rather than invent a second parser.
- `Lockspire.Storage.Ecto.Repository` already implements `DpopReplayStore` with configured-repo resolution and a database uniqueness boundary.
- DCR already exercises `private_key_jwt` key-material validation, and shipped device token exchange establishes the device-only capability this phase must make registerable.

### Established Patterns
- Public facades stay additive and small while protocol services own validation and storage adapters own persistence.
- Host seams own business policy; Lockspire-owned plugs decide only protocol validity and declared route constraints.
- Runtime and docs claims require executable tests, including negative cases that prove a narrow exception does not broaden adjacent flows.

### Integration Points
- AccessToken construction and verifier normalization, scope/audience plugs, sender-constraint enforcement, client registration and DCR validation, DPoP replay-store selection, generated router guidance, ExDoc, supported-surface docs, and release/docs contract tests.

</code_context>

<specifics>
## Specific Ideas

- The best result reads like a deliberately designed Elixir API: semantic accessors with one stable normalization rule, capability-shaped registration errors, and a default replay path that works after the Phase 131 installer has delivered migrations.
- Negative proof is essential: device-only relaxation must not permit an authorization-code client without redirects, and custom DPoP injection must not make the default repository path optional or in-memory.

</specifics>

<deferred>
## Deferred Ideas

- The separate-origin confidential client, full authorization/token lifecycle, protected SaaS API, and black-box durable replay journey belong to Phase 133.
- Internal dependency-graph restructuring beyond the minimum required for a truthful shared contract belongs to Phase 134.
- New grants, hosted authorization, and host product-policy APIs remain outside v1.37.

</deferred>
