<user_constraints>
## User Constraints

### Locked Decisions
- Create `Lockspire.Host.TokenExchangeValidator` behaviour.
- Create `%Lockspire.Host.TokenExchangeContext{}` struct.
- Return signature: `:ok | {:ok, %{claims: map()}} | {:error, term()}`.
- Add `token_exchange_validator/0` to `Lockspire.Config` (fails securely/returns default-deny if missing/not configured).
- Invoke it in `Lockspire.Protocol.Rfc8693Exchange` before token minting.
- Map `{:error, reason}` to an `access_denied` OAuth error, logging the internal reason.
- Merge custom claims returned in `{:ok, %{claims: custom_claims}}` into the new minted token securely (rejecting overrides of protocol claims like iss, sub, aud, exp, jti).

### the agent's Discretion
None

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

# Phase 49: Host Policy Behaviour - Research

**Researched:** 2024-05-05
**Domain:** Protocol Extension & Domain Authorization
**Confidence:** HIGH

## Summary

Phase 49 introduces domain-specific logic allowing the host application to authorize, augment, or reject OAuth 2.0 Token Exchanges (RFC 8693). This bridges the gap between Lockspire's purely protocol-level exchange validation (e.g. validating the `subject_token`) and the host app's business logic (e.g. checking subscription tiers, tenant boundaries, or adding tenant-specific claims to the resulting token).

A critical finding is that `Lockspire.Protocol.Rfc8693Exchange` currently issues an opaque access token string via `TokenFormatter.format_access_token/1`. However, the requirement to merge custom claims and protect protocol claims (`iss`, `sub`, `aud`, `exp`, `jti`) necessitates issuing the access token as a signed JWT instead of an opaque string when custom claims are involved. This will require leveraging Lockspire's existing `IdToken.sign/1` mechanism or adding a dedicated JWT signing function to format a structured JWT access token for this specific flow.

**Primary recommendation:** Introduce the `Lockspire.Host.TokenExchangeValidator` behaviour and integrate it into `Rfc8693Exchange`, shifting token generation to a signed JWT if the validator returns custom claims, taking care to strictly enforce protocol claim boundaries.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token Exchange Domain Logic | API / Backend | — | The token exchange behavior dictates whether the host app permits an exchange; this is pure backend business logic. |
| Access Token Minting | API / Backend | — | Protocol boundaries dictate token formats and signatures. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Lockspire.Protocol.IdToken` (or internal JWK utils) | Current | JWT Generation | Required for issuing structured access tokens containing custom claims. |

## Architecture Patterns

### Recommended Pattern: The Host Seam

The Host pattern relies on behaviours defined in `lib/lockspire/host/` which are invoked by the core protocol, with configuration fetching wrapped securely in `Lockspire.Config`.

**What:** A configurable validator module implementing a defined behaviour that intercepts the token exchange process.
**When to use:** When the protocol requires domain-specific decisions that the library cannot natively know.

**Example Implementation:**
```elixir
defmodule Lockspire.Host.TokenExchangeValidator do
  @moduledoc "Host behaviour for validating RFC 8693 Token Exchanges."

  @type context :: Lockspire.Host.TokenExchangeContext.t()
  
  @callback validate(context()) :: 
              :ok | 
              {:ok, %{claims: map()}} | 
              {:error, term()}
end
```

### Anti-Patterns to Avoid
- **Implicit Default-Allow on Missing Config:** If the host forgets to configure a validator, defaulting to `:ok` represents a major security vulnerability for endpoints that could escalate privileges. Instead, `Config.token_exchange_validator/0` must implement a default-deny behavior or raise at boot/runtime if not explicitly handled.
- **Deep Merging Custom Claims Over Protocol Claims:** Using `Map.merge(protocol_claims, custom_claims)` allows a host to manipulate the token's lifetime or subject. The merge direction MUST be `Map.merge(custom_claims, protocol_claims)` or use `Map.drop/2` on the custom claims to strip restricted keys.

## Common Pitfalls

### Pitfall 1: Opaque vs Structured Access Tokens
**What goes wrong:** Attempting to inject `custom_claims` into an opaque token (like a 32-byte randomized string), which is structurally impossible, or storing them in the database record but failing to return them to the resource server.
**Why it happens:** The current `Rfc8693Exchange` code uses `TokenFormatter.format_access_token`, which assumes opaque tokens by default.
**How to avoid:** If `custom_claims` are returned by the validator, switch the generation method to emit a signed JWT. Ensure the JWT is signed with the provider's active JWK using existing internal mechanisms.

### Pitfall 2: Overriding Protocol Claims
**What goes wrong:** A host application accidentally (or maliciously) returns custom claims containing `"exp"` or `"sub"`, overwriting the protocol's validated claims.
**Why it happens:** Blindly merging `Map.merge(protocol_claims, custom_claims)`.
**How to avoid:** 
```elixir
# Safe merging pattern
restricted_keys = ["iss", "sub", "aud", "exp", "jti", "iat", "client_id"]
safe_custom_claims = Map.drop(custom_claims, restricted_keys)
final_claims = Map.merge(safe_custom_claims, protocol_claims)
```

### Pitfall 3: Error Masking in Logs
**What goes wrong:** The host returns `{:error, :tenant_suspended}`. The protocol maps this to a generic `access_denied` error, but the specific `tenant_suspended` reason is never logged, making debugging impossible for the operator.
**Why it happens:** The OAuth error struct overwrites the underlying reason code without logging it.
**How to avoid:** Emit an observability/telemetry event or use `Logger.warning` with the internal reason before returning the generic `Error` struct.

## Code Examples

### Config Resolver Default-Deny
```elixir
def token_exchange_validator do
  case Application.get_env(:lockspire, :token_exchange_validator) do
    nil -> Lockspire.Host.DefaultDenyTokenExchangeValidator
    module when is_atom(module) -> module
  end
end
```

### Token Exchange Context
```elixir
defmodule Lockspire.Host.TokenExchangeContext do
  @enforce_keys [:client_id, :subject_token, :requested_scopes]
  defstruct [:client_id, :subject_token, :requested_scopes]
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Quick run command | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-49-1 | Rejects exchange if validator returns `{:error, reason}` | unit | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs` | ✅ |
| REQ-49-2 | Mints structured token containing custom claims | unit | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs` | ✅ |
| REQ-49-3 | Prevents custom claims from overriding `iss`, `exp`, etc. | unit | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs` | ✅ |
| REQ-49-4 | Fails securely if config is missing | unit | `mix test test/lockspire/config_test.exs` | ✅ |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Protocol restricts subject impersonation via hardcoded claim overrides. |
| V4 Access Control | yes | Host validator serves as the primary authorization gate for token exchanges. |
| V6 Cryptography | yes | Minted tokens must be cryptographically signed (JWT) if claims are embedded. |

### Known Threat Patterns for Elixir/OAuth

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Claim Injection / Overwrite | Tampering | Drop restricted protocol keys from host map before merging. |
| Unconfigured Open-Proxy | Elevation of Privilege | Implement default-deny validator if config is missing. |

## Sources

### Primary (HIGH confidence)
- Codebase audit: `lib/lockspire/protocol/rfc8693_exchange.ex`
- Codebase audit: `lib/lockspire/config.ex`
- Context: Phase 49 Decision Document.
