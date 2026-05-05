# Phase 50 Research: Delegation & Act Claims in Token Exchange (RFC 8693)

This document analyzes two critical architectural decisions for implementing RFC 8693 Token Exchange delegation in Lockspire: how to populate the `act` (actor) claim and where to enforce maximum delegation depth.

---

## Decision 1: Act Claim Extractor

**Context:** When a Token Exchange request includes an `actor_token`, the resulting access token should represent delegation via the `act` claim. Should Lockspire automatically map the actor's identity into the `act` claim, or should it delegate this construction to the host application via the existing `Lockspire.Host.TokenExchangeValidator` behaviour?

### Approach A: Automatic Extraction
Lockspire automatically parses the validated `actor_token`, extracts standard claims (e.g., `sub`, `client_id`), and nests them into the `act` claim of the new token.

*   **Pros:** Immediate RFC compliance out-of-the-box. Low friction for standard service-to-service delegation workflows. Prevents host apps from accidentally malforming the `act` JSON object.
*   **Cons:** Highly inflexible. Host apps may need to inject custom claims into the `act` object (e.g., organizational units, specific roles the actor assumes) which an automatic extractor cannot anticipate.
*   **Example:** A token with `{ "sub": "user_1", "act": { "sub": "service_a" } }` is generated implicitly.

### Approach B: Explicit Seam (Host Behaviour)
Lockspire validates the `actor_token` structurally and cryptographically, then passes the decoded claims to `Lockspire.Host.TokenExchangeValidator.validate/1` (or a similar callback). The host application is responsible for returning the explicit map to be injected as the `act` claim.

*   **Pros:** Maximum flexibility. The host app maintains total control over what represents an "actor" in their domain context. Adheres to Lockspire's philosophy of explicit domain boundaries.
*   **Cons:** Higher burden on the developer. If they simply want standard RFC 8693 behavior, they have to write boilerplate code.
*   **Example:** The host implements `c:validate/1` to return `{:ok, %{act: %{sub: actor_claims["sub"], custom_role: "auditor"}}}`.

### Ecosystem Idioms (Elixir/Plug/Ecto)
In the Elixir ecosystem, libraries like `Pow` or `Ueberauth` heavily favor **explicit behaviours and callbacks**. "Magic" automatic mappings are generally discouraged because they hide domain logic. Exposing a struct (e.g., `%Lockspire.TokenExchangeContext{}`) that flows through a configurable behaviour module is the gold standard.

### Lessons from Popular OIDC Providers
*   **Keycloak:** Takes the "Automatic Extraction" approach. It handles standard cases seamlessly but can be notoriously difficult to customize if your actor metadata doesn't perfectly align with Keycloak's internal user/client models.
*   **IdentityServer / Duende (.NET):** Takes the "Explicit Seam" approach via `IProfileService` and custom grant validators. Developers must explicitly wire up the `act` claim. While initial setup is higher, large enterprises strongly prefer this as it allows them to map complex domain relationships into the token.
*   **Auth0:** Currently requires manual assembly via "Actions" (scripting) to support RFC 8693 delegation, highlighting that rigid automatic pipelines eventually require escape hatches.

### Developer Ergonomics & DX
The Principle of Least Surprise dictates that a security library should not make implicit assumptions about business logic. However, DX suffers if every user must rewrite the exact same standard `act` mapping. 

---

## Decision 2: Max Delegation Depth

**Context:** RFC 8693 allows the `act` claim to be recursively nested (e.g., User -> A -> B -> C). Deep nesting causes "JWT bloat," leading to HTTP 431 Header Too Large errors, increased CPU overhead, and massive audit complexity. We must limit the `max_delegation_depth`.

### Approach A: Global `ServerPolicy`
A single integer configured at the Lockspire server level (e.g., `config :lockspire, max_delegation_depth: 3`).

