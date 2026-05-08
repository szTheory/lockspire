# Technology Stack

**Project:** Lockspire
**Researched:** 2024

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Plug | ~> 1.14 | Header & Peer Data Extraction | Standard interface for intercepting HTTP requests in Elixir/Phoenix, allowing inspection of both `conn.req_headers` and `Plug.Conn.get_peer_data/1`. |
| Erlang `:public_key` | standard lib | X.509 Parsing | Built-in Erlang capability to decode PEM or DER certificates, extract the Subject DN, and calculate thumbprints without external C dependencies. |
| Erlang `:crypto` | standard lib | Thumbprint Hashing | Fast, native SHA-256 calculation required for the `x5t#S256` token binding claims (RFC 8705). |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| x509 | ~> 0.8 | Dev/Test PKI Generation | Excellent for generating self-signed client certificates and CA chains during test suite execution to prove mTLS extraction paths. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| mTLS Plug Library | Native Implementation | `apiac_auth_mtls` | `apiac` is a broader API access control suite. Lockspire needs a highly specific, embedded approach tailored to its existing protocol pipeline and JWT handling, rather than importing an external generalized auth suite. |

## Installation

No new production dependencies are required beyond standard Erlang/Elixir libraries.

```bash
# Dev/Test dependencies for generating certificates in test suites
npm install -D {:x509, "~> 0.8", only: [:test, :dev]}
```

## Sources

- Erlang `:public_key` docs: https://www.erlang.org/doc/man/public_key.html
- Elixir Plug docs: https://hexdocs.pm/plug/Plug.Conn.html
- RFC 8705: https://datatracker.ietf.org/doc/html/rfc8705