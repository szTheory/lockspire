# Phase 111: Demo URL Contract & Config Unification - Research

**Researched:** 2026-06-04
**Domain:** Phoenix adoption demo runtime configuration, OAuth/OIDC URL contract, smoke proof
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public URL Contract

- **D-01:** Parse `LOCKSPIRE_DEMO_BASE_URL` once in the adoption demo config and derive both `AdoptionDemoWeb.Endpoint` `url:` and `config :lockspire, :issuer` from it. The Lockspire issuer should be exactly `{base_url}/lockspire`.
- **D-02:** Keep `LOCKSPIRE_DEMO_BASE_URL` as the browser-visible external origin, not as the bind interface or database/network configuration. The config path should normalize the value enough to avoid trailing-slash drift.

### Seeded Demo URLs

- **D-03:** Derive seeded local browser-visible URLs from the same base URL, especially the `acme-ledger-public` and `acme-ledger-backend` redirect URIs plus local demo output strings that show `/oauth/callback`.
- **D-04:** Preserve intentionally external partner fixtures such as Northstar and legacy callback/logout URLs; those model non-local partner state and should not be rewritten to the demo base URL.

### Smoke Proof

- **D-05:** Keep `scripts/demo/adoption_smoke.py` as the executable drift fence for Phase 111. It should continue to use `LOCKSPIRE_DEMO_BASE_URL` as its only external URL input.
- **D-06:** Improve smoke failure clarity for issuer, endpoint, redirect, and verification-URI drift where useful, but do not create a new smoke wrapper or startup-output path in this phase. Those belong to Phase 114.

### Docker Bind Behavior

- **D-07:** Add one explicit bind-interface environment option for the demo endpoint. The default remains loopback for host-local runs, and Docker startup can set it to a container-reachable interface such as `0.0.0.0`.
- **D-08:** Do not infer bind IP from `LOCKSPIRE_DEMO_BASE_URL`; public URL and listening interface are separate concerns.

### Scope Split

- **D-09:** Keep Phase 111 narrowly focused on URL contract/config unification and deterministic proof. App-plus-Postgres Compose work is Phase 112; conflict controls and optional Traefik are Phase 113; startup output, smoke wrapper, and docs expansion are Phase 114; hygiene and cleanup are Phase 115.

### the agent's Discretion

- The exact helper shape for parsing `LOCKSPIRE_DEMO_BASE_URL` is at the agent's discretion, provided it stays local to the adoption demo and does not broaden Lockspire's public API.
- The exact environment variable name for endpoint bind IP is at the agent's discretion, provided the default remains loopback and Docker can opt into a container-reachable bind.
- The exact wording of smoke assertion errors is at the agent's discretion, provided issuer and endpoint drift fail clearly.

### Deferred Ideas (OUT OF SCOPE)

