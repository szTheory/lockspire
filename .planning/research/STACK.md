# Technology Stack

**Project:** Lockspire
**Researched:** 2026-05-22

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `:public_key` (Erlang) | OTP 25+ | x.509 Parsing | Native OTP capabilities for decoding DER/PEM certificates without external dependencies. |
| `Plug.Conn` | Elixir/Phoenix | State & Header Extraction | Core primitive for reading `x-forwarded-client-cert` headers or `:ssl` peer data. |
| `x509` (Hex) | `~> 0.8` | Certificate Validation | If Erlang's native `:public_key` is too low-level for checking SANs, the `x509` package is the Elixir standard for ergonomic certificate handling. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `apiac_auth_mtls` | `~> 1.0` | Reference / Alternative | Review for reference implementation of extracting certificates from proxy headers versus native Cowboy termination. Lockspire should likely build extraction directly into its own pipeline to avoid generic dependency bloat, but the logic is heavily validated here. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Cert Parsing | Erlang `:public_key` or `x509` | Hand-rolled binary parsing | Security risk. Use battle-tested OTP/Hex libs for cryptographic primitives. |
| MTLS Termination | Host Proxy (Nginx/Envoy) | Forced Cowboy Direct | Modern Phoenix apps are almost always behind edge proxies (Fly.io, ALB). Forcing Cowboy direct termination breaks the "embedded library" promise by dictating deployment architecture. |

## Installation
No new external dependencies strictly required if using `:public_key`, but `{:x509, "~> 0.8.8"}` is highly recommended for developer ergonomics.

## Sources
- Erlang OTP `:public_key` documentation
- Hexdocs: `x509` and `apiac_auth_mtls`