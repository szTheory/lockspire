# Phase 89: Registration, Discovery, And Admin Truth - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Lockspire's stored client metadata, DCR/RFC 7592 behavior, discovery metadata, and admin/operator surfaces tell one truthful story about the narrow shipped `client_secret_jwt` slice from Phase 88. This phase does not broaden runtime endpoint scope beyond the existing shared direct-client surfaces, does not add a generic JWT client-auth framework, and does not widen FAPI or stronger-trust claims.

</domain>

<decisions>
## Implementation Decisions

### Registration and persisted client-auth truth
- **D-01:** Treat `token_endpoint_auth_method=client_secret_jwt` and `token_endpoint_auth_signing_alg=HS256` as an explicit persisted pair for the shipped v1.24 slice. Do not silently infer or default the signing algorithm during DCR or operator creation.
- **D-02:** Accept `client_secret_jwt` only for confidential clients. Public-client combinations must fail closed as invalid client metadata.
- **D-03:** Require `token_endpoint_auth_signing_alg` when `token_endpoint_auth_method=client_secret_jwt`, and for v1.24 accept only `HS256`.
- **D-04:** Reject `HS384` and `HS512` for now even though the broader OIDC/RFC surface permits HMAC families. Phase 88 deliberately shipped an `HS256`-only runtime.
- **D-05:** Reject `token_endpoint_auth_signing_alg` when the auth method is neither `client_secret_jwt` nor `private_key_jwt`; do not preserve stray JWT-auth metadata on non-JWT client-auth records.
- **D-06:** Reject `client_secret_jwt` under effective FAPI security profiles so registration truth matches the Phase 88 runtime denial posture.
- **D-07:** Store client-auth signing-alg truth as typed durable client state, not metadata-only spillover. Downstream JSON, admin, and discovery output should derive from the stored client record.
- **D-08:** RFC 7592 full-replace semantics must stay explicit: switching to `client_secret_jwt` requires the alg field, switching away clears the stored alg, and omitting the alg while remaining on `client_secret_jwt` is an error rather than silent reuse.

### Discovery and endpoint metadata truth
- **D-09:** Preserve Lockspire's existing route-truthful discovery shape. Publish `client_secret_jwt` only on mounted endpoints that actually use the shared direct-client verifier.
- **D-10:** Keep endpoint-local auth-method publication for `/token`, `/revoke`, and `/introspect`; do not collapse Phase 89 into a looser issuer-wide claim that could outpace mounted-route truth.
- **D-11:** When an endpoint publishes either `client_secret_jwt` or `private_key_jwt`, publish the corresponding `*_auth_signing_alg_values_supported` field to satisfy RFC 8414.
- **D-12:** For each published endpoint, make the signing-alg metadata the union of JWT auth methods actually accepted there under the effective issuer posture:
  `HS256` for `client_secret_jwt`, plus the current asymmetric allowlist for `private_key_jwt`.
- **D-13:** Under FAPI profiles, do not publish `client_secret_jwt` and do not publish `HS256`; keep only the existing asymmetric FAPI-allowed discovery posture.
- **D-14:** Do not invent new non-standard endpoint-auth metadata for device authorization or backchannel authentication. Keep standards-facing discovery limited to the existing token/revocation/introspection fields.
- **D-15:** Discovery and docs must explain the mixed JWT-alg union truth explicitly so integrators understand that `HS256` applies only to `client_secret_jwt` while asymmetric algorithms apply only to `private_key_jwt`.

### Admin and operator truth
- **D-16:** Expose `client_secret_jwt` in operator client creation now so admin parity matches DCR/discovery truth; do not keep it as a DCR-only or hidden capability.
- **D-17:** Do not expose a broad editable signing-alg chooser in the admin UI for v1.24. The operator surface should reflect the shipped narrow truth, not imply broader algorithm support.
- **D-18:** Show the signing algorithm (`HS256`) explicitly as read-only truth anywhere `client_secret_jwt` is displayed in admin/detail/help copy so the surface stays honest without becoming a generic metadata editor.
- **D-19:** Preserve current immutable-field posture: auth method remains create-time security truth, later edits stay targeted workflows, and secret-handling/redaction posture remains unchanged.
- **D-20:** Operator wording should present `client_secret_jwt` as a narrow convenience auth method for direct-client endpoints, not as a stronger-trust or FAPI-capable posture.
- **D-21:** Keep secret-handling truth unchanged across operator and DCR surfaces: raw client secrets and raw assertions are never exposed after initial issuance, while the encrypted verifier derivative remains internal-only and redacted.