- Default app-plus-Postgres Compose topology, database healthcheck, project-scoped volumes, idempotent container setup, and HTTP readiness wait - Phase 112.
- Configurable Compose project names, public app ports, scoped cache reset, and optional Traefik hostname routing - Phase 113.
- Startup ready banner, reprint command, smoke wrapper, and expanded adoption-demo docs - Phase 114.
- Repo hygiene gate, scoped cleanup lanes, CI/local hygiene split, and demo-owned Docker artifact cleanup - Phase 115.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| URL-01 | The adoption demo has one canonical `LOCKSPIRE_DEMO_BASE_URL` for the browser-visible origin. | Existing config still splits `LOCKSPIRE_DEMO_HOST`, `PORT`, and hard-coded issuer; replace with one parsed base URL in `examples/adoption_demo/config/config.exs`. [VERIFIED: codebase grep] |
| URL-02 | Phoenix endpoint URL generation and the Lockspire issuer derive from the same base URL. | Phoenix `:url` config controls generated app URLs, while Lockspire discovery and endpoint metadata derive from `Lockspire.Config.issuer!/0`. [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] [VERIFIED: codebase grep] |
| URL-03 | Seeded redirect, callback, and verification URLs align with the configured base URL after demo setup. | Local seed literals for redirect URIs, registration URI, interaction return URLs, logout post-redirect, and printed callback output currently include `http://127.0.0.1:4100`. [VERIFIED: codebase grep] |
| URL-04 | The smoke script continues to use `LOCKSPIRE_DEMO_BASE_URL` as its only external URL input and fails clearly on issuer or endpoint drift. | `scripts/demo/adoption_smoke.py` already reads only `LOCKSPIRE_DEMO_BASE_URL` for the external browser origin and asserts issuer, authorization endpoint, device endpoint, callback, and verification URI. [VERIFIED: codebase grep] |
| URL-05 | Docker mode binds Phoenix to a container-reachable interface without changing the safe loopback default for host-local runs. | Bandit/Phoenix HTTP options pass listener `ip` and `port` separately from Phoenix `url:` generation, so add a bind-IP env without coupling it to the public base URL. [VERIFIED: local deps] [CITED: https://bandit.hexdocs.pm/0.7.1/Bandit.PhoenixAdapter.html] |
</phase_requirements>

## Summary

Phase 111 should modify only the adoption demo URL contract and proof surface. The correct implementation center is `examples/adoption_demo/config/config.exs`: parse `LOCKSPIRE_DEMO_BASE_URL` once, normalize trailing slashes, derive `AdoptionDemoWeb.Endpoint` `url:` and `config :lockspire, :issuer` from it, and keep listener bind config separate through a new explicit env such as `LOCKSPIRE_DEMO_BIND_IP`. [VERIFIED: codebase grep] [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html]

The planner should treat seeded demo data and displayed developer-app URLs as part of the same contract. Local Acme demo URLs must derive from the configured base URL; external Northstar, legacy, and backend partner fixture URLs must remain external because the user locked them as non-local partner state. [VERIFIED: codebase grep] [ASSUMED]

`scripts/demo/adoption_smoke.py` is already the right black-box drift fence. The planner should improve assertion messages around discovery issuer/endpoint values and device verification URI, but should not introduce new wrappers, startup banners, default app-plus-DB Compose, optional Traefik behavior, or protocol changes in this phase. [VERIFIED: codebase grep]

**Primary recommendation:** Add a tiny adoption-demo-only base URL helper in config/seeds/controller code, set Phoenix `url:` and Lockspire `issuer` from `LOCKSPIRE_DEMO_BASE_URL`, add a separate `LOCKSPIRE_DEMO_BIND_IP` listener env, and extend the existing smoke with clearer drift diagnostics. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir; the host app owns accounts, login UX, layouts, branding, and product policy. [VERIFIED: AGENTS.md]
- Preserve embedded-library shape and do not turn this phase into a standalone auth service or hosted-auth surface. [VERIFIED: AGENTS.md]
- Keep strong boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Keep the host seam explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve security defaults: PKCE S256 required by default, exact-match redirect URI validation, hashed client secrets, short-lived single-use codes, refresh rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]
- Project stack directives name Phoenix `1.8.5`, LiveView `1.1.28`, Ecto SQL `3.13.5`, PostgreSQL `14+`, Bandit `1.6.1`, Oban `2.21.x`, and OpenTelemetry `1.6.0`; current lockfiles resolve Phoenix `1.8.7`, LiveView `1.1.30`, Ecto SQL `3.13.5`, Bandit `1.11.1`, Oban `2.21.1`, and OpenTelemetry API `1.5.0`. [VERIFIED: AGENTS.md] [VERIFIED: mix deps]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Browser-visible demo origin contract | Frontend Server / Phoenix Endpoint | API / Backend | Phoenix `url:` owns generated browser-visible app URLs; Lockspire issuer and discovery derive backend protocol metadata from the same origin. [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] [VERIFIED: codebase grep] |
| Lockspire issuer and discovery endpoints | API / Backend | Frontend Server / Phoenix Endpoint | Lockspire protocol metadata is built from `Lockspire.Config.issuer!/0`; this phase should feed config, not alter discovery code. [VERIFIED: codebase grep] |
| Seeded local OAuth redirect/callback data | Database / Storage | API / Backend | Seed data persists redirect URIs and interaction/logout URLs, and exact-match redirect validation compares request values against stored client data. [VERIFIED: codebase grep] |
| Demo developer-app display | Browser / Client | Frontend Server / Phoenix Controller | Displayed OAuth callback and authorize URL are rendered by `DeveloperController`; derive them from config so copied demo values match seeded client state. [VERIFIED: codebase grep] |
| Docker listener binding | Frontend Server / Phoenix Endpoint | Docker runtime | Bandit `http: [ip:, port:]` controls the socket listener, while Phoenix `url:` controls generated public URLs. [VERIFIED: local deps] [CITED: https://bandit.hexdocs.pm/0.7.1/Bandit.PhoenixAdapter.html] |
| Drift proof | External smoke script | CI | `scripts/demo/adoption_smoke.py` drives HTTP through the configured base URL and CI already invokes it with `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100`. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.7` locked, `~> 1.8.5` required | Endpoint URL generation and router/controller host app behavior | Phoenix Endpoint `:url` is the documented place for app-wide generated URLs. [VERIFIED: mix deps] [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] |
| Bandit | `1.11.1` locked, `~> 1.11` required | Phoenix HTTP server adapter and listener binding | Bandit adapter consumes Phoenix `http:` options including `ip` and `port`. [VERIFIED: mix deps] [VERIFIED: local deps] |
| Ecto SQL/PostgreSQL | `ecto_sql 3.13.5`, PostgreSQL `14+` | Seeded demo client and interaction state | `mix ecto.setup` runs migrations and `priv/repo/seeds.exs`, which owns repeatable demo proof state. [VERIFIED: mix deps] [VERIFIED: codebase grep] |
| Python stdlib | Python `3.14.4` available | Black-box smoke HTTP client | The smoke script uses only Python standard-library modules and has no package install step. [VERIFIED: local environment] [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | `1.4.5` locked | JSON parsing/rendering in Phoenix/Lockspire responses | Existing demo and protocol responses already use Jason via Phoenix JSON config. [VERIFIED: mix deps] [VERIFIED: codebase grep] |
| Docker | `29.5.2` available locally | Later Docker mode and current compose file | Phase 111 only needs the bind env in compose/Docker config; full Docker topology is deferred. [VERIFIED: local environment] [VERIFIED: CONTEXT.md] |
| PostgreSQL client tools | `psql 14.17` available locally | Local DB readiness/debugging | CI uses `pg_isready`; host-local smoke may need local PostgreSQL for `mix ecto.setup`. [VERIFIED: local environment] [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Local config helper in `config.exs` | Shared module under `lib/adoption_demo` | A shared module is easier to reuse in seeds/controller but is less available during config evaluation unless compiled first; config-local functions are safer for endpoint/issuer boot config. [ASSUMED] |
| `LOCKSPIRE_DEMO_BIND_IP` | `PHX_HOST`, `LOCKSPIRE_DEMO_HOST`, or deriving from base URL | A dedicated bind env keeps public URL and listener socket separate, matching the locked decision and Phoenix/Bandit config split. [VERIFIED: CONTEXT.md] [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] |
| New smoke wrapper | Existing `scripts/demo/adoption_smoke.py` | A wrapper belongs to Phase 114; Phase 111 should improve direct smoke messages only. [VERIFIED: CONTEXT.md] |

**Installation:**

No new external packages should be installed in Phase 111. [VERIFIED: codebase grep]

## Package Legitimacy Audit

No external package installation is recommended for this phase, so the Package Legitimacy Gate is not required. [VERIFIED: codebase grep]

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Environment
  LOCKSPIRE_DEMO_BASE_URL
    |
    v
Adoption demo config helper
  - parse absolute URI
  - normalize no trailing slash
  - reject query/fragment/blank host
    |
    +--> Phoenix Endpoint url: [scheme, host, port]
    |       |
    |       v
    |   Browser-visible Phoenix URL generation
    |
    +--> Lockspire issuer: base_url <> "/lockspire"
    |       |
    |       v
    |   Discovery/JWKS/token/userinfo/device metadata
    |
    +--> Seed/controller local demo URLs
            |
            v
        Registered redirect URIs, callback display, demo output

Environment
  LOCKSPIRE_DEMO_BIND_IP
    |
    v
Bandit/Phoenix http: [ip:, port:]
    |
    v
Listener socket only, independent of public URL

Smoke proof
  LOCKSPIRE_DEMO_BASE_URL
    |
    v
GET discovery -> assert issuer/endpoints
Authorize/token -> assert callback redirect URI alignment
Device code -> assert verification_uri
Protected API -> assert issued-token path still works
```

### Recommended Project Structure

```text
examples/adoption_demo/
├── config/config.exs                         # parse base URL, set endpoint url, issuer, bind IP
├── priv/repo/seeds.exs                       # derive local seed URLs from base URL
├── lib/adoption_demo_web/controllers/
│   └── developer_controller.ex               # derive displayed redirect URI and authorize param
├── docker-compose.yml                        # set explicit bind env for Docker mode
└── mix.exs                                   # existing ecto.setup remains the setup path
scripts/demo/
└── adoption_smoke.py                         # clearer drift assertions, no new wrapper
```

### Pattern 1: Parse Once And Derive Config

**What:** Normalize `LOCKSPIRE_DEMO_BASE_URL` at adoption-demo boot and derive all public URL config from the resulting URI. [VERIFIED: codebase grep]

**When to use:** Endpoint `url:` and Lockspire `issuer` must share scheme, host, and external port. [VERIFIED: CONTEXT.md]

**Example:**

```elixir
# Source: Phoenix Endpoint docs and existing adoption_demo config.
demo_base_url =
  System.get_env("LOCKSPIRE_DEMO_BASE_URL", "http://127.0.0.1:4100")
  |> String.trim()
  |> String.trim_trailing("/")

demo_uri = URI.parse(demo_base_url)

if demo_uri.scheme in [nil, ""] or demo_uri.host in [nil, ""] or demo_uri.query || demo_uri.fragment do
  raise ArgumentError, "LOCKSPIRE_DEMO_BASE_URL must be an absolute URL without query or fragment"
end

config :adoption_demo, AdoptionDemoWeb.Endpoint,
  url: [
    scheme: demo_uri.scheme,
    host: demo_uri.host,
    port: demo_uri.port
  ]

config :lockspire,
  issuer: demo_base_url <> "/lockspire",
  mount_path: "/lockspire"
```

### Pattern 2: Separate Bind IP From Public URL

**What:** Use an explicit env for the socket bind IP, defaulting to loopback. [VERIFIED: CONTEXT.md]

**When to use:** Docker must set a container-reachable listener such as `0.0.0.0` without changing the browser-visible base URL. [VERIFIED: CONTEXT.md]

**Example:**

```elixir
# Source: local Bandit.PhoenixAdapter docs in deps/bandit.
defp demo_bind_ip do
  case System.get_env("LOCKSPIRE_DEMO_BIND_IP", "127.0.0.1") do
    "127.0.0.1" -> {127, 0, 0, 1}
    "0.0.0.0" -> {0, 0, 0, 0}
    other -> raise ArgumentError, "unsupported LOCKSPIRE_DEMO_BIND_IP=#{inspect(other)}"
  end
end

config :adoption_demo, AdoptionDemoWeb.Endpoint,
  http: [
    ip: demo_bind_ip(),
    port: String.to_integer(System.get_env("PORT") || "4100")
  ]
```

### Pattern 3: Keep Seed URL Derivation Local And Explicit

**What:** Add local variables in `seeds.exs`, such as `demo_base_url`, `oauth_callback_url`, `lockspire_base_url`, and `verification_url`, then use those only for local Acme demo records. [VERIFIED: codebase grep]

**When to use:** Seeded `acme-ledger-public`, `acme-ledger-backend`, local interaction return URLs, local registration URI, local post-logout redirect, and printed callback output must align with the base URL. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: existing examples/adoption_demo/priv/repo/seeds.exs structure.
demo_base_url =
  System.get_env("LOCKSPIRE_DEMO_BASE_URL", "http://127.0.0.1:4100")
  |> String.trim()
  |> String.trim_trailing("/")

oauth_callback_url = demo_base_url <> "/oauth/callback"
lockspire_url = demo_base_url <> "/lockspire"

%Client{
  client_id: "acme-ledger-public",
  redirect_uris: [oauth_callback_url]
}

%Interaction{
  return_to: lockspire_url <> "/interactions/interaction-pending-login"
}
```

### Anti-Patterns to Avoid

- **Inferring bind IP from `LOCKSPIRE_DEMO_BASE_URL`:** Public URL and socket bind are different configuration axes. [VERIFIED: CONTEXT.md] [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html]
- **Rewriting external partner fixtures:** Northstar, legacy, and backend example URLs intentionally model external partner state and must remain external. [VERIFIED: CONTEXT.md]
- **Changing Lockspire protocol code to fix demo drift:** Discovery and device verification already derive from issuer; fix the demo config that feeds issuer. [VERIFIED: codebase grep]
- **Broadening docs/startup/Docker topology:** Startup banner, smoke wrapper, default app-plus-DB Compose, conflict controls, and Traefik work are explicitly later phases. [VERIFIED: CONTEXT.md]
- **Leaving `LOCKSPIRE_DEMO_HOST` as a second public URL source:** It conflicts with `LOCKSPIRE_DEMO_BASE_URL` as the single browser-visible truth. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL parsing | String splitting on `://`, `:`, or `/` | Elixir `URI.parse/1` and `URI.to_string/1` | Handles scheme, host, port, path, query, and fragment consistently. [VERIFIED: codebase grep] |
| Phoenix external URL generation | Custom URL helper spread through controllers | Endpoint `url:` config and base-derived local variables | Phoenix documents `:url` as the app-wide generated URL config. [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] |
| Issuer endpoint construction | Discovery-specific endpoint rewrites | Existing `Lockspire.Config.issuer!/0` and discovery `issuer_url/2` | Existing discovery code builds endpoint metadata from issuer and route paths. [VERIFIED: codebase grep] |
| HTTP smoke client | New dependency-based browser stack | Existing Python stdlib smoke script | Current script already proves browser-like cookies, login, consent, token exchange, device flow, and protected API. [VERIFIED: codebase grep] |
| IP address parser | Broad arbitrary IP parser | Small allowlist for `127.0.0.1` and `0.0.0.0` unless more is required later | Phase scope only needs safe loopback default plus Docker-reachable bind. [VERIFIED: CONTEXT.md] [ASSUMED] |

**Key insight:** The hard part is not URL construction; it is avoiding two independent truths. Keep one public base URL and one separate bind interface, then let existing Phoenix and Lockspire URL builders do their normal work. [VERIFIED: codebase grep] [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html]

## Common Pitfalls

### Pitfall 1: Trailing Slash Drift

**What goes wrong:** `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100/` creates issuer or callback values with `//lockspire` or `//oauth/callback`. [ASSUMED]

**Why it happens:** Existing literals are simple concatenations in smoke and should be matched by config/seeds normalization. [VERIFIED: codebase grep]

**How to avoid:** Normalize base URL once with `String.trim_trailing("/")` and use derived variables. [ASSUMED]

**Warning signs:** Smoke fails discovery issuer, token exchange redirect URI, or device verification URI assertions. [VERIFIED: codebase grep]

### Pitfall 2: `url:` Port Versus Listener Port Confusion

**What goes wrong:** Generated URLs point at the internal container port or listener bind instead of the browser-visible port. [ASSUMED]

**Why it happens:** Phoenix `url:` is for generated URLs; Bandit `http:` is for listener config. [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] [VERIFIED: local deps]

**How to avoid:** Derive `url:` from `LOCKSPIRE_DEMO_BASE_URL`, derive `http: [ip:, port:]` from bind/port envs, and do not reuse bind IP for generated URLs. [VERIFIED: CONTEXT.md]

**Warning signs:** Discovery publishes `0.0.0.0`, Docker internal port `4000`, or a host that differs from the smoke base URL. [ASSUMED]

### Pitfall 3: Exact Redirect URI Mismatch

**What goes wrong:** Authorization succeeds until token exchange or redirect validation fails because request `redirect_uri` differs byte-for-byte from seeded client redirect URIs. [VERIFIED: codebase grep]

**Why it happens:** Lockspire validates redirect URIs by exact membership in `client.redirect_uris`. [VERIFIED: codebase grep]

**How to avoid:** Use the same `oauth_callback_url` expression in seeds, developer display, authorize params, and smoke. [VERIFIED: codebase grep]

**Warning signs:** Smoke fails at authorize or token exchange after changing only base URL. [VERIFIED: codebase grep]

### Pitfall 4: Accidentally Rewriting Fixture URLs

**What goes wrong:** Admin UI proof loses realistic external partner data if all URLs in seeds are blindly rewritten to the demo base URL. [VERIFIED: CONTEXT.md]

**Why it happens:** Grep replacement treats local demo and external partner fixtures as equivalent. [ASSUMED]

**How to avoid:** Rewrite only local `127.0.0.1:4100` demo URLs that represent the adoption demo browser origin; preserve `partners.northstar.example.com`, `legacy-reporter.example.com`, and backend long-path fixtures. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md]

