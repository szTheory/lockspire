# Architecture Patterns

**Domain:** Embedded OAuth/OIDC Provider for Elixir/Phoenix
**Researched:** 2025-05-24

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| Client Authenticator Plug | Validates client credentials (Secret, JWT, mTLS) | Token Endpoint, DCR |
| Token Exchange Validator | Extensible behaviour for host apps to validate impersonation | Token Endpoint |
| CIBA Backchannel | Initiates push/polling for decoupled auth | PubSub, Background Jobs (Oban) |

## Patterns to Follow

### Pattern 1: CIBA via Phoenix PubSub
**What:** Using Elixir's native distributed PubSub to handle CIBA notification modes.
**When:** When a consumption device initiates a CIBA request and the auth device is connected via LiveView or Channels.
**Example:**
Lockspire publishes `{:ciba_request, auth_req_id}` to a user-specific PubSub topic. The host app's LiveView subscribes to this topic and prompts the user on their phone. Once approved, the LiveView calls Lockspire API to approve, which signals the token endpoint poll.

### Pattern 2: Token Exchange via Callbacks
**What:** Host app provides a callback module implementing `Lockspire.TokenExchange.Validator`.
**When:** The Identity Provider needs to know if User A is allowed to impersonate User B, or if Client X can exchange a token for Client Y.
**Example:**
\`\`\`elixir
defmodule MyApp.TokenExchangeValidator do
  @behaviour Lockspire.TokenExchangeValidator

  def validate_exchange(subject_token, requested_token_type, _conn) do
    # Domain-specific logic
  end
end
\`\`\`

## Anti-Patterns to Avoid

### Anti-Pattern 1: Strict `Plug.Conn.get_peer_data/1` for mTLS
**What:** Attempting to read the client certificate directly from the Erlang SSL socket in a standard Phoenix app.
**Why bad:** Phoenix apps are almost always deployed behind a TLS-terminating load balancer (ALB, Nginx, Fly.io edge). The socket will not have the client certificate.
**Instead:** The application MUST read the certificate from a configurable HTTP header (e.g., `X-Forwarded-Client-Cert`), requiring the host app developer to ensure their proxy securely sets this and strips spoofed headers.

### Anti-Pattern 2: Hardcoding RAR Schemas
**What:** Defining strict JSON schemas for `authorization_details` in Lockspire itself.
**Why bad:** RAR is domain-specific. A banking app has different RAR structures than an IoT app.
**Instead:** Provide a dynamic Ecto type or allow host apps to supply an `embedded_schema` module to validate incoming RAR structures.
