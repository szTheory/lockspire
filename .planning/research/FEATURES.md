# Feature Landscape

**Domain:** RFC 8705 (Mutual TLS for OAuth)
**Researched:** 2024

## Table Stakes

Features users expect for basic RFC 8705 compliance. Missing = product feels incomplete for FAPI 2.0 Advanced.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `tls_client_auth` | Standard PKI-based client authentication. | Med | Requires validating the Subject DN against client metadata. |
| `self_signed_tls_client_auth` | Self-signed JWKS-based authentication. | Med | Matches certificate thumbprint against pre-registered keys in the client's JWKS. |
| Certificate-Bound Access Tokens | Required by RFC 8705 for sender-constraining. | Low | Injecting `cnf` claim (`x5t#S256`) during issuance and validating it on introspection/resource requests. |
| Proxy Header Extraction | Crucial for real-world Elixir deployments behind NGINX/ALB. | High | Must handle URL-encoded PEM, raw PEM, or standard RFC 9440 formats securely. |

## Differentiators

Features that set product apart. Not expected, but valued in an embedded context.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Explicit Proxy Trust Config | Host apps must explicitly map *which* header is trusted and from *which* internal IPs. | Med | Prevents accidental header spoofing vulnerabilities out-of-the-box. |
| Support for RFC 9440 | Adopting the modern `Client-Cert` header standard. | Low | Most ecosystems still rely on custom `X-SSL-Cert` headers; standardizing on RFC 9440 is future-proof. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Native TLS Termination UI/Config | Lockspire is not a reverse proxy. Configuring Erlang `:ssl` options for the whole Phoenix app is out of scope. | Provide clear documentation on how the host app configures NGINX or Phoenix `Endpoint` directly, and have Lockspire only care about extracting the data from the `conn`. |

## Feature Dependencies

```
Proxy Header Extraction / Peer Data Extraction
  ↓
mTLS Client Authentication (`tls_client_auth`)
  ↓
Certificate-Bound Access Tokens (`cnf` claim)
```

## MVP Recommendation

Prioritize:
1. Proxy Header Extraction (the secure foundation).
2. `self_signed_tls_client_auth` (easier to test and widely used in Open Banking).
3. Certificate-Bound Access Tokens (sender-constraining).

Defer: Full PKI `tls_client_auth` relying on CA chains if it introduces too much complexity initially, focusing first on the self-signed thumbprint method which aligns well with existing JWKS infrastructure in Lockspire.

## Sources

- RFC 8705 (OAuth 2.0 Mutual-TLS Client Authentication and Certificate-Bound Access Tokens)
- RFC 9440 (Client-Cert HTTP Header)