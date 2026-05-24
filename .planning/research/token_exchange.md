# Token Exchange (RFC 8693) Implementation Research for Lockspire

**Context:** Implementation of OAuth 2.0 Token Exchange (RFC 8693) for Lockspire (an embedded Elixir/Phoenix OIDC provider).
**Verdict:** HIGHLY RECOMMENDED for microservices architectures, but requires strict boundary controls.
**Confidence:** HIGH

## Executive Summary

RFC 8693 defines a protocol for exchanging one token for another, enabling two critical patterns: **Delegation** (Service A acts *on behalf of* User U) and **Impersonation** (Admin acts *as* User U). While highly valuable in multi-tier architectures (e.g., API Gateways to microservices), it introduces significant security and token lifecycle complexity. For an embedded provider like Lockspire, this must be built with strict downscoping rules and an idiomatic, explicit Elixir API to prevent privilege escalation.

## Lessons Learned from Other Ecosystems

1. **node-oidc-provider**:
   - Does not ship Token Exchange "out of the box", but provides a robust Custom Grant Type API.
   - **Lesson:** Provide an extensible grant pipeline. Let developers register `urn:ietf:params:oauth:grant-type:token-exchange` and supply a callback/module that dictates the business logic for token validation and exchange.
2. **Keycloak & IdentityServer**:
   - Offer highly structured administrative UI/policies defining "Client A is allowed to exchange tokens for Client B".
   - **Lesson:** Token Exchange policies must be first-class citizens. Do not leave the authorization of the exchange purely to undocumented developer code. If Client A tries to exchange a token, the provider must check a strict `may_act` or explicit delegation policy.
3. **General Footguns**:
   - **Token Bloat:** Deep delegation chains (where `act` claims are deeply nested like `act: { sub: "A", act: { sub: "B" } }`) lead to massive JWTs that exceed HTTP header limits.
   - **Scope Escalation:** If the exchange handler doesn't enforce that the requested scope is a subset of the original `subject_token` scope, a compromised internal service can elevate privileges.

## Idiomatic Elixir / Plug / Ecto Architecture

For Lockspire, Token Exchange should be seamlessly integrated into the existing token endpoint using Plug and Ecto.

### 1. The Plug Layer (Protocol Validation)
Pattern match the incoming custom grant at the Plug level to extract parameters.

```elixir
# Lockspire.Protocol.TokenExchangePlug
def call(%Plug.Conn{params: %{"grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange"}} = conn, _opts) do
  with {:ok, exchange_req} <- parse_and_validate_params(conn.params),
       {:ok, new_token} <- Lockspire.Domain.Token.exchange(exchange_req) do
    render_token(conn, new_token)
  else
    {:error, reason} -> render_error(conn, reason)
  end
end
```

### 2. The Domain Layer (Policy & Validation)
Leverage pattern matching to cleanly separate Impersonation vs Delegation based on the presence of the `actor_token`.

```elixir
# Impersonation (No Actor Token)
def exchange(%{subject_token: sub_tok, actor_token: nil, client: client}) do
  # Validate subject token, check if client has impersonation rights
end

# Delegation (Actor Token Present)
def exchange(%{subject_token: sub_tok, actor_token: act_tok, client: client}) do
  # Validate BOTH tokens, ensure act_tok is authorized to act on behalf of sub_tok
end
```

### 3. Ecto & Token Storage
When resolving the `subject_token`, query Ecto to ensure the token hasn't been revoked. 

```elixir
# Validating the subject token against the database
def get_valid_subject_token(token_string) do
  from(t in Token,
    where: t.token == ^token_string and t.revoked_at |> is_nil() and t.expires_at > ^DateTime.utc_now()
  )
  |> Repo.one()
end
```

### 4. JWT Construction (The `act` Claim)
Elixir's map manipulation makes constructing the `act` claim very clean. Lockspire should provide a structured helper to prevent developers from manually mangling the claim.

```elixir
def build_delegation_claims(subject_claims, actor_claims) do
  subject_claims
  |> Map.put("act", %{"sub" => actor_claims["sub"]})
  # Ensure scopes are downscoped
  |> Map.put("scope", downscope(subject_claims["scope"], requested_scope))
end
```

## Developer Ergonomics (DX) & Principle of Least Surprise

- **Explicit Opt-in:** Token Exchange should be disabled by default. It's a powerful feature that expands the attack surface.
- **DSL for Delegation:** Lockspire should provide a simple configuration DSL for defining exchange policies, rather than forcing the developer to write custom Plug logic. 
  - *Example:* `config :lockspire, token_exchange: [allow: {"frontend_client", to_act_as: "backend_service"}]`
- **Clear Error Messages:** If an exchange fails, the error should clearly state whether it was a token validation failure (e.g., `subject_token` expired) or a policy failure (e.g., Client A not allowed to impersonate User U).
- **Extensible Callbacks:** For complex ecosystems, provide a behavior (`Lockspire.TokenExchange.Policy`) that developers can implement to query their own domain logic for impersonation rights.

## Tradeoffs and Risks

| Pro | Con | Mitigation in Lockspire |
| :--- | :--- | :--- |
| Solves microservice context propagation cleanly. | Massive increase in token state complexity. | Strict Ecto schema separation between standard tokens and exchanged tokens (tracking the `grant_id` lineage). |
| Standardized via RFC 8693 (no custom headers needed). | Potential for scope privilege escalation. | Hardcode downscoping at the domain level; do not let user-provided callbacks override it. |
| Auditable delegation via `act` claims. | Deep delegation chains bloat JWT size. | Limit delegation depth via configuration (e.g., `max_delegation_depth: 1`). |

## Roadmap Recommendation
1. Implement standard custom grant support first (if not already present).
2. Build Token Exchange strictly for the `access_token` to `access_token` use case initially.
3. Add `act` claim generation and parsing helpers.
4. Introduce a `Lockspire.TokenExchange.Policy` behavior for developers to authorize exchanges.
