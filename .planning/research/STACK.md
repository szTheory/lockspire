# Stack Research

**Domain:** Embedded OAuth/OIDC authorization server library for Phoenix/Elixir
**Researched:** 2026-04-22
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Phoenix | 1.8.5 | Web and router integration for mounted OAuth/OIDC endpoints | Official Phoenix docs show `v1.8.5`; it matches the target Phoenix install surface and keeps Lockspire aligned with current Phoenix conventions. |
| Phoenix LiveView | 1.1.28 | Admin UI, consent UX, and operator workflows | Official docs show `v1.1.28`; LiveView is central to the product shape and avoids a separate console stack. |
| Ecto SQL | 3.13.5 | Durable storage, migrations, and transactional invariants | Official docs show `v3.13.5`; Ecto/Postgres is the default path that best supports auditable protocol state and tight Phoenix integration. |
| PostgreSQL | 14+ | Primary durable store for clients, grants, keys, refresh families, and audit records | Oban `v2.21` requires PostgreSQL 14+, and durable auth truth belongs in Postgres rather than ephemeral process state. |
| Bandit | 1.6.1 | HTTP server for Plug/Phoenix apps | Official docs show `v1.6.1`; Bandit fits current Phoenix deployments well and keeps the runtime surface simple. |
| Oban | 2.21.x | Scheduled and durable background work such as key lifecycle and cleanup | Official docs show `v2.21.1`; Oban is the natural Phoenix/Elixir choice for operational jobs and release-grade background workflows. |
| OpenTelemetry | 1.6.0 | Tracing foundation and telemetry bridge | Official docs show `v1.6.0`; it gives Lockspire a clean path to trace protocol flows and operator actions in production systems. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_html` | 4.3.0 | HTML-safe rendering primitives in operator and consent surfaces | Use for shared Phoenix rendering safety and form helpers in generated or library-owned UI. |
| `opentelemetry_telemetry` | 1.1.2 | Bridge `:telemetry` events into OpenTelemetry spans and metrics | Use when production deployments want trace correlation without replacing Phoenix-native telemetry emission. |
| `hammer` or equivalent | Latest Phoenix-compatible release | Rate limiting for sensitive endpoints | Use on authorization, token, introspection, and registration surfaces where abuse protection matters. |
| JOSE-compatible JWT/JWK tooling | Latest Phoenix-compatible release | JWT signing, verification, and JWKS handling | Use for standards-compliant token and key operations, but keep algorithms and key lifecycle policy under Lockspire control. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| ExUnit + Phoenix test helpers | Fast protocol, LiveView, and integration tests | Should cover both happy and negative paths with generated host-app fixtures. |
| StreamData | Property-style testing for protocol invariants | Useful for PKCE, redirect validation, replay handling, and key rotation edge cases. |
| Dialyzer + warnings-as-errors | API and library quality guardrails | Supports the repo DNA around honest contracts and release discipline. |
| Credo + formatter + CI pipelines | Static feedback and style enforcement | Keep generated code and library internals predictable across contributors. |

## Installation

```elixir
# mix.exs
defp deps do
  [
    {:phoenix, "~> 1.8.5"},
    {:phoenix_live_view, "~> 1.1.28"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, ">= 0.0.0"},
    {:bandit, "~> 1.6"},
    {:oban, "~> 2.21"},
    {:opentelemetry, "~> 1.6"},
    {:opentelemetry_telemetry, "~> 1.1"}
  ]
end
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Embedded Phoenix library | Standalone headless service | Only when a team explicitly wants a separate auth service and accepts higher operational cost. |
| Ecto/Postgres durable truth | Mnesia or mostly in-memory state | Only for narrowly scoped caches; not for core protocol records. |
| LiveView admin/consent surfaces | Separate SPA admin | Only if a future product direction demands an external console, which is not the v1 thesis. |
| Bandit | Cowboy | Use Cowboy if the host app already standardizes on it and has operational reasons to keep it. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Wildcard redirect URI matching | Creates redirect and mix-up attack space | Exact string equality with narrowly defined localhost exceptions |
| Implicit flow or ROPC | Conflicts with modern OAuth security posture | Authorization code + PKCE and explicitly scoped machine flows |
| Mnesia for durable auth truth | Operational complexity and scale behavior do not justify it here | Postgres for source of truth, ETS only for bounded caches |
| Host-takeover macros that hide account/login ownership | Violates the project seam and makes integration brittle | Small explicit behaviours and generated host glue modules |
| Heavy theming systems | Recreates the foreign-console problem Lockspire is supposed to avoid | Host-owned layouts and editable generated LiveView code |

## Stack Patterns by Variant

**If the host app is a single-tenant Phoenix SaaS:**
- Use row-level tables without extra tenant complexity
- Because the initial wedge is fastest to ship with simpler issuer and scope policy

**If the host app is multi-tenant:**
- Add tenant-aware issuers, keys, and client isolation on top of the same Ecto/Postgres default
- Because tenant separation is a first-class requirement, but separate databases should remain an enterprise-tier option

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `phoenix ~> 1.8.5` | `phoenix_live_view ~> 1.1.28` | Matches the current Phoenix/LiveView docs line. |
| `ecto_sql ~> 3.13` | PostgreSQL 14+ | Aligns with the recommended durable store and current Oban requirement. |
| `oban ~> 2.21` | PostgreSQL 14+ | Official upgrade docs require PostgreSQL 14 or later. |
| `opentelemetry ~> 1.6` | `opentelemetry_telemetry ~> 1.1` | Keeps telemetry emission and trace bridging in the same generation of tooling. |

## Sources

- Official Phoenix docs — https://hexdocs.pm/phoenix/Phoenix.html
- Official Phoenix LiveView docs — https://hexdocs.pm/phoenix_live_view/api-reference.html
- Official Ecto SQL docs — https://hexdocs.pm/ecto_sql/api-reference.html
- Official Oban docs — https://hexdocs.pm/oban/v2-21.html
- Official Bandit docs — https://hexdocs.pm/bandit/1.6.1/api-reference.html
- Official OpenTelemetry docs — https://hexdocs.pm/opentelemetry/search.html
- Official OpenTelemetry Telemetry docs — https://hexdocs.pm/opentelemetry_telemetry/api-reference.html
- Project corpus in `prompts/` — product shape, seam choices, release posture, and threat model

---
*Stack research for: Embedded OAuth/OIDC authorization server library for Phoenix/Elixir*
*Researched: 2026-04-22*
