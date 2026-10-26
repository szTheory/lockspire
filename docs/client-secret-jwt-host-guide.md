# `client_secret_jwt` Host Guide

For the dedicated verifier key settings and reader-first rollout limits, see
the [client secret verifier configuration guide](client-secret-verifier-configuration.md).

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

## Shared-secret lifetime

The DCR shared-secret lifetime applies to newly issued or operator-replaced
secrets for eligible self-registered apps. A blank or zero setting means no
automatic expiry. A positive setting records an expiry from the time the secret
is issued or replaced. Changing policy does not rewrite an existing secret's
stored expiry; legacy secret dates remain advisory until an operator replaces
the secret. Authentication fails at the exact stored expiry time.

This deadline applies to the shared secret used to sign assertions. It does not
replace assertion `exp`, `iat`, audience, algorithm, or replay checks. Expiring
the secret does not revoke tokens issued earlier, which retain their own
validity periods. Public-key and mTLS authentication are not subject to the
shared-secret deadline.

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
- partner coordination around credential rollout

Lockspire owns the protocol verification and operator secret-rotation path
described here. The host app still owns the human-facing application behavior
and partner coordination around credential rollout.


## Verifier-key changes and client recovery

The dedicated verifier key protects Lockspire's stored copy of the shared
secret so it can verify `client_secret_jwt` assertions. Changing that key does
not change the partner's secret. Follow the
[verifier configuration and recovery guide](client-secret-verifier-configuration.md)
for reader-first distribution, preview, apply, a separate fresh check, and
host-owned fleet and rollback checks before retiring a live read key.

If a verifier key is temporarily unavailable, the affected JWT client
authentication fails closed as `invalid_client`; Lockspire does not fall back
to Basic or post authentication. Restoring the original key preserves the
existing partner secret. If it cannot be restored, an authorized client-secret
rotation or re-provisioning replaces that secret, so coordinate the new
one-time handoff with the partner. A stored secret hash cannot be reversed.
The secret's configured expiry and the JWT assertion's own lifetime remain in
force during either recovery path.
