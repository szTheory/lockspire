# Phase 59: Registration, Policy & Metadata Truth - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 59 defines the truthful contract for Lockspire's `jwks_uri` + `private_key_jwt` slice before the guarded fetcher and full verifier work lands in Phases 60-61. The phase covers DCR / RFC 7592 intake-update rules, operator-policy truth, and discovery / revocation / introspection metadata truth for the supported direct-client authentication surface.

This phase does **not** broaden Lockspire into a general remote metadata platform, a broader operator key-management console, or a separate configurable crypto-control plane. It keeps the embedded-library shape intact and sets downstream phases up to implement a narrow, secure, unsurprising confidential-client authentication wedge.

</domain>

<decisions>
## Implementation Decisions

### Scope and product-shape posture

- **D-01:** Keep v1.15 limited to `jwks_uri` plus `private_key_jwt`. Do not widen into `client_secret_jwt`, mTLS, signed metadata, federation trust chains, or generic outbound metadata ingestion.
- **D-02:** Preserve the embedded-library boundary. Dangerous remote-key resolution and assertion verification remain Lockspire-owned; host apps should not own SSRF controls, JWT signature trust, or endpoint-metadata truth for this slice.
- **D-03:** Downstream agents should prefer strong, coherent recommendations over broad option menus. Escalate back to the user only for decisions that materially change public API, security posture, or product shape.

### Registration and RFC 7592 management truth

- **D-04:** `jwks_uri` is accepted only for the supported confidential-client slice where `token_endpoint_auth_method = "private_key_jwt"`. Phase 59 does not authorize `jwks_uri` for other auth methods or other remote-ingestion stories.
- **D-05:** `jwks` and `jwks_uri` remain strictly mutually exclusive across registration and update flows, with explicit `invalid_client_metadata` errors.
- **D-06:** `private_key_jwt` registrations must still provide cryptographic material (`jwks` or `jwks_uri`) at intake time; Phase 59 should not create placeholder clients that claim JWT auth but cannot possibly verify.
- **D-07:** The repo should keep DCR / RFC 7592 metadata truth ahead of operator-UI completeness. Registration/update behavior and published metadata are the contract-setting priority for this phase.

### Operator workflow posture

- **D-08:** Phase 59 will **not** add first-class admin create/edit workflows for operator-created `private_key_jwt` clients.
- **D-09:** Operator-facing Phase 59 work is limited to truthful policy visibility and explanatory UX around the supported slice, not a new key-management workflow.
- **D-10:** Expansion of admin client UX for operator-created `private_key_jwt` clients is deferred until guarded JWKS retrieval and shared assertion verification are implemented and repo-proven in later phases.

### Algorithm policy surface

- **D-11:** Accepted `private_key_jwt` signing algorithms are derived from Lockspire's effective issuer security posture, not from a separate operator-configurable algorithm allowlist.
- **D-12:** Operator surfaces should display the effective supported JWT client-assertion algorithms read-only. They should explain the result of policy, not ask operators to design crypto policy manually.
- **D-13:** Discovery and endpoint metadata must publish only the effective signing-algorithm set that Lockspire will actually enforce for this slice.
- **D-14:** Phase 59 must avoid creating a second crypto-policy plane that can drift from `security_profile`, FAPI posture, or runtime verifier behavior.

### Metadata truth model

- **D-15:** Token, revocation, and introspection metadata should be computed from endpoint-specific truth predicates backed by one shared direct-client-auth capability source.
- **D-16:** When mounted endpoints share the same effective `private_key_jwt` behavior, their published auth-method and signing-algorithm sets should match.
- **D-17:** If revocation or introspection later diverges in real enforcement behavior, that endpoint may publish a narrower set automatically. Metadata-only divergence knobs are rejected.
- **D-18:** JWT signing-algorithm metadata should be published only for endpoints that actually publish a JWT client-auth method.
- **D-19:** Discovery truth stays centralized in `Lockspire.Protocol.Discovery`, not scattered across controllers or per-endpoint ad hoc logic.

### Security and least-surprise guardrails

- **D-20:** Do not add admin-side remote JWKS preview/test-fetch affordances in Phase 59. Those would imply fetch-safety guarantees before Phase 60 proves them.
- **D-21:** Do not publish `private_key_jwt` on any endpoint before the effective endpoint behavior actually accepts and verifies it.
- **D-22:** Keep audience expectations issuer-bound across the `private_key_jwt` slice. Do not introduce endpoint-URL audience flexibility.

### the agent's Discretion

- Exact helper names and internal decomposition for discovery truth predicates.
- Exact wording in admin policy help text, docs, and metadata-oriented tests, as long as it stays recommendation-heavy and truthful.
- Whether to expose the effective algorithm set through shared helper functions or through a security-profile-specific capability helper, provided runtime and metadata truth stay coupled.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation set for this phase is:
  - keep operator workflow narrow for now,
  - derive assertion algorithms from security posture,
  - use endpoint-specific metadata publication backed by one shared capability source,
  - bias downstream work toward standard-path recommendations instead of repeatedly re-asking low-impact branches.
- This matches the repo's existing shape:
  - `Lockspire.Protocol.Registration` and `Lockspire.Protocol.RegistrationManagement` already own DCR/RFC 7592 metadata behavior.
  - `Lockspire.Protocol.Discovery` already centralizes metadata truth.
  - `Lockspire.Protocol.ClientAuth` is the natural shared seam for direct-client authentication behavior.
  - current admin client LiveView workflows are intentionally narrow and task-specific rather than a broad auth-server console.