**Warning signs:** Northstar/legacy callback/logout/admin proof values disappear from seeds. [VERIFIED: codebase grep]

### Pitfall 5: Smoke Failure Messages Hide Expected/Actual Drift

**What goes wrong:** Python bare `assert` failures omit enough context to diagnose whether issuer, endpoint, or verification URI drifted. [VERIFIED: codebase grep]

**Why it happens:** Existing smoke uses direct `assert discovery_json[...] == ...` in several places. [VERIFIED: codebase grep]

**How to avoid:** Replace drift assertions with helper functions that print label, expected, actual, and base URL. [ASSUMED]

**Warning signs:** CI prints only `adoption demo smoke failed:` with a sparse assertion message before dumping server logs. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official/local sources:

### Phoenix Endpoint URL From Base URL

```elixir
# Source: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html
config :adoption_demo, AdoptionDemoWeb.Endpoint,
  url: [
    scheme: demo_uri.scheme,
    host: demo_uri.host,
    port: demo_uri.port
  ]
```

### Bandit Listener Bind From Separate Env

```elixir
# Source: examples/adoption_demo/deps/bandit/lib/bandit/phoenix_adapter.ex
config :adoption_demo, AdoptionDemoWeb.Endpoint,
  http: [
    ip: demo_bind_ip(),
    port: String.to_integer(System.get_env("PORT") || "4100")
  ]
```

