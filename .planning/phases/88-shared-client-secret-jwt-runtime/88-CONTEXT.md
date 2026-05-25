# Phase 88: Shared `client_secret_jwt` Runtime - Context

**Gathered:** 2026-05-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend Lockspire's shared direct-client authentication runtime so confidential clients registered for `client_secret_jwt` can authenticate on the shipped Lockspire-owned direct-client endpoints, with strict replay, audience, lifetime, and algorithm enforcement that preserves the current embedded-library and secret-handling posture.
</domain>

<decisions>
## Implementation Decisions

### Shared auth routing
- **D-01:** `Lockspire.Protocol.ClientAuth.authenticate/3` must stop implicitly treating every JWT client assertion as `private_key_jwt` and instead resolve JWT assertion handling explicitly from the stored `token_endpoint_auth_method` after client lookup.
- **D-02:** Runtime behavior must continue to fail closed as `invalid_client` when the attempted assertion mode does not match the registered client auth method; `client_secret_jwt` must not silently fall back to `client_secret_basic`, `client_secret_post`, or `private_key_jwt`.

### Direct-client runtime surface
- **D-03:** Phase 88 covers only the currently shipped Lockspire-owned direct-client endpoints that already share the client-auth runtime: `POST /token`, `POST /revoke`, `POST /introspect`, `POST /device/code`, and `POST /bc-authorize`.
- **D-04:** `POST /par` is not part of the Phase 88 shipped `client_secret_jwt` surface unless a later phase explicitly broadens support truth and proof for it.

### Assertion validation posture
- **D-05:** `client_secret_jwt` must inherit the existing strict assertion contract already enforced for verifier-backed JWT client auth where it applies: issuer-string `aud`, `iss` and `sub` bound to the client identifier, bounded lifetime, required `jti`, replay recording only after verified claims, and generic wire-level `invalid_client` failures.
- **D-06:** Replay, telemetry, and durable audit handling must preserve the current redaction posture: no raw `client_assertion`, JWT claims/header, or secret-derived material may leak through telemetry or audit metadata.

### Algorithm and security-profile posture
- **D-07:** The Phase 88 runtime slice is intentionally narrow: `client_secret_jwt` should accept `HS256` only.
- **D-08:** `client_secret_jwt` is unavailable under FAPI security profiles in v1.24; this milestone must not broaden FAPI, mTLS, or higher-trust claims through the symmetric-JWT slice.

### the agent's Discretion
- Exact verifier module shape and how much code is shared vs split between `private_key_jwt` and `client_secret_jwt`, provided explicit auth-method routing and strict fail-closed behavior remain intact.
- Exact reason-code mapping for new symmetric-JWT-specific failures, provided the wire contract remains standard `invalid_client` and the current telemetry/audit redaction posture is preserved.
- Whether representative cross-endpoint proof lives in one shared runtime test module or a mix of client-auth and endpoint-level protocol tests.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase boundary
- `.planning/PROJECT.md` — v1.24 milestone goal, narrow embedded-library boundary, and support-truth posture for `client_secret_jwt`
- `.planning/REQUIREMENTS.md` — `AUTH-01` and `AUTH-02`, proof posture, support-truth guardrails, and explicit out-of-scope boundaries
- `.planning/ROADMAP.md` — Phase 88 goal, plans, and success criteria
- `.planning/STATE.md` — current milestone state and next-step framing

### Prior phase context
- `.planning/phases/87-CONTEXT.md` — recent support-truth decision pattern and high-threshold escalation posture

