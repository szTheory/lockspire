# Technology Stack

**Project:** Lockspire Token Exchange (RFC 8693)
**Researched:** 2026-05-XX

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | 1.14+ | Host Language | Core runtime for Lockspire. |
| Phoenix | 1.7+ | Web Framework | Request/Response handling for the `/oauth/token` endpoint. |
| JOSE / Joken | Current | JWT Manipulation | Required for decoding `subject_token`/`actor_token` and minting new tokens containing the `act` (actor) claims. |

### Supporting Standards (RFCs)
| Standard | Purpose | When to Use |
|----------|---------|-------------|
| RFC 8693 | OAuth 2.0 Token Exchange | The primary specification for this milestone. |
| RFC 7519 | JSON Web Token (JWT) | For standardizing the `urn:ietf:params:oauth:token-type:jwt` format exchanged in requests. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Policy Engine | **Host App Behaviour** (`Lockspire.TokenExchangeValidator`) | Built-in OPA (Open Policy Agent) integration | Lockspire aims to be an embedded Elixir library, not a standalone service. Relying on host-app Elixir code allows developers to write idiomatic Elixir or integrate their own policy tools (including OPA if they choose). |

## Installation

No new installation dependencies are anticipated beyond the existing Lockspire core stack. The implementation will extend existing `Plug` pipelines and token minting modules.

## Sources

- [RFC 8693: OAuth 2.0 Token Exchange](https://datatracker.ietf.org/doc/html/rfc8693) (HIGH confidence)