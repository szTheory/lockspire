# Phase 73: JWT Introspection Responses - Research

**Researched:** 2026-05-07
**Status:** Ready for planning

## Objective

Validate the narrow implementation shape for RFC 9701 JWT token introspection responses on Lockspire's existing `/introspect` endpoint without widening the embedded-library seam or inventing a second crypto-policy plane.

## Primary Standards Findings

### RFC 9701 contract

- A resource server requests the JWT representation by sending `Accept: application/token-introspection+jwt`.
- The successful JWT response must use `Content-Type: application/token-introspection+jwt`.
- The JWT protected header must set `typ` to `token-introspection+jwt`.
- The top-level JWT claims must include:
  - `iss`
  - `aud`
  - `iat`
  - `token_introspection`
- `token_introspection` contains the RFC 7662 introspection response members.
- If the token is invalid, expired, revoked, or not intended for the caller, `token_introspection.active` must be `false` and no other `token_introspection` members should be present.
- RFC 9701 says the JWT may include additional claims, but it specifically says the JWT should not include top-level `sub` and `exp` because the response JWT is not an access token.

### RFC 7662 compatibility baseline

- Introspection remains a resource-server-authenticated endpoint.
- The authorization server may respond differently to different protected resources for the same token, including narrowing scopes.
- Existing Lockspire semantics already align with the narrow inactive contract: unauthorized caller, expired token, revoked token, or client mismatch collapse to `active: false`.

### RFC 9110 negotiation implications

- `Accept` negotiation should honor explicit media ranges and quality weights.
- `q=0` means not acceptable.
- More specific media ranges take precedence over broader ranges.
- If the response representation varies by `Accept`, adding `Vary: Accept` is appropriate even when `Cache-Control: no-store` is also present.

## Local Codebase Findings

### Existing boundaries already match the desired architecture

- `Lockspire.Protocol.Introspection` is already the truth source for token classification and payload shape.
- `Lockspire.Web.IntrospectionController` is already a thin delivery adapter and is the right place to decide JSON vs JWT representation.
- `Lockspire.Protocol.IdToken` and `Lockspire.Protocol.LogoutToken` are the best local precedents for a purpose-built JWT signer module with explicit claim shaping.
- `Lockspire.Protocol.Jarm` is the best local precedent for:
  - signing-key lookup through `fetch_active_signing_key/1`
  - JOSE compact serialization
  - private JWK decode fallback logic
- `Repository.fetch_active_signing_key/1` already applies effective security-profile filtering, so Phase 73 should reuse that seam rather than introduce introspection-specific algorithm policy.

### Missing pieces Phase 73 must add

- No current helper parses `Accept` for JWT introspection negotiation.
- No current dedicated signer exists for the RFC 9701 envelope.
- Current controller tests only cover the JSON path.

## Recommended Implementation Shape

### 1. Keep negotiation in the controller

Recommendation:
- Keep `Lockspire.Protocol.Introspection` as the producer of the introspection payload truth, but widen the success return into a protocol-owned success context that carries the payload plus the authenticated caller/signing inputs the controller needs.
- Add a small Lockspire-owned negotiation helper in the web/controller layer that:
  - reads the `Accept` header
  - returns `:jwt` only when `application/token-introspection+jwt` is explicitly acceptable with non-zero weight
  - otherwise returns `:json`

Behavior rules:
- Missing `Accept` header -> JSON
- `Accept: */*` only -> JSON
- `Accept: application/json` -> JSON
- `Accept: application/token-introspection+jwt` -> JWT
- Mixed values -> choose the RFC 9110 winner
- Malformed or ambiguous values should fail safe to JSON, not silently opt callers into JWT

### 2. Add a dedicated signer module

Recommendation:
- Create `lib/lockspire/protocol/introspection_jwt.ex`.

Responsibilities:
- Accept the authenticated caller identity, issuer, introspection payload, issue time, and signing-key context.
- Fetch the active signing key using the effective security profile and explicit signing algorithm.
- Build only the narrow RFC 9701 envelope:
  - `iss`
  - `aud`
  - `iat`
  - `token_introspection`
