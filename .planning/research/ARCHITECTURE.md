# Architecture Patterns

**Domain:** Embedded OAuth/OIDC Provider (Phoenix/Elixir)
**Researched:** 2026-05-22

## Recommended Architecture

Because Lockspire is an embedded library, it cannot control the TLS termination boundary. It must treat the client certificate as contextual data provided by the host application through a formalized extraction boundary.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Lockspire.MTLS.Extractor` (Behaviour) | Extracts raw client certificate from `Plug.Conn` (via Cowboy `:ssl` or Proxy Headers). | Host App implementation, Lockspire Plugs |
| `Lockspire.ClientAuth` | Validates `tls_client_auth` and `self_signed_tls_client_auth` against client registration metadata. | Extractor, Client Storage |
| `Lockspire.TokenPipeline` | Computes `x5t#S256` hash of the cert and embeds it in the token `cnf` claim. | Extractor, Token Generator |

### Data Flow

1. External request hits Proxy (Nginx/Envoy). Proxy terminates mTLS and adds `X-Forwarded-Client-Cert` header.
2. Request hits Phoenix `Endpoint` -> `Router` -> `Lockspire.Plug.MTLSContext`.
3. `Lockspire.Plug.MTLSContext` calls the configured `MTLS.Extractor` (e.g., `MyApp.MyNginxExtractor`).
4. Extractor returns the parsed `:public_key` x.509 record.
5. Lockspire stores the cert record in `conn.private[:lockspire_mtls_cert]`.
6. Downstream pipelines (Token, PAR, CIBA) read the cert from the connection for authentication or `cnf` binding.

## Patterns to Follow

### Pattern 1: Host-Provided Extractor
**What:** Do not hardcode header names or parsing logic. Expose a Behaviour that host apps implement.
**When:** Extracting proxy-offloaded certificates.
**Example:**
```elixir
defmodule MyApp.Lockspire.MTLSExtractor do
  @behaviour Lockspire.MTLS.Extractor

  def extract(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-client-cert") do
      [pem] -> parse_pem(pem)
      [] -> nil
    end
  end
end
```

### Pattern 2: Endpoint Aliasing
**What:** Support `mtls_endpoint_aliases` in `.well-known/openid-configuration`.
**Why:** Many load balancers require mTLS to be enabled per-domain. It's common to host the standard API on `api.example.com` and the mTLS API on `matls.api.example.com`.
**Instead of:** Forcing the host to use a single domain for both standard and mTLS traffic.

## Scalability Considerations

| Concern | Resolution |
|---------|------------|
| Parsing Overhead | PEM decoding is fast, but should only be executed on endpoints that explicitly require Client Auth or Token Binding (e.g., `/token`, `/par`), not unconditionally on every request. |
| Header Size | Client certificates can be several kilobytes. Ensure Phoenix's header size limits are configured appropriately if proxying via HTTP headers. |