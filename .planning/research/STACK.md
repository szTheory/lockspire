# Technology Stack: CIBA implementation

**Project:** Lockspire
**Researched:** 2026-05-05

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Phoenix/Elixir | ~> 1.7 | HTTP Endpoints & Concurrency | The existing Lockspire foundation. Its actor model is perfect for managing asynchronous CIBA states. |

### Background Processing
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Oban | ~> 2.15 | Ping/Push Delivery | For Ping and Push CIBA modes, Lockspire must send HTTP requests to the client's notification endpoint. Oban provides durable queues, retries, and backoff out-of-the-box. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Joken/JOSE | ~> 2.0 | JWT Parsing/Signing | Used to validate the signed `request` parameter (if supported) and to issue the `login_hint_token` or `id_token` containing the `auth_req_id` claim in Push mode. |
| Phoenix.PubSub | ~> 2.1 | Internal Signaling | (Optional) Can be used to wake up polling processes or notify LiveViews when a CIBA request transitions to a granted state. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Webhook Delivery | Oban | Task.Supervisor | Raw Tasks lack durability across node restarts and do not provide automatic exponential backoff for failing Ping/Push client endpoints. |
| DB Polling | Registry/PubSub | Sleep Loops | For Poll mode, relying purely on DB queries via `Process.sleep` under heavy load can exhaust connections. Event-driven signaling via PubSub is more efficient in Elixir. |

## Sources

- CIBA Core 1.0 Specification: https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html