### Smoke Drift Assertion Helper

```python
# Source: scripts/demo/adoption_smoke.py pattern.
def assert_equal(actual, expected, label):
    if actual != expected:
        raise AssertionError(
            f"{label}: expected {expected!r}, got {actual!r} "
            f"(LOCKSPIRE_DEMO_BASE_URL={BASE_URL!r})"
        )

assert_equal(discovery_json["issuer"], BASE_URL + "/lockspire", "discovery issuer")
assert_equal(
    discovery_json["authorization_endpoint"],
    BASE_URL + "/lockspire/authorize",
    "authorization endpoint",
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate `LOCKSPIRE_DEMO_HOST`, `PORT`, and hard-coded issuer | One `LOCKSPIRE_DEMO_BASE_URL` for browser-visible URLs plus separate bind env | Phase 111 planned on 2026-06-04 | Prevents issuer, discovery endpoint, seed, and smoke drift. [VERIFIED: CONTEXT.md] |
| Bare smoke assertions for URL equality | Labeled expected/actual drift messages | Phase 111 recommendation | Makes CI failures diagnose issuer or endpoint drift directly. [VERIFIED: codebase grep] [ASSUMED] |
| Traefik-only compose comments implying `0.0.0.0` bind | Explicit bind env consumed by Phoenix config | Phase 111 recommendation | Later Docker phases can set container-reachable bind without changing host-local default. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md] |

**Deprecated/outdated:**

- `LOCKSPIRE_DEMO_HOST` as a public URL input is outdated for Phase 111 because `LOCKSPIRE_DEMO_BASE_URL` is now the locked single browser-visible URL truth. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep]
- Hard-coded `http://127.0.0.1:4100` in local demo seeds and developer UI is outdated except as the default `LOCKSPIRE_DEMO_BASE_URL` value. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | External Northstar/legacy/backend fixtures should remain non-local because they model partner state, beyond the locked Northstar/legacy examples. | Summary, Pitfalls | Planner might preserve or rewrite one fixture incorrectly; verify exact intended list during implementation review. |
| A2 | A config-local helper is preferable to a compiled shared module for endpoint/issuer boot config. | Alternatives Considered | Planner could choose a shared helper and hit config evaluation ordering problems. |
| A3 | The bind IP parser can be a small allowlist for `127.0.0.1` and `0.0.0.0`. | Don't Hand-Roll | If later phases need IPv6 or custom LAN IPs, this may need extension. |
| A4 | Trimming trailing slashes is sufficient normalization for Phase 111. | Common Pitfalls | If users provide paths in base URL, config may need stricter rejection. |
| A5 | Expected/actual smoke helper wording is enough for drift clarity. | Common Pitfalls, State of the Art | CI failures may still need more context if response JSON is malformed. |

