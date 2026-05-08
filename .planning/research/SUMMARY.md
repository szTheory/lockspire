# Research Summary: Lockspire mTLS (RFC 8705) Support

**Domain:** OAuth 2.0 Mutual-TLS Client Authentication and Certificate-Bound Access Tokens (RFC 8705)
**Researched:** 2024
**Overall confidence:** HIGH

## Executive Summary

Mutual TLS (mTLS) is a core requirement for FAPI 2.0 Advanced profiles, utilizing client certificates for both robust client authentication and sender-constrained access tokens. In a standard Elixir/Phoenix environment, implementing RFC 8705 presents a unique infrastructural challenge: Phoenix applications are typically deployed behind TLS-terminating reverse proxies or load balancers (AWS ALB, NGINX, HAProxy). Because the proxy terminates the TLS session, the actual mTLS handshake happens at the edge, not within Erlang's `:ssl` module.

The ecosystem handles this by having the proxy forward the client certificate details downstream to the Phoenix app via HTTP headers. While standardizing this header transmission has historically been fragmented (relying on `X-SSL-Cert` or `X-Forwarded-Client-Cert`), the recent **RFC 9440 (Client-Cert HTTP Header)** provides a standard path forward. The primary danger of this architecture is **header spoofing**, where a misconfigured proxy allows an attacker's injected certificate header to reach the application.

For Lockspire, acting as an embedded library, the solution requires a flexible, security-first extraction layer that allows host applications to configure whether they are terminating TLS directly (using `Plug.Conn.get_peer_data/1`) or relying on specific trusted headers from a proxy, with strict guidance on proxy sanitization.

## Key Findings

**Stack:** Phoenix Plugs relying on `:public_key` for parsing and standard Elixir crypto for thumbprint verification, with RFC 9440 `Client-Cert` header support.
**Architecture:** A configurable certificate extraction Plug (`Lockspire.Plug.ExtractClientCert`) that sits early in the pipeline, parsing headers or peer data and appending the resolved certificate to `conn.assigns` for downstream authentication/validation.
**Critical pitfall:** Header spoofing. If a proxy fails to strip incoming `Client-Cert` headers, attackers can bypass mTLS entirely and forge the sender-constrained token binding (`cnf` claim).

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Phase 1: Certificate Extraction and Normalization** - Establishes the safe extraction of X.509 certificates from both Erlang's `:ssl` peer data and HTTP headers (specifically standardizing on RFC 9440).
   - Addresses: Safely pulling client certificates in varying deployment topologies.
   - Avoids: Header spoofing vulnerabilities by requiring explicit opt-in for header trust.

2. **Phase 2: mTLS Client Authentication (`tls_client_auth` & `self_signed_tls_client_auth`)** - Implements the actual RFC 8705 authentication methods at the token endpoint.
   - Addresses: Validating the client certificate against registered JWKS/metadata.

3. **Phase 3: Certificate-Bound Access Tokens** - Injects the `cnf` claim (`x5t#S256`) into issued tokens and validates it on protected resources.
   - Addresses: Sender-constraining for FAPI 2.0 Advanced compliance.

**Phase ordering rationale:**
- Extraction (Phase 1) is the prerequisite foundation. Without securely retrieving the certificate, authentication (Phase 2) and token binding (Phase 3) cannot exist. We must solve the proxy-header problem first.

**Research flags for phases:**
- Phase 1: Needs deeper research into exact host-app configuration schemas to ensure the embedded library doesn't accidentally expose a vulnerable default.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Standard Elixir `:public_key` and Plugs are the established path. |
| Features | HIGH | RFC 8705 explicitly defines the requirements for auth and token binding. |
| Architecture | HIGH | The proxy-header pattern is a well-known industry standard for TLS offloading. |
| Pitfalls | HIGH | Header spoofing is universally documented as the primary risk in this architecture. |

## Gaps to Address

- Standardizing operator documentation for exactly how to configure AWS ALB, NGINX, and HAProxy to securely strip and forward the certificate headers to Lockspire.
