# Feature Landscape

**Domain:** Embedded OAuth/OIDC Provider (Phoenix/Elixir)
**Researched:** 2026-05-22

## Table Stakes

Features users expect for RFC 8705 Mutual TLS compliance.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `tls_client_auth` | Standard PKI client authentication method. | Medium | Requires matching client's certificate Subject Distinguished Name (DN) or Subject Alternative Name (SAN). |
| `self_signed_tls_client_auth` | Allows clients to use self-signed certs registered via JWKS. | Medium | Compares the presented cert against the client's registered `jwks` or `jwks_uri`. |
| Certificate-Bound Access Tokens | Sender-constrains tokens using `cnf: {"x5t#S256": "..."}`. | Low | Lockspire already has `cnf` binding via DPoP. This just adds another binding method. |
| Proxy Header Extraction | Phoenix apps run behind proxies. | High | Must safely parse PEM or XFCC formats from HTTP headers. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| MTLS Endpoint Aliases | `mtls_endpoint_aliases` in Discovery allows host apps to host mTLS endpoints on a different subdomain (e.g., `matls.example.com`). | Medium | Solves the problem where a proxy can't do optional mTLS on the main domain. |
| Host-Owned Extractor Seam | Exposing a `Lockspire.MTLS.Extractor` behaviour so hosts can parse proprietary edge headers (e.g., Cloudflare Access). | Low | Perfectly aligns with Lockspire's "host-owns-the-network" philosophy. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Automatic Proxy Trust | Blindly trusting `X-Forwarded-Client-Cert` opens the door to trivial spoofing. | Require explicit host-app opt-in and provide massive warnings about proxy stripping rules. |
| Automated CA Management | Lockspire is not a Certificate Authority. | The host infrastructure (Vault, AWS ACM) handles CA chains; Lockspire just validates what the proxy passes. |

## Feature Dependencies
- MTLS Extraction Foundation → Client Authentication (`tls_client_auth`)
- MTLS Extraction Foundation → Certificate-Bound Tokens

## MVP Recommendation
Prioritize:
1. Pluggable `MTLS.Extractor` Behaviour
2. Client Authentication (`tls_client_auth` and `self_signed_tls_client_auth`)
3. `x5t#S256` Access Token Binding
4. `mtls_endpoint_aliases` in Discovery Metadata