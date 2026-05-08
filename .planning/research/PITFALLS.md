# Domain Pitfalls

**Domain:** RFC 8705 (Mutual TLS for OAuth)
**Researched:** 2024

## Critical Pitfalls

Mistakes that cause rewrites or major security vulnerabilities.

### Pitfall 1: mTLS Proxy Header Spoofing
**What goes wrong:** An attacker sends an HTTP request containing a forged `Client-Cert` (or `X-SSL-Cert`) header. The application trusts this header and grants access based on the attacker's forged identity.
**Why it happens:** The TLS-terminating reverse proxy (NGINX, ALB) was not configured to sanitize/strip incoming headers before appending its own verified certificate header. Alternatively, the application parses headers implicitly without validating the internal IP address of the proxy.
**Consequences:** Complete bypass of mTLS security. Attackers can impersonate confidential clients or steal sender-constrained access tokens.
**Prevention:** 
1. The proxy *must* overwrite or strip incoming certificate headers.
2. The Lockspire extraction Plug *must* require explicit configuration to trust headers, and ideally validate that the `conn.remote_ip` belongs to the trusted proxy subnet.
**Detection:** Penetration testing by injecting custom headers from the public internet.

### Pitfall 2: Header Normalization Differentials
**What goes wrong:** The proxy strips `Client-Cert` (hyphen) but the attacker sends `Client_Cert` (underscore). The proxy ignores it, but the application framework normalizes underscores to hyphens and parses the attacker's header.
**Why it happens:** Web servers and application frameworks (like Plug/Cowboy) have different rules for HTTP header normalization.
**Consequences:** Header spoofing bypass.
**Prevention:** Use strictly defined header names (e.g., standard RFC 9440 `Client-Cert`). Ensure the extraction Plug uses exact string matching on the normalized header map provided by `Plug.Conn` without doing its own fuzzy matching.

## Moderate Pitfalls

### Pitfall 1: URL-Encoded PEM Artifacts
**What goes wrong:** NGINX often passes certificates URL-encoded (or with spaces replaced by tabs/escapes) in headers (e.g., using `$ssl_client_escaped_cert`). The Elixir `:public_key` module fails to parse this.
**Prevention:** The extraction Plug must intelligently handle URL-decoding and whitespace normalization before attempting `pem_decode`.

## Minor Pitfalls

### Pitfall 1: CPU Overhead on Parsing
**What goes wrong:** Running `:public_key.pem_decode` on a massive certificate chain for every single API request adds CPU overhead.
**Prevention:** For resource servers, consider if the proxy can calculate the SHA-256 thumbprint at the edge and pass *that* in a separate header, avoiding the need for the Elixir app to parse the full PEM on every request. (This is an optimization, not strictly required for MVP).

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Certificate Extraction | Accidental spoofing vulnerability enabled by default. | Make direct TLS (`get_peer_data`) the default, or require a `source` explicitly. Do not automatically fall back to headers. |
| FAPI 2.0 Strictness | Dropping support for DPoP because mTLS is implemented. | FAPI 2.0 Advanced requires mTLS *or* DPoP (often both in practice for different layers). Ensure Lockspire's policy resolver correctly allows either based on client configuration, rather than creating a global XOR. |

## Sources

- FAPI 2.0 Security Profile
- RFC 9440 (Client-Cert HTTP Header)
- Open Banking implementation guidelines on proxy termination.