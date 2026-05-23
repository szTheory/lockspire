# Supported Surface

Lockspire `1.0.0` is a GA release of an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It is meant for Phoenix teams that want to become an OAuth/OIDC provider inside an existing app while keeping accounts, login UX, layouts, branding, and product policy in the host application.

This page is the canonical public support contract for what Lockspire currently supports, what it does not support, and what repo-owned proof backs those claims.

README, `SECURITY.md`, and maintainer-only release guidance point back to this file. They do not broaden or replace it.

## Supported in scope

Lockspire `1.0.0` GA currently supports this repo-proven embedded Phoenix surface:

- Embedded Phoenix install flow through `mix lockspire.install`
- One canonical Phoenix onboarding path, with `--sigra-host` limited to comments and guidance for the host-owned seam rather than a second topology
- `mix lockspire.verify` as the canonical post-install diagnostics step for config, seam presence, router wiring, `/verify` routes, and migrations
- `mix lockspire.upgrade` for manifest-tracked Lockspire-managed scaffolding only
- Authorization code flow with PKCE S256
- The Phase 37 OIDC strictness slice proven in-repo: exact `redirect_uri` matching, `prompt=none` returning redirect-safe `login_required` instead of host login redirects, durable `max_age` / `auth_time` handling, and integer `auth_time` emission in ID tokens when `max_age` or explicit `auth_time` demand requires it
- Pushed authorization requests only as Lockspire-issued `request_uri` references that extend the existing authorization code + PKCE flow
- global and client-specific PAR requirement policies (can be configured as `required` or `optional`)
- OIDC discovery and JWKS
- Resource Indicators on the authorization and token surface, with truthful discovery metadata via `resource_indicators_supported` only when the mounted authorization-code surface is actually usable
- `authorization_details_types_supported` in discovery only when the mounted authorization-code surface is usable and the host has configured at least one RAR validator type
- Userinfo
- Dynamic client registration and registration management for self-service clients within the repo-proven RFC 7591/RFC 7592 slice
- Confidential-client `private_key_jwt` authentication on Lockspire-owned direct-client endpoints, with registration managed through inline `jwks` or guarded `jwks_uri`
- Revocation
- Introspection
- JWT-secured authorization response mode (JARM) as an optional authorization-response representation when clients explicitly choose `jwt`, `query.jwt`, `fragment.jwt`, or `form_post.jwt`
- RFC 9701 JWT introspection responses on the existing `POST /introspect` endpoint when the caller explicitly sends `Accept: application/token-introspection+jwt`
- Refresh token rotation
- Host Phoenix API route protection with `Lockspire.Plug.VerifyToken`, optional `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`, including route-level `scopes:` and `audience:` / `audiences:` restrictions for Lockspire-issued access tokens
- DPoP on token requests, Lockspire-owned endpoints, host Phoenix API routes protected by the shipped plug pipeline, and truthful introspection visibility for active bound tokens, including automatic `DPoP-Nonce` challenge and retry support on those shipped DPoP surfaces, with bearer clients remaining unchanged by default unless they explicitly opt into DPoP mode
- Device authorization flow for embedded Phoenix hosts: `POST /device/code`, device polling through `POST /token`, single-use token redemption, and token issuance backed by the host-owned `/verify` seam
- A generated, host-owned device verification seam for `/verify`, including `LockspireVerificationController`, `lockspire_verification_html`, and the security contract in `docs/device-flow-host-guide.md`
- A generated, host-owned custom RAR consent seam through `lockspire_consent_live.ex`, with an illustrative `payment_initiation` walkthrough in `docs/rar-consent-host-guide.md`
- RP-initiated logout plus logout propagation from the protocol-owned `/end_session/complete` seam: durable back-channel enqueueing with Oban and Req, plus front-channel iframe cleanup as best effort browser choreography only
- Host-owned login redirects and consent handoff seams, including Sigra-shaped account resolution from `conn.assigns.current_scope.user`
- LiveView and admin workflows for clients, consents, tokens, keys, PAR/DPoP/DCR policies, and operator-managed logout propagation settings
- Phoenix-first onboarding docs and generated host integration files
- FAPI 2.0 Security Profile enforcement when `security_profile: :fapi_2_0_security` is set globally or per-client: PAR-required at /authorize, DPoP sender-constrained access tokens, ES256/PS256 signing only, exact-match redirect URIs with zero tolerance for trailing slashes or query drift
- FAPI 2.0 Message Signing strict enforcement when `security_profile: :fapi_2_0_message_signing` is set globally or per-client: the baseline optional JARM and RFC 9701 capabilities above become explicit requirements, `/authorize` requires JARM, `/introspect` requires `Accept: application/token-introspection+jwt`, and client `:none` overrides remain intentional mixed-mode escape hatches
- RFC 9207 `iss` parameter emitted on every authorization-response redirect (success, denial, and error) for all clients regardless of profile
- Truthful FAPI 2.0 keys in `.well-known/openid-configuration`: `authorization_response_iss_parameter_supported` always true; `require_pushed_authorization_requests` true only when the global server policy is `:fapi_2_0_security`