### Planning and escalation posture
- **D-22:** Downstream planner and executor should continue using the project methodology already in `.planning/METHODOLOGY.md`: assumption-first, research-first, decisive defaults, and high-threshold escalation.
- **D-23:** Escalate only if implementation would materially change the public support contract, widen endpoint scope beyond the Phase 88 direct-client list, relax the HS256-only/FAPI-denied posture, or require broadening the admin surface into a generic client-auth metadata editor.

### the agent's Discretion
- Exact field name and schema shape for storing client-auth signing-alg truth, provided it is typed durable client state and not metadata-only.
- Exact helper/module boundaries for shared client-auth metadata validation and discovery publication logic.
- Exact admin copy, section titles, and read-only presentation mechanics, provided `HS256` is explicit and the surface remains calm and narrow.
- Exact error reason-code vocabulary for new metadata validation branches, provided field attribution stays precise and wire behavior remains standard.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle is intentionally narrow and mutually reinforcing: explicit persisted auth-method + alg truth, route-truthful discovery, and operator creation that exposes the method without pretending Lockspire ships a broad editable JWT-auth matrix.
- Good ecosystem lessons to preserve:
  Doorkeeper-style host seam and install DX, `node-oidc-provider`-style serious protocol truth, OpenIddict-style separation between generic server core and host-specific integration, and Spring Authorization Server's first-class client metadata modeling.
- Footguns to avoid:
  implicit `HS256` defaults, metadata-only storage, publishing `HS256` without `client_secret_jwt`, publishing `client_secret_jwt` without endpoint signing-alg metadata, admin parity gaps, and any copy that implies FAPI or stronger trust than the runtime actually provides.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase boundary
- `.planning/PROJECT.md` — current v1.24 milestone intent, embedded-library boundary, and support-truth posture
- `.planning/REQUIREMENTS.md` — `REG-01`, `REG-02`, `META-01`, support-truth gate, and out-of-scope boundaries
- `.planning/ROADMAP.md` — Phase 89 goal, plan split, and success criteria
- `.planning/STATE.md` — current milestone state and next-step framing
- `.planning/METHODOLOGY.md` — assumption-first, research-first decisive defaults, and high-threshold escalation

### Prior phase truth
- `.planning/phases/88-shared-client-secret-jwt-runtime/88-CONTEXT.md` — Phase 88 runtime contract, endpoint scope, HS256-only posture, and FAPI denial
- `.planning/phases/87-CONTEXT.md` — support-truth architecture and canonical-doc discipline pattern

### Existing runtime, registration, and persistence seams
- `lib/lockspire/protocol/client_auth.ex` — shared direct-client auth routing and published/runtime method split
- `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` — shipped Phase 88 HS256 verifier, timing/replay/audit posture, and FAPI-sensitive runtime truth
- `lib/lockspire/protocol/registration.ex` — DCR intake validator and current client metadata coherence patterns
- `lib/lockspire/protocol/registration_management.ex` — RFC 7592 full-replace update path that must stay aligned with stored client-auth truth
- `lib/lockspire/protocol/dcr_policy.ex` — DCR allowlist intersection and auth-method policy envelope
- `lib/lockspire/protocol/discovery.ex` — current route-truthful endpoint auth publication and signing-alg metadata behavior
- `lib/lockspire/domain/client.ex` — durable client domain model that Phase 89 must keep coherent
- `lib/lockspire/storage/ecto/client_record.ex` — persisted enum/field truth and current missing `client_secret_jwt` persistence seam
- `lib/lockspire/clients.ex` — operator-created client normalization, secret material generation, and current auth-method validation boundary
- `lib/lockspire/admin/clients.ex` — immutable-field posture, targeted update workflows, and secret rotation/redaction flow
- `lib/lockspire/admin/server_policy.ex` — current registration-truth helper pattern used for admin DCR posture copy
- `lib/lockspire/security/policy.ex` — supported auth-method gate and sealed verifier helpers
- `lib/lockspire/redaction.ex` — redaction invariants for verifier material and related metadata