- In the broader ecosystem, the main lesson is to avoid prematurely copying standalone-provider UX into an embedded library:
  - broad consoles like Keycloak can afford richer operator workflows, but they also normalize configuration sprawl and easy crypto footguns;
  - library-oriented systems and framework integrations do better when the runtime contract is narrow, derived, and truthful;
  - the recurring mistake is to let UI, metadata, and verifier behavior drift apart.
- The DX principle for Phase 59 is: publish explicit, trustworthy behavior and defer convenience surfaces that would overclaim security-sensitive support.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning artifacts
- `.planning/PROJECT.md` — v1.15 goal, embedded-library boundary, active requirements posture
- `.planning/REQUIREMENTS.md` — `REG-01`, `REG-02`, `REG-03`, `META-01`, `META-02`
- `.planning/ROADMAP.md` — Phase 59 goal, plans, and success criteria
- `.planning/STATE.md` — current milestone state and historical carry-forward constraints
- `.planning/research/SUMMARY.md` — milestone research summary and recommended narrow wedge

### Prior phase context
- `.planning/phases/25-dcr-storage-skeleton-domain-types-and-policy-resolver/25-CONTEXT.md` — DCR policy shape, discovery-binding precedent, and historical `jwks_uri` deferral
- `.planning/phases/26-protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co/26-CONTEXT.md` — DCR/RFC 7592 protocol-module shape and explicit earlier `jwks_uri` rejection
- `.planning/phases/58-milestone-closure-discovery/58-CONTEXT.md` — discovery truth philosophy and recommendation-heavy downstream preference

### Code and tests
- `lib/lockspire/protocol/registration.ex` — current intake validation and `jwks` / `jwks_uri` handling
- `lib/lockspire/protocol/registration_management.ex` — RFC 7592 update path and client metadata application
- `lib/lockspire/protocol/discovery.ex` — centralized discovery metadata logic
- `lib/lockspire/protocol/client_auth.ex` — shared direct-client auth seam
- `lib/lockspire/protocol/security_profile.ex` — effective signing-algorithm posture source
- `lib/lockspire/protocol/introspection.ex` — endpoint-specific caller constraints
- `lib/lockspire/protocol/revocation.ex` — endpoint-specific direct-client auth path
- `lib/lockspire/domain/server_policy.ex` — durable policy boundary
- `lib/lockspire/domain/client.ex` — durable client fields including `jwks` and `jwks_uri`
- `lib/lockspire/storage/ecto/client_record.ex` — update-boundary warnings and current DCR/admin field separation
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` — operator DCR policy surface
- `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` — DCR policy form shape
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — current admin client workflow scope
- `lib/lockspire/web/live/admin/clients_live/show.ex` — current client detail UX and edit workflow boundaries
- `test/support/fixtures/dcr_fixtures.ex` — existing DCR fixtures and auth-method allowlist assumptions
- `test/lockspire/web/discovery_controller_test.exs` — discovery truth tests to extend
- `docs/maintainer-conformance.md` — current support-truth wording that Phase 59/61 will need to bring back into alignment later in the milestone

### Historical non-normative reference
- `.planning/phases/45-s02-dynamic-jwks-fetching/45-S02-STRATEGY.md` — useful prior thinking on keeping remote JWKS caching narrow and library-friendly; informative, not milestone-binding

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.Registration` already centralizes DCR slice validation, including `jwks` xor `jwks_uri` checks and `private_key_jwt` cryptographic-material requirements.
- `Lockspire.Protocol.RegistrationManagement` already mirrors DCR metadata application for RFC 7592 updates and is the right place for truth-preserving management behavior.
- `Lockspire.Protocol.Discovery` already owns route-aware metadata publication and should remain the only place where endpoint auth-method/signing-alg truth is assembled.
- `Lockspire.Protocol.ClientAuth` is already shared by token-adjacent direct-client endpoints and should remain the capability source that metadata truth follows.
- `Lockspire.Protocol.SecurityProfile` already models coarse-grained cryptographic posture and should remain the source of effective algorithm decisions.

### Established Patterns

- Narrow durable policy enums and derived runtime behavior are preferred over freeform operator-configured crypto lists.
- Controllers are thin delivery adapters; protocol modules own behavior and truth.
- LiveView admin workflows are intentionally scoped, not a general-purpose security console.
- Discovery metadata should be explicit and truthful to mounted, effective behavior, not marketing claims or future intent.

### Integration Points

- Phase 59 planning should treat `registration.ex`, `registration_management.ex`, `discovery.ex`, DCR policy UI, and discovery tests as the main implementation center.
- Any admin-surface changes in this phase should stay on the policy/truth side, not broaden into full operator client-key workflows.
- Later phases should be able to consume Phase 59's truth helpers directly:
  - Phase 60 for guarded remote JWKS resolution
  - Phase 61 for shared `private_key_jwt` verification and endpoint enforcement

</code_context>

<deferred>
## Deferred Ideas

- First-class admin create/edit workflow for operator-created `private_key_jwt` clients
- Admin-side JWKS preview/test fetch actions
- Separate operator-configurable JWT client-assertion algorithm allowlists
- Metadata-only divergence knobs between token, revocation, and introspection
- Broader auth-method expansion such as `client_secret_jwt` or mTLS
- Generic outbound remote metadata ingestion infrastructure

</deferred>

---

*Phase: 59-registration-policy-metadata-truth*
*Context gathered: 2026-05-06*
