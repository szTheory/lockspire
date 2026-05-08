# Architecture Patterns

**Domain:** RFC 8705 (Mutual TLS for OAuth)
**Researched:** 2024

## Recommended Architecture

Lockspire's embedded nature means it cannot control the physical network topology. The architecture must assume the host app is either terminating TLS directly in Erlang or offloading it to a reverse proxy.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Lockspire.Plug.ExtractClientCert` | Extracts the client certificate from either `Plug.Conn.get_peer_data/1` or configured HTTP headers, parses it via `:public_key`, and assigns it to `conn.assigns.lockspire_client_cert`. | Host application pipeline |
| `Lockspire.Protocol.MTLS` | Handles the RFC 8705 authentication logic, validating the certificate's thumbprint against the client's registered JWKS or Subject DN against metadata. | `ExtractClientCert` (consumes `assigns`) |
| Token Issuer | Injects the `cnf` claim (`x5t#S256`) into the access token payload during the token exchange if mTLS is used. | `Protocol.MTLS` |
| Resource Validator | Ensures the certificate presented during a resource request matches the `cnf` claim in the presented access token. | `ExtractClientCert` |

### Data Flow

1. **Request Ingress:** A request arrives at the host's Phoenix Endpoint.
2. **Extraction Plug:** `ExtractClientCert` runs early in the pipeline.
   - If configured for direct TLS, it reads `get_peer_data/1`.
   - If configured for proxy headers, it reads the trusted header (e.g., `Client-Cert`).
3. **Parsing:** The PEM/DER data is parsed into an Erlang `:OTPCertificate` record and stored in `conn.assigns`.
4. **Endpoint Processing:** When the request hits the Token Endpoint (or a protected resource), Lockspire reads the certificate from `assigns` and performs the necessary RFC 8705 validation.

## Patterns to Follow

### Pattern 1: Early Explicit Extraction
**What:** Extracting the certificate via a Plug *before* it reaches the specific OAuth endpoints.
**When:** Always.
**Example:**
```elixir
# In the host application's endpoint.ex or router.ex
plug Lockspire.Plug.ExtractClientCert,
  source: :header,
  header_name: "client-cert",
  trusted_proxies: ["10.0.0.0/8"] # Highly recommended
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Implicit Header Trust
**What:** Automatically parsing `X-SSL-Cert` or `Client-Cert` headers without explicit host-app configuration.
**Why bad:** This leads directly to header spoofing vulnerabilities if the host app's proxy isn't configured to strip these headers from external traffic.
**Instead:** Require explicit configuration (`source: :header`) and strongly recommend restricting the extraction to trusted internal IP ranges.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Certificate Parsing | Negligible | `:public_key.pem_decode` is fast, but doing it on every request adds CPU overhead. | The reverse proxy should ideally send just the pre-calculated SHA-256 thumbprint in a header if possible, or parsing remains highly optimized in native Erlang. |

## Sources

- Elixir Plug and HTTP Header semantics.
- RFC 8705 architecture models.