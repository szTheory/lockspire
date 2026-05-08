# Private Key JWT Host Guide

Lockspire supports a narrow `private_key_jwt` client-authentication slice for confidential clients on Lockspire-owned direct-client endpoints. This guide explains the shipped surface for Phoenix hosts without widening Lockspire into a general remote-metadata or federation product.

For the canonical public support contract, see `docs/supported-surface.md`.

## What this guide covers

This guide is limited to:

- confidential clients using `token_endpoint_auth_method=private_key_jwt`
- client key material supplied as inline `jwks` or remote `jwks_uri`
- Lockspire-owned direct-client endpoints that reuse the shared verifier
- rotation behavior for client keys served from `jwks_uri`

It does not add support for `client_secret_jwt`, mTLS, generic external trust chains, or federation-style metadata ingestion.

## Registration shape

Lockspire accepts `private_key_jwt` only for confidential clients inside the shipped direct-client slice.

The registration shape is:

- `token_endpoint_auth_method=private_key_jwt`
- exactly one of `jwks` or `jwks_uri`
- signing keys and algorithms that match the effective issuer security posture

`jwks` and `jwks_uri` are mutually exclusive. Lockspire rejects registrations or updates that try to set both.

## Inline `jwks` versus remote `jwks_uri`

Inline `jwks` keeps the client's public verification keys inside the client record.

`jwks_uri` is supported through a guarded Lockspire fetch path:

- `https` only
- no redirects
- unsafe targets fail closed before request dispatch
- oversized bodies are rejected
- fetch failures stay generic at the wire boundary as `invalid_client`

This is a narrow key-retrieval path for client authentication only. It is not a generic outbound metadata-ingestion feature.

## Assertion requirements

Client assertions must be signed. Lockspire does not allow `alg=none`.

The assertion must use:

- `iss` equal to the client identifier
- `sub` equal to the client identifier
- `aud` equal to the issuer identifier string
- bounded lifetime claims with normal skew handling
- a unique `jti` so replay protection can record successful use

Lockspire intentionally binds `aud` to the issuer string rather than accepting endpoint-specific audiences. That is a deliberate security choice for this slice, not an accidental implementation detail.

Accepted signing algorithms follow the current issuer posture:

- default posture publishes and accepts `RS256`, `ES256`, `PS256`, and `EdDSA`
- FAPI 2.0 posture narrows the allowlist to `ES256` and `PS256`

## Key rotation behavior

For `jwks_uri` clients, Lockspire caches successful fetches with a bounded TTL.

When a client rotates keys:

1. Lockspire keeps using the cached key set until cache expiry or a verification miss requires refresh.
2. One bounded forced refresh path attempts to load the newer JWKS document.
3. If refresh succeeds, the new key material replaces the cached entry.
4. If refresh fails, Lockspire preserves the last known good cache entry and still fails the current authentication attempt closed.

This gives clients a realistic rotation path without turning the embedded library into a broad remote-key management system.

## Direct-client endpoints that consume the shared verifier

The shipped `private_key_jwt` verifier is shared across Lockspire-owned direct-client surfaces, including:

- `POST /token`
- `POST /revoke`
- `POST /introspect`
- `POST /device/code`
- `POST /backchannel/authentication`

Lockspire documentation and discovery metadata only claim support where the shared runtime actually enforces it.

## What hosts still own

Your host app still owns:

- account records
- login UX
- branding and layouts
- consent and product policy
- rate limiting and perimeter controls around the mounted Lockspire routes

Lockspire owns the protocol verification path described here. The host app owns the human-facing application behavior around it.
