# Technology Stack

**Project:** Lockspire
**Researched:** 2025-03-08

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Phoenix | ~> 1.8.5 | OP Web Surface | Already in use. Handles Front-Channel Logout natively via standard HTML/LiveView redirects, iframes, and session management. No new framework needed. |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Ecto/Postgres | ~> 3.13 | State Management | Already in use. Will track logout status and session bindings required for back/front-channel logout. |

### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| OIDF Conformance Suite | Latest | OIDC Core Testing | Official tool required to verify OpenID Certification. Acts as the "referee" testing the OP against edge cases. Should be run via Docker locally or used via the hosted certification service. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| erlang-jose (`jose`) | ~> 1.11 | JAR Decryption | Already in project. Has native `JOSE.JWE` support for block/key decryption. Use to decrypt encrypted Request Objects without adding new dependencies. |
| req | ~> 0.5 | Back-Channel Logout POSTs | Use for OP-to-RP server-to-server outbound calls (sending logout tokens). The 2024 Elixir standard with built-in retries and JSON support. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| HTTP Client | `req` | `finch` | Finch is great for high-throughput connection pooling, but Req (built on Finch) handles retries, JSON encoding, and error handling natively, reducing boilerplate for OP-to-RP logout POSTs. |
| HTTP Client | `req` | `httpoison` | HTTPoison is based on Hackney (process-per-request) and is considered legacy. The Elixir ecosystem has moved to the Mint stack (Finch/Req). |
| JWE Library | `erlang-jose` | `joken` | Joken provides a high-level JWT wrapper, but Lockspire already uses `jose` directly for JWS/JWKS. Adding Joken for JWE would be redundant since `jose` handles JWE directly. |
| Testing | OIDF Suite | Custom ExUnit | Custom unit tests cannot replace the official OpenID Foundation Conformance Suite for proving specification compliance, as the suite specifically tests complex negative/edge-case paths required for OIDC Core compliance. |

## Installation

```bash
# Add to mix.exs
defp deps do
  [
    # ... existing deps ...
    {:req, "~> 0.5"} # New dependency for Back-Channel Logout POSTs
  ]
end
```

## Sources

- https://hexdocs.pm/jose/JOSE.JWE.html (HIGH confidence - Verified in codebase)
- https://github.com/wojtekmach/req (HIGH confidence - Elixir HTTP client standard 2024)
- https://gitlab.com/openid/conformance-suite (HIGH confidence - Official OpenID Foundation tool)
