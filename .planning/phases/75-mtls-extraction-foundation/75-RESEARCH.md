<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Extractor Integration Method**: Host applications MUST explicitly opt-in to mTLS extraction by placing `plug Lockspire.MTLS.Plug, extractor: {Mod, opts}` in their router pipeline, *before* forwarding to `Lockspire.Web.Router`. The extracted certificate will be stored in `conn.private[:lockspire_mtls_cert]`.
- **Extractor Output Signature**: The `Lockspire.MTLS.Extractor` behaviour will define a single callback: `@callback extract(Plug.Conn.t(), keyword()) :: {:ok, binary()} | {:error, atom()}`. It must return the raw DER-encoded binary of the client certificate.
- **Proxy Header Formatting**: `Lockspire.MTLS.ProxyHeaderExtractor` will not attempt to guess the header format. The host must explicitly configure the format (e.g., `:url_encoded_pem` or `:envoy_xfcc`).
- **Native Cowboy Extraction**: `Lockspire.MTLS.CowboyDirectExtractor` will use `Plug.Conn.get_peer_data(conn)[:ssl_cert]` natively.

### the agent's Discretion
None

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MTLS-EXT-01 | Define a `Lockspire.MTLS.Extractor` behaviour for retrieving client certs. | Confirmed callback signature `extract/2` returning DER binary. |
| MTLS-EXT-02 | Provide a `CowboyDirectExtractor` for extracting certificates natively. | Verified `Plug.Conn.get_peer_data/1` returns raw DER binary. |
| MTLS-EXT-03 | Provide a `ProxyHeaderExtractor` for extracting URL-encoded PEM certs. | Identified Nginx (`url_encoded_pem`) and Envoy (`envoy_xfcc`) formats and Erlang `:public_key.pem_decode` usage. |
| MTLS-EXT-04 | Extraction MUST require explicit host configuration in Plug pipeline. | Confirmed design choice using `plug Lockspire.MTLS.Plug` over global `config.exs`. |
</phase_requirements>

# Phase 75: MTLS Extraction Foundation - Research

**Researched:** 2024-05-22
**Domain:** Elixir/Plug HTTP mTLS Extraction
**Confidence:** HIGH

## Summary

This phase establishes the foundation for extracting Mutual TLS (mTLS) client certificates from incoming requests in Elixir. Because mTLS termination can happen natively (in Cowboy/Erlang) or at an edge proxy (Nginx, Envoy, API Gateway), Lockspire must support both through a unified abstraction.

The primary recommendation is to enforce explicit extraction via a Phoenix/Plug router pipeline rather than implicit global configuration (e.g., `config.exs`). This addresses the prompt's question about configuration placement: a router plug `plug Lockspire.MTLS.Plug, extractor: {...}` provides the host with precise, route-specific control and prevents the number one mTLS vulnerability—implicit trust of spoofed proxy headers.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **mTLS Extraction Opt-in** | Frontend Server (SSR) | — | The host application's Router pipeline is the correct boundary. Global `config.exs` lacks route-level granularity. |
| **Proxy Header Parsing** | API / Backend | — | Lockspire provides the extractors that parse URL-encoded PEM or Envoy XFCC headers into DER. |
| **TLS Termination** | CDN / Proxy | Cowboy (Backend) | Lockspire does not terminate TLS; it extracts the resulting artifact from the runtime environment. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Plug.Conn` | > 1.0 | Connection state | Built-in Phoenix/Elixir HTTP primitive; provides `get_peer_data/1`. |
| `:public_key` | Built-in | Certificate parsing | Erlang OTP standard library; avoids heavy 3rd-party dependencies like `x509`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:public_key` | `x509` (Hex) | `x509` offers nicer Elixir wrappers but adds unnecessary dependency weight just to extract a DER binary. |

## Architecture Patterns

### System Architecture Diagram

```
[Edge Proxy / Load Balancer] --(mTLS terminated, inserts XFCC header)--> [Host App Endpoint]
                                                                               |
                                                                        [Router Pipeline]
                                                                               |
                                                                  plug Lockspire.MTLS.Plug
                                                                (invokes configured Extractor)
                                                                               |
                                                                   [Lockspire.Web.Router]
                                                                (consumes conn.private cert)
```

### Recommended Project Structure
```text
lib/lockspire/mtls/
├── extractor.ex                # Behaviour definition
├── plug.ex                     # Middleware enforcer
├── cowboy_direct_extractor.ex  # Cowboy-native extraction
└── proxy_header_extractor.ex   # Header-based extraction
```

### Pattern 1: Explicit Plug Integration
**What:** The host explicitly opts into extraction in their router, passing the extractor configuration.
**When to use:** Always, for boundary enforcement.
**Example:**
```elixir
pipeline :mtls_api do
  plug :accepts, ["json"]
  plug Lockspire.MTLS.Plug, extractor: {Lockspire.MTLS.ProxyHeaderExtractor, header: "x-forwarded-client-cert", format: :url_encoded_pem}
end
```

### Pattern 2: Cowboy Native Extraction
**What:** Extracting the raw DER binary from the underlying Erlang `:ssl` socket.
**When to use:** When Cowboy terminates the TLS connection directly.
**Example:**
```elixir
case Plug.Conn.get_peer_data(conn) do
  %{ssl_cert: cert} when is_binary(cert) -> {:ok, cert} # Already DER format
  _ -> {:error, :no_cert}
end
```

