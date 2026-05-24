# Phase 71: JARM Core Assumptions & Research

## Assumptions

### Authorization Request Validation
- **Assumption:** `response_mode` parameter validation needs to be introduced, enabling `jwt` and composite modes.
- **Why this way:** `lib/lockspire/protocol/authorization_request.ex` completely blocks this parameter via `@unsupported_params ~w(response_mode)`. This must be removed, and a new validation step must verify the requested mode against the client's registered configuration.
- **If wrong:** The Authorization Server will incorrectly reject legitimate JARM requests with an `unsupported_response_mode` error.

### Client Metadata & Storage
- **Assumption:** `authorization_signed_response_alg` must be added to the client domain and persistence layer.
- **Why this way:** `lib/lockspire/domain/client.ex` and `lib/lockspire/storage/ecto/client_record.ex` already model similar fields like `id_token_signed_response_alg`, but currently lack `authorization_signed_response_alg`. 
- **If wrong:** The system cannot persistently record or enforce a client's specific requested signing algorithm for JARM responses.

### Discovery Metadata Advertisement
- **Assumption:** Discovery must dynamically advertise JARM support based on the active security profile and server capabilities.
- **Why this way:** `lib/lockspire/protocol/discovery.ex` currently hardcodes `@response_modes_supported ["query"]`. This needs to expand to include `jwt`, `query.jwt`, `fragment.jwt`, and `form_post.jwt`. Additionally, `authorization_signing_alg_values_supported` must be derived similarly to `id_token_signing_alg_values_supported()`.
- **If wrong:** OIDC Discovery (`/.well-known/openid-configuration`) will not advertise the AS's capabilities correctly.

### Authorization Response Rendering & JWT Signing
- **Assumption:** `AuthorizationFlow` must incorporate a dedicated JWS generation step using active keys from the KeyStore.
- **Why this way:** `lib/lockspire/protocol/authorization_flow.ex` currently encodes `code`, `state`, and `iss` as raw query parameters. To support JARM, these must instead be wrapped in a JWS payload, signed using active keys retrieved from the `KeyStore`.
- **If wrong:** The authorization response will leak sensitive parameters directly in the URL query/fragment.

### Form Post Rendering
- **Assumption:** A new HTML template/view must be created to support the `form_post.jwt` response mode.
- **Why this way:** A codebase search for `form_post` yields no results. `form_post` dictates that the AS must render an auto-submitting HTML form containing the `response` parameter.
- **If wrong:** Clients requesting `response_mode=form_post.jwt` will be met with an unsupported error or an incorrect HTTP redirect instead of the mandated HTML page.

## Research Findings

### FAPI 2.0 Cryptography Restrictions on JARM
- **Finding:** FAPI 2.0 Section 5.4.1 explicitly mandates the use of PS256, ES256, or EdDSA for all JWTs, which directly governs the `authorization_signed_response_alg` parameter used in JARM. RS256 is strictly prohibited due to vulnerabilities associated with PKCS#1 v1.5 padding.
- **Action:** Given Lockspire is entering FAPI 2.0 Advanced Cryptography, the server must be capable of rejecting RS256 and `none` for JARM responses. This will be enforced using a policy-driven toggle (e.g., a FAPI strict mode), similar to how `id_token_signed_response_alg` restrictions are currently handled.