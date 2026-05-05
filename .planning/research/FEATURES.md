# Feature Landscape

**Domain:** Embedded OAuth/OIDC Provider (Token Exchange)
**Researched:** 2026-05-XX

## Table Stakes

Features users expect. Missing = product feels incomplete and non-compliant with RFC 8693.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `urn:ietf:params:oauth:grant-type:token-exchange` | Core spec requirement. | Low | Must be supported at the standard token endpoint. |
| Token Type URIs | Required to identify `subject_token` and issued tokens. | Low | E.g., `urn:ietf:params:oauth:token-type:jwt` and `access_token`. |
| Downscoping | Microservices need to reduce token scope for downstream calls. | Medium | Default behavior should strictly subset the requested scopes against the `subject_token` scopes. |
| `subject_token` Validation | Must verify signature, expiration, and issuer. | Medium | Relies on existing token validation logic, but applied to the request payload rather than an Auth header. |

## Differentiators

Features that set Lockspire apart in the Elixir ecosystem.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `Lockspire.TokenExchangeValidator` Behaviour | Gives Phoenix teams complete, type-safe control over audience pivoting and upscoping logic. | Medium | Decouples protocol parsing from domain business rules. |
| Delegation `act` Claim Chain | Full support for complex delegation tracing. | High | Mints tokens that explicitly map the chain of custody (who acts for whom) to prevent stealth privilege escalation. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Hardcoded RBAC/Policies | Lockspire does not own the host app's domain logic or user roles. | Delegate to the host application via the Behaviour. |
| Default Upscoping | Massive security risk (privilege escalation). | Strictly deny requests for larger scopes/different audiences unless explicitly approved by the host app's validator module. |

## Feature Dependencies

`grant-type:token-exchange` parsing → `subject_token` validation → Host App Validator Behaviour → Token Minting (with `act` claims).

## MVP Recommendation

Prioritize:
1. Parsing the `token-exchange` grant type and standardized token type URIs.
2. Validating the `subject_token`.
3. Implementing the `TokenExchangeValidator` Behaviour with a default policy of strict downscoping (only allowing a subset of original scopes/audiences).

Defer: Deep, nested `act` claim chains (multi-hop delegation) until single-hop delegation and impersonation are proven.

## Sources
- [RFC 8693](https://datatracker.ietf.org/doc/html/rfc8693) (HIGH confidence)