## Open Questions (RESOLVED)

1. **Should `LOCKSPIRE_DEMO_BASE_URL` allow a path prefix other than root?**
   - What we know: The locked issuer is exactly `{base_url}/lockspire`, and current demo routes live at root plus `/lockspire`. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep]
   - What's unclear: Whether a future reverse-proxy path prefix is intended. [ASSUMED]
   - Recommendation: For Phase 111, reject or ignore path-prefix expansion and keep base URL as an origin with no path except optional trailing slash. [ASSUMED]
   - RESOLVED: Phase 111 rejects path prefixes except empty/root path. Reverse-proxy path-prefix behavior is not part of the v1.30 Phase 111 URL contract and can be considered only if a later phase explicitly scopes it.

2. **Should the bind env accept arbitrary IPv4 values?**
   - What we know: Requirements only need loopback default and Docker-reachable `0.0.0.0`. [VERIFIED: REQUIREMENTS.md]
   - What's unclear: Whether local LAN testing is needed before later Docker phases. [ASSUMED]
   - Recommendation: Start with `127.0.0.1` and `0.0.0.0`; add broader parsing only if tests or user decisions require it. [ASSUMED]
   - RESOLVED: Phase 111 accepts only `127.0.0.1` and `0.0.0.0` for the bind env. Broader IP parsing is deferred unless later Docker conflict/control work creates a concrete need.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/config verification | yes | `1.19.5` with OTP `28` | Use project CI image if local version diverges. [VERIFIED: local environment] |
