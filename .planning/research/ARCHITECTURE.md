# Architecture Patterns

**Domain:** Token Exchange (RFC 8693) for Lockspire
**Researched:** 2026-05-XX

## Recommended Architecture

Token exchange fundamentally bridges the gap between **Cryptographic Protocol Validation** and **Domain Business Logic**.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Lockspire.Web.TokenEndpoint` | Parses the `grant_type=...token-exchange` payload. Validates token type URIs. | `Lockspire.Protocol.TokenExchange` |
| `Lockspire.Protocol.TokenExchange` | Orchestrates the exchange. Cryptographically verifies the `subject_token` and `actor_token`. Constructs the context. | `HostApp.TokenExchangeValidator` (via Behaviour) |
| `Lockspire.TokenExchangeValidator` (Behaviour) | **Host-defined module.** Evaluates business rules: "Is Client X allowed to impersonate User Y for Service Z?" | Host App Database / Domain Context |
| `Lockspire.TokenMinter` | Generates the final JWT, embedding new scopes, audiences, and `act` (actor) claims based on host approval. | `Lockspire.Protocol.TokenExchange` |

### Data Flow

1. **Request:** Client calls `/oauth/token` with `grant_type=...token-exchange`, `subject_token=abc`, and `requested_token_type=...jwt`.
2. **Verification:** Lockspire decrypts/verifies `subject_token` to ensure it is valid, unexpired, and issued by this server.
3. **Delegation to Host:** Lockspire builds a struct (e.g., `Lockspire.TokenExchange.Context`) containing the validated original token claims, the requesting client ID, requested scopes, and requested audience.
4. **Host Policy Execution:** Lockspire calls `HostApp.Validator.validate_exchange(context)`.
5. **Host Decision:** The host app returns `{:ok, %{scopes: [...], aud: [...], act: %{...}}}` or `{:error, :unauthorized}`.
6. **Token Issuance:** If `:ok`, Lockspire mints the new token with the approved constraints and returns it in the RFC 8693 response format.

## Patterns to Follow

### Pattern 1: Explicit Host-Driven Policy (The Elixir Behaviour Pattern)
**What:** Define a clear Elixir Behaviour that host applications must implement to govern token exchanges.
**When:** Always for token exchange.
**Example:**
\`\`\`elixir
defmodule Lockspire.TokenExchangeValidator do
  @callback validate_exchange(context :: Lockspire.TokenExchange.Context.t()) :: 
    {:ok, modifications :: map()} | {:error, reason :: atom()}
end
\`\`\`

### Pattern 2: Delegation over Impersonation
**What:** When a service needs to call another service on behalf of a user, use the `act` claim to preserve the identity of the calling service.
**When:** Whenever the architecture resembles a service mesh or API gateway.
**Example:**
\`\`\`json
{
  "sub": "user_123",
  "aud": "backend_billing_service",
  "act": {
    "sub": "api_gateway_client"
  }
}
\`\`\`

## Anti-Patterns to Avoid

### Anti-Pattern 1: Implicit Upscoping
**What:** Automatically granting scopes or audiences requested by the client that were not present in the original `subject_token` without host approval.
**Why bad:** Leads directly to privilege escalation where a compromised low-tier service can request an admin-level token.
**Instead:** Default strictly to **downscoping** (intersection of original scopes and requested scopes). Require the `TokenExchangeValidator` to explicitly return `{:ok, %{expanded_scopes: [...]}}` if upscoping is truly intended.

## Scalability Considerations

| Concern | Approach |
|---------|----------|
| Token Introspection Load | Because exchanged tokens are typically short-lived and used rapidly by microservices, rely on stateless JWT validation rather than hitting the database for every hop, unless strictly revoked. |
| Exchange Latency | Ensure the `validate_exchange/1` callback is highly optimized by the host app (e.g., using ETS for policy caching if necessary). |

## Sources
- [RFC 8693 Section 2 & 4](https://datatracker.ietf.org/doc/html/rfc8693) (HIGH confidence)