### Existing runtime and security seams
- `lib/lockspire/protocol/client_auth.ex` — shared direct-client auth entry point and current implicit JWT assertion routing
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex` — existing strict JWT client-assertion verifier contract, replay handling, telemetry, and audit behavior
- `lib/lockspire/protocol/introspection.ex` — representative shared direct-client auth consumer
- `lib/lockspire/protocol/revocation.ex` — representative shared direct-client auth consumer
- `lib/lockspire/protocol/device_authorization.ex` — representative shared direct-client auth consumer
- `lib/lockspire/protocol/backchannel_authentication.ex` — representative shared direct-client auth consumer
- `lib/lockspire/protocol/token_exchange.ex` — token-endpoint-side shared client-auth usage pattern
- `lib/lockspire/protocol/discovery.ex` — current direct-client auth publication and endpoint metadata truth shape
- `lib/lockspire/security/policy.ex` — supported auth-method seam and shared secret hashing/verification utilities
- `lib/lockspire/protocol/security_profile.ex` — effective security-profile resolution and current signing-algorithm allowlists
- `lib/lockspire/domain/client.ex` — durable client auth-method shape and client profile fields
- `lib/lockspire/storage/ecto/client_record.ex` — persisted enum-backed auth-method storage
- `lib/lockspire/redaction.ex` — telemetry and audit redaction invariants for sensitive material

### Existing docs and proof
- `docs/supported-surface.md` — canonical support contract, including current explicit “`client_secret_jwt` out of scope” truth that later phases must update carefully
- `docs/private-key-jwt-host-guide.md` — current narrow direct-client JWT auth slice, issuer-string `aud`, and shipped endpoint scope
- `docs/install-and-onboard.md` — onboarding truth that currently points confidential-client JWT auth users only to `private_key_jwt`
- `test/lockspire/protocol/client_auth_test.exs` — strict JWT assertion behavior, replay, telemetry, and audit proof
- `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` — representative cross-endpoint proof for the shipped direct-client verifier surface
- `test/lockspire/protocol/discovery_test.exs` — current endpoint auth-method and signing-algorithm discovery truth
- `test/lockspire/audit/event_test.exs` — audit redaction proof for JWT client-auth failures
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Protocol.ClientAuth` already centralizes parsing, client lookup, method validation, and endpoint-facing `invalid_client` error shaping.
- `Lockspire.Protocol.ClientAuth.PrivateKeyJwt` already provides the strict assertion-validation pattern to mirror for audience, timing, replay, telemetry, and audit behavior.
- `Lockspire.Security.Policy.verify_client_secret/2` provides the existing hashed-secret comparison primitive that may constrain how symmetric assertion verification is modeled against stored client-secret truth.
- `Lockspire.Redaction` and `Lockspire.Audit.Event` already enforce sensitive-field stripping for telemetry and audit output.

### Established Patterns
- Shared direct-client endpoint protocols delegate client authentication to `ClientAuth.authenticate/3` and translate `ClientAuth.Error` into endpoint-local error structs without changing wire behavior.
- Discovery and support truth are kept narrow and route-sensitive; published auth-method metadata is expected to align with actual shared runtime support.
- Security-profile posture is centralized through `Lockspire.Protocol.SecurityProfile`, and stricter profiles narrow accepted algorithms rather than widening convenience modes.

### Integration Points
- New runtime work must connect to the existing `ClientAuth.authenticate/3` flow without widening host seams or introducing a separate auth service boundary.
- Cross-endpoint proof should follow the existing representative-direct-client-surface pattern used for `private_key_jwt`.
- Later registration/discovery/admin phases will need the Phase 88 runtime truth to be stable so they can expose `client_secret_jwt` coherently without reopening runtime semantics.
</code_context>

<specifics>
## Specific Ideas

- Keep the Phase 88 `client_secret_jwt` slice deliberately narrower than `private_key_jwt`: no generic symmetric-JWT framework, no endpoint creep, and no accidental FAPI broadening.
- Preserve the same least-surprise operator and support story already used for other Lockspire direct-client auth methods: one shared runtime path, one truthful endpoint scope, one fail-closed wire contract.
</specifics>

<deferred>
## Deferred Ideas

- Adding `client_secret_jwt` to `POST /par` or any other surface outside the currently shipped direct-client scope
- Broadening symmetric JWT algorithm support beyond `HS256`
- Supporting `client_secret_jwt` under FAPI security profiles
- Any wider secret-management UX, recoverable secret storage, or generic JWT client-auth framework
</deferred>

---

*Phase: 88-shared-client-secret-jwt-runtime*
*Context gathered: 2026-05-25*
