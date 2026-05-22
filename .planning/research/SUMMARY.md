# Research Summary: Mutual TLS (RFC 8705) for Lockspire

**Domain:** Embedded OAuth/OIDC Provider (Phoenix/Elixir)
**Researched:** 2026-05-22
**Overall confidence:** HIGH

## Executive Summary
With FAPI 2.0 Message Signing complete (v1.19), Lockspire possesses advanced application-layer non-repudiation and security (DPoP, JARM). The remaining high-leverage trust gap for "real integrator readiness" in regulated environments (e.g., Open Banking, high-value fintech) is Mutual TLS (RFC 8705). While DPoP solves sender-constraining at the application layer, many established ecosystems rigidly mandate mTLS for B2B client authentication and token binding.

Implementing mTLS in an embedded Phoenix library presents unique architectural challenges. Because Phoenix apps are almost universally deployed behind TLS-terminating reverse proxies (AWS ALB, Cloudflare, Fly.io edge, Nginx), Lockspire cannot rely exclusively on Cowboy's direct `:ssl` termination. It must provide robust, spoof-resistant proxy header parsing (e.g., `X-Forwarded-Client-Cert`) while preserving the host app's control over network boundaries.

## Key Findings
**Stack:** Native Cowboy `:ssl` extraction for direct deployments, paired with a configurable Plug-based extractor behaviour for proxy-offloaded architectures. The Erlang `:public_key` or Hex `x509` libraries should be used for parsing.
**Architecture:** Pluggable `Lockspire.MTLS.Extractor` behaviour allowing host apps to define exactly how client certificates are retrieved from the connection, avoiding dangerous "magic" proxy assumptions.
**Critical pitfall:** Proxy Header Spoofing. If Lockspire blindly trusts `X-Forwarded-Client-Cert` headers and the host proxy doesn't strip them from incoming internet requests, attackers can trivially bypass client authentication.

## Implications for Roadmap
Based on research, suggested phase structure for Milestone v1.20 (RFC 8705 Mutual TLS):

1. **Phase: MTLS Extraction Foundation** - Establish the pluggable `MTLS.Extractor` boundary and native Cowboy extraction support.
   - Addresses: Reading certificates via proxy headers or `:ssl` peer data.
   - Avoids: Hardcoding dangerous proxy header assumptions.

2. **Phase: Client Authentication (tls_client_auth)** - Implement `tls_client_auth` and `self_signed_tls_client_auth` client auth methods at the `/token`, `/par`, and `/bc-authorize` endpoints.
   - Addresses: Validating x.509 chains and matching SAN/Subject attributes against client configuration.

3. **Phase: Certificate-Bound Tokens** - Implement `cnf` binding with `x5t#S256` for access tokens.
   - Addresses: Sender-constrained tokens via mTLS, leveraging the existing DPoP `cnf` infrastructure.

4. **Phase: Discovery and Security Posture** - Advertise `mtls_endpoint_aliases` in OpenID configuration and update security docs with explicit proxy-stripping warnings.

**Phase ordering rationale:**
- Extraction must exist before authentication can consume the certificate. Client auth is the primary driver, and token binding reuses existing DPoP infrastructure.

**Research flags for phases:**
- Phase 1: Needs deeper research into exact header formats across common Elixir deployment targets (Fly.io, AWS ALB, Nginx) to ensure the extractor behaviour is sufficiently flexible for real-world deployments.

## Confidence Assessment
| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Cowboy `:ssl` and `Plug.Conn` extraction patterns are well documented. |
| Features | HIGH | RFC 8705 is stable and maps perfectly to existing Lockspire client auth paths. |
| Architecture | HIGH | Pluggable extractors align perfectly with Lockspire's host-owned seam philosophy. |
| Pitfalls | HIGH | Proxy spoofing is a universally recognized mTLS anti-pattern. |

## Gaps to Address
- Which proxy header format should be the "default" provided by Lockspire (e.g., Nginx URL-encoded PEM vs Envoy structured XFCC), or should Lockspire force the host to implement the parser entirely to maximize safety?