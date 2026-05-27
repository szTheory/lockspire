# Phoenix Resource Server Token Acceptance

**Date:** 2026-05-27  
**Status:** Earmarked next feature-sized milestone  
**Purpose:** Preserve the next-milestone target so future sessions start from the adoption-demo finding instead of re-deriving it.

## Trigger

The adoption demo smoke proved Lockspire can boot inside a representative Phoenix host and drive browser/device/userinfo flows over HTTP. It also clarified the next adopter-facing ambiguity: a Phoenix SaaS developer will ask which Lockspire-issued token shape their own API should accept.

## Problem

Lockspire currently has two adjacent but easy-to-confuse stories:

- Lockspire's `/token` endpoint issues stored access tokens that work with Lockspire-owned resource endpoints such as `/userinfo`.
- `Lockspire.Plug.VerifyToken` verifies JWT bearer tokens for Phoenix API route protection.

That split may be correct, but the adopter story needs to be explicit and repo-proven. We should not imply that opaque/stored access tokens and JWT bearer route-protection fixtures are interchangeable.

## Earmarked Milestone Shape

Working title: **Phoenix Resource Server Token Acceptance**

Done enough means:

- The docs state the blessed Phoenix API protection path for a host app using Lockspire.
- The adoption demo and generated-host guidance agree with the docs.
- CI proves the representative path from an issued/accepted token to a protected Phoenix API response, or explicitly proves the chosen boundary if the accepted token is intentionally not the `/token` opaque format.
- `Lockspire.Plug.VerifyToken` naming, docs, and examples are clear enough that adopters do not mistake JWT bearer verification for generic opaque-token introspection.

## Non-Goals

- Do not turn Lockspire into a service mesh, API gateway, hosted auth service, or generic resource-server platform.
- Do not chase broad token-format parity unless the narrow Phoenix SaaS adoption story requires it.
- Do not reopen SAML/LDAP, certification breadth, or CIAM scope.

## First Investigation

Before building, inspect:

- `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.RequireToken`, and `Lockspire.Plug.EnforceSenderConstraints`
- `Lockspire.Protocol.TokenExchange`, `Lockspire.Protocol.Userinfo`, and `Lockspire.Protocol.Introspection`
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs`
- `examples/adoption_demo`
- `docs/protect-phoenix-api-routes.md`, `docs/install-and-onboard.md`, and `docs/supported-surface.md`

The first design question is whether the narrow answer should be:

1. document and prove JWT access-token issuance for host APIs,
2. add an introspection-backed Plug for opaque/stored access tokens, or
3. keep both but name and route them so the distinction is obvious.