### JWT Introspection Representation

Lockspire supports RFC 9701 JWT introspection as a negotiated representation of the existing introspection endpoint. The direct-client authentication surface stays the same; only the success representation changes when the caller explicitly sends `Accept: application/token-introspection+jwt`.

- Successful negotiated introspection returns `Content-Type: application/token-introspection+jwt`
- Active and inactive successful introspection outcomes can both be returned as signed JWTs
- Error responses stay on the standard JSON OAuth error path
- No host MIME registration is required
- This Phase 73 slice does not claim introspection encryption, new discovery metadata, or strict mode enforcement

## FAPI 2.0 Message Signing Strict Tier

Lockspire keeps baseline JARM and RFC 9701 JWT introspection support optional for general OIDC interoperability, then offers a stricter `:fapi_2_0_message_signing` profile for deployments that want those message-signing capabilities enforced.

- The strict tier requires explicit JARM on `/authorize`
- The strict tier requires explicit `Accept: application/token-introspection+jwt` on `/introspect`
- The strict tier preserves the mixed-mode escape hatch: a client can still explicitly set `security_profile: :none` under a stricter global policy
- The strict tier does not require JARM encryption
- The strict tier does not broaden Lockspire into a larger FAPI certification or unsupported-surface claim

Active response shape example:

```json
{
  "iss": "https://issuer.example.com",
  "aud": "gateway-client",
  "iat": 1778241726,
  "token_introspection": {
    "active": true,
    "client_id": "saas-client",
    "scope": "openid profile",
    "sub": "account-123"
  }
}
```

Inactive response shape example:

```json
{
  "iss": "https://issuer.example.com",
  "aud": "gateway-client",
  "iat": 1778241726,
  "token_introspection": {
    "active": false
  }
}
```

## Explicitly out of scope

Lockspire does not currently support:

- Implicit flow
- Request-object-by-value support
- Generic external `request_uri` handling outside Lockspire's own PAR endpoint
- Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope
- broader resource-server integration beyond Lockspire-owned endpoints and the shipped Phoenix plug pipeline
- `client_secret_jwt`
- Generic JWT client-auth support outside the Lockspire-owned direct-client surfaces that reuse the shared verifier
- Lockspire-owned device verification browser UI or hosted approval pages
- Lockspire-owned semantic RAR consent rendering, renderer registries, or payment-product UI
- Dynamic Client Registration support for `backchannel_logout_uri`, `backchannel_logout_session_required`, `frontchannel_logout_uri`, or `frontchannel_logout_session_required` remains unsupported in this slice
- Hosted auth as a separate required service
- SAML
- LDAP or Active Directory federation
- Full CIAM or workforce identity platform scope
- Lockspire-owned account database, passwords, or login UX
- Broad compatibility claims beyond the Phoenix/Elixir embedded-library path documented in this repo
- External OIDF or FAPI suite certification claims — Lockspire does not treat historical or optional external-suite runs as part of the current public support contract for the embedded Phoenix library path

## Trust posture

Lockspire maintains its 1.0 GA posture because public claims are backed by what this repo can prove today. Repo-owned proof for this posture lives in:

- `docs/install-and-onboard.md` as the canonical Phoenix host onboarding path
- `docs/protect-phoenix-api-routes.md` for the shipped host Phoenix API route protection guide
- `docs/rar-consent-host-guide.md` for custom RAR consent on the generated host seam
- `docs/private-key-jwt-host-guide.md` for the shipped `jwks_uri` + `private_key_jwt` client-auth slice
- `docs/device-flow-host-guide.md` for the Phase 31 verification security contract
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` for generated-host Phoenix API route protection proof
- `test/integration/install_generator_test.exs` for generator-backed install proof
- `test/integration/phase6_onboarding_e2e_test.exs` for the canonical auth-code + PKCE onboarding flow, including unauthenticated `/authorize`, host login, interaction resume, consent, and token exchange
- `test/integration/phase37_protocol_strictness_e2e_test.exs` for the generated-host strictness proof covering `prompt=none`, `max_age`, `auth_time`, and exact redirect behavior
- `test/lockspire/release_readiness_contract_test.exs` for narrow release and docs posture checks
- `.github/workflows/ci.yml` and `.github/workflows/release.yml` for maintained contributor and protected release lanes
- `docs/maintainer-release.md` and `SECURITY.md` for versioned release and disclosure guidance

Lockspire does not use README summaries, maintainer-only workflow docs, external-suite artifact folders, workflow-run folklore, or a demo app as its primary public proof story.

Historical Phase 37 external-suite wiring and any OIDF or FAPI Docker runs remain maintainer-only corroboration. They can be useful for standards-sensitive investigation, but they are optional, secondary to the repo-native proof above, and not part of the current public support contract.

## GA bar

A 1.0 GA claim honestly says:

- there is one canonical Phoenix onboarding path
- `--sigra-host` is guidance-only; it does not create a second install topology or a compile-time Sigra dependency
- install diagnostics and managed-scaffolding upgrades are explicit (`mix lockspire.verify` and `mix lockspire.upgrade`)
- the generated host seam resolves the signed-in user through host-owned session state such as `conn.assigns.current_scope.user`
- secure OAuth/OIDC defaults are enforced inside the supported surface
- executable install and onboarding proof is checked into the repo
- the shipped device flow is an embedded-library path: device authorization endpoint, device polling, token redemption, and a narrow host-owned device verification seam, not a Lockspire-owned browser UI
- the shipped `private_key_jwt` slice is narrow: confidential clients, inline `jwks` or guarded `jwks_uri`, issuer-string `aud`, and Lockspire-owned direct-client endpoints only
- the shipped protected-resource proof surface is narrow: Lockspire-owned endpoints plus host Phoenix API routes protected by the documented plug pipeline, not generic gateway or third-party issuer middleware
- the shipped logout propagation surface is asymmetric by design: back-channel delivery is durable and front-channel logout is best effort only
- contributor and release workflows are versioned in the repo
- a private disclosure path exists for supported security issues

A 1.0 GA claim should not say:

- Lockspire is production-ready for unsupported host shapes
- Lockspire supports broader request-object modes, generic external `request_uri` handling, generic gateway protected-resource middleware, SAML, or LDAP
- Lockspire accepts DCR logout metadata or proves front-channel logout success remotely
- Lockspire is a hosted auth service or full CIAM product
- Lockspire has broad certification or conformance coverage

## GA Criteria

A 1.0 GA claim requires everything in the GA bar plus:

- repeated green release gates in the trusted publish lane
- maintainer runbooks that match real release operations
- stable support expectations for the documented embedded-library surface
- evidence that public docs, workflows, and shipped behavior still agree over time
