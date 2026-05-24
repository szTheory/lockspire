# Phase 43 Research: End-to-End FAPI 2.0 Validation

## FAPI-05: Strict Redirect URI Matching

### Context
FAPI 2.0 and OAuth 2.1 mandate exact string matching for redirect URIs, strictly forbidding any tolerance for trailing slashes, port normalization, or query parameter re-ordering. 

### Findings
Lockspire's current implementation (`validate_redirect_uri/2` in `AuthorizationRequest` and `validate_redirect_uri_binding/2` in `TokenExchange`) uses Elixir's `in` operator (`redirect_uri in client.redirect_uris`) and exact equality (`==`). 
*   **Pros:** This is already an O(1), structurally exact string match. It is the most secure, fastest, and idiomatic approach in Elixir.
*   **Cons:** It can occasionally frustrate developers who configure `http://localhost:8080/` in their client but send `http://localhost:8080`.
*   **Recommendation:** Do not alter the matching logic. Introducing a URI parser introduces attack vectors (e.g., scheme confusion or path traversal bugs). Keep the exact string match. The action for Phase 43 is simply to add explicit E2E tests validating the rejection of trailing-slash and query parameter drift to prove the zero-tolerance policy. 

## FAPI-06: Discovery Metadata & Mix-Up Attack Mitigation

### Context
FAPI 2.0 requires Authorization Servers to explicitly declare compliance features in their `.well-known/openid-configuration` discovery document. A key requirement is mitigating Mix-Up Attacks (RFC 9207) by including the `iss` parameter in authorization responses.

### Findings
Currently, Lockspire's `AuthorizationFlow.build_redirect/2` appends `code`, `state`, or `error` to the redirect URI, but it does **not** append the `iss` parameter. Furthermore, the discovery document does not publish `authorization_response_iss_parameter_supported` or `require_pushed_authorization_requests`.

### Recommendation
To satisfy FAPI-06 and achieve a durable FAPI 2.0 posture, Phase 43 must implement the following:
1.  **RFC 9207 Enforcement:** Unconditionally append `iss: Config.issuer!()` to all authorization redirects (both success and error) in `AuthorizationFlow`. This protects all clients (not just FAPI clients) from Mix-Up attacks.
2.  **Discovery Truth:** Unconditionally add `"authorization_response_iss_parameter_supported" => true` to the `openid-configuration` in `Protocol.Discovery`. 
3.  **Profile-Aware Discovery:** When the server's global security profile is set to `:fapi_2_0_security`, dynamically add `"require_pushed_authorization_requests" => true` to the discovery metadata, as PAR enforcement is mandatory under this profile.

## Conclusion
This provides a complete, one-shot architectural recommendation for Phase 43. It resolves the gray areas by deferring to strict protocol standards (RFC 9207) and idiomatic Elixir exact-match boundaries, eliminating the need for further structural debate.