| Mix | Compile/test commands | yes | `1.19.5` | Use CI. [VERIFIED: local environment] |
| Python 3 | `scripts/demo/adoption_smoke.py` | yes | `3.14.4` | Use CI runner Python. [VERIFIED: local environment] |
| Docker | Docker bind/compose sanity | yes | `29.5.2` | Phase can still compile/smoke host-local without Docker; full Docker proof is later. [VERIFIED: local environment] |
| PostgreSQL client tools | Local DB readiness/debugging | yes | `psql 14.17` | CI service provides Postgres. [VERIFIED: local environment] |
| Context7 CLI | Documentation lookup | no | n/a | Used HexDocs and local dependency docs. [VERIFIED: local environment] |

**Missing dependencies with no fallback:**

- None identified for Phase 111 research. [VERIFIED: local environment]

**Missing dependencies with fallback:**

- Context7 CLI is unavailable; official HexDocs and local dependency source were used instead. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix plus Python stdlib smoke. [VERIFIED: codebase grep] |
| Config file | Root `mix.exs`, `test/test_helper.exs`; adoption demo has no `examples/adoption_demo/test` directory. [VERIFIED: codebase grep] |
| Quick run command | `mix format --check-formatted examples/adoption_demo/config/config.exs examples/adoption_demo/priv/repo/seeds.exs examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex && cd examples/adoption_demo && mix compile --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `cd examples/adoption_demo && mix ecto.setup && mix phx.server` plus `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` from repo root. [VERIFIED: codebase grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| URL-01 | `LOCKSPIRE_DEMO_BASE_URL` is the canonical browser-visible origin | static + smoke | `rg -n "LOCKSPIRE_DEMO_HOST|http://127\\.0\\.0\\.1:4100" examples/adoption_demo scripts/demo docs/adoption-demo.md .github/workflows/ci.yml` after implementation; expected remaining literals should be intentional defaults only. [VERIFIED: codebase grep] | yes |
| URL-02 | Endpoint URL and Lockspire issuer derive from same base | smoke | `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` with server running. [VERIFIED: codebase grep] | yes |
| URL-03 | Seeds align redirect/callback/verification URLs | integration smoke | `cd examples/adoption_demo && mix ecto.setup`, then smoke. [VERIFIED: codebase grep] | yes |
| URL-04 | Smoke remains base-URL driven and clear on drift | static + smoke | `rg -n "LOCKSPIRE_DEMO_BASE_URL|os\\.environ|get\\(" scripts/demo/adoption_smoke.py` and a deliberate mismatched base smoke if time permits. [VERIFIED: codebase grep] | yes |
| URL-05 | Docker can bind to container-reachable interface without weakening default | compile + compose config review | `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0 cd examples/adoption_demo && mix compile --warnings-as-errors`; optionally `docker compose config`. [VERIFIED: codebase grep] | yes |

### Sampling Rate

- **Per task commit:** `cd examples/adoption_demo && mix compile --warnings-as-errors` plus targeted `rg` for hard-coded URL drift. [VERIFIED: codebase grep]
- **Per wave merge:** Run `mix format --check-formatted` for touched Elixir files, adoption demo compile, `mix ecto.setup`, server, and smoke. [VERIFIED: codebase grep]
- **Phase gate:** Full adoption demo smoke green with default `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100`; static grep shows no unintended second browser-visible URL truth. [VERIFIED: REQUIREMENTS.md]

### Wave 0 Gaps

- [ ] No adoption-demo ExUnit test directory exists; planner may use the smoke as the primary executable proof instead of creating new ExUnit infrastructure. [VERIFIED: codebase grep]
- [ ] No unit test currently covers config parsing; planner may add a small script/compile proof or keep validation in smoke depending on task granularity. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Preserve host-owned login and operator guard routes; do not alter auth flows. [VERIFIED: AGENTS.md] [VERIFIED: codebase grep] |
| V3 Session Management | yes | Keep existing Phoenix browser pipeline/session behavior untouched. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Keep `/lockspire/admin` behind host operator plug. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Validate `LOCKSPIRE_DEMO_BASE_URL` as absolute URL without query/fragment and validate bind env against expected values. [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] [ASSUMED] |
| V6 Cryptography | no new crypto | Do not change PKCE, signing, client secret hashing, token, or key behavior. [VERIFIED: AGENTS.md] |

### Known Threat Patterns for Phoenix/OAuth Demo Config

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Open redirect or redirect mismatch via seeded callback drift | Tampering | Derive registered redirect URIs and smoke redirect params from the same base URL while preserving exact-match validation. [VERIFIED: codebase grep] |
| Publishing wrong issuer/endpoints in discovery | Spoofing | Feed `config :lockspire, :issuer` from normalized base URL and let discovery derive endpoints from `Config.issuer!/0`. [VERIFIED: codebase grep] |
| Exposing demo server beyond local host unintentionally | Information Disclosure | Default bind IP remains `127.0.0.1`; Docker must opt into `0.0.0.0` explicitly. [VERIFIED: CONTEXT.md] |
| Leaking secrets in demo output while touching seeds | Information Disclosure | Do not expand startup output in this phase and preserve redaction-sensitive seed comments. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep] |

## Exact Files And Planner Notes

| File | Current Finding | Recommended Planning Action |
|------|-----------------|-----------------------------|
| `examples/adoption_demo/config/config.exs` | Hard-codes `http: [ip: {127,0,0,1}]`, builds endpoint `url:` from `LOCKSPIRE_DEMO_HOST`/`PORT`, and hard-codes Lockspire issuer. [VERIFIED: codebase grep] | Add base URL parsing; derive endpoint `url:` and issuer; add separate bind IP env; retire `LOCKSPIRE_DEMO_HOST`. |
| `examples/adoption_demo/priv/repo/seeds.exs` | Local `127.0.0.1:4100` literals appear in Acme redirect URIs, Northstar registration URI, interactions, logout post-redirect, and printed callback output. [VERIFIED: codebase grep] | Derive local demo URLs from base URL; preserve external partner fixtures. |
| `examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex` | Displays and submits hard-coded local callback URL. [VERIFIED: codebase grep] | Derive callback from base URL or endpoint config so UI copy matches seed/smoke. |
| `examples/adoption_demo/docker-compose.yml` | Sets `PORT=4000` and comments that Phoenix should bind to `0.0.0.0`, but config does not consume a bind env. [VERIFIED: codebase grep] | Add explicit bind env for Docker; avoid broader compose topology changes. |
| `scripts/demo/adoption_smoke.py` | Base-url driven already; uses bare equality asserts for issuer/endpoints/verification URI. [VERIFIED: codebase grep] | Keep single env input; add clearer expected/actual assertion helper. |
| `.github/workflows/ci.yml` | Adoption smoke job already sets `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100`. [VERIFIED: codebase grep] | Usually no change needed except if new bind env affects CI default. |
| `docs/adoption-demo.md` | Documents opening `http://127.0.0.1:4100` and default smoke command. [VERIFIED: codebase grep] | Keep docs changes minimal; larger Docker/default docs belong to Phase 114. |
| `lib/lockspire/config.ex` | `device_verification_uri/0` derives `/verify` from issuer. [VERIFIED: codebase grep] | Do not change protocol code; config unification should make verification URI align. |
| `lib/lockspire/protocol/discovery.ex` | Discovery endpoint metadata derives from issuer and route paths. [VERIFIED: codebase grep] | Do not change protocol code for this phase. |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundaries, stack directives, security defaults. [VERIFIED: AGENTS.md]
- `.planning/phases/111-demo-url-contract-config-unification/111-CONTEXT.md` - locked Phase 111 decisions. [VERIFIED: CONTEXT.md]
- `.planning/REQUIREMENTS.md` - URL-01..URL-05 and v1.30 scope split. [VERIFIED: REQUIREMENTS.md]
- `.planning/ROADMAP.md` - Phase 111 scope and later phase boundaries. [VERIFIED: ROADMAP.md]
- `examples/adoption_demo/config/config.exs`, `priv/repo/seeds.exs`, `DeveloperController`, `docker-compose.yml`, `.github/workflows/ci.yml`, and `scripts/demo/adoption_smoke.py` - current implementation state. [VERIFIED: codebase grep]
- Phoenix Endpoint official docs - `:url` runtime configuration and endpoint URL helpers. [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html]
- Local Bandit adapter docs in `examples/adoption_demo/deps/bandit/lib/bandit/phoenix_adapter.ex` - `http:`/`https:` options pass through to Bandit. [VERIFIED: local deps]

### Secondary (MEDIUM confidence)

- Bandit HexDocs search result for PhoenixAdapter option names. [CITED: https://bandit.hexdocs.pm/0.7.1/Bandit.PhoenixAdapter.html]

### Tertiary (LOW confidence)

- None used as authoritative input; assumptions are listed in the Assumptions Log. [VERIFIED: research process]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions verified with `mix deps`; no new package install recommended. [VERIFIED: mix deps]
- Architecture: HIGH - current code directly shows URL generation, issuer derivation, seed literals, and smoke assertions. [VERIFIED: codebase grep]
- Pitfalls: MEDIUM - drift points are verified, but some implementation-shape details are recommendations and are marked assumed. [VERIFIED: codebase grep] [ASSUMED]

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for codebase-specific findings; recheck official docs if Phoenix/Bandit dependencies are upgraded before implementation. [ASSUMED]
