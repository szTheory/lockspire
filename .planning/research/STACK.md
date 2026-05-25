# v1.24 Research: Stack

## Scope

Add a narrow `client_secret_jwt` slice for confidential clients on Lockspire-owned direct-client endpoints:

- `POST /token`
- `POST /revoke`
- `POST /introspect`
- `POST /device/code`
- `POST /bc-authorize`

## Existing Stack Reuse

- `lib/lockspire/protocol/client_auth.ex` already centralizes direct-client authentication across the shipped shared surfaces.
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex` and its tests provide the closest runtime pattern for strict JWT assertion verification and replay recording.
- `lib/lockspire/protocol/discovery.ex` already publishes per-endpoint auth-method and signing-alg metadata for JWT-based client auth.
- `lib/lockspire/protocol/registration.ex`, `lib/lockspire/clients.ex`, and admin LiveView client forms already own the registration and operator truth for `token_endpoint_auth_method`.
- `Lockspire.Security.Policy.hash_client_secret/1` and `verify_client_secret/2` already give Lockspire a durable hashed-at-rest secret source that can be reused as the HMAC verification key.

## Standards Inputs

- RFC 7523 defines the JWT client assertion envelope: `iss`, `sub`, `aud`, `exp`, and optional replay-resistant `jti`.
- OpenID Connect Core Section 9 defines `client_secret_jwt` as a token-endpoint client-auth method alongside `private_key_jwt`.
- OpenID Connect Discovery and Dynamic Client Registration define `token_endpoint_auth_methods_supported`, `token_endpoint_auth_signing_alg_values_supported`, and per-client `token_endpoint_auth_signing_alg`.

## Recommended Stack Changes

- No new dependency is needed.
- Extend the shared direct-client auth runtime with a symmetric JWT verifier instead of creating endpoint-specific code paths.
- Reuse the existing used-`jti` recording path so successful assertions become single-use across the shipped direct-client surfaces.
- Reuse current secret-at-rest storage; do not introduce plaintext secret recovery or a second symmetric credential store.
- Keep the default symmetric signing set narrow and explicit, then bind it to the effective security posture instead of advertising every JOSE HMAC algorithm by default.

## What Not To Add

- No generic JWT client-auth framework beyond Lockspire-owned direct-client surfaces.
- No broader secret escrow, key-management UI, or external HSM integration.
- No new hosted-auth, federation, or third-party gateway surface.
- No support claim that `client_secret_jwt` is equivalent to `private_key_jwt` or mTLS in higher-trust deployments.
