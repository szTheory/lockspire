# Resource Indicators (RFC 8707) Implementation Research

**Project:** Lockspire
**Researched:** 2024-05-30
**Domain:** OAuth 2.0 / OIDC Authorization Server

## Executive Summary
RFC 8707 (Resource Indicators for OAuth 2.0) introduces the `resource` parameter, allowing clients to explicitly state the target Resource Server (API) when requesting an access token. This solves the "Audience Ambiguity" problem by replacing "fat" tokens (which are valid for many APIs and vulnerable to token replay) with "targeted" downscoped tokens.

## Pros, Cons, and Tradeoffs

### Pros
*   **Security (Zero Trust):** Enforces the Principle of Least Privilege. If a downstream API is compromised, a targeted access token cannot be replayed against another API because the `aud` (audience) claim restricts it.
*   **Token Size:** Access tokens are smaller because they only contain the `aud` and `scopes` relevant to the specific resource.
*   **Declarative Policy:** Separates "where" the client is acting (resource) from "what" the client is doing (scope). 

### Cons & Tradeoffs
*   **Client Complexity:** Clients can no longer rely on a single global access token. They must maintain a token cache mapped by resource URI and dynamically negotiate tokens.
*   **Performance / AS Load:** Increased traffic to the Authorization Server's `/token` endpoint as clients exchange their refresh tokens for resource-specific access tokens.
*   **Migration Friction:** Legacy Resource Servers that do not strictly validate the `aud` claim will negate the security benefits.

## Idiomatic Elixir / Plug / Ecto Patterns

For Lockspire (an embedded Elixir/Phoenix OIDC provider), implementing RFC 8707 should follow idiomatic patterns:

1.  **Ecto Data Model (Contexts):**
    *   Shift from flat `Scope` records to an `ApiResource` model (`has_many :scopes`).
    *   Add a `require_resource_indicator` boolean field to allow gradual migration for developers.
2.  **Plug Validation:**
    *   Create a custom Plug in the authorization pipeline to validate the `resource` parameter as absolute URIs (as mandated by the spec).
3.  **Dynamic Downscoping (Token Minting):**
    *   When the `/token` endpoint processes a `grant_type=refresh_token` request with a `resource` parameter, dynamically filter the granted scopes so the minted JWT only includes the intersection of the requested resource's scopes and the originally granted scopes.
    *   Set the `aud` claim to the requested resource URI (preferably a single string rather than an array).

## Lessons Learned from Ecosystems (Duende, Keycloak, Node-OIDC-Provider)

*   **Duende IdentityServer:** Introduced `RequireResourceIndicator` to enforce this cleanly. They recommend grouping logically related microservices into a single `ApiResource` if they share the same trust boundary to avoid "token bloat" and excessive round-trips.
*   **Scope vs. Resource:** A massive anti-pattern is overloading scopes to handle resources (e.g., `scope=billing:read`). Using RFC 8707 keeps the model clean (`resource=https://api/billing`, `scope=read`).
*   **The "One Resource, One Token" Rule:** While the RFC allows multiple `resource` parameters, best practice is to issue tokens for exactly *one* resource. This ensures the `aud` claim is a single string, the gold standard for preventing redirection attacks.

## Ergonomics, DX, and Principle of Least Surprise

*   **URI Formatting:** Enforce URIs for the `resource` identifier. This makes them self-documenting for developers and prevents namespace collisions.
*   **Gradual Migration:** Since Lockspire is an embedded provider, developers will have existing clients. Provide a `strict_resource_indicators` configuration at the client or resource level so developers can opt-in without breaking existing integrations.
*   **Clear Error Messages:** If a client requests a scope that doesn't belong to the requested resource, return an RFC-compliant `invalid_scope` error with a helpful description, reducing debugging time.

## Potential Footguns

*   **The Lazy API Footgun:** If Resource Servers do not strictly validate the `aud` claim, RFC 8707 provides zero security value. Lockspire should heavily document this requirement for API developers.
*   **Refresh Token Overscoping:** Ensure that while Access Tokens are strictly downscoped via the `resource` parameter, the underlying Refresh Token retains the full set of authorized scopes so the client doesn't lose access on subsequent requests.