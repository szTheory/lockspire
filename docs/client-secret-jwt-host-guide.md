# `client_secret_jwt` Host Guide

Lockspire ships a narrow `client_secret_jwt` slice for confidential clients on the Lockspire-owned direct-client endpoints that reuse the shared verifier. This guide explains that shipped slice only. It does not broaden the public support contract beyond [`docs/supported-surface.md`](supported-surface.md).

## What this guide covers

This guide is limited to:

- confidential clients using `token_endpoint_auth_method=client_secret_jwt`
- `token_endpoint_auth_signing_alg=HS256`
- Lockspire-owned direct-client endpoints that reuse the shared verifier
- issuer-string `aud`, bounded assertion lifetimes, required `jti`, and replay prevention

It does not add support for generic JWT client authentication, `POST /par`, `HS384`, `HS512`, FAPI equivalence, or mTLS-style trust claims.

## Registration shape

Lockspire accepts `client_secret_jwt` only for confidential clients inside the shipped direct-client slice.

The registration shape is:

- `token_endpoint_auth_method=client_secret_jwt`
- `token_endpoint_auth_signing_alg=HS256`
- a managed client secret stored hashed at rest

Lockspire does not silently infer `HS256` from a broader algorithm family and does not accept `HS384` or `HS512` for this slice.

## Assertion requirements

Client assertions must be signed JWTs. Lockspire does not allow `alg=none`.

The assertion must use:

- `iss` equal to the client identifier
- `sub` equal to the client identifier
- `aud` equal to the issuer identifier string
- bounded lifetime claims with normal skew handling
- a unique `jti` so replay protection can record successful use

Lockspire intentionally binds `aud` to the issuer string rather than accepting endpoint-specific audiences. That is a deliberate compatibility and verification choice for this shipped slice.

## Direct-client endpoints that consume the shared verifier

The shipped `client_secret_jwt` verifier is shared across the Lockspire-owned direct-client surfaces that already use the common client-auth path, including:

- `POST /token`
- `POST /revoke`
- `POST /introspect`
- `POST /device/code`
- `POST /backchannel/authentication`

`POST /par` is intentionally excluded from this slice. Lockspire documentation and discovery metadata only claim support where the shared runtime actually enforces it.

## Explicit non-goals

This guide does not claim:

- support on `POST /par`
- `HS384` or `HS512`
- FAPI or mTLS equivalence
- a generic JWT client-auth umbrella beyond the Lockspire-owned direct-client surfaces

## What hosts still own

Your host app still owns:

- account records
- login UX
- branding and layouts
- consent and product policy
- rate limiting and perimeter controls around the mounted Lockspire routes
- secret issuance, rotation operations, and partner coordination around credential rollout

Lockspire owns the protocol verification path described here. The host app still owns the human-facing application behavior and operating procedures around it.
