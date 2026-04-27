# Technology Stack

**Project:** Lockspire
**Researched:** 2026-04-27

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir/Phoenix | Existing | Endpoints (`/device/code`, `/token`) | Fits naturally into the existing Lockspire ecosystem. Elixir's concurrency model handles polling efficiently. |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Ecto/Postgres | Existing | State management for `device_code` and `user_code` | Maintains Lockspire's "no external dependencies" constraint. While Redis is often used for short-lived codes, Ecto is sufficient if properly indexed and pruned. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None required | - | - | Built-in Elixir modules (`Crypto`, `Process`) can handle code generation and timing. Rate-limiting should ideally hook into the host app's existing solution. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| State Storage | Ecto/Postgres | Redis / Nebulex | Violates Lockspire's constraint of not forcing external infrastructure on the host Phoenix app. |
| Polling Control | Ecto DB Reads | ETS (Erlang Term Storage) | ETS is lost on application restart. Since OAuth flows can outlive a deploy, Ecto ensures durability. DB load is mitigated by the 5+ second polling interval and `slow_down` responses. |

## Implementation Notes

- **Code Generation:** Use `Base 20` (`BCDFGHJKLMNPQRSTVWXZ`) for user codes to avoid ambiguous characters (0/O, 1/I) and vowels (preventing accidental profanity).
- **Format:** Group user codes with dashes (e.g., `WDJB-MJHT`) for readability.

## Sources

- RFC 8628 (OAuth 2.0 Device Authorization Grant)
- Industry best practices for 2024 (phishing resistance, Base20 user codes).