### Existing admin and docs surfaces
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — operator creation/edit form shape and current auth-method control
- `lib/lockspire/web/live/admin/clients_live/show.ex` — immutable posture copy and auth-method detail presentation
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` — current registration-truth wording pattern for JWT client-auth capabilities
- `docs/supported-surface.md` — canonical support contract that currently marks `client_secret_jwt` out of scope and must be updated carefully in later phases
- `docs/private-key-jwt-host-guide.md` — current narrow JWT client-auth guide and endpoint-scope wording pattern

### Existing proof surfaces
- `test/lockspire/protocol/client_auth_test.exs` — repo-native proof for valid/invalid `client_secret_jwt` runtime behavior and redaction
- `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` — representative cross-endpoint proof for the shipped direct-client runtime slice
- `test/lockspire/protocol/registration_test.exs` — DCR metadata validation and persistence proof pattern
- `test/lockspire/protocol/registration_management_test.exs` — RFC 7592 replace semantics and auth-method update proof pattern
- `test/lockspire/protocol/discovery_test.exs` — discovery metadata contract tests
- `test/lockspire/web/discovery_controller_test.exs` — mounted-route discovery truth proof
- `test/lockspire/admin/clients_test.exs` — operator create/show/update and secret-handling proof

### External standards and ecosystem references
- `https://openid.net/specs/openid-connect-registration-1_0.html` — client metadata definition for `token_endpoint_auth_signing_alg`
- `https://www.rfc-editor.org/rfc/rfc8414.html` — endpoint auth metadata and signing-alg publication requirements
- `https://documentation.openiddict.com/configuration/assertion-based-client-authentication` — security posture and migration framing for JWT client auth
- `https://docs.spring.io/spring-security/reference/7.1-SNAPSHOT/api/java/org/springframework/security/oauth2/server/authorization/settings/ConfigurationSettingNames.Client.html` — first-class client setting precedent for JWT auth signing alg
- `https://docs.spring.io/spring-security/reference/7.0-SNAPSHOT/servlet/oauth2/authorization-server/core-model-components.html` — registered-client metadata precedent including `client_secret_jwt`
- `https://github.com/panva/node-oidc-provider` — broad protocol-core precedent for shared client-auth truth across surfaces

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Protocol.Registration` already concentrates client metadata coherence checks in one Plug-free validator pipeline that both DCR create and later management flows reuse.
- `Lockspire.Protocol.Discovery` already uses mounted-route truth and endpoint-local auth metadata publication instead of broad issuer marketing claims.
- `Lockspire.Admin.Clients` and `ClientsLive.Show` already establish the product posture that security-sensitive client truth is create-time and later edits happen through targeted workflows.
- `Lockspire.Security.Policy` and `Lockspire.Redaction` already provide the internal secret-derivative and redaction seams needed to preserve current secret-handling truth.

### Established Patterns
- Lockspire prefers typed domain/storage truth over free-form metadata when a value affects protocol correctness, operator understanding, or published discovery behavior.
- Discovery metadata is already filtered by mounted endpoint truth, and signing-alg metadata is already conditional on JWT auth publication.
- Operator UX favors calm, explicit, read-only capability panels over sprawling generic editors.
- Support-truth docs are intentionally centralized, with adjacent guides deferring to `docs/supported-surface.md`.

### Integration Points
- Phase 89 must reconcile the current gap where the runtime/domain know about `client_secret_jwt` but `ClientRecord` persistence and RFC 7592 update mapping do not yet fully model it.
- Any new client-auth signing-alg field must flow through operator create, DCR create, RFC 7592 update/read, admin detail views, and discovery publication without parallel truth stores.
- Discovery publication logic will need method-aware JWT alg unions so the endpoint metadata remains truthful once both `private_key_jwt` and `client_secret_jwt` are advertised.

</code_context>

<deferred>
## Deferred Ideas

- Broader `client_secret_jwt` algorithm support beyond `HS256`
- FAPI-compatible support for `client_secret_jwt`
- Extending `client_secret_jwt` to `POST /par` or any endpoint outside the Phase 88 direct-client surface
- Turning the admin UI into a generic editable JWT client-auth metadata console
- New non-standard discovery metadata for device authorization or backchannel authentication

</deferred>

---

*Phase: 89-registration-discovery-and-admin-truth*
*Context gathered: 2026-05-25*
