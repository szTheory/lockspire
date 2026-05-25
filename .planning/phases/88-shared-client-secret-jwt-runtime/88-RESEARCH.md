# Phase 88: Shared `client_secret_jwt` Runtime - Research

**Researched:** 2026-05-25
**Domain:** narrow symmetric JWT client authentication on shared direct-client surfaces
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### The agent's Discretion
- Exact verifier module shape and how much code is shared vs split between `private_key_jwt` and `client_secret_jwt`, provided explicit auth-method routing and strict fail-closed behavior remain intact.
- Exact reason-code mapping for new symmetric-JWT-specific failures, provided the wire contract remains standard `invalid_client` and the current telemetry/audit redaction posture is preserved.
- Whether representative cross-endpoint proof lives in one shared runtime test module or a mix of client-auth and endpoint-level protocol tests.

### Deferred Ideas (OUT OF SCOPE)
- Adding `client_secret_jwt` to `POST /par` or any other surface outside the currently shipped direct-client scope
- Broadening symmetric JWT algorithm support beyond `HS256`
- Supporting `client_secret_jwt` under FAPI security profiles
- Any wider secret-management UX, recoverable secret storage, or generic JWT client-auth framework
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | A confidential client registered for `client_secret_jwt` can authenticate successfully on Lockspire-owned shared direct-client endpoints using a valid signed assertion instead of `client_secret_basic` or `client_secret_post`. | Reuse shared `ClientAuth` delegate path with explicit JWT method routing and a symmetric verifier module. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`] |
| AUTH-02 | Lockspire rejects malformed, replayed, expired, audience-mismatched, method-mismatched, or algorithm-disallowed `client_secret_jwt` assertions with standard `invalid_client` behavior across the shared direct-client surfaces. | Mirror `private_key_jwt` sequencing for claim validation, replay recording, telemetry, and endpoint-local error shaping. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`] |
</phase_requirements>

## Summary

Lockspire already has the correct architectural seam for Phase 88: all shipped direct-client surfaces delegate authentication through `Lockspire.Protocol.ClientAuth.authenticate/3`, and endpoint modules translate `ClientAuth.Error` into local `%Error{}` structs without learning auth-method specifics. The only runtime truth gap is that JWT bearer assertions are still parsed as `:private_key_jwt` before the stored client auth method is known. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`] [VERIFIED: `lib/lockspire/protocol/introspection.ex`] [VERIFIED: `lib/lockspire/protocol/revocation.ex`] [VERIFIED: `lib/lockspire/protocol/device_authorization.ex`] [VERIFIED: `lib/lockspire/protocol/backchannel_authentication.ex`] [VERIFIED: `lib/lockspire/protocol/token_exchange.ex`]

The narrowest safe Phase 88 design is to keep tentative JWT client-id extraction, fetch the client, then resolve JWT assertion verification explicitly from the stored `token_endpoint_auth_method`. `private_key_jwt` should continue to use the existing asymmetric verifier, while `client_secret_jwt` should use a new verifier module that follows the same sequencing and redaction posture but verifies `HS256` assertions against the existing hashed client-secret boundary rather than new recoverable secret storage. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`] [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `lib/lockspire/security/policy.ex`]

The strongest proof pattern already exists in-repo: `test/lockspire/protocol/client_auth_test.exs` proves success, audience/lifetime/algorithm failures, replay handling, and telemetry/audit behavior for `private_key_jwt`, while `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` proves shared runtime behavior across representative direct-client surfaces. Phase 88 should mirror those two proof layers for `client_secret_jwt` rather than teaching individual endpoint modules about symmetric JWT behavior. [VERIFIED: `test/lockspire/protocol/client_auth_test.exs`] [VERIFIED: `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`]

**Primary recommendation:** Split Phase 88 into three runtime-first plans: explicit auth-method routing plus verifier dispatch in `ClientAuth`, strict `client_secret_jwt` verifier behavior with `HS256`-only and FAPI-deny posture, and representative success/failure proof across shared direct-client surfaces. [VERIFIED: `.planning/ROADMAP.md`]

## Recommended Runtime Design

### 1. Explicit JWT method routing after client lookup

- Preserve the current tentative JWT client-id extraction in `peek_jwt_client_id/1`, because it supports client lookup without trusting the assertion yet. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`]
- Change the parsed JWT bearer method from hard-coded `:private_key_jwt` to a neutral tentative marker such as `:jwt_client_assertion`, then resolve it against `client.token_endpoint_auth_method` only after `fetch_client/2`. This prevents implicit routing through the asymmetric verifier and keeps method mismatch failures fail-closed. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`]
- Keep `validate_registered_auth_method/2` as the method-gate of record. It already returns `invalid_client` with `:unsupported_token_endpoint_auth_method` on attempted-method mismatch; Phase 88 should preserve that wire contract. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`]

### 2. New `ClientSecretJwt` verifier with the same sequencing as `PrivateKeyJwt`

- Add `Lockspire.Protocol.ClientAuth.ClientSecretJwt` under `lib/lockspire/protocol/client_auth/` as a sibling of `PrivateKeyJwt`. Keep the top-level contract `verify(client, assertion, opts) :: :ok | {:error, atom()}` the same so `ClientAuth` can dispatch without special-case error shaping. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`]
- Mirror the existing verifier sequence exactly where it applies: decode/verify signature, validate algorithm, validate claims, then record replay. Replay must still be recorded only after verified claims succeed. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`]
- Use the existing issuer-string audience contract (`Config.issuer!()`), required `iss`/`sub` binding to `client.client_id`, `exp`, and either `iat` or `nbf`, plus the current `@max_assertion_age` and clock skew values unless implementation evidence forces a narrower bound. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`]

### 3. HS256-only and security-profile-aware posture

- Keep `client_secret_jwt` narrower than `private_key_jwt`: accept `HS256` only, and reject all other algorithms including `HS384`, `HS512`, `RS256`, and `alg=none`. [VERIFIED: `.planning/phases/88-shared-client-secret-jwt-runtime/88-CONTEXT.md`] [VERIFIED: `.planning/REQUIREMENTS.md`]
- Consult `Lockspire.Protocol.SecurityProfile.resolve_effective_profile/2` so the verifier can deny `client_secret_jwt` outright under FAPI or any stronger profile that should not admit symmetric client assertions in this milestone. The important behavior is fail-closed profile truth, not broad algorithm negotiation. [VERIFIED: `lib/lockspire/protocol/security_profile.ex`] [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`]

### 4. Preserve the current secret-storage boundary

- The verifier must authenticate with the existing stored client secret truth, which is hashed at rest and compared via `Lockspire.Security.Policy.verify_client_secret/2`. Phase 88 must not introduce recoverable secrets, reusable symmetric JWK state, or a new host seam for raw secret lookup. [VERIFIED: `lib/lockspire/security/policy.ex`] [VERIFIED: `.planning/REQUIREMENTS.md`]
- The implementation detail is likely a brute-force style verification against the presented assertion's signing input using a raw client secret supplied only in test/local setup, or a JOSE-based HMAC verification path coupled to the current secret comparison boundary. The constraint is architectural: any working implementation must leave stored secrets hashed at rest and invisible outside current runtime needs. [INFERRED from `lib/lockspire/security/policy.ex` and milestone constraints]

## Existing Evidence And Reusable Proof

- `test/lockspire/protocol/client_auth_test.exs` already provides the exact unit-level test shapes to mirror for signed-success, bad-signature, bad-audience, replay, and stable telemetry/audit metadata. Add a sibling `describe "authenticate/3 with client_secret_jwt"` block rather than creating a new unit-test file. [VERIFIED: `test/lockspire/protocol/client_auth_test.exs`]
- `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` already shows the representative cross-endpoint proof set Phase 88 needs: introspection, revocation, device authorization, and backchannel authentication success plus a consistent invalid-client failure sweep. Create the symmetric slice as a role-match companion test module. [VERIFIED: `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`]
- `test/lockspire/audit/event_test.exs` already checks that verifier-originated audit events are normalized without leaking raw assertion or key material. Phase 88 should extend that proof to `client_secret_jwt`-specific failure metadata if new event metadata fields are introduced. [VERIFIED: `test/lockspire/audit/event_test.exs`]
- `lib/lockspire/protocol/discovery.ex` and discovery tests are useful only as non-goal guardrails in this phase: they currently publish `private_key_jwt` truth and will be updated in Phase 89, not Phase 88. [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [VERIFIED: `test/lockspire/protocol/discovery_test.exs`]

## Risks And Pitfalls

### Routing and support-truth drift

- If JWT bearer assertions continue to parse directly as `:private_key_jwt`, runtime truth will diverge immediately from the planned `client_secret_jwt` slice and the wrong verifier will keep handling symmetric assertions. This is the main blocker Phase 88 must remove first. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`]
- Endpoint modules must remain ignorant of auth-method differences. Adding endpoint-local `client_secret_jwt` branches would create surface drift and make later discovery truth harder to keep coherent. [VERIFIED: `lib/lockspire/protocol/introspection.ex`] [VERIFIED: `lib/lockspire/protocol/revocation.ex`] [VERIFIED: `lib/lockspire/protocol/device_authorization.ex`] [VERIFIED: `lib/lockspire/protocol/backchannel_authentication.ex`]

### Secret-handling and observability drift

- Symmetric JWT support is easy to implement incorrectly by introducing recoverable secrets, logging assertion payloads, or putting new secret-derived metadata into telemetry or audit events. The `PrivateKeyJwt` metadata shape is the safe analog to copy. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `lib/lockspire/redaction.ex`] [VERIFIED: `test/lockspire/audit/event_test.exs`]
- Replay recording must remain post-verification only. Recording `jti` before audience or signature validation would create denial-of-service and correctness bugs. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `test/lockspire/protocol/client_auth_test.exs`]

### Security-profile widening

- `client_secret_jwt` must not broaden the current FAPI truth. Any implementation that simply treats `HS256` as another allowed signing algorithm under the existing profile allowlists risks advertising or accepting symmetric JWT under stronger profiles later. Keep the deny logic explicit in the new verifier or the dispatch seam. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/phases/88-shared-client-secret-jwt-runtime/88-CONTEXT.md`] [VERIFIED: `lib/lockspire/protocol/security_profile.ex`]

### Scope creep into later phases

- Discovery metadata, DCR/admin persistence, and support-surface docs are Phase 89 and 90 work. Phase 88 should keep those files untouched unless a test fixture or existing invariant proves they must change for runtime stability. [VERIFIED: `.planning/ROADMAP.md`] [VERIFIED: `.planning/REQUIREMENTS.md`]
- `POST /par` is intentionally out of scope in this phase even though earlier direct-client slices reused shared auth there. Do not add PAR proof or metadata changes here. [VERIFIED: `.planning/phases/88-shared-client-secret-jwt-runtime/88-CONTEXT.md`]

## Recommended Plan Split

1. **Runtime routing and dispatch:** update `Lockspire.Protocol.ClientAuth` so JWT bearer assertions are resolved explicitly from the stored client auth method and dispatched to either `PrivateKeyJwt` or `ClientSecretJwt`, while keeping fail-closed mismatch behavior. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`]
2. **Verifier and posture enforcement:** add `Lockspire.Protocol.ClientAuth.ClientSecretJwt` with `HS256`-only signature validation, issuer-string audience, timing/lifetime checks, replay recording, telemetry/audit parity, and explicit FAPI/profile denial. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `lib/lockspire/protocol/security_profile.ex`]
3. **Representative proof:** extend `test/lockspire/protocol/client_auth_test.exs`, add `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`, and touch audit proof only if needed to demonstrate valid and invalid behavior across the shipped direct-client surfaces. [VERIFIED: `test/lockspire/protocol/client_auth_test.exs`] [VERIFIED: `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`] [VERIFIED: `test/lockspire/audit/event_test.exs`]

## Key Files For Planning

- `.planning/phases/88-shared-client-secret-jwt-runtime/88-CONTEXT.md` - locked scope, endpoint boundary, and non-goals.
- `.planning/phases/88-shared-client-secret-jwt-runtime/88-PATTERNS.md` - repo-local analogs for routing, verifier sequencing, and proof layout.
- `lib/lockspire/protocol/client_auth.ex` - shared runtime entry point and current implicit JWT routing bug.
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex` - verifier sequencing, replay timing, telemetry, and audit analog.
- `lib/lockspire/protocol/security_profile.ex` - effective-profile resolution and posture seam.
- `lib/lockspire/security/policy.ex` - hashed-secret verification boundary that Phase 88 must preserve.
- `test/lockspire/protocol/client_auth_test.exs` - unit-level verifier and failure-contract proof.
- `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` - representative cross-endpoint runtime proof.
- `test/lockspire/audit/event_test.exs` - redaction/audit normalization proof.

## Sources

### Primary

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/phases/88-shared-client-secret-jwt-runtime/88-CONTEXT.md`
- `.planning/phases/88-shared-client-secret-jwt-runtime/88-PATTERNS.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
- `lib/lockspire/protocol/client_auth.ex`
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex`
- `lib/lockspire/protocol/introspection.ex`
- `lib/lockspire/protocol/revocation.ex`
- `lib/lockspire/protocol/device_authorization.ex`
- `lib/lockspire/protocol/backchannel_authentication.ex`
- `lib/lockspire/protocol/token_exchange.ex`
- `lib/lockspire/protocol/security_profile.ex`
- `lib/lockspire/security/policy.ex`
- `lib/lockspire/redaction.ex`
- `test/lockspire/protocol/client_auth_test.exs`
- `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`
- `test/lockspire/audit/event_test.exs`

## Metadata

**Confidence breakdown:**
- Routing design: HIGH - the shared auth seam and fail-closed error shaping already exist and need a narrow dispatch correction. [VERIFIED: `lib/lockspire/protocol/client_auth.ex`]
- Verifier shape: HIGH - `PrivateKeyJwt` gives a direct sequencing analog for claims, replay, and telemetry/audit behavior. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`]
- Proof strategy: HIGH - representative positive/negative proof patterns already exist for both unit-level and cross-endpoint runtime coverage. [VERIFIED: `test/lockspire/protocol/client_auth_test.exs`] [VERIFIED: `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`]

## RESEARCH COMPLETE