### Pattern 3: Proxy Header Extraction
**What:** Parsing the URL-encoded PEM from an edge proxy.
**When to use:** When behind Nginx, Envoy, or AWS API Gateway.
**Example:**
```elixir
with [header_value] <- Plug.Conn.get_req_header(conn, "x-forwarded-client-cert"),
     pem_string <- URI.decode(header_value),
     [{:Certificate, der, :not_encrypted} | _] <- :public_key.pem_decode(pem_string) do
  {:ok, der}
else
  _ -> {:error, :invalid_header}
end
```

### Anti-Patterns to Avoid
- **Config.exs extraction config:** Assuming mTLS extraction should be configured in `config.exs`. It removes the host's ability to selectively apply mTLS to specific pipelines (e.g., admin vs public APIs).
- **Implicit Header Trust:** Auto-detecting XFCC headers without explicit configuration. This allows attackers to spoof `X-Forwarded-Client-Cert` on unprotected routes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PEM Parsing | Regex or string splitting | `:public_key.pem_decode/1` | Erlang handles the complexities of Base64, whitespace, and ASN.1 wrapping natively. |
| Peer Data access | Reaching into Cowboy socket | `Plug.Conn.get_peer_data/1` | Plug maintains compatibility across Cowboy upgrades. |

## Common Pitfalls

### Pitfall 1: Assuming Cowboy provides PEM
**What goes wrong:** Attempting to decode the result of `Plug.Conn.get_peer_data(conn)[:ssl_cert]`.
**Why it happens:** Misunderstanding Erlang's `:ssl` module.
**How to avoid:** Remember that Cowboy/Erlang natively return the raw DER-encoded binary, not PEM. No decoding is necessary.

### Pitfall 2: Envoy XFCC Format Complexity
**What goes wrong:** Crashing when Envoy sends multiple proxy hops.
**Why it happens:** Envoy `x-forwarded-client-cert` can be a comma-separated list of semicolon-separated key-value pairs (e.g., `By=...;Hash=...;Cert="..."`).
**How to avoid:** Provide an `:envoy_xfcc` format option that defensively parses the `Cert="..."` value from the string.

## Code Examples

Verified patterns from official sources:

### Plug.Conn.Adapter.peer_data
```elixir
# Source: HexDocs for Plug (https://hexdocs.pm/plug/Plug.Conn.Adapter.html)
@type peer_data() :: %{
  address: :inet.ip_address(),
  port: :inet.port_number(),
  ssl_cert: binary() | nil
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Global implicit extraction | Route-level Plug enforcement | Lockspire Phase 75 | Eliminates header spoofing vulnerabilities by requiring explicit host opt-in. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Envoy text format provides `Cert` as a URL-encoded string inside quotes | Architecture Patterns | The `:envoy_xfcc` parser might fail to extract the certificate correctly. |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond standard Erlang OTP/Elixir)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/lockspire/mtls` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MTLS-EXT-01 | Defines Extractor behaviour | unit | `mix test test/lockspire/mtls/extractor_test.exs` | ❌ Wave 0 |
| MTLS-EXT-02 | Cowboy direct extraction works | unit | `mix test test/lockspire/mtls/cowboy_direct_extractor_test.exs` | ❌ Wave 0 |
| MTLS-EXT-03 | Proxy header extraction works | unit | `mix test test/lockspire/mtls/proxy_header_extractor_test.exs` | ❌ Wave 0 |
| MTLS-EXT-04 | Plug halts on invalid/missing cert | unit | `mix test test/lockspire/mtls/plug_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/lockspire/mtls/plug_test.exs` — covers MTLS-EXT-04
- [ ] `test/lockspire/mtls/cowboy_direct_extractor_test.exs` — covers MTLS-EXT-02
- [ ] `test/lockspire/mtls/proxy_header_extractor_test.exs` — covers MTLS-EXT-03
- [ ] Valid PEM and DER fixtures in tests for assertions.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | mTLS extraction primitive |
| V3 Session Management | no | — |
| V4 Access Control | yes | Certificate-bound tokens rely on this extraction |
| V5 Input Validation | yes | `:public_key.pem_decode` |
| V6 Cryptography | yes | Erlang `:ssl` and `:public_key` |

### Known Threat Patterns for Elixir/Plug

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Proxy Header Spoofing | Spoofing | Require explicit Plug configuration; do not auto-detect XFCC. |
| ASN.1 Parsing DoS | Denial of Service | Use built-in OTP C-based decoders (`:public_key`); limit header size in Plug. |

## Sources

### Primary (HIGH confidence)
- HexDocs for Plug - `Plug.Conn.get_peer_data/1` signature verification
- `75-DECISIONS.md` - Lockspire MTLS Architecture Decisions
- `75-PATTERNS.md` - Lockspire Pattern Map

### Secondary (MEDIUM confidence)
- Envoy Proxy Documentation - X-Forwarded-Client-Cert text format

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Erlang/Elixir modules are heavily established.
- Architecture: HIGH - Dictated by `75-DECISIONS.md`.
- Pitfalls: HIGH - Proxy header spoofing is universally recognized as the primary mTLS risk.

**Research date:** 2024-05-22
**Valid until:** 2025-05-22