*   **Pros:** Extremely simple to implement and reason about. Protects the entire IdP from systemic JWT bloat DOS attacks in one stroke.
*   **Cons:** A blunt instrument. If 99% of the system needs a depth of 1, but a single legacy pipeline needs a depth of 4, the global limit must be set to 4, lowering the security posture for everyone.

### Approach B: Per-Client Config
A field on the `Client` Ecto schema (e.g., `client.max_delegation_depth`).

*   **Pros:** Principle of Least Privilege. Only specific high-trust downstream services are allowed to accept deeply nested delegations.
*   **Cons:** Higher administrative overhead. If an organization decides to cap all delegation at 2 hops, they must migrate the database to update all clients.

### Approach C: Both (Global Default + Per-Client Override)
A global fallback via `ServerPolicy` that can be overridden by a specific `Client` config.

*   **Pros:** Best of both worlds. Sane defaults with surgical overrides.
*   **Cons:** Slightly more complex resolution logic during token minting.

### Ecosystem Idioms (Elixir/Plug/Ecto)
Elixir configuration often relies on Application environment variables for global defaults (`config/config.exs`) and Ecto structs for dynamic, per-tenant or per-client overrides. Resolving config via `Map.get(client, :max_delegation_depth) || Application.get_env(:lockspire, :max_delegation_depth, 3)` is an extremely common pattern.

### Lessons from Popular OIDC Providers
*   The industry consensus (including emerging IETF drafts and gateways like Gravitee) is converging on a **sensible default of 3 hops**. 
*   Providers that failed to implement limits early on suffered from cascading infrastructure failures when nested JWTs exceeded Nginx's default 8KB/16KB header limits.
*   Treating nested `act` claims as informational for audit, but strictly limiting their depth to prevent DOS, is the established best practice.

### Developer Ergonomics & DX
Failing silently is the worst DX. If a token exchange exceeds the depth limit, the IdP *must* return a clear RFC-compliant error (e.g., `invalid_request` with an `error_description` explicitly mentioning delegation depth). 

---

## Deep, Cohesive, One-Shot Recommendation

To move Phase 50 forward with an architecture that is idiomatic, secure, and developer-friendly, Lockspire should implement the following hybrid strategy:

### 1. Act Claim Extractor: Explicit Seam with a "Batteries-Included" Default
**Recommendation:** Do not use implicit magic. Extend the `Lockspire.Host.TokenExchangeValidator` behaviour to handle delegation logic. 

However, to provide great DX, Lockspire should ship a `Lockspire.Host.DefaultDelegationValidator` (which implements the behaviour) that performs the standard RFC 8693 mapping: extracting the `sub` and `client_id` from the `actor_token` and formatting them into the `act` claim. 
*   **Why:** This provides out-of-the-box compliance for 80% of users, while allowing the remaining 20% to swap in their own module via configuration. The host application explicitly "opts-in" to the mapping logic by choosing the validator, preserving Lockspire's philosophy of explicit host control.

### 2. Max Delegation Depth: Both (Global Default + Per-Client Override)
**Recommendation:** Implement `max_delegation_depth` on both the `ServerPolicy` and the `Client` schema.
*   Set a hardcoded, un-bypassable system maximum (e.g., 5) to prevent physical JWT bloat DOS attacks.
*   Expose a global `ServerPolicy` configuration default (recommended: `3`).
*   Allow the target `Client` Ecto schema to override this downward or upward (up to the system maximum).
*   **Validation Logic:** When parsing the `actor_token`, Lockspire must recursively count the existing `act` layers. If `current_depth + 1 > resolved_max_depth`, immediately reject the exchange with `{"error": "invalid_request", "error_description": "max_delegation_depth_exceeded"}`.
*   **Why:** This protects the ecosystem from Nginx/ALB header size crashes by default, enforces the principle of least privilege per client, and leverages standard Elixir config-resolution patterns. 

This combination ensures strict RFC 8693 compliance, prevents infrastructure-level DOS vectors, and provides a clear, documented path for advanced enterprise customizations.