- Set protected header fields:
  - `alg`
  - `kid`
  - `typ: token-introspection+jwt`
- Return a compact JWS.

Non-goals for Phase 73:
- no encryption
- no metadata publication
- no separate resource-server identity model
- no extra default top-level `sub`, `exp`, `nbf`, or `jti`

### 3. Preserve existing auth and inactive semantics

Recommendation:
- Continue authenticating callers exactly as the existing introspection path does.
- Bind JWT `aud` to the authenticated introspection caller identity already proven by the direct-client auth surface.
- Preserve the current inactive collapse semantics by nesting `%{active: false}` as the entire `token_introspection` object.
- Return the authenticated caller and any signer-relevant context from the protocol layer in a dedicated success shape so the controller can choose JWT vs JSON without re-running auth or reconstructing `aud`.

### 4. Keep error responses JSON

Recommendation:
- Even when JWT is requested, protocol or caller-auth errors should stay on the current JSON error path.
- Preserve `WWW-Authenticate` behavior for `invalid_client`.

Rationale:
- This keeps the endpoint compatible with existing OAuth error handling and matches the narrow v1 milestone boundary.

### 5. Update headers narrowly

Successful JWT responses should include:
- `Content-Type: application/token-introspection+jwt`
- `Cache-Control: no-store`
- `Pragma: no-cache`
- `Vary: Accept`

Successful JSON responses can keep the current headers. Adding `Vary: Accept` to both success paths is also acceptable if implemented consistently.

## Likely File Touch Points

- `lib/lockspire/protocol/introspection_jwt.ex` - new signer for RFC 9701 envelope
- `lib/lockspire/web/controllers/introspection_controller.ex` - negotiation and response selection
- `test/lockspire/protocol/introspection_jwt_test.exs` - focused signer tests
- `test/lockspire/web/introspection_controller_test.exs` - negotiation, headers, inactive JWT, and JSON-error coverage
- Possibly `lib/lockspire/web/controllers/introspection_controller.ex` private helpers or a tiny adjacent utility for `Accept` parsing
- Docs/support truth files only if the plan chooses to include repo-truth updates in this phase

## Recommended Test Matrix

### Protocol signer tests

- Signs a valid RFC 9701 envelope with `typ=token-introspection+jwt`
- Preserves nested introspection payload with string keys
- Produces inactive envelope with only `token_introspection.active == false`
- Rejects missing signing key
- Rejects disallowed signing algorithm under the effective security profile

### Controller tests

- JWT response when `Accept: application/token-introspection+jwt`
- JSON response when `Accept` is missing
- JSON response when only wildcard/general JSON is acceptable
- Correct winner when both JSON and JWT appear with weights
- JWT path preserves cache headers and adds `Vary: Accept`
- Error responses remain JSON even when JWT is requested
- Inactive JWT response contains only nested `active: false`
- Negotiated JWT signing failure returns a JSON `server_error` response rather than a malformed or partial JWT response

## Risks and Planning Notes

- The only genuinely new behavior area is RFC 9110-style `Accept` parsing. Keep it small and test-heavy.
- Avoid leaking current atom-key payloads directly into the signer. Normalize nested claims to string keys explicitly.
- Avoid copying JARM's outer claim shape. RFC 9701 requires a different envelope.
- Avoid claiming encryption or metadata support in docs or discovery during Phase 73 unless those capabilities are actually implemented.

## Concrete Planning Recommendation

Split Phase 73 into three plans:

1. Introduce the dedicated JWT signer and focused signer tests.
2. Wire controller-side `Accept` negotiation and JWT delivery while preserving JSON errors and inactive semantics, using a protocol-owned success context for the signer handoff.
3. Update docs or executable examples only if needed to keep repo-truth accurate for the shipped Phase 73 surface.

## Sources

- RFC 9701: https://www.rfc-editor.org/rfc/rfc9701.html
- RFC 7662: https://www.rfc-editor.org/rfc/rfc7662.html
- RFC 9110: https://www.rfc-editor.org/rfc/rfc9110.html

## RESEARCH COMPLETE
