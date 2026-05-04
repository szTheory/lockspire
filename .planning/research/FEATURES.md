# Feature Landscape

**Domain:** Embedded OAuth/OIDC Provider for Elixir/Phoenix
**Researched:** 2025-05-24

## Table Stakes

Features users expect for a 1.0 GA Identity Provider. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| 1.0 GA Stabilization | Breaking changes cause churn. Adopters need API guarantees. | High | Requires documentation, audit, and strict deprecation policies. |
| Pluggable Token Storage | Host apps must control how tokens are stored (Ecto, Redis). | Medium | Essential for embedded nature. |

## Differentiators

Features that set product apart. Not expected, but highly valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| OIDC CIBA | Perfect fit for Elixir's real-time PubSub/Channels. Decoupled auth is highly valued in FinTech/POS. | Medium | Differentiator against Go/Ruby tools where backchannel is harder. |
| Token Exchange (RFC 8693) | Native support for microservice delegation/impersonation. | Medium | High demand for internal API gateways. |

## Bleeding Edge / Niche

Features that are powerful but complex or currently niche.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Mutual TLS (mTLS) | FAPI compliance, ultimate token binding. | High | Infra-heavy. Plug must handle proxy headers correctly. |
| Rich Authz Requests (RAR) | Fine-grained JSON-based permissions instead of string scopes. | High | Ecto embedded schemas could make this great, but spec is very new. |

## Feature Dependencies

```
1.0 GA API Contract → Token Exchange (Requires stable token generation APIs)
1.0 GA API Contract → CIBA (Requires stable backchannel interaction endpoints)
mTLS → DCR (Client registration must support TLS client auth subjects)
```

## MVP Recommendation (Next DAG Steps)

Prioritize:
1. 1.0 GA Release (Stabilization)
2. Token Exchange (RFC 8693)
3. OIDC CIBA

Defer: 
- mTLS: Requires massive documentation on reverse proxies (Nginx/ALB).
- RAR: Still standardizing in the wild; wait for more established